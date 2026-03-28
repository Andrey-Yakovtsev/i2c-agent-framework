#!/bin/bash
# I2C Framework — Project Installation Script
# Installs the framework into a specific project directory.
# Framework is fully embedded into the project — no external dependencies.
#
# Usage:
#   ./install.sh /path/to/project                  # Claude Code (default)
#   ./install.sh --target=claude /path/to/project   # Claude Code
#   ./install.sh --target=qwen /path/to/project     # Qwen Code

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
    -*)
      echo "Ошибка: неизвестный флаг '$1'" >&2
      echo "Использование: $0 [--target=claude|qwen] /path/to/project" >&2
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

# --- Validate project path ---
if [[ -z "$PROJECT_DIR" ]]; then
  echo "Ошибка: укажи путь к проекту." >&2
  echo "Использование: $0 [--target=claude|qwen] /path/to/project" >&2
  exit 1
fi

# Resolve to absolute path
PROJECT_DIR="$(cd "$PROJECT_DIR" 2>/dev/null && pwd)" || {
  echo "Ошибка: директория '$1' не существует." >&2
  exit 1
}

# --- Determine target-specific paths ---
if [[ "$TARGET" == "claude" ]]; then
  TARGET_DIR=".claude"
  GLOBAL_DIR="$HOME/.claude"
  GLOBAL_MD="$GLOBAL_DIR/CLAUDE.md"
elif [[ "$TARGET" == "qwen" ]]; then
  TARGET_DIR=".qwen"
  GLOBAL_DIR="$HOME/.qwen"
  GLOBAL_MD="$GLOBAL_DIR/QWEN.md"
fi

echo "I2C Framework installer"
echo "  Framework: $FRAMEWORK_DIR"
echo "  Project:   $PROJECT_DIR"
echo "  Target:    $TARGET"
echo ""

# ============================================================
# Step 1: Embed framework into project (.i2c/framework/)
# ============================================================
I2C_DIR="$PROJECT_DIR/.i2c"
FRAMEWORK_DEST="$I2C_DIR/framework"

echo "Embedding framework into .i2c/framework/ ..."
rm -rf "$FRAMEWORK_DEST"
mkdir -p "$FRAMEWORK_DEST"

# Copy framework components
cp -r "$FRAMEWORK_DIR/agents"      "$FRAMEWORK_DEST/agents"
cp -r "$FRAMEWORK_DIR/protocols"   "$FRAMEWORK_DEST/protocols"
cp -r "$FRAMEWORK_DIR/templates"   "$FRAMEWORK_DEST/templates"
cp -r "$FRAMEWORK_DIR/diagnostics" "$FRAMEWORK_DEST/diagnostics"

# Generate orchestrator with project-relative paths
sed "s|~/i2c-agent-framework|.i2c/framework|g" \
  "$FRAMEWORK_DIR/orchestrator-source.md" > "$FRAMEWORK_DEST/orchestrator.md"

# For QWEN: also embed the full QWEN orchestrator
if [[ "$TARGET" == "qwen" ]]; then
  sed "s|~/i2c-agent-framework|.i2c/framework|g" \
    "$FRAMEWORK_DIR/QWEN.md" > "$FRAMEWORK_DEST/QWEN.md"
fi

# Replace all external path references in copied files
find "$FRAMEWORK_DEST" -name "*.md" -exec sed -i '' "s|~/i2c-agent-framework|.i2c/framework|g" {} +

# Write meta-information for framework-update command
echo "$FRAMEWORK_DIR" > "$FRAMEWORK_DEST/.source"
(cd "$FRAMEWORK_DIR" && git rev-parse --short HEAD 2>/dev/null || echo "unknown") > "$FRAMEWORK_DEST/VERSION"

echo "  ✓ agents/ protocols/ templates/ diagnostics/ orchestrator.md"
echo "  ✓ VERSION: $(cat "$FRAMEWORK_DEST/VERSION")"

# ============================================================
# Step 2: Create .i2c/ skeleton in project (if not exists)
# ============================================================
if [[ ! -f "$I2C_DIR/config.md" ]]; then
  echo ""
  echo "Creating .i2c/ skeleton ..."
  mkdir -p "$I2C_DIR/scratch"

  # Copy templates
  cp "$FRAMEWORK_DIR/templates/MEMORY.md" "$I2C_DIR/MEMORY.md"
  cp "$FRAMEWORK_DIR/templates/GOALS.md" "$I2C_DIR/GOALS.md"
  cp "$FRAMEWORK_DIR/templates/JOURNAL.md" "$I2C_DIR/JOURNAL.md"

  # Create empty config and pipeline state
  cat > "$I2C_DIR/config.md" << 'CONFIGEOF'
# Project Config

> Заполняется при `/i2c-setup`. Все поля обязательны.

| Поле | Значение |
|------|---------|
| Название проекта | — |
| Домен | — |
| Цель | — |
| Целевой пользователь | — |
| Стек / ограничения | — |
| MVP | — |
CONFIGEOF

  echo '{}' > "$I2C_DIR/pipeline_state.json"

  echo "  ✓ .i2c/ created with templates"
