# Протокол: Verification Cycle

Анализ тестов и верификация реализации. Используется в `code-rfc`, `patch-rfc`, `verify-rfc`.

## 5a — Failure Analyst (если есть FAIL)

Прочитай test-results. Для каждого FAIL запусти `agents/failure-analyst.md` **параллельно**.
Передай каждому: RFC, код теста, stacktrace, файл реализации, текст AC.
**patch:** добавь тип теста (existing/new). existing + CODE_BUG = регрессия.
Все пишут в один файл: `.i2c/scratch/{PREFIX}-failure-analysis.md`

Если все PASS → пропусти.

## 5b — Critic (Verification)

Запусти `agents/critic.md`, режим "Verification".
Передай: RFC (AC), план реализации, отчёты модулей, test-results, failure-analysis (если были).

Правила интерпретации:
- PASS-тест → AC покрыт (приоритет над [ПОДОЗРЕНИЕ])
- FAIL + CODE_BUG → [ТОЧНО], блокирует
- FAIL + TEST_BUG → не проблема кода
- FAIL + AMBIGUOUS → "Открытые вопросы", не блокирует
- **patch:** unchanged-AC не проверять; сверять против обновлённого RFC

Пишет: `.i2c/scratch/{PREFIX}-verification.md`

## 5c — Обработка вердиктов

**VERIFIED** → SUCCESS.

**NEEDS_FIXES** (CODE_BUG):
- `fixes_round += 1`. Если `>= 2` → HALT_FAILURE_BUDGET.
- Иначе → спавни coding-агентов для проблемных модулей → повтори с шага 5 (тесты перезапускаются).

**NEEDS_TEST_FIX** (только TEST_BUG):
- Спавни test-writer для проблемных тестов + замечания из failure-analysis.
- После исправления → повтори тест-раннер и Verification.

**AMBIGUOUS:**
- Покажи пользователю спорное место из RFC.
- Спроси: уточнить RFC или принять допущение? При допущении → фиксация в JOURNAL.md.

**CRITICAL_GAPS** (FAIL ≥50% модулей):
- HALT_CRITICAL_GAPS. Предложи пересоздать план или Human-in-the-loop.
