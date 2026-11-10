"""Independently verify raw benchmark exports; no third-party dependencies.

Usage: python benchmark/tool/analyze_matrix.py RESULTS_DIRECTORY
Writes analysis.json. Exit 0 requires a complete, consistent three-run group
for every scenario selected in index.json. Invalid attempts are retained.
These are work-duration statistics, not GPU or presentation measurements.
"""

import argparse
import hashlib
import json
import math
from pathlib import Path


STAGES = {"build": "buildUs", "raster": "rasterUs", "totalSpan": "totalUs"}
CONFIG_KEYS = (
    "flutterRevision", "dartVersion", "osVersion", "platform", "buildMode",
    "device", "gpu", "renderer", "powerMode", "case", "opticalConfig",
    "surfaceCount", "arrangement", "animatedBackground", "qualityScale",
    "physicalWidth", "physicalHeight", "devicePixelRatio", "refreshRateHz",
)


def distribution(values):
    values = sorted(values)
    if not values:
        return dict.fromkeys(("p50Ms", "p90Ms", "p99Ms", "worstMs"))
    result = {
        key: values[math.floor((len(values) - 1) * p + .5)] / 1000
        for key, p in (("p50Ms", .5), ("p90Ms", .9), ("p99Ms", .99))
    }
    return {**result, "worstMs": values[-1] / 1000}


def close(actual, expected):
    return (actual is None and expected is None) or (
        isinstance(actual, (int, float)) and not isinstance(actual, bool)
        and isinstance(expected, (int, float))
        and math.isclose(actual, expected, rel_tol=1e-9, abs_tol=1e-9)
    )


def validate_report(report):
    errors = []
    frames = report.get("frames", [])
    metadata = report.get("metadata", {})
    if metadata.get("benchmarkProtocolVersion") == 6:
        required = metadata.get("requiredInitialSettleUs")
        age = metadata.get("appSessionAgeAtStartUs")
        if type(required) is not int or required < 60_000_000:
            errors.append("initial settling policy shorter than sixty seconds")
        elif type(age) is not int or age < required:
            errors.append("application session did not complete initial settling")
    if not frames or len(frames) != report.get("sampleCount"):
        errors.append("empty or mismatched sample count")
    for frame in frames:
        if any(type(frame.get(k)) is not int or frame[k] < 0
               for k in ("vsyncUs", "buildUs", "rasterUs", "totalUs")):
            return {"valid": False, "errors": ["invalid raw frame"], "statistics": {}}
    start, end = report.get("samplingStartVsyncUs"), report.get("samplingEndVsyncUs")
    if not isinstance(start, int) or not isinstance(end, int) or end - start < 30_000_000:
        errors.append("measurement window shorter than 30 seconds")
    elif any(not start <= f["vsyncUs"] < end for f in frames):
        errors.append("raw frame outside measurement window")
    if len({f["vsyncUs"] for f in frames}) != len(frames):
        errors.append("duplicate raw frame timestamps")
    if report.get("warmupUs", 0) < 3_000_000:
        errors.append("warmup shorter than three seconds")
    if not all(report.get(key) is True for key in
               ("complete", "measurementComplete", "qualifiedMeasurement")):
        errors.append("application did not qualify measurement")
    if report.get("stopReason") != "duration" or report.get("capacityReached"):
        errors.append("measurement stopped early")
    if report.get("missingQualificationEvidence") != []:
        errors.append("missing qualification evidence")
    for key in CONFIG_KEYS:
        if key not in metadata or metadata[key] in (None, "", "unrecorded"):
            if key != "opticalConfig":
                errors.append(f"missing metadata: {key}")
    if metadata.get("buildMode") not in ("profile", "release"):
        errors.append("debug or unknown build mode")
    if any(metadata.get(key) in ("inactive", "hidden", "paused")
           for key in ("lifecycleAtStart", "lifecycleAtEnd")):
        errors.append("inactive application")
    case = metadata.get("case", "")
    paths = set(metadata.get("activePathsDuringSampling", []))
    expected = ("capture" if case.startswith("capture") or case == "refraction"
                else "filter" if case == "filter" else "fallback" if case == "blur" else None)
    if expected and paths != {expected}:
        errors.append(f"expected only {expected} path, observed {sorted(paths)}")
    diagnostics = [report.get("captureAtSamplingStartObserved", {}),
                   report.get("captureAtEnd", {}), *report.get("captureEvents", [])]
    if any(d.get("captureFailures", 0) for d in diagnostics):
        errors.append("capture failures")
    if expected == "capture" and not report.get("captureAtEnd", {}).get("captureCount", 0):
        errors.append("no captured image evidence")
    statistics = {stage: distribution([f[field] for f in frames])
                  for stage, field in STAGES.items()}
    for stage, values in statistics.items():
        for key, expected_value in values.items():
            if not close(report.get(stage, {}).get(key), expected_value):
                errors.append(f"incorrect {stage}.{key}")
    refresh = report.get("refreshRateHz")
    budgets = {"reference120Hz": 8.33, "reference60Hz": 16.67}
    if isinstance(refresh, (int, float)) and refresh > 0:
        budgets["display"] = 1000 / refresh
        if not close(report.get("frameBudgetMs"), budgets["display"]):
            errors.append("incorrect display frame budget")
        if not close(metadata.get("refreshRateHz"), refresh):
            errors.append("inconsistent refresh rate metadata")
    else:
        errors.append("missing positive refresh rate")
    for name, budget in budgets.items():
        build = sum(f["buildUs"] / 1000 > budget for f in frames)
        raster = sum(f["rasterUs"] / 1000 > budget for f in frames)
        either = sum(max(f["buildUs"], f["rasterUs"]) / 1000 > budget for f in frames)
        expected_counts = {"budgetMs": budget, "build": build, "raster": raster,
                           "either": either, "eitherRate": either / len(frames) if frames else None}
        recorded = report.get("budgetExceedances", {}).get(name, {})
        if any(not close(recorded.get(k), v) for k, v in expected_counts.items()):
            errors.append(f"incorrect {name} budget exceedances")
    return {"valid": not errors, "errors": errors, "statistics": statistics,
            "sampleCount": len(frames)}


