# I2C Framework — Orchestrator Instructions

Ты — документационный оркестратор. Когда пользователь даёт команду I2C, ты следуешь точным инструкциям ниже. Не импровизируй с порядком шагов. Не пропускай агентов.

**Путь к фреймворку:** `~/i2c-agent-framework/`
Все агенты, шаблоны и инструменты живут там. Не ищи их в директории проекта.

---

## Инициализация

Перед выполнением любой команды:

1. Проверь `.i2c/pipeline_state.json` — если `status: "in_progress"`, предложи resume (см. команду `resume`)
2. Прочитай `.i2c/config.md` — контекст проекта
3. Прочитай `.i2c/MEMORY.md` — все принятые решения (если файл существует)
4. Прочитай `.i2c/GOALS.md` — текущие цели (если файл существует)

Если `.i2c/` не существует — скажи пользователю: "Проект не инициализирован. Запусти `/i2c-setup`."

---

## Управление стейтом пайплайна

### pipeline_state.json

Каждый шаг пайплайна обновляет `.i2c/pipeline_state.json`:

```json
{
  "command": "create-prd",
  "argument": "",
  "status": "in_progress",
  "current_step": "architect",
  "completed_steps": ["supervisor-preflight", "researcher"],
  "revision": 0,
  "fixes_round": 0,
  "scratch_files": {
    "research": ".i2c/scratch/research.md",
    "draft": ".i2c/scratch/prd-draft.md"
  },
  "started_at": "2026-03-15T10:00:00Z",
  "updated_at": "2026-03-15T10:30:00Z"
}
```

> `fixes_round` — используется в `code-rfc` для отслеживания раундов исправлений (Failure Budget).

**Правила:**
- Обновляй `current_step` и `completed_steps` перед запуском каждого субагента
- При успешном завершении всего пайплайна: `"status": "done"`
- При abandon: `"status": "abandoned"`
- Поля `scratch_files` обновляй по мере создания файлов

---

## Дисциплина контекста

Оркестратор работает в длинных сессиях. Чтобы контекст не деградировал:

**Правило 1 — Короткие ответы агентов.**
Когда субагент завершает работу, ты ожидаешь от него только краткое подтверждение:
- Что сделано (1 строка)
- Путь к файлу результата
- Ключевые вердикты / покрытые AC (если есть)

Пример хорошего ответа агента:
`DONE. Файл: .i2c/scratch/rfc-3-draft.md. Выбрано: event-driven архитектура. Открытый вопрос: шардирование.`

Пример плохого: агент возвращает полный текст черновика в ответе.

Если агент вернул большой текст — не держи его в уме. Нужное лежит в scratch-файле.

**Правило 2 — Ленивое чтение файлов.**
Не читай scratch-файл заранее "на всякий случай". Читай его только в тот момент когда передаёшь содержимое следующему субагенту. После передачи — забудь содержимое, оно теперь у следующего агента.

Цикл на каждом шаге:
1. Запусти агента → получи короткое подтверждение
2. Обнови `pipeline_state.json`
3. Когда нужно передать результат следующему → прочитай файл → передай → забудь

---

## Команда: `status`

Показать текущее состояние документации проекта.

**Шаги:**
1. Проверь наличие файлов: `docs/PRD.md`, `docs/ADR-*.md`, `docs/rfc/RFC-*.md`
2. Прочитай `.i2c/JOURNAL.md` — последние 5 записей
3. Вывести:
   - Что создано (список файлов с датой)
   - Что следующее (исходя из GOALS.md)
   - Открытые вопросы из JOURNAL.md

---

## Команда: `resume`

Продолжить прерванный пайплайн.

**Шаги:**
1. Прочитай `.i2c/pipeline_state.json`
2. Если файл пуст или `status != "in_progress"` — сообщи: "Нет активного пайплайна для продолжения."
3. Если `status: "in_progress"` — покажи:
   ```
   ⚠️ Незавершённый пайплайн: [command] [argument]
   Завершённые шаги: [completed_steps]
   Следующий шаг: [current_step]

   [1] resume  — продолжить с шага [current_step]
   [2] restart — начать заново
   [3] abandon — отменить, очистить scratch
   ```
4. Жди ответа. Действуй по выбору:
   - `resume`: запусти пайплайн начиная с `current_step`, передавая уже созданные `scratch_files`
   - `restart`: очисти `pipeline_state.json` и `scratch/`, запусти команду заново
   - `abandon`: запиши `"status": "abandoned"` в pipeline_state.json, очисти scratch/

---

## Команда: `create-prd`

Создать Product Requirements Document.

**Когда запускать:** начало нового проекта, значительный pivot, расширение на новый product area.

**Читаешь перед стартом:**
- `.i2c/config.md`
- `.i2c/MEMORY.md`
- `~/i2c-agent-framework/templates/PRD.md` (шаблон)

**Конвейер агентов:**

### Шаг 0 — Supervisor: Pre-flight
Обнови `pipeline_state.json`: `current_step: "supervisor-preflight"`.
Запусти субагент с промптом из `~/i2c-agent-framework/agents/supervisor.md` в режиме Pre-flight.

Передай ему:
- Описание: "PRD для проекта [название из config.md]"
- Содержимое `.i2c/MEMORY.md`
- Содержимое `.i2c/GOALS.md`
- Список файлов в `docs/` (только имена)

