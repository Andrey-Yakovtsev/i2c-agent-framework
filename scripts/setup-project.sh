#!/usr/bin/env bash
# setup-project.sh — инициализация проекта для I2C Framework
#
# Использование:
#   ./scripts/setup-project.sh /path/to/project                  # --target=claude по умолчанию
#   ./scripts/setup-project.sh --target=claude /path/to/project
#   ./scripts/setup-project.sh --target=qwen   /path/to/project

set -euo pipefail

FRAMEWORK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="claude"
PROJECT_DIR=""

# --- Разбор аргументов ---
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

if [[ -z "$PROJECT_DIR" ]]; then
  echo "Использование: $0 [--target=claude|qwen] /path/to/project" >&2
  exit 1
fi

PROJECT_DIR="$(realpath "$PROJECT_DIR")"

if [[ ! -d "$PROJECT_DIR" ]]; then
  echo "Ошибка: директория '$PROJECT_DIR' не существует" >&2
  exit 1
fi

echo "Инициализация I2C Framework"
echo "  Проект:  $PROJECT_DIR"
echo "  Target:  $TARGET"
echo "  Framework: $FRAMEWORK_DIR"
echo ""

# --- Создание структуры .i2c/ ---
I2C_DIR="$PROJECT_DIR/.i2c"
mkdir -p "$I2C_DIR/scratch"

# pipeline_state.json
if [[ ! -f "$I2C_DIR/pipeline_state.json" ]]; then
  echo '{}' > "$I2C_DIR/pipeline_state.json"
  echo "Создан:  .i2c/pipeline_state.json"
fi

# MEMORY.md из шаблона
if [[ ! -f "$I2C_DIR/MEMORY.md" ]]; then
  cp "$FRAMEWORK_DIR/templates/MEMORY.md" "$I2C_DIR/MEMORY.md"
  echo "Создан:  .i2c/MEMORY.md"
fi

# GOALS.md
if [[ ! -f "$I2C_DIR/GOALS.md" ]]; then
  cat > "$I2C_DIR/GOALS.md" << 'EOF'
# Project Goals

## Текущая стадия
Stage 0 — Инициализация

## Следующий шаг
Запустить `/i2c-create-prd`
EOF
  echo "Создан:  .i2c/GOALS.md"
fi

# JOURNAL.md
if [[ ! -f "$I2C_DIR/JOURNAL.md" ]]; then
  TODAY="$(date '+%Y-%m-%d')"
  cat > "$I2C_DIR/JOURNAL.md" << EOF
# Project Journal

## $TODAY Проект настроен (/i2c-setup, скрипт setup-project.sh)
- Конфигурация: .i2c/config.md
- Target: $TARGET
- Следующий шаг: /i2c-create-prd
EOF
  echo "Создан:  .i2c/JOURNAL.md"
fi

# config.md — базовый, если отсутствует
if [[ ! -f "$I2C_DIR/config.md" ]]; then
  cat > "$I2C_DIR/config.md" << 'EOF'
# Project Config

## Название проекта
[заполнить]

## Домен / индустрия
[заполнить]

## Цель проекта (одно предложение)
[заполнить]

## Целевой пользователь
[заполнить]

## Технические ограничения (стек, платформа, compliance)
[заполнить]

## Временные рамки MVP
[заполнить]
EOF
  echo "Создан:  .i2c/config.md  ← заполни вручную или через /i2c-setup"
fi

# --- Target: claude ---
if [[ "$TARGET" == "claude" ]]; then
  # Создаём/обновляем CLAUDE.md в проекте
  CLAUDE_MD="$PROJECT_DIR/CLAUDE.md"
  IMPORT_LINE="@~/.claude/i2c-orchestrator.md"

  if [[ -f "$CLAUDE_MD" ]]; then
    if grep -qF "$IMPORT_LINE" "$CLAUDE_MD"; then
      echo "Пропущен: CLAUDE.md уже содержит импорт фреймворка"
    else
      echo "" >> "$CLAUDE_MD"
      echo "$IMPORT_LINE" >> "$CLAUDE_MD"
      echo "Обновлён: CLAUDE.md (добавлен импорт фреймворка)"
    fi
  else
    cat > "$CLAUDE_MD" << EOF
# Project Instructions

$IMPORT_LINE
EOF
    echo "Создан:  CLAUDE.md"
  fi

  # Копируем команды в ~/.claude/commands/
  CLAUDE_COMMANDS_DIR="$HOME/.claude/commands"
  mkdir -p "$CLAUDE_COMMANDS_DIR"
  for cmd_file in "$FRAMEWORK_DIR/commands"/i2c-*.md; do
    [[ -f "$cmd_file" ]] || continue
    cp "$cmd_file" "$CLAUDE_COMMANDS_DIR/"
  done
  echo "Скопированы: commands/i2c-*.md → ~/.claude/commands/"

