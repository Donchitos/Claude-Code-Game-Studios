# Hook: pre-commit-code-quality

## Trigger

Runs before any commit that modifies files under the code root — `src/`
(Godot), `Assets/` (Unity) or `Source/` (Unreal); see
`.claude/docs/code-root-resolution.md`.

## Purpose

Enforces coding standards before code enters version control. Catches style
violations, missing documentation, overly complex methods, and hardcoded
values that should be data-driven.

## Implementation

```bash
#!/bin/bash
# Pre-commit hook: Code quality checks
# Adapt the specific checks to your language and tooling

# The code root depends on the engine; resolve it the way the shipped commit
# check does. An unresolved root is reported, never guessed as src/.
. "$(git rev-parse --show-toplevel)/.claude/hooks/yaml-helper.sh"
CODE_ROOT=$(resolve_code_root | cut -f1)
if [ -z "$CODE_ROOT" ]; then
    echo "SKIPPED: no code root (set engine.name in project.yaml) — code checks did not run."
    exit 0
fi

CODE_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E "^$CODE_ROOT/")

EXIT_CODE=0

if [ -n "$CODE_FILES" ]; then
    for file in $CODE_FILES; do
        # Check for hardcoded magic numbers in gameplay code
        if [[ "$file" == */[Gg]ameplay/* ]]; then
            # Look for numeric literals that are likely balance values
            # Adjust the pattern for your language
            if grep -nE '(damage|health|speed|rate|chance|cost|duration)[[:space:]]*[:=][[:space:]]*[0-9]+' "$file"; then
                echo "WARNING: $file may contain hardcoded gameplay values. Use data files."
                # Warning only, not blocking
            fi
        fi

        # Check for TODO/FIXME without assignee
        if grep -nE '(TODO|FIXME|HACK)[^(]' "$file"; then
            echo "WARNING: $file has TODO/FIXME without owner tag. Use TODO(name) format."
        fi

        # Run language-specific linter (uncomment appropriate line)
        # For GDScript: gdlint "$file" || EXIT_CODE=1
        # For C#: dotnet format --check "$file" || EXIT_CODE=1
        # For C++: clang-format --dry-run -Werror "$file" || EXIT_CODE=1
    done

    # Run unit tests for modified systems
    # Uncomment and adapt for your test framework
    # python -m pytest tests/unit/ -x --quiet || EXIT_CODE=1
fi

exit $EXIT_CODE
```

## Agent Integration

When this hook fails:
1. For style violations: auto-fix with your formatter or invoke `lead-programmer`
2. For hardcoded values: invoke `gameplay-programmer` to externalize the values
3. For test failures: invoke `qa-tester` to diagnose and `gameplay-programmer` to fix
