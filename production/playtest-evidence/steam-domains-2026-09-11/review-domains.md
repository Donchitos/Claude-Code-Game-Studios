# Steam five-domain QA / contract review — 2026-09-11

Reviewer: independent `save_domain_audit` subagent. Review scope: `tools/steam/build_domain_schemas.py`, five generated domain schemas, `src/data/steam_structure_validator.gd`, `src/data/steam_save_domains.gd`; read-only implementation review and independent `/tmp` probes. Only this report is written by the reviewer. The reviewer has earlier audit context; this is an independent implementation recheck, not a fresh-context full design verdict.

## Verdict

**PASS within the reviewed schema/validator scope — 0 open P1/P2 findings.** The four original findings and the additional lifetime-spending finding are fixed in the reviewed implementation. The final recheck is limited to those reported issues and does not expand the review scope. Production admission, complete Steam recovery, migration execution and commercial maximum capacity remain unproven; this review does not approve them.

### Closed P1 — purchase receipt contradicted lifetime spending

Location: `src/data/steam_save_domains.gd`, `_progression`, receipt checks following the balance conservation check.

Before the final fix, the validator accepted a purchased QINGYUAN level 1, purchase sequence 1 and a V2 receipt proving a cost of 4, while `spent_pages_total=0`, `unspent_pages=6`, `earned_pages_total=6`. The enclosing ledger balances and the receipt balances each reconcile individually, but they cannot describe the same purchase history. The current Progression owner has purchases as its only sink and no refund operation; a confirmed purchase cost cannot exceed lifetime spent. The problem is independent of repricing: checking this lower bound does not recompute historical prices.

Final implementation requires `receipt.cost_pages <= spent_pages_total` and `receipt.balance_after <= unspent_pages`, without changing the historical-price or receipt-preservation rules. Independent public `validate` probe now returns `receipt_cost_exceeds_all_lifetime_spend actual=INVALID expected=INVALID`; the purchase-plus-income positive control remains OK. This P1 is closed.

## Closed findings and independent counterexamples

| Earlier finding / boundary | Retest observation |
|---|---|
| Later income invalidates historical receipt | Purchase receipt next revision 1, domain revision 2 and conserved income now returns OK. |
| RUNNING exposes unresolved pre-active offer | Nonempty offer with null selection returns INVALID; selection with zero handoff revision also returns INVALID. |
| Unrelated recipe and seed independently pass catalog checks | Wrong recipe returns INVALID; correct recipe while campaign prep is locked returns INVALID; correct pairing after the first three completed missions and matching unlocks returns OK. |
| Caller mission map can redefine mission ordinal | Missing first mission and changed mission hash both return INVALID_CONFIG during initialization. |
| Preparation shape mistaken for complete semantic recovery | Missing Preparation validator returns UNSUPPORTED_SCHEMA for PREPARED and RUNNING; explicit owner rejection propagates. Positive owner in this probe is synthetic and proves only dispatch. |
| RESULT_PENDING mistaken for completed Settlement implementation | Structurally valid pending intent reaches `owner_id=SettlementComplete` with UNSUPPORTED_SCHEMA when the owner is absent. No reward plan or COMPLETE success is claimed. |

## Executed evidence

Platform: macOS; Godot `4.7.1.stable.official.a13da4feb`.

- `Godot --headless --path <repository> --script tests/integration/steam_domains_test.gd`: `STEAM_DOMAINS_TEST checks=95 failures=0` (final rerun).
- `python3 tools/steam/check_domain_artifacts.py`: `DOMAIN_ARTIFACT_CHECK checks=199 failures=0 structural_only=true`.
- Independent `/tmp/steam_domains_recheck.gd`, using the public `initialize` / `validate` API and repository fixtures: `INDEPENDENT_DOMAIN_RECHECK checks=17 failures=0` (final rerun). The earlier 17-check run exposed the additional P1; the unchanged independent probe confirms it is now rejected. The script also includes positive controls for accepted purchase-plus-income and authorized matching recipe cases.

The structural evaluator covers this generator's restricted vocabulary; strict u63 patterns precede integer conversion, current arithmetic uses checked subtraction/summation, five domain payloads reject missing/extra fields and incorrect wire types, and dynamic checkpoint payloads require the registered owner callback. No additional confirmed type or overflow finding was established in this recheck.

## Capacity and release boundary

Reviewed `envelope-measurements.json`: 15 cases, five samples per case, zero probe failures, `commercial_maximum_proven=false`, `durable_protocol_tested=false`. Its note explicitly excludes OS locking, slot replacement, process kill, power loss and Windows evidence. RESULT_PENDING samples carry complete after-images for structural pressure only; they do not prove a reachable Mission/Settlement result. The legacy snapshot owner does not implement Mission, Preparation or full SkillDraft recovery.

These samples and caller limits cannot freeze a production maximum. Actual Preparation/RNG semantics, Settlement COMPLETE validator, all commercial required-owner snapshots, full-content capacities, migration readback and platform durability remain implementation/release gates. Production must remain disabled; no old binary capacity is reused as the JSON v2 maximum.

## Final reviewed SHA-256 identities

Hashes below identify the files at the final reported-finding recheck. They do not identify a production release.

| File | SHA-256 |
|---|---|
| `src/data/steam_save_domains.gd` | `493a5667925bb744c5dc6517d66fdf4f4bc9b306fdcdf3a32f7f51e69db8cac6` |
| `src/data/steam_structure_validator.gd` | `aeba046c2a446836bee082def064e0345d4e702b2e5e560c6a0a2dbb6b7cce38` |
| `tools/steam/build_domain_schemas.py` | `6ce88788154ba6fd00d40e6b4805f11bde9ff1e7f28b7f6e39404a879d9a82af` |
| `tests/integration/steam_domains_test.gd` | `2e01613af55bcc41d3522fece6044f24c6e304dad7cdb96ea6caf900c9fc0bd1` |
| `assets/schemas/steam/records-domain-v1.schema.json` | `3a877db946918ec51bec12fd0d6d198bc616636ad90d5604b55106c2586ed855` |
| `assets/schemas/steam/progression-domain-v1.schema.json` | `4b90ae967127ca2f52e94a28c323f5738022aaed66e0d699a30ce6fea3153534` |
| `assets/schemas/steam/preparation-domain-v1.schema.json` | `f1ca889a3e7c09b01243b75c67be214b0374727f4576dbcd154d1169a1c51a47` |
| `assets/schemas/steam/current_run-domain-v1.schema.json` | `06359c45964acef3c388610d762017145947e2e9ac465bd52dbf1f9b03e74d79` |
| `assets/schemas/steam/user_settings-domain-v1.schema.json` | `a87c7ad8a9d1d4a535d836c9f4001101a7063f2f76c8efe4cd0c5d60c70e8d4d` |
| `/tmp/steam_domains_recheck.gd` | `b4be40709225db9ea1d217a98d72dac2a315c783c2b7bfe6b9324d7d33553f4c` |
