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
Supervisor проверяет: RFC ACCEPTED? Зависимости реализованы? Нет дублирования?

## Шаг 1 — Architect (Planning)

**full mode:** запусти **два субагента параллельно**:
- Субагент A: `agents/architect.md`, режим "Planning" → `.i2c/scratch/impl-[N]-plan-draft.md`
- Субагент B: `agents/architect.md`, режим "Test Planning" → `.i2c/scratch/test-[N]-plan.md`

**patch mode:** один субагент: `agents/architect.md`, режим "Patch Planning".
Передай: текущий RFC + оригинальный IMPL + verification-отчёт + MEMORY.md.
Пишет: `.i2c/scratch/patch-[N]-plan.md`

## Шаг 2 — Critic (Planning review)

`agents/critic.md`, режим "Planning". Проверяет покрытие AC в плане реализации и тестах.
**patch:** дополнительно проверяет что задачи расширяют, а не перезаписывают; unchanged-модули отмечены как "пропустить".
Пишет: `.i2c/scratch/{PREFIX}-plan-review.md`

## Шаг 3 — Writer (финализация плана)

`agents/writer.md`. Передай: plan-draft + plan-review + шаблон IMPL.md (только full) + MEMORY.md.
Пишет: `.i2c/scratch/{PREFIX}-plan-final.md`
**full:** скопируй в `docs/impl/IMPL-[N]-[slug].md`
**patch:** остаётся в scratch (IMPL обновится после SUCCESS)

## Шаг 3.5 — Environment Bootstrap (только full mode)

Проверь наличие `Dockerfile`/`docker-compose.yml`. Если контейнер уже запущен → пропусти.
Иначе: `agents/env-bootstrap.md`. При FAILED → `HALT_ENV_SETUP_FAILED`.

## Шаг 4 — Параллельный запуск coding + test-writer

Прочитай финальный план.

**Группа A — coding-агенты:** для каждого модуля/задачи из плана запусти `agents/coder.md`.
Передай: RFC, MEMORY.md, задача из плана, целевые файлы.
Агент сам читает `protocols/code-quality.md`; если RFC имеет секцию безопасности — также `protocols/secure-code.md`.
**patch:** добавь "НЕ ТРОГАЙ unchanged-модули", "расширяй, не перезаписывай".
Каждый пишет отчёт: `.i2c/scratch/{PREFIX}-module-[M]-report.md`

**Группа B — test-writer агенты:** `agents/test-writer.md`.
Передай: RFC, MEMORY.md, test-plan. НЕ читай файлы реализации.
**full:** для каждого тест-файла из test-plan.
**patch:** только для new_ac.
Пишет: `.i2c/scratch/{PREFIX}-test-report.md`

Запускай обе группы **в одном сообщении**. Последующие волны coding — без test-writer.

**После завершения — тест-раннер:**
Запусти субагент: выполнить тесты (команда из MEMORY.md), записать результаты в `.i2c/scratch/{PREFIX}-test-results.md`.
Формат: `| Тест | AC | [Тип] | Статус | Stacktrace |` (Тип = existing/new — только для patch).

## Шаг 5 — Verification

См. `protocols/verification-cycle.md`. Передай: RFC, план, отчёты модулей, результаты тестов.

## Терминальные состояния

| Состояние | Условие |
|---|---|
| **SUCCESS** | Все AC verified |
| **HALT_FAILURE_BUDGET** | `fixes_round >= 2` + NEEDS_FIXES |
| **HALT_CRITICAL_GAPS** | FAIL у ≥50% модулей/задач |
| **HALT_DEPENDENCY_DEADLOCK** | depends_on RFC не реализованы (только full) |
| **HALT_POLICY_VIOLATION** | Нарушение ограничений из MEMORY.md (только full) |
| **HALT_ENV_SETUP_FAILED** | Bootstrap не смог поднять окружение (только full) |

При HALT: `pipeline_state.json` → `"status": "halted"`, `"halt_reason": "..."`. JOURNAL.md не обновлять.

## После SUCCESS

1. `pipeline_state.json` → `"status": "done"`
2. Обнови MEMORY.md: таблица "Принятые решения по компонентам" + RTM (`✅ Verified` или `⚠️ Partial`)
3. Если отклонения от AC/RFC → добавь в "Технический долг" MEMORY.md
4. Запиши в JOURNAL.md: файлы, AC покрытие, отклонения, tech debt
5. **patch:** обнови `docs/impl/IMPL-[N]-*.md` — добавь `## История изменений` с новыми AC и файлами
6. Сообщи пользователю результат
