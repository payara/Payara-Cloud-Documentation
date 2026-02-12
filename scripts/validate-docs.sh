#!/usr/bin/env bash

# Master validation script - runs all documentation validators

# Ensure we're at repository root
cd "$(git rev-parse --show-toplevel)" || exit 1

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Documentation Validation Suite${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

failed_validators=()
passed_validators=()
all_warnings=()
all_errors=()

# Function to run a validator
run_validator() {
    local name="$1"
    local script="$2"
    local temp_output=$(mktemp)

    echo -e "${BLUE}Running: $name...${NC}"

    # Run validator and capture output
    if bash "scripts/$script" > "$temp_output" 2>&1; then
        passed_validators+=("$name")
        exit_code=0
    else
        failed_validators+=("$name")
        exit_code=1
    fi

    # Extract warnings and errors from output
    while IFS= read -r line; do
        # Check if line contains WARNING (with ANSI codes)
        if echo "$line" | grep -q "WARNING"; then
            all_warnings+=("[$name] $line")
        # Check if line contains ERROR (with ANSI codes)
        elif echo "$line" | grep -q "ERROR"; then
            all_errors+=("[$name] $line")
        fi
    done < "$temp_output"

    rm "$temp_output"
    return $exit_code
}

# Run all validators (continue even if some fail)
run_validator "Product Name Validation" "validate-product-names.sh" || true
run_validator "Deprecated Name Check" "validate-deprecated-names.sh" || true
run_validator "Link Integrity Check" "validate-links.sh" || true
run_validator "Navigation Validation" "validate-nav.sh" || true
run_validator "Conditional Content Check" "validate-conditionals.sh" || true
run_validator "Image Reference Check" "validate-images.sh" || true
run_validator "Empty File Check" "validate-empty.sh" || true

echo ""

# Display all warnings
if [ ${#all_warnings[@]} -gt 0 ]; then
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}All Warnings (${#all_warnings[@]})${NC}"
    echo -e "${YELLOW}========================================${NC}"
    echo ""
    for warning in "${all_warnings[@]}"; do
        echo -e "$warning"
    done
    echo ""
fi

# Display all errors
if [ ${#all_errors[@]} -gt 0 ]; then
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}All Errors (${#all_errors[@]})${NC}"
    echo -e "${RED}========================================${NC}"
    echo ""
    for error in "${all_errors[@]}"; do
        echo -e "$error"
    done
    echo ""
fi

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Validation Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

if [ ${#passed_validators[@]} -gt 0 ]; then
    echo -e "${GREEN}Passed (${#passed_validators[@]}):${NC}"
    for validator in "${passed_validators[@]}"; do
        echo -e "  ${GREEN}✓${NC} $validator"
    done
    echo ""
fi

if [ ${#failed_validators[@]} -gt 0 ]; then
    echo -e "${RED}Failed (${#failed_validators[@]}):${NC}"
    for validator in "${failed_validators[@]}"; do
        echo -e "  ${RED}✗${NC} $validator"
    done
    echo ""
fi

# Final result
if [ ${#failed_validators[@]} -eq 0 ]; then
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}All validations passed!${NC}"
    echo -e "${GREEN}========================================${NC}"
    exit 0
else
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}${#failed_validators[@]} validation(s) failed${NC}"
    echo -e "${RED}========================================${NC}"
    exit 1
fi
