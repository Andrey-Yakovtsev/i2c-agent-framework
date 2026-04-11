# Протокол: Auto Pipeline

Meta-loop для автономного цикла `create-rfc` → `code-rfc` по всем planned/unimplemented RFC. Не пишет в `dependency-graph.json` напрямую — граф обновляют внутренние sub-pipelines. Auto только читает граф и управляет последовательностью.

## Состояние

**Два файла:**

1. **`.i2c/pipeline_state.json`** — состояние текущего inner sub-pipeline. При запуске sub-pipeline auto добавляет поля:
   - `parent_command: "auto"`
   - `parent_state_file: ".i2c/auto_state.json"`

2. **`.i2c/auto_state.json`** — meta-layer (без очередей, граф = очередь):

```json
{"command":"auto","from_stage":"rfc|code","halt_on_clarify":false,
 "status":"running|halted|done","halt_reason":"...",
 "current_target":"RFC-5","current_phase":"create-rfc|code-rfc",
 "completed":[{"kind":"create-rfc","id":"RFC-3","at":"..."}],
 "started_at":"...","updated_at":"..."}
```

## Предусловия (проверить в начале)

1. `docs/PRD.md` существует
2. `.i2c/engineering-practices.md` существует
3. `.i2c/dependency-graph.json` существует
4. `.i2c/pipeline_state.json` не `in_progress` (иначе предложи `/i2c-resume`)
5. Для `--from=rfc`: GOALS.md секция "Запланированные ADR" пуста или пользователь подтвердил

Несоблюдение → `HALT_PRECONDITIONS_MISSING` с пояснением.

## Meta-loop (state-machine)

На **каждой** итерации:

1. Re-read `dependency-graph.json`, `auto_state.json`, `pipeline_state.json` (state-machine дисциплина)
2. Decision:
   - `pipeline_state.in_progress` И `parent_command=auto` → продолжить inner sub-pipeline через `create-pipeline.md` / `code-pipeline.md`
   - `pipeline_state.in_progress` И `parent_command != auto` → `HALT` с `halt_reason="concurrent pipeline"`
   - `pipeline_state` пуст/done → выбрать следующий target:
     - `--from=rfc` И есть `status=planned` RFC → topological pick → установить `pipeline_state={command:"create-rfc", argument:<description>, parent_command:"auto", parent_state_file:".i2c/auto_state.json"}` → delegate `create-pipeline.md`
     - Есть `status=accepted` RFC без исходящего edge `implements` → topological pick → установить `pipeline_state={command:"code-rfc", argument:"<N>", parent_command:"auto", parent_state_file:".i2c/auto_state.json"}` → delegate `code-pipeline.md`
     - Ничего нет → `auto_state.status=done`, exit с сообщением "auto cycle complete"
3. После завершения sub-pipeline (его "После завершения" шаг проверит `parent_command`):
   - SUCCESS → обнови `auto_state.completed`, reset `pipeline_state={}`, goto 1
   - HALT → `auto_state.status=halted`, `halt_reason` = inner halt reason, exit

## HALT states

| Reason | Триггер |
|---|---|
| `HALT_PRECONDITIONS_MISSING` | Предусловия не выполнены |
| `HALT_REVISION_BUDGET` | Inner create-rfc провалил ревизию #2 |
| `HALT_CLARIFY_REQUIRED` | `--halt-on-clarify` и Supervisor CLARIFY |
| `HALT_FAILURE_BUDGET` | Inner code-rfc `fixes_round >= 2` |
| `HALT_CRITICAL_GAPS` | Inner code-rfc FAIL ≥50% модулей |
| `HALT_ENV_SETUP_FAILED` | Bootstrap упал |
| `HALT_POLICY_VIOLATION` | Нарушение MEMORY.md constraint |
| `HALT_CONSISTENCY` | Scoped Consistency Check — критические проблемы |
| `HALT_DEPENDENCY_CYCLE` | Цикл в графе RFC зависимостей |

## Supervisor Pre-flight в auto-mode

Каждый inner sub-pipeline при запуске через auto должен знать что он в auto-режиме. Оркестратор передаёт `auto_mode: true` при делегировании supervisor.

- `CLARIFY` → конвертируется в `APPROVE_WITH_ASSUMPTIONS`, вопросы становятся списком допущений для Architect (который фиксирует в `## Допущения`). Исключение: `--halt-on-clarify` → HALT.
- `SKIP` → элемент пропускается, auto переходит к следующему.
- `APPROVE` / `APPROVE_WITH_ASSUMPTIONS` → стандартно.

## Протокол ревизий в auto

Writer #1 → Architect #2 → **HALT с `halt_reason="HALT_REVISION_BUDGET"`** (без human-in-the-loop).

## Логирование

Каждый target пишется в `JOURNAL.md`:

```
## [ts] Auto cycle started (from=rfc)
## [ts] RFC-5 created
## [ts] RFC-5 coded (IMPL-5)
## [ts] RFC-6 HALT_FAILURE_BUDGET
```
