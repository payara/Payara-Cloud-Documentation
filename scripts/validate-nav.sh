#!/usr/bin/env bash
set -e

# Validate navigation completeness and correctness

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

error_count=0
warning_count=0

echo "Validating navigation..."
echo ""

# Check each module's navigation
for module_dir in docs/modules/*; do
    [[ -d "$module_dir" ]] || continue

    module=$(basename "$module_dir")
    nav_file="${module_dir}/nav.adoc"
    pages_dir="${module_dir}/pages"

    [[ -d "$pages_dir" ]] || continue

    echo "Checking module: ${module}"

    # Check if nav.adoc exists
    if [[ ! -f "$nav_file" ]]; then
        echo -e "${YELLOW}WARNING${NC}: Module ${module} has no nav.adoc"
        warning_count=$((warning_count + 1))
        continue
    fi

    # Extract page references from nav.adoc
    # Matches: xref:page.adoc[text] or * xref:page.adoc[text]
    # Use process substitution to handle filenames with spaces
    nav_pages_temp=""
    while IFS= read -r xref_match; do
        # Remove xref: prefix to get the page path
        nav_page="${xref_match#xref:}"

        # Remove anchor if present (e.g. page.adoc#section -> page.adoc)
        nav_page="${nav_page%%#*}"

        # Skip inter-module or component links (contain ':')
        if [[ "$nav_page" == *:* ]]; then
            continue
        fi

        if [[ ! -f "${pages_dir}/${nav_page}" ]]; then
            echo -e "${RED}ERROR${NC}: Navigation in ${module} references non-existent page: ${nav_page}"
            echo "  → Expected at: ${pages_dir}/${nav_page}"
            error_count=$((error_count + 1))
        fi

        # Collect nav pages for orphan detection
        nav_pages_temp="${nav_pages_temp}${nav_page}"$'\n'
    done < <(grep -oP 'xref:[^\[]+' "$nav_file" 2>/dev/null | sort -u || true)

    # Check for orphaned pages (exist but not in nav)
    # Use process substitution with while loop to handle filenames with spaces
    while IFS= read -r -d '' page_path; do
        # Get relative path from pages_dir
        rel_path="${page_path#${pages_dir}/}"
        page=$(basename "$page_path")

        if ! echo "$nav_pages_temp" | grep -qxF "$rel_path"; then
            # Allow certain common files to be unlisted
            if [[ "$page" != "README.adoc" && "$page" != "_"* ]]; then
                echo -e "${YELLOW}WARNING${NC}: Page exists but not in navigation: ${module}/${page}"
                echo "  → Page location: ${page_path}"
                warning_count=$((warning_count + 1))
            fi
        fi
    done < <(find "$pages_dir" -name "*.adoc" -type f -print0)
done

echo ""

# Check antora.yml nav references
echo "Checking antora.yml navigation references..."

if [[ -f "docs/antora.yml" ]]; then
    # Extract module nav references from antora.yml
    grep -A 20 "^nav:" docs/antora.yml | grep "modules/" | while read -r line; do
        # Extract: modules/MODULE/nav.adoc
        if [[ "$line" =~ modules/([^/]+)/nav\.adoc ]]; then
            module="${BASH_REMATCH[1]}"
            nav_path="docs/modules/${module}/nav.adoc"

            if [[ ! -f "$nav_path" ]]; then
                echo -e "${RED}ERROR${NC}: antora.yml references non-existent nav file: ${nav_path}"
                error_count=$((error_count + 1))
            fi
        fi
    done
fi

echo ""

# Final result
if [[ "${error_count}" -eq 0 ]] && [[ "${warning_count}" -eq 0 ]]; then
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Navigation validation passed!${NC}"
    echo -e "${GREEN}========================================${NC}"
    exit 0
elif [[ "${error_count}" -eq 0 ]]; then
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}Navigation validation passed with ${warning_count} warning(s)${NC}"
    echo -e "${YELLOW}========================================${NC}"
    exit 0
else
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}Navigation validation failed${NC}"
    echo -e "${RED}Errors: ${error_count}, Warnings: ${warning_count}${NC}"
    echo -e "${RED}========================================${NC}"
    exit 1
fi
