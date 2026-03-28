#!/bin/bash
# gstack-openclaw installer — one command, non-destructive
# Usage: curl -fsSL https://raw.githubusercontent.com/ashish797/YC-World/main/install.sh | bash
# Or: bash install.sh

set -e

SKILLS_DIR="${HOME}/.agents/skills"
GSTACK_DIR="${SKILLS_DIR}/gstack-openclaw"
REPO_URL="https://github.com/ashish797/YC-World.git"

echo "=== gstack-openclaw installer ==="
echo ""

# Check if already installed
if [ -d "$GSTACK_DIR" ]; then
    echo "gstack-openclaw already installed at $GSTACK_DIR"
    echo "Updating..."
    cd "$GSTACK_DIR" && git pull --quiet
    echo "Updated to latest."
else
    echo "Cloning to $GSTACK_DIR..."
    git clone --single-branch --depth 1 "$REPO_URL" "$GSTACK_DIR"
fi

# Create skills directory if it doesn't exist
mkdir -p "$SKILLS_DIR"

# Symlink each skill (skip if already exists — non-destructive)
echo ""
echo "Installing skills..."
INSTALLED=0
SKIPPED=0

for skill_dir in "$GSTACK_DIR"/*/; do
    skill_name=$(basename "$skill_dir")
    
    # Skip non-skill directories
    [ ! -f "$skill_dir/SKILL.md" ] && continue
    
    target="$SKILLS_DIR/$skill_name"
    
    if [ -e "$target" ] || [ -L "$target" ]; then
        # Check if it's already our symlink
        if [ -L "$target" ] && [ "$(readlink "$target")" = "$skill_dir" ]; then
            echo "  ✓ $skill_name (already linked)"
        else
            echo "  ⚠ $skill_name (exists, skipping — not overwriting)"
            SKIPPED=$((SKIPPED + 1))
        fi
    else
        ln -sf "$skill_dir" "$target"
        echo "  ✓ $skill_name"
        INSTALLED=$((INSTALLED + 1))
    fi
done

# Add proactive rules to AGENTS.md if not already there
WORKSPACE="${HOME}/.openclaw/workspace"
AGENTS_MD="${WORKSPACE}/AGENTS.md"
GSTACK_PROACTIVE="$GSTACK_DIR/GSTACK-PROACTIVE.md"

if [ -f "$AGENTS_MD" ] && ! grep -q "GSTACK-PROACTIVE" "$AGENTS_MD" 2>/dev/null; then
    echo "" >> "$AGENTS_MD"
    echo "# GStack Skills" >> "$AGENTS_MD"
    echo "" >> "$AGENTS_MD"
    echo "gstack-openclaw is installed. Read \$GSTACK_PROACTIVE for skill suggestions and proactive behavior rules." >> "$AGENTS_MD"
    echo "  ✓ Added proactive rules reference to AGENTS.md"
elif [ ! -f "$AGENTS_MD" ]; then
    echo "# AGENTS.md" > "$AGENTS_MD"
    echo "" >> "$AGENTS_MD"
    echo "gstack-openclaw is installed. Read $GSTACK_PROACTIVE for skill suggestions and proactive behavior rules." >> "$AGENTS_MD"
    echo "  ✓ Created AGENTS.md with proactive rules"
else
    echo "  ✓ AGENTS.md already has gstack reference"
fi

# Copy YC World workspace template
WORKSPACE_DIR="${HOME}/.openclaw/ycworld"
if [ ! -d "$WORKSPACE_DIR" ]; then
    echo ""
    echo "Creating YC World workspace..."
    cp -r "$GSTACK_DIR/workspace-template" "$WORKSPACE_DIR"
    echo "  ✓ YC World workspace created at $WORKSPACE_DIR"
    echo "  ✓ CEO + 5 departments + company config"
else
    echo "  ✓ YC World workspace already exists"
fi

# Build browse binary if bun is available
BROWSE_BIN="$GSTACK_DIR/browse/dist/browse"
if [ ! -x "$BROWSE_BIN" ] && command -v bun >/dev/null 2>&1; then
    echo ""
    echo "Building browse binary (headless browser)..."
    cd "$GSTACK_DIR/browse"
    bun install --silent 2>/dev/null
    bun build src/cli.ts --compile --outfile dist/browse 2>/dev/null
    if [ -x "$BROWSE_BIN" ]; then
        echo "  ✓ browse binary built successfully"
    else
        echo "  ⚠ browse binary build failed — run manually: cd $GSTACK_DIR/browse && bun install && bun build src/cli.ts --compile --outfile dist/browse"
    fi
    cd - > /dev/null
elif [ -x "$BROWSE_BIN" ]; then
    echo "  ✓ browse binary already built"
fi

echo ""
echo "=== Done ==="
echo "  Installed: $INSTALLED new skills"
echo "  Skipped:   $SKIPPED (already existed)"
echo "  Total:     $(ls -d "$SKILLS_DIR"/*/ 2>/dev/null | wc -l) skills in $SKILLS_DIR"
echo ""
echo "Skills are active immediately — no restart needed."
echo "To uninstall: rm -rf $GSTACK_DIR && find $SKILLS_DIR -type l -lname '$GSTACK_DIR/*' -delete"
