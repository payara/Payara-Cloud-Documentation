#!/usr/bin/env bash
set -e

# Validate that .adoc files are not empty (contain at least one non-whitespace character)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

error_count=0

echo "Checking for empty .adoc files (fast scan)..."
echo ""

# Use grep -rL to find files that do NOT match the pattern (i.e., are empty or contain only whitespace)
# -r: recursive search
# -L: list files that do NOT contain a match
# --include="*.adoc": only include .adoc files
# "[^[:space:]]": regex to find any non-whitespace character
empty_files=$(grep -rL "[^[:space:]]" docs/modules --include="*.adoc" || true)

if [[ -n "$empty_files" ]]; then
    echo -e "${RED}ERROR${NC}: Found empty or whitespace-only .adoc files:"
    while IFS= read -r file; do
        echo "  → $file"
        error_count=$((error_count + 1))
    done <<< "$empty_files"
fi

echo ""

# Final result
if [[ "${error_count}" -eq 0 ]]; then
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Empty file validation passed!${NC}"
    echo -e "${GREEN}========================================${NC}"
    exit 0
else
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}Empty file validation failed${NC}"
    echo -e "${RED}Errors: ${error_count}${NC}"
    echo -e "${RED}========================================${NC}"
    exit 1
fi
