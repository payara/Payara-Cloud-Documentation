#!/usr/bin/env bash
set -e

# Validate internal xref links in AsciiDoc files

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

error_count=0
warning_count=0

echo "Validating internal links..."
echo ""

# Find all xref links in .adoc files
echo "Checking xref links..."

while IFS= read -r -d '' file; do
    # Extract xrefs from this file
    # Matches: xref:page.adoc[text], xref:module:page.adoc[text], or xref:component:module:page.adoc[text]
    grep -oP 'xref:[^\[]+' "$file" 2>/dev/null | while read -r xref_line; do
        # Remove 'xref:' prefix
        target="${xref_line#xref:}"

        # Determine current module from file path
        current_module=""
        if [[ "$file" =~ docs/modules/([^/]+)/ ]]; then
            current_module="${BASH_REMATCH[1]}"
        fi

        # Parse Antora xref formats:
        # 1. component:module:page.adoc (e.g., docs:ROOT:page.adoc)
        # 2. module:page.adoc (e.g., ROOT:page.adoc)
        # 3. page.adoc (same module)

        module="$current_module"
        page="$target"

        # Count colons to determine format
        colon_count=$(echo "$target" | tr -cd ':' | wc -c)

        if [[ "${colon_count}" -ge 2 ]]; then
            # Format: component:module:page.adoc
            # Extract module and page (skip component for now - assume same component)
            if [[ "$target" =~ ^[^:]+:([^:]+):(.+)$ ]]; then
                module="${BASH_REMATCH[1]}"
                page="${BASH_REMATCH[2]}"
            fi
        elif [[ "${colon_count}" -eq 1 ]]; then
            # Format: module:page.adoc
            module="${target%%:*}"
            page="${target#*:}"
        fi
        # else: page.adoc format, use current module

        # Remove anchor if present
        page="${page%%#*}"

        # Check if module exists
        if [[ ! -d "docs/modules/${module}" ]]; then
            echo -e "${RED}ERROR${NC}: $file"
            echo "  → xref to non-existent module: ${module}"
            echo "  → Full xref: ${target}"
            error_count=$((error_count + 1))
            continue
        fi

        # Check if page exists in that module
        if [[ ! -f "docs/modules/${module}/pages/${page}" ]]; then
            echo -e "${RED}ERROR${NC}: $file"
            echo "  → xref to non-existent page: ${module}/${page}"
            echo "  → Full xref: ${target}"
            error_count=$((error_count + 1))
        fi
    done
done < <(find docs/modules -name "*.adoc" -type f -print0)

if [[ "${error_count}" -eq 0 ]]; then
    echo -e "${GREEN}✓ All xref links are valid${NC}"
else
    echo -e "${RED}✗ Found ${error_count} broken xref link(s)${NC}"
fi
echo ""

# Check for external links (just report, don't validate)
echo "Scanning external links (https/http)..."
external_count=0

while IFS= read -r -d '' file; do
    grep -oP 'https?://[^\s\[\]]+' "$file" 2>/dev/null | while read -r url; do
        external_count=$((external_count + 1))
    done
done < <(find docs/modules -name "*.adoc" -type f -print0)

echo -e "${YELLOW}ℹ Found ${external_count} external link(s) (not validated)${NC}"
echo ""

# Final result
if [[ "${error_count}" -eq 0 ]]; then
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Link validation passed!${NC}"
    echo -e "${GREEN}========================================${NC}"
    exit 0
else
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}Link validation failed with ${error_count} error(s)${NC}"
    echo -e "${RED}========================================${NC}"
    exit 1
fi
