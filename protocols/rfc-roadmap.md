# Протокол: RFC Roadmap (Planned Nodes)

Расширение dependency-graph для хранения **запланированных** (ещё не созданных) RFC.

## Расширение схемы

Node получает поле `status`:

```json
{
  "<ID>": {
    "type": "prd|adr|rfc|impl",
    "path": "docs/...",
    "status": "planned|draft|accepted|superseded"
  }
}
```

**Обратная совместимость:** nodes без `status` считаются `accepted`.

Новый тип edge:

| Тип | From → To | Пример |
|-----|-----------|--------|
| `planned_by` | planned RFC → ADR | ADR предложил этот RFC |

## Операции

### add_planned_nodes(adr_id, rfc_list)

Вызывается после ACCEPTED ADR (если есть секция "Необходимые RFC").

Для каждого RFC из таблицы:
1. Создай node: `id` = `RFC-[next_N]`, `type` = `rfc`, `path` = `—`, `status` = `planned`
2. Создай edge: `from` = RFC-id, `to` = adr_id, `type` = `planned_by`
3. Если RFC зависит от другого planned RFC → edge `depends_on`
4. Сохрани `description` в node (краткое описание из таблицы ADR)

### promote_node(id)

Вызывается при старте `create-rfc` для planned RFC:
1. `status`: `planned` → `draft`
2. `path`: обновляется на реальный путь
3. При завершении create-rfc: `status` → `accepted`

### Отображение в status/impact

- `/i2c-status`: покажи planned RFC отдельной секцией
- `/i2c-impact`: planned nodes включаются в downstream с пометкой `(planned)`
- `/i2c-rebuild-graph`: не затрагивает planned nodes (нет файлов для парсинга); при rebuild planned nodes, не имеющие файла, сохраняются

## Обновление GOALS.md

После `add_planned_nodes` обнови GOALS.md:

```
## Запланированные RFC (из ADR-[N])
1. RFC-[M]: [компонент] — [описание]
2. RFC-[M+1]: [компонент] — [описание] (зависит от RFC-[M])

Следующий шаг: `/i2c-create-rfc [компонент]`
```
