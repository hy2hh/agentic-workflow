#!/bin/bash
# Pre-commit verification hook
# Triggered before Bash tool calls that contain "git commit"
# Verifies only the files staged for commit — not the entire project

set -euo pipefail

INPUT=$(cat)

# Only run on git commit commands
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null || echo "")
if ! echo "$COMMAND" | grep -qE 'git\s+commit'; then
  exit 0
fi

# Get staged files
STAGED_FILES=$(git diff --cached --name-only 2>/dev/null || echo "")
if [ -z "$STAGED_FILES" ]; then
  exit 0
fi

ERRORS=""

# Check TypeScript files
TS_FILES=$(echo "$STAGED_FILES" | grep -E '\.(ts|tsx)$' || true)
if [ -n "$TS_FILES" ]; then
  # Use project tsc if available, skip if not configured
  if [ -f "tsconfig.json" ] && command -v tsc >/dev/null 2>&1; then
    TS_ERRORS=$(tsc --noEmit 2>&1 | head -20 || true)
    if [ -n "$TS_ERRORS" ]; then
      ERRORS="${ERRORS}\n[TypeScript errors]\n${TS_ERRORS}"
    fi
  fi
fi

# Check Python files (per-file syntax only — fast)
PY_FILES=$(echo "$STAGED_FILES" | grep -E '\.py$' || true)
if [ -n "$PY_FILES" ]; then
  while IFS= read -r pyfile; do
    if [ -f "$pyfile" ]; then
      PY_ERROR=$(python -m py_compile "$pyfile" 2>&1 || true)
      if [ -n "$PY_ERROR" ]; then
        ERRORS="${ERRORS}\n[Python syntax error: $pyfile]\n${PY_ERROR}"
      fi
    fi
  done <<< "$PY_FILES"
fi

if [ -n "$ERRORS" ]; then
  echo "Pre-commit verification failed:" >&2
  echo -e "$ERRORS" >&2
  exit 1
fi

exit 0
