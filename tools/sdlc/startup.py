#!/usr/bin/env python3
"""Read-only Phase 1 routing. No claims, checkout, writes, GitHub sync or worker dispatch."""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess

ROOT_DIR = Path(__file__).resolve().parents[2]
MANIFEST = '.sdlc/phase1_tasks.json'


def git(root, *args, optional=False):
    result = subprocess.run(['git', *args], cwd=root, capture_output=True,
                            text=True, encoding='utf-8', errors='replace', timeout=3)
    if result.returncode and not (optional and result.returncode == 1):
        raise ValueError('Git kontrolu basarisiz: ' + ' '.join(args))
    return result.stdout.strip()


def scope(value, root=None):
    """Canonical conservative cross-platform relative path; no wildcard scopes."""
    if not isinstance(value, str) or not value.strip():
        raise ValueError('Bos veya gecersiz yol')
    value = value.replace('\\', '/')
    parts = value.rstrip('/').split('/')
    if any(p in ('', '.', '..') or p.endswith((' ', '.')) for p in parts):
        raise ValueError('Kanonik olmayan yol: ' + value)
    if any(c in value for c in ':*?[]\x00\n\r') or value.startswith('/'):
        raise ValueError('Repo disi veya desen yol: ' + value)
    normalized = '/'.join(parts)
    if root is not None:
        base = Path(root).resolve()
        if not (base / normalized).resolve().is_relative_to(base):
            raise ValueError('Repo disina cikan baglanti: ' + value)
    return normalized.casefold()


def inside(path, parent):
    return path == parent or path.startswith(parent + '/')


def overlap(a, b):
    return inside(a, b) or inside(b, a)


def validate_manifest(data, root=None):
    if not isinstance(data, dict) or data.get('schema_version') != 1:
        raise ValueError('Manifest schema_version 1 gerekli')
    if type(data.get('revision')) is not int or data['revision'] < 1:
        raise ValueError('Manifest revision gerekli')
    if data.get('developers') != ['alicomert', 'okanipk'] or data.get('integration_owner') != 'alicomert':
        raise ValueError('Gelistirici/entegrator sozlesmesi gecersiz')
    shared = [scope(p, root) for p in data['shared_paths']]
    tasks = data.get('tasks')
    if not isinstance(tasks, list) or not tasks:
        raise ValueError('Gorev listesi bos')
    index = {}
    branches = set()
    for task in tasks:
        tid = task.get('id')
        if not isinstance(tid, str) or not re.fullmatch(r'P[12]-[AOI][0-9]{2}', tid) or tid in index:
            raise ValueError('Gecersiz/tekrar gorev ID')
        if task.get('owner') not in data['developers']:
            raise ValueError('Bilinmeyen gorev sahibi: ' + tid)
        if task.get('status') not in ('planned', 'in_progress', 'blocked', 'done'):
            raise ValueError('Gecersiz durum: ' + tid)
        if type(task.get('priority')) is not int:
            raise ValueError('Oncelik gerekli: ' + tid)
        branch = task.get('branch', '')
        if not re.fullmatch(r'feat/' + task['owner'] + r'/[a-z0-9-]+', branch) or branch in branches:
            raise ValueError('Dal gecersiz/tekrar: ' + tid)
        branches.add(branch)
        for key in ('depends_on', 'write_scopes', 'acceptance', 'evidence', 'roles', 'open_questions'):
            if not isinstance(task.get(key), list):
                raise ValueError('Liste gerekli: ' + tid + ':' + key)
        if not task['write_scopes'] or not task['acceptance'] or not task.get('title'):
            raise ValueError('Kapsam/kabul/baslik gerekli: ' + tid)
        paths = [scope(p, root) for p in task['write_scopes']]
        if any(overlap(p, s) for p in paths for s in shared):
            if task['owner'] != data['integration_owner'] or not re.fullmatch(r'P[12]-I[0-9]{2}', tid):
                raise ValueError('Ortak dosya yalniz entegrasyon gorevine verilir: ' + tid)
        if task['status'] == 'done' and (not task['evidence'] or task['open_questions']):
            raise ValueError('Kanit olmadan done yasak: ' + tid)
        index[tid] = task
    visiting, visited = set(), set()
    def visit(tid):
        if tid not in index:
            raise ValueError('Eksik bagimlilik: ' + str(tid))
        if tid in visiting:
            raise ValueError('Dongusel gorev bagimliligi')
        if tid in visited:
            return
        visiting.add(tid)
        for dep in index[tid]['depends_on']:
            visit(dep)
            if index[tid]['status'] == 'done' and index[dep]['status'] != 'done':
                raise ValueError('Bitmemis bagimliliga sahip done gorev')
        visiting.remove(tid)
        visited.add(tid)
    for tid in index:
        visit(tid)
    # Explicit integration handoffs preserve historical ownership; never waive live work.
    handoffs = data.get('integration_handoffs', [])
    if not isinstance(handoffs, list):
        raise ValueError('Gecersiz entegrasyon devirleri')
    authorized = set()
    for handoff in handoffs:
        if not isinstance(handoff, dict):
            raise ValueError('Gecersiz devir kaydi')
        source = index.get(handoff.get('from_task'))
        target = index.get(handoff.get('to_task'))
        paths = handoff.get('scopes')
        if (not source or not target or source['status'] != 'done'
                or target['owner'] != data['integration_owner']
                or not re.fullmatch(r'P2-I[0-9]{2}', target['id'])
                or source['owner'] == target['owner']
                or source['id'] not in target['depends_on']
                or not handoff.get('reason') or not isinstance(paths, list) or not paths):
            raise ValueError('Gecersiz entegrasyon devri')
        for path in paths:
            normalized = scope(path, root)
            if (not any(inside(normalized, scope(p, root)) for p in source['write_scopes'])
                    or not any(inside(normalized, scope(p, root)) for p in target['write_scopes'])):
                raise ValueError('Devir kapsami gorev disinda')
            authorized.add((source['id'], target['id'], normalized))
    # Cross-owner overlap requires a handoff covering the entire intersection.
    for a in tasks:
        for b in tasks:
            if a['owner'] == b['owner']:
                continue
            for x in a['write_scopes']:
                for y in b['write_scopes']:
                    sx, sy = scope(x, root), scope(y, root)
                    if not overlap(sx, sy):
                        continue
                    intersection = sx if inside(sx, sy) else sy
                    if not any(((s == a['id'] and t == b['id']) or (s == b['id'] and t == a['id']))
                               and inside(intersection, p) for s, t, p in authorized):
                        raise ValueError('Iki gelistiriciye ortak yazma kapsami: ' + a['id'] + '/' + b['id'])
    return index