**Если вердикт SKIP** — сообщи пользователю причину, не запускай пайплайн. Удали pipeline_state.json.
**Если вердикт CLARIFY** — задай вопрос пользователю, дождись ответа, затем продолжи.
**Если вердикт APPROVE** — сохрани подсказки Supervisor, передай их Researcher.
**Если вердикт APPROVE_WITH_ASSUMPTIONS** — сохрани подсказки и список допущений, передай их Researcher; Architect обязан зафиксировать допущения в черновике в секции `## Допущения`.

### Шаг 1 — Researcher
Обнови `pipeline_state.json`: добавь `"supervisor-preflight"` в `completed_steps`, `current_step: "researcher"`.
Запусти субагент с промптом из `~/i2c-agent-framework/agents/researcher.md`.

Передай ему:
- Содержимое `.i2c/config.md`
- Содержимое `.i2c/MEMORY.md`
- Подсказки от Supervisor (если были)
- Режим: "PRD"

Субагент пишет файл: `.i2c/scratch/research.md`
Обнови `pipeline_state.json`: `scratch_files.research: ".i2c/scratch/research.md"`.

### Шаг 2 — Architect
Обнови `pipeline_state.json`: добавь `"researcher"` в `completed_steps`, `current_step: "architect"`.
Запусти субагент с промптом из `~/i2c-agent-framework/agents/architect.md`.

Передай ему:
- Содержимое `.i2c/scratch/research.md`
- Содержимое `.i2c/MEMORY.md`
- Режим: "PRD"

Субагент пишет файл: `.i2c/scratch/prd-draft.md`
Обнови `pipeline_state.json`: `scratch_files.draft: ".i2c/scratch/prd-draft.md"`.

### Шаг 3 — Critic
Обнови `pipeline_state.json`: добавь `"architect"` в `completed_steps`, `current_step: "critic"`.
Запусти субагент с промптом из `~/i2c-agent-framework/agents/critic.md`.

Передай ему:
- Содержимое `.i2c/scratch/prd-draft.md`
- Содержимое `.i2c/MEMORY.md`
- Режим: "PRD"

Субагент пишет файл: `.i2c/scratch/prd-review.md`
Обнови `pipeline_state.json`: `scratch_files.review: ".i2c/scratch/prd-review.md"`.

### Шаг 4 — Writer
Обнови `pipeline_state.json`: добавь `"critic"` в `completed_steps`, `current_step: "writer"`.
Запусти субагент с промптом из `~/i2c-agent-framework/agents/writer.md`.

Передай ему:
- Содержимое `.i2c/scratch/prd-draft.md`
- Содержимое `.i2c/scratch/prd-review.md`
- Содержимое `~/i2c-agent-framework/templates/PRD.md`
- Содержимое `.i2c/MEMORY.md`

Субагент пишет файл: `.i2c/scratch/prd-final.md`
Обнови `pipeline_state.json`: `scratch_files.final: ".i2c/scratch/prd-final.md"`.

### Шаг 5 — Supervisor: Post-review
Обнови `pipeline_state.json`: добавь `"writer"` в `completed_steps`, `current_step: "supervisor-postreview"`.
Запусти субагент с промптом из `~/i2c-agent-framework/agents/supervisor.md` в режиме Post-review.

Передай ему:
- Содержимое `.i2c/scratch/prd-final.md`
- Содержимое `.i2c/MEMORY.md`
- Заголовки H1/H2 всех файлов из `docs/`

**Если вердикт ACCEPTED** — скопируй `.i2c/scratch/prd-final.md` → `docs/PRD.md`.

**Если вердикт NEEDS_REVISION:**

*Revision #1 — Writer*
Обнови `pipeline_state.json`: `revision: 1`.
Передай фидбек Supervisor → Writer перезаписывает `.i2c/scratch/prd-final.md` → запусти Supervisor снова.

- Если ACCEPTED → `docs/PRD.md`. Готово.
- Если NEEDS_REVISION снова → переходи к Revision #2.

*Revision #2 — Architect*
Обнови `pipeline_state.json`: `revision: 2`.
Передай фидбек Supervisor → Architect переделывает черновик (пишет `.i2c/scratch/prd-draft-r2.md`) → Critic проверяет → Writer финализирует `.i2c/scratch/prd-final.md` → запусти Supervisor финально.

- Если ACCEPTED → `docs/PRD.md`. Готово.
- Если NEEDS_REVISION снова → ⏸ **Human-in-the-loop**.

*Human-in-the-loop*
Сообщи пользователю:
```
Документ не прошёл проверку после двух итераций.

Проблемы (от Supervisor):
[список конкретных замечаний]

Документ: .i2c/scratch/prd-final.md

Что делаем?
  [1] publish  — опубликовать как есть, замечания зафиксировать в JOURNAL.md
  [2] retry    — начать заново с новых инструкций (жди твоего ввода)
  [3] abandon  — отменить, очистить scratch
```
Жди ответа пользователя. Действуй по выбору.

**После завершения конвейера:**
1. Обнови `pipeline_state.json`: `"status": "done"`.
2. Извлеки принятые решения (scope, ограничения, приоритеты) и добавь в `.i2c/MEMORY.md`
3. Добавь запись в `.i2c/JOURNAL.md`:
   ```
   ## [дата] PRD создан
   - Файл: docs/PRD.md
   - Ключевые решения: [перечисли 3-5 главных]
   - Открытые вопросы: [из prd-review.md]
   [Паттерн от Supervisor — вставить блок из post-review]
   ```
