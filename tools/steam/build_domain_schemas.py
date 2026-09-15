"""ADR-0006 WP04b strict five-domain structural contracts.
Owner/catalog, conservation and operation semantics also require runtime validation.
"""
import json
from pathlib import Path
from build_schemas import obj, ref, array, u63_pattern, END
ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'assets/schemas/steam'
U = ref('u63'); H = ref('hex64'); I = ref('id'); B = {'type': 'boolean'}
def enum(*values): return {'enum': list(values)}
def nullable(shape): return {'anyOf': [{'type': 'null'}, shape]}
def record(**fields): return obj(fields)
def versioned(**fields): return record(schema={'const': '1'}, domain_revision=U, **fields)
def wrap(payload): return record(schema={'const': '1'}, payload=payload)
def definitions():
    defs = {'u63': {'type': 'string', 'pattern': u63_pattern()},
            'hex64': {'type': 'string', 'pattern': r'^[0-9a-f]{64}' + END},
            'hex32': {'type': 'string', 'pattern': r'^[0-9a-f]{32}' + END},
            'bits64': {'type': 'string', 'pattern': r'^[0-9a-f]{16}' + END},
            'f64': {'type': 'string', 'pattern': r'^[0-9a-f]{16}' + END, 'format': 'steam-f64'},
            'id': {'type': 'string', 'minLength': 1, 'pattern': r'^[\x01-\x7f]+' + END}}
    defs['legacy_records'] = record(total_runs=U, victories=U, best_level=U, best_kills=U, best_seconds=ref('f64'))
    defs['economy'] = record(unspent=U, earned=U, spent=U)
    defs['records'] = versioned(content_revision=U, legacy_records=ref('legacy_records'),
        mission_records=record(completed_runs=U, victories=U, defeats=U, abandoned=U, technical_aborts=U, total_kills=U),
        spirit_stones=ref('economy'), core_herb_count=U)
    receipt = dict(purchase_id=U, branch_id=enum('QINGYUAN','LONGCHUN','DAYAN'), from_level=U, to_level=U, cost_pages=U, balance_before=U, balance_after=U)
    defs['purchase_receipt'] = {'anyOf': [record(kind={'const':'LEGACY_V1'}, **receipt), record(kind={'const':'V2'}, **receipt,
        base_domain_revision=U, next_domain_revision=U, request_hash=H)]}
    defs['progression'] = versioned(content_revision=U, unspent_pages=U, earned_pages_total=U, spent_pages_total=U,
        upgrade_sequence=U, next_purchase_id=U, branch_levels=record(QINGYUAN=enum(*map(str,range(6))), LONGCHUN=enum(*map(str,range(6))), DAYAN=enum(*map(str,range(6)))), last_purchase_receipt=nullable(ref('purchase_receipt')))
    defs['selection'] = {'anyOf':[record(kind={'const':'NO_PILL'}),record(kind={'const':'PILL'}, seed_id=I, recipe_id=I)]}
    defs['prep_receipt'] = record(preparation_id=U, run_seq=U, selection=ref('selection'), source_content_hash=H,
        create_operation_id=ref('hex32'), create_request_hash=H)
    defs['reservation'] = record(receipt=ref('prep_receipt'), state=enum('RESERVED','CONSUMED'), recovery_revision=U)
    defs['preparation'] = versioned(content_revision=U, next_preparation_id=U,
        seed_ledgers=array(record(seed_id=I, available=U, reserved=U, consumed=U, earned=U)),
        legacy_starter_claimed=B, applied_campaign_grant_ids=array(I, uniqueItems=True),
        active_reservation=nullable(ref('reservation')),
        last_resolution=nullable(record(preparation_id=U, run_seq=U, outcome=enum('CANCELLED','CONSUMED'), operation_id=ref('hex32'))))
    defs['user_settings'] = versioned(content_revision=U,
        volume_percent=record(**{k:enum(*map(str,range(101))) for k in ['master','music','sfx','ui']}),
        font_scale_id=enum('100','115','130'), reduce_motion=B, reduce_sensory_load=B, high_contrast=B, screen_reader_hints=B, locale_id=I)
    defs['offer_row'] = record(candidate_id=I, skill_id=I, rank=U)
    defs['loadout_row'] = record(skill_id=I, rank=U)
    defs['preparation_checkpoint'] = record(preparation_id=U, run_seq=U, revision=U, offer_revision=U,
        offer_rows=array(ref('offer_row')), offer_hash=nullable(H), refresh_used=U, refresh_remaining=U,
        selected_candidate_id=nullable(I), choice_command_id=nullable(ref('hex32')),
        loadout_rows=array(ref('loadout_row')), loadout_hash=H,
        rng=record(algorithm_id=I, version=I, seed=ref('bits64'), state=ref('bits64'), cursor=U),
        handoff_revision=U)
    # Dynamic owner payloads are closed by the required-owner registry, never a default {}.
    defs['owner_snapshot'] = record(owner_id=I, schema=U, revision=U, payload={'type':'object'})
    defs['checkpoint'] = record(checkpoint_seq=U, active_tick=U, owner_snapshots=array(ref('owner_snapshot')))
    defs['result'] = record(schema={'const':'1'},profile_id=ref('hex32'),branch_id=ref('hex32'),run_seq=U,mission_id=I,
        mission_definition_hash=H,terminal_tick=U,result_kind=enum('VICTORY','DEFEAT','ABANDONED','TECHNICAL_ABORT'),reason=I,objective_progress_hash=H)
    defs['terminal_intent'] = record(sealed_result=ref('result'), result_hash=H, complete_operation_id=ref('hex32'),
        complete_base_revision=U,complete_request_hash=H,complete_next_domains={'type':'object'})
    defs['run'] = record(run_seq=U,mission_id=I,run_status=enum('PREPARED','RUNNING','SUSPENDED','RESULT_PENDING'),
        mission_definition_hash=H,config_hash=H,seed=ref('bits64'),prep_receipt=ref('prep_receipt'),
        preparation_checkpoint=ref('preparation_checkpoint'),checkpoint=nullable(ref('checkpoint')),terminal_intent=nullable(ref('terminal_intent')))
    defs['current_run'] = record(run=nullable(ref('run')))
    return defs

def main():
    defs=definitions()
    for domain in ['records','progression','preparation','current_run','user_settings']:
        schema={'$schema':'https://json-schema.org/draft/2020-12/schema','$id':'urn:xiuxian:steam:'+domain+'-domain-v1',
            '$comment':'Structural only; owner registry, exact content, cross-domain semantics and admission gates are mandatory.', '$defs':defs, **wrap(ref(domain))}
        (OUT/(domain+'-domain-v1.schema.json')).write_text(json.dumps(schema,indent=2)+'\n')
    print('DOMAIN_SCHEMAS_WRITTEN count=5 structural_only=true')
if __name__=='__main__': main()
