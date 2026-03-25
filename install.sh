#!/bin/bash
# I2C Framework — Installation Script
# Registers the framework globally for Claude Code or Qwen Code.
#
# Usage:
#   ./install.sh                  # Claude Code (default)
#   ./install.sh --target=claude  # Claude Code
#   ./install.sh --target=qwen    # Qwen Code

set -e

FRAMEWORK_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="claude"

# --- Parse arguments ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --target=claude)
      TARGET="claude"
      shift
      ;;
    --target=qwen)
      TARGET="qwen"
      shift
      ;;
    --target=*)
      echo "Ошибка: неизвестный target '${1#--target=}'. Допустимые значения: claude, qwen" >&2
      exit 1
      ;;
    *)
      echo "Ошибка: неизвестный аргумент '$1'" >&2
      echo "Использование: $0 [--target=claude|qwen]" >&2
      exit 1
      ;;
  esac
done

echo "I2C Framework installer"
echo "Framework path: $FRAMEWORK_DIR"
echo "Target: $TARGET"
echo ""

# ============================================================
# Target: Claude Code
# ============================================================
if [[ "$TARGET" == "claude" ]]; then
  COMMANDS_DIR="$HOME/.claude/commands"
  GLOBAL_MD="$HOME/.claude/CLAUDE.md"
  GENERATED="$HOME/.claude/i2c-orchestrator.md"
  IMPORT_LINE="@$HOME/.claude/i2c-orchestrator.md"

  # 1. Create ~/.claude/commands/ if needed
  mkdir -p "$COMMANDS_DIR"

  # 2. Create symlinks for all i2c-*.md command files
  echo "Creating command symlinks in $COMMANDS_DIR ..."
  for f in "$FRAMEWORK_DIR/commands"/i2c-*.md; do
    filename="$(basename "$f")"
    ln -sf "$f" "$COMMANDS_DIR/$filename"
    echo "  ✓ $filename"
  done

  # 3. Generate ~/.claude/i2c-orchestrator.md with real framework path
  sed "s|~/i2c-agent-framework|${FRAMEWORK_DIR}|g" "$FRAMEWORK_DIR/CLAUDE.md" > "$GENERATED"
  echo "Сгенерирован: ~/.claude/i2c-orchestrator.md"
  echo "  Путь к фреймворку: $FRAMEWORK_DIR"

  # 4. Register import in ~/.claude/CLAUDE.md
  if [ ! -f "$GLOBAL_MD" ]; then
    echo "" > "$GLOBAL_MD"
  fi

  if grep -qF "$IMPORT_LINE" "$GLOBAL_MD"; then
    echo ""
    echo "Глобальный CLAUDE.md уже содержит импорт — пропускаю."
  else
    echo "" >> "$GLOBAL_MD"
    echo "# I2C Framework" >> "$GLOBAL_MD"
    echo "$IMPORT_LINE" >> "$GLOBAL_MD"
    echo ""
    echo "Зарегистрирован импорт в ~/.claude/CLAUDE.md"
  fi

  echo ""
  echo "✅ I2C Framework installed (Claude Code)."
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

# ============================================================
# Target: Qwen Code
# ============================================================
elif [[ "$TARGET" == "qwen" ]]; then
  COMMANDS_DIR="$HOME/.qwen/commands"
  GLOBAL_MD="$HOME/.qwen/QWEN.md"
  GENERATED="$HOME/.qwen/i2c-orchestrator.md"
  IMPORT_LINE="@$HOME/.qwen/i2c-orchestrator.md"

  # 1. Create ~/.qwen/commands/ if needed
  mkdir -p "$COMMANDS_DIR"

  # 2. Copy all i2c-*.md command files (physical copies, not symlinks)
  echo "Копирование команд в $COMMANDS_DIR ..."
  for f in "$FRAMEWORK_DIR/commands"/i2c-*.md; do
    filename="$(basename "$f")"
    cp "$f" "$COMMANDS_DIR/$filename"
    echo "  ✓ $filename"
  done

  # 3. Generate ~/.qwen/i2c-orchestrator.md with real framework path
  sed "s|~/i2c-agent-framework|${FRAMEWORK_DIR}|g" "$FRAMEWORK_DIR/QWEN.md" > "$GENERATED"
  echo "Сгенерирован: ~/.qwen/i2c-orchestrator.md"
  echo "  Путь к фреймворку: $FRAMEWORK_DIR"

  # 4. Register import in ~/.qwen/QWEN.md
  if [ ! -f "$GLOBAL_MD" ]; then
    echo "" > "$GLOBAL_MD"
  fi

  if grep -qF "$IMPORT_LINE" "$GLOBAL_MD"; then
    echo ""
    echo "Глобальный QWEN.md уже содержит импорт — пропускаю."
  else
    echo "" >> "$GLOBAL_MD"
    echo "# I2C Framework" >> "$GLOBAL_MD"
    echo "$IMPORT_LINE" >> "$GLOBAL_MD"
    echo ""
    echo "Зарегистрирован импорт в ~/.qwen/QWEN.md"
  fi

  echo ""
  echo "✅ I2C Framework installed (Qwen Code)."
  echo ""
  echo "Available commands in Qwen Code:"
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
  echo "Start a new Qwen Code session to activate."
  echo "Обновление после git pull: ./install.sh --target=qwen"
fi
