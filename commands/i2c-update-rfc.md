---
name: i2c-update-rfc
description: Updates RFC after upstream ADR changes or requirement changes
---
Обновить RFC после изменения вышестоящего ADR или требований.

Агент сам читает обновлённый ADR (через dependency-graph upstream edges) и определяет что изменилось.
Описание изменений не требуется — агент выводит его из секции "История изменений" ADR.

Конвейер: Architect → Critic → Writer → Supervisor (без Researcher).
После одобрения обновляет RFC, очищает запись Tech Debt, проверяет downstream IMPL.

**Аргумент:** номер RFC (обязательно).
**Пример:** `/i2c-update-rfc 3`

Если `$ARGUMENTS` пуст — спроси пользователя: "Введи номер RFC для обновления (например: '3'):"
Дождись ответа и используй его как аргумент.

Прочитай файл {{FRAMEWORK_DIR}}/orchestrator.md (используй Read tool) и выполни команду `update-rfc $ARGUMENTS` по инструкциям из этого файла.
