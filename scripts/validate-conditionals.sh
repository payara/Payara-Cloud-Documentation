#!/usr/bin/env bash
set -e

# Validate conditional content blocks use correct product names

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

error_count=0
warning_count=0

echo "Validating conditional content..."
echo ""

# Expected product names for each edition
QUBE_NAME="Payara Qube"
CLOUD_NAME="Payara Qube (Managed)"

echo "Checking edition-specific content blocks..."

while IFS= read -r -d '' file; do
    # Skip attribute definition files
    [[ "$file" == *"_attributes.adoc" ]] && continue

    line_num=0
    in_qube_block=false
    in_cloud_block=false
    current_edition=""

    while IFS= read -r line; do
        line_num=$((line_num + 1))

        # Detect start of conditional blocks
        if [[ "$line" =~ ifeval::\[\"\{page-site-edition\}\"[[:space:]]*==[[:space:]]*\"qube\"\] ]]; then
            in_qube_block=true
            current_edition="qube"
            continue
        elif [[ "$line" =~ ifeval::\[\"\{page-site-edition\}\"[[:space:]]*==[[:space:]]*\"cloud\"\] ]]; then
            in_cloud_block=true
            current_edition="cloud"
            continue
        fi

        # Detect end of conditional blocks
        if [[ "$line" =~ ^endif:: ]]; then
            in_qube_block=false
            in_cloud_block=false
            current_edition=""
            continue
        fi

        # Check content within qube blocks
        if [[ "$in_qube_block" = true ]]; then
            # Should NOT contain "Payara Qube (Managed)" or "managed"
            if [[ "$line" =~ "Payara Qube (Managed)" ]]; then
                echo -e "${RED}ERROR${NC}: ${file}:${line_num}"
                echo "  → Qube-only block contains Cloud product name"
                echo "  → Found: 'Payara Qube (Managed)'"
                echo "  → Line: ${line}"
                error_count=$((error_count + 1))
            fi

            # Warn about suspicious "managed" mentions
            if [[ "$line" =~ [Mm]anaged[[:space:]]+(service|cloud|platform) ]]; then
                echo -e "${YELLOW}WARNING${NC}: ${file}:${line_num}"
                echo "  → Qube-only block mentions 'managed service/cloud'"
                echo "  → Line: ${line}"
                warning_count=$((warning_count + 1))
            fi
        fi

        # Check content within cloud blocks
        if [[ "$in_cloud_block" = true ]]; then
            # Check for wrong product name usage
            # If they write "Payara Qube" without "(Managed)", that's suspicious
            if [[ "$line" =~ Payara[[:space:]]+Qube[^[:space:]\(] ]]; then
                echo -e "${YELLOW}WARNING${NC}: ${file}:${line_num}"
                echo "  → Cloud-only block may be using wrong product name"
                echo "  → Expected: 'Payara Qube (Managed)' or '{productName}'"
                echo "  → Line: ${line}"
                warning_count=$((warning_count + 1))
            fi

            # Warn about "self-hosted" mentions
            if [[ "$line" =~ [Ss]elf-hosted ]]; then
                echo -e "${YELLOW}WARNING${NC}: ${file}:${line_num}"
                echo "  → Cloud-only block mentions 'self-hosted'"
                echo "  → Line: ${line}"
                warning_count=$((warning_count + 1))
            fi
        fi

        # Outside blocks: check for hard-coded product names instead of {productName}
        if [[ "$in_qube_block" = false ]] && [[ "$in_cloud_block" = false ]]; then
            if [[ "$line" =~ Payara[[:space:]]+Qube[[:space:]]*\(Managed\) ]]; then
                echo -e "${YELLOW}WARNING${NC}: ${file}:${line_num}"
                echo "  → Hard-coded product name outside conditional block"
                echo "  → Consider using: {productName}"
                echo "  → Line: ${line}"
                warning_count=$((warning_count + 1))
            fi
        fi
    done < "$file"
done < <(find docs/modules -name "*.adoc" -type f -print0)

echo ""

# Check for unclosed conditional blocks
echo "Checking for unclosed conditional blocks..."

while IFS= read -r -d '' file; do
    [[ "$file" == *"_attributes.adoc" ]] && continue

    # Count all conditional opening statements
    ifdef_count=$(grep -cE "^ifdef::" "$file" 2>/dev/null | head -1 || echo 0)
    ifndef_count=$(grep -cE "^ifndef::" "$file" 2>/dev/null | head -1 || echo 0)
    ifeval_count=$(grep -cE "^ifeval::" "$file" 2>/dev/null | head -1 || echo 0)
    endif_count=$(grep -cE "^endif::" "$file" 2>/dev/null | head -1 || echo 0)

    # Ensure counts are integers
    ifdef_count=${ifdef_count//[^0-9]/}
    ifndef_count=${ifndef_count//[^0-9]/}
    ifeval_count=${ifeval_count//[^0-9]/}
    endif_count=${endif_count//[^0-9]/}
    ifdef_count=${ifdef_count:-0}
    ifndef_count=${ifndef_count:-0}
    ifeval_count=${ifeval_count:-0}
    endif_count=${endif_count:-0}

    # Total conditional openings
    total_if=$((ifdef_count + ifndef_count + ifeval_count))

    if [[ "${total_if}" -ne "${endif_count}" ]]; then
        echo -e "${RED}ERROR${NC}: ${file}"
        echo "  → Mismatched conditional blocks"
        echo "  → ifdef: ${ifdef_count}, ifndef: ${ifndef_count}, ifeval: ${ifeval_count} (total: ${total_if})"
        echo "  → endif: ${endif_count}"
        error_count=$((error_count + 1))
    fi
done < <(find docs/modules -name "*.adoc" -type f -print0)

echo ""

# Final result
if [[ "${error_count}" -eq 0 ]] && [[ "${warning_count}" -eq 0 ]]; then
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Conditional content validation passed!${NC}"
    echo -e "${GREEN}========================================${NC}"
    exit 0
elif [[ "${error_count}" -eq 0 ]]; then
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}Conditional content validation passed with ${warning_count} warning(s)${NC}"
    echo -e "${YELLOW}========================================${NC}"
    exit 0
else
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}Conditional content validation failed${NC}"
    echo -e "${RED}Errors: ${error_count}, Warnings: ${warning_count}${NC}"
    echo -e "${RED}========================================${NC}"
    exit 1
fi
