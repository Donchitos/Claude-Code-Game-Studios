#!/usr/bin/env python3
"""Independent footprint/path checks for generated chapter-one layouts."""
import json
import sys
import math
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def segment_distance(p, a, b):
    dx, dy = b[0] - a[0], b[1] - a[1]
    t = max(0, min(1, ((p[0] - a[0]) * dx + (p[1] - a[1]) * dy) / (dx * dx + dy * dy))) if dx or dy else 0
    return math.dist(p, (a[0] + dx * t, a[1] + dy * t))


def clear(a, b, rocks, radius=25):
    return all(segment_distance((r['x'], r['y']), a, b) > r['radius'] + radius for r in rocks)


def reachable(start, target, rocks):
    grid = [(x, y) for x in range(-900, 901, 25) for y in range(-575, 576, 25)]
    allowed = {p for p in grid if clear(p, p, rocks)}
    origin = min(allowed, key=lambda p: math.dist(start, p))
    assert clear(start, origin, rocks)
    todo, seen = deque([origin]), {origin}
    while todo:
        p = todo.popleft()
        if math.dist(p, target) <= 40 and clear(p, target, rocks):
            return True
        for dx, dy in [(25,0),(-25,0),(0,25),(0,-25)]:
            q = (p[0]+dx, p[1]+dy)
            if q in allowed and q not in seen and clear(p, q, rocks):
                seen.add(q)
                todo.append(q)
    return False


def main():
    data = json.loads((ROOT / 'assets/config/campaign_game.json').read_text())
    scenes = {s['id']:s for s in data['scenes']}
    checks = 0
    chapter = 3 if '--chapter-three' in sys.argv else 2 if '--chapter-two' in sys.argv else 1
    missions = data['missions'][24:] if '--late-chapters' in sys.argv else data['missions'][(chapter-1)*8:chapter*8]
    if '--late-chapters' in sys.argv: chapter = '4_TO_8'
    for m in missions:
        layout = scenes[m['scene_layout_id']]['layout']
        for target in m['target_positions'] + m.get('clues', []):
            assert reachable(layout['start'], target, layout['obstacles']), (m['id'], target)
            checks += 1
        if m.get('clues'):
            route = [layout['start']] + m['clues']
            for a,b in zip(route,route[1:]):
                assert clear(a,b,layout['obstacles']), ('clue trail',a,b)
                checks += 1
        if m['kind'] == 'ESCORT':
            route = [layout['start']] + m['target_positions']
            for a,b in zip(route,route[1:]):
                assert clear(a,b,layout['obstacles']), ('escort segment',a,b)
                checks += 1
    print(f'CHAPTER_{chapter}_ROUTES_PASS checks={checks} radius=25 swept_segments=true')


if __name__ == '__main__':
    main()
