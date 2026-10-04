---
paths:
  - ".claude/skills/**"
  - ".claude/agents/**"
---

# Skill and Gate Authoring

**A check that cannot report that it did not run is not a check.**

The same shape recurs across unrelated subsystems, so treat it as the default
risk in any check you write, not as an unusual mistake.

The failure is always the same trade: a step that could not run produces output
indistinguishable from a step that ran and found nothing. Nobody reading the
output can tell which happened, and the permissive reading is the one that gets
believed, because it is the one that lets work proceed.

## The five obligations

### 1. Every gating verdict needs a "could not assess" value

If a skill emits a verdict something else depends on, its vocabulary must include
one — `NOT ASSESSED`, or the local equivalent — and the report must say *which*
of the reasons applied. A vocabulary of three confident verdicts forces every
unknown into a claim.

**Rank it deliberately.** It must outrank the pass value: a run that could not
assess part of its scope has not established that the scope is good. It must
**not** outrank the failure values: a known problem is more actionable than an
unknown, and demoting a real failure behind an access problem buries it.

**`NOT ASSESSED` is not a gentler failure verdict.** "I looked and found nothing"
and "I could not look" have different fixes — one needs work done, the other
needs access granted or an input classified. Collapsing them sends the reader to
the wrong fix.

### 2. An absent value may not default to the permissive one

Especially when **nothing in the framework writes that key**. Before defaulting,
check who sets it: a key with a reader and no writer takes its default branch on
every project that ever runs, so that branch is not an edge case — it is the
behaviour.

Over-running a check costs minutes. Under-running one ships the category unrun.

### 3. A skipped step announces itself

In the output, not only in the source. If a phase, category, or agent did not run
— wrong engine, missing config, unavailable input, a `team.size` that collapses
the pipeline — the artifact must say so by name. A silent skip and a successful
one are the same artifact.

A rule enforced in the body and never surfaced in the output is, to the reader,
identical to no rule at all.

### 4. Never assert what you cannot source — and wire the gap to the verdict

Where this repo pins external facts (`docs/engine-reference/**`), do not fill a
gap from training data. Write the gap down instead: `NOT SOURCEABLE — <what> is
not covered by <path>`.

**Flagging alone is not enough.** A named gap that does not reach the verdict is
just a comment. Wire it: a category with no sourced inputs must force obligation
1's value, so the gap makes the pass unreachable rather than sitting beside it.

A confidently wrong pattern list is worse than an absent one — it produces a scan
that looks thorough, finds nothing, and reads as a pass.

### 5. Gates derive their covered set; they do not enumerate it

An allowlist pins what was known when it was written and is silent about
everything added since. Derive the set from what the repo actually contains, so a
new skill or agent cannot ship outside coverage by simply not being on a list.

**If the category is not mechanically crisp, say so in the gate and keep the
list.** A gate that fires on forty files does not get fixed, it gets muted — and
a muted gate is worse than a narrow one, because it reads as coverage. When you
keep a list, record *why* derivation failed and state the obligation to extend it.

Two further gate rules earned the hard way:

- **Assert something that cannot be true by accident.** A check for the word
  "unity" was satisfied by a file path, and case-insensitively by "community".
  Assert a distinctive token instead.
- **A gate you have not watched fail is not a gate.** Break the thing it guards,
  confirm it fails, restore. One mutation per tool invocation — a batch that
  times out leaves the repo holding a broken file, and `trap … EXIT` does not
  survive `SIGTERM`.

## Evidence

Every row below is a real instance this rule was written to prevent.

| Where | What was indistinguishable from success |
|---|---|
| `team-*` engine step | Specialist skipped when no engine configured — output identical to a run that consulted one |
| `team-ui` accessibility gate | Passed vacuously; its criterion file did not exist |
| `yaml-helper` | Locked key in `project.local.yaml` dropped in silence; user saw the default they were overriding |
| all nine `team-*` | Pipeline printed six agents and ran one, with no statement of the difference |
| `/security-audit` | Godot-only greps returned zero hits on Unity/Unreal, and zero hits read as clean |
| `unity/VERSION.md` | "Post-cutoff" table listed pre-cutoff versions, inverting the signal it exists to send |
| `/security-audit` | `platform.multiplayer` had a reader and no writer; the network category never ran, on any project |
| `test-evidence-review` | No verdict for "could not check", so an unverifiable story got a verdict saying it was verified |
| the gate meant to catch all of this | Was a hand-written list, and read green over the gap |

## The test to apply

Before shipping a skill or gate, ask: **if this step silently did not run, what
would the output look like?**

If the answer is "the same", it is not finished.
