#!/bin/bash
# I2C Framework — Installation Script
# Creates symlinks in ~/.claude/commands/ and registers the framework globally.
#
# Usage: ./install.sh
# Works from any installation directory — generates ~/.claude/i2c-orchestrator.md
# with the real framework path substituted automatically.

set -e

FRAMEWORK_DIR="$(cd "$(dirname "$0")" && pwd)"
COMMANDS_DIR="$HOME/.claude/commands"
GLOBAL_CLAUDE="$HOME/.claude/CLAUDE.md"
GENERATED="$HOME/.claude/i2c-orchestrator.md"
IMPORT_LINE="@$HOME/.claude/i2c-orchestrator.md"

echo "I2C Framework installer"
echo "Framework path: $FRAMEWORK_DIR"
echo ""

# 1. Create ~/.claude/commands/ if needed
mkdir -p "$COMMANDS_DIR"

# 2. Create symlinks for all i2c-*.md command files
echo "Creating command symlinks in $COMMANDS_DIR ..."
for f in "$FRAMEWORK_DIR/commands"/i2c-*.md; do
  filename="$(basename "$f")"
  target="$COMMANDS_DIR/$filename"
  ln -sf "$f" "$target"
  echo "  ✓ $filename"
done

# 3. Generate ~/.claude/i2c-orchestrator.md with real framework path
sed "s|~/i2c-agent-framework|${FRAMEWORK_DIR}|g" "$FRAMEWORK_DIR/CLAUDE.md" > "$GENERATED"
echo "Сгенерирован: ~/.claude/i2c-orchestrator.md"
echo "  Путь к фреймворку: $FRAMEWORK_DIR"

# 4. Register import in ~/.claude/CLAUDE.md
if [ ! -f "$GLOBAL_CLAUDE" ]; then
  echo "" > "$GLOBAL_CLAUDE"
fi

if grep -qF "$IMPORT_LINE" "$GLOBAL_CLAUDE"; then
  echo ""
  echo "Глобальный CLAUDE.md уже содержит импорт — пропускаю."
else
  echo "" >> "$GLOBAL_CLAUDE"
  echo "# I2C Framework" >> "$GLOBAL_CLAUDE"
  echo "$IMPORT_LINE" >> "$GLOBAL_CLAUDE"
  echo ""
  echo "Зарегистрирован импорт в ~/.claude/CLAUDE.md"
fi

echo ""
echo "✅ I2C Framework installed."
echo ""
echo "Available commands in Claude Code:"
echo "  /i2c-setup [/path/to/project]"
echo "  /i2c-create-prd"
echo "  /i2c-create-adr [название решения]"
echo "  /i2c-create-rfc [название компонента]"
echo "  /i2c-update-prd [описание изменений]"
echo "  /i2c-update-adr [N] [описание изменений]"
echo "  /i2c-code-rfc [N]"
echo "  /i2c-verify-rfc [N]"
echo "  /i2c-status"
echo "  /i2c-check"
echo "  /i2c-resume"
echo ""
echo "Start a new Claude Code session to activate."
