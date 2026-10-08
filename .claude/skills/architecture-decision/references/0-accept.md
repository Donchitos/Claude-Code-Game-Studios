# /architecture-decision — Acceptance Mode

> Part of `/architecture-decision`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

**If the argument starts with `accept` followed by an ADR id**

(e.g., `/architecture-decision accept ADR-0005`):

Enter **acceptance mode**. This is the *only* path in the framework that moves an
ADR from `Proposed` to `Accepted`. Authoring always produces `Proposed`
(Step 5), while
`/create-control-manifest`, `/create-epics`, `/create-stories` and `/gate-check`
all require `Accepted` — so without this mode the pipeline had a state it could
enter and never leave.

1. **Resolve the id to a file, then read it.** Glob
   `docs/architecture/adr-NNNN-*.md` for the given number. If **no** file matches,
   or **more than one** does, stop and say which — do not pick one. If the file
   has no `## Status` section, stop and say so; a missing Status is exactly what
   retrofit mode is for.
2. **Check the current status.** If it is already `Accepted`, say so and stop.
   If it is `Deprecated` or `Superseded`, refuse: reviving a superseded decision
   is a new ADR, not a status edit.
3. **Check its dependencies first.** Read `## ADR Dependencies`.

   **If that section is absent, empty, or reads `UNKNOWN`, do not read it as
   "no dependencies" — refuse and say which:**
   > "ADR-0005's dependency section is [absent / UNKNOWN], so I cannot tell what
   > this decision rests on. An empty dependency list and an unexamined one look
   > identical here, and only one of them is safe to accept. Run
   > `/architecture-decision retrofit <path>` to establish it."

   A dependency check reading a field that defaults to empty is the vacuous-pass
   shape this gate exists to prevent — the check would examine nothing and report
   clean.

   If it depends on any ADR that is not itself `Accepted`, **refuse and name them**:
   > "ADR-0005 depends on ADR-0002, which is still Proposed. Accept ADR-0002
   > first — an accepted decision resting on an unaccepted one is not a decision,
   > it is a deferral with a different label."
   This is the same dependency rule `/architecture-review` already flags; here it
   is enforced rather than reported.
4. **Confirm with the user, always.** Per `CONTRACT.md`, acceptance authority is
   **the user, or `technical-director` on the user's explicit confirmation — no
   other agent, and never this skill on its own.** Use `AskUserQuestion`:
   - Prompt: "Accept ADR-NNNN — [title]? This is what unblocks stories and epics
     that depend on it."
   - Options: `[A] Yes — accept it` / `[B] Not yet — leave it Proposed`
   **This prompt fires regardless of `modes.automation`, including `autonomous`.**
   Acceptance is the decision the whole architecture pipeline gates on; it is not
   a step to be inferred.
5. **Find the stories this will unblock, BEFORE the prompt in step 4.** Grep
   every story for a Blocked Status line —
   `Grep pattern="Status\**:\**\s*Blocked" path="production/epics" glob="**/story-*.md" output_mode="files_with_matches"`,
   which matches `> **Status**: Blocked` (the form `/create-stories` writes),
   `**Status:** Blocked` and `Status: Blocked` — and keep the files that name
   this ADR's id as the reason they are blocked. That pairing is what "blocked
   pending this ADR" means — a story blocked for an unrelated reason will not
   name it. Leave out a story that names this ADR only as the successor to point
   at (`point the story at ADR-NNNN`, the note for a `Deprecated` or
   `Superseded` ADR): it is still governed by the old ADR, and accepting the
   successor does not re-point it.
   > **Stories live only under `production/epics/`.** A flat top-level stories
   > directory does not exist and no skill creates one — never write or match a
   > path outside `production/epics/`. `/dev-story` matches entries *by file
   > path*, so a story recorded under any other path silently fails to match and
   > never gets picked up.

   Feed the count into step 4's prompt so it reads *"3 stories become Ready"*
   rather than a generic claim: **the user is being asked to authorise an effect, and should be
   shown the effect.** If none match, say "no stories are waiting on this" — that
   is useful information, not an empty result to omit.
6. On confirmation, `Edit` the `## Status` line to `Accepted`. Leave an existing
   `## Date` as it is: it records when the ADR was written, and `/create-stories`
   stamps stories with it (or `## Last Verified`), so rewriting it on acceptance
   would make every story drafted against the Proposed ADR look out of date to
   `/dev-story`. **If that section is absent, add it** with today's date — retrofit
   mode already owns this shape, and acceptance must not fail on a template that
   predates the field.
7. Then set each story found in step 5 from `Blocked` to `Ready`. Unblocking is a
   consequence of acceptance, never of authoring — see Step 6's note below.
8. Report what moved: the ADR (and its `## Date`, if one was added), and every
   story that became Ready.