# --- Target: qwen ---
elif [[ "$TARGET" == "qwen" ]]; then
  # Создаём/обновляем QWEN.md в проекте (sed-генерация с реальным путём)
  QWEN_MD="$PROJECT_DIR/QWEN.md"
  sed "s|~/i2c-agent-framework|${FRAMEWORK_DIR}|g" "$FRAMEWORK_DIR/QWEN.md" > "$QWEN_MD"
  echo "Сгенерирован: QWEN.md (путь к фреймворку: $FRAMEWORK_DIR)"

  # Копируем агентов в .qwen/agents/
  QWEN_AGENTS_DIR="$PROJECT_DIR/.qwen/agents"
  mkdir -p "$QWEN_AGENTS_DIR"
  for agent_file in "$FRAMEWORK_DIR/agents"/*.md; do
    [[ -f "$agent_file" ]] || continue
    cp "$agent_file" "$QWEN_AGENTS_DIR/"
  done
  echo "Скопированы: agents/*.md → .qwen/agents/"

  # Копируем команды в .qwen/commands/
  QWEN_COMMANDS_DIR="$PROJECT_DIR/.qwen/commands"
  mkdir -p "$QWEN_COMMANDS_DIR"
  for cmd_file in "$FRAMEWORK_DIR/commands"/i2c-*.md; do
    [[ -f "$cmd_file" ]] || continue
    cp "$cmd_file" "$QWEN_COMMANDS_DIR/"
  done
  echo "Скопированы: commands/i2c-*.md → .qwen/commands/"

  # Глобальная регистрация: копируем команды в ~/.qwen/commands/
  QWEN_GLOBAL_COMMANDS="$HOME/.qwen/commands"
  mkdir -p "$QWEN_GLOBAL_COMMANDS"
  for cmd_file in "$FRAMEWORK_DIR/commands"/i2c-*.md; do
    [[ -f "$cmd_file" ]] || continue
    cp "$cmd_file" "$QWEN_GLOBAL_COMMANDS/"
  done
  echo "Скопированы: commands/i2c-*.md → ~/.qwen/commands/"

  # Глобальная регистрация: генерируем ~/.qwen/i2c-orchestrator.md
  QWEN_GLOBAL_GENERATED="$HOME/.qwen/i2c-orchestrator.md"
  sed "s|~/i2c-agent-framework|${FRAMEWORK_DIR}|g" "$FRAMEWORK_DIR/QWEN.md" > "$QWEN_GLOBAL_GENERATED"
  echo "Сгенерирован: ~/.qwen/i2c-orchestrator.md"

  # Глобальная регистрация: добавляем импорт в ~/.qwen/QWEN.md
  QWEN_GLOBAL_MD="$HOME/.qwen/QWEN.md"
  QWEN_IMPORT_LINE="@$HOME/.qwen/i2c-orchestrator.md"
  if [[ ! -f "$QWEN_GLOBAL_MD" ]]; then
    echo "" > "$QWEN_GLOBAL_MD"
  fi
  if grep -qF "$QWEN_IMPORT_LINE" "$QWEN_GLOBAL_MD"; then
    echo "Глобальный ~/.qwen/QWEN.md уже содержит импорт — пропускаю."
  else
    echo "" >> "$QWEN_GLOBAL_MD"
    echo "# I2C Framework" >> "$QWEN_GLOBAL_MD"
    echo "$QWEN_IMPORT_LINE" >> "$QWEN_GLOBAL_MD"
    echo "Зарегистрирован импорт в ~/.qwen/QWEN.md"
  fi
fi

echo ""
echo "✅ I2C Framework инициализирован в $PROJECT_DIR"
echo ""
echo "Создано:"
echo "  .i2c/config.md           — конфигурация проекта"
echo "  .i2c/MEMORY.md           — реестр принятых решений"
echo "  .i2c/GOALS.md            — текущие цели"
echo "  .i2c/JOURNAL.md          — лог действий"
echo "  .i2c/pipeline_state.json — стейт пайплайна"

if [[ "$TARGET" == "claude" ]]; then
  echo "  CLAUDE.md                — импорт фреймворка"
  echo "  ~/.claude/commands/      — slash-команды I2C"
elif [[ "$TARGET" == "qwen" ]]; then
  echo "  QWEN.md                  — оркестратор проекта (сгенерирован с реальным путём)"
  echo "  .qwen/agents/            — субагенты I2C"
  echo "  .qwen/commands/          — slash-команды I2C (уровень проекта)"
  echo "  ~/.qwen/commands/        — slash-команды I2C (глобально)"
  echo "  ~/.qwen/i2c-orchestrator.md — глобальный оркестратор"
  echo ""
  echo "Обновление фреймворка (после git pull):"
  echo "  cd $FRAMEWORK_DIR && git pull"
  echo "  ./scripts/setup-project.sh --target=qwen $PROJECT_DIR"
  echo "  (все физические копии перезапишутся)"
fi

echo ""
echo "Следующий шаг: /i2c-setup  (для интерактивного заполнения config.md)"
echo "           или: /i2c-create-prd"