def resolve(data, developer, branch, dirty_paths, locks, root=None):
    """Pure routing for tests and CLI. can_write is a protocol gate, not OS permission."""
    index = validate_manifest(data, root)
    reasons = []
    if developer not in data['developers']:
        reasons.append('UNKNOWN_DEVELOPER: --developer veya git config --local sdlc.developer kullanin')
    mine = sorted((t for t in index.values() if t['owner'] == developer and t['status'] != 'done'),
                  key=lambda t: (t['priority'], t['id']))
    active = [t for t in mine if t['status'] == 'in_progress']
    if len(active) > 1:
        reasons.append('MULTIPLE_ACTIVE_TASKS: gorev durumlarini netlestirin')
    on_branch = [t for t in mine if t['branch'] == branch]
    ready = [t for t in mine if t['status'] != 'blocked' and not t['open_questions']
             and all(index[d]['status'] == 'done' for d in t['depends_on'])]
    candidate = (on_branch or active or ready or [None])[0]
    if candidate is None:
        reasons.append('WAITING: atanmis hazir gorev yok')
    if not branch or branch in ('main', 'master'):
        reasons.append('PROTECTED_OR_DETACHED_BRANCH: ayri ozellik dali gerekli')
    if candidate:
        if branch != candidate['branch']:
            reasons.append('WRONG_BRANCH: beklenen ' + candidate['branch'])
        if candidate not in ready:
            reasons.append('TASK_BLOCKED: acik karar veya tamamlanmamis bagimlilik')
        allowed = [scope(s, root) for s in candidate['write_scopes']]
        for path in dirty_paths:
            if not any(inside(scope(path, root), s) for s in allowed):
                reasons.append('UNRELATED_DIRTY_PATH: ' + path)
        # No session supplied: all leases, including same-developer sessions, are foreign.
        for lock in locks:
            if any(overlap(s, scope(p, root)) for s in allowed for p in lock['write_scopes']):
                reasons.append('LOCAL_LEASE_CONFLICT: ' + lock.get('developer', '?'))
    elif dirty_paths:
        reasons.append('DIRTY_WORKTREE_WITHOUT_TASK')
    return dict(schema_version=1, developer=developer or None,
                assignment_source='repo-manifest', manifest_revision=data['revision'],
                source_freshness='unknown', coordination='local-only', branch=branch or None,
                dirty_paths=dirty_paths, candidate_task=candidate, blocked_reasons=reasons,
                can_write=not reasons,
                next_action='Gorev planini ve dosya kapsam onayini kontrol edin; otomatik kod yazilmaz.' if not reasons
                else 'Engelleri kullanici ile giderin; stash/reset/checkout/commit otomatik yapilmaz.')


