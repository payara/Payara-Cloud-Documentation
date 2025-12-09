#!/usr/bin/env bash
set -e

# Expected product names
QUBE_NAME="Payara Qube"
CLOUD_NAME="Payara Qube (Managed)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

error_count=0

echo "Validating product names configuration..."
echo ""

# Check _attributes files are identical
echo "Checking if _attributes.adoc files are in sync..."
if ! diff -q docs/modules/ROOT/partials/_attributes.adoc \
        docs/modules/reference/partials/_attributes.adoc > /dev/null 2>&1; then
    echo -e "${RED}ERROR: _attributes.adoc files are out of sync${NC}"
    echo "Differences found:"
    diff docs/modules/ROOT/partials/_attributes.adoc \
         docs/modules/reference/partials/_attributes.adoc || true
    error_count=$((error_count + 1))
else
    echo -e "${GREEN}✓ _attributes.adoc files are in sync${NC}"
fi
echo ""

# Validate product names in attributes files
echo "Checking product names in _attributes.adoc..."
if ! grep -q "productName: ${QUBE_NAME}$" docs/modules/ROOT/partials/_attributes.adoc; then
    echo -e "${RED}ERROR: Qube product name incorrect in _attributes.adoc${NC}"
    echo "Expected: productName: ${QUBE_NAME}"
    echo "Found:"
    grep "productName.*qube" docs/modules/ROOT/partials/_attributes.adoc || echo "  (not found)"
    error_count=$((error_count + 1))
else
    echo -e "${GREEN}✓ Qube product name is correct: '${QUBE_NAME}'${NC}"
fi

if ! grep -q "productName: ${CLOUD_NAME}" docs/modules/ROOT/partials/_attributes.adoc; then
    echo -e "${RED}ERROR: Cloud product name incorrect in _attributes.adoc${NC}"
    echo "Expected: productName: ${CLOUD_NAME}"
    echo "Found:"
    grep "productName.*cloud" docs/modules/ROOT/partials/_attributes.adoc || echo "  (not found)"
    error_count=$((error_count + 1))
else
    echo -e "${GREEN}✓ Cloud product name is correct: '${CLOUD_NAME}'${NC}"
fi
echo ""

# Validate local playbook configurations
echo "Checking local playbook configurations..."

if [[ -f "qube.yml" ]]; then
    if ! grep -q "page-site-edition: 'qube'" "qube.yml"; then
        echo -e "${RED}ERROR: qube.yml doesn't set page-site-edition: 'qube'${NC}"
        error_count=$((error_count + 1))
    else
        echo -e "${GREEN}✓ qube.yml sets page-site-edition correctly${NC}"
    fi
else
    echo -e "${YELLOW}WARNING: qube.yml not found${NC}"
fi

if [[ -f "cloud.yml" ]]; then
    if ! grep -q "page-site-edition: 'cloud'" "cloud.yml"; then
        echo -e "${RED}ERROR: cloud.yml doesn't set page-site-edition: 'cloud'${NC}"
        error_count=$((error_count + 1))
    else
        echo -e "${GREEN}✓ cloud.yml sets page-site-edition correctly${NC}"
    fi
else
    echo -e "${YELLOW}WARNING: cloud.yml not found${NC}"
fi
echo ""

# Validate edition slug values
echo "Checking edition slugs in _attributes.adoc..."
if ! grep -q ":productEditionSlug: qube" docs/modules/ROOT/partials/_attributes.adoc; then
    echo -e "${RED}ERROR: Qube edition slug incorrect${NC}"
    error_count=$((error_count + 1))
else
    echo -e "${GREEN}✓ Qube edition slug is correct${NC}"
fi

if ! grep -q ":productEditionSlug: cloud" docs/modules/ROOT/partials/_attributes.adoc; then
    echo -e "${RED}ERROR: Cloud edition slug incorrect${NC}"
    error_count=$((error_count + 1))
else
    echo -e "${GREEN}✓ Cloud edition slug is correct${NC}"
fi
echo ""

# Final result
if [[ "${error_count}" -eq 0 ]]; then
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}All product name validations passed!${NC}"
    echo -e "${GREEN}========================================${NC}"
    exit 0
else
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}Validation failed with ${error_count} error(s)${NC}"
    echo -e "${RED}========================================${NC}"
    exit 1
fi
