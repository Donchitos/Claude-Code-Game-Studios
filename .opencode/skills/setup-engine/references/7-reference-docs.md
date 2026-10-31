# /setup-engine — Section 7: Populate Engine Reference Docs

> Part of `/setup-engine`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## 7. Populate Engine Reference Docs

**In this file:**

- First: does a reference set already exist for this engine?
- Sourcing rule for everything written in this section
- If WITHIN training data (LOW RISK):
- If BEYOND training data (MEDIUM or HIGH RISK):

### First: does a reference set already exist for this engine?

**Check before doing anything else.** The template ships
`docs/engine-reference/godot/`, `unity/` and `unreal/` **already populated**, so
"the directory exists and pins a version" is the state of *every* fresh project,
not an edge case. Both branches below say "create", and following either one
literally on a pre-populated directory either overwrites curated content or
leaves `project.yaml` and the CLAUDE.md-imported reference disagreeing.

Read `docs/engine-reference/<engine>/VERSION.md` and compare its
**Engine Version** to the version chosen in Section 3:

- **No directory, or no `VERSION.md`** → create, using the risk branch below.
- **Same version** → nothing to regenerate. Refresh `Last Docs Verified` only if you
  actually re-verified against the docs this run. Do not restamp a date you did
  not check. The one row still written is `Installed at pin time`, from
  Section 3 — its probe result is recorded whatever the outcome, after asking
  "May I record `Installed at pin time: [result]` in
  `docs/engine-reference/<engine>/VERSION.md`?" (it is a tracked file).
- **Directory pins an OLDER version than the one chosen** → **update, do not
  replace.** This is the common case. Show the changes below, then ask "May I
  update the `docs/engine-reference/<engine>/` files for [version]?" before editing.
  1. Edit `VERSION.md` in place: new **Engine Version**, new **Project Pinned**
     and **Last Docs Verified**, the `Installed at pin time` row from Section 3,
     and a new row in the post-cutoff timeline for each version added.
  2. **Append** to `breaking-changes.md`, `deprecated-apis.md` and
     `current-best-practices.md` under a heading naming the version span
     (`## 4.6 → 4.7`). Never truncate the older spans — a project migrating
     across two versions still needs the earlier one.
  3. Re-grade the older timeline rows if the cutoff moved past them.
- **Directory pins a NEWER version than the one chosen** → stop and ask. Someone
  pinned forward deliberately, or the version choice is wrong. Do not silently
  downgrade a curated reference.

### Sourcing rule for everything written in this section

**Never fill a gap from training data. Write the gap down instead.**

The whole purpose of these files is to be the thing agents consult *instead of*
their training data. A confidently wrong entry here is worse than no entry: it
produces work that looks verified and is not.

- Every claim must come from a page you fetched this run. Record the URL.
- If the official docs do not state something the template asks for — a release
  date, a subsystem's behaviour, web-export specifics — write
  **`NOT SOURCEABLE — <what>, not stated at <url>`** and move on.
- A `NOT SOURCEABLE` line is a successful outcome, not a failure to finish.
- Do not infer one fact from an adjacent one. "The migration guide lists no
  physics change" is not "the physics default is unchanged"; if you record the
  inference, label it as an inference and name what it rests on.

### If WITHIN training data (LOW RISK):

Ask: "May I create `docs/engine-reference/<engine>/VERSION.md`?" Wait for
confirmation, then create this minimal file:

```markdown
# [Engine] — Version Reference

| Field | Value |
|-------|-------|
| **Engine Version** | [version] |
| **Project Pinned** | [today's date] |
| **Installed at pin time** | [Section 3 result — the installed version, or NOT DETERMINED] |
| **LLM Knowledge Cutoff** | [the cutoff from the Section 6 coverage table] |
| **Risk Level** | LOW — version is within LLM training data |

## Note

This engine version is within the LLM's training data. Engine reference
docs are optional but can be added later if agents suggest incorrect APIs.

Run `/setup-engine refresh` to populate full reference docs at any time.
```

Do NOT create breaking-changes.md, deprecated-apis.md, etc. — they would
add context cost with minimal value.

### If BEYOND training data (MEDIUM or HIGH RISK):

Create the full reference doc set by searching the web:

1. **Search for the official migration/upgrade guide**:
   - `"[engine] [old version] to [new version] migration guide"`
   - `"[engine] [version] breaking changes"`
   - `"[engine] [version] changelog"`
   - `"[engine] [version] deprecated API"`

2. **Fetch and extract** from official documentation:
   - Breaking changes between each version from the training cutoff to current
   - Deprecated APIs with replacements
   - New features and best practices

Ask: "May I create the engine reference docs under `docs/engine-reference/<engine>/`?"

Wait for confirmation before writing any files.

3. **Create the full reference directory**:
   ```
   docs/engine-reference/<engine>/
   ├── VERSION.md              # Version pin + knowledge gap analysis
   ├── breaking-changes.md     # Version-by-version breaking changes
   ├── deprecated-apis.md      # "Don't use X → Use Y" tables
   ├── current-best-practices.md  # New practices since training cutoff
   └── modules/                # Per-subsystem references (create as needed)
   ```

4. **Populate each file** using real data from the web searches, following
   the format established in existing reference docs. Every file must have
   a "Last verified: [date]" header.

5. **For module files**: Only create modules for subsystems where significant
   changes occurred. Don't create empty or minimal module files.

---
