import copy
import json
from pathlib import Path
import tempfile
import unittest

from analyze_matrix import CONFIG_KEYS, analyze, distribution, validate_group, validate_report


def sample():
    frames = [{"vsyncUs": 3_000_000 + i * 1_000_000, "buildUs": 1000,
               "rasterUs": 2000, "totalUs": 4000} for i in range(30)]
    metadata = dict.fromkeys(CONFIG_KEYS, "observed")
    metadata.update(buildMode="profile", case="ordinary", refreshRateHz=60,
                    benchmarkProtocolVersion=7, requiredInitialSettleUs=60_000_000,
                    appSessionAgeAtStartUs=70_000_000,
                    hudRefreshHz=0, idleHudRefreshHz=4,
                    opticalConfig=None, activePathsDuringSampling=[],
                    lifecycleAtStart="resumed", lifecycleAtEnd="resumed")
    return {"metadata": metadata, "frames": frames, "sampleCount": 30,
            "samplingStartVsyncUs": 3_000_000, "samplingEndVsyncUs": 33_000_000,
            "warmupUs": 3_000_000, "complete": True, "measurementComplete": True,
            "qualifiedMeasurement": True, "missingQualificationEvidence": [],
            "stopReason": "duration", "capacityReached": False,
            "refreshRateHz": 60, "frameBudgetMs": 1000 / 60,
            "build": distribution([1000] * 30), "raster": distribution([2000] * 30),
            "totalSpan": distribution([4000] * 30), "scenario": "ordinary-1-compact-static",
            "repetition": 1, "budgetExceedances": {
                key: {"budgetMs": budget, "build": 0, "raster": 0, "either": 0, "eitherRate": 0}
                for key, budget in (("reference120Hz", 8.33), ("reference60Hz", 16.67),
                                    ("display", 1000 / 60))}}


