# Contributing Guide

This guide covers how to contribute to the DataOS OpenLineage fork, specifically for adding custom facets.

---

## Adding a Custom Facet

Custom facets allow you to extend OpenLineage with domain-specific metadata. Follow these steps to add a new facet.

### Prerequisites

- Python 3.9+ with virtual environment
- Generator dependencies installed

```bash
# Setup (one-time)
cd /path/to/OpenLineage
source .venv/bin/activate
make generate-setup
```

---

### Step 1: Create the JSON Schema

Create a new JSON file in `spec/facets/` following the OpenLineage JSON Schema format.

**File naming:** `{FacetName}{FacetType}Facet.json`

| Facet Type | Base Class | Example |
|------------|------------|---------|
| Dataset | `DatasetFacet` | `MyCustomDatasetFacet.json` |
| Job | `JobFacet` | `MyCustomJobFacet.json` |
| Run | `RunFacet` | `MyCustomRunFacet.json` |
| InputDataset | `InputDatasetFacet` | `MyCustomInputDatasetFacet.json` |
| OutputDataset | `OutputDatasetFacet` | `MyCustomOutputDatasetFacet.json` |

> **⚠️ CRITICAL: `$id` URL Requirement**
> 
> The `$id` field in your JSON schema **MUST** use a **reachable domain**. For DataOS custom facets, use:
> ```
> "$id": "https://github.com/moderndatacompany/OpenLineage/spec/facets/1-0-0/YourFacetName.json"
> ```
> 
> **Alternative** (for facets that may be upstreamed to OpenLineage):
> ```
> "$id": "https://openlineage.io/spec/facets/1-0-0/YourFacetName.json"
> ```
> 
> **Do NOT use non-existent domains** like `dataos.io`, `example.com`, or unregistered company domains.
> 
> **Why?** The Java code generator validates that the `$id` URL's domain is reachable. Using a non-existent 
> domain causes `UnknownHostException` errors and the build will fail. Both `github.com/moderndatacompany` 
> and `openlineage.io` are reachable domains - they will return a 404 for unpublished specs, which the 
> generator handles gracefully with a warning.

**Example:** `spec/facets/MyCustomDatasetFacet.json`

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://github.com/moderndatacompany/OpenLineage/spec/facets/1-0-0/MyCustomDatasetFacet.json",
  "$defs": {
    "MyCustomDatasetFacet": {
      "allOf": [
        {
          "$ref": "https://openlineage.io/spec/2-0-2/OpenLineage.json#/$defs/DatasetFacet"
        },
        {
          "type": "object",
          "properties": {
            "myField": {
              "description": "Description of this field",
              "type": "string"
            },
            "anotherField": {
              "description": "Another field description",
              "type": "integer"
            }
          },
          "required": ["myField"]
        }
      ],
      "type": "object"
    }
  },
  "type": "object",
  "properties": {
    "myCustom": {
      "$ref": "#/$defs/MyCustomDatasetFacet"
    }
  }
}
```

**Key points:**
- `$id`: Must use a reachable domain - `github.com/moderndatacompany/...` or `openlineage.io/...` (see warning above)
- `allOf`: Reference the appropriate base facet type from OpenLineage spec
- `properties`: Define your custom fields with descriptions
- `required`: List required fields (optional, omit for all fields optional)

---

### Step 2: Generate Python Code

Run the generator using the Makefile command:

```bash
make python-generate
```

This will:
1. Read all JSON schemas from `spec/facets/`
2. Generate Python classes in `client/python/src/openlineage/client/generated/`
3. Update `facet_v2.py` to export the new facet

**Note:** You may see a ruff warning for `base_subset_dataset.py` - this is a pre-existing issue and can be ignored.

---

### Step 2b: Generate Java Code

Run the Java generator using the Makefile command:

```bash
make java-generate
```

This will:
1. Read all JSON schemas from `spec/facets/` and `spec/registry/`
2. Generate Java classes in `client/java/src/main/java/io/openlineage/client/OpenLineage.java`

**Expected output:**
```
Generating Java code from spec...
Note: Using --rerun-tasks --no-build-cache to ensure fresh generation
...
[main] WARN io.openlineage.client.Generator - This version of the spec is not published yet: https://openlineage.io/spec/facets/1-0-0/MyCustomDatasetFacet.json
...
BUILD SUCCESSFUL
✅ Java code generated!
```

**Note:** The warning "This version of the spec is not published yet" is expected for custom facets. The generator verifies the `$id` URL exists - unpublished specs will show this warning but generation will succeed.

**Verify your facet was generated:**
```bash
grep -n "MyCustom" client/java/src/main/java/io/openlineage/client/OpenLineage.java | head -10
```

---

### Step 3: Verify the Generated Code

Check that your facet was generated:

```bash
# View the generated file
cat client/python/src/openlineage/client/generated/my_custom_dataset.py
```

Expected output:

```python
@attr.define
class MyCustomDatasetFacet(DatasetFacet):
    myField: str
    """Description of this field"""
    
    anotherField: int | None = attr.field(default=None)
    """Another field description"""

    @staticmethod
    def _get_schema() -> str:
        return "https://dataos.io/spec/facets/1-0-0/MyCustomDatasetFacet.json#/$defs/MyCustomDatasetFacet"
