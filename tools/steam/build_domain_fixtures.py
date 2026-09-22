"""Synthetic owner/campaign fixture; never commercial configuration/content."""
import json, struct, hashlib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
def canonical(v): return json.dumps(v,ensure_ascii=False,sort_keys=True,separators=(',',':'))
def hash_value(v): return hashlib.sha256(canonical(v).encode()).hexdigest()
def wrap(p): return {'schema':'1','payload':p}
def payload(**fields): return dict(schema='1',domain_revision='0',content_revision='1',**fields)
def build():
    source=json.loads((ROOT/'tests/fixtures/steam/campaign-fixture.json').read_text())
    domains={
      'campaign':wrap({'schema':'1','domain_revision':'0','completed_mission_ids':[],'ending_seen':False}),
      'unlocks':wrap({'schema':'1','domain_revision':'0','unlocked_content_ids':['TEST-START']}),
      'records':wrap(payload(legacy_records=dict(total_runs='0',victories='0',best_level='0',best_kills='0',best_seconds='0000000000000000'),
          mission_records={k:'0' for k in ['completed_runs','victories','defeats','abandoned','technical_aborts','total_kills']},
          spirit_stones=dict(unspent='0',earned='0',spent='0'),core_herb_count='0')),
      'progression':wrap(payload(unspent_pages='0',earned_pages_total='0',spent_pages_total='0',upgrade_sequence='0',next_purchase_id='1',
          branch_levels=dict(QINGYUAN='0',LONGCHUN='0',DAYAN='0'),last_purchase_receipt=None)),
      'preparation':wrap(payload(next_preparation_id='1',seed_ledgers=[dict(seed_id=k,available='0',reserved='0',consumed='0',earned='0') for k in ['TEST-SEED-A','TEST-SEED-B','TEST-SEED-C']],legacy_starter_claimed=False,applied_campaign_grant_ids=[],active_reservation=None,last_resolution=None)),
      'user_settings':wrap(payload(volume_percent={k:'100' for k in ['master','music','sfx','ui']},font_scale_id='100',reduce_motion=False,reduce_sensory_load=False,high_contrast=False,screen_reader_hints=False,locale_id='zh-CN')),
      'current_run':wrap(dict(run=None))}
    context=dict(content_revision='1',config_hash='c'*64,seed_caps={k:'999' for k in ['TEST-SEED-A','TEST-SEED-B','TEST-SEED-C']},recipe_seeds={'TEST-RECIPE-A':'TEST-SEED-A'},locale_ids=['en','zh-CN'],offer_max=3,loadout_max=8,refresh_max=2,required_owner_ids=['LEGACY_STAGE'],mission_hashes=source['catalog']['mission_hashes'])
    root=dict(profile_id='1'*32,branch_id='2'*32,revision='1',resolved_run_seq='0',next_run_seq='2',operation_id='3'*32)
    receipt=dict(preparation_id='1',run_seq='1',selection=dict(kind='NO_PILL'),source_content_hash='c'*64,create_operation_id='4'*32,create_request_hash='d'*64)
    checkpoint=dict(preparation_id='1',run_seq='1',revision='0',offer_revision='0',offer_rows=[],offer_hash=None,refresh_used='0',refresh_remaining='2',selected_candidate_id=None,choice_command_id=None,loadout_rows=[],loadout_hash=hash_value([]),rng=dict(algorithm_id='TEST-RNG',version='1',seed='ffffffffffffffff',state='abcdef0123456789',cursor='0'),handoff_revision='0')
    run=dict(run_seq='1',mission_id='S1-M01-01',run_status='PREPARED',mission_definition_hash=context['mission_hashes']['S1-M01-01'],config_hash='c'*64,seed='ffffffffffffffff',prep_receipt=receipt,preparation_checkpoint=checkpoint,checkpoint=None,terminal_intent=None)
    return dict(domains=domains,context=context,root=root,prepared_run=run)
if __name__=='__main__':
    data=build();(ROOT/'tests/fixtures/steam/domains-fixture.json').write_text(json.dumps(data,indent=2)+'\n')
    print('DOMAIN_FIXTURE_WRITTEN synthetic=true')
