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
