#!/usr/bin/env python3
"""Fail-closed, local-only advisory write-scope coordination.

This registry and its O_EXCL transaction mutex coordinate cooperating processes
in ONE checkout on a local filesystem. They are not a distributed lock service,
Git synchronization, an access-control mechanism, or protection against editors
that ignore this protocol. Developer/session identifiers are self-declared, not
an authenticated identity. A crashed mutex requires explicit human recovery;
this module never guesses that an existing mutex is stale or deletes it.
"""

import argparse
from contextlib import contextmanager
import datetime
import json
import math
import os
from pathlib import Path, PureWindowsPath
import subprocess
import sys
import tempfile
import time

ROOT_DIR = Path(__file__).resolve().parent.parent.parent
LOCKS_FILE = ROOT_DIR / ".sdlc" / "locks.json"
GIT_TIMEOUT = 3.0
MUTEX_TIMEOUT = 5.0


class LockError(ValueError):
    """Registry, scope, identity, or transaction state is not safe to use."""


def _git(*args) -> str:
    """Read bounded local Git metadata; failures are unknown, never defaults."""
    try:
        result = subprocess.run(
            ["git", *args], cwd=str(ROOT_DIR), capture_output=True,
            text=True, timeout=GIT_TIMEOUT, check=False,
        )
        return result.stdout.strip() if result.returncode == 0 else ""
    except (OSError, subprocess.SubprocessError, UnicodeError):
        return ""


def get_current_dev() -> str:
    """Explicit SDLC identity only; unknown is '', not a system/user.name guess."""
    if "SDLC_DEVELOPER" in os.environ:
        return os.environ["SDLC_DEVELOPER"].strip()
    return _git("config", "--local", "--get", "sdlc.developer")


def get_current_branch() -> str:
    """Return the current local branch, or '' on detached HEAD/read failure."""
    return _git("symbolic-ref", "--quiet", "--short", "HEAD")


def _text(value, field: str, required: bool = True) -> str:
    if not isinstance(value, str) or (required and not value.strip()):
        raise LockError(f"{field} must be {'a non-empty' if required else 'a'} string")
    if any(ord(char) < 32 or ord(char) == 127 for char in value):
        raise LockError(f"{field} contains control characters")
    return value


def normalize_scope(scope: str, root=None) -> str:
    """Return a canonical repository-relative literal path, resolving symlinks.

    Absolute/drive/UNC/root paths, any '..' component, empty/root scopes and
    Windows ambiguous components are rejected, even when running on POSIX.
    Nonexistent descendants are allowed; existing symlink parents must resolve
    inside the repository. ROOT_DIR is looked up at call time for test injection.
    """
    _text(scope, "scope")
    value = scope.strip().replace("\\", "/")
    if value.startswith("/") or PureWindowsPath(value).drive or ":" in value:
        raise LockError("scope must be repository-relative, not absolute/drive/UNC")
    parts = []
    for part in value.split("/"):
        if part == "..":
            raise LockError("scope must not contain '..'")
        if part in ("", "."):
            continue
        if part.endswith((" ", ".")):
            raise LockError("scope has an ambiguous trailing space/dot component")
        parts.append(part)
    if not parts:
        raise LockError("scope must name a file/directory, not the repository root")
    try:
        base = Path(ROOT_DIR if root is None else root).resolve(strict=True)
        resolved = base.joinpath(*parts).resolve(strict=False)
        relative = resolved.relative_to(base)
    except (OSError, RuntimeError, ValueError) as exc:
        raise LockError(f"scope cannot be resolved inside repository: {exc}") from exc
    if not relative.parts:
        raise LockError("scope resolves to the repository root")
    return relative.as_posix()


def scopes_overlap(a: str, b: str, root=None) -> bool:
    """Conservative casefold comparison with directory-component boundaries."""
    first = normalize_scope(a, root=root).casefold()
    second = normalize_scope(b, root=root).casefold()
    return first == second or first.startswith(second + "/") or second.startswith(first + "/")


def _unique_object(pairs):
    obj = {}
    for key, value in pairs:
        if key in obj:
            raise LockError(f"duplicate JSON key: {key}")
        obj[key] = value
    return obj


def _invalid_constant(value):
    raise LockError(f"non-standard JSON constant: {value}")


