# Fork Maintenance Guide

This guide covers how to keep the DataOS fork in sync with upstream OpenLineage while minimizing merge conflicts.

## Fork Strategy

```
┌─────────────────────────────────────────────────────────────┐
│                    Upstream OpenLineage                     │
│                  github.com/OpenLineage/OpenLineage         │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ periodic sync
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    DataOS Fork                              │
│         github.com/moderndatacompany/OpenLineage            │
│                                                             │
│   Minimal changes:                                          │
│   • client/java/gradle.properties (version, groupId)        │
│   • client/java/build.gradle (property-based config)        │
│   • Makefile (DataOS commands)                              │
│   • dataos/ directory (documentation)                       │
└─────────────────────────────────────────────────────────────┘
```

---

## Files Modified in This Fork

### High-Conflict Risk (Frequently Updated Upstream)

| File | Our Changes | Conflict Strategy |
|------|-------------|-------------------|
| `client/java/gradle.properties` | groupId, artifactId, version | **Keep ours** - just version/coordinates |
| `client/python/pyproject.toml` | name, version | **Keep ours** for name/version lines |
| `client/python/src/openlineage/client/constants.py` | `__version__` | **Keep ours** - just version |

### Low-Conflict Risk (Rarely Changed Upstream)

| File | Our Changes | Conflict Strategy |
|------|-------------|-------------------|
| `client/java/build.gradle` | Property-based groupId/artifactId | **Merge carefully** - our changes are isolated |
| `Makefile` | Added Java/Python commands | **Merge carefully** - additions only |

### No-Conflict (DataOS-Only Files)

| File/Directory | Purpose |
|----------------|---------|
| `dataos/` | All DataOS documentation |

---

## Syncing with Upstream

### Initial Setup (One-Time)

Add upstream as a remote:
```bash
git remote add upstream https://github.com/OpenLineage/OpenLineage.git
git fetch upstream
```

Verify remotes:
```bash
git remote -v
# origin    https://github.com/moderndatacompany/OpenLineage.git (fetch)
# origin    https://github.com/moderndatacompany/OpenLineage.git (push)
# upstream  https://github.com/OpenLineage/OpenLineage.git (fetch)
# upstream  https://github.com/OpenLineage/OpenLineage.git (push)
```

### Sync Process

#### Step 1: Fetch Upstream Changes
```bash
git fetch upstream
```

#### Step 2: Check What's Changed
```bash
# See commits we don't have
git log HEAD..upstream/main --oneline

# See if our modified files changed upstream
git diff HEAD..upstream/main -- client/java/gradle.properties
git diff HEAD..upstream/main -- client/java/build.gradle
git diff HEAD..upstream/main -- Makefile
```

#### Step 3: Merge Upstream
```bash
# Make sure you're on your main branch
git checkout main

# Merge upstream
git merge upstream/main
```

#### Step 4: Resolve Conflicts

If conflicts occur, they'll most likely be in:

**`client/java/gradle.properties`** (most common):

| Section | Content |
|---------|---------|
| **OURS (DataOS)** | `groupId=io.dataos.openlineage`<br>`artifactId=openlineage-java`<br>`version=1.43.0.1-SNAPSHOT` |
| **UPSTREAM** | `version=1.44.0-SNAPSHOT` |

**Resolution:** Keep DataOS config, update base version:

```properties
# DataOS fork of OpenLineage Java Client
groupId=io.dataos.openlineage
artifactId=openlineage-java
version=1.44.0.1-SNAPSHOT
```

#### Step 5: Complete the Merge
```bash
git add .
git commit -m "Merge upstream OpenLineage 1.44.0"
git push origin main
```

---

## Version Strategy

DataOS versions follow the upstream OpenLineage version with a patch number appended:

```
Upstream: 1.43.0 → 1.44.0 → 1.45.0
DataOS:   1.43.0.1 → 1.44.0.1 → 1.45.0.1
```

### Version Format: `{upstream-version}.{patch}`

| Version | Meaning |
|---------|---------|
| `1.43.0.1` | First DataOS release based on upstream 1.43.0 |
| `1.43.0.2` | Second DataOS release (bug fix) |
| `1.44.0.1` | First release after syncing with upstream 1.44.0 |