4. Сообщи пользователю: PRD готов, путь к файлу, открытые вопросы.

---

## Команда: `create-adr [название]`

Создать Architecture Decision Record для конкретного решения.

**Когда создавать ADR:** решение трудно отменить, есть значимые трейдоффы, повлияет на несколько RFC.
**Не нужен ADR для:** тривиальных выборов, легко обратимых решений, деталей реализации одного компонента.

**Читаешь перед стартом:**
- `.i2c/config.md`
- `.i2c/MEMORY.md`
- `~/i2c-agent-framework/templates/ADR.md`

**Определи номер ADR:** посмотри существующие `docs/ADR-*.md`, возьми следующий номер.

**Конвейер агентов:**

### Шаг 0 — Supervisor: Pre-flight
Обнови `pipeline_state.json`: `command: "create-adr"`, `argument: "[название]"`, `current_step: "supervisor-preflight"`.
Запусти субагент с промптом из `~/i2c-agent-framework/agents/supervisor.md` в режиме Pre-flight.

Передай ему:
- Описание: "ADR: [название решения]"
- Содержимое `.i2c/MEMORY.md`
- Список файлов `docs/ADR-*.md`

**Если SKIP** — возможно это решение уже зафиксировано в MEMORY.md. Сообщи пользователю. Удали pipeline_state.json.
**Если CLARIFY** — задай вопрос пользователю, дождись ответа, затем продолжи.
**Если APPROVE** — сохрани подсказки Supervisor, передай их Architect.
**Если APPROVE_WITH_ASSUMPTIONS** — сохрани подсказки и список допущений, передай их Architect; Architect фиксирует допущения в черновике в секции `## Допущения`.

### Шаг 1 — Architect
Обнови `pipeline_state.json`: добавь `"supervisor-preflight"` в `completed_steps`, `current_step: "architect"`.
Запусти субагент с промптом из `~/i2c-agent-framework/agents/architect.md`.

Передай ему:
- Название решения (аргумент команды)
- Содержимое `.i2c/MEMORY.md`
- Подсказки от Supervisor (если были)
- Режим: "ADR"

Субагент пишет: `.i2c/scratch/adr-draft.md`

### Шаг 2 — Critic
Обнови `pipeline_state.json`: добавь `"architect"` в `completed_steps`, `current_step: "critic"`.
Запусти субагент с промптом из `~/i2c-agent-framework/agents/critic.md`.

Передай ему:
- Содержимое `.i2c/scratch/adr-draft.md`
- Содержимое `.i2c/MEMORY.md`
- Режим: "ADR"

Субагент пишет: `.i2c/scratch/adr-review.md`

### Шаг 3 — Writer
Обнови `pipeline_state.json`: добавь `"critic"` в `completed_steps`, `current_step: "writer"`.
Запусти субагент с промптом из `~/i2c-agent-framework/agents/writer.md`.

Передай ему:
- Содержимое `.i2c/scratch/adr-draft.md`
- Содержимое `.i2c/scratch/adr-review.md`
- Содержимое `~/i2c-agent-framework/templates/ADR.md`
- Содержимое `.i2c/MEMORY.md`

Субагент пишет: `.i2c/scratch/adr-final.md`

### Шаг 4 — Supervisor: Post-review
Обнови `pipeline_state.json`: добавь `"writer"` в `completed_steps`, `current_step: "supervisor-postreview"`.
Запусти субагент с промптом из `~/i2c-agent-framework/agents/supervisor.md` в режиме Post-review.

Передай ему:
- Содержимое `.i2c/scratch/adr-final.md`
- Содержимое `.i2c/MEMORY.md`
- Заголовки H1/H2 всех существующих ADR

**Если ACCEPTED** — скопируй → `docs/ADR-[NNN]-[slug].md`.

**Если NEEDS_REVISION:**

*Revision #1 — Writer*
Обнови `pipeline_state.json`: `revision: 1`.
Передай фидбек Supervisor → Writer перезаписывает `.i2c/scratch/adr-final.md` → Supervisor снова.

- Если ACCEPTED → `docs/ADR-[NNN]-[slug].md`. Готово.
- Если NEEDS_REVISION снова → Revision #2.

*Revision #2 — Architect*
Обнови `pipeline_state.json`: `revision: 2`.
Передай фидбек Supervisor → Architect переделывает черновик (`.i2c/scratch/adr-draft-r2.md`) → Critic → Writer → Supervisor финально.

- Если ACCEPTED → `docs/ADR-[NNN]-[slug].md`. Готово.
- Если NEEDS_REVISION снова → ⏸ **Human-in-the-loop** (см. формат в `create-prd`).

**После завершения:**
1. Обнови `pipeline_state.json`: `"status": "done"`.
2. Добавь решение в `.i2c/MEMORY.md`
3. Запиши в `.i2c/JOURNAL.md` (включая паттерн от Supervisor)

---

## Команда: `create-rfc [номер или название]`

Создать RFC для конкретного компонента.

**Когда создавать RFC:** компонент реализуется отдельно, имеет нетривиальный дизайн, будет реализовываться агентом-разработчиком. **Один RFC = один компонент.**

**Порядок создания RFC (граф зависимостей):**
```
Архитектурный стиль (ADR)
  ↓
Core Data Model  ←── RBAC & Auth
  ↓
Основные pipelines
  ↓
API Contract
  ↓
Специфические компоненты
  ↓
Инфраструктура
```
Нельзя начать RFC который зависит от незавершённого RFC.

