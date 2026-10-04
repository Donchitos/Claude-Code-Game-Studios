# Error Recovery Protocol

Shared procedure for any skill that spawns agents via the `Agent` tool. Referenced from the
`## Error Recovery Protocol` section of each orchestration/review skill. Those
skills keep the two load-bearing imperatives (surface immediately, produce a
partial report) inline, and keep their own **Common blockers** list inline —
those are skill-specific. This file holds the full procedure.

## Trigger 0 — verify the artifact before reading the response

**Before applying anything below, and before treating a phase as complete: if
the return contract named a path, check that the path exists.** A named
artifact that is not on disk is a FAILED PHASE, no matter how the agent's
response reads.

This trigger exists because the three below are not sufficient. They fire on
BLOCKED, on an error, and on "cannot complete" — and an agent can fail in a way
that is none of those. Observed live: a `devops-engineer` spawned
as half of a parallel phase ran **26 tool calls and ~31,600 tokens**, then
returned a single fluent preamble — "I'll verify the build infrastructure…" —
with no path, no summary, no BLOCKED item, and **no file written**. Nothing in
steps 1–4 matches that shape. An orchestrator reading the transcript sees a
plausible response and advances, and half a parallel phase disappears with no
signal at all.

The work was not lost — resumed with an explicit "you did not honour the return
contract" message, the same agent completed in **one tool call**, because its
investigation was still in context. Only the write-and-return step had failed.
So the recovery is cheap; the detection is the hard part, and the detection
cannot come from reading the response.

**A fluent response is not evidence that a phase ran.** The artifact is —
observe the artifact, not the transcript. The rule applies to sub-agents
exactly as it does to skills.

When the path is missing:
1. Do **not** advance the pipeline or summarise the phase as done.
2. Resume the agent, naming the unmet contract explicitly and telling it that
   "I could not write" is a valid answer but silence is not. Prefer resuming
   over re-spawning — the context is usually still there, and a re-spawn pays
   for the whole investigation again.
3. If the second attempt also produces nothing, treat it as BLOCKED and apply
   steps 1–5 below.

---

If any spawned agent returns BLOCKED, errors, or cannot complete:

1. **Surface immediately** — report "[AgentName]: BLOCKED — [reason]" to the user
   before continuing to dependent phases. The reason names what is missing and
   where it was expected (the path or the input), so the user can supply it.
2. **Assess dependencies** — check whether the blocked agent's output is required
   by subsequent phases. If yes, do not proceed past that dependency point without
   user input.
3. **Offer options** via `AskUserQuestion`:
   - Skip this agent and note the gap in the final report — never fill the skipped agent's section with content of your own
   - Retry with narrower scope
   - Stop here and resolve the blocker first
4. **Always produce a partial report** — output whatever was completed. Never
   discard work because one agent blocked.
5. **A skip does not clear the block.** In a `/team-*` pipeline, choosing "skip
   this agent and note the gap" lets the remaining phases run, but the skipped
   agent's work is missing from what the pipeline delivers: the final verdict is
   BLOCKED, naming the skipped agent and its gap — never COMPLETE.