def validate_group(reports):
    checked = [validate_report(report) for report in reports]
    errors = []
    if len(reports) != 3 or sorted(r.get("repetition", 0) for r in reports) != [1, 2, 3]:
        errors.append("requires exactly repetitions 1, 2, 3")
    configurations = [{k: r.get("metadata", {}).get(k)
                       for k in (*CONFIG_KEYS, "benchmarkProtocolVersion", "requiredInitialSettleUs")}
                      for r in reports]
    if configurations and any(c != configurations[0] for c in configurations):
        errors.append("different configurations in repetition group")
    if len({r.get("scenario") for r in reports}) != 1:
        errors.append("different scenarios in repetition group")
    spread = {}
    for stage in STAGES:
        spread[stage] = {}
        for percentile, limit in (("p50Ms", 1.25), ("p99Ms", 1.5)):
            values = [r["statistics"].get(stage, {}).get(percentile) for r in checked]
            if not values or any(v is None for v in values):
                ratio = None
            else:
                low, high = min(values), max(values)
                ratio = high / low if low else (1.0 if high == 0 else None)
            stable = ratio is not None and ratio <= limit
            spread[stage][percentile] = {"maxMinRatio": ratio, "limit": limit, "stable": stable}
            if not stable:
                errors.append(f"unstable {stage}.{percentile}")
    return {"valid": not errors and all(r["valid"] for r in checked),
            "errors": errors, "runs": checked, "spread": spread}


def inside(root, relative):
    path = (root / relative).resolve()
    if not path.is_relative_to(root.resolve()):
        raise ValueError(f"Result path escapes selected directory: {relative}")
    return path


def analyze(root):
    index = json.loads((root / "index.json").read_text(encoding="utf-8-sig"))
    attempts = []
    for attempt in index["attempts"]:
        directory = inside(root, attempt["directory"])
        try:
            manifest = json.loads((directory / "matrix.json").read_text(encoding="utf-8-sig"))
            paths = [inside(directory, name) for name in manifest["results"]]
            reports = [json.loads(path.read_text(encoding="utf-8-sig")) for path in paths]
            result = validate_group(reports)
            result["rawSha256"] = {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}
            if not manifest.get("completed") or manifest.get("smokeOnly"):
                result["valid"] = False
                result["errors"].append("incomplete or smoke-only manifest")
            if any(r.get("scenario") != attempt["scenario"] for r in reports):
                result["valid"] = False
                result["errors"].append("manifest scenario mismatch")
            if attempt.get("exitCode") != 0 or not attempt.get("qualified"):
                result["valid"] = False
                result["errors"].append("runner or environment did not qualify attempt")
        except (OSError, ValueError, KeyError, TypeError) as error:
            result = {"valid": False, "errors": [str(error)]}
        attempts.append({"scenario": attempt["scenario"], "directory": attempt["directory"], **result})
    # The most recent attempt is authoritative; never select the best previous run.
    latest = {attempt["scenario"]: attempt for attempt in attempts}
    missing = [name for name in index["scenarios"] if name not in latest or not latest[name]["valid"]]
    return {"schemaVersion": 1, "complete": not missing and bool(index["scenarios"]),
            "scope": "scenarios selected in index.json; not an automatic full-matrix claim",
            "sourceHash": index["configuration"]["sourceHash"],
            "missingOrUnstableScenarios": missing, "attempts": attempts}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directory", type=Path)
    parser.add_argument("--group", action="store_true", help="Check one three-run matrix.json export")
    args = parser.parse_args()
    if args.group:
        manifest = json.loads((args.directory / "matrix.json").read_text(encoding="utf-8-sig"))
        paths = [inside(args.directory, name) for name in manifest["results"]]
        result = validate_group([json.loads(p.read_text(encoding="utf-8-sig")) for p in paths])
        result["complete"] = result["valid"] and manifest.get("completed") is True and not manifest.get("smokeOnly")
        result["rawSha256"] = {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}
    else:
        result = analyze(args.directory)
    (args.directory / "analysis.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(f"Independent analysis: complete={result['complete']}; "
          f"errors={len(result.get('errors', result.get('missingOrUnstableScenarios', [])))}")
    return 0 if result["complete"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