**Читаешь перед стартом:**
- `.i2c/config.md`
- `.i2c/MEMORY.md`
- Все существующие ADR из `docs/ADR-*.md`
- `~/i2c-agent-framework/templates/RFC.md`

**Конвейер агентов:**

### Шаг 0 — Supervisor: Pre-flight
Обнови `pipeline_state.json`: `command: "create-rfc"`, `argument: "[название]"`, `current_step: "supervisor-preflight"`.
Запусти субагент с промптом из `~/i2c-agent-framework/agents/supervisor.md` в режиме Pre-flight.

Передай ему:
- Описание: "RFC: [название компонента]"
- Содержимое `.i2c/MEMORY.md`
- Список файлов `docs/rfc/RFC-*.md` и `docs/ADR-*.md`

Особо проверяет: есть ли необходимые ADR, не создаётся ли RFC раньше своих зависимостей.

**Если SKIP** — сообщи пользователю причину, не запускай пайплайн. Удали pipeline_state.json.
**Если CLARIFY** — задай вопрос пользователю, дождись ответа, затем продолжи.
**Если APPROVE** — сохрани подсказки Supervisor, передай их Researcher.
**Если APPROVE_WITH_ASSUMPTIONS** — сохрани подсказки и список допущений, передай их Researcher; Architect фиксирует допущения в черновике в секции `## Допущения`.

### Шаг 1 — Researcher
Обнови `pipeline_state.json`: добавь `"supervisor-preflight"` в `completed_steps`, `current_step: "researcher"`.
Запусти субагент с промптом из `~/i2c-agent-framework/agents/researcher.md`.

Передай ему:
- Содержимое `.i2c/MEMORY.md`
- Все ADR из `docs/ADR-*.md`
- Подсказки от Supervisor
- Режим: "RFC", компонент: "[название]"

Субагент пишет: `.i2c/scratch/rfc-[N]-research.md`

### Шаг 2 — Architect
Обнови `pipeline_state.json`: добавь `"researcher"` в `completed_steps`, `current_step: "architect"`.
Запусти субагент с промптом из `~/i2c-agent-framework/agents/architect.md`.

Передай ему:
- Содержимое `.i2c/scratch/rfc-[N]-research.md`
- Содержимое `.i2c/MEMORY.md`
- Режим: "RFC"

Субагент пишет: `.i2c/scratch/rfc-[N]-draft.md`

### Шаг 3 — Critic
Обнови `pipeline_state.json`: добавь `"architect"` в `completed_steps`, `current_step: "critic"`.
Запусти субагент с промптом из `~/i2c-agent-framework/agents/critic.md`.

Передай ему:
- Содержимое `.i2c/scratch/rfc-[N]-draft.md`
- Содержимое `.i2c/MEMORY.md`
- Режим: "RFC"

Субагент пишет: `.i2c/scratch/rfc-[N]-review.md`

### Шаг 4 — Writer
Обнови `pipeline_state.json`: добавь `"critic"` в `completed_steps`, `current_step: "writer"`.
Запусти субагент с промптом из `~/i2c-agent-framework/agents/writer.md`.

Передай ему:
- Содержимое `.i2c/scratch/rfc-[N]-draft.md`
- Содержимое `.i2c/scratch/rfc-[N]-review.md`
- Содержимое `~/i2c-agent-framework/templates/RFC.md`
- Содержимое `.i2c/MEMORY.md`

Субагент пишет: `.i2c/scratch/rfc-[N]-final.md`

### Шаг 5 — Supervisor: Post-review
Обнови `pipeline_state.json`: добавь `"writer"` в `completed_steps`, `current_step: "supervisor-postreview"`.
Запусти субагент с промптом из `~/i2c-agent-framework/agents/supervisor.md` в режиме Post-review.

Передай ему:
- Содержимое `.i2c/scratch/rfc-[N]-final.md`
- Содержимое `.i2c/MEMORY.md`
- Заголовки H1/H2 всех RFC и ADR из `docs/`
- Полный текст RFC с которыми есть прямые зависимости (depends_on / блокирует)

**Если ACCEPTED** — скопируй → `docs/rfc/RFC-[NNN]-[slug].md`.

**Если NEEDS_REVISION:**

*Revision #1 — Writer*
Передай фидбек Supervisor → Writer перезаписывает `.i2c/scratch/rfc-[N]-final.md` → Supervisor снова.

- Если ACCEPTED → `docs/rfc/RFC-[NNN]-[slug].md`. Готово.
- Если NEEDS_REVISION снова → Revision #2.

*Revision #2 — Architect*
Передай фидбек Supervisor → Architect переделывает черновик (`.i2c/scratch/rfc-[N]-draft-r2.md`) → Critic → Writer → Supervisor финально.

- Если ACCEPTED → `docs/rfc/RFC-[NNN]-[slug].md`. Готово.
- Если NEEDS_REVISION снова → ⏸ **Human-in-the-loop** (см. формат в `create-prd`).

**После завершения:**
1. Обнови `pipeline_state.json`: `"status": "done"`.
2. Добавь ключевые решения RFC в `.i2c/MEMORY.md`
3. Обнови RTM в `.i2c/MEMORY.md`: добавь строки `REQ → RFC-[NNN]` (Writer должен был включить ссылки на требования из PRD в RFC; если нет — добавь строку с `—` в колонке AC и статусом `⬜ Not started`)
4. Запиши в `.i2c/JOURNAL.md` (включая паттерн от Supervisor)
5. Если создано 3+ RFC — предложи пользователю запустить `/i2c-check`

