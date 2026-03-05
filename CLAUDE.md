# agentic-workflow Plugin - Development Guide

## Project Structure

```
agentic-workflow/
├── .claude-plugin/
│   └── marketplace.json     # Marketplace manifest (includes version)
├── plugins/
│   └── agentic-workflow/
│       └── .claude-plugin/
│           └── plugin.json  # Plugin metadata (includes version)
└── CLAUDE.md
```

## Version Update Rules

### Default Rule

Unless explicitly instructed otherwise, **only increment the patch version (x in 0.0.x)**.

```
0.1.2 → 0.1.3  ✅ (default)
0.1.2 → 0.2.0  ❌ (requires explicit instruction)
0.1.2 → 1.0.0  ❌ (requires explicit instruction)
```

### Files to Update

When changing the version, **both files must be updated**:

1. `.claude-plugin/marketplace.json` → `version` field
2. `plugins/agentic-workflow/.claude-plugin/plugin.json` → `version` field

### Cache Deletion

After updating the version, **local cache and marketplace cache must be deleted**.

```bash
# Delete local plugin cache
rm -rf ~/.claude/plugins/agentic-workflow

# Delete marketplace cache (if it exists)
rm -rf ~/.claude/marketplace-cache
```

> Without clearing the cache, the old version may continue to load.

### Version Update Checklist

```
□ Update version in marketplace.json
□ Update version in plugin.json
□ Verify both files have the same version
□ Delete local cache
□ Delete marketplace cache
□ Commit message: chore: bump version to X.X.X
```

---

## Code Simplification & Optimization Priority

### 📊 Priority Order (Strict Hierarchy)

코드 작성/최적화 시 **반드시 이 순서대로** 적용하세요. 상위 규칙이 하위 규칙을 항상 이깁니다.

```
Priority 1️⃣ : Team Convention Compliance
    ↓ (Team Convention이 먼저)
Priority 2️⃣ : ESLint / TypeScript Errors
    ↓ (ts-lint 에러 방지)
Priority 3️⃣ : Performance Optimization
    ↓ (성능은 마지막)
Priority 4️⃣ : Readability Improvement
```

### 1️⃣ Team Convention (최우선)

**reference:** `~/.claude/shared/team-convention.md`

**필수 규칙:**
```typescript
// ✅ PRIORITY RULES (절대 어기지 마세요)
- One component per file
- React.memo for all components
- Single responsibility principle
- camelCase, PascalCase, UPPER_CASE 네이밍
- Boolean props shorthand: <Component isActive />
- Always use braces in conditionals
- 2 spaces indentation
- Single quotes for strings
- Always use semicolons
```

**위반 예시:**
```typescript
// ❌ WRONG - team convention 위반
if (isActive) return <Component />;  // No braces
const MAX_ITEMS = 10;                  // 수정 필요 아님, 올바름

// ❌ WRONG - camelCase 위반
const ItemCount = 5;                  // 상수인데 PascalCase

// ❌ WRONG - Boolean props
<Component isActive={true} />         // Shorthand 사용 필요

// ✅ CORRECT
if (isActive) {
  return <Component />;
}

const MAX_ITEMS = 10;
const itemCount = 5;
<Component isActive />
```

### 2️⃣ ESLint / TypeScript Compliance

**파일 저장 직후 즉시:**
```bash
pnpm lint:fix      # ESLint 자동 수정
pnpm fix           # ESLint + Prettier
```

**체크리스트:**
```
✅ No ESLint errors
✅ No TypeScript errors (any 사용 금지)
✅ Pre-commit hooks pass
```

**흔한 ESLint 위반:**
```typescript
// ❌ var 사용
var count = 0;
→ const count = 0;

// ❌ Double quotes
const msg = "hello";
→ const msg = 'hello';

// ❌ Missing semicolons
const x = 5
→ const x = 5;

// ❌ No braces
if (x > 5) return;
→ if (x > 5) { return; }
```

### 3️⃣ Performance Optimization

**reference:** `~/.claude/shared/react-best-practices.md`

**최적화 포인트 (Priority 1,2 만족 후에만):**
```typescript
// ✅ useMemo for expensive calculations
const result = useMemo(() =>
  expensiveCalculation(items),
  [items]
);

// ✅ useCallback for stable references
const handleClick = useCallback((id: number) => {
  updateItem(id);
}, [updateItem]);

// ✅ Extract to memoized components
export const ItemList = React.memo(({ items }: Props) => {
  return items.map(renderItem);
});
```

### 4️⃣ Readability

**마지막 단계 (Priority 1,2,3 만족 후):**
```typescript
// ✅ Named conditions
const isEligible = age >= 18 && hasPermission;

// ✅ Early returns
if (!data) {
  return <Loading />;
}

// ✅ Extract constants
const DEBOUNCE_DELAY = 300;
const MAX_RETRIES = 5;
```

---

### 🔄 Code Review Workflow

**코드 작성 후 검토 순서:**

```bash
# Step 1: Team Convention 확인
✅ CLAUDE.md의 "Code Simplification" 섹션 참고

# Step 2: 자동 린팅
pnpm lint:fix
pnpm fix

# Step 3: 타입 체크
pnpm type-check

# Step 4: 성능 리뷰 (선택)
/simplify --focus=performance

# Step 5: 커밋
git commit -m "..."
```

---

### ⚠️ Critical Rules

**절대 어기지 마세요:**

```
❌ Performance for Team Convention trade-off
   → Team Convention이 우선

❌ ESLint errors
   → pnpm lint:fix로 반드시 해결

❌ TypeScript any 사용
   → 명시적 타입 정의

❌ Single-line conditionals without braces
   → 항상 중괄호 사용

❌ Inconsistent naming conventions
   → camelCase, PascalCase, UPPER_CASE 엄격히
```

---

### 📝 Example: Correct Workflow

**상황: 새 컴포넌트 작성 완료**

```typescript
// ❌ Initial code
const UserCard = ({name, isActive=true}) => {
  if (isActive) return <div>{name}</div>;
  const ITEM_SIZE = 10
  return <div></div>
}

// ✅ After Priority 1 (Team Convention)
export const UserCard = React.memo(({name, isActive}: Props) => {
  if (isActive) {
    return <div>{name}</div>;
  }

  const ITEM_SIZE = 10;
  return <div></div>;
});

// ✅ After Priority 2 (ESLint)
pnpm lint:fix
// → Automatic fixes applied (quotes, semicolons, etc.)

// ✅ After Priority 3 (Performance - if needed)
const userMemo = useMemo(() => calculateUser(name), [name]);
// → Only if performance issue identified

// ✅ After Priority 4 (Readability)
const isValidUser = isActive && name?.length > 0;
// → Named conditions for clarity
```

---

### 🎯 Key Takeaway

**항상 이 순서대로:**
```
1. Team Convention 준수 (반드시)
2. ESLint 에러 없음 (반드시)
3. 성능 최적화 (필요한 경우만)
4. 가독성 개선 (선택)
```

**"더 빠른" 코드가 ESLint 에러를 만들면, ESLint를 따르세요.**
