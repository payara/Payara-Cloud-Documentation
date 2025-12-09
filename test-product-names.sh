#!/usr/bin/env bash

# Test suite for product name configuration
# Each function runs an independent test and reports PASS/FAIL

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0

# Test helper functions
pass() {
    echo -e "${GREEN}PASS${NC}: $1"
    PASSED=$((PASSED + 1))
}

fail() {
    echo -e "${RED}FAIL${NC}: $1"
    if [[ -n "$2" ]]; then
        echo "  Details: $2"
    fi
    FAILED=$((FAILED + 1))
}

# Test 1: _attributes files are identical
test_attributes_files_identical() {
    if diff -q docs/modules/ROOT/partials/_attributes.adoc \
            docs/modules/reference/partials/_attributes.adoc > /dev/null 2>&1; then
        pass "_attributes.adoc files are identical"
    else
        fail "_attributes.adoc files differ" "$(diff docs/modules/ROOT/partials/_attributes.adoc docs/modules/reference/partials/_attributes.adoc | head -5)"
    fi
}

# Test 2: Qube product name in attributes
test_qube_name() {
    if grep -q 'productName: Payara Qube$' docs/modules/ROOT/partials/_attributes.adoc; then
        pass "Qube product name is correct"
    else
        local found=$(grep 'productName.*qube' docs/modules/ROOT/partials/_attributes.adoc || echo "not found")
        fail "Qube product name is incorrect" "Expected 'Payara Qube', found: $found"
    fi
}

# Test 3: Cloud product name in attributes
test_cloud_name() {
    if grep -q 'productName: Payara Qube (Managed)' docs/modules/ROOT/partials/_attributes.adoc; then
        pass "Cloud product name is correct"
    else
        local found=$(grep 'productName.*cloud' docs/modules/ROOT/partials/_attributes.adoc || echo "not found")
        fail "Cloud product name is incorrect" "Expected 'Payara Qube (Managed)', found: $found"
    fi
}

# Test 4: Edition slugs are correct
test_edition_slugs() {
    local qube_slug=$(grep -A2 'page-site-edition.*qube' docs/modules/ROOT/partials/_attributes.adoc | grep 'productEditionSlug' | awk -F': ' '{print $2}')
    local cloud_slug=$(grep -A2 'page-site-edition.*cloud' docs/modules/ROOT/partials/_attributes.adoc | grep 'productEditionSlug' | awk -F': ' '{print $2}')

    if [[ "$qube_slug" == "qube" ]] && [[ "$cloud_slug" == "cloud" ]]; then
        pass "Edition slugs are correct (qube: $qube_slug, cloud: $cloud_slug)"
    else
        fail "Edition slugs are incorrect" "qube: $qube_slug (expected: qube), cloud: $cloud_slug (expected: cloud)"
    fi
}

# Test 5: Local qube.yml configuration
test_local_qube_yml() {
    if [[ ! -f "qube.yml" ]]; then
        echo -e "${YELLOW}SKIP${NC}: Local qube.yml (file not found)"
        return
    fi

    if grep -q "page-site-edition: 'qube'" "qube.yml"; then
        pass "Local qube.yml sets page-site-edition correctly"
    else
        fail "Local qube.yml page-site-edition is incorrect"
    fi
}

# Test 6: Local cloud.yml configuration
test_local_cloud_yml() {
    if [[ ! -f "cloud.yml" ]]; then
        echo -e "${YELLOW}SKIP${NC}: Local cloud.yml (file not found)"
        return
    fi

    if grep -q "page-site-edition: 'cloud'" "cloud.yml"; then
        pass "Local cloud.yml sets page-site-edition correctly"
    else
        fail "Local cloud.yml page-site-edition is incorrect"
    fi
}

# Main test execution
echo "=========================================="
echo "Product Name Configuration Test Suite"
echo "=========================================="
echo ""

test_attributes_files_identical
test_qube_name
test_cloud_name
test_edition_slugs
test_local_qube_yml
test_local_cloud_yml

echo ""
echo "=========================================="
echo "Test Results"
echo "=========================================="
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi
