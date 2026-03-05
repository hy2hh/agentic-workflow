---
name: batch-task-runner
description: |
  TRIGGER when: user asks to process a task list from a file, says "pending 항목 처리",
  "리팩토링 목록 진행", "남은 작업 순서대로", "batch", "항목별로 처리",
  or references a task/refactoring list file (e.g., pending-refactoring.md).

  Processes items from a persistent task file one at a time with verify + commit
  per item. Monitors context usage and gracefully stops when heavy, updating the
  task file so the next session can continue seamlessly.

  <example>
  Context: User asks to process a refactoring list
  user: "pending-refactoring.md의 항목 순서대로 진행해줘"
  assistant: "Priority 1 #1부터 시작합니다. 항목당 검증+커밋 후 다음으로 넘어갑니다."
  <commentary>
  Read task file, process sequentially by priority, verify+commit each,
  stop gracefully when context gets heavy.
  </commentary>
  </example>

  <example>
  Context: User asks to continue from last session
  user: "남은 리팩토링 이어서 해줘"
  assistant: "task 파일 확인 후 다음 미완료 항목부터 진행합니다."
  <commentary>
  Task file is the source of truth. Completed items are already removed.
  Pick up from where the file starts.
  </commentary>
  </example>

  <example>
  Context: Context getting heavy mid-task
  user: (internal context pressure detected)
  assistant: "3개 항목 완료. task 파일 업데이트 후 세션을 마무리합니다. 다음 세션에서 동일 프롬프트로 이어갈 수 있습니다."
  <commentary>
  Never silently degrade. Stop cleanly, persist progress, guide user.
  </commentary>
  </example>
---

# Batch Task Runner

Process a persistent task list across sessions with automatic chunking, verification, and progress tracking.

## Core Principle

**The task file is the single source of truth.** Completed items are removed from the file. The next session reads the same file and picks up where the previous session left off. No context carryover needed.

## Workflow

### Step 1: Read Task File

Read the task list file from the project memory or specified path.
Identify the next item to process by priority order (Priority 1 first, then 2, etc.).

```
Common locations:
- .claude/projects/*/memory/pending-*.md
- docs/pending-*.md
- User-specified path
```

### Step 2: Process One Item

For each task item:

1. **Analyze scope** - Read relevant files, understand the change
2. **Delegate if complex** - Use sub-agent (Explore/Plan) for items spanning 3+ files
3. **Implement** - Make the changes
4. **Verify** - Run lint + typecheck (use project-specific commands)
5. **Commit** - One commit per completed item with descriptive message

```
Per-item cycle:
  Read task → Analyze → [Sub-agent if needed] → Implement → Verify → Commit
```

### Step 3: Update Task File

After each item is committed:
- Remove the completed item from the task file
- Add a brief completion note if useful (date, commit hash)
- Save the file immediately (don't batch updates)

### Step 4: Context Health Check

After each item, evaluate whether to continue:

**Continue if:**
- No context compression has occurred yet
- The next item is similar in scope to what was just done
- Files needed for the next item are already in context

**Stop if:**
- Context compression has occurred (prior messages were summarized)
- The next item requires reading many new files (5+) not in context
- 3+ items have been completed in this session (good stopping point)
- The next item is significantly different in domain from the current work

### Step 5: Graceful Stop

When stopping:

1. Commit any in-progress work
2. Update the task file (remove completed items)
3. Report to user:
   - How many items were completed
   - How many remain
   - What the next item is
4. Tell the user they can continue with the same prompt

```
Example stop message:
"3개 항목 완료 (#1, #2, #4). 8개 남아있습니다.
다음 항목: #3 Withdraw orchestrator 중복 제거
다음 세션에서 동일하게 진행하면 이어서 처리됩니다."
```

## Verification Commands

Use the project's own verification commands. Common patterns:

```bash
# JavaScript/TypeScript projects
pnpm lint:fix && pnpm typecheck     # or
npm run lint && npm run typecheck

# Python projects
ruff check --fix . && mypy .

# If unknown, check package.json or pyproject.toml first
```

## Commit Convention

One commit per task item:

```
refactor: <what was done> (batch-task #N)

- Brief description of changes
- Files affected

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

## Sub-Agent Delegation

For complex items (3+ files, cross-cutting changes):

| Phase | Agent Type | Purpose |
|-------|-----------|---------|
| Scope analysis | Explore (quick) | Find all affected files |
| Implementation plan | Plan | Design the refactoring approach |
| Implementation | Direct (main context) | Apply changes with full awareness |

Do NOT delegate implementation to sub-agents for refactoring tasks.
Sub-agents lack the accumulated context of what was already changed.

## Rules

- NEVER process all items without stopping to check context health
- NEVER skip verification (lint + typecheck) between items
- NEVER keep completed items in the task file
- ALWAYS commit after each item (not batched at the end)
- ALWAYS update the task file immediately after each commit
- ALWAYS tell the user how to continue when stopping
- If an item fails verification, revert and move to the next item. Note the failure in the task file.

## Anti-Patterns

1. **The Marathoner**: Processing all items without checking context health
2. **The Batcher**: Committing all items at once at the end
3. **The Forgetter**: Not updating the task file, losing progress across sessions
4. **The Over-Delegator**: Sending refactoring to sub-agents that lack prior context
5. **The Silent Stopper**: Stopping without telling the user what remains
