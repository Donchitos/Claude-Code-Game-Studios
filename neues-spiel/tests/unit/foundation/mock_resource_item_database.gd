## Minimal RID-shaped test double (ADR-0005 Validation Criteria).
##
## Implements exactly the two members [GameWorld]'s boot gate (ADR-0005)
## depends on: [method is_ready] and [signal validation_complete]. Lives
## under tests/ only -- the concrete [code]ResourceItemDatabase[/code]
## Autoload is a separate epic's job (rid-002); this double never claims to
## BE it, only to duck-type its boot-gate-relevant surface.
class_name MockResourceItemDatabase
extends Node

## Emitted when validation settles. Carries a plain [Dictionary] ([code]
## {"success": bool, "issues": Array}[/code]) rather than a typed
## [code]ValidationResult[/code] -- that class does not exist yet in this
## codebase (rid-004/005 introduce it). [GameWorld] reads [code]
## result["success"][/code] / [code]result["issues"][/code].
signal validation_complete(result: Dictionary)

var _ready_immediately: bool = false


## Configures this double so [method is_ready] reports [code]true[/code]
## from the moment it's assigned -- simulates RID's confirmed-common
## synchronous-Ready case (ADR-0005 Decision §3): validation already
## completed during the Autoload's own [code]_ready()[/code], before
## [GameWorld]'s [code]_ready()[/code] runs.
func configure_ready_immediately() -> void:
	_ready_immediately = true


## Returns whether this double reports the successful Ready state. Mirrors
## RID's real [code]is_ready() -> bool[/code] contract.
func is_ready() -> bool:
	return _ready_immediately


## Fires [signal validation_complete] with the given outcome, simulating RID
## settling after [GameWorld] has already connected (the check-then-connect
## fallback branch) -- used for both the Ready-via-signal and the Failed
## test cases (ADR-0005 QA plan).
func settle(success: bool, issues: Array = []) -> void:
	validation_complete.emit({"success": success, "issues": issues})