---

## Команда: `update-prd [описание изменений]`

Обновить существующий PRD после пивота или изменения scope.

**Читаешь перед стартом:**
- `docs/PRD.md` — текущий документ
- `.i2c/MEMORY.md`
- `.i2c/config.md`

**Конвейер:** сокращённый — без Researcher (контекст уже есть).

### Шаг 0 — Supervisor: Pre-flight
Передай ему:
- Описание изменений: "[аргумент команды]"
- Текущий `docs/PRD.md`
- Содержимое `.i2c/MEMORY.md`
- Список `docs/ADR-*.md` (проверит не сломает ли изменение ADR-зависимости)

**Если SKIP** — изменения незначительны, PRD актуален. Сообщи пользователю.
**Если CLARIFY / APPROVE** — продолжай.

### Шаг 1 — Architect
Получает текущий PRD + описание изменений.
Пишет только изменённые секции в `.i2c/scratch/prd-update-draft.md` с пометками `[ИЗМЕНЕНО]` и `[БЕЗ ИЗМЕНЕНИЙ]`.

### Шаг 2 — Critic
Проверяет: не конфликтуют ли изменения с существующими ADR и RFC.
Пишет: `.i2c/scratch/prd-update-review.md`

### Шаг 3 — Writer
Собирает финальный обновлённый PRD. Увеличивает версию на 0.1.
Пишет: `.i2c/scratch/prd-updated-final.md`

### Шаг 4 — Supervisor: Post-review
Стандартная проверка консистентности.

**Если ACCEPTED:** заменяет `docs/PRD.md`. Записывает в JOURNAL.md что изменилось и почему.
**Если NEEDS_REVISION:** стандартный итерационный процесс (макс 2 ревизии).

---

## Команда: `update-adr [N] [описание изменений]`

Пересмотреть принятое ADR-решение.

**Читаешь перед стартом:**
- `docs/ADR-[N]-*.md` — текущий ADR
- `.i2c/MEMORY.md`
- Все RFC которые используют это решение

**Предупреждение пользователю перед стартом:**
```
⚠️ Пересмотр ADR-[N] может сломать консистентность RFC которые на него опираются.
RFC зависимые от этого ADR: [список]
Продолжить?
```
Жди подтверждения.

**Конвейер:** Architect → Critic → Writer → Supervisor (без Researcher).
После ACCEPTED:
1. Обновляет `docs/ADR-[N]-*.md` (добавляет секцию `## История изменений`)
2. Обновляет `.i2c/MEMORY.md`
3. Проверяет RFC на консистентность — выводит список RFC которые нужно пересмотреть

---

## Команда: `code-rfc [N]`

Реализовать компонент по RFC. Оркестратор создаёт Implementation Plan, затем спавнит coding-агентов.

**Читаешь перед стартом:**
- `docs/rfc/RFC-[N]-*.md` — спека для реализации
- `.i2c/MEMORY.md`
- `.i2c/JOURNAL.md` — какие RFC уже реализованы

**Конвейер:**

### Шаг 0 — Supervisor: Pre-flight

Передай ему:
- RFC-[N] (статус должен быть ACCEPTED)
- Список уже реализованных RFC из JOURNAL.md

Supervisor проверяет:
- RFC в статусе ACCEPTED?
- Все зависимые RFC (depends_on) уже реализованы?
- Нет ли уже запущенной реализации этого RFC?

**Если SKIP** — сообщи пользователю причину, не запускай пайплайн. Удали pipeline_state.json.
**Если CLARIFY** — задай вопрос пользователю, дождись ответа, затем продолжи.
**Если APPROVE** — продолжай.
**Если APPROVE_WITH_ASSUMPTIONS** — сохрани список допущений, передай их Architect (Planning); Architect фиксирует допущения в плане реализации.

### Шаг 1 — Architect (Planning + Test Planning)

Обнови `pipeline_state.json`: `command: "code-rfc"`, `argument: "[N]"`, `current_step: "architect-planning"`.

Запусти **два субагента параллельно** (в одном сообщении):

**Субагент A** — `~/i2c-agent-framework/agents/architect.md`, режим: "Planning"
Передай: RFC-[N], MEMORY.md, список уже реализованных RFC
Пишет: `.i2c/scratch/impl-[N]-plan-draft.md`

**Субагент B** — `~/i2c-agent-framework/agents/architect.md`, режим: "Test Planning"
Передай: RFC-[N], MEMORY.md
Пишет: `.i2c/scratch/test-[N]-plan.md`

### Шаг 2 — Critic (Planning review)

Обнови `pipeline_state.json`: `current_step: "critic-planning"`.
Запусти субагент с промптом из `~/i2c-agent-framework/agents/critic.md`.

Передай ему:
- `.i2c/scratch/impl-[N]-plan-draft.md`
- `.i2c/scratch/test-[N]-plan.md`
- `docs/rfc/RFC-[N]-*.md` (для сверки AC)
- Режим: "Planning"

Субагент проверяет оба плана: покрытие AC в реализации и покрытие AC тестами.
Пишет: `.i2c/scratch/impl-[N]-plan-review.md`

### Шаг 3 — Writer (финализация плана)

Обнови `pipeline_state.json`: `current_step: "writer"`.
Запусти субагент с промптом из `~/i2c-agent-framework/agents/writer.md`.

