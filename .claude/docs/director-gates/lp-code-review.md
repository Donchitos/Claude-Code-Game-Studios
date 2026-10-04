> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# LP-CODE-REVIEW — Lead Programmer Code Review

Agent: `lead-programmer` | Model tier: Sonnet

**Trigger**: After a dev story is implemented (`/dev-story`, `/story-done`), or
as part of `/code-review`

**Context to pass**:
- Implementation file paths
- Story file path (for acceptance criteria)
- Relevant GDD section
- ADR that governs this system

**Prompt**:
> "Review this implementation against the story acceptance criteria and governing
> ADR. Does the code match the architecture boundary definitions? Are there
> violations of the coding standards or forbidden patterns? Is the public API
> testable and documented? Are there any correctness issues against the GDD rules?
> Return APPROVE, CONCERNS [specific issues], or REJECT [must be revised before merge]."

**Verdicts**: APPROVE / CONCERNS / REJECT
