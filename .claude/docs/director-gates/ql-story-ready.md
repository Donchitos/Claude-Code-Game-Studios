> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# QL-STORY-READY — QA Lead Story Readiness Check

Agent: `qa-lead` | Model tier: session (inherit)

**Trigger**: Before a story is accepted into a sprint — invoked by `/create-stories`
and `/story-readiness`

**Context to pass**:
- Story file path — or, from `/create-stories` (which runs this gate before any
  story is written), the story inline
- Story type (Logic / Integration / Visual/Feel / UI / Config/Data)
- Acceptance criteria list (verbatim from the story)
- The GDD requirement (TR-ID and text) the story covers

**Prompt**:
> "Review this story's acceptance criteria for testability before it enters the
> sprint. Are all criteria specific enough that a developer would know unambiguously
> when they are done? For Logic-type stories: can every criterion be verified with
> an automated test? For Integration stories: is each criterion observable in a
> controlled test environment? Flag criteria that are too vague to implement
> against, and flag criteria that require a full game build to test (mark these
> DEFERRED, not BLOCKED). Return ADEQUATE (criteria are implementable as written),
> GAPS [specific criteria needing refinement], or INADEQUATE [criteria are too
> vague — story must be revised before sprint inclusion]."

**Verdicts**: ADEQUATE / GAPS / INADEQUATE
