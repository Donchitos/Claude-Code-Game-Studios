"""Deterministic independent oracle fixtures; never emits production content or saves."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'tests/fixtures/steam'


def canonical(value):
    # Python reference encoder: control characters are explicitly canonicalized.
    def quote(s):
        return '"' + ''.join('\\u%04x' % ord(c) if ord(c) < 32 else '\\' + c if c in '"\\' else c for c in s) + '"'
    if value is None:
        return 'null'
    if type(value) is bool:
        return 'true' if value else 'false'
    if isinstance(value, str):
        return quote(value)
    if isinstance(value, list):
        return '[' + ','.join(canonical(x) for x in value) + ']'
    if isinstance(value, dict):
        return '{' + ','.join(quote(k) + ':' + canonical(value[k]) for k in sorted(value)) + '}'
    raise TypeError('native numbers forbidden')


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    vectors = [None, True, False, [], {}, {'quote': '"\\/\n\t\x01', 'unicode': '任务😀'},
               {'order': ['B', 'A', 'C'], 'u63': '9223372036854775807'},
               {'a': {'b': ['9007199254740993', '3ff0000000000000']}},
               {'z': {'later': False, 'earlier': True}, 'a': ['B', 'A']}]
    golden = [{'value': v, 'canonical': canonical(v), 'sha256': hashlib.sha256(canonical(v).encode()).hexdigest()} for v in vectors]
    rows = []
    hashes = {}
    previous = None
    for ordinal in range(1, 65):
        chapter = (ordinal - 1) // 8 + 1
        mid = f'S1-M{chapter:02}-{(ordinal - 1) % 8 + 1:02}'
        # Deliberately synthetic definition hash: NOT a generated MissionDefinition.
        digest = hashlib.sha256(('TEST-ONLY:' + mid).encode()).hexdigest()
        hashes[mid] = digest
        rows.append(dict(mission_id=mid, chapter_id=f'S1-CH{chapter:02}', ordinal=str(ordinal),
                         prerequisite_id_or_null=previous, mission_definition_hash=digest,
                         first_grants=['TEST-FIRST'] if ordinal == 1 else ['TEST-PREP'] if ordinal == 3 else []))
        previous = mid
    chash = hashlib.sha256(b'SYNTHETIC-CATALOG-NOT-PRODUCTION').hexdigest()
    fixture = {'fixture_only': True, 'definition': {'schema': '1', 'content_revision': '1', 'content_hash': chash, 'missions': rows},
               'catalog': {'content_revision': '1', 'content_hash': chash, 'mission_hashes': hashes,
                           'unlock_ids': ['TEST-FIRST', 'TEST-PREP', 'TEST-START'],
                           'initial_unlock_ids': ['TEST-START'], 'prep_unlock_ids': ['TEST-PREP']}}
    for name, data in [('codec-golden.json', golden), ('campaign-fixture.json', fixture)]:
        (OUT / name).write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
    print(f'FIXTURES_WRITTEN golden={len(golden)} synthetic_missions=64 production_content=false')


if __name__ == '__main__':
    main()
