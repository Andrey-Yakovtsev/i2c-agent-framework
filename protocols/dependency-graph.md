# Протокол: Dependency Graph

Машиночитаемый граф зависимостей между артефактами проекта. Хранится в `.i2c/dependency-graph.json`.

## Схема

```json
{
  "version": 1,
  "nodes": {
    "<ID>": { "type": "prd|adr|rfc|impl", "path": "docs/...", "status": "..." }
  },
  "edges": [
    { "from": "<ID>", "to": "<ID>", "type": "<тип>" }
  ],
  "last_updated": "<ISO 8601>"
}
```

**ID артефактов:** `PRD`, `ADR-NNN`, `RFC-NNN`, `IMPL-NNN`.

**Типы edges** (направление: from зависит от to):

| Тип | From → To | Пример |
|-----|-----------|--------|
| `implements_requirement` | ADR → PRD | ADR реализует требование из PRD |
| `implements_decision` | RFC → ADR | RFC использует решение из ADR |
| `depends_on` | RFC → RFC | RFC зависит от другого RFC |
| `implements` | IMPL → RFC | Реализация по спецификации RFC |

## Операции

### Запись

- **add_node(id, type, path, status)** — добавить артефакт в граф
- **add_edge(from, to, type)** — добавить зависимость
- **remove_node(id)** — удалить артефакт и все его edges
- **update_status(id, status)** — обновить статус node
- Всегда обновляй `last_updated`

### Чтение

- **get_downstream(id)** — все nodes, у которых есть edge TO данного id (кто зависит от него). Рекурсивно для транзитивных.
- **get_upstream(id)** — все nodes, на которые id ссылается через edges FROM (от чего он зависит). Рекурсивно для транзитивных.

### Каскадное оповещение

**flag_for_review(ids[], reason, source_id):**
1. Для каждого id из списка добавь запись в MEMORY.md "Технический долг":
   `| TD-XXX | [id] требует пересмотра: [reason] | [source_id] | high | [дата] |`
2. Выведи пользователю список затронутых артефактов + рекомендуемые команды

## Правила каскада

**Вниз (downstream):**
- ADR breaking change → `flag_for_review` для всех downstream RFC + их IMPL
- RFC изменился → `flag_for_review` для всех downstream IMPL + RFC с `depends_on`

**Вверх (upstream):**
- IMPL verification → AMBIGUOUS вердикт указывает на неопределённость в RFC → предложи `/i2c-impact RFC-[N]`
- Если проблема прослеживается до ADR → предложи `/i2c-update-adr [N]`

**Принцип:** граф только оповещает и предлагает команды. Документы не перезаписываются автоматически.

## Формат вывода impact

```markdown
# Impact Analysis: [artifact-id]

## Downstream (зависят от [id])
- [ID]: [path] — [тип связи] → **требует пересмотра**

## Upstream ([id] зависит от)
- [ID]: [path] — [тип связи]

## Транзитивные (через промежуточные)
- [ID] (через [промежуточный]) — **возможное влияние**

## Рекомендуемый порядок обновления
1. `/i2c-update-...` ← текущее
2. `/i2c-update-...` ← далее
```

При `--cascade` порядок определяется топологической сортировкой downstream nodes.

## Инициализация (rebuild)

1. Просканируй `docs/PRD.md`, `docs/ADR-*.md`, `docs/rfc/RFC-*.md`, `docs/impl/IMPL-*.md`
2. Для каждого файла создай node (id из имени, type из префикса, status из метаданных)
3. Парси метаданные:
   - ADR "Связанные решения" → edges `implements_decision` или `implements_requirement`
   - RFC "Зависит от" → edges `depends_on`
   - RFC "Блокирует" → обратный edge `depends_on` (от заблокированного к текущему)
   - RFC "Связанные решения" → edges `implements_decision` к ADR
   - IMPL → edge `implements` к RFC по номеру
4. Проверь: нет ли ссылок на несуществующие документы → выведи предупреждения
5. Запиши `.i2c/dependency-graph.json`
