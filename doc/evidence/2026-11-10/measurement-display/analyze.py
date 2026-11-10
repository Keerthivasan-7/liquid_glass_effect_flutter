from pathlib import Path
import bisect
import collections
import json
import statistics

root = Path(__file__).resolve().parent
results = []
for variant in ('bounded-baseline', 'bounded-implemented'):
    data = json.loads((root / variant / 'profile.json').read_text())
    events = data['timeline']['traceEvents']
    report = data['benchmark']
    start, end = report['samplingStartVsyncUs'], report['samplingEndVsyncUs']
    marks = sorted(e['ts'] for e in events if e.get('name') == 'benchmark.HUD.refresh'
                   and e.get('args', {}).get('active') is True and start <= e['ts'] < end)
    stacks = collections.defaultdict(list)
    builds = []
    for event in events:
        if event.get('name') != 'BUILD':
            continue
        key = event['tid']
        if event['ph'] == 'B':
            stacks[key].append(event['ts'])
        elif event['ph'] == 'E' and stacks[key]:
            began = stacks[key].pop()
            if start <= began < event['ts'] <= end:
                builds.append((began, event['ts'] - began))
    near, other = [], []
    first_after = []
    build_starts = [b[0] for b in builds]
    for marker in marks:
        index = bisect.bisect_left(build_starts, marker)
        if index < len(builds) and builds[index][0] - marker < 20000:
            first_after.append(builds[index][1])
    for timestamp, duration in builds:
        before = bisect.bisect_right(marks, timestamp) - 1
        (near if before >= 0 and timestamp - marks[before] < 20000 else other).append(duration)
    def describe(values):
        return {'count': len(values), 'medianUs': statistics.median(values) if values else None,
                'maxUs': max(values) if values else None}
    results.append({'variant': variant, 'completed': data['completed'],
        'profileFreezeHud': data['profileFreezeHud'],
        'retainedTraceRangeUs': [min(e.get('ts', 10**30) for e in events), max(e.get('ts', 0) for e in events)],
        'measurementRangeUs': [start, end], 'hudMarkersInsideRetainedMeasurement': len(marks),
        'frameworkBuildsAfterHudMarkerWithin20ms': describe(near),
        'firstFrameworkBuildAfterEachHudMarker': describe(first_after),
        'frameworkBuildsWithoutRecentHudMarker': describe(other),
        'frameTimingBuild': report['build'], 'frameTimingRaster': report['raster'],
        'rawSamples': report['sampleCount'],
        'limits': 'Bounded two-second diagnostic inside the measured window. Tracing overhead; not phone performance or a qualified matrix.'})
print(json.dumps(results, indent=2))
(root / 'analysis.json').write_text(json.dumps(results, indent=2) + '\n')
