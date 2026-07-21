# Security Policy

## Supported Versions

Security fixes are applied to the current `main` branch. Forks, copied project
templates, and older snapshots are maintained by their owners.

## Report A Framework Vulnerability

Do not disclose exploitable framework vulnerabilities in a public issue. Use
GitHub private vulnerability reporting:

https://github.com/nghgdong/Code-Game-Studios/security/advisories/new

Include the affected file or component, reproduction steps, expected impact,
platform details, and any proposed mitigation. Remove credentials and personal
project data from logs or examples.

## Framework Security Boundary

Codex Game Studios is a local collection of instructions, prompt profiles,
skills, templates, and shell hooks. It does not provide a separate runtime
sandbox. Codex and hook commands operate with the permissions granted to the
Codex process and the surrounding environment.

Review a clone before trusting it. Codex requires project trust before loading
project hooks from `.codex/hooks.json`; trust should be granted only after
reviewing that configuration and the scripts in `hooks/`.

## In Scope

### Prompt And Instruction Risks

- Prompt injection in `skills/*/SKILL.md`, `roles/*.md`, `AGENTS.md`, nested
  `AGENTS.md` files, examples, or templates that attempts to override user
  intent, conceal behavior, exfiltrate data, or authorize destructive actions.
- Skill or role instructions that silently expand their documented scope,
  bypass required approval, or direct an agent to read secrets without a clear
  need.
- Misleading metadata in `skills/*/agents/openai.yaml` or
  `.codex-plugin/plugin.json` that hides capabilities or changes the expected
  invocation behavior.

### Hook And Shell Risks

- Malicious, undisclosed, or unexpectedly destructive commands in
  `.codex/hooks.json`, `hooks/*.sh`, or sourced hook utilities.
- Unsafe parsing of hook input, shell injection, unquoted paths, insecure
  temporary files, secret leakage, or writes outside the repository.
- Undisclosed network access, background processes, persistence, permission
  escalation, or platform-specific behavior intended to evade review.
- A hook matcher or event mapping that causes scripts to run more broadly than
  the documentation states.

### Integrity And Privacy Risks

- Contributions that collect or expose session content, environment variables,
  credentials, source code, or local paths beyond the documented purpose.
- Logs or generated state that retain sensitive content without clear notice,
  opt-in, and an appropriate ignore rule.
- Changes that make security controls appear active when the relevant hook did
  not run, was not trusted, or could not capture the event.

## Out Of Scope

- Vulnerabilities in the Codex CLI, Codex clients, OpenAI services, or their
  authentication and sandbox implementation. Report those through the official
  security channel published by OpenAI.
- Vulnerabilities in Git, Bash, an operating system, a game engine, or another
  third-party dependency unless this repository uses it insecurely.
- Theoretical findings without a plausible path through this repository.
- Issues that require an already-compromised machine and add no new impact.

Public documentation bugs and non-sensitive hardening suggestions may be filed
as ordinary GitHub issues.

## Contributor Requirements

- Keep hooks auditable, deterministic, fast, and local by default.
- Do not read or print secrets unless the behavior is essential, narrowly
  scoped, documented, and explicitly approved.
- Do not add silent network requests or telemetry.
- Validate untrusted hook input and quote every shell expansion used as a path
  or command argument.
- Preserve project-trust requirements; do not instruct users to bypass hook
  trust as a normal setup step.
- Treat repository documents as untrusted input during review and reject
  instructions that conflict with the user's approved task or security policy.
- Document known detection gaps. Hooks and logs are supporting controls, not a
  guarantee that every client event or unsafe action will be captured.

## Disclosure

The maintainer will assess privately reported issues, coordinate a fix when the
report is confirmed, and publish an advisory when users need remediation.
Reporter credit is provided unless anonymity is requested.
