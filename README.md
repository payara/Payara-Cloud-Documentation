# Payara Qube Documentation

Source documentation for **Payara Qube** (self-hosted) and **Payara Qube (Managed)** (cloud service), built with [Antora](https://antora.org/).

This repository uses conditional attributes to generate edition-specific documentation from a single codebase.
The `page-site-edition` attribute (set to `qube` or `cloud` in playbook files) is evaluated in `_attributes.adoc` to determine which product name appears in the generated documentation.

## Repository Structure

```
.
├── docs/
│   ├── antora.yml                  # Component descriptor
│   └── modules/                    # Documentation modules
│       ├── ROOT/                   # Core documentation
│       │   └── partials/_attributes.adoc  # Product name definitions (source of truth)
│       ├── reference/              # API reference
│       ├── cli/                    # CLI documentation
│       ├── maven-plugin/           # Maven plugin
│       └── intellij-idea-plugin/   # IntelliJ plugin
│
├── qube.yml                        # Build config for Qube edition
├── cloud.yml                       # Build config for Cloud edition
│
├── validate-*.sh                   # Validation scripts
├── validate-docs.sh                # Master validator (runs all)
│
└── scripts/
    ├── install-hooks.sh            # Install git hooks
    └── pre-commit                  # Pre-commit validation
```

## Getting Started

**Prerequisites:**
- [Node.js](https://nodejs.org/)
- Antora CLI: `npm install -g @antora/cli @antora/site-generator`

**For Contributors:**

1. Install git hooks (runs validators on commit):
   ```bash
   ./scripts/install-hooks.sh
   ```

2. Verify setup:
   ```bash
   ./validate-docs.sh
   ```

## Building Documentation

Build specific editions:
```bash
# Qube edition
antora qube.yml

# Cloud edition
antora cloud.yml
```

Output generates to `build/html/` (or configured output directory).

## Validation Suite

Run all validators before submitting PRs:
```bash
./validate-docs.sh
```

### Individual Validators

| Validator                      | Purpose                                                                         |
|--------------------------------|---------------------------------------------------------------------------------|
| `validate-product-names.sh`    | Ensures product names in `_attributes.adoc` and playbooks match expected values |
| `validate-deprecated-names.sh` | Detects usage of deprecated product name "Payara Cloud" in documentation        |
| `validate-nav.sh`              | Verifies navigation entries point to existing pages, identifies orphaned pages  |
| `validate-links.sh`            | Checks integrity of internal `xref` links between pages and modules             |
| `validate-images.sh`           | Confirms referenced images exist in assets, warns about unused images           |
| `validate-conditionals.sh`     | Validates `ifeval`/`ifdef` blocks use correct product names for each edition    |
| `validate-empty.sh`            | Detects empty or whitespace-only `.adoc` files                                  |

### Test Suite

Test the validators:
```bash
./test-product-names.sh
```

## Product Name System

Product names are defined once in `docs/modules/ROOT/partials/_attributes.adoc`:

```asciidoc
ifeval::["{page-site-edition}" == "qube"]
:productName: Payara Qube
:productEditionSlug: qube
endif::[]

ifeval::["{page-site-edition}" == "cloud"]
:productName: Payara Qube (Managed)
:productEditionSlug: cloud
endif::[]
```

Reference in content using `{productName}` instead of hard-coding product names.

**Important:** The `reference` module's `_attributes.adoc` is a **symlink** to ROOT's version. This ensures consistency across all modules.

## Contributing

1. **Never hard-code product names** - always use `{productName}` attribute
2. **Run validation before committing** - `./validate-docs.sh`
3. **Use edition-specific content blocks** when content differs:
   ```asciidoc
   ifeval::["{page-site-edition}" == "qube"]
   Self-hosted specific content here
   endif::[]

   ifeval::["{page-site-edition}" == "cloud"]
   Managed service specific content here
   endif::[]
   ```
4. **Test both editions** when making structural changes:
   ```bash
   antora qube.yml && antora cloud.yml
   ```

## Pipeline Integration

The GitHub Actions workflow (`.github/workflows/validate-docs.yml`) runs all validators on:
- Pull requests
- Pushes to main branches

Failed validation blocks merging.

## Troubleshooting

### Validation Fails: "Product name incorrect"
Check `docs/modules/ROOT/partials/_attributes.adoc` has correct product names:
- Qube edition: `Payara Qube`
- Cloud edition: `Payara Qube (Managed)`

### Validation Fails: "_attributes.adoc files out of sync"
The reference module should symlink to ROOT:
```bash
cd docs/modules/reference/partials
rm _attributes.adoc
ln -s ../../ROOT/partials/_attributes.adoc _attributes.adoc
```

### Navigation Errors
Ensure all `xref:` paths in `nav.adoc` files:
- Point to existing `.adoc` files
- Use correct relative paths from the `pages/` directory
- Don't reference inter-module links without proper format (`module:page.adoc`)

### Unclosed Conditional Blocks
Every `ifdef`, `ifndef`, or `ifeval` needs a matching `endif::[]`. Run:
```bash
./validate-conditionals.sh
```

### Build Fails: "Page not found"
1. Check the page exists in `docs/modules/MODULE/pages/`
2. Verify `xref:` syntax is correct
3. Ensure cross-module references use `module:page.adoc` format

## License

[Add license information here]
