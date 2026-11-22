# Skill Test Spec: /asset-generate

## Skill Summary

`/asset-generate` turns one approved `/asset-spec` prompt into a reviewable image preview through optional Atlas Cloud integration. It validates the live model schema and asks before every billable POST. Generation POSTs are never retried; prediction GET polling is bounded.

## Static Assertions (Structural)

- [ ] Has all required frontmatter fields
- [ ] Has at least two phase headings
- [ ] Contains verdict keywords: COMPLETE, BLOCKED, CONCERNS
- [ ] Requires explicit approval before a billable request
- [ ] Ends with `/asset-audit` as a next-step handoff

## Test Cases

### Case 1: Approved visual spec generates one preview

**Fixture:** One approved visual asset spec has a Generation Prompt, Atlas credentials are configured, and the output path does not exist.

**Expected behavior:** The skill shows model, live price, dimensions, and output path; asks for approval; submits once; reviews the saved image.

**Assertions:**
- [ ] Reads the asset spec and available art standards before proposing generation
- [ ] Asks before the billable request
- [ ] Saves only to a project-relative path
- [ ] Ends with COMPLETE only after image review

### Case 2: Missing or unapproved prompt

**Fixture:** The selected asset is unapproved or has no Generation Prompt.

**Expected behavior:** The skill returns BLOCKED without a network submission.

**Assertions:**
- [ ] No generation command is run
- [ ] The missing prerequisite is named
- [ ] `/asset-spec` remains the source of visual direction

### Case 3: Generation polling fails

**Fixture:** The POST returns a prediction id, but bounded GET polling does not reach a terminal status.

**Expected behavior:** The skill reports the failure and does not rerun the generation command.

**Assertions:**
- [ ] Generation POST is not retried
- [ ] Prediction GET polling is bounded
- [ ] User must explicitly approve any later second request

## Protocol Compliance

- [ ] Atlas Cloud remains an optional provider
- [ ] Credentials are read only from environment variables and never printed
- [ ] Existing files are not overwritten without explicit approval
- [ ] Generated previews are not automatically marked production-ready
- [ ] Ends with `/asset-audit`
