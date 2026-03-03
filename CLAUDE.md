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
