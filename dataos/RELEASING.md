# Releasing Guide

This guide covers the complete process of publishing the OpenLineage clients:
- **Java** → Maven Central
- **Python** → PyPI

---

## ⚠️ IMPORTANT: Do NOT Use Upstream Release Scripts

> **Warning:** This is a DataOS fork with custom versioning. Do NOT use the upstream release tools.

### Scripts to AVOID

| Script/Tool | Location | Why to Avoid |
|-------------|----------|--------------|
| `release.sh` | Repository root | Will bump versions using upstream format |
| `bump-my-version` | CLI tool | Configured for upstream versioning |

### What Happens If You Run Them?

Running `release.sh` or `bump-my-version` will:
1. ❌ Overwrite our DataOS version format
2. ❌ Break version consistency between files
3. ❌ Cause confusion with upstream versioning

### Correct DataOS Release Process

**Always update versions manually:**

1. Edit `client/java/gradle.properties` (Java version)
2. Edit `client/python/pyproject.toml` (Python version)
3. Edit `client/python/src/openlineage/client/constants.py` (Python runtime version)
4. Run `make java-publish` or `make python-publish`

See detailed steps below.

---

## Overview

```
┌─────────────────────────────────────────────────────────────┐
│                 DataOS Release Process                      │
│                                                             │
│  1. Setup (one-time)     → Sonatype/PyPI account, GPG key  │
│  2. Prepare release      → Manually update versions        │
│  3. Publish              → make java-publish / python-publish│
│  4. Verify               → Check on Maven Central / PyPI   │
└─────────────────────────────────────────────────────────────┘
```

---

## Prerequisites (One-Time Setup)

### 1. Java Prerequisites

#### Sonatype Account

Maven Central is managed by Sonatype. You need an account to publish.

1. Go to https://central.sonatype.com/
2. Sign up (Google account works)
3. **Create a namespace** that matches your groupId
   - For `io.dataos.openlineage` → need to verify `dataos.io` domain
   - For `io.github.USERNAME` → automatically verified via GitHub

#### GPG Key Setup

All artifacts must be GPG signed.

#### Install GPG
```bash
# macOS
brew install gnupg

# Verify installation
gpg --version
```

#### Generate a Key
```bash
gpg --full-generate-key
```

Choose:
- Key type: `RSA and RSA` (default)
- Key size: `4096`
- Expiration: `0` (never expires) or your preference
- Real name: Your name
- Email: Your email
- Passphrase: **Save this securely!**

#### Get Your Key ID
```bash
gpg --list-secret-keys --keyid-format=short
```

Output:
```
sec   rsa4096/ABCD1234 2026-01-23 [SC]
      1234567890ABCDEF1234567890ABCDEF12345678
uid         [ultimate] Your Name <your@email.com>
ssb   rsa4096/EFGH5678 2026-01-23 [E]
```

Your key ID is `ABCD1234` (after `rsa4096/`).

#### Publish Public Key to Keyserver
```bash
gpg --keyserver keyserver.ubuntu.com --send-keys YOUR_KEY_ID
```

This allows Maven Central to verify your signatures.

#### Export Private Key
```bash
gpg --armor --export-secret-keys YOUR_KEY_ID
```

**Save the entire output** (including `-----BEGIN PGP PRIVATE KEY BLOCK-----` and `-----END PGP PRIVATE KEY BLOCK-----`).

#### Sonatype Token

1. Go to https://central.sonatype.com/
2. Click your profile → **View Account**
3. Click **Generate User Token**
4. Save the username and password

---

## Environment Variables

Before publishing, set these environment variables:

```bash
# Sonatype credentials (from token generation)
export RELEASE_USERNAME="your-sonatype-token-username"
export RELEASE_PASSWORD="your-sonatype-token-password"

# GPG signing key (entire key block)
export ORG_GRADLE_PROJECT_signingKey="-----BEGIN PGP PRIVATE KEY BLOCK-----

lQdGBGN...
...your key content...
-----END PGP PRIVATE KEY BLOCK-----"

# GPG passphrase
export ORG_GRADLE_PROJECT_signingPassword="your-gpg-passphrase"
```

### Verify Variables Are Set
```bash
echo "RELEASE_USERNAME: ${RELEASE_USERNAME:+SET}"
echo "RELEASE_PASSWORD: ${RELEASE_PASSWORD:+SET}"
echo "signingKey: ${ORG_GRADLE_PROJECT_signingKey:+SET}"
echo "signingPassword: ${ORG_GRADLE_PROJECT_signingPassword:+SET}"
```

All should show `SET`.

---

## Release Process

### Step 1: Update Version

Edit `client/java/gradle.properties`:

```properties
# Change from SNAPSHOT to release version
version=1.43.0.1
```

**Version format:** `{upstream-version}.{patch}`

