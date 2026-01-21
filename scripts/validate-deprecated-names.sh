#!/usr/bin/env bash
set -e

# Validate that deprecated product names are not used in documentation

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

error_count=0

echo "Checking for deprecated product names..."
echo ""

# Search for "Payara Cloud" in all .adoc files
# This should have been replaced with "Payara Qube (Managed)"
while IFS= read -r -d '' file; do
    # Skip _attributes.adoc as it may contain migration notes
    if [[ "${file}" == *"_attributes.adoc"* ]]; then
        continue
    fi

    line_num=0
    while IFS= read -r line; do
        line_num=$((line_num + 1))

        if echo "${line}" | grep -q "Payara Cloud"; then
            echo -e "${RED}ERROR${NC}: ${file}:${line_num}"
            echo "  → Found deprecated name: 'Payara Cloud'"
            echo "  → Should be: 'Payara Qube (Managed)'"
            echo "  → Line: ${line}"
            echo ""
            error_count=$((error_count + 1))
        fi
    done < "${file}"
done < <(find docs/modules -name "*.adoc" -type f -print0)

# Final result
if [[ "${error_count}" -eq 0 ]]; then
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Deprecated name validation passed!${NC}"
    echo -e "${GREEN}========================================${NC}"
    exit 0
else
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}Deprecated name validation failed${NC}"
    echo -e "${RED}Errors: ${error_count}${NC}"
    echo -e "${RED}========================================${NC}"
    exit 1
fi
