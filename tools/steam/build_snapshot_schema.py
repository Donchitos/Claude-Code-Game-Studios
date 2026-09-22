"""Generate structural snapshot schema from Godot's exported closed descriptor."""
import json
from pathlib import Path
from build_domain_schemas import definitions, record, array
ROOT=Path(__file__).resolve().parents[2]
EVIDENCE=ROOT/'production/playtest-evidence/steam-domains-2026-09-11'
def translate(shape):
    if isinstance(shape,str):
        if shape=='string':return {'type':'string'}
        if shape=='bool':return {'type':'boolean'}
        if shape=='vec2':return array({'$ref':'#/$defs/f64'},minItems=2,maxItems=2)
        return {'$ref':'#/$defs/'+ ('f64' if shape=='f32' else shape)}
    if '$array' in shape:return array(translate(shape['$array']),maxItems=shape['$max'])
    return record(**{k:translate(v) for k,v in shape.items()})
def main():
    descriptor=json.loads((EVIDENCE/'snapshot-shape.json').read_text())
    sample=json.loads((EVIDENCE/'snapshot-full.json').read_text())
    shape=translate(descriptor)
    for key in ['profile','engine','config_hash']:shape['properties'][key]={'const':sample[key]}
    defs=definitions()
    schema={'$schema':'https://json-schema.org/draft/2020-12/schema','$id':'urn:xiuxian:steam:legacy-battle-snapshot-v1',
        '$comment':'Generated for exact current default config/build. Structure only; SteamBattleSnapshot validates finite real_t readback, causal state, references, build, barrier and owner admission.',
        '$defs':{k:defs[k] for k in ['u63','f64','bits64']},**shape}
    (ROOT/'assets/schemas/steam/legacy-battle-snapshot-v1.schema.json').write_text(json.dumps(schema,indent=2)+'\n')
    from check_domain_artifacts import formats
    from jsonschema import Draft202012Validator
    validator=Draft202012Validator(schema,format_checker=formats)
    count=0
    for name in ['full','ring','summon','bite','phase_pending']:
        value=json.loads((EVIDENCE/f'snapshot-{name}.json').read_text())
        validator.validate(value);count+=1
    print(f'SNAPSHOT_SCHEMA_CHECK cases={count} structural_only=true')
if __name__=='__main__':main()
