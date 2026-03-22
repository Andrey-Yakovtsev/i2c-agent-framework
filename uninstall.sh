#!/bin/bash
# I2C Framework — Uninstall Script
# Removes symlinks from ~/.claude/commands/ and cleans up global CLAUDE.md import.

set -e

FRAMEWORK_DIR="$(cd "$(dirname "$0")" && pwd)"
COMMANDS_DIR="$HOME/.claude/commands"
GLOBAL_CLAUDE="$HOME/.claude/CLAUDE.md"

echo "I2C Framework uninstaller"
echo ""

# 1. Remove symlinks
if [ -d "$COMMANDS_DIR" ]; then
  echo "Removing command symlinks from $COMMANDS_DIR ..."
  for f in "$COMMANDS_DIR"/i2c-*.md; do
    [ -L "$f" ] && rm "$f" && echo "  ✓ removed $(basename "$f")"
  done
else
  echo "No commands directory found — skipping."
fi

# 2. Remove generated orchestrator
rm -f "$HOME/.claude/i2c-orchestrator.md"
echo "Удалён ~/.claude/i2c-orchestrator.md"

# 3. Remove framework import from ~/.claude/CLAUDE.md
if [ -f "$GLOBAL_CLAUDE" ]; then
  sed -i '' '/^# I2C Framework$/d' "$GLOBAL_CLAUDE"
  sed -i '' '\|@.*i2c-orchestrator\.md|d' "$GLOBAL_CLAUDE"
  echo "Removed framework import from $GLOBAL_CLAUDE"
fi

echo ""
echo "✅ I2C Framework uninstalled."
