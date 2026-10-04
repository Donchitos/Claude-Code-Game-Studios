# Agent Test Spec: devops-engineer

## Agent Summary
- **Domain**: CI/CD pipeline configuration, build scripts, version control workflow and branching strategy (trunk-based, per `CLAUDE.md`), release tagging scheme, automated test integration in CI, artifact management, environment management
- **Does NOT own**: Game code or assets, technology stack decisions and server infrastructure changes (technical-director approves), security audits (security-engineer), QA test strategy (qa-lead), game networking logic (network-programmer)
- **Gate IDs**: None; reports to technical-director and escalates build-time and infrastructure concerns there

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references CI/CD, build, deployment, version control)
- [ ] `tools:` reads `Read, Glob, Grep, Write, Edit, Bash` — Bash to run builds and pipelines; game code and assets are excluded by the body's "What This Agent Must NOT Do" list, not by the tool list
- [ ] Model tier is `sonnet` — frontmatter `model:` reads exactly `sonnet` (tiers: `.claude/docs/model-tiers.md`)
- [ ] Agent definition does not claim authority over game logic, security audits, or QA test design
- [ ] Its Implementation Workflow questions are pipeline questions (which platforms, engine version and export presets CI builds; where build secrets and signing keys live) — none asks how game code should be structured

---

## Test Cases

### Case 1: In-domain request — CI setup for a Godot project
**Input**: "Set up a CI pipeline for our Godot 4 project. It should run tests on every push to main and every pull request, and fail the build if tests fail."
**Expected behavior**:
- Produces a GitHub Actions workflow YAML (`.github/workflows/ci.yml` or equivalent)
- Uses the Godot headless test runner command from `coding-standards.md`: `godot --headless -s -d --remote-debug tcp://127.0.0.1:0 res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests --ignoreHeadlessMode`
- Configures trigger on `push` to main and `pull_request`
- Sets the job to fail (non-zero exit) when tests fail — does NOT add `continue-on-error` or any other setting that lets the pipeline pass on a test failure
- Shows the workflow and asks "May I write this to `.github/workflows/<file>`?" before writing it (Collaboration Protocol, step 5)

### Case 2: Out-of-domain request — game networking implementation
**Input**: "Implement the server-authoritative movement system for our multiplayer game."
**Expected behavior**:
- Does not produce game networking or movement code — "Modify game code or assets" is on its "What This Agent Must NOT Do" list
- Says the work belongs to a programmer and names who takes it: `lead-programmer` or `technical-director`, the agents its file names (naming `network-programmer`, the owner of netcode, also satisfies this)
- States what it can do instead: the infrastructure that builds, tests, and deploys the game once the netcode exists
- Does not conflate CI pipeline configuration with in-game network architecture

### Case 3: Build failure diagnosis
**Input**: "Our CI pipeline is failing on the merge step. The error is: 'Asset import failed: texture compression format unsupported in headless mode.'"
**Expected behavior**:
- Diagnoses the failure as an environment problem in the headless CI runner (the import step needs a capability the headless runner lacks), not a flaky step to retry
- Before stating how Godot 4.6 imports or compresses textures headlessly, cross-references `docs/engine-reference/godot/` — `VERSION.md` pins 4.6, past the model's training data — and says so when the reference does not cover it, rather than asserting version-specific behavior from memory
- Proposes at least one actionable fix that keeps the import and test steps in the pipeline, and names its tradeoff
- Does NOT remove the import step, skip the tests, or mark the job `continue-on-error` to get a green build — "Skip CI steps for speed" is forbidden, and `coding-standards.md` says "Never disable or skip failing tests to make CI pass — fix the underlying issue"
- Does NOT declare the pipeline unfixable

### Case 4: Branching strategy conflict
**Input**: "Half the team wants to use GitFlow with long-lived feature branches. The other half wants trunk-based development. How should we set this up?"
**Expected behavior**:
- Recommends trunk-based development because `CLAUDE.md` names it under Version Control ("Git with trunk-based development"), and says that is the model it followed
- Explains the model as its Branching Strategy section defines it: `main` is the always-shippable trunk, built and tested by CI on every push and pull request; work happens on short-lived branches merged back within a day or two through a pull request that passes CI; unfinished work ships dark behind a feature flag
- Rejects GitFlow's long-lived branches specifically — there is no long-lived integration branch beside `main`
- Covers releases and hotfixes per the same section: a release is a tag on `main`; a `release/*` branch is cut only to stabilise a release (bug fixes only, every fix also lands on `main`); a `hotfix/*` branch starts from the release tag (or its `release/*` branch, if one exists) and merges back to `main`, and to that `release/*` branch only if it exists
- Does NOT present this as a 50/50 choice, and does not adopt GitFlow on its own authority — the model comes from `CLAUDE.md`'s Version Control line, so switching means changing that line

### Case 5: Context pass — platform-specific build matrix
**Input context**: Project targets PC (Windows, Linux), Nintendo Switch, and PlayStation 5. CI runs on GitHub-hosted runners, which have no console export templates or SDKs installed.
**Input**: "Set up our CI build matrix so we get a build artifact for each target platform on every release branch push."
**Expected behavior**:
- Produces a build matrix configuration with four platform entries — Windows, Linux, Switch, PS5 — each a one-command build (Build Pipeline)
- Triggers release builds the way its Branching Strategy defines a release: on release tags on `main`, and on pushes to a `release/*` branch while one exists for stabilisation — and says why, rather than assuming a standing release branch
- Does NOT provision new build infrastructure for the console entries (e.g., self-hosted runners with the platform SDKs) on its own — "Change server infrastructure without technical-director approval" is forbidden, so it flags the requirement for technical-director approval instead of silently writing it into the config
- Organizes artifacts by platform name, with versioning and retention (Artifact Management)

---

## Protocol Compliance

- [ ] Stays within declared domain (CI/CD, build scripts, version control, artifacts, environments)
- [ ] Declines game code and networking requests and names who takes them (`lead-programmer` / `technical-director`, or the owning programmer)
- [ ] Recommends trunk-based development when branching strategy is contested, citing `CLAUDE.md`'s Version Control line
- [ ] Returns structured pipeline configurations (YAML, scripts), not freeform advice, and asks before writing them
- [ ] Never skips CI or test steps to get a green build, and routes infrastructure changes to technical-director for approval

---

## Coverage Notes
- Case 1 references `coding-standards.md` CI rules — verify this file is present and current before running this test
- Case 3 tests that the agent consults `docs/engine-reference/godot/` for version-specific behavior; it does not require the reference to cover headless import
- Case 4 (branching strategy) is a convention-enforcement test — agent must know the project convention, not just give neutral advice
- Case 5 supplies the target platforms in context; in a real project they come from `project.yaml`
- No automated runner; review manually or via `/skill-test`
