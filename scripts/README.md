# Setup Scripts

## Git Hooks Installation

### For Contributors

After cloning this repository, run the following command to install git hooks:

```bash
./scripts/install-hooks.sh
```

This installs a pre-commit hook that validates documentation before allowing commits:
- Product name validation (when `_attributes.adoc` or `.yml` files change)
- Conditional content validation (when `.adoc` files change)

### What Gets Installed

- **pre-commit hook**: Validates product names when committing changes to:
  - `docs/modules/*/partials/_attributes.adoc`
  - `*.yml` playbook files

### Manual Installation

If the automated installation doesn't work, you can manually copy the hook:

```bash
cp scripts/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

## Verification

After installation, verify the hook is working:

```bash
# Check hook is installed and executable
ls -la .git/hooks/pre-commit

# Test the hook (should pass with current configuration)
git add docs/modules/ROOT/partials/_attributes.adoc
git commit -m "test commit"
# You should see validation output before the commit succeeds
```

## Bypassing the Hook

In rare cases where you need to bypass validation (not recommended):

```bash
git commit --no-verify -m "your message"
```

**Note**: This should only be used in exceptional circumstances, as it bypasses important validation checks.

---

## Documentation Validation Scripts

### Running All Validations

To run the complete validation suite locally:

```bash
./scripts/validate-docs.sh
```

This runs all validators and provides a summary of passed/failed checks.

### Individual Validators

Each validator can be run independently:

| Script | Purpose |
|--------|---------|
| `validate-product-names.sh` | Ensures product names and slugs are correctly configured |
| `validate-deprecated-names.sh` | Checks for deprecated product name usage |
| `validate-links.sh` | Validates internal and external link integrity |
| `validate-nav.sh` | Checks navigation structure consistency |
| `validate-conditionals.sh` | Validates conditional content blocks |
| `validate-images.sh` | Verifies image references exist |
| `validate-empty.sh` | Detects empty documentation files |

### Running Individual Validators

```bash
# Run a specific validator
./scripts/validate-links.sh
./scripts/validate-product-names.sh
```

### Exit Codes

All validators return:
- `0` - All checks passed
- `1` - One or more checks failed