| Example | Meaning |
|---------|---------|
| `1.43.0.1` | First DataOS release based on OpenLineage 1.43.0 |
| `1.43.0.2` | Second DataOS release (bug fix) |
| `1.44.0.1` | First release after syncing with upstream 1.44.0 |

### Step 2: Verify Build

```bash
# Check artifact info
make java-info

# Should show:
# ✓ Release version - GPG signing required

# Build and test
make java-build-quick
```

### Step 3: Publish

```bash
make java-publish
```

This will:
1. Build the JAR, sources JAR, and javadoc JAR
2. Sign all artifacts with your GPG key
3. Upload to Sonatype staging repository
4. Automatically release to Maven Central

### Step 4: Verify Publication

After publishing:
1. Check status at https://central.sonatype.com/
2. Look for your artifact: `io.dataos.openlineage:openlineage-java`
3. **Note:** It may take 10-30 minutes to appear in search

Once published, anyone can use:
```xml
<dependency>
    <groupId>io.dataos.openlineage</groupId>
    <artifactId>openlineage-java</artifactId>
    <version>1.43.0.1</version>
</dependency>
```

### Step 5: Post-Release

After successful release, commit the release version and bump to next SNAPSHOT:

```bash
# Commit the release version
git add client/java/gradle.properties
git commit -m "Release version 1.43.0.1"

# Bump to next SNAPSHOT for development
# Edit client/java/gradle.properties: version=1.43.0.2-SNAPSHOT

git add client/java/gradle.properties
git commit -m "Bump version to 1.43.0.2-SNAPSHOT"
git push origin main
```

---

## Release Checklist

```
□ All tests passing (`make java-build-quick`)
□ Version updated (removed -SNAPSHOT)
□ Environment variables set:
  □ RELEASE_USERNAME
  □ RELEASE_PASSWORD
  □ ORG_GRADLE_PROJECT_signingKey
  □ ORG_GRADLE_PROJECT_signingPassword
□ GPG public key published to keyserver
□ Run `make java-publish`
□ Verify on Maven Central
□ Commit release version
□ Bump to next SNAPSHOT version
□ Commit and push
```

---

## Troubleshooting

### "Cannot perform signing task because it has no configured signatory"

**Cause:** GPG signing environment variables not set.

**Solution:** Set `ORG_GRADLE_PROJECT_signingKey` and `ORG_GRADLE_PROJECT_signingPassword`.

### "401 Unauthorized" or "403 Forbidden"

**Cause:** Invalid Sonatype credentials.

**Solution:**
1. Regenerate your Sonatype token
2. Update `RELEASE_USERNAME` and `RELEASE_PASSWORD`

### "Could not PUT... 400 Bad Request"

**Cause:** GroupId doesn't match your Sonatype namespace.

**Solution:** Ensure your `groupId` in `gradle.properties` starts with your verified namespace.

### GPG Key Not Found on Keyserver

**Cause:** Public key not published or not yet propagated.

**Solution:**
```bash
# Publish to multiple keyservers
gpg --keyserver keyserver.ubuntu.com --send-keys YOUR_KEY_ID
gpg --keyserver keys.openpgp.org --send-keys YOUR_KEY_ID
```

Wait a few minutes and try again.

### "Received status code 400... transports-datazone"

**Cause:** Submodules (transports-*) trying to publish with different groupId.

**Solution:** The Makefile is configured to only publish the core client. If you see this, ensure you're using `make java-publish` (not running Gradle directly).

---

## Important Notes

### Maven Central is Immutable

Once a version is published to Maven Central:
- ❌ Cannot be deleted
- ❌ Cannot be modified
- ❌ Cannot be re-published with same version

**Always test with SNAPSHOT versions first!**

### SNAPSHOT vs Release

| Type | Signing | Maven Central | Local Maven |
|------|---------|---------------|-------------|
| `X.Y.Z-SNAPSHOT` | Not required | ❌ Not allowed | ✅ Allowed |
| `X.Y.Z` (release) | Required | ✅ Allowed | ✅ Allowed |

### Credential Security

⚠️ **Never commit credentials to git!**

Options for secure storage:
1. Environment variables (current approach)
2. `~/.gradle/gradle.properties` (local machine only)
3. CI/CD secrets (for automated releases)

---

## Automated Releases (CI/CD)

> **Note:** Automated releases through GitHub CI/CD are pending and will be implemented in a future iteration. For now, releases are done manually using the steps above.

---

# Python Client - Publishing to PyPI

## Overview

```
┌─────────────────────────────────────────────────────────────┐
│                Python Release Process                        │
│                                                             │
│  1. Setup (one-time)     → Python env, PyPI account, token  │
│  2. Prepare release      → Update version in 2 files        │
│  3. Build                → Create wheel and sdist           │
│  4. Publish              → Upload to PyPI                   │
│  5. Verify               → Check on PyPI                    │
└─────────────────────────────────────────────────────────────┘
```

