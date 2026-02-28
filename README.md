# agentic-workflow

Claude Code가 서브에이전트/팀을 효율적으로 활용하도록 강제하는 플러그인.

## 해결하는 문제

| 문제 | 해결 |
|------|------|
| 서브에이전트 결과를 메인 컨텍스트에 전문 적재 → 토큰 낭비 | 파일 저장 강제, 메인은 요약만 |
| 독립 작업을 순차 실행 → 비효율 | 병렬 실행 규칙 |
| 리서치 결과가 세션 종료 시 소실 | 파일 영속화 필수 |
| 메인 컨텍스트에서 모든 것을 직접 처리 | 전문 에이전트에 위임 |

## 컴포넌트

### Skill: `agentic-delegation`
- 자동 활성화: 복합 작업, 리서치, 분석 시 Claude가 자동으로 규칙 로드
- 5가지 핵심 규칙: 컨텍스트 보호, 병렬 실행, 결과 영속화, 파이프라인 체이닝, 적절한 위임

### Agent: `delegation-orchestrator`
- 복합 작업을 자동 분할하고 병렬 서브에이전트에 위임
- 결과를 파일에 저장하고 메인에는 요약만 전달

### Hook: PostToolUse (Task)
- Task 도구 사용 후 자동으로 메트릭 수집
- `.claude/agentic-metrics.jsonl`에 기록
- 수집 항목: 파일 저장 여부, 병렬 실행 여부, 에이전트 타입, 출력 크기

## 설치

```bash
claude install /path/to/agentic-workflow
```

## 메트릭 확인

```bash
# 최근 메트릭 보기
cat .claude/agentic-metrics.jsonl | tail -20

# 파일 저장 비율 확인
cat .claude/agentic-metrics.jsonl | jq -s '[.[] | .saved_to_file] | (map(select(.)) | length) as $t | ($t / length * 100)'

# 병렬 실행 비율 확인
cat .claude/agentic-metrics.jsonl | jq -s '[.[] | .ran_in_background] | (map(select(.)) | length) as $t | ($t / length * 100)'
```

## 프로젝트별 확장

이 플러그인은 범용입니다. 프로젝트별 특화 규칙은 해당 프로젝트의 CLAUDE.md에 추가하세요:

```markdown
## Agent Pipeline Rules
[리서치]     → 병렬 서브에이전트 → docs/ 저장 → 메인은 요약만
[로직 분석]  → strategy-reviewer (background)
[코드 수정]  → strategy-developer → test-runner 자동 체인
```
