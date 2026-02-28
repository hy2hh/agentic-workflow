---
name: agentic-delegation
description: |
  This skill should be used when the user asks Claude to perform complex tasks that involve research, analysis, code modification, or any multi-step work. It activates when Claude considers using sub-agents, teams, or the Task tool. It provides mandatory rules for efficient delegation, parallel execution, and context protection.

  <example>
  Context: User asks for a research task
  user: "이 프로젝트에서 쓸 수 있는 대안 라이브러리들 조사해줘"
  assistant: "병렬 서브에이전트로 조사하고 결과를 파일에 저장하겠습니다."
  <commentary>
  Research results must be saved to files, not kept only in context. Multiple research topics should use parallel agents.
  </commentary>
  </example>

  <example>
  Context: User asks to fix a bug and update tests
  user: "이 버그 수정하고 테스트도 돌려봐"
  assistant: "분석은 서브에이전트에 위임하고, 결과 받으면 수정 후 test-runner를 체인으로 실행합니다."
  <commentary>
  Analysis, code modification, and testing are independent enough to pipeline. Don't do everything in the main context.
  </commentary>
  </example>

  <example>
  Context: Sub-agent returns a large result
  user: (sub-agent completes research with 5000+ words)
  assistant: "결과를 docs/에 저장하고 핵심 요약만 전달합니다."
  <commentary>
  Never load full sub-agent output into main context. Save to file, report summary only.
  </commentary>
  </example>

  <example>
  Context: User asks for code review across multiple files
  user: "PR 리뷰 해줘"
  assistant: "3개 병렬 에이전트로 파일 그룹별 리뷰를 실행합니다."
  <commentary>
  Code review across many files should always use parallel agents, never sequential review in main context.
  </commentary>
  </example>
---

# Agentic Delegation Rules

You MUST follow these rules whenever you use the Task tool, spawn sub-agents, or handle complex multi-step work. These rules protect context efficiency, ensure result persistence, and maximize parallel throughput.

## Rule 1: Context Protection

NEVER load full sub-agent results into the main conversation context.

**Required pattern:**
1. Sub-agent saves results to a file (e.g., `docs/`, `reports/`, or project-appropriate location)
2. Main context receives only a 3-5 line summary
3. If the user needs details, reference the file path

**Prohibited pattern:**
- Sub-agent returns 500+ words and you paste it into your response
- Keeping research/analysis results only in conversation memory
- Repeating sub-agent findings verbatim

**How to implement:**
When launching a sub-agent via the Task tool, include in the prompt:
```
Save your full results to [specific file path].
Return only a 3-5 line summary with the file path.
```

## Rule 2: Parallel Execution

When you have 2+ independent tasks, you MUST launch them as parallel sub-agents in a single message.

**Required pattern:**
- Research task A + Research task B → launch both in one message block
- Code analysis + test execution → parallel if independent
- Multiple file reviews → split by file group, run parallel

**Prohibited pattern:**
- Launching agent A, waiting for result, then launching agent B (when they're independent)
- Doing research yourself while a sub-agent could do it
- Sequential execution of independent work

**Decision rule:**
Ask yourself: "Does task B depend on the output of task A?"
- If NO → parallel
- If YES → sequential, but pipeline (A's output feeds B's input automatically)

## Rule 3: Result Persistence

Every research, analysis, or investigation result MUST be saved to a file. Context-only results are forbidden.

**File location guidelines:**
- Research/investigation → `docs/` directory
- Analysis reports → `reports/` or `docs/` directory
- Metrics/data → `.claude/` or project data directory
- Temporary analysis → at minimum a scratch file that can be referenced

**Required metadata in saved files:**
- Date of creation
- Source/methodology summary
- Key findings (so the file is self-contained)

## Rule 4: Pipeline Chaining

For multi-step workflows, chain agents in sequence:

```
[Analysis Agent] → saves findings to file
    → [Implementation Agent] reads findings, makes changes
        → [Test Agent] validates changes
```

**Required pattern:**
- Each agent in the chain reads from files, not from context
- Each agent saves its output for the next stage
- Main context orchestrates but doesn't hold intermediate results

**Common pipelines:**
- Bug fix: `analyzer → developer → test-runner`
- Feature: `planner → developer → reviewer → test-runner`
- Research: `parallel researchers → synthesizer → file save`

## Rule 5: Appropriate Delegation

Use the right agent type for each task. Don't do specialized work in the main context.

**Delegation guide:**
| Task Type | Delegate To | Main Context Does |
|-----------|-------------|-------------------|
| Code search/exploration | Explore agent | Read summary |
| Research (web/codebase) | general-purpose agent | Read summary |
| Code review | Specialized reviewer agent | Report to user |
| Code modification | Developer agent | Verify result |
| Test execution | test-runner agent | Report pass/fail |
| Complex planning | Plan agent | Present to user |

**When NOT to delegate:**
- Simple single-file edits (< 10 lines)
- Direct answers to conceptual questions
- Single grep/glob lookups
- Quick status checks

## Anti-Patterns to Avoid

1. **The Hoarder**: Loading all sub-agent results into context "just in case"
2. **The Serializer**: Running independent tasks one at a time
3. **The Amnesiac**: Keeping results only in context, losing them when session ends
4. **The Micromanager**: Doing sub-agent-level work in the main context
5. **The Duplicator**: Doing the same research a sub-agent is already doing

## Metrics Collection

This plugin collects workflow efficiency metrics to `.claude/agentic-metrics.jsonl`. Metrics include:
- Whether sub-agent results were saved to files
- Parallel vs sequential execution patterns
- Delegation frequency

These metrics enable data-driven improvement of delegation patterns over time.
