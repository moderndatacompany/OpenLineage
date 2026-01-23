# DataOS OpenLineage Fork

This is the DataOS fork of [OpenLineage](https://github.com/OpenLineage/OpenLineage), maintained for internal DataOS use with custom modifications.

> ⚠️ **Important:** Do NOT use `release.sh` or `bump-my-version` from the upstream project. These will break our versioning. See [RELEASING.md](./RELEASING.md) for the correct release process.

## Quick Links

| Document | Description |
|----------|-------------|
| [DEVELOPMENT.md](./DEVELOPMENT.md) | Local development, building, testing |
| [RELEASING.md](./RELEASING.md) | Publishing to Maven Central & PyPI |
| [CONTRIBUTING.md](./CONTRIBUTING.md) | Adding custom facets and contributing |
| [FORK-MAINTENANCE.md](./FORK-MAINTENANCE.md) | Syncing with upstream OpenLineage |

## What's Different in This Fork?

### Java Client Customizations

| Change | Location | Purpose |
|--------|----------|---------|
| GroupId/ArtifactId/Version | `client/java/gradle.properties` | DataOS-specific Maven coordinates |
| Property-based coordinates | `client/java/build.gradle` | Minimize merge conflicts with upstream |

### Python Client Customizations

| Change | Location | Purpose |
|--------|----------|---------|
| Package name & version | `client/python/pyproject.toml` | DataOS-specific PyPI package |
| Version constant | `client/python/src/openlineage/client/constants.py` | Runtime version |

## Current Artifact Coordinates

### Java (Maven Central)

```xml
<dependency>
    <groupId>io.dataos.openlineage</groupId>
    <artifactId>openlineage-java</artifactId>
    <version>1.43.0.1</version>
</dependency>
```

### Python (PyPI)

```bash
pip install dataos-openlineage-python==1.43.0.1
```

**Versioning:** Both clients use `X.Y.Z.N` format where `X.Y.Z` is the upstream OpenLineage version and `.N` is the DataOS patch number.

## Quick Start

```bash
# See all available commands
make help

# ─────────────────────────────────────
# Java
# ─────────────────────────────────────
make java-info           # Show version info
make java-build-quick    # Build JAR
make java-publish-local  # Publish to ~/.m2

# ─────────────────────────────────────
# Python
# ─────────────────────────────────────
make python-info          # Show version info
make python-build         # Build wheel
make python-publish-local # Install locally
```

## Repository Structure

```
OpenLineage/
├── dataos/                    # DataOS-specific documentation (this folder)
│   ├── README.md
│   ├── DEVELOPMENT.md
│   ├── RELEASING.md
│   └── FORK-MAINTENANCE.md
├── client/
│   ├── java/                  # Java client
│   │   ├── gradle.properties  # Version & coordinates (DataOS-modified)
│   │   └── build.gradle       # Build config (minimal changes)
│   └── python/                # Python client
│       ├── pyproject.toml     # Package name & version (DataOS-modified)
│       └── src/openlineage/client/constants.py  # Version constant
├── integration/               # Spark, Flink, dbt integrations
├── spec/                      # OpenLineage specification (JSON schemas)
└── Makefile                   # Development commands
```

## Support

For questions about this fork, contact the DataOS team members: Animesh Kumar, Akshay Jain and Rakesh Vishwakarma
