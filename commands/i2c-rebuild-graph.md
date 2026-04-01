---
name: i2c-rebuild-graph
description: Rebuilds dependency graph from existing documents
---
Перестроить граф зависимостей из существующих документов в `docs/`.

Сканирует все ADR, RFC и IMPL файлы, парсит метаданные (Зависит от, Блокирует, Связанные решения)
и генерирует `.i2c/dependency-graph.json`. Полезно для инициализации графа в существующем проекте
или синхронизации после ручных правок документов.

**Аргументы:** не требуются.
**Пример:** `/i2c-rebuild-graph`

Прочитай файл {{FRAMEWORK_DIR}}/orchestrator.md (используй Read tool) и выполни команду `rebuild-graph` по инструкциям из этого файла.
