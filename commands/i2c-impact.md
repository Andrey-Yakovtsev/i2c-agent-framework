---
name: i2c-impact
description: Analyzes dependency impact of an artifact change
---
Показать граф зависимостей артефакта — что затронет его изменение.

Выводит upstream (от чего зависит) и downstream (что зависит от него) артефакты,
включая транзитивные зависимости. С флагом `--cascade` предлагает порядок обновления.

**Аргументы:** `[artifact-id]` (например `ADR-001`, `RFC-002`), опционально `--cascade`.
**Пример:** `/i2c-impact ADR-001` или `/i2c-impact RFC-002 --cascade`

Прочитай файл {{FRAMEWORK_DIR}}/orchestrator.md (используй Read tool) и выполни команду `impact` по инструкциям из этого файла.
