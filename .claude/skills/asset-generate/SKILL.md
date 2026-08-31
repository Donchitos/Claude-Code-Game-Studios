---
name: asset-generate
description: "Generate one reviewable game-art preview from an approved asset spec using Atlas Cloud as an optional image provider. Validates the live model schema, asks before the billable request, and saves the image to a project-relative path."
argument-hint: "[spec-path | ASSET-NNN] [--output <relative-path>]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion
model: sonnet
---

# Asset Generate

Generate a single visual preview after `/asset-spec` has produced an approved prompt. Atlas Cloud is optional: this command does not replace the project's existing art workflow or default provider.

## Phase 1: Resolve the Approved Spec

Parse the argument as either a spec path or an `ASSET-NNN` identifier.

1. If a path is provided, require it to remain under `design/assets/specs/` and read it.
2. If an identifier is provided, search `design/assets/specs/*.md` for exactly one matching heading.
3. If there is no argument, list approved visual assets and use `AskUserQuestion` to select one.
4. Stop with `BLOCKED` if the asset is audio-only, has no **Generation Prompt**, is not approved, or matches more than one spec.

Read `design/art/art-bible.md` and `.claude/docs/technical-preferences.md` when present. Extract the asset name, visual description, generation prompt, dimensions, format, and naming convention. Do not invent missing visual direction.

## Phase 2: Propose One Preview

Build a proposal using the approved prompt and standards:

```text
Asset: ASSET-NNN — [name]
Provider: Atlas Cloud (optional)
Model: google/nano-banana-pro/text-to-image-developer
Aspect ratio: [schema-supported ratio]
Resolution: 1k
Preview path: assets/art/previews/[standards-compliant-name].png
Estimated model price: read from the live catalog; do not hardcode it
```

If `ATLASCLOUD_API_KEY` is unavailable, return `BLOCKED` with setup guidance. Never print or read the key value. Do not submit a fallback request to another provider.

Use `AskUserQuestion` before any paid request:

> "This will submit exactly one billable Atlas Cloud image request using the approved prompt. Generate this preview?"

Options: `[A] Generate once` / `[B] Revise settings` / `[C] Stop`

Do not continue without explicit approval.

## Phase 3: Generate Exactly Once

Run the bundled standard-library helper from the project root:

```bash
python3 .claude/skills/asset-generate/scripts/atlas_generate.py \
  --spec "design/assets/specs/[spec-file].md" \
  --asset-id "ASSET-NNN" \
  --aspect-ratio "[ratio]" \
  --resolution "1k" \
  --output "assets/art/previews/[name].png"
```

The helper performs these safeguards:

- Fetches the live Atlas Cloud model catalog and the selected model's schema before generation.
- Reads the approved prompt directly from the selected spec section, avoiding shell interpolation.
- Validates model availability, aspect ratio, and resolution against that schema.
- Issues the generation `POST` exactly once and never retries it.
- Polls only the prediction `GET`, with a bounded attempt count.
- Rejects absolute paths and paths outside the project root.
- Corrects the requested file extension if the generated image format differs.
- Refuses to overwrite an existing file unless `--overwrite` was explicitly approved.

If the helper fails after the POST, report the prediction id when available and stop. Do not rerun the command automatically because that could create a second billable request.

## Phase 4: Review the Result

After generation:

1. Read the generated image with Claude Code's image-reading capability.
2. Compare it against the spec's visual description, art-bible anchors, dimensions, and negative prompt.
3. Present a concise PASS / CONCERNS / FAIL review. This is a preview, not automatically a production-ready asset.
4. If the result needs another generation, explain the changes and return to Phase 2. A second request always requires a fresh explicit approval.

Do not modify the asset manifest or mark the asset complete automatically.

## Phase 5: Next Step

Report the project-relative preview path and prediction id. Recommend:

- `/asset-audit` to check naming, format, size, and pipeline compliance.
- Manual art-direction review before moving the preview into a production asset directory.

Verdict: `COMPLETE` only when one image is saved and reviewed; otherwise `BLOCKED` or `CONCERNS` with the reason.
