"""Validate WP04c planning inventory and report unresolved commercial gates.
PASS means a well-formed responsibility inventory, never runtime admission.
"""
import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'design/registry/manifests/steam-recovery-responsibilities-v1.json'
OWNER_IDS = {'Scope', 'Player', 'Stage', 'Enemy', 'Boss', 'Spawn', 'Weapon',
             'Projectile', 'Damage', 'DropLeveling', 'SkillDraftLoadout', 'RNG', 'Mission'}
FEATURE_IDS = {'Preparation', 'SettlementComplete', 'CampaignUnlocks',
               'ProgressionRecordsSettings', 'CharacterCodexNarrative'}
KINDS = {'SURVIVE', 'BREAK', 'CLEANSE', 'HUNT', 'ESCORT', 'BOSS'}


def validate(data):
    """Only the current OPEN inventory revision is supported; no self-certification."""
    errors = []
    def require(ok, label):
        if not ok:
            errors.append(label)
    require(data.get('schema') == '1', 'schema')
    require(data.get('profile') == 'STEAM_MISSION_V1', 'profile')
    require(data.get('status') == 'RESPONSIBILITY_INVENTORY_NOT_INSTALLABLE', 'status')
    require(data.get('production_enabled') is False and data.get('battle_ready') is False, 'no release admission')
    for key, expected in [('snapshot_owners', OWNER_IDS), ('persistent_features', FEATURE_IDS)]:
        rows = data.get(key, [])
        ids = [r.get('responsibility_id') for r in rows]
        require(len(ids) == len(expected) and set(ids) == expected, key + '.exact_set')
        for row in rows:
            prefix = key + '.' + str(row.get('responsibility_id'))
            require(row.get('status') == 'OPEN', prefix + '.status')
            require(row.get('commercial_provider') is None and row.get('commercial_schema') is None, prefix + '.unimplemented')
            require(bool(row.get('persist')) and all(isinstance(s, str) and s for s in row['persist']), prefix + '.persist')
            path = row.get('owner_gdd', '')
            require(path.startswith('design/gdd/') and '..' not in Path(path).parts and (ROOT / path).is_file(), prefix + '.owner_gdd')
            size = 'max_snapshot_bytes' if key == 'snapshot_owners' else 'max_domain_bytes'
            require(size in row and row[size] is None, prefix + '.unmeasured_budget')
            if key == 'snapshot_owners':
                require(bool(row.get('barrier_requires_empty')), prefix + '.barrier')
    rows = data.get('mission_overlays', [])
    require(len(rows) == len(KINDS) and {r.get('objective_kind') for r in rows} == KINDS, 'six objectives')
    for row in rows:
        require(row.get('status') == 'OPEN' and bool(row.get('required_state')), 'objective state')
        require(all(k in row and row[k] is None for k in ['production_definition', 'phase_manifest', 'fact_capacity']), 'objective unimplemented')
    budget = data.get('budget', {})
    require(budget.get('status') == 'OPEN' and budget.get('production_limits') is None, 'commercial budget stays OPEN')
    require(budget.get('required_states') == ['PREPARED', 'RUNNING', 'SUSPENDED', 'RESULT_PENDING'], 'all four save states')
    require(bool(data.get('joint_invariants')) and bool(data.get('rebuild_only')), 'cross-owner and rebuild boundary')
    return errors


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--report', type=Path)
    args = parser.parse_args()
    data = json.loads(SOURCE.read_text())
    errors = validate(data)
    report = dict(status='PASS' if not errors else 'FAIL', errors=errors,
                  scope='responsibility inventory only', snapshot_responsibilities=len(data['snapshot_owners']),
                  persistent_features=len(data['persistent_features']), objective_kinds=len(data['mission_overlays']),
                  open_snapshot_owners=[r['responsibility_id'] for r in data['snapshot_owners']],
                  commercial_budget='OPEN', production_enabled=False, battle_ready=False)
    if args.report:
        args.report.write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report))
    raise SystemExit(bool(errors))


if __name__ == '__main__':
    main()
