---
name: git-workflow
description: |
  TRIGGER when: user mentions "커밋", "commit", "push", "pull", "sync",
  "rebase", "merge", "브랜치 동기화", "올려줘", "푸시", or any git operation.

  Ensures complete git cycles using rebase-based sync. Handles conflict
  resolution automatically. Never stops at diagnosis — always executes to
  completion.

  <example>
  Context: User asks to sync and push
  user: "풀 받고 푸시해줘"
  assistant: "rebase로 origin 동기화 후 push까지 완료합니다."
  <commentary>
  Full cycle: fetch → rebase → conflict resolution (if any) → push confirmed.
  Never stop after diagnosing a problem without executing the fix.
  </commentary>
  </example>

  <example>
  Context: User asks to commit and push
  user: "커밋하고 푸시해"
  assistant: "스테이징 → 커밋 → push까지 완료합니다."
  <commentary>
  Complete the entire cycle in one flow. Confirm push success with
  git log and git status before reporting done.
  </commentary>
  </example>
---

# Git Workflow

Complete git operations with rebase-based sync and intelligent conflict resolution.

## Merge Strategy

| Branch | Strategy | Notes |
|--------|----------|-------|
| `main` | Merge commit | Release and main branch only |
| All others | Rebase merge | Default for all feature/fix branches |

**Default: always rebase unless working directly on `main`.**

## Full Sync Cycle

```
1. git fetch origin
2. git rebase origin/<target-branch>
3. Resolve conflicts if any (see rules below)
4. git push origin <branch>
5. Confirm: git log --oneline -3 && git status
```

**Never stop after step 1 or 2 without completing the cycle.**

## Conflict Resolution Rules

### Lock Files (`package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, etc.)
```bash
# During rebase, accept origin's lock file
git checkout --ours <lockfile>   # --ours = origin during rebase
git add <lockfile>
git rebase --continue
# Then regenerate
pnpm install   # or npm install / yarn install as appropriate
```

> **Note on rebase direction**: During `git rebase`, `--ours` refers to the
> rebase target (origin), and `--theirs` refers to the local branch being
> replayed. This is the **opposite** of a regular merge.

### Code Files (non-lock)
```bash
# Keep local changes — local branch is --theirs during rebase
git checkout --theirs <file>
git add <file>
git rebase --continue
```

### Logic Conflicts (both sides modified the same logic)
- **Do NOT auto-resolve.** Stop and report to user with:
  - Which file has the conflict
  - What origin changed
  - What local changed
  - Ask for explicit direction

## Commit Cycle (no sync needed)

```
1. git add <specific files>   # Never git add -A blindly
2. git commit -m "<message>"
3. git push origin <branch>
4. Confirm: git log --oneline -3
```

## Rules

- **ALWAYS complete the full cycle** — diagnose AND execute, never just diagnose
- **ALWAYS confirm push success** before reporting done (show `git log` or `git status`)
- **NEVER use `git add -A`** without checking `git status` first
- **NEVER force push** to `main` without explicit user instruction
- If push is rejected (non-fast-forward): rebase and retry, do not stop
- If rebase has conflicts: resolve per rules above and continue, do not stop
