# I2C — Idea to Code Framework

Переиспользуемый фреймворк для автономного создания проектной документации и кода с помощью AI-агентов.

```
Идея → PRD → ADR → RFC → Tests + Code
```

Claude Code / Qwen Code выступает оркестратором. Каждый документ проходит через конвейер из специализированных субагентов:

```
Supervisor (pre-flight) → Researcher → Architect → Critic → Writer → Supervisor (post-review)
```

---

## Содержание

1. [Установка в проект](#установка-в-проект)
2. [Полный цикл: от идеи до кода](#полный-цикл-от-идеи-до-кода)
3. [Команды](#команды)
4. [Работа с существующим проектом](#работа-с-существующим-проектом)
5. [Обрыв сессии и resume](#обрыв-сессии-и-resume)
6. [Обновление фреймворка и документов](#обновление-фреймворка-и-документов)
7. [Агенты](#агенты)
8. [Структура файлов проекта](#структура-файлов-проекта)
9. [Структура фреймворка](#структура-фреймворка)
10. [Принципы](#принципы)

---

## Установка в проект

Фреймворк устанавливается **в конкретный проект**, а не глобально. В не-i2c сессиях — нулевой overhead.

### Claude Code

```bash
git clone https://github.com/anthropics/i2c-agent-framework ~/i2c-agent-framework
cd ~/i2c-agent-framework
./install.sh /path/to/your/project
```

### Qwen Code

```bash
cd ~/i2c-agent-framework
./install.sh --target=qwen /path/to/your/project
```

### Что делает `install.sh`

1. Генерирует `orchestrator-installed.md` в папке фреймворка (с реальными путями)
2. Создаёт `.i2c/` скелет в проекте (config, MEMORY, GOALS, JOURNAL, pipeline_state)
3. Генерирует `/i2c-*` команды в `<project>/.claude/commands/` (или `.qwen/commands/`)
4. Чистит старую глобальную установку (если была)

После установки — команды видны **только** в этом проекте. Другие проекты не затрагиваются.

### Настройка проекта

Открой Claude/Qwen в проекте и выполни:

```
/i2c-setup
```

Оркестратор задаст вопросы о проекте (название, домен, цель, пользователь, стек) и заполнит `.i2c/config.md`.

- **Новый проект** — `config.md` заполняется интерактивно, `MEMORY.md` остаётся пустым. Следующий шаг: `/i2c-create-prd`.
- **Существующий проект** — Researcher аудирует кодовую базу и заполняет `MEMORY.md` уже принятыми решениями. Следующий шаг: `/i2c-status`.

---

## Полный цикл: от идеи до кода

### Шаг 1 — PRD: что строим

```
/i2c-create-prd
```

Запускает конвейер: Supervisor → Researcher → Architect → Critic → Writer → Supervisor.

Researcher исследует проблему, пользователей и рынок. Architect формулирует Vision, MVP scope, ключевые workflow и метрики. Critic проверяет что MVP не слишком широк, пользователь конкретный, метрики измеримы. Writer собирает финальный PRD по шаблону.

Результат: `docs/PRD.md`

---

### Шаг 2 — ADR: ключевые архитектурные решения

Для каждого решения которое трудно отменить:

```
/i2c-create-adr выбор архитектурного стиля
/i2c-create-adr выбор базы данных
/i2c-create-adr стратегия аутентификации
```

Создавай ADR в порядке зависимостей. Architect рассматривает минимум 2 альтернативы с реальными трейдоффами. Critic проверяет что минусы названы честно.

Результат: `docs/ADR-001-[slug].md`, `docs/ADR-002-[slug].md`, ...

Каждое решение автоматически попадает в `MEMORY.md` — следующие ADR и RFC не могут его переоткрыть.

---

### Шаг 3 — RFC: детальная спека компонентов

```
/i2c-create-rfc core data model
/i2c-create-rfc auth service
/i2c-create-rfc document processing pipeline
```

Один RFC = один компонент. Создавай в порядке зависимостей. Supervisor проверяет граф зависимостей — нельзя создать RFC раньше ADR от которого он зависит.

Результат: `docs/rfc/RFC-001-[slug].md`, ...

**Не жди создания всех RFC.** Как только RFC принят — передавай в `code-rfc`. Создание следующего RFC и реализация предыдущего идут параллельно.

---

### Шаг 4 — Code: реализация по RFC

```
/i2c-code-rfc 1
/i2c-code-rfc 2 --auto    # без ручных аппрувов
```

Конвейер:

1. **Architect** — параллельно создаёт план реализации и план тестов
2. **Critic** — проверяет оба плана на покрытие AC
3. **Writer** — финализирует Implementation Plan
4. **Coding + Test Writer** — параллельно: код по модулям и тесты из RFC (Test Writer не видит реализацию)
5. **Failure Analyst** — для упавших тестов: `CODE_BUG` / `TEST_BUG` / `AMBIGUOUS`
6. **Critic [Verification]** — итоговая проверка кода против AC с учётом тестов

Исходы: `VERIFIED` → SUCCESS, `NEEDS_FIXES` → доработка (макс 2 раунда), `NEEDS_TEST_FIX` → починка тестов, `CRITICAL_GAPS` → пересмотр плана.

Результат: код + тесты + `docs/impl/IMPL-[N]-[slug].md`

---

## Команды

| Команда | Аргументы | Что делает |
|---------|-----------|-----------|
| `/i2c-setup` | — | Интерактивная настройка проекта (config.md, MEMORY.md) |
| `/i2c-create-prd` | — | Создаёт Product Requirements Document |
| `/i2c-create-adr` | `название решения` | Создаёт Architecture Decision Record |
| `/i2c-create-rfc` | `название компонента` | Создаёт RFC для компонента |
| `/i2c-code-rfc` | `N [--auto]` | Реализует компонент по RFC-N. `--auto` — без ручных аппрувов |
| `/i2c-verify-rfc` | `N` | Проверяет существующую реализацию против AC из RFC-N |
| `/i2c-patch-rfc` | `N [--auto]` | Обновляет реализацию после изменения RFC (дельта-патч) |
| `/i2c-update-prd` | `описание изменений` | Обновляет PRD после пивота |
| `/i2c-update-adr` | `N описание` | Пересматривает ADR-N (предупреждает о зависимых RFC) |
| `/i2c-resume` | — | Продолжает прерванный пайплайн |
| `/i2c-check` | — | Проверяет консистентность документации |
| `/i2c-status` | — | Что создано, что следующее, открытые вопросы |
| `/i2c-framework-update` | — | Обновляет фреймворк (git pull + regenerate) |

---

## Работа с существующим проектом

```bash
# 1. Установи фреймворк
~/i2c-agent-framework/install.sh /path/to/project

# 2. Настрой проект (выбери "Существующий")
/i2c-setup

# 3. Проверь что отсутствует
/i2c-status
/i2c-check

# 4. Создай недостающие документы
/i2c-create-prd
/i2c-create-adr ...
/i2c-create-rfc ...

# 5. Верифицируй существующий код
/i2c-verify-rfc 1
```

---

## Обрыв сессии и resume

```
/i2c-resume
```

Оркестратор читает `.i2c/pipeline_state.json` и предлагает: продолжить с прерванного шага, начать заново или отменить. Промежуточные файлы в `.i2c/scratch/` сохраняются между сессиями.

---

## Обновление фреймворка и документов

### Обновление фреймворка

Из Claude/Qwen в проекте:

```
/i2c-framework-update
```

Или вручную:

```bash
cd ~/i2c-agent-framework
git pull
./install.sh /path/to/project              # Claude
./install.sh --target=qwen /path/to/project  # Qwen
```

Правки оркестратора делай в `orchestrator-source.md`. `orchestrator-installed.md` — генерируемый артефакт, не редактируй напрямую.

### Обновление документов проекта

```
/i2c-update-prd "меняем целевого пользователя с B2C на B2B"
/i2c-update-adr 2 "переходим с PostgreSQL на CockroachDB"
/i2c-patch-rfc 3    # после изменения RFC-3
```

---

## Агенты

| Агент | Режимы | Роль |
|-------|--------|------|
| **Supervisor** | Pre-flight, Post-review | Нужен ли артефакт? Вписывается в экосистему? |
| **Researcher** | PRD, RFC, Discovery | Исследование проблемы, аудит кода |
| **Architect** | PRD, ADR, RFC, Planning, Test Planning | Проектирование, трейдоффы, планы реализации и тестов |
| **Critic** | PRD, ADR, RFC, Planning, Verification | Атакует черновики, верифицирует код против AC |
| **Writer** | Все документальные | Финализация по шаблону |
| **Test Writer** | — | Тесты из RFC без доступа к реализации |
| **Failure Analyst** | — | Анализ упавших тестов: CODE_BUG / TEST_BUG / AMBIGUOUS |

---

## Структура файлов проекта

```
your-project/
  .claude/commands/i2c-*.md          ← генерируются install.sh (или .qwen/commands/)
  .i2c/
    config.md                        ← контекст проекта
    MEMORY.md                        ← принятые решения + RTM
    GOALS.md                         ← текущая стадия
    JOURNAL.md                       ← лог действий
    pipeline_state.json              ← стейт пайплайна (для resume)
    scratch/                         ← временные файлы агентов (не коммитить)
  docs/
    PRD.md
    ADR-001-arch-style.md
    rfc/
      RFC-001-data-model.md
    impl/
      IMPL-001-data-model.md
  tests/
    rfc-001/
      test_core.py
```

**`.gitignore`:**
```
.i2c/scratch/
```

---

## Структура фреймворка

```
i2c-agent-framework/
  orchestrator-source.md     ← source of truth (плейсхолдер путей)
  orchestrator-installed.md  ← генерируется install.sh (.gitignored)
  install.sh                 ← установка в проект
  agents/
    supervisor.md
    researcher.md
    architect.md
    critic.md
    writer.md
    test-writer.md
    failure-analyst.md
  commands/                  ← шаблоны команд (с {{FRAMEWORK_DIR}})
    i2c-setup.md
    i2c-create-prd.md
    i2c-create-adr.md
    i2c-create-rfc.md
    i2c-code-rfc.md
    i2c-verify-rfc.md
    i2c-patch-rfc.md
    i2c-update-prd.md
    i2c-update-adr.md
    i2c-resume.md
    i2c-status.md
    i2c-check.md
    i2c-framework-update.md
  templates/
    PRD.md, ADR.md, RFC.md, IMPL.md, MEMORY.md, GOALS.md, JOURNAL.md
  diagnostics/
    review-checklist.md
```

---

## Принципы

**Документы создаются агентами, не людьми.** Человек задаёт цель и подтверждает результат.

**MEMORY.md — закон.** Решения зафиксированные в MEMORY.md не переоткрываются.

**RFC — единственный арбитр.** Когда тест и код расходятся, правота определяется по RFC.

**Тесты из документации, не из кода.** Test Writer пишет тесты из RFC не видя реализацию. Тест = контракт.

**Критика обязательна.** Ни один черновик не становится финальным без Critic.

**Стейт сохраняется.** `pipeline_state.json` фиксирует каждый шаг. Обрыв сессии — не потеря работы.

**Supervisor — привратник.** Документ попадает в `docs/` только после ACCEPTED.

**Код и спека идут параллельно.** `code-rfc` не ждёт создания всех RFC — только принятия конкретного RFC и верификации его зависимостей.