This makes it clear which upstream version the DataOS fork is based on.

**Note:** Java uses `-SNAPSHOT` suffix for development builds (e.g., `1.43.0.1-SNAPSHOT`). Python doesn't have this concept.

---

## Handling Specific Conflicts

### gradle.properties Conflicts (Java)

**Always keep:**
- Our `groupId`
- Our `artifactId`
- Our version format (`X.Y.Z.N-SNAPSHOT`)

**May update:**
- The base version number to match upstream

### build.gradle Conflicts (Java)

Our changes use `findProperty()` with fallbacks:
```groovy
group = project.findProperty('groupId') ?: 'io.openlineage'
```

If upstream modifies the publishing section:
1. Keep the `findProperty()` pattern
2. Accept other upstream changes
3. Verify the fallback values match upstream defaults

### pyproject.toml Conflicts (Python)

**Always keep:**
- Our `name` (`dataos-openlineage-python`)
- Our version format (`X.Y.Z.N`)

**Accept from upstream:**
- Dependency updates
- Tool configuration changes
- New optional dependencies

Example conflict:

| Section | Content |
|---------|---------|
| **OURS (DataOS)** | `name = "dataos-openlineage-python"`<br>`version = "1.43.0.1"` |
| **UPSTREAM** | `name = "openlineage-python"`<br>`version = "1.44.0"` |

**Resolution:**

```toml
name = "dataos-openlineage-python"
version = "1.44.0.1"
```

### constants.py Conflicts (Python)

Simple version conflict:

| Section | Content |
|---------|---------|
| **OURS (DataOS)** | `__version__ = "1.43.0.1"` |
| **UPSTREAM** | `__version__ = "1.44.0"` |

**Resolution:** Update base version, keep our patch number:

```python
__version__ = "1.44.0.1"
```

### Makefile Conflicts

Our additions are in clearly marked sections:
```makefile
# =============================================================================
# Java Client Commands
# =============================================================================

# =============================================================================
# Python Client Commands
# =============================================================================
```

If upstream adds their own Makefile changes:
1. Accept their changes
2. Keep our DataOS sections

---

## When NOT to Sync

Consider skipping an upstream release if:
- It only contains features you don't need
- It has breaking changes requiring significant testing
- You're in the middle of a release cycle

You can always sync later when ready.

---

## Checking Fork Status

### How Far Behind Are We?

```bash
git fetch upstream
git rev-list --count HEAD..upstream/main
# Output: number of commits we're behind
```

### What Changed in Upstream?

```bash
# Summary of changes
git log HEAD..upstream/main --oneline

# Detailed changelog
git log HEAD..upstream/main

# Check specific file
git log HEAD..upstream/main -- client/java/build.gradle
```

---

## Emergency: Reset to Upstream

If the fork gets too diverged and you want to start fresh:

⚠️ **Warning:** This loses all DataOS customizations!

```bash
# Create backup branch
git checkout -b dataos-backup

# Reset main to upstream
git checkout main
git reset --hard upstream/main

# Re-apply DataOS changes manually
# ... edit gradle.properties, build.gradle, etc.
```

---

## Best Practices

### Do

- ✅ Keep DataOS changes minimal and isolated
- ✅ Use property files for configuration (easier to merge)
- ✅ Document all changes in this `dataos/` directory
- ✅ Sync regularly (every 1-2 upstream releases)
- ✅ Test thoroughly after syncing
- ✅ Update versions manually in all required files

### Don't

- ❌ Modify core Java source files unless absolutely necessary
- ❌ Change upstream's package structure
- ❌ Skip testing after a merge
- ❌ Let the fork get too far behind (harder to merge)
- ❌ **Use `release.sh` or `bump-my-version`** — these are upstream tools that will break our versioning

---

## Quick Reference

```bash
# Setup (one-time)
git remote add upstream https://github.com/OpenLineage/OpenLineage.git

# Check status
git fetch upstream
git log HEAD..upstream/main --oneline

# Sync
git fetch upstream
git merge upstream/main
# ... resolve conflicts ...
git push origin main

# After sync, verify
make java-build-quick
make java-info
```