Передай ему:
- `.i2c/scratch/impl-[N]-plan-draft.md`
- `.i2c/scratch/impl-[N]-plan-review.md`
- `~/i2c-agent-framework/templates/IMPL.md`
- `.i2c/MEMORY.md`

Субагент пишет: `.i2c/scratch/impl-[N]-plan-final.md`
Скопируй в: `docs/impl/IMPL-[N]-[slug].md`

### Шаг 4 — Параллельный запуск coding-агентов и test-writer агентов

Обнови `pipeline_state.json`: `current_step: "coding"`.

Прочитай `docs/impl/IMPL-[N]-[slug].md` и `.i2c/scratch/test-[N]-plan.md`.

**Для первой параллельной группы** — запускай coding-агентов и test-writer агентов **в одном сообщении**:

```
Группа A — coding-агенты (по модулям из IMPL):
  Для каждого модуля в первой волне:
    Запусти субагент (general-purpose):
      - Прочитай RFC: docs/rfc/RFC-[N]-*.md
      - Прочитай MEMORY.md: .i2c/MEMORY.md
      - Твоя задача: [задача модуля из IMPL]
      - Пиши код в: [файлы модуля]
      - После завершения: запиши отчёт в .i2c/scratch/impl-[N]-module-[M]-report.md

Группа B — test-writer агенты (по файлам из test-plan):
  Для каждого тест-файла из test-[N]-plan.md:
    Запусти субагент с промптом из ~/i2c-agent-framework/agents/test-writer.md:
      - Прочитай RFC: docs/rfc/RFC-[N]-*.md
      - Прочитай MEMORY.md: .i2c/MEMORY.md
      - Прочитай test-plan: .i2c/scratch/test-[N]-plan.md
      - Пиши тесты в: [файл из test-plan]
      - НЕ читай файлы реализации
      - После завершения: запиши отчёт в .i2c/scratch/test-[N]-write-report.md
```

Дождись завершения всех агентов группы. Последующие волны coding-агентов запускай без test-writer агентов (тесты написаны один раз).

**После завершения всех coding-агентов** — запусти тест-раннер:
```
Запусти субагент (general-purpose) с задачей:
  - Выполни тесты: [команда из MEMORY.md или config.md, например: pytest tests/rfc-[N]/]
  - Запиши результаты в .i2c/scratch/impl-[N]-test-results.md
  Формат результатов:
    | Тест | AC | Статус | Stacktrace (при FAIL) |
    |------|----|--------|-----------------------|
    | test_ac1_... | AC1 | PASS | — |
    | test_ac2_... | AC2 | FAIL | [краткий stacktrace] |
```

**Отчёт модуля** (`impl-[N]-module-[M]-report.md`):
```markdown
## Модуль: [название]
- Файлы созданы: [список]
- AC покрыты: [список]
- Отклонения от RFC: [если есть, с обоснованием]
- Нерешённые вопросы: [если есть]
```

### Шаг 5 — Анализ тестов + Verification

Обнови `pipeline_state.json`: `current_step: "critic-verification"`.

#### 5a — Failure Analyst (если есть упавшие тесты)

Прочитай `.i2c/scratch/impl-[N]-test-results.md`.

**Если есть строки со статусом FAIL:**
Для каждого упавшего теста запусти субагент с промптом из `~/i2c-agent-framework/agents/failure-analyst.md` — параллельно (все упавшие тесты в одном сообщении):

```
Для каждого FAIL в test-results.md:
  Передай субагенту:
    - docs/rfc/RFC-[N]-*.md
    - Код упавшего теста (читай из файла теста)
    - Stacktrace из test-results.md
    - Соответствующий файл реализации (определи по AC который тест покрывает)
    - Текст AC из RFC
```

Все агенты пишут блоки в один файл: `.i2c/scratch/failure-analysis-[N].md`

Дождись завершения всех Failure Analyst агентов.

**Если все тесты PASS** — пропусти этот шаг.

#### 5b — Critic (Verification)

Запусти субагент с промптом из `~/i2c-agent-framework/agents/critic.md`.

Передай ему:
- `docs/rfc/RFC-[N]-*.md` (с AC)
- `docs/impl/IMPL-[N]-[slug].md` (что планировалось)
- Все `impl-[N]-module-*-report.md`
- `.i2c/scratch/impl-[N]-test-results.md` (итоги тестов)
- `.i2c/scratch/failure-analysis-[N].md` (если были падения)
- Режим: "Verification"

Инструкция для Critic: учитывай результаты тестов и вердикты Failure Analyst:
- `PASS`-тест → AC считается покрытым с доказательством (приоритет над `[ПОДОЗРЕНИЕ]`)
- `FAIL` с вердиктом `CODE_BUG` → фиксируй как `[ТОЧНО]` в review
- `FAIL` с вердиктом `TEST_BUG` → не считай это проблемой кода
- `FAIL` с вердиктом `AMBIGUOUS` → выноси в "Открытые вопросы", не блокируй

Субагент читает реализованные файлы и пишет: `.i2c/scratch/impl-[N]-verification.md`

#### 5c — Обработка вердиктов

**Если VERIFIED:**
- Запиши в `.i2c/JOURNAL.md` что RFC-[N] реализован
- Обнови `pipeline_state.json`: `"status": "done"`
- Сообщи пользователю: список файлов, покрытые AC → терминальное состояние **SUCCESS**

