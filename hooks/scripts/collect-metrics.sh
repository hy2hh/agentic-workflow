#!/bin/bash
# Agentic Workflow Metrics Collector
# Triggered by PostToolUse hook on Task tool completions
# Appends metrics to .claude/agentic-metrics.jsonl in the current project

set -euo pipefail

# Read hook input from stdin
INPUT=$(cat)

# Extract tool name from the hook context
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"' 2>/dev/null || echo "unknown")

# Only process Task tool results
if [ "$TOOL_NAME" != "Task" ]; then
  exit 0
fi

# Extract relevant fields
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // "{}"' 2>/dev/null || echo "{}")
TOOL_OUTPUT=$(echo "$INPUT" | jq -r '.tool_output // ""' 2>/dev/null || echo "")

# Detect if result mentions file saving
SAVED_TO_FILE=false
if echo "$TOOL_OUTPUT" | grep -qiE '(saved|wrote|created|written).*(file|docs/|\.md|\.json|\.txt)' 2>/dev/null; then
  SAVED_TO_FILE=true
fi
if echo "$TOOL_OUTPUT" | grep -qiE '(파일|저장|생성).*(완료|했|됨)' 2>/dev/null; then
  SAVED_TO_FILE=true
fi

# Detect if agent ran in background (parallel indicator)
RAN_IN_BACKGROUND=false
if echo "$TOOL_INPUT" | jq -e '.run_in_background == true' >/dev/null 2>&1; then
  RAN_IN_BACKGROUND=true
fi

# Extract agent type
AGENT_TYPE=$(echo "$TOOL_INPUT" | jq -r '.subagent_type // "unknown"' 2>/dev/null || echo "unknown")

# Extract description
DESCRIPTION=$(echo "$TOOL_INPUT" | jq -r '.description // ""' 2>/dev/null || echo "")

# Determine metrics file location
METRICS_DIR=".claude"
METRICS_FILE="${METRICS_DIR}/agentic-metrics.jsonl"

# Create directory if needed
mkdir -p "$METRICS_DIR"

# Estimate output size (character count as proxy for tokens)
OUTPUT_LENGTH=${#TOOL_OUTPUT}

# Append metric entry
jq -n \
  --arg ts "$TIMESTAMP" \
  --arg agent_type "$AGENT_TYPE" \
  --arg description "$DESCRIPTION" \
  --argjson saved_to_file "$SAVED_TO_FILE" \
  --argjson ran_in_background "$RAN_IN_BACKGROUND" \
  --argjson output_chars "$OUTPUT_LENGTH" \
  '{
    timestamp: $ts,
    event: "task_completion",
    agent_type: $agent_type,
    description: $description,
    saved_to_file: $saved_to_file,
    ran_in_background: $ran_in_background,
    output_chars: $output_chars
  }' >> "$METRICS_FILE" 2>/dev/null || true

exit 0
