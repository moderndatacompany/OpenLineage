# Development Guide

This guide covers local development setup, building, and testing the OpenLineage Java and Python clients.

## Prerequisites

### Required

| Tool | Version | Installation |
|------|---------|--------------|
| Java JDK | 17+ | `brew install openjdk@17` |
| Python | 3.9+ | Via pyenv (see below) |
| pyenv | Latest | `brew install pyenv` |
| uv | Latest | `brew install uv` |
| Gradle | (bundled) | Uses `./gradlew` wrapper |

### Optional (for full test suite)

| Tool | Version | Purpose |
|------|---------|---------|
| Docker | Latest | Transport module tests (S3, GCS, etc.) |

---

## Python Environment Setup

The Python client requires a properly configured Python environment. We use `pyenv` to manage Python versions.

### Step 1: Install pyenv (if not already installed)

```bash
# macOS
brew install pyenv

# Add to ~/.zshrc or ~/.bashrc
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc
echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc
echo 'eval "$(pyenv init -)"' >> ~/.zshrc

# Reload shell
exec zsh -l
```

### Step 2: Install Python and Create Virtual Environment

```bash
# Install Python 3.11 (if not already installed)
pyenv install 3.11.13

# Set Python version for this project
pyenv local 3.11.13

# Verify Python is available
python --version  # Should show Python 3.11.x

# Create virtual environment
python -m venv .venv

# Activate virtual environment
source .venv/bin/activate
```

### Step 3: Install Dependencies

```bash
# With virtual environment activated
pip install twine  # Required for PyPI publishing
```

### Verifying Setup

```bash
# Check Python
which python
# Should show: /path/to/OpenLineage/.venv/bin/python

# Check uv
uv --version

# Check twine (for publishing)
twine --version
```

### Activating Environment (Each Session)

```bash
# Navigate to project directory
cd /path/to/OpenLineage

# Activate virtual environment
source .venv/bin/activate

# Your prompt should show (.venv)
```

## Makefile Commands

Run `make help` to see all available commands:

```bash
make help
```

### Java Client Commands

| Command | Description | Docker Required |
|---------|-------------|-----------------|
| `make java-info` | Show version and artifact coordinates | No |
| `make java-build` | Build and test (full test suite) | Yes |
| `make java-build-quick` | Build and test (skip Docker-dependent tests) | No |
| `make java-publish-local` | Publish to local Maven (`~/.m2/repository`) | No |
| `make java-publish` | Publish to Maven Central | No |

### Python Client Commands

| Command | Description |
|---------|-------------|
| `make python-info` | Show version and package info |
| `make python-build` | Build wheel and source distribution |
| `make python-test` | Run tests |
| `make python-publish-local` | Install locally for testing |
| `make python-publish` | Publish to PyPI |

---

# Java Client

## Building the Java Client

### Step 1: Check Current Version

```bash
make java-info
```

Output:
```
Java Client Artifact Info
─────────────────────────────────────────────────────
  Group ID:     io.dataos.openlineage
  Artifact ID:  openlineage-java
  Version:      1.43.0.1-SNAPSHOT

  Maven:
    <dependency>
      <groupId>io.dataos.openlineage</groupId>
      <artifactId>openlineage-java</artifactId>
      <version>1.43.0.1-SNAPSHOT</version>
    </dependency>

  Gradle:
    implementation 'io.dataos.openlineage:openlineage-java:1.43.0.1-SNAPSHOT'

  ⚠ SNAPSHOT version - signing not required
```

### Step 2: Build

**Quick build (recommended for development):**
```bash
make java-build-quick
```

This skips tests that require Docker (transport modules like S3, GCS, Kinesis).

**Full build (requires Docker running):**
```bash
make java-build
```

### Step 3: Locate the JAR

After building, the JAR is located at:
```
client/java/build/libs/openlineage-java-<version>.jar
```

---

## Publishing Java to Local Maven

To test the JAR in other local projects before releasing:

```bash
make java-publish-local
```

This publishes to `~/.m2/repository/io/dataos/openlineage/openlineage-java/`.

### Using in Another Project

**Maven (`pom.xml`):**
```xml
<dependency>
    <groupId>io.dataos.openlineage</groupId>
    <artifactId>openlineage-java</artifactId>
    <version>1.43.0.1-SNAPSHOT</version>
</dependency>
```

**Gradle (`build.gradle`):**
```groovy
repositories {
    mavenLocal()  // Important: include local Maven
    mavenCentral()
}

dependencies {
    implementation 'io.dataos.openlineage:openlineage-java:1.43.0.1-SNAPSHOT'
}
```

---

## Java Configuration Files

### `client/java/gradle.properties`