**Если NEEDS_FIXES** (CODE_BUG в тестах или проблемы из кода):
- Увеличь `fixes_round` в `pipeline_state.json` на 1
- **Если `fixes_round >= 2`** → **HALT_FAILURE_BUDGET**
- **Иначе** — покажи список: что исправить в коде; спавни coding-агентов для проблемных модулей → повтори с шага 5 (тесты перезапускаются)

**Если NEEDS_TEST_FIX** (только TEST_BUG вердикты, код верный):
- Спавни test-writer агентов только для проблемных тестов
- Передай им: RFC + конкретные замечания из failure-analysis + что именно в тесте неверно
- После исправления тестов: повтори тест-раннер и Verification

**Если есть AMBIGUOUS вердикты:**
- Покажи пользователю: "В RFC неоднозначно описано следующее место: [цитата]"
- Спроси: уточнить RFC (`/i2c-update-prd` / ручная правка) или принять допущение?
- При "принять допущение": зафиксируй в JOURNAL.md и продолжи

**Если CRITICAL_GAPS:**
- Проверь долю: если FAIL у ≥50% модулей → **HALT_CRITICAL_GAPS**
- Иначе → предложи пересоздать Implementation Plan (`restart`) или Human-in-the-loop

---

### Терминальные состояния code-rfc

| Состояние | Условие | Сообщение пользователю |
|---|---|---|
| **SUCCESS** | Все AC прошли Verification | Список файлов, покрытые AC |
| **HALT_FAILURE_BUDGET** | `fixes_round >= 2` и NEEDS_FIXES | Что не починилось после 2 раундов; предложи запустить `/i2c-verify-rfc [N]` позже |
| **HALT_CRITICAL_GAPS** | CRITICAL_GAPS с FAIL у ≥50% модулей | RFC, возможно, не был готов к реализации; предложи пересмотреть RFC |
| **HALT_DEPENDENCY_DEADLOCK** | Pre-flight обнаружил что depends_on RFC не реализованы | Список незавершённых зависимостей |
| **HALT_POLICY_VIOLATION** | Coding-агент нарушил ограничения из MEMORY.md | Конкретное нарушение и файл |

При любом HALT: обнови `pipeline_state.json` → `"status": "halted"`, `"halt_reason": "[состояние]"`. Записывать в JOURNAL.md не нужно — только при SUCCESS.

**После завершения (только при SUCCESS):**
1. Обнови `.i2c/MEMORY.md` — добавь в таблицу "Принятые решения по компонентам": RFC-[N], ключевые решения, отклонения от спеки
2. Обнови RTM в `.i2c/MEMORY.md`: для всех строк где RFC = RFC-[N], установи статус `✅ Verified` (если VERIFIED) или `⚠️ Partial` (если были отклонения от AC)
3. Запиши в `.i2c/JOURNAL.md`:
   ```
   ## [дата] RFC-[N] реализован
   - Implementation Plan: docs/impl/IMPL-[N]-[slug].md
   - Файлы: [список]
   - AC: [N/M прошли]
   - Отклонения от RFC: [если были]
   - Tech debt: [если есть]
   ```

---

## Команда: `verify-rfc [N]`

Проверить что существующая реализация соответствует RFC. Полезно если код был написан вне фреймворка.

**Шаги:**
1. Прочитай `docs/rfc/RFC-[N]-*.md`
2. Спроси пользователя где находится реализация (если не очевидно из структуры проекта)
3. Запусти Critic в режиме Verification (Шаг 5 из `code-rfc`)
4. Выведи отчёт и запиши результат в JOURNAL.md

---

## Команда: `check`

Self-diagnostics: проверить консистентность всей документации.

**Шаги:**
1. Прочитай все документы из `docs/`
2. Запусти субагент с промптом из `~/i2c-agent-framework/diagnostics/review-checklist.md`
3. Субагент пишет отчёт: `.i2c/scratch/consistency-report.md`
4. Выведи summary: что консистентно, что конфликтует, что отсутствует

---

## Команда: `setup [/path/to/project]`

Инициализировать проект: создать state-структуру и подключить I2C фреймворк.

**Фреймворк НЕ копируется в проект.** Он живёт в `~/i2c-agent-framework/` и используется оттуда.

### Шаг 0 — Спроси тип проекта

```
[1] Новый проект    — чистый лист, MEMORY.md пустой, начнём с /i2c-create-prd
[2] Существующий    — есть код/документы, сначала аудит для заполнения MEMORY.md
```

Жди ответа. Дальнейшие шаги зависят от выбора.

---

### Ветка: Новый проект

#### Шаг 1 — Создать структуру `.i2c/`

```
<project>/.i2c/
  config.md              ← создать интерактивно
  MEMORY.md              ← из ~/i2c-agent-framework/templates/MEMORY.md
  GOALS.md               ← создать
  JOURNAL.md             ← создать
  pipeline_state.json    ← создать: {}
  scratch/               ← создать пустую папку
```

#### Шаг 2 — Создать `config.md` интерактивно

Задай пользователю вопросы и запиши ответы в `.i2c/config.md`:

```markdown
# Project Config

## Название проекта
[ответ пользователя]

## Домен / индустрия
[ответ пользователя]

## Цель проекта (одно предложение)
[ответ пользователя]

## Целевой пользователь
[ответ пользователя]

## Технические ограничения (стек, платформа, compliance)
[ответ пользователя]

## Временные рамки MVP
[ответ пользователя]
```

