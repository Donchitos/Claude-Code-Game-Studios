# Agent Test Spec: localization-lead

## Agent Summary
- **Domain**: Internationalization (i18n) architecture, string extraction workflows and tooling configuration, locale testing methodology, translation pipeline design (extraction → TMS → import), string quality standards, locale-specific formatting rules (plurals, RTL, date/number formats)
- **Does NOT own**: Game narrative content and dialogue writing (writer), code implementation of i18n calls (gameplay-programmer), translation work itself (external translators)
No fixed model routing is required; the caller selects the available Codex model.
- **Gate IDs**: None; escalates pipeline architecture decisions to technical-director when they affect build systems

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references i18n, string extraction, locale pipeline, localization)
- [ ] Role boundaries and file ownership match the stated domain
- [ ] Does not require fixed model routing; the calling Codex client selects the available model
- [ ] Agent definition does not claim authority over narrative content, game code implementation, or translation quality

---

## Test Cases

### Case 1: In-domain request — string extraction pipeline for a Unity project
**Input**: "Set up a string extraction pipeline for our Unity game. We need to get all localizable strings into a format translators can work with."
**Expected behavior**:
- Produces a concrete extraction configuration covering: which string types to extract (UI labels, dialogue, item descriptions — not debug strings), the tool to use (e.g., Unity Localization package string tables, or a custom extraction script targeting specific component types), and the output format (CSV, XLIFF, or TMX — notes which formats are compatible with common TMS tools like Crowdin or Lokalise)
- Specifies the folder structure: e.g., `assets/localization/en/` as the source locale, `assets/localization/{locale}/` for translated files
- Notes that string keys must be stable (do not use index-based keys) — key changes break all existing translations
- Does NOT produce Unity C# code for the i18n implementation — marks as [TO BE IMPLEMENTED BY PROGRAMMER]

### Case 2: Out-of-domain request — translate game dialogue
**Input**: "Translate the following English dialogue into French: 'Well met, traveler. The road ahead is treacherous.'"
**Expected behavior**:
- Does not produce a French translation
- States clearly: "localization-lead owns the pipeline, quality standards, and workflow; actual translation work is performed by human translators or approved translation vendors — I am not a translator"
- Optionally notes what information a translator would need: context (who is speaking, to whom, game genre/tone), character limit constraints if any, glossary terms (e.g., if "traveler" has a game-specific translation)

### Case 3: Domain boundary — missing plural forms in Russian locale
**Input**: "Our Russian locale files only have a singular form for item quantity strings. Russian requires multiple plural forms (1 item, 2-4 items, 5+ items use different forms)."
**Expected behavior**:
- Identifies this as a locale-specific plural form gap: Russian has 3 plural categories (one, few, many) per CLDR/Unicode plural rules — a single string is insufficient
- Flags it as a localization quality bug, not a minor style issue — incorrect plural forms are grammatically wrong and visible to players
- Recommends the fix: update the string extraction format to support CLDR plural categories (one/few/many/other), and flag to the translation vendor that Russian strings need all plural forms
- Notes which other languages in the pipeline also require plural form support (e.g., Polish, Czech, Arabic)
- Does NOT suggest using a numeric threshold workaround as a substitute for proper CLDR plural support

### Case 4: String key naming conflict between two systems
**Input**: "Our UI system uses keys like 'button_confirm' and 'button_cancel'. Our dialogue system uses 'confirm' and 'cancel' for the same concepts. Translators are confused about which to use."
**Expected behavior**:
- Identifies the conflict: two systems use different key naming conventions for semantically identical strings, creating duplicate translation work and translator confusion
- Produces a naming convention resolution: domain-prefixed keys with a consistent separator (e.g., `ui.button.confirm`, `ui.button.cancel`) — all systems use the same key for shared concepts
- Recommends that shared UI primitives (Confirm, Cancel, Back, OK) use a single canonical key in a shared namespace, referenced by both systems
- Provides a migration path: map old keys to new keys, update all string references in both systems, deprecate old keys after one release cycle
- Does NOT recommend maintaining two separate keys for the same concept

### Case 5: Context pass — pipeline accommodates RTL languages
**Input context**: Target locales include English (en), French (fr), German (de), Arabic (ar), and Hebrew (he).
**Input**: "Design the localization pipeline for this project."
**Expected behavior**:
- Identifies Arabic and Hebrew as RTL languages — explicitly calls this out as a pipeline requirement
- Designs the pipeline to include: RTL text rendering support (flag for programmer: UI must support RTL layout mirroring), bidirectional (bidi) text handling in string tables, locale-specific testing checklist entry for RTL layout
- Does NOT design a pipeline that only accounts for LTR languages when RTL locales are specified
- Notes that Arabic also requires a different plural form structure (6 plural categories in CLDR) — flags for translation vendor
- Output includes all five locales in the pipeline architecture, not just the default (en)

---

## Protocol Compliance

- [ ] Stays within declared domain (pipeline, extraction, string quality, locale formats, i18n architecture)
- [ ] Does not produce translations — redirects translation work to human translators/vendors
- [ ] Flags locale-specific gaps (plural forms, RTL) as quality bugs requiring pipeline changes
- [ ] Produces a unified key naming convention when conflicts arise — does not accept dual conventions
- [ ] Incorporates all provided target locales, including RTL languages, into pipeline design

---

## Coverage Notes
- Case 3 (plural forms) and Case 5 (RTL) are locale-correctness tests — these affect shipping quality in non-English markets
- Case 4 (key naming conflict) is a pipeline hygiene test — duplicate keys cause ongoing translator confusion and cost
- Case 5 requires the target locale list to be in context; if not provided, agent should ask before designing the pipeline
- No automated runner; review manually or via `$skill-test`
