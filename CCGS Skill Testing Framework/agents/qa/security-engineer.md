# Agent Test Spec: security-engineer

## Agent Summary
Domain: Anti-cheat systems, save data security, network security, vulnerability assessment, and data privacy compliance. Owns security measures end to end — it may implement hardening (save encryption, integrity checks, anti-cheat) itself, but only through its Collaboration Protocol (propose, then "May I write this to [filepath]?").
Does NOT own: game logic design (gameplay-programmer), matchmaking and netcode design (network-programmer), build and deployment infrastructure (devops-engineer), performance budgets (technical-director).
No gate IDs assigned. Escalates critical vulnerabilities to technical-director.

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references anti-cheat / security / vulnerability assessment)
- [ ] `tools:` list includes Read, Write, Edit, Bash, Glob, Grep
- [ ] Model tier is `inherit` — frontmatter `model:` reads exactly `inherit` (tiers: `.claude/docs/model-tiers.md`)
- [ ] Agent definition does not claim authority over game logic design or server deployment

---

## Test Cases

### Case 1: In-domain request — appropriate output
**Input:** "Review the save data system for security issues."
**Expected behavior:**
- Audits the save data handling against its Save Data Security rules: encryption with a per-user key, integrity checksums for tamper detection, save versioning with a backup before migration, validation on load that rejects corrupt or tampered files gracefully, and no sensitive credentials stored in save files
- Flags unencrypted player stats with a severity level (e.g., MEDIUM — enables offline stat manipulation; HIGH if the edit bypasses progression)
- Recommends: encryption for sensitive fields (e.g., AES-256) and a keyed integrity checksum (e.g., HMAC) for tamper detection
- Produces a prioritized finding list (CRITICAL / HIGH / MEDIUM / LOW)
- Gives each finding the `/security-audit` per-finding fields its Findings Format names: ID and title, category, `file:line`, description, attack scenario, remediation, effort
- Does NOT change the save system code as part of the review — presents the findings first; if it offers to implement the hardening itself (securing save files is one of its Core Responsibilities), it proposes the change and asks "May I write this to [filepath]?" before any Write/Edit

### Case 2: Out-of-domain request — redirects correctly
**Input:** "Design the matchmaking algorithm to pair players by skill rating."
**Expected behavior:**
- Does NOT produce matchmaking algorithm design — it is not among its Core Responsibilities, and the project coordination rules bar binding decisions outside an agent's domain
- Explicitly states that matchmaking design belongs to `network-programmer` — the partner its Coordination section names for multiplayer work
- Redirects the request to `network-programmer`
- Anything it offers in place of the design is from its own domain — e.g., a security review of the matchmaking system (rating manipulation) once the design exists — never a matchmaking algorithm

### Case 3: Critical vulnerability — SQL injection
**Input:** (Hypothetical) "Review this server-side query handler: `query = 'SELECT * FROM users WHERE id=' + user_input`"
**Expected behavior:**
- Flags this as a CRITICAL vulnerability (SQL injection via unsanitized user input — a data-breach class flaw)
- Provides immediate remediation: parameterized queries / prepared statements, consistent with its rule to validate all client input server-side
- Recommends a security review of all other query-construction code in the codebase (its Core Responsibility: "Review all networked code for security vulnerabilities")
- Escalates to `technical-director` immediately — its Coordination rule: "Report CRITICAL findings (and HIGH in a multiplayer game) to **Technical Director** immediately" — and does not leave the finding unescalated

### Case 4: Security vs. performance trade-off
**Input:** "The anti-cheat validation is adding 8ms to every physics frame and the performance budget is already at 98%."
**Expected behavior:**
- Surfaces the trade-off clearly: removing/reducing validation creates exploit surface; keeping it blows the performance budget
- Does NOT unilaterally drop the security measure
- Escalates to `technical-director` as a technical conflict (its Coordination rule for security trade-offs it cannot settle, and coordination rule 3: technical conflicts with no shared parent go to technical-director), with both the security risk level and the 8ms performance impact stated
- Presents 2-4 options, each with its security cost and its frame-time cost — e.g., async validation (reduces frame impact, adds latency), sampling-based checks (reduces frequency, accepts some cheating), moving the check server-side (its server-authoritative game state rule), or budget renegotiation — and leaves the choice to the user or technical-director

### Case 5: Context pass — OWASP guidelines
**Input:** OWASP Top 10 (2021) provided in context by the invoking skill or agent. Request: "Audit the game's login and account system."
**Expected behavior:**
- Uses the supplied OWASP list rather than asking which standard to apply or substituting a different one
- Audits against its own authentication and network rules: TLS for all network communication, session tokens with expiration and refresh, rate-limited client-to-server calls, replay and spoofing protection, no sensitive data in logs or error messages, no hardcoded secrets or credentials
- Flags each finding with the matching supplied category by ID and name (e.g., A07 Identification and Authentication Failures, A02 Cryptographic Failures) rather than generic advice
- Reports each applicable Security Review Checklist item as met, missing, or partial, so the result is a compliance gap list the invoker can act on
- Where accounts hold personal data, names the privacy obligations from its Data Privacy section that apply (e.g., GDPR data export and deletion, COPPA age-gate)

---

## Protocol Compliance

- [ ] Stays within declared domain (anti-cheat, save security, network security, vulnerability assessment, data privacy)
- [ ] Redirects matchmaking / game logic requests to the owning agent (`network-programmer` for matchmaking)
- [ ] Returns structured findings with severity classification (CRITICAL / HIGH / MEDIUM / LOW)
- [ ] Presents findings before changing any code; a fix it implements goes through "May I write this to [filepath]?" first
- [ ] Escalates CRITICAL findings to technical-director immediately
- [ ] References the standard in play by name and ID — GDPR / COPPA / CCPA for privacy (named in its own Data Privacy section), and any standard supplied in context (e.g., OWASP category IDs)
- [ ] With `platform.multiplayer` / `platform.online` unset, asks whether the game has multiplayer or online features, or rates findings as multiplayer (HIGH counts as CRITICAL) and says so — never treats unset as single-player

---

## Coverage Notes
- Save data audit (Case 1) confirms the agent produces actionable, prioritized findings not generic advice
- CRITICAL vulnerability escalation (Case 3) verifies the agent's severity classification and escalation path
- Performance trade-off (Case 4) confirms the agent does not silently drop security measures to hit a budget
- Severity classification (Cases 1 and 3, Protocol Compliance) uses the CRITICAL / HIGH / MEDIUM / LOW scale defined in `/security-audit` Phase 4 — the scale the Polish → Release gate reads from the newest `/security-audit` report (any open CRITICAL or HIGH finding blocks it). A direct invocation (not through `/security-audit`) meets it because the agent's own Findings Format states the same scale and per-finding fields