else
  echo ".i2c/ state already exists — preserving."
fi

# ============================================================
# Step 3: Generate commands in project
# ============================================================
COMMANDS_DIR="$PROJECT_DIR/$TARGET_DIR/commands"
mkdir -p "$COMMANDS_DIR"

echo ""
echo "Generating commands in $PROJECT_DIR/$TARGET_DIR/commands/ ..."
for f in "$FRAMEWORK_DIR/commands"/i2c-*.md; do
  filename="$(basename "$f")"
  sed "s|{{FRAMEWORK_DIR}}|.i2c/framework|g" "$f" > "$COMMANDS_DIR/$filename"
  echo "  ✓ $filename"
done

# ============================================================
# Step 4: Copy claude-settings.json (Claude only)
# ============================================================
if [[ "$TARGET" == "claude" ]]; then
  SETTINGS_FILE="$PROJECT_DIR/$TARGET_DIR/settings.json"
  if [[ ! -f "$SETTINGS_FILE" ]]; then
    cp "$FRAMEWORK_DIR/templates/claude-settings.json" "$SETTINGS_FILE"
    echo "  ✓ .claude/settings.json"
  fi
fi

# ============================================================
# Step 4b: Update project QWEN.md reference (Qwen only)
# ============================================================
if [[ "$TARGET" == "qwen" ]]; then
  PROJECT_QWEN="$PROJECT_DIR/QWEN.md"
  if [[ -f "$PROJECT_QWEN" ]]; then
    if grep -q "@.*i2c-agent-framework" "$PROJECT_QWEN"; then
      sed -i '' "s|@.*i2c-agent-framework/QWEN.md|@.i2c/framework/QWEN.md|g" "$PROJECT_QWEN"
      echo "  ✓ Updated QWEN.md reference → @.i2c/framework/QWEN.md"
    elif ! grep -q "@.i2c/framework/QWEN.md" "$PROJECT_QWEN"; then
      echo "" >> "$PROJECT_QWEN"
      echo "@.i2c/framework/QWEN.md" >> "$PROJECT_QWEN"
      echo "  ✓ Added @.i2c/framework/QWEN.md to QWEN.md"
    fi
  else
    printf "# Project Instructions\n\n@.i2c/framework/QWEN.md\n" > "$PROJECT_QWEN"
    echo "  ✓ Created QWEN.md with @.i2c/framework/QWEN.md"
  fi
fi

# ============================================================
# Step 5: Migration — cleanup old global installation
# ============================================================
echo ""
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

# Remove I2C entries from global CLAUDE.md / QWEN.md
if [[ -f "$GLOBAL_MD" ]]; then
  if grep -q "i2c" "$GLOBAL_MD" 2>/dev/null; then
    # Remove lines containing i2c-orchestrator or i2c-agent-framework references
    # Also remove "# I2C Framework" headers that precede them
    tmpfile=$(mktemp)
    awk '
      /^# I2C Framework/ {
        # Read next line to check if it is an i2c reference
        if ((getline nextline) > 0) {
          if (nextline ~ /i2c-orchestrator|i2c-agent-framework/) {
            # Skip both lines (header + reference)
            next
          } else {
            # Print both lines — not i2c related
            print
            print nextline
          }
        }
        next
      }
      /i2c-orchestrator|i2c-agent-framework/ { next }
      { print }
    ' "$GLOBAL_MD" > "$tmpfile"
    # Remove trailing empty lines
    sed -i '' -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$tmpfile" 2>/dev/null || true
    mv "$tmpfile" "$GLOBAL_MD"
    echo "  ✓ Cleaned I2C entries from $GLOBAL_MD"
    CLEANED=true
  fi
fi

if [[ "$CLEANED" == "false" ]]; then
  echo "  (no old installation found)"
fi

# ============================================================
# Done
# ============================================================
echo ""
echo "✅ I2C Framework installed in $PROJECT_DIR (target: $TARGET)."
echo "   Framework embedded in .i2c/framework/ — no external dependencies."
echo ""
echo "Next steps:"
echo "  1. Open $TARGET in your project directory"
echo "  2. Run /i2c-setup to configure the project interactively"
echo ""
echo "Available commands:"
echo "  /i2c-setup                     — configure project"
echo "  /i2c-create-prd                — create PRD"
echo "  /i2c-create-adr [name]         — create ADR"
echo "  /i2c-create-rfc [name]         — create RFC"
echo "  /i2c-update-prd [changes]      — update PRD"
echo "  /i2c-update-adr [N] [changes]  — update ADR"
echo "  /i2c-code-rfc [N]              — implement RFC"
echo "  /i2c-verify-rfc [N]            — verify implementation"
echo "  /i2c-patch-rfc [N]             — patch after RFC change"
echo "  /i2c-status                    — show project status"
echo "  /i2c-check                     — consistency check"
echo "  /i2c-resume                    — resume pipeline"
echo "  /i2c-framework-update          — update framework"
