# Context Recovery Schema

Этот файл описывает как восстановить контекст для точного выполнения задачи. Единый источник правды: **задача → упорядоченные входы → word-бюджет → lazy-условия**.

**Когда читать:**
- **Оркестратор — обязательно в начале КАЖДОГО шага пайплайна**, до формирования промпта субагенту. Это не fallback "на случай если", а основной механизм работы оркестратора. Оркестратор — stateless interpreter между шагами: всё критичное на диске, перед каждым шагом читается заново.
- **Субагенты этот файл НЕ читают.** Они получают нужные входы уже собранными от оркестратора в промпте. Субагент — stateless function, не может и не должен самодиагностировать потерю контекста.

**Почему это работает при компактизации контекста.**
Claude Code и Qwen Code автоматически сжимают историю в длинных сессиях. Оркестратор не держит критичное состояние в памяти — всё на диске (`pipeline_state.json`, `context-schema.md`, `MEMORY.md`, scratch-файлы). После компактизации компактный summary ("идёт create-prd, шаг 3") достаточен: оркестратор снова открывает диск и загружает свежие данные. Компактизация становится транзпарентной.

**Как кастомизировать:** этот файл принадлежит проекту. Правь его под специфику: добавляй новые задачи, корректируй бюджеты, уточняй lazy-условия.

---

## Универсальные входы (для всех задач)

- `.i2c/MEMORY.md` § Tech Stack, § Rules — всегда (~300 слов)
- `.i2c/dependency-graph.json` — всегда, для lookup связей между артефактами

---

## create-prd

**Budget:** ~1500 слов.

- `.i2c/config.md` (full)
- `.i2c/MEMORY.md` § User Profile, § Scope (если есть)
- `templates/PRD.md` (структура)
- Для Clarification Loop: `.i2c/scratch/prd-answers-r*.md` (все круги, если есть)

**Lazy:** —

---

## create-adr [name]

**Budget:** ~2500 слов.

- Заголовки H1/H2 всех существующих `docs/ADR-*.md`
- `docs/PRD.md` (full)
- `.i2c/engineering-practices.md` (full, ≤400 слов) — **обязательно**
- `.i2c/MEMORY.md` § Decisions, § Tech Stack
- `.i2c/GOALS.md` § "Запланированные ADR" — подсказка о месте в roadmap
- `templates/ADR.md`

**Lazy:** полный текст конкретного ADR только при явной ссылке из Supervisor Pre-flight.

---

## create-rfc [component]

**Budget:** ~4000 слов.

- Все `docs/ADR-*.md` (full) — источник решений
- `docs/PRD.md` § MVP, § Scenarios
- `.i2c/engineering-practices.md` (full)
- `.i2c/MEMORY.md` § Decisions, § Tech Stack, § Rules, § RTM
- Upstream RFC из dependency-graph (только прямые зависимости)
- `templates/RFC.md`

**Lazy:** RFC вне цепочки зависимостей — только при триггере consistency check.

---

## code-rfc [N] — Planning фаза (Architect)

**Budget:** ~3000 слов.

- `docs/rfc/RFC-[N]-*.md` (full) — source of truth
- `docs/impl/IMPL-*.md` для upstream dependencies (только секция AC coverage)
- `.i2c/engineering-practices.md` (full)
- `.i2c/MEMORY.md` § Tech Stack, § Rules, § RTM
- `protocols/code-quality.md`

**Lazy:** `protocols/secure-code.md` только при наличии секции безопасности в RFC.

---

## code-rfc [N] — Coding фаза (Coder per-module)

**Budget:** ~1500 слов. **Критично:** контекст длинный, компактность обязательна.

- `rfc-[N]-ac-checklist.md` (≤200 слов) — основа
- Задача из плана (1 модуль, ≤300 слов)
- `.i2c/engineering-practices.md` (≤400 слов) — **обязательно**
- `.i2c/MEMORY.md` § Rules (только, не вся)
- Целевые файлы для редактирования

**Lazy:** полный RFC только если `ac-checklist` флагнул `[NEEDS CLARIFICATION]`.

---

## code-rfc [N] — Test Writing фаза

**Budget:** ~2000 слов. Test Writer **НЕ читает реализацию**.

- `docs/rfc/RFC-[N]-*.md` (full) — единственный источник
- `test-[N]-plan.md` (≤400 слов)
- `.i2c/engineering-practices.md` § Testing (если секция есть)
- `.i2c/MEMORY.md` § Rules (правила тестирования)

**Lazy:** —

---

## auto [--from=rfc|code]

**Budget:** ~800 слов (meta-loop, большинство работы делегируется inner sub-pipelines).

- `.i2c/dependency-graph.json` — **обязательно**, основной источник очереди
- `.i2c/auto_state.json` — состояние meta-loop (создать если нет)
- `.i2c/pipeline_state.json` — состояние inner sub-pipeline (может быть пустым между итерациями)
- `docs/PRD.md` — для предусловий и передачи в inner sub-pipelines
- `.i2c/engineering-practices.md` — для передачи в inner sub-pipelines
- `.i2c/GOALS.md` — проверка что ADR backlog пуст (для `--from=rfc`)
- `.i2c/MEMORY.md` § Tech Stack, § Rules

**Lazy:** содержимое конкретных ADR/RFC — читается inner sub-pipelines через их собственные секции этой схемы (create-rfc, code-rfc).

**State-machine flow:** re-read всех перечисленных выше файлов в начале **каждой** итерации meta-loop (см. `protocols/auto-pipeline.md`). Не держи в памяти между итерациями.

---

## verify-rfc / verification cycle

**Budget:** ~2500 слов.

- `docs/rfc/RFC-[N]-*.md` (full) — arbiter
- Test results (compact)
- Implementation reports (compact)
- Относящаяся секция `ac-checklist.md`

**Lazy:** исходный код только под конкретный FAIL, таргетно.

---

## update-prd / update-adr / update-rfc

**Budget:** как у соответствующего create-*, минус Researcher (контекст уже есть). Добавь:
- Текущий артефакт (full)
- Описание изменения из аргумента команды
- Downstream артефакты (для warning о breaking changes) — только заголовки

---

## patch-rfc [N]

**Budget:** ~2500 слов (меньше чем full code-rfc — работаем на дельте).

- `docs/rfc/RFC-[N]-*.md` (full) — обновлённый
- `docs/impl/IMPL-[N]-*.md` — оригинальный план
- `impl-[N]-verification.md` (если есть) — что уже прошло
- `.i2c/engineering-practices.md`
- `.i2c/MEMORY.md` § Rules

**Lazy:** коды модулей — только те что в `patch-plan.new_ac` или `changed_interface`.

---

## Правила интерпретации

- **Budget — ориентир, не абсолют.** Если вход «full» раздувает контекст, оркестратор может запрашивать секции вместо целых файлов.
- **"Обязательно" значит обязательно.** Если в списке стоит без слова "lazy" — этот вход должен быть передан агенту.
- **Lazy-вход грузится по триггеру.** Триггер указан явно.
- **При расхождении с командой в orchestrator.** Этот файл — авторитетный источник. Команды в orchestrator-source.md постепенно будут делегировать чтение списка входов сюда.