```

---

### Step 4: Build and Test

#### Python

Build the Python wheel:

```bash
cd /path/to/OpenLineage
make python-build
```

Run existing tests to verify nothing is broken:

```bash
make python-test
```

Install and test:

```bash
pip install client/python/dist/dataos_openlineage_python-*.whl --force-reinstall

# Verify import works
python -c "from openlineage.client.generated.my_custom_dataset import MyCustomDatasetFacet; print('Success!')"

# Verify it's in facet_v2
python -c "from openlineage.client.facet_v2 import *; print('my_custom_dataset' in dir())"
```

#### Java

Build the Java JAR (includes running tests):

```bash
make java-build-quick
```

This command runs 400+ existing tests. All tests should pass.

Publish to local Maven for testing:

```bash
make java-publish-local
```

Test in your Java project by adding the dependency:
```xml
<dependency>
    <groupId>io.dataos.openlineage</groupId>
    <artifactId>openlineage-java</artifactId>
    <version>1.43.0.1-SNAPSHOT</version>
</dependency>
```

Example usage:
```java
OpenLineage ol = new OpenLineage(URI.create("https://example.com"));

// Using builder
MyCustomDatasetFacet facet = ol.newMyCustomDatasetFacetBuilder()
    .myField("value")
    .anotherField(42)
    .build();
```

---

### Step 5: Commit and Create PR

```bash
# Add your changes
git add spec/facets/MyCustomDatasetFacet.json

# Python generated files
git add client/python/src/openlineage/client/generated/my_custom_dataset.py
git add client/python/src/openlineage/client/facet_v2.py

# Java generated file
git add client/java/src/main/java/io/openlineage/client/OpenLineage.java

# Commit
git commit -m "Add MyCustomDatasetFacet for [purpose]"

