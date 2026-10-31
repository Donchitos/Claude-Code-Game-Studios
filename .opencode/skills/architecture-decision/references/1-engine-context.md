# /architecture-decision — Step 1: Load Engine Context

> Part of `/architecture-decision`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## 1. Load Engine Context (ALWAYS FIRST)

Before doing anything else, establish the engine environment:

1. Read `docs/engine-reference/[engine]/VERSION.md` to get:
   - Engine name and version
   - LLM knowledge cutoff date
   - Post-cutoff version risk levels (LOW / MEDIUM / HIGH)

2. Identify the **domain** of this architecture decision from the title or
   user description. Common domains: Physics, Rendering, UI, Audio, Navigation,
   Animation, Networking, Core, Input, Scripting.

3. Read the corresponding module reference if it exists:
   `docs/engine-reference/[engine]/modules/[domain].md`

4. Read `docs/engine-reference/[engine]/breaking-changes.md` — flag any
   changes in the relevant domain that post-date the LLM's training cutoff.

5. Read `docs/engine-reference/[engine]/deprecated-apis.md` — flag any APIs
   in the relevant domain that should not be used.

6. **Display a knowledge gap warning** before proceeding if the domain carries
   MEDIUM or HIGH risk:

   ```
   ⚠️  ENGINE KNOWLEDGE GAP WARNING
   Engine: [name + version]
   Domain: [domain]
   Risk Level: HIGH — This version is post-LLM-cutoff.

   Key changes verified from engine-reference docs:
   - [Change 1 relevant to this domain]
   - [Change 2]

   This ADR will be cross-referenced against the engine reference library.
   Proceed with verified information only — do NOT rely solely on training data.
   ```

   If no engine has been configured yet, prompt: "No engine is configured.
   Run `/setup-engine` first, or tell me which engine you are using."

---