This is the **primary configuration file** for the Java client:

```properties
# DataOS fork of OpenLineage Java Client
groupId=io.dataos.openlineage
artifactId=openlineage-java
version=1.43.0.1-SNAPSHOT

# Gradle settings
org.gradle.caching=true
org.gradle.jvmargs=-Xmx4096M
```

### Versioning Convention (Java & Python)

Both clients use the same version format for consistency:

| Format | Example | Use Case |
|--------|---------|----------|
| `X.Y.Z.N-SNAPSHOT` | `1.43.0.1-SNAPSHOT` | Java development/testing |
| `X.Y.Z.N` | `1.43.0.1` | Release (both Java & Python) |

Where:
- `X.Y.Z` = Upstream OpenLineage version this is based on
- `.N` = DataOS patch number (increment for each release)
- `-SNAPSHOT` = Development version (Java only, removed for releases)

**Note:** Java uses `-SNAPSHOT` suffix for development builds. Python doesn't have this concept.

---

# Python Client

## Building the Python Client

### Step 1: Check Current Version

```bash
make python-info
```

Output:
```
Python Client Package Info
─────────────────────────────────────────────────────
  Package:  dataos-openlineage-python
  Version:  1.43.0.1

  Install:
    pip install dataos-openlineage-python==1.43.0.1

  With extras:
    pip install "dataos-openlineage-python[kafka]==1.43.0.1"
```

### Step 2: Build

```bash
make python-build
```

This creates:
```
client/python/dist/
├── dataos_openlineage_python-1.43.0.1-py3-none-any.whl
└── dataos_openlineage_python-1.43.0.1.tar.gz
```

### Step 3: Run Tests

```bash
make python-test
```

---

## Publishing Python Locally

To test the package locally before releasing:

```bash
make python-publish-local
```

This installs the wheel directly via pip.

### Verify Installation

```bash
python -c "from openlineage.client import __version__; print(__version__)"
# Output: 1.43.0.1
```

### Using in Another Project

**requirements.txt:**
```
dataos-openlineage-python==1.43.0.1
```

**With extras (e.g., Kafka support):**
```
dataos-openlineage-python[kafka]==1.43.0.1
```

---

## Python Configuration Files

### `client/python/pyproject.toml`

The package name and version are defined here:

```toml
[project]
name = "dataos-openlineage-python"
version = "1.43.0.1"
```

### `client/python/src/openlineage/client/constants.py`

The runtime version constant:

```python
__version__ = "1.43.0.1"
```

**Important:** Both files must have matching versions!

---

# Running Tests

## Java Tests

```bash
# All tests (needs Docker)
cd client/java && ./gradlew test

# Core client only
cd client/java && ./gradlew :test

# Specific module
cd client/java && ./gradlew :transports-s3:test
```

## Python Tests

```bash
# Via Makefile
make python-test

# Or directly
cd client/python && uv run pytest tests/
```

---

# Code Quality

## Java

```bash
# Check formatting
cd client/java && ./gradlew spotlessCheck

# Fix formatting
cd client/java && ./gradlew spotlessApply

# PMD static analysis
cd client/java && ./gradlew pmdMain
```

## Python

```bash
# Check formatting
cd client/python && uv run ruff check .

# Fix formatting
cd client/python && uv run ruff format .

# Type checking
cd client/python && uv run mypy src/
```

---

# Cleaning Up

```bash
# Clean everything (Python + Java)
make clean

# Clean Java only
cd client/java && ./gradlew clean

# Clean Python only
rm -rf client/python/dist client/python/.venv
```

---

# Troubleshooting

## Java Issues

### "Could not find a valid Docker environment"

**Cause:** Tests for transport modules (S3, GCS, etc.) use Testcontainers which requires Docker.

**Solution:** 
- Start Docker Desktop, OR
- Use `make java-build-quick` to skip these tests

### "Cannot perform signing task because it has no configured signatory"

**Cause:** Trying to publish a release version (non-SNAPSHOT) without GPG keys configured.

**Solution:**
- For local testing, use SNAPSHOT versions
- For releases, see [RELEASING.md](./RELEASING.md)

## Python Issues

### "uv: command not found"

**Solution:** Install uv:
```bash
# macOS (recommended)
brew install uv

# Or via script
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### Import errors after local install

**Solution:** Make sure you're using the installed version:
```bash
pip uninstall openlineage-python dataos-openlineage-python
make python-publish-local
```

---

# Next Steps

- To publish to Maven Central or PyPI, see [RELEASING.md](./RELEASING.md)
- To sync with upstream OpenLineage, see [FORK-MAINTENANCE.md](./FORK-MAINTENANCE.md)
