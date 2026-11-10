"""Look for measurement-UI cadence in the unchanged physical baseline."""
import json
import math
from pathlib import Path
import statistics

root = Path(__file__).resolve().parent
folder = root.parent / 'performance-physical-current'
summary = json.loads((folder / 'summary.json').read_text())
results = []
for count in (1, 4, 10):
    scenario = f'ordinary-{count}-compact-static'
    group = next(g for g in summary['groups'] if g['scenario'] == scenario)
    for filename in group['rawSha256']:
        raw = folder / scenario / f"attempt-{group['attempt']}" / filename
        report = json.loads(raw.read_text())
        frames = report['frames']
        slow = [f for f in frames if f['buildUs'] > 8330]
        gaps = [(b['vsyncUs'] - a['vsyncUs']) / 1000 for a, b in zip(slow, slow[1:])]
        phases = [(f['vsyncUs'] % 250000) / 250000 * math.tau for f in slow]
        coherence = abs(sum(complex(math.cos(p), math.sin(p)) for p in phases)) / len(phases) if phases else None
        results.append({'scenario': scenario, 'repetition': report['repetition'],
            'frames': len(frames), 'buildOver8_33ms': len(slow),
            'expectedFourHzUpdates': report['requestedDurationUs'] / 250000,
            'medianSlowFrameGapMs': statistics.median(gaps) if gaps else None,
            'fourHzPhaseCoherence': coherence})
output = root / 'phone-pulse-analysis.json'
output.write_text(json.dumps({'scope': 'Correlation only; no causal attribution without a trace.', 'runs': results}, indent=2) + '\n')
print(json.dumps(results, indent=2))