class RawValidationTest(unittest.TestCase):
    def test_dart_rounding_and_microseconds(self):
        self.assertEqual(distribution([1000, 2000])["p50Ms"], 2)

    def test_independently_accepts_matching_raw_statistics(self):
        self.assertTrue(validate_report(sample())["valid"])

    def test_rejects_forged_summary_even_if_qualified(self):
        report = sample()
        report["raster"]["p99Ms"] = 1
        self.assertIn("incorrect raster.p99Ms", validate_report(report)["errors"])

    def test_rejects_forged_budget_count(self):
        report = sample()
        report["budgetExceedances"]["display"]["either"] = 1
        self.assertFalse(validate_report(report)["valid"])

    def test_rejects_timestamp_outside_window(self):
        report = sample()
        report["frames"][0]["vsyncUs"] = 0
        self.assertIn("raw frame outside measurement window", validate_report(report)["errors"])

    def test_rejects_duplicates_and_partial_windows(self):
        report = sample()
        report["frames"][1]["vsyncUs"] = report["frames"][0]["vsyncUs"]
        self.assertFalse(validate_report(report)["valid"])
        report = sample()
        report["samplingEndVsyncUs"] -= 1
        self.assertFalse(validate_report(report)["valid"])

    def test_rejects_unexpected_fallback(self):
        report = sample()
        report["metadata"].update(case="captureBalanced", activePathsDuringSampling=["fallback"])
        self.assertFalse(validate_report(report)["valid"])

    def test_rejects_unsettled_current_protocols_even_if_application_claims_qualified(self):
        for protocol in (6, 7):
            with self.subTest(protocol=protocol):
                report = sample()
                report["metadata"]["benchmarkProtocolVersion"] = protocol
                report["metadata"]["appSessionAgeAtStartUs"] = 59_999_999
                self.assertIn("application session did not complete initial settling",
                              validate_report(report)["errors"])

    def test_preserves_legacy_protocol_six_validation(self):
        report = sample()
        report["metadata"]["benchmarkProtocolVersion"] = 6
        report["metadata"]["hudRefreshHz"] = 4
        report["metadata"].pop("idleHudRefreshHz")
        self.assertTrue(validate_report(report)["valid"])

    def test_rejects_unfrozen_or_missing_protocol_seven_display_policy(self):
        for cadence in (4, None, False):
            with self.subTest(cadence=cadence):
                report = sample()
                report["metadata"]["hudRefreshHz"] = cadence
                self.assertIn("measurement display was not frozen",
                              validate_report(report)["errors"])
        report = sample()
        report["metadata"].pop("idleHudRefreshHz")
        self.assertIn("missing idle display cadence", validate_report(report)["errors"])

    def test_rejects_unknown_protocol_instead_of_bypassing_policy(self):
        report = sample()
        report["metadata"]["benchmarkProtocolVersion"] = 999
        self.assertIn("unknown benchmark protocol", validate_report(report)["errors"])

    def test_cannot_mix_display_workloads_in_a_repetition_group(self):
        reports = [sample() for _ in range(3)]
        for repetition, report in enumerate(reports, 1):
            report["repetition"] = repetition
            report["metadata"]["benchmarkProtocolVersion"] = 6
            report["metadata"]["hudRefreshHz"] = 4
            report["metadata"].pop("idleHudRefreshHz")
        reports[1]["metadata"]["hudRefreshHz"] = 0
        self.assertIn("different configurations in repetition group",
                      validate_group(reports)["errors"])

    def test_rejects_historical_reports_relabelled_by_a_current_manifest(self):
        reports = [sample() for _ in range(3)]
        for repetition, report in enumerate(reports, 1):
            report["repetition"] = repetition
            report["metadata"]["benchmarkProtocolVersion"] = 6
            report["metadata"]["hudRefreshHz"] = 4
            report["metadata"].pop("idleHudRefreshHz")
        self.assertTrue(validate_group(reports, protocols=(6, None))["valid"])
        self.assertIn("result protocol does not match manifest or runner",
                      validate_group(reports, protocols=(7, 7))["errors"])

    def test_rejects_focus_loss_even_if_application_claims_qualified(self):
        report = sample()
        report["metadata"]["lifecycleAtEnd"] = "inactive"
        self.assertIn("inactive application", validate_report(report)["errors"])

    def test_requires_three_identical_distinct_repetitions(self):
        reports = [sample() for _ in range(3)]
        for repetition, report in enumerate(reports, 1):
            report["repetition"] = repetition
        self.assertTrue(validate_group(reports)["valid"])
        changed = copy.deepcopy(reports)
        changed[1]["metadata"]["gpu"] = "other"
        self.assertFalse(validate_group(changed)["valid"])
        reports[1]["repetition"] = 1
        self.assertFalse(validate_group(reports)["valid"])

    def test_keeps_unstable_runs_instead_of_picking_best(self):
        reports = [sample() for _ in range(3)]
        for repetition, report in enumerate(reports, 1):
            report["repetition"] = repetition
        reports[2]["frames"] = [{**f, "buildUs": 2000} for f in reports[2]["frames"]]
        reports[2]["build"] = distribution([2000] * 30)
        checked = validate_group(reports)
        self.assertFalse(checked["valid"])
        self.assertEqual(len(checked["runs"]), 3)
        self.assertIn("unstable build.p50Ms", checked["errors"])

    def test_latest_rejected_attempt_cannot_reuse_an_older_accepted_group(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            scenario = sample()["scenario"]
            attempts = []
            for number in (1, 2):
                group = root / f"attempt-{number}"
                group.mkdir()
                files = []
                for repetition in (1, 2, 3):
                    report = sample()
                    report["repetition"] = repetition
                    name = f"run-{repetition}.json"
                    (group / name).write_text(json.dumps(report), encoding="utf-8")
                    files.append(name)
                (group / "matrix.json").write_text(json.dumps({
                    "completed": True, "results": files}), encoding="utf-8")
                attempts.append({"scenario": scenario, "directory": group.name,
                                 "qualified": number == 1,
                                 "exitCode": 0 if number == 1 else 1})
            (root / "index.json").write_text(json.dumps({
                "configuration": {"sourceHash": "test-source"},
                "scenarios": [scenario], "attempts": attempts}), encoding="utf-8")
            checked = analyze(root)
            self.assertTrue(checked["attempts"][0]["valid"])
            self.assertFalse(checked["attempts"][1]["valid"])
            self.assertFalse(checked["complete"])
            self.assertEqual(checked["missingOrUnstableScenarios"], [scenario])


if __name__ == "__main__":
    unittest.main()
