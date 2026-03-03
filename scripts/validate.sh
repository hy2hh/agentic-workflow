#!/bin/bash
# 플러그인 배포 전 검증 스크립트
# 사용법: bash scripts/validate.sh

set -euo pipefail

PLUGIN_DIR="plugins/agentic-workflow"
ERRORS=0

echo "=== agentic-workflow 플러그인 검증 ==="

# 1. JSON 유효성
echo ""
echo "[1] JSON 유효성 검사"
find "$PLUGIN_DIR" -name "*.json" | while read f; do
  if jq . "$f" > /dev/null 2>&1; then
    echo "  OK: $f"
  else
    echo "  ERROR: $f — JSON 파싱 실패"
    ERRORS=$((ERRORS + 1))
  fi
done

# 2. hooks.json 구조 검증
echo ""
echo "[2] hooks.json 구조 검증"
HOOKS_FILE="$PLUGIN_DIR/hooks/hooks.json"
if [ -f "$HOOKS_FILE" ]; then
  # 최상위에 "hooks" 키가 있는지 확인
  HAS_HOOKS_KEY=$(jq 'has("hooks")' "$HOOKS_FILE" 2>/dev/null || echo "false")
  if [ "$HAS_HOOKS_KEY" = "true" ]; then
    echo "  OK: 최상위 'hooks' 키 존재"
  else
    echo "  ERROR: 최상위 'hooks' 키 없음 — { \"hooks\": { ... } } 구조 필요"
    ERRORS=$((ERRORS + 1))
  fi

  # hooks 값이 object인지 확인
  HOOKS_TYPE=$(jq '.hooks | type' "$HOOKS_FILE" 2>/dev/null || echo '"null"')
  if [ "$HOOKS_TYPE" = '"object"' ]; then
    echo "  OK: hooks 값이 object"
  else
    echo "  ERROR: hooks 값이 object가 아님 (현재: $HOOKS_TYPE)"
    ERRORS=$((ERRORS + 1))
  fi
else
  echo "  SKIP: hooks.json 없음"
fi

# 3. Shell 스크립트 문법 검사
echo ""
echo "[3] Shell 스크립트 문법 검사"
find "$PLUGIN_DIR" -name "*.sh" | while read f; do
  if bash -n "$f" 2>/dev/null; then
    echo "  OK: $f"
  else
    echo "  ERROR: $f — 문법 오류"
    ERRORS=$((ERRORS + 1))
  fi
done

# 4. 필수 파일 존재 확인
echo ""
echo "[4] 필수 파일 확인"
REQUIRED=(
  "$PLUGIN_DIR/.claude-plugin/plugin.json"
  "$PLUGIN_DIR/hooks/hooks.json"
)
for f in "${REQUIRED[@]}"; do
  if [ -f "$f" ]; then
    echo "  OK: $f"
  else
    echo "  ERROR: $f — 없음"
    ERRORS=$((ERRORS + 1))
  fi
done

# 5. 스킬 파일 SKILL.md 존재 확인
echo ""
echo "[5] 스킬 SKILL.md 확인"
find "$PLUGIN_DIR/skills" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | while read d; do
  if [ -f "$d/SKILL.md" ]; then
    echo "  OK: $d/SKILL.md"
  else
    echo "  ERROR: $d/SKILL.md — 없음"
    ERRORS=$((ERRORS + 1))
  fi
done

echo ""
if [ "$ERRORS" -eq 0 ]; then
  echo "검증 완료 — 에러 없음"
  exit 0
else
  echo "검증 실패 — $ERRORS 에러 발생"
  exit 1
fi
