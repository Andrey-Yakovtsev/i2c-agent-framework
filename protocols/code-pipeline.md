# Протокол: Code Pipeline

Конвейер реализации/патча компонента по RFC.

## Параметры

| Параметр | Описание |
|----------|----------|
| `MODE` | `full` (code-rfc) или `patch` (patch-rfc) |
| `N` | Номер RFC |
| `AUTO_FLAG` | `--auto` → `mode: "bypassPermissions"`, иначе → `mode: "dontAsk"` |
| `PLAN_SOURCE` | full: RFC + MEMORY; patch: RFC + IMPL + verification-отчёт |
| `PREFIX` | `impl-[N]` (full) или `patch-[N]` (patch) |

## Шаг 0 — Supervisor: Pre-flight

Передай: RFC-[N] + специфичные для MODE входы (см. оркестратор).
Supervisor проверяет: RFC ACCEPTED? Зависимости реализованы? Нет дублей?

## Шаг 1 — Architect (Planning)

**full mode:** запусти **два субагента параллельно**:
- Субагент A: `agents/architect.md`, режим "Planning" → `.i2c/scratch/impl-[N]-plan-draft.md` + `rfc-[N]-ac-checklist.md` (см. `protocols/ac-checklist.md`)
- Субагент B: `agents/architect.md`, режим "Test Planning" → `.i2c/scratch/test-[N]-plan.md`

**patch mode:** один субагент: `agents/architect.md`, режим "Patch Planning".
Передай: текущий RFC + оригинальный IMPL + verification-отчёт + MEMORY.md.
Пишет: `.i2c/scratch/patch-[N]-plan.md`

## Шаг 2 — Critic (Planning review)

`agents/critic.md`, режим "Planning". Проверяет покрытие AC в плане реализации и тестах.
**patch:** проверяет что задачи расширяют, не перезаписывают; unchanged = "пропустить".
Пишет: `.i2c/scratch/{PREFIX}-plan-review.md`

## Шаг 3 — Writer (финализация плана)

`agents/writer.md`. Передай: plan-draft + plan-review + шаблон IMPL.md (только full) + MEMORY.md.
Пишет: `.i2c/scratch/{PREFIX}-plan-final.md`
**full:** скопируй в `docs/impl/IMPL-[N]-[slug].md`
**patch:** остаётся в scratch (IMPL обновится после SUCCESS)

## Шаг 3.5 — Environment Bootstrap (только full mode)

Проверь `Dockerfile`/`docker-compose.yml`. Контейнер запущен → пропусти.
Иначе: `agents/env-bootstrap.md`. При FAILED → `HALT_ENV_SETUP_FAILED`.

## Шаг 4 — Параллельный запуск coding + test-writer

Прочитай финальный план.

**Группа A — coding-агенты:** для каждого модуля/задачи запусти `agents/coder.md`.
Передай: RFC, MEMORY.md, задачу, целевые файлы, `rfc-[N]-ac-checklist.md`, `.i2c/engineering-practices.md`.
Агент читает `protocols/code-quality.md`; при секции безопасности — `protocols/secure-code.md`.
**patch:** "НЕ ТРОГАЙ unchanged", "расширяй, не перезаписывай".
Отчёт: `.i2c/scratch/{PREFIX}-module-[M]-report.md`

**Группа B — test-writer:** `agents/test-writer.md`.
Передай: RFC, MEMORY.md, test-plan, `.i2c/engineering-practices.md` (секция Testing). НЕ читай реализацию.
**full:** для каждого тест-файла из test-plan.
**patch:** только для new_ac.
Пишет: `.i2c/scratch/{PREFIX}-test-report.md`

Обе группы **в одном сообщении**. Последующие волны coding — без test-writer.

**После завершения — тест-раннер:**
Запусти субагент: тесты (команда из MEMORY.md) → `.i2c/scratch/{PREFIX}-test-results.md`.
Формат: `| Тест | AC | [Тип] | Статус | Stacktrace |` (Тип existing/new — patch only).

## Шаг 5 — Verification

См. `protocols/verification-cycle.md`. Передай: RFC, план, отчёты модулей, результаты тестов.

## Терминальные состояния

| Состояние | Условие |
|---|---|
| **SUCCESS** | Все AC verified |
| **HALT_FAILURE_BUDGET** | `fixes_round >= 2` + NEEDS_FIXES |
| **HALT_CRITICAL_GAPS** | FAIL у ≥50% модулей/задач |
| **HALT_DEPENDENCY_DEADLOCK** | depends_on RFC не реализованы |
| **HALT_POLICY_VIOLATION** | Нарушение ограничений MEMORY.md |
| **HALT_ENV_SETUP_FAILED** | Bootstrap не поднял окружение |

При HALT: `pipeline_state.json` → `"status": "halted"`, `"halt_reason": "..."`.

## После SUCCESS

1. `pipeline_state.json` → `"status": "done"`
2. Обнови MEMORY.md: "Принятые решения по компонентам" + RTM (`✅ Verified` / `⚠️ Partial`)
3. Отклонения AC/RFC → "Технический долг" MEMORY.md
4. JOURNAL.md: файлы, покрытие, отклонения, tech debt
5. **patch:** обнови `docs/impl/IMPL-[N]-*.md` — `## История изменений`
6. Обнови `dependency-graph.json`: IMPL node + edge `implements` к RFC-[N]
7. Если `pipeline_state.parent_command == "auto"` → верни управление `auto-pipeline.md`. Иначе — сообщи пользователю.