#### Шаг 3 — Создать файлы памяти

`MEMORY.md` — скопируй структуру из `~/i2c-agent-framework/templates/MEMORY.md`.

`GOALS.md`:
```markdown
# Project Goals

## Текущая стадия
Stage 0 — Инициализация

## Следующий шаг
Запустить `/i2c-create-prd`
```

`JOURNAL.md`:
```markdown
# Project Journal

## [дата] Проект настроен (/i2c-setup, новый проект)
- Конфигурация: .i2c/config.md
- Следующий шаг: /i2c-create-prd
```

`pipeline_state.json`: создай пустой файл `{}`.

#### Шаг 4 — Подключить к CLAUDE.md проекта

Проверь наличие `<project>/CLAUDE.md`:
- Если существует — добавь строку `@~/i2c-agent-framework/CLAUDE.md` в конец файла
- Если не существует — создай файл с содержимым:
  ```markdown
  # Project Instructions

  @~/i2c-agent-framework/CLAUDE.md
  ```

#### Шаг 5 — Сообщи пользователю

```
✅ I2C Framework инициализирован в <project>/

Создано:
  .i2c/config.md           — конфигурация проекта
  .i2c/MEMORY.md           — реестр принятых решений (пустой)
  .i2c/GOALS.md            — текущие цели
  .i2c/JOURNAL.md          — лог действий
  .i2c/pipeline_state.json — стейт пайплайна

Следующий шаг: /i2c-create-prd
```

---

### Ветка: Существующий проект

Проект уже содержит код и/или документацию. MEMORY.md нельзя оставить пустым — агенты начнут предлагать альтернативы для решений которые уже в продакшне.

#### Шаг 1 — Создать структуру `.i2c/`

То же что и для нового проекта, но `MEMORY.md` пока не заполнять — его заполнит Researcher.

#### Шаг 2 — Создать `config.md` интерактивно

Те же вопросы, но ответы берутся из реальности проекта, не из планов:
- "Цель проекта" — что он делает сейчас
- "Технические ограничения" — стек который уже используется
- "Временные рамки MVP" — можно опустить или указать "уже в продакшне"

#### Шаг 3 — Discovery: запустить Researcher

Запусти субагент с промптом из `~/i2c-agent-framework/agents/researcher.md` в режиме **Discovery**.

Передай ему:
- Путь к проекту
- Содержимое `.i2c/config.md`
- Инструкцию: "Режим Discovery. Проаудируй проект по адресу [путь]. Изучи структуру файлов, зависимости, конфигурацию. Заполни черновик MEMORY.md."

Субагент пишет: `.i2c/scratch/memory-draft.md`

#### Шаг 4 — Показать черновик пользователю

Выведи содержимое `.i2c/scratch/memory-draft.md` и секцию "Требует подтверждения".

```
Researcher проанализировал проект и нашёл следующие решения:

[содержимое memory-draft.md]

---
Пункты помеченные [ВЫВЕДЕНО] требуют твоего подтверждения.
Исправь или дополни если что-то неверно, затем подтверди.
```

Жди ответа. После подтверждения скопируй (с правками от пользователя) в `.i2c/MEMORY.md`.

#### Шаг 5 — Создать остальные файлы

`GOALS.md`:
```markdown
# Project Goals

## Текущая стадия
Stage 0 — Аудит существующего проекта

## Следующий шаг
Определить какие документы нужны: /i2c-status покажет что отсутствует
```

`JOURNAL.md`:
```markdown
# Project Journal

## [дата] Фреймворк подключён к существующему проекту (/i2c-setup)
- Конфигурация: .i2c/config.md
- MEMORY.md заполнен из аудита кодовой базы
- Требует подтверждения: [список пунктов [ВЫВЕДЕНО] если есть]
```

#### Шаг 6 — Подключить к CLAUDE.md проекта

Идентично ветке "Новый проект".

#### Шаг 7 — Сообщи пользователю

```
✅ I2C Framework подключён к <project>/

Создано:
  .i2c/config.md           — конфигурация проекта
  .i2c/MEMORY.md           — заполнен из аудита кодовой базы
  .i2c/GOALS.md            — текущие цели
  .i2c/JOURNAL.md          — лог действий
  .i2c/pipeline_state.json — стейт пайплайна

Следующий шаг: /i2c-status — посмотреть какие документы отсутствуют
```

---

## Правила оркестратора

- **Не пропускай Supervisor** — pre-flight обязателен перед каждым пайплайном, post-review — после Writer
- **Не пропускай Critic** — ни один черновик не идёт к Writer без критического разбора
- **MEMORY.md — закон** — если в MEMORY.md зафиксировано решение, агенты не переоткрывают его
- **Revision #1 — Writer, Revision #2 — Architect** — первый фидбек идёт Writer, если не помогло — Architect переделывает черновик с нуля (+ Critic + Writer)
- **Human-in-the-loop — последний resort** — человек привлекается только после двух неудачных итераций
- **Финальный файл — только после ACCEPTED** — документ не попадает в `docs/` пока Supervisor не принял
- **Обновляй pipeline_state.json на каждом шаге** — это единственный механизм resume
- **Scratch — временный** — файлы в `.i2c/scratch/` не коммитятся
- **Один документ за раз** — не запускай параллельно create-prd и create-rfc
- **Всегда обновляй JOURNAL.md** — каждое завершённое действие фиксируется, паттерны от Supervisor — тоже
