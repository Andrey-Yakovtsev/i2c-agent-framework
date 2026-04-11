# Протокол: ADR Roadmap (Initial Cut)

Автоматически генерирует **начальный** список кандидатов-ADR после финализации PRD и `engineering-practices.md`. Первый cut, не финал — по мере создания каждого ADR могут всплывать новые кандидаты. Вызывается из `create-prd` "После завершения".

## Вход

- `docs/PRD.md`
- `.i2c/engineering-practices.md`
- `.i2c/MEMORY.md`

## Шаг 1 — Architect (режим "ADR Roadmap")

Запусти `agents/architect.md` в режиме "ADR Roadmap". Передай: PRD + practices + MEMORY.md.

Задача: предложить список тем для ADR (не сами ADR, а заголовки + 1 строка обоснования).

**Категории для обязательного рассмотрения** (если релевантно стеку из MEMORY.md):

- Persistence: выбор БД, транзакции, миграции
- Auth & session store: SSO, сессии, токены
- Deployment target & environment topology: контейнеры, оркестратор, окружения
- Observability stack: logs / metrics / traces
- Integration protocol: HTTP / events / queue
- Error handling & retry policy
- Secrets management

Architect фильтрует: оставляй только то что имеет смысл для scope PRD и стека. Избыточное для MVP — исключай.

**Формат вывода:** `.i2c/scratch/adr-roadmap.md`

```markdown
# ADR Roadmap (initial cut)

| Приоритет | Тема ADR | Обоснование (1 строка) |
|-----------|----------|------------------------|
| P1 | Выбор основной БД | Ключевое решение, блокирует data-model RFC |
| P1 | Стратегия аутентификации | Блокирует auth RFC и session store |
| P2 | Observability stack | Необходимо до production, после MVP |
```

Максимум 15 строк. Приоритеты: P1 (нужен до первого RFC), P2 (до production), P3 (позже).

## Шаг 2 — Обновление GOALS.md

Слей содержимое в секцию "Запланированные ADR (initial cut)" в `GOALS.md`. Каждая строка:

```
- [ ] ADR: [тема] [P1|P2|P3] — [обоснование]
```

Добавь в начало секции disclaimer:

> **Это первоначальный список, сформированный из PRD и engineering practices. По мере принятия ADR могут появляться новые кандидаты. Список можно править вручную.**

## Рост backlog

Не требует отдельной команды. После каждого принятого ADR оркестратор перечитывает его секции "Последствия" → "Что это открывает" и "Триггеры пересмотра" и, если находит упомянутые там решения, требующие отдельного ADR, дописывает их в GOALS.md § "Запланированные ADR" (см. `orchestrator-source.md`, команда `create-adr`, шаг 2 "После завершения"). Автоматический рост через planned-nodes в графе зависимостей — out of scope (ADR — обсуждение, не компонент).

## Отличие от rfc-roadmap

`rfc-roadmap.md` создаёт **planned-nodes в графе зависимостей** после каждого ACCEPTED ADR (так как RFC — это конкретные компоненты). `adr-roadmap.md` использует **GOALS.md как носитель** — ADR-темы это темы для обсуждения, граф ими засорять не нужно.
