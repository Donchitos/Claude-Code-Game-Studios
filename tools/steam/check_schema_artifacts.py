"""Independent JSON Schema shape/boundary checks; requires jsonschema 4.x."""
import copy
import json
import re
from pathlib import Path
from jsonschema import Draft202012Validator
from build_schemas import schemas

ROOT = Path(__file__).resolve().parents[2]
checks = 0


def check(condition, label):
    global checks
    checks += 1
    assert condition, label


def main():
    fixture = json.loads((ROOT / 'tests/fixtures/steam/campaign-fixture.json').read_text())
    gd = (ROOT / 'src/data/steam_campaign_schema.gd').read_text()
    shapes = {}
    for name, expected in schemas():
        path = ROOT / 'assets/schemas/steam' / (name + '.schema.json')
        schema = json.loads(path.read_text())
        check(schema == expected, 'generated schema drift: ' + name)
        Draft202012Validator.check_schema(schema)
        shapes[name] = Draft202012Validator(schema)
        pattern = schema['$defs']['u63']['pattern']
        for value in ['0', '9', '9007199254740993', str(2**63-2), str(2**63-1)]:
            check(re.search(pattern, value) is not None, 'u63 valid ' + value)
        for value in ['', '01', '+1', '-1', '1.0', '1e3', '1\n', str(2**63), '9'*19, '9'*20, '１２']:
            check(re.search(pattern, value) is None, 'u63 invalid ' + repr(value))
    definition_shape = shapes['campaign-definition-v1'].schema
    for constant, properties in [('DEFINITION_FIELDS', definition_shape['properties']),
                                 ('ROW_FIELDS', definition_shape['properties']['missions']['items']['properties'])]:
        fields = json.loads(re.search(r'const ' + constant + r' := (\[[^\n]+)', gd).group(1))
        check(set(fields) == set(properties), 'GDScript/schema shape ' + constant)
    validator = shapes['campaign-definition-v1']
    check(validator.is_valid(fixture['definition']), '64-row synthetic definition shape')
    for field in fixture['definition']:
        bad = copy.deepcopy(fixture['definition']); del bad[field]
        check(not validator.is_valid(bad), 'required definition field ' + field)
    bad = copy.deepcopy(fixture['definition']); bad['missions'][0]['extra'] = True
    check(not validator.is_valid(bad), 'unknown row field')
    bad = copy.deepcopy(fixture['definition']); bad['missions'][0]['ordinal'] = 1
    check(not validator.is_valid(bad), 'native numeric ordinal')
    for name, payload, constant in [
        ('campaign-domain-v1', {'schema': '1', 'domain_revision': '0', 'completed_mission_ids': [], 'ending_seen': False}, 'CAMPAIGN_FIELDS'),
        ('unlock-domain-v1', {'schema': '1', 'domain_revision': '0', 'unlocked_content_ids': []}, 'UNLOCK_FIELDS')]:
        validator = shapes[name]
        wrapper = {'schema': '1', 'payload': payload}
        check(validator.is_valid(wrapper), 'valid wrapper ' + name)
        check(not validator.is_valid(None), 'null wrapper')
        bad = copy.deepcopy(wrapper); bad['extra'] = None
        check(not validator.is_valid(bad), 'unknown wrapper field')
        bad = copy.deepcopy(wrapper); bad['payload']['domain_revision'] = str(2**63)
        check(not validator.is_valid(bad), 'overflow domain revision')
        fields = json.loads(re.search(r'const ' + constant + r' := (\[[^\n]+)', gd).group(1))
        shape = validator.schema['properties']['payload']
        check(set(fields) == set(payload) == set(shape['properties']) == set(shape['required']), 'GDScript/schema properties+required')
    result = {'status': 'PASS', 'checks': checks, 'scope': 'STRUCTURE_AND_BOUNDARIES_ONLY',
              'production_enabled': False, 'fixture_kind': 'SYNTHETIC_NOT_GAME_CONTENT'}
    print(json.dumps(result, sort_keys=True))


if __name__ == '__main__':
    main()
