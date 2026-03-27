# Протокол: Create Pipeline

Общий конвейер для создания документов (PRD, ADR, RFC). Параметры передаёт оркестратор.

## Параметры

| Параметр | Описание |
|----------|----------|
| `ARTIFACT_TYPE` | PRD / ADR / RFC |
| `HAS_RESEARCHER` | Есть ли шаг Researcher (PRD: да, RFC: да, ADR: нет) |
| `TEMPLATE` | Путь к шаблону: `~/i2c-agent-framework/templates/{ARTIFACT_TYPE}.md` |
| `DOCS_PATH` | Куда копировать финальный файл (например `docs/PRD.md`) |
| `PREFIX` | Префикс scratch-файлов (например `prd`, `adr`, `rfc-[N]`) |
| `PRE_FLIGHT_INPUTS` | Что передать Supervisor на pre-flight (специфично для команды) |
| `RESEARCHER_INPUTS` | Что передать Researcher (если HAS_RESEARCHER) |
| `ARCHITECT_EXTRA_INPUTS` | Дополнительные входы для Architect (специфично для команды) |
| `POST_REVIEW_EXTRA` | Дополнительные входы для Supervisor post-review |
| `HAS_CONSISTENCY_CHECK` | Есть ли Scoped Consistency Check после post-review (только RFC) |

## Конвейер

### Шаг 0 — Supervisor: Pre-flight

Запусти `agents/supervisor.md` в режиме Pre-flight. Передай `PRE_FLIGHT_INPUTS` + MEMORY.md.
Вердикты: см. оркестратор «Вердикты Supervisor Pre-flight».

### Шаг 1 — Researcher (если HAS_RESEARCHER)

Запусти `agents/researcher.md`. Передай: `RESEARCHER_INPUTS` + MEMORY.md + подсказки Supervisor. Режим: `ARTIFACT_TYPE`.
Пишет: `.i2c/scratch/{PREFIX}-research.md`

### Шаг 2 — Architect

Запусти `agents/architect.md`. Режим: `ARTIFACT_TYPE`.
Передай: результат Researcher (если был) или входы команды + MEMORY.md + `ARCHITECT_EXTRA_INPUTS`.
Пишет: `.i2c/scratch/{PREFIX}-draft.md`

### Шаг 3 — Critic

Запусти `agents/critic.md`. Режим: `ARTIFACT_TYPE`.
Передай: `{PREFIX}-draft.md` + MEMORY.md.
Пишет: `.i2c/scratch/{PREFIX}-review.md`

### Шаг 4 — Writer

Запусти `agents/writer.md`.
Передай: `{PREFIX}-draft.md` + `{PREFIX}-review.md` + `TEMPLATE` + MEMORY.md.
Пишет: `.i2c/scratch/{PREFIX}-final.md`

### Шаг 5 — Supervisor: Post-review

Запусти `agents/supervisor.md` в режиме Post-review.
Передай: `{PREFIX}-final.md` + MEMORY.md + `POST_REVIEW_EXTRA`.

- **ACCEPTED** → скопируй `{PREFIX}-final.md` → `DOCS_PATH`.
- **NEEDS_REVISION** → см. «Протокол ревизий» в оркестраторе (`[final]` = `{PREFIX}-final.md`, `[draft]` = `{PREFIX}-draft`, `[docs-path]` = `DOCS_PATH`).

### Шаг 5.5 — Scoped Consistency Check (если HAS_CONSISTENCY_CHECK)

Запусти `diagnostics/review-checklist.md` в режиме Scoped (`scope: "new-rfc"`).
Передай: новый RFC + все RFC из `Зависит от:` + все ADR.
Пишет: `.i2c/scratch/{PREFIX}-consistency.md`

- ❌ критические → покажи пользователю, предложи [1] исправить (возврат к Architect), [2] принять с фиксацией в JOURNAL.md
- ⚠️ или ✅ → добавь предупреждения в JOURNAL.md, продолжай

### После завершения

1. `pipeline_state.json` → `"status": "done"`
2. Извлеки решения → `.i2c/MEMORY.md`
3. Запиши в `.i2c/JOURNAL.md` (включая паттерн от Supervisor)
4. Для RFC: обнови RTM в MEMORY.md (`REQ → RFC-[NNN]`); если создано 3+ RFC — предложи `/i2c-check`
5. Сообщи пользователю: файл готов, путь, открытые вопросы
