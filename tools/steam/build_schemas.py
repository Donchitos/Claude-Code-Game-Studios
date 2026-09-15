"""Build portable Draft 2020-12 structural schemas for the implemented domains.
Semantic graph/hash/atomic grant checks remain in SteamCampaignSchema.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'assets/schemas/steam'
END = r'$(?![\s\S])'  # Python/ECMAScript strict end, including final newlines.


def u63_pattern():
    maximum = str((1 << 63) - 1)
    patterns = ['0', r'[1-9][0-9]{0,17}', maximum]
    for i, ch in enumerate(maximum):
        lower = 1 if i == 0 else 0
        upper = int(ch) - 1
        if upper >= lower:
            digit = str(lower) if lower == upper else f'[{lower}-{upper}]'
            patterns.append(maximum[:i] + digit + f'[0-9]{{{18-i}}}')
    return '^(?:' + '|'.join(patterns) + ')' + END


def obj(properties):
    return {'type': 'object', 'properties': properties, 'required': list(properties), 'additionalProperties': False}


def ref(name):
    return {'$ref': '#/$defs/' + name}


def array(items, **bounds):
    return {'type': 'array', 'items': items, **bounds}


def schemas():
    defs = {'u63': {'type': 'string', 'pattern': u63_pattern()},
            'hex64': {'type': 'string', 'pattern': r'^[0-9a-f]{64}' + END},
            'id': {'type': 'string', 'minLength': 1, 'pattern': r'^[\x00-\x7f]+' + END}}
    campaign = obj({'schema': {'const': '1'}, 'domain_revision': ref('u63'),
                    'completed_mission_ids': array(ref('id'), uniqueItems=True, maxItems=64), 'ending_seen': {'type': 'boolean'}})
    unlocks = obj({'schema': {'const': '1'}, 'domain_revision': ref('u63'),
                   'unlocked_content_ids': array(ref('id'), uniqueItems=True)})
    row = obj({'mission_id': ref('id'), 'chapter_id': ref('id'), 'ordinal': ref('u63'),
               'prerequisite_id_or_null': {'anyOf': [ref('id'), {'type': 'null'}]},
               'mission_definition_hash': ref('hex64'), 'first_grants': array(ref('id'), uniqueItems=True)})
    definition = obj({'schema': {'const': '1'}, 'content_revision': ref('u63'), 'content_hash': ref('hex64'),
                      'missions': array(row, minItems=64, maxItems=64)})
    for name, shape in [('campaign-domain-v1', obj({'schema': {'const': '1'}, 'payload': campaign})),
                        ('unlock-domain-v1', obj({'schema': {'const': '1'}, 'payload': unlocks})),
                        ('campaign-definition-v1', definition)]:
        yield name, {'$schema': 'https://json-schema.org/draft/2020-12/schema',
                     '$id': 'urn:xiuxian:steam:' + name,
                     '$comment': 'Structural only. Must also pass SteamCampaignSchema semantics and production admission gates.',
                     '$defs': defs, **shape}


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for name, data in schemas():
        (OUT / (name + '.schema.json')).write_text(json.dumps(data, indent=2) + '\n')
    print('SCHEMAS_WRITTEN count=3 structural_only=true')


if __name__ == '__main__':
    main()
