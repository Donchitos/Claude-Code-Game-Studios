# Hook: post-merge-asset-validation

## Trigger

Runs after any merge to the `develop` or `main` branch that includes changes
to `assets/`.

## Purpose

Validates that all assets in the merged branch conform to naming conventions,
size budgets, and format requirements. Prevents non-compliant assets from
accumulating on integration branches.

## Implementation

```bash
#!/bin/bash
# Post-merge hook: Asset validation
# Checks merged assets against project standards

MERGED_ASSETS=$(git diff --name-only HEAD@{1} HEAD | grep -E '^assets/')

if [ -z "$MERGED_ASSETS" ]; then
    exit 0
fi

EXIT_CODE=0
WARNINGS=""

for file in $MERGED_ASSETS; do
    filename=$(basename "$file")

    # Check naming convention (lowercase with underscores)
    if echo "$filename" | grep -qE '[A-Z[:space:]-]'; then
        WARNINGS="$WARNINGS\nNAMING: $file -- must be lowercase with underscores"
        EXIT_CODE=1
    fi

    # Check texture sizes (must be power of 2)
    if [[ "$file" == *.png || "$file" == *.jpg ]]; then
        # Requires ImageMagick
        if command -v identify &> /dev/null; then
            dims=$(identify -format "%w %h" "$file" 2>/dev/null)
            if [ -n "$dims" ]; then
                w=$(echo "$dims" | cut -d' ' -f1)
                h=$(echo "$dims" | cut -d' ' -f2)
                if (( (w & (w-1)) != 0 || (h & (h-1)) != 0 )); then
                    WARNINGS="$WARNINGS\nSIZE: $file -- dimensions ${w}x${h} not power-of-2"
                fi
            fi
        fi
    fi

    # Check file size budgets
    size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
    if [ -n "$size" ]; then
        # Textures: max 4MB
        if [[ "$file" == assets/art/* ]] && [ "$size" -gt 4194304 ]; then
            WARNINGS="$WARNINGS\nBUDGET: $file -- ${size} bytes exceeds 4MB texture budget"
            EXIT_CODE=1
        fi
        # Audio: max 10MB for music, 512KB for SFX
        if [[ "$file" == assets/audio/sfx* ]] && [ "$size" -gt 524288 ]; then
            WARNINGS="$WARNINGS\nBUDGET: $file -- ${size} bytes exceeds 512KB SFX budget"
        fi
    fi
done

if [ -n "$WARNINGS" ]; then
    echo "=== Asset Validation Report ==="
    echo -e "$WARNINGS"
    echo "================================"
    echo "Run /asset-audit for a full report."
fi

exit $EXIT_CODE
```

## Agent Integration

When this hook reports issues:
1. For naming violations: fix manually or invoke `art-director` for guidance
2. For size violations: invoke `technical-artist` for optimization advice
3. For a full audit: run `/asset-audit` skill