def _validate(data: dict) -> dict:
    """Validate the complete v1 registry before any lock can be trusted."""
    if not isinstance(data, dict) or type(data.get("version")) is not int or data["version"] != 1:
        raise LockError("lock registry must be an object with integer version 1")
    if "coordination" in data and data["coordination"] != "local-only":
        raise LockError("lock registry coordination must be local-only")
    if not isinstance(data.get("locks"), list):
        raise LockError("lock registry 'locks' must be a list")
    owners = set()
    for index, lock in enumerate(data["locks"]):
        if not isinstance(lock, dict):
            raise LockError(f"locks[{index}] must be an object")
        for field in ("developer", "session_id", "branch", "locked_at"):
            _text(lock.get(field), f"locks[{index}].{field}")
        for field in ("issue_id", "task_title"):
            _text(lock.get(field), f"locks[{index}].{field}", required=False)
        try:
            datetime.datetime.fromisoformat(lock["locked_at"].replace("Z", "+00:00"))
        except ValueError as exc:
            raise LockError(f"locks[{index}].locked_at must be an ISO timestamp") from exc
        scopes = lock.get("write_scopes")
        if not isinstance(scopes, list) or not scopes:
            raise LockError(f"locks[{index}].write_scopes must be a non-empty list")
        for scope in scopes:
            normalize_scope(scope)
        owner = (lock["developer"], lock["session_id"])
        if owner in owners:
            raise LockError("duplicate developer/session owner records")
        owners.add(owner)
    return data


def load_locks() -> dict:
    """Read and validate locks, raising LockError even if the file is missing."""
    try:
        with Path(LOCKS_FILE).open("r", encoding="utf-8") as stream:
            data = json.load(stream, object_pairs_hook=_unique_object, parse_constant=_invalid_constant)
        return _validate(data)
    except (OSError, UnicodeError, ValueError, RecursionError) as exc:
        raise LockError(f"Cannot trust lock registry {LOCKS_FILE}: {exc}") from exc


def list_active_locks() -> list:
    """Return validated records; an unreadable registry never means no locks."""
    return load_locks()["locks"]


@contextmanager
def _transaction(timeout=MUTEX_TIMEOUT):
    """Serialize local mutations; never break or remove another mutex."""
    if isinstance(timeout, bool) or not isinstance(timeout, (int, float)) or not math.isfinite(timeout) or timeout < 0:
        raise LockError("mutex timeout must be a finite nonnegative number")
    mutex = Path(str(LOCKS_FILE) + ".mutex")
    deadline = time.monotonic() + timeout
    while True:
        try:
            descriptor = os.open(str(mutex), os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
            break
        except FileExistsError as exc:
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                raise LockError("Local transaction mutex timeout; inspect/recover manually, never auto-break stale mutex") from exc
            time.sleep(min(0.05, remaining))
        except OSError as exc:
            raise LockError(f"Cannot create local transaction mutex: {exc}") from exc
    try:
        os.close(descriptor)
        yield
    finally:
        try:
            mutex.unlink()
        except OSError as exc:
            raise LockError(f"Cannot remove owned transaction mutex: {exc}") from exc


def _atomic_save(data: dict, exclusive: bool = False) -> None:
    """Publish complete data atomically; caller must hold _transaction.

    Explicit initialization uses a hard link for atomic no-clobber creation.
    Filesystems without local hard-link support fail closed rather than falling
    back to overwriting existing state.
    """
    _validate(data)
    path = Path(LOCKS_FILE)
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w", encoding="utf-8", dir=str(path.parent),
            prefix=path.name + ".", suffix=".tmp", delete=False,
        ) as stream:
            temporary = Path(stream.name)
            json.dump(data, stream, indent=2, ensure_ascii=False, allow_nan=False)
            stream.write("\n")
            stream.flush()
            os.fsync(stream.fileno())
        if exclusive:
            os.link(str(temporary), str(path))
        else:
            os.replace(str(temporary), str(path))
            temporary = None
    except (OSError, ValueError) as exc:
        raise LockError(f"Cannot atomically write lock registry: {exc}") from exc
    finally:
        if temporary is not None:
            try:
                temporary.unlink()
            except FileNotFoundError:
                pass
            except OSError as exc:
                raise LockError(f"Cannot remove temporary registry: {exc}") from exc


def initialize_locks(timeout=MUTEX_TIMEOUT) -> tuple:
    """Explicitly create a missing local registry, never overwrite any existing path.

    No startup/read/acquire/release path calls this helper implicitly. Atomic
    exclusive publication needs local filesystem hard-link support.
    """
    path = Path(LOCKS_FILE)
    try:
        path.parent.mkdir(parents=True, exist_ok=True)
    except OSError as exc:
        raise LockError(f"Cannot create local registry directory: {exc}") from exc
    with _transaction(timeout):
        _atomic_save({
            "version": 1, "coordination": "local-only",
            "description": "Local advisory coordination; not distributed locking or authentication.",
            "locks": [],
        }, exclusive=True)
    return True, "Initialized empty local-only advisory lock registry"


def save_locks(data: dict) -> None:
    """Compatibility write API: validated, serialized, never recreates missing state.

    Prefer acquire/release: this low-level whole-registry operation does not merge
    a caller's stale snapshot and is not an ownership/authentication API.
    """
    with _transaction():
        load_locks()
        _atomic_save(data)


def _identity(dev, session_id):
    developer = dev if dev else get_current_dev()
    session = session_id if session_id is not None else os.environ.get("SDLC_SESSION", "")
    return _text(developer, "developer (use --dev or SDLC_DEVELOPER/local sdlc.developer)"), _text(session, "session (use --session or SDLC_SESSION)")


