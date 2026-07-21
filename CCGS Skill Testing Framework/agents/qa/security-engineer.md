# Agent Test Spec: security-engineer

## Agent Summary
Domain: Anti-cheat systems, save data security, network security, vulnerability assessment, and data privacy compliance.
Does NOT own: game logic design (gameplay-programmer), server infrastructure (devops-engineer).
No fixed model routing is required; the caller selects the available Codex model.
No gate IDs assigned.

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references anti-cheat / security / vulnerability assessment)
- [ ] Role boundaries and file ownership match the stated domain
- [ ] Does not require fixed model routing; the calling Codex client selects the available model
- [ ] Agent definition does not claim authority over game logic design or server deployment

---

## Test Cases

### Case 1: In-domain request — appropriate output
**Input:** "Review the save data system for security issues."
**Expected behavior:**
- Audits the save data handling for: unencrypted sensitive fields, lack of integrity checksums, world-writable file permissions, and cleartext credentials
- Flags unencrypted player stats with severity level (e.g., MEDIUM — enables offline stat manipulation)
- Recommends: AES-256 encryption for sensitive fields, HMAC checksum for tamper detection
- Produces a prioritized finding list (CRITICAL / HIGH / MEDIUM / LOW)
- Does NOT change the save system code directly — produces findings for gameplay-programmer or engine-programmer to act on

### Case 2: Out-of-domain request — redirects correctly
**Input:** "Design the matchmaking algorithm to pair players by skill rating."
**Expected behavior:**
- Does NOT produce matchmaking algorithm design
- Explicitly states that matchmaking design belongs to `network-programmer`
- Redirects the request to `network-programmer`
- May note it can review the matchmaking system for security vulnerabilities (e.g., rating manipulation) once the design is complete

### Case 3: Critical vulnerability — SQL injection
**Input:** (Hypothetical) "Review this server-side query handler: `query = 'SELECT * FROM users WHERE id=' + user_input`"
**Expected behavior:**
- Flags this as a CRITICAL vulnerability (SQL injection via unsanitized user input)
- Provides immediate remediation: parameterized queries / prepared statements
- Recommends a security review of all other query-construction code in the codebase
- Escalates to `technical-director` given CRITICAL severity — does not leave the finding unescalated

### Case 4: Security vs. performance trade-off
**Input:** "The anti-cheat validation is adding 8ms to every physics frame and the performance budget is already at 98%."
**Expected behavior:**
- Surfaces the trade-off clearly: removing/reducing validation creates exploit surface; keeping it blows the performance budget
- Does NOT unilaterally drop the security measure
- Escalates to `technical-director` with both the security risk level and the performance impact quantified
- Proposes options: async validation (reduces frame impact, adds latency), sampling-based checks (reduces frequency, accepts some cheating), or budget renegotiation

### Case 5: Context pass — OWASP guidelines
**Input:** OWASP Top 10 (2021) provided in context. Request: "Audit the game's login and account system."
**Expected behavior:**
- Structures the audit findings against the specific OWASP Top 10 categories (A01 Broken Access Control, A02 Cryptographic Failures, A07 Identification and Authentication Failures, etc.)
- References specific control IDs from the provided list rather than generic advice
- Flags each finding with the relevant OWASP category
- Produces a compliance gap list: which controls are met, which are missing, which are partial

---

## Protocol Compliance

- [ ] Stays within declared domain (anti-cheat, save security, network security, vulnerability assessment)
- [ ] Redirects matchmaking / game logic requests to appropriate agents
- [ ] Returns structured findings with severity classification (CRITICAL / HIGH / MEDIUM / LOW)
- [ ] Does not implement fixes unilaterally — produces findings for the responsible programmer
- [ ] Escalates CRITICAL findings to technical-director immediately
- [ ] References specific standards (OWASP, GDPR, etc.) when provided in context

---

## Coverage Notes
- Save data audit (Case 1) confirms the agent produces actionable, prioritized findings not generic advice
- CRITICAL vulnerability escalation (Case 3) verifies the agent's severity classification and escalation path
- Performance trade-off (Case 4) confirms the agent does not silently drop security measures to hit a budget
