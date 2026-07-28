# villager-ai-025: the plumbing landed, and the payload now measures POSITIVE

> **UPDATED 2026-07-28** — the first valid post-fix measurement exists and it is
> good. See the section at the bottom. The text below is kept as written,
> because the sequence of what was known when is the useful part.

# (original note) the plumbing landed, the outcome did not

Third attempt at "A builder always has a way down". What holds and what does not,
kept apart deliberately.

## Proven and landed

- `ScaffoldErectionCoordinator` receives real ticks in the shipped game.
- A single marooned observation never erects anything — the persistence
  discipline that keeps this from repeating the queue flood which starved the
  walls earlier.

Both assertions live in
`neues-spiel/tests/integration/scene_world_management/scaffold_erection_descent_live_test.gd`.

## NOT proven — the payload

A persistently marooned villager does not actually get a descent scaffold
erected. Verbatim from the run:

    line 170: expected a descent scaffold to be planned and erected next to the
    marooned villager's pillar top (1008, 11, 1012) after 3 persistent
    observations

The assertion's own body was lost while splitting the file (a write landed before
the extraction step failed); only its failure message survives, and it is
recorded here rather than reconstructed from memory. Rewriting it from the
intent is the first task of the next attempt — and rewriting is cheap next to
pretending the body was preserved.

## The measurement that looked like success and was not

An earlier run appeared to show more scaffolding and was reported that way. It
was invalid: it predated the `connect_tick` fix, so the trigger was inert and its
numbers came out byte-identical to the baseline. The extra scaffolding in that
frame came from the doorway geometry, not from the descent trigger.

**There is still NO valid post-fix measurement of either lever.** Pre-fix, both
stand:

    CROWN: STALLDIAG room walls villager=(993, 9, 1004) state=5 pending=5
           [(994,6,1004) (994,7,1004) (994,8,1004) (992,7,1002) (992,8,1002)]
           final 24/29 wall cells BUILT
    ROOF:  ROOFDESCENT villager=(994, 10, 1003) state=3
           find_path(villager, settlement_ground=(998, 6, 1002)).size()=0 empty=true
    Telemetry: self_seal_climb=39 marooned_relocation=11

## Why it is being landed as plumbing-only rather than held back

The tick fix it uncovered is worth landing on its own (see
`scaffold_tick_wiring_test.gd`): the same constructor-time clock bug silently
disabled the DISMANTLE coordinator's tick, which meant SC-INV-2's deferred retry
could never fire in the shipped game at all. That is a real defect in already-
committed work, found only because a diagnostic printed
`dismantle_connected=false` on a real boot.

Shipping the trigger as "wired, therefore working" would add another
hosted-but-inert instance while fixing one. It is stated as plumbing.


---

## FIRST VALID POST-FIX MEASUREMENT (2026-07-28)

The first run in which the descent trigger was actually connected.

**CAVEAT FIRST, because it bounds what may be concluded:** two other Godot
processes were already running when this started (the parallel biome session).
Every wall-clock-CAPPED stage in this run was therefore competing for CPU.
Position-based results are unaffected; stage completion counts are not
trustworthy until this is repeated on a quiet machine.

### Lever 2 — ROOF DESCENT: PASSES

    before: villager=(994, 10, 1003)  find_path(...).size()=0   empty=true
    after:  villager=(1008, 4, 1000)  find_path(...).size()=11  empty=false

The villager is no longer on the roof. It is on the ground with an eleven-step
path home. This is the guarantee the story exists for, and it holds.

### Lever 1 — CROWN: improved, not yet passing

    before: villager=(993, 9, 1004) state=5 pending=5  final 24/29
    after:  villager=(998, 6, 1010) state=3 pending=2  final 27/29

The builder is no longer marooned on the crown — y=6 is ground. Pending fell
from five cells to two, and those two are `(992,7,1002)` and `(992,8,1002)`:
exactly the pair above the erased door cell, floating with no support beneath
them. That is a different problem from stranding.

### The mechanism is visibly doing work

    scaffold cells standing at roof stage: 21   (was 0)
    bed construction result: 2 / 2 cells        (first time ever)

### The regression that needs a quiet re-run

    roof construction result: 0 / 12   (was 10 / 12)

Either the scaffolding work is consuming the tick budget the roof used to get,
or the run was simply starved by the two foreign Godot processes. **Both are
plausible and neither is measured.** Do not conclude from this number until it
is reproduced on an idle machine — tonight's record for concluding from
plausible-looking evidence is 0 for 5.

### Telemetry unchanged

    self_seal_climb=40 marooned_relocation=11

The ADR-0009 climb mutations still carry the ascent. The TD's retirement
criterion (both zero) remains far off, and this story never claimed to reach it.

---

## The roof regression is REAL — repeated on a quiet machine (2026-07-28)

The caveat above said the roof number could not be trusted because two foreign
Godot processes were competing. Repeated with none running:

    construction result: 27 / 29 wall cells reached BUILT
    roof construction result: 0 / 12 cells reached BUILT
    scaffold cells standing at roof stage: 19
    bed construction result: 2 / 2 cells reached BUILT
    stage 7 (sleep): villager id=0 is SLEEPING at (993, 6, 1002)
    credited per-tick recovery delta = 0.3500 -> UNSHELTERED

Byte-for-byte the same outcome as the contended run. **So the regression is
mine, not the machine's.** Roof 10/12 before this change, 0/12 after.

### The trade, stated plainly

GAINED — descent works (villager off the roof, eleven-step path home; off the
crown, y=6 instead of y=9), three more wall cells (24->27 of 29), the first
completed bed ever, and the payoff loop's stages 6 and 7 reached for the first
time: the villager claims a bed it built itself and sleeps in it.

LOST — the roof, entirely.

### Most likely cause, held as a HYPOTHESIS and not a finding

Nineteen to twenty-one scaffold cells are real construction jobs, and there is
exactly one villager. The attention that used to reach the roof now goes into
building the scaffolding that gets the villager down. If that is right, the fix
is not to weaken the descent trigger but to stop erecting scaffolding the
villager does not need — or to let a descent scaffold be cheaper than a wall.

Tonight's record for hypotheses that read plausibly is 0 for 5, so this is
written down to be TESTED, not acted on. The cheapest test: count how many of
the 19 standing cells are descent scaffolds versus job scaffolds, and how many
ticks each consumed.