---

## Prerequisites (One-Time Setup)

### 1. Python Environment

You need a Python environment with `uv` (for building) and `twine` (for publishing).

```bash
# Install pyenv (if not already installed)
brew install pyenv

# Install Python 3.11
pyenv install 3.11.13

# Set Python version for this project
cd /path/to/OpenLineage
pyenv local 3.11.13

# Create and activate virtual environment
python -m venv .venv
source .venv/bin/activate

# Install publishing dependencies
pip install twine
```

### 2. Install uv (Build Tool)

```bash
# macOS (recommended)
brew install uv

# Or via script
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### 3. PyPI Account

1. Go to https://pypi.org/account/register/
2. Create an account
3. Enable 2FA (required for publishing)

### 4. API Token

1. Go to https://pypi.org/manage/account/token/
2. Create a new API token
3. Scope: "Entire account" (for first publish) or project-specific
4. **Save the token** - it starts with `pypi-`

---

## Environment Variables

```bash
export TWINE_USERNAME="__token__"
export TWINE_PASSWORD="pypi-xxxxxxxxxxxxxxxxxxxxx"
```

**Note:** When using API tokens, username is literally `__token__`.

---

## Release Process

### Step 1: Activate Python Environment

```bash
cd /path/to/OpenLineage
source .venv/bin/activate
```

### Step 2: Update Version

Update version in **TWO** files:

**`client/python/pyproject.toml`:**
```toml
version = "1.43.0.2"
```

**`client/python/src/openlineage/client/constants.py`:**
```python
__version__ = "1.43.0.2"
```

### Step 3: Verify Version

```bash
make python-info
```

### Step 4: Run Tests

```bash
make python-test
```

### Step 5: Build

```bash
make python-build
```

Verify the dist folder:
```bash
ls client/python/dist/
# dataos_openlineage_python-1.43.0.2-py3-none-any.whl
# dataos_openlineage_python-1.43.0.2.tar.gz
```

### Step 6: Publish

```bash
# Set credentials
export TWINE_USERNAME="__token__"
export TWINE_PASSWORD="pypi-xxxxxxxxxxxxxxxxxxxxx"

# Publish
make python-publish
```

### Step 7: Verify

Check on PyPI:
- https://pypi.org/project/dataos-openlineage-python/

Test installation:
```bash
pip install dataos-openlineage-python==1.43.0.2
python -c "from openlineage.client import __version__; print(__version__)"
```

---

## Python Release Checklist

```
□ Python environment activated (`source .venv/bin/activate`)
□ uv installed (`uv --version`)
□ twine installed (`twine --version`)
□ Version updated in pyproject.toml
□ Version updated in constants.py
□ Both versions match
□ Tests passing (`make python-test`)
□ Environment variables set:
  □ TWINE_USERNAME
  □ TWINE_PASSWORD
□ Clean build (`rm -rf client/python/dist && make python-build`)
□ Run `make python-publish`
□ Verify on PyPI
□ Test pip install
```

---

## Publishing to Test PyPI (Optional)

To test publishing without affecting production PyPI:

```bash
# Set Test PyPI credentials
export TWINE_USERNAME="__token__"
export TWINE_PASSWORD="pypi-test-xxxxx"

# Build
make python-build

# Upload to Test PyPI
pip install twine
twine upload --repository testpypi client/python/dist/*

# Test install from Test PyPI
pip install --index-url https://test.pypi.org/simple/ dataos-openlineage-python
```

---

## Troubleshooting

### "The user 'xxx' isn't allowed to upload to project 'dataos-openlineage-python'"

**Cause:** First-time publishing requires project creation rights.

**Solution:** Use an account-wide token for the first publish.

### "File already exists"

**Cause:** This version was already published to PyPI.

**Solution:** PyPI is immutable. Increment the version number.

### "Invalid version"

**Cause:** PyPI has strict version format requirements.

**Solution:** Use format `X.Y.Z.dataosN` (no hyphens).

---

## Important Notes

### PyPI is Immutable

Once a version is published:
- ❌ Cannot be deleted (only yanked)
- ❌ Cannot be re-uploaded with same version

**Always test locally first!**

### Version Format

Both Java and Python use the same version format: `X.Y.Z.N`

| Example | Meaning |
|---------|---------|
| `1.43.0.1` | First DataOS release based on OpenLineage 1.43.0 |
| `1.43.0.2` | Second DataOS release (bug fix) |
| `1.44.0.1` | First release after syncing with upstream 1.44.0 |

**Note:** Java uses `-SNAPSHOT` suffix for development builds (e.g., `1.43.0.1-SNAPSHOT`), but Python doesn't have this concept.

---

## CI/CD Secrets for Python

| Secret Name | Value |
|-------------|-------|
| `TWINE_USERNAME` | `__token__` |
| `TWINE_PASSWORD` | PyPI API token |
