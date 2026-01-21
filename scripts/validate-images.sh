#!/usr/bin/env bash
set -e

# Validate image references and asset files

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

error_count=0
warning_count=0

echo "Validating image references..."
echo ""

echo "Checking image:: references..."

while IFS= read -r -d '' file; do
    # Extract image references
    # Matches: image::path/to/image.png[] or image:path/to/image.png[]
    grep -oP 'image::?[^\[]+' "$file" 2>/dev/null | while read -r img_line; do
        # Remove 'image::' or 'image:' prefix
        img_path="${img_line#image::}"
        img_path="${img_path#image:}"

        # Determine which module this file is in
        if [[ "$file" =~ docs/modules/([^/]+)/ ]]; then
            current_module="${BASH_REMATCH[1]}"
            target_module="$current_module"

            # Parse Antora image reference formats:
            # 1. docs:ROOT:path/to/image.png (component:module:path)
            # 2. ROOT:path/to/image.png (module:path)
            # 3. path/to/image.png (simple path)

            if [[ "$img_path" =~ ^[^:]+:[^:]+:(.+)$ ]]; then
                # Format: component:module:path (e.g., docs:ROOT:qube/img.png)
                # Extract module and path
                if [[ "$img_path" =~ ^[^:]+:([^:]+):(.+)$ ]]; then
                    target_module="${BASH_REMATCH[1]}"
                    img_path="${BASH_REMATCH[2]}"
                fi
            elif [[ "$img_path" =~ ^([^:]+):(.+)$ ]]; then
                # Format: module:path (e.g., ROOT:qube/img.png)
                target_module="${BASH_REMATCH[1]}"
                img_path="${BASH_REMATCH[2]}"
            fi
            # else: simple path format, use as-is

            assets_dir="docs/modules/${target_module}/assets"

            # Check if image exists in target module's assets
            if [[ ! -f "${assets_dir}/${img_path}" ]]; then
                # Also check images/ subdirectory (common pattern)
                if [[ ! -f "${assets_dir}/images/${img_path}" ]]; then
                    echo -e "${RED}ERROR${NC}: ${file}"
                    echo "  → References missing image: ${img_path}"
                    echo "  → Expected at: ${assets_dir}/${img_path}"
                    echo "  →           or: ${assets_dir}/images/${img_path}"
                    error_count=$((error_count + 1))
                fi
            fi
        fi
    done
done < <(find docs/modules -name "*.adoc" -type f -print0)

if [[ $error_count -eq 0 ]]; then
    echo -e "${GREEN}✓ All image references are valid${NC}"
fi
echo ""

# Check for unused images (optional - warning only)
echo "Checking for unused assets..."

unused_count=0
for module_dir in docs/modules/*; do
    [[ -d "$module_dir" ]] || continue

    module=$(basename "$module_dir")
    assets_dir="$module_dir/assets"

    [[ -d "$assets_dir" ]] || continue

    # Find all image files
    while IFS= read -r -d '' img_file; do
        # Get relative path from assets dir
        rel_path="${img_file#${assets_dir}/}"

        # Get just the filename for flexible searching
        filename=$(basename "$img_file")

        # Try multiple search patterns to account for different reference formats
        found=false

        # 1. Search for exact relative path (e.g., "images/path/to/img.png")
        if grep -rq "image::.*${rel_path}\|image:.*${rel_path}" "${module_dir}/pages" 2>/dev/null; then
            found=true
        fi

        # 2. If in images/ subdirectory, check without that prefix
        # (e.g., "path/to/img.png" for Antora cross-references like "docs:ROOT:path/to/img.png")
        if [[ "$found" = false ]] && [[ "$rel_path" == images/* ]]; then
            path_without_images="${rel_path#images/}"
            if grep -rq "image::.*${path_without_images}\|image:.*${path_without_images}" "${module_dir}/pages" 2>/dev/null; then
                found=true
            fi
        fi

        # 3. Fallback: search for just the filename (catches any reference format)
        if [[ "$found" = false ]]; then
            if grep -rq "image::.*${filename}\|image:.*${filename}" "${module_dir}/pages" 2>/dev/null; then
                found=true
            fi
        fi

        if [[ "$found" = false ]]; then
            echo -e "${YELLOW}WARNING${NC}: Unused asset: ${module}/${rel_path}"
            unused_count=$((unused_count + 1))
        fi
    done < <(find "$assets_dir" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.gif" -o -name "*.svg" \) -print0 2>/dev/null || true)
done

if [[ "${unused_count}" -eq 0 ]]; then
    echo -e "${GREEN}✓ No unused assets found${NC}"
else
    echo -e "${YELLOW}ℹ Found ${unused_count} potentially unused asset(s)${NC}"
    warning_count=$((warning_count + unused_count))
fi
echo ""

# Final result
if [[ "${error_count}" -eq 0 ]] && [[ "${warning_count}" -eq 0 ]]; then
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Image validation passed!${NC}"
    echo -e "${GREEN}========================================${NC}"
    exit 0
elif [[ "${error_count}" -eq 0 ]]; then
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}Image validation passed with ${warning_count} warning(s)${NC}"
    echo -e "${YELLOW}========================================${NC}"
    exit 0
else
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}Image validation failed${NC}"
    echo -e "${RED}Errors: ${error_count}, Warnings: ${warning_count}${NC}"
    echo -e "${RED}========================================${NC}"
    exit 1
fi