def _is_owner(lock, developer, session):
    return lock["developer"] == developer and lock["session_id"] == session


def acquire_lock(dev: str, scopes: list, issue_id: str = "", title: str = "", session_id=None, timeout=MUTEX_TIMEOUT) -> tuple:
    """Acquire/update only the exact developer/session owner's scopes atomically."""
    developer, session = _identity(dev, session_id)
    branch = get_current_branch()
    if not branch or branch.casefold() in ("main", "master", "head"):
        raise LockError("Acquire requires a feature branch, not main/master/detached/unknown")
    _text(branch, "branch")
    if not isinstance(scopes, list) or not scopes:
        raise LockError("At least one scope must be supplied")
    clean_scopes = list(dict.fromkeys(normalize_scope(scope) for scope in scopes))
    _text(issue_id, "issue_id", required=False)
    _text(title, "task_title", required=False)
    with _transaction(timeout):
        data = load_locks()
        for lock in data["locks"]:
            if _is_owner(lock, developer, session):
                continue
            if lock["session_id"] == session:
                return False, "Session already belongs to a different developer; exact ownership required"
            for existing in lock["write_scopes"]:
                for scope in clean_scopes:
                    if scopes_overlap(scope, existing):
                        return False, f"CONFLICT: '{scope}' is locked by {lock['developer']} (session {lock['session_id']}, branch {lock['branch']})"
        data["locks"] = [lock for lock in data["locks"] if not _is_owner(lock, developer, session)]
        data["locks"].append({
            "developer": developer, "session_id": session, "branch": branch,
            "issue_id": issue_id, "task_title": title, "write_scopes": clean_scopes,
            "locked_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        })
        _atomic_save(data)
    return True, f"Local advisory lock acquired: {developer}/{session} -> {clean_scopes}"


def release_lock(dev: str = None, session_id=None, timeout=MUTEX_TIMEOUT) -> tuple:
    """Release only the exact owner/session, never all sessions for a developer."""
    developer, session = _identity(dev, session_id)
    with _transaction(timeout):
        data = load_locks()
        remaining = [lock for lock in data["locks"] if not _is_owner(lock, developer, session)]
        if len(remaining) == len(data["locks"]):
            return False, "No lock for this exact developer/session owner"
        data["locks"] = remaining
        _atomic_save(data)
    return True, f"Local advisory lock released: {developer}/{session}"


def check_scope_safety(target_scope: str, current_dev: str = "", session_id=None) -> list:
    """List conflicts; absent explicit session conservatively checks ALL sessions.

    An explicitly supplied session (or SDLC_SESSION) excludes only that exact
    developer/session owner. A developer name alone never grants an exemption.
    """
    target = normalize_scope(target_scope)
    developer = current_dev or get_current_dev()
    session = session_id if session_id is not None else os.environ.get("SDLC_SESSION", "")
    conflicts = []
    for lock in list_active_locks():
        if developer and session and _is_owner(lock, developer, session):
            continue
        if any(scopes_overlap(target, scope) for scope in lock["write_scopes"]):
            conflicts.append(lock)
    return conflicts


def main(argv=None):
    """CLI errors/conflicts exit 2 without tracebacks; no implicit session files."""
    parser = argparse.ArgumentParser(description="Local-only advisory scope locks (not distributed/authenticated)")
    commands = parser.add_subparsers(dest="command")
    commands.add_parser("list", help="List validated local locks")
    commands.add_parser("init", help="Explicitly create a missing local registry; never overwrite existing state")
    acquire = commands.add_parser("acquire", help="Acquire on a feature branch")
    acquire.add_argument("--scope", required=True, help="Comma-separated literal repository-relative scopes")
    acquire.add_argument("--dev", default="")
    acquire.add_argument("--session", default=None, help="Explicit owner session, or SDLC_SESSION")
    acquire.add_argument("--issue", default="")
    acquire.add_argument("--title", default="")
    release = commands.add_parser("release", help="Release only your exact session")
    release.add_argument("--dev", default="")
    release.add_argument("--session", default=None)
    check = commands.add_parser("check", help="Check every session unless an explicit owner session is supplied")
    check.add_argument("--scope", required=True)
    check.add_argument("--dev", default="")
    check.add_argument("--session", default=None)
    args = parser.parse_args(argv)
    try:
        if args.command == "acquire":
            ok, message = acquire_lock(args.dev, args.scope.split(","), args.issue, args.title, session_id=args.session)
            print(message)
            return 0 if ok else 2
        if args.command == "release":
            ok, message = release_lock(args.dev, session_id=args.session)
            print(message)
            return 0 if ok else 2
        if args.command == "check":
            conflicts = check_scope_safety(args.scope, args.dev, session_id=args.session)
            print(json.dumps(conflicts, ensure_ascii=False, indent=2))
            return 2 if conflicts else 0
        print(json.dumps(list_active_locks(), ensure_ascii=False, indent=2))
        return 0
    except (LockError, OSError, UnicodeError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
