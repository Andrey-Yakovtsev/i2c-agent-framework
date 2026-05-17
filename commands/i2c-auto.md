---
name: i2c-auto
description: Autonomous cycle — creates all planned RFCs and implements them end-to-end
---
Meta-команда для автономного цикла разработки: создаёт все planned RFC и реализует их через `code`, секвенциально, в топологическом порядке зависимостей, без ручных подтверждений.

**Когда использовать:** после того как PRD и все нужные ADR уже приняты. Команда пройдёт по оставшимся RFC и коду до конца или до HALT.

**Неявно включает `--auto` семантику** для всех внутренних вызовов `code` — отдельно передавать флаг не нужно.

**Аргументы (все опциональные):**
- `--from=rfc` (default) — создаёт все planned RFC, затем реализует каждый.
- `--from=code` — только реализация: все уже accepted RFC без IMPL прогоняются через `code`.
- `--halt-on-clarify` — если Supervisor Pre-flight вернёт CLARIFY, вместо конвертации в APPROVE_WITH_ASSUMPTIONS halt с просьбой ответить вручную.

**Примеры:**
- `/i2c-auto` — полный цикл от planned RFC до кода
- `/i2c-auto --from=code` — только реализация уже созданных RFC
- `/i2c-auto --halt-on-clarify` — более осторожный режим

**Отличие от `--auto` флага:**
- `/i2c-code --rfc N --auto` — один RFC без permission-prompts
- `/i2c-auto` — цепочка всех оставшихся RFC до конца

Прочитай файл {{FRAMEWORK_DIR}}/orchestrator.md (используй Read tool) и выполни команду `auto $ARGUMENTS` по инструкциям из этого файла.
