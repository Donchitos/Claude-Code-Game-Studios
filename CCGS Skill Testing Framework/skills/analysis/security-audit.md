# Skill Test Spec: $security-audit

## Skill Summary

`$security-audit` audits the game for security risks including save data
integrity, network communication, anti-cheat exposure, and data privacy. It
reads source files in `src/` for security patterns and checks whether sensitive
data is handled correctly. No director gates are invoked. The skill does not
write files (findings report only). Verdicts: SECURE, CONCERNS, or
VULNERABILITIES FOUND.

---

## Static Assertions (Structural)

Verified automatically by `$skill-test static` — no fixture needed.

- [ ] Has non-empty `name` and `description`; `agents/openai.yaml` has non-empty display name and short description
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: SECURE, CONCERNS, VULNERABILITIES FOUND
- [ ] Does NOT require "May I write" language (read-only; findings report only)
- [ ] Has a next-step handoff (what to do with findings)

---

## Director Gate Checks

None. Security audit is a read-only advisory skill; no gates are invoked.

---

## Test Cases

### Case 1: Happy Path — Save data encrypted, no hardcoded credentials

**Fixture:**
- `src/core/save_system.gd` uses `Crypto` class to encrypt save data before writing
- No hardcoded API keys, passwords, or credentials in any `src/` file
- No version numbers or internal build IDs exposed in client-facing output

**Input:** `$security-audit`

**Expected behavior:**
1. Skill scans `src/` for security patterns: encryption usage, hardcoded credentials, exposed internals
2. All checks pass: save data encrypted, no credentials found, no exposed internals
3. Findings report shows all checks PASS
4. Verdict is SECURE

**Assertions:**
- [ ] Skill checks save data handling for encryption usage
- [ ] Skill scans for hardcoded credentials (API keys, passwords, tokens)
- [ ] Skill checks for version/build numbers exposed to players
- [ ] All checks shown in findings report
- [ ] Verdict is SECURE when all checks pass

---

### Case 2: Vulnerabilities Found — Unencrypted save data and exposed version

**Fixture:**
- `src/core/save_system.gd` writes save data as plain JSON (no encryption)
- `src/ui/debug_overlay.gd` contains: `label.text = "Build: " + ProjectSettings.get("application/config/version")`
  (exposes internal build version to player)

**Input:** `$security-audit`

**Expected behavior:**
1. Skill scans `src/` — finds unencrypted save write in `save_system.gd`
2. Skill finds exposed version string in `debug_overlay.gd`
3. Both findings are flagged as VULNERABILITIES
4. Verdict is VULNERABILITIES FOUND
5. Skill provides remediation recommendations for each vulnerability

**Assertions:**
- [ ] Unencrypted save data is flagged as a vulnerability with file and approximate line
- [ ] Exposed version string is flagged as a vulnerability
- [ ] Remediation suggestion is given for each vulnerability
- [ ] Verdict is VULNERABILITIES FOUND when any vulnerability is detected
- [ ] No files are written or modified

---

### Case 3: Online Features Without Authentication — CONCERNS

**Fixture:**
- `src/networking/lobby.gd` exists with functions: `join_lobby()`, `send_chat()`
- No authentication check is found before `send_chat()` — players can call it without being verified
- Game has online multiplayer features (inferred from file presence)

**Input:** `$security-audit`

**Expected behavior:**
1. Skill scans `src/networking/` — detects online feature code
2. Skill checks for authentication guard before network calls — finds none on `send_chat()`
3. Flags: "Online feature without authentication check — CONCERNS"
4. Verdict is CONCERNS (not VULNERABILITIES FOUND, as this is a missing control, not an exploit)

**Assertions:**
- [ ] Skill detects online features by scanning for networking source files
- [ ] Missing authentication checks before network operations are flagged
- [ ] Verdict is CONCERNS (advisory severity) for missing authentication guards
- [ ] Output recommends adding authentication before network calls

---

### Case 4: Edge Case — No Source Files to Analyze

**Fixture:**
- `src/` directory does not exist or is completely empty

**Input:** `$security-audit`

**Expected behavior:**
1. Skill attempts to scan `src/` — no files found
2. Skill outputs an error: "No source files found in `src/` — nothing to audit"
3. No findings report is generated
4. No verdict is emitted

**Assertions:**
- [ ] Skill does not crash when `src/` is empty or absent
- [ ] Output clearly states that no source files were found
- [ ] No verdict is emitted (there is nothing to assess)
- [ ] Skill suggests verifying the `src/` directory path

---

### Case 5: Gate Compliance — No gate; security-engineer invoked separately

**Fixture:**
- Source files exist; 1 CONCERNS-level finding detected (debug logging enabled in release build)
- `review-mode.txt` contains `full`

**Input:** `$security-audit`

**Expected behavior:**
1. Skill scans source; finds debug logging active in release path
2. No director gate is invoked regardless of review mode
3. Verdict is CONCERNS
4. Output notes: "For formal security review, consider engaging a security-engineer agent"
5. Findings are presented as a read-only report; no files written

**Assertions:**
- [ ] No director gate is invoked in any review mode
- [ ] Security-engineer consultation is suggested (not mandated)
- [ ] No files are written
- [ ] Verdict is CONCERNS for advisory-level security findings

---

## Protocol Compliance

- [ ] Reads source files in `src/` before auditing
- [ ] Checks save data encryption, hardcoded credentials, exposed internals, auth guards
- [ ] Provides remediation recommendations for each finding
- [ ] Does not write any files (read-only skill)
- [ ] No director gates are invoked
- [ ] Verdict is one of: SECURE, CONCERNS, VULNERABILITIES FOUND

---

## Coverage Notes

- Anti-cheat analysis (client-side value validation, server authority) is not
  explicitly tested here; it follows the CONCERNS or VULNERABILITIES pattern
  depending on severity.
- Data privacy compliance (GDPR, COPPA) is out of scope for this spec; those
  require legal review beyond code scanning.