# Push and create PR
git push origin your-branch
```

---

## PR Checklist

Before submitting your PR, ensure:

```
□ JSON schema follows OpenLineage format
□ Schema $id uses a reachable domain (see $id URL Requirement above)
□ Python generator ran successfully (make python-generate)
□ Java generator ran successfully (make java-generate)
□ Generated Python file is committed (client/python/src/openlineage/client/generated/)
□ Generated facet_v2.py is committed
□ Generated OpenLineage.java is committed (client/java/src/main/java/...)
□ Python build succeeds (make python-build)
□ Java build succeeds (make java-build-quick)
□ Existing tests pass (make python-test)
□ Import test passes (python -c "from openlineage.client.generated.your_facet import ...")
□ PR description explains the facet purpose
```

### About Tests

**You do NOT need to write new tests for custom facets.** The existing test suite validates the facet framework. Just ensure:

1. **Run existing tests** - `make python-test` should pass
2. **Java tests run during build** - `make java-build-quick` includes tests
3. **Manual import check** - Verify your facet can be imported

The 400+ existing tests already cover serialization, deserialization, and the facet framework. If your facet follows the JSON schema format and the existing tests pass, your facet will work correctly.

---

## JSON Schema Reference

### Field Types

| JSON Type | Python Type | Example |
|-----------|-------------|---------|
| `string` | `str` | `"type": "string"` |
| `integer` | `int` | `"type": "integer"` |
| `number` | `float` | `"type": "number"` |
| `boolean` | `bool` | `"type": "boolean"` |
| `array` | `list` | `"type": "array", "items": {...}` |
| `object` | `dict` | `"type": "object"` |

### Special Formats

| Format | Python Validation |
|--------|-------------------|
| `date-time` | ISO-8601 datetime validation |
| `uri` | URL validation |
| `uuid` | UUID validation |

### Optional vs Required Fields

**Required field** (no default):
```json
"properties": {
  "myField": { "type": "string" }
},
"required": ["myField"]
```

**Optional field** (has default):
```json
"properties": {
  "myField": { "type": "string" }
}
// Not in "required" array → generates with default=None
```

---

## Nested Classes

For complex facets with nested structures:

```json
{
  "$defs": {
    "NestedClass": {
      "type": "object",
      "properties": {
        "nestedField": { "type": "string" }
      },
      "required": ["nestedField"]
    },
    "MyComplexFacet": {
      "allOf": [
        { "$ref": "https://openlineage.io/spec/2-0-2/OpenLineage.json#/$defs/DatasetFacet" },
        {
          "type": "object",
          "properties": {
            "nested": { "$ref": "#/$defs/NestedClass" },
            "nestedList": {
              "type": "array",
              "items": { "$ref": "#/$defs/NestedClass" }
            }
          }
        }
      ]
    }
  }
}
```

---

## Examples

Look at existing facets in `spec/facets/` for reference:

| Facet | Good Example Of |
|-------|-----------------|
| `SchemaDatasetFacet.json` | Nested classes, arrays |
| `DocumentationJobFacet.json` | Simple facet with optional fields |
| `ColumnLineageDatasetFacet.json` | Complex nested structures |
| `TagsDatasetFacet.json` | Arrays of objects |

---

## Troubleshooting

### Java Generator Issues

**Error: `UnknownHostException: yourdomain.io`**
```
Caused by: java.net.UnknownHostException: yourdomain.io
```
**Fix:** Your JSON schema's `$id` URL uses a domain that doesn't exist. Change it to use either:
- `https://github.com/moderndatacompany/OpenLineage/spec/facets/...` (recommended for DataOS facets)
- `https://openlineage.io/spec/facets/...` (for facets that may be upstreamed)

**Error: Task shows `UP-TO-DATE` but file not generated**
```
> Task :generateCode UP-TO-DATE
```
**Fix:** The Makefile command already includes `--rerun-tasks --no-build-cache` flags. If you're running Gradle directly, use:
```bash
cd client/java && ./gradlew --rerun-tasks --no-build-cache generateCode
```

**Warning: "This version of the spec is not published yet"**
```
[main] WARN io.openlineage.client.Generator - This version of the spec is not published yet: https://openlineage.io/spec/facets/1-0-0/MyCustomFacet.json
```
**This is expected** for custom facets. The generator validates the URL but continues with a warning.

### Python Generator Issues

**Error: `ModuleNotFoundError: No module named 'openlineage'`**
**Fix:** Install the package in editable mode first:
```bash
make generate-setup
# OR
pip install -e "client/python[generator]"
```

**Error: `ModuleNotFoundError: No module named 'base'`**
**Fix:** Run the generator from the correct directory:
```bash
cd client/python/src/openlineage/client/generator && python generate.py
# OR just use:
make python-generate
```

**Warning: `base_subset_dataset.py failed on ruff`**
This is a pre-existing issue with an upstream schema. The file is still generated and usable.

---

## Getting Help

- Check existing facets in `spec/facets/` for patterns
- Review generated code in `client/python/src/openlineage/client/generated/`
- Upstream OpenLineage docs: `website/docs/spec/facets/`
- Contact: DataOS team members (Animesh Kumar, Akshay Jain, Rakesh Vishwakarma)
