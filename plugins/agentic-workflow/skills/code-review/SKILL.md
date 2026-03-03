---
name: code-review
description: |
  TRIGGER when: user asks for code review, says "리뷰", "review", "코드 검토",
  "PR 리뷰", "수정 파일 검토", "버그 찾아줘", or any request to review/audit
  code changes.

  Runs a parallel sub-agent review pipeline. CRITICAL and HIGH issues are
  auto-fixed without asking for approval. Results are saved to file.

  <example>
  Context: User asks for a review of recent changes
  user: "수정한 파일들 리뷰해줘"
  assistant: "파일 그룹별 병렬 서브에이전트로 리뷰 후 CRITICAL/HIGH 즉시 수정합니다."
  <commentary>
  One-shot parallel review = sub-agents, not TeamCreate.
  CRITICAL/HIGH findings are fixed immediately without pausing for approval.
  </commentary>
  </example>

  <example>
  Context: User asks for PR review
  user: "PR 전체 리뷰해줘"
  assistant: "변경 파일을 그룹으로 나눠 병렬 리뷰 후 자동 수정합니다."
  <commentary>
  Split files into 3-5 groups by domain, run parallel sub-agents,
  merge findings, auto-fix CRITICAL/HIGH, report summary with file path.
  </commentary>
  </example>
---

# Code Review Pipeline

Parallel sub-agent code review with automatic fix execution.

## Pipeline

### Phase 1 — Identify Scope
```bash
git diff --name-only HEAD~1   # last commit changes
# or
git diff --name-only           # unstaged changes
```
Group files by domain (e.g., backend logic, frontend/UI, API contracts, config).

### Phase 2 — Parallel Review
Launch one sub-agent per file group simultaneously in a single message block.

Each reviewer sub-agent must:
- Read assigned files
- Categorize findings: `CRITICAL` / `HIGH` / `MEDIUM` / `LOW` / `INFO`
- Save full findings to `docs/review-{group}-{date}.md`
- Return only a severity-count summary

**Use `subagent_type: general-purpose`. Do NOT use TeamCreate.**

### Phase 3 — Triage & Fix

| Severity | Action |
|----------|--------|
| CRITICAL | Fix immediately — no approval step |
| HIGH | Fix immediately — no approval step |
| MEDIUM | Fix if change is isolated and safe; otherwise include in report |
| LOW / INFO | Report only |

Fix all CRITICAL and HIGH issues before proceeding. Do not ask "should I fix these?"

### Phase 4 — Verify
After fixes:
- TypeScript files: `tsc --noEmit` (or equivalent project command)
- Python files: `python -m py_compile <file>` per changed file
- Run existing tests if available

### Phase 5 — Commit
Create a single commit with a message that lists all fixes applied.
Format: `fix: <summary of changes> (auto-review: N critical, M high fixed)`

## Output to User

```
Review complete.
- Files reviewed: N
- Findings: X critical, Y high, Z medium, W low
- Auto-fixed: X critical + Y high issues
- Report: docs/review-{date}.md
- Commit: <hash> pushed
```

## Rules

- NEVER pause between Phase 3 review results and fix execution
- NEVER use TeamCreate for review tasks — sub-agents only
- ALWAYS save full findings to a file before summarizing
- ALWAYS complete the full pipeline (review → fix → verify → commit)
