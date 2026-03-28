#!/bin/bash
# gstack-openclaw uninstaller
# Usage: bash uninstall.sh

set -e

SKILLS_DIR="${HOME}/.agents/skills"
GSTACK_DIR="${SKILLS_DIR}/gstack-openclaw"

echo "=== gstack-openclaw uninstaller ==="
echo ""

if [ ! -d "$GSTACK_DIR" ]; then
    echo "gstack-openclaw is not installed."
    exit 0
fi

# Remove symlinks pointing to gstack-openclaw
REMOVED=0
for link in "$SKILLS_DIR"/*; do
    [ -L "$link" ] || continue
    target=$(readlink "$link")
    case "$target" in
        "$GSTACK_DIR"*)
            skill_name=$(basename "$link")
            rm "$link"
            echo "  ✗ $skill_name"
            REMOVED=$((REMOVED + 1))
            ;;
    esac
done

# Remove the repo
rm -rf "$GSTACK_DIR"

echo ""
echo "=== Done ==="
echo "  Removed: $REMOVED skills"
echo "  Deleted: $GSTACK_DIR"
