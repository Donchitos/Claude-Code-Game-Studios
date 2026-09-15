"""Independent Python structural/bit-format oracle for WP04b artifacts."""
import copy, json, struct
from pathlib import Path
from jsonschema import Draft202012Validator, FormatChecker
from build_domain_schemas import definitions, wrap, ref
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'assets/schemas/steam'
checks=0
formats=FormatChecker()
@formats.checks('steam-f64')
def f64(value):
    if not isinstance(value,str) or len(value)!=16:return False
    try:
        number=struct.unpack('>d',bytes.fromhex(value))[0]
        return number==number and abs(number)!=float('inf') and value!='8000000000000000'
    except (ValueError,struct.error):return False

def check(condition,label):
    global checks
    checks+=1
    assert condition,label

def main():
    fixture=json.loads((ROOT/'tests/fixtures/steam/domains-fixture.json').read_text())
    for domain in ['records','progression','preparation','current_run','user_settings']:
        schema=json.loads((OUT/(domain+'-domain-v1.schema.json')).read_text())
        check(schema['$defs']==definitions(),domain+' stale generated definitions')
        Draft202012Validator.check_schema(schema)
        validator=Draft202012Validator(schema,format_checker=formats)
        good=fixture['domains'][domain]
        check(validator.is_valid(good),domain+' valid')
        for key in good['payload']:
            bad=copy.deepcopy(good);del bad['payload'][key]
            check(not validator.is_valid(bad),domain+' missing '+key)
        for badvalue in [None,{},[],True,3,3.0,'1']:
            check(not validator.is_valid(badvalue),domain+' invalid type')
        for value in ['-1','01','1.0',str(1<<63),'1\n',True,1]:
            if domain=='current_run':continue
            bad=copy.deepcopy(good);bad['payload']['domain_revision']=value
            check(not validator.is_valid(bad),domain+' bad u63')
        bad=copy.deepcopy(good);bad['payload']['extra']=None
        check(not validator.is_valid(bad),domain+' unknown field')
    r=json.loads((OUT/'records-domain-v1.schema.json').read_text())
    validator=Draft202012Validator(r,format_checker=formats)
    for bits in ['7ff0000000000000','fff0000000000000','7ff8000000000000','8000000000000000']:
        bad=copy.deepcopy(fixture['domains']['records']);bad['payload']['legacy_records']['best_seconds']=bits
        check(not validator.is_valid(bad),'nonfinite/negativezero')
    for path in (ROOT/'production/playtest-evidence/steam-domains-2026-09-11').glob('*.payload.json'):
        root=json.loads(path.read_text())
        for name in ['records','progression','preparation','current_run','user_settings']:
            schema=json.loads((OUT/(name+'-domain-v1.schema.json')).read_text())
            v=Draft202012Validator(schema,format_checker=formats)
            check(v.is_valid(root['domains'][name]),path.name+' '+name)
        run=root['domains']['current_run']['payload']['run']
        if run['terminal_intent']:
            after=run['terminal_intent']['complete_next_domains']
            check(set(after)==set(fixture['domains']) and after['current_run']['payload']['run'] is None,'nonrecursive complete after-image')
    print(f'DOMAIN_ARTIFACT_CHECK checks={checks} failures=0 structural_only=true')
if __name__=='__main__':main()
