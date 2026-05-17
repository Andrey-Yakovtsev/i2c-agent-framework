# Протокол: Feature Mode

Дельта режима `MODE: feature` команды `code` — добавление новой фичи в
**уже реализованный** код RFC-N по свободному описанию. Механика конвейера —
как у `patch` в `code-pipeline.md`; ниже только отличия.

## Параметры

| Параметр | Значение |
|----------|----------|
| `MODE` | `feature` |
| `N` | Номер RFC, в код которого добавляется фича |
| `PREFIX` | `feat-[N]` |
| `DESC` | Описание фичи (из аргумента `--feature N "описание"`) |

## Шаг 0 — Supervisor Pre-flight (feature)

Передай: `DESC` + RFC-[N] + `IMPL-[N]` + MEMORY.md.

Проверки:
- RFC-[N] ACCEPTED и имеет реализацию (`IMPL-[N]` существует)? Нет → SKIP
  («сначала `/i2c-code --rfc N`»).
- Фича вписывается в scope RFC-N, а не относится к другому компоненту?
- **Масштаб — вердикт REDIRECT.** Если фича: подразумевает новое
  архитектурное решение; даёт >6 новых AC; затрагивает несколько
  компонентов/RFC; или ломает публичный контракт — верни **REDIRECT**
  с предложением `/i2c-create-adr` или `/i2c-create-rfc`. Не запускай пайплайн.

Feature-режим не вызывается из `/i2c-auto` (auto работает только с RFC).

## Шаг 1 — Architect (Feature Planning)

Один субагент `agents/architect.md`, режим «Feature Planning».
Передай: `DESC` + RFC-[N] + `IMPL-[N]` + MEMORY.md.
Architect синтезирует новые AC из описания, классифицирует элементы как
`new_ac` / `changed_interface`, явно перечисляет `unchanged`.
Пишет: `.i2c/scratch/feat-[N]-plan.md` (формат — как Patch Plan).

## Шаги 2–5 — как `patch`

Critic (Planning), Writer, Coding + test-writer, Verification — по
`code-pipeline.md` с механикой `patch`:
- env bootstrap (Шаг 3.5) **пропускается** — окружение уже поднято;
- coding-агенты расширяют код, не перезаписывают `unchanged`;
- test-writer пишет тесты только для `new_ac`;
- тест-раннер прогоняет полный сюит (проверка регрессий);
- Verification проверяет новые AC; existing + CODE_BUG = регрессия.

## После SUCCESS

Шаг «После SUCCESS» из `code-pipeline.md` отрабатывает как для `patch`
(включая `## История изменений` в `IMPL-[N]`). Дополнительно:
1. § RTM MEMORY.md — добавь строки для новых AC фичи.
2. § Tech Debt MEMORY.md — запись: `RFC-[N] spec отстаёт от IMPL: фича
   "[DESC]" реализована напрямую` (источник — feature, приоритет P2).
3. Сообщи пользователю: рекомендуется `/i2c-update-rfc [N]`, чтобы
   привести спецификацию RFC-N в соответствие с реализованным кодом.
