# Hook: pre-commit-design-check

## Trigger

Runs before any commit that modifies files in `design/` or `assets/data/`.

## Purpose

Ensures design documents and game data files maintain consistency and
completeness before they enter version control. Catches missing sections,
broken cross-references, and invalid data before they propagate.

## Implementation

```bash
#!/bin/bash
# Pre-commit hook: Design document and game data validation
# Place in .git/hooks/pre-commit or configure via your hook manager

DESIGN_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '^design/')
DATA_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '^assets/data/')

EXIT_CODE=0

# Check design documents for required sections
if [ -n "$DESIGN_FILES" ]; then
    for file in $DESIGN_FILES; do
        if [[ "$file" == *.md ]]; then
            # Check for required sections in GDD documents
            if [[ "$file" == design/gdd/* ]]; then
                for section in "Overview" "Detailed" "Edge Cases" "Dependencies" "Acceptance Criteria"; do
                    if ! grep -qi "$section" "$file"; then
                        echo "ERROR: $file missing required section: $section"
                        EXIT_CODE=1
                    fi
                done
            fi
        fi
    done
fi

# Validate JSON data files
if [ -n "$DATA_FILES" ]; then
    for file in $DATA_FILES; do
        if [[ "$file" == *.json ]]; then
            # Find a working Python command
            PYTHON_CMD=""
            for cmd in python python3 py; do
                if command -v "$cmd" >/dev/null 2>&1; then
                    PYTHON_CMD="$cmd"
                    break
                fi
            done
            if [ -n "$PYTHON_CMD" ] && ! "$PYTHON_CMD" -m json.tool "$file" > /dev/null 2>&1; then
                echo "ERROR: $file is not valid JSON"
                EXIT_CODE=1
            fi
        fi
    done
fi

exit $EXIT_CODE
```

## Agent Integration

When this hook fails, the committer should:
1. For missing design sections: invoke the `game-designer` agent to complete
   the document
2. For invalid JSON: invoke the `tools-programmer` agent or fix manually