def inspect(root=ROOT_DIR, developer=''):
    root = Path(root).resolve()
    report = dict(schema_version=1, can_write=False, blocked_reasons=[],
                  candidate_task=None, source_freshness='unknown', coordination='local-only')
    try:
        config = git(root, 'config', '--local', '--get', 'sdlc.developer', optional=True)
        identities = {'argument': developer.strip(), 'environment': os.environ.get('SDLC_DEVELOPER', '').strip(),
                      'git-local-config': config}
        values = {v for v in identities.values() if v}
        if len(values) > 1:
            raise ValueError('IDENTITY_DISAGREEMENT: kimlik kaynaklari farkli')
        chosen = next(iter(values), '')
        branch = git(root, 'branch', '--show-current')
        # NUL format preserves spaces, unicode and both sides of renames.
        raw = subprocess.run(['git', 'status', '--porcelain=v1', '-z', '--untracked-files=all'],
                             cwd=root, capture_output=True, timeout=3, check=True).stdout.decode('utf-8')
        items, paths, i = raw.split('\0'), [], 0
        while i < len(items):
            entry = items[i]
            i += 1
            if not entry:
                continue
            paths.append(entry[3:])
            if 'R' in entry[:2] or 'C' in entry[:2]:
                paths.append(items[i])
                i += 1
        data = json.loads((root / MANIFEST).read_text(encoding='utf-8'))
        # Read actual local store without creating it or falling back to empty on corruption.
        from locks import load_locks
        local = load_locks() if root == ROOT_DIR else json.loads((root / '.sdlc/locks.json').read_text(encoding='utf-8'))
        if local.get('version') != 1 or not isinstance(local.get('locks'), list):
            raise ValueError('Gecersiz yerel kilit kaydi')
        report = resolve(data, chosen, branch, sorted(set(paths)), local['locks'], root)
        report['identity_source'] = [k for k, v in identities.items() if v]
        report['next_action'] += ' Ortak baseline/manifest surumunu partnerinizle dogrulayin; GitHub senkronu yok.'
    except (ValueError, OSError, KeyError, TypeError, subprocess.SubprocessError) as exc:
        report['blocked_reasons'].append('STARTUP_ERROR: ' + str(exc))
        report['can_write'] = False
    return report


def run(developer='', as_json=False):
    report = inspect(developer=developer)
    if as_json:
        print(json.dumps(report, ensure_ascii=True, indent=2))
    else:
        print('[PHASE1 START] Salt okunur gorev yonlendirmesi / yerel koordinasyon')
        print('Gelistirici:', report.get('developer'), '| Dal:', report.get('branch'))
        print('Manifest:', report.get('manifest_revision'), '| Uzak guncellik: UNKNOWN (ag sorgulanmadi)')
        task = report.get('candidate_task')
        if task:
            print('Gorev:', task['id'], '-', task['title'], '|', task['status'])
            print('Beklenen dal:', task['branch'])
            print('Yazma kapsami:', ', '.join(task['write_scopes']))
            print('Uzmanlar:', ', '.join(task['roles']))
            for item in task['acceptance']:
                print('  Kabul:', item)
        for reason in report['blocked_reasons']:
            print('[DUR]', reason)
        print('Protokol gecidi:', 'READY (dosya onayi ve yerel lease ayrica gerekli)' if report['can_write'] else 'BLOCKED - yazma yok')
        print(report.get('next_action', 'Baslangic hatasini giderin.'))
        print('Plan: production/phase-1-workstreams.md | Bu arac ajan baslatmaz ve gorev sahipligi degistirmez.')
    return 0 if report['can_write'] else 2


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--developer', default='')
    parser.add_argument('--json', action='store_true')
    args = parser.parse_args()
    raise SystemExit(run(args.developer, args.json))