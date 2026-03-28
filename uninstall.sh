#!/bin/bash
# I2C Framework — Uninstall Script
# Removes I2C framework from a project and/or cleans up old global installation.
#
# Usage:
#   ./uninstall.sh /path/to/project                  # Remove from project (Claude, default)
#   ./uninstall.sh --target=qwen /path/to/project     # Remove from project (Qwen)
#   ./uninstall.sh                                     # Cleanup old global installation only

set -e

FRAMEWORK_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="claude"
PROJECT_DIR=""

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
      if [[ -z "$PROJECT_DIR" ]]; then
        PROJECT_DIR="$1"
      else
        echo "Ошибка: лишний аргумент '$1'" >&2
        exit 1
      fi
      shift
      ;;
  esac
done

echo "I2C Framework uninstaller"
echo ""

# --- Determine target-specific paths ---
if [[ "$TARGET" == "claude" ]]; then
  TARGET_DIR=".claude"
elif [[ "$TARGET" == "qwen" ]]; then
  TARGET_DIR=".qwen"
fi

# ============================================================
# Project-level uninstall
# ============================================================
if [[ -n "$PROJECT_DIR" ]]; then
  PROJECT_DIR="$(cd "$PROJECT_DIR" 2>/dev/null && pwd)" || {
    echo "Ошибка: директория '$PROJECT_DIR' не существует." >&2
    exit 1
  }

  echo "Removing I2C framework from $PROJECT_DIR ..."

  # Remove embedded framework
  if [[ -d "$PROJECT_DIR/.i2c/framework" ]]; then
    rm -rf "$PROJECT_DIR/.i2c/framework"
    echo "  ✓ Removed .i2c/framework/"
  fi

  # Remove commands
  for f in "$PROJECT_DIR/$TARGET_DIR/commands"/i2c-*.md; do
    if [[ -f "$f" ]]; then
      rm "$f"
      echo "  ✓ Removed $TARGET_DIR/commands/$(basename "$f")"
    fi
  done

  echo ""
  echo "Note: .i2c/ state files (config.md, MEMORY.md, etc.) are preserved."
  echo "To remove everything: rm -rf $PROJECT_DIR/.i2c/"
fi

# ============================================================
# Global cleanup (legacy)
# ============================================================
GLOBAL_DIR="$HOME/$TARGET_DIR"
GLOBAL_MD="$GLOBAL_DIR/$([ "$TARGET" == "claude" ] && echo "CLAUDE.md" || echo "QWEN.md")"

echo "Checking for old global installation to clean up ..."

CLEANED=false

# Remove old orchestrator from global dir
if [[ -f "$GLOBAL_DIR/i2c-orchestrator.md" ]]; then
  rm "$GLOBAL_DIR/i2c-orchestrator.md"
  echo "  ✓ Removed $GLOBAL_DIR/i2c-orchestrator.md"
  CLEANED=true
fi

# Remove old i2c-* commands from global commands dir
if [[ -d "$GLOBAL_DIR/commands" ]]; then
  for f in "$GLOBAL_DIR/commands"/i2c-*.md; do
    if [[ -f "$f" ]]; then
      rm "$f"
      echo "  ✓ Removed global command: $(basename "$f")"
      CLEANED=true
    fi
  done
fi

# Remove framework import from global MD
if [[ -f "$GLOBAL_MD" ]]; then
  if grep -q "i2c" "$GLOBAL_MD" 2>/dev/null; then
    tmpfile=$(mktemp)
    awk '
      /^# I2C Framework/ {
        if ((getline nextline) > 0) {
          if (nextline ~ /i2c-orchestrator|i2c-agent-framework/) {
            next
          } else {
            print
            print nextline
          }
        }
        next
      }
      /i2c-orchestrator|i2c-agent-framework/ { next }
      { print }
    ' "$GLOBAL_MD" > "$tmpfile"
    sed -i '' -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$tmpfile" 2>/dev/null || true
    mv "$tmpfile" "$GLOBAL_MD"
    echo "  ✓ Cleaned I2C entries from $GLOBAL_MD"
    CLEANED=true
  fi
fi

if [[ "$CLEANED" == "false" ]]; then
  echo "  (no old installation found)"
fi

echo ""
echo "✅ I2C Framework uninstalled."
