"""Seven-domain capacity envelopes from actual legacy Stage pressure snapshots.
These are measurable test envelopes, NOT proven-reachable commercial maxima.
"""
import copy, json
from pathlib import Path
from build_domain_fixtures import build, canonical, hash_value
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'production/playtest-evidence/steam-domains-2026-09-11'
MAX=(1<<63)-1

def build_envelopes():
    fixture=build(); source=json.loads((ROOT/'tests/fixtures/steam/campaign-fixture.json').read_text())
    domains=fixture['domains']
    for key, domain in domains.items():
        if key != 'current_run': domain['payload']['domain_revision']=str(MAX-2)
    domains['campaign']['payload'].update(completed_mission_ids=[m['mission_id'] for m in source['definition']['missions']],ending_seen=True)
    domains['unlocks']['payload']['unlocked_content_ids']=source['catalog']['unlock_ids']
    domains['records']['payload'].update(legacy_records=dict(total_runs=str(MAX),victories=str(MAX),best_level=str(MAX),best_kills=str(MAX),best_seconds='7fefffffffffffff'),
        mission_records=dict(completed_runs=str(MAX),victories=str(MAX-3),defeats='1',abandoned='1',technical_aborts='1',total_kills=str(MAX)),
        spirit_stones=dict(unspent=str(MAX-1),earned=str(MAX),spent='1'),core_herb_count=str(MAX))
    domains['progression']['payload'].update(unspent_pages=str(MAX-180),earned_pages_total=str(MAX),spent_pages_total='180',upgrade_sequence='15',next_purchase_id='16',branch_levels=dict(QINGYUAN='5',LONGCHUN='5',DAYAN='5'),
        last_purchase_receipt=dict(kind='V2',purchase_id='15',branch_id='DAYAN',from_level='4',to_level='5',cost_pages='20',balance_before=str(MAX-1),balance_after=str(MAX-21),base_domain_revision=str(MAX-4),next_domain_revision=str(MAX-3),request_hash='c'*64))
    for ledger in domains['preparation']['payload']['seed_ledgers']:
        ledger.update(available='999',reserved='0',consumed=str(MAX-999),earned=str(MAX))
    domains['preparation']['payload'].update(next_preparation_id=str(MAX),legacy_starter_claimed=True,applied_campaign_grant_ids=['TEST-PREP'],last_resolution=dict(preparation_id=str(MAX-2),run_seq=str(MAX-2),outcome='CONSUMED',operation_id='7'*32))
    cases=[]
    for case_name in ['full','ring','summon','bite','phase_pending']:
        snapshot_file=OUT/f'snapshot-{case_name}.json'
        snapshot=json.loads(snapshot_file.read_text())
        run=copy.deepcopy(fixture['prepared_run'])
        run.update(run_seq=str(MAX-1),mission_id='S1-M08-08',mission_definition_hash=source['catalog']['mission_hashes']['S1-M08-08'],config_hash=snapshot['config_hash'])
        run['prep_receipt'].update(preparation_id=str(MAX-1),run_seq=str(MAX-1),source_content_hash=snapshot['config_hash'])
        pc=run['preparation_checkpoint'];pc.update(preparation_id=str(MAX-1),run_seq=str(MAX-1),revision=str(MAX),handoff_revision=str(MAX))
        # Explicit test catalog fixture only. Full SkillDraft payload remains unregistered.
        pc['rng']['cursor']=str(MAX)
        run['checkpoint']=dict(checkpoint_seq=str(MAX),active_tick=snapshot['scope']['completed_active_ticks'],owner_snapshots=[dict(owner_id='LEGACY_STAGE',schema='1',revision=str(MAX),payload=snapshot)])
        current=copy.deepcopy(domains)
        current['preparation']['payload']['active_reservation']=dict(receipt=run['prep_receipt'],state='CONSUMED',recovery_revision=str(MAX))
        current['current_run']['payload']['run']=run
        for state in ['RUNNING','SUSPENDED','RESULT_PENDING']:
            run['run_status']=state
            run['terminal_intent']=None
            if state=='RESULT_PENDING':
                next_domains=copy.deepcopy(current)
                next_domains['current_run']['payload']['run']=None
                next_domains['preparation']['payload']['active_reservation']=None
                result=dict(schema='1',profile_id='1'*32,branch_id='2'*32,run_seq=run['run_seq'],mission_id=run['mission_id'],mission_definition_hash=run['mission_definition_hash'],terminal_tick=run['checkpoint']['active_tick'],result_kind='ABANDONED',reason='TEST-CAPACITY-ABANDON',objective_progress_hash='e'*64)
                request=dict(profile_id='1'*32,branch_id='2'*32,base_revision=str(MAX-1),operation_id='6'*32,kind='COMPLETE',next_domains=next_domains)
                # Request identity is test-only: production COMPLETE normal API not installed.
                run['terminal_intent']=dict(sealed_result=result,result_hash=hash_value(result),complete_operation_id='6'*32,complete_base_revision=str(MAX-1),complete_request_hash=hash_value(request),complete_next_domains=next_domains)
            root=dict(schema='2',profile_id='1'*32,branch_id='2'*32,revision=str(MAX-1),parent_hash='9'*64,content_revision='1',content_hash=source['catalog']['content_hash'],next_run_seq=str(MAX),resolved_run_seq=str(MAX-2),
                last_operation=dict(operation_id='3'*32,request_hash='f'*64,kind='STAGE_RESULT' if state=='RESULT_PENDING' else 'SUSPEND',base_revision=str(MAX-2)),domains=current,migration_source=None)
            name=snapshot_file.stem+'-'+state.lower()
            raw=canonical(root)
            (OUT/(name+'.payload.json')).write_text(raw)
            wrapper=dict(format='STEAM_SAVE_V2',payload_json=raw,payload_sha256=hash_value(root))
            encoded=canonical(wrapper)
            (OUT/(name+'.slot.json')).write_text(encoded)
            cases.append(dict(case=name,payload_bytes=len(raw.encode()),slot_bytes=len(encoded.encode()),domain_bytes={k:len(canonical(v).encode()) for k,v in current.items()},sha256=hash_value(root)))
    manifest=dict(scope='LEGACY_STAGE_PC_V1 synthetic seven-domain envelopes',natural_reachability_proven=False,production_admission=False,commercial_maximum='OPEN',
        missing_budget_owners=['Mission six objectives and fact queues','full SkillDraft/Loadout','Preparation RNG/offer owner','SettlementComplete exact after-images','Character/Codex/Narrative content catalogs'],
        test_allocation_ceiling_bytes=8000000,capacities=json.loads((ROOT/'assets/config/production_defaults.json').read_text())['capacities'],cases=cases)
    (OUT/'capacity-fixtures.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print('CAPACITY_ENVELOPES cases=%d max_slot_bytes=%d commercial_maximum=OPEN'%(len(cases),max(r['slot_bytes'] for r in cases)))
if __name__=='__main__':build_envelopes()
