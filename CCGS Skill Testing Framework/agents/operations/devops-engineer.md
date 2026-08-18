# Agent Test Spec: devops-engineer

## Agent Summary
- **Domain**: CI/CD pipeline configuration, build scripts, version control workflow enforcement, deployment infrastructure, branching strategy, environment management, automated test integration in CI
- **Does NOT own**: Game logic or gameplay systems, security audits (security-engineer), QA test strategy (qa-lead), game networking logic (network-programmer)
- **Model tier**: Sonnet
- **Gate IDs**: None; escalates deployment blockers to producer

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references CI/CD, build, deployment, version control)
- [ ] `allowed-tools:` list matches the agent's role (Read/Write for pipeline config files, shell scripts, YAML; no game source editing tools)
- [ ] Model tier is `haiku` (agent frontmatter sets haiku; coordination-rules.md assigns Haiku to read-and-format roles)
- [ ] Agent definition does not claim authority over game logic, security audits, or QA test design

---

## Test Cases

### Case 1: In-domain request — CI setup for a Godot project
**Input**: "Set up a CI pipeline for our Godot 4 project. It should run tests on every push to main and every pull request, and fail the build if tests fail."
**Expected behavior**:
- Produces a GitHub Actions workflow YAML (`.github/workflows/ci.yml` or equivalent)
- Uses the Godot headless test runner command from `coding-standards.md`: `godot --headless --script tests/gdunit4_runner.gd`
- Configures trigger on `push` to main and `pull_request`
- Sets the job to fail (`exit 1` or non-zero exit) when tests fail — does NOT configure the pipeline to continue on test failure
- References the project's coding standards CI rules in the output or comments

### Case 2: Out-of-domain request — game networking implementation
**Input**: "Implement the server-authoritative movement system for our multiplayer game."
**Expected behavior**:
- Does not produce game networking or movement code
- States clearly: "Game networking implementation is owned by network-programmer; I handle the infrastructure that builds, tests, and deploys the game"
- Does not conflate CI pipeline configuration with in-game network architecture

### Case 3: Build failure diagnosis
**Input**: "Our CI pipeline is failing on the merge step. The error is: 'Asset import failed: texture compression format unsupported in headless mode.'"
**Expected behavior**:
- Diagnoses the root cause: headless CI environment does not support GPU-dependent texture compression
- Proposes a concrete fix: either pre-import assets locally before CI runs (commit .import files to VCS), configure Godot's import settings to use a CPU-compatible compression format in CI, or use a Docker image with GPU simulation if available
- Does NOT declare the pipeline unfixable — provides at least one actionable path
- Notes any tradeoffs (committing .import files increases repo size; CPU compression may differ from GPU output)

### Case 4: Branching strategy conflict
**Input**: "Half the team wants to use GitFlow with long-lived feature branches. The other half wants trunk-based development. How should we set this up?"
**Expected behavior**:
- Recommends trunk-based development per project conventions (CLAUDE.md / coordination-rules.md specify Git with trunk-based development)
- Provides concrete rationale for the recommendation in this project's context: smaller team, fewer integration conflicts, faster CI feedback
- Does NOT present this as a 50/50 choice if the project has an established convention
- Explains how to implement trunk-based development with short-lived feature branches and feature flags if needed
- Does NOT override the project convention without flagging that doing so requires updating CLAUDE.md

### Case 5: Context pass — platform-specific build matrix
**Input context**: Project targets PC (Windows, Linux), Nintendo Switch, and PlayStation 5.
**Input**: "Set up our CI build matrix so we get a build artifact for each target platform on every release branch push."
**Expected behavior**:
- Produces a build matrix configuration with three platform entries: Windows, Linux, Switch, PS5
- Applies platform-appropriate build steps: PC uses standard Godot export templates; Switch and PS5 require platform-specific export templates (notes that console templates require licensed SDK access and are not publicly distributed)
- Does NOT assume all platforms can use the same build runner — flags that console builds may require self-hosted runners with licensed SDKs
- Organizes artifacts by platform name in the pipeline output

---

## Protocol Compliance

- [ ] Stays within declared domain (CI/CD, build scripts, version control, deployment)
- [ ] Redirects game logic and networking requests to appropriate programmers
- [ ] Recommends trunk-based development when branching strategy is contested, per project conventions
- [ ] Returns structured pipeline configurations (YAML, scripts) not freeform advice
- [ ] Flags platform SDK licensing constraints for console builds rather than silently producing incorrect configs

---

## Coverage Notes
- Case 1 (Godot CI) references `coding-standards.md` CI rules — verify this file is present and current before running this test
- Case 4 (branching strategy) is a convention-enforcement test — agent must know the project convention, not just give neutral advice
- Case 5 requires that project's target platforms are documented (in `technical-preferences.md` or equivalent)
- No automated runner; review manually or via `/skill-test`
