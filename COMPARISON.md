# Сравнение: I2C vs Spec Kit vs BMAD-METHOD

Три ведущих фреймворка для Spec-Driven Development с AI-агентами. Честное сравнение по состоянию на март 2026.

---

## Обзор

| | **I2C** | **Spec Kit** (GitHub) | **BMAD-METHOD** |
|---|---|---|---|
| Подход | Документ → Код через специализированный конвейер агентов | Specify → Plan → Tasks → Implement | Agile-команда из AI-персон |
| Поддерживаемые IDE | Claude Code, Qwen Code | 25+ (Claude, Copilot, Cursor, Gemini, Kiro...) | Claude Code, Cursor |
| Лицензия | MIT | MIT | MIT |
| GitHub stars | — | ~83,000 | ~42,600 |
| Бэкинг | Indie | GitHub (Microsoft) | Community |

---

## Архитектура и workflow

### Spec Kit

```
Constitution → Specify → Plan → Tasks → Implement
```

- **Constitution** — неизменный документ верхнего уровня (стиль кода, NFR, архитектурные правила)
- Каждая спека генерирует набор markdown-файлов (data-model, plan, tasks, research, API)
- Agent-agnostic: slash-команды работают в любом поддерживаемом IDE
- Git-ветки per specification
- 40+ community extensions
- Token budget: 200K на сессию

### BMAD-METHOD

```
Analysis → Planning → Architecture → Implementation
```

- 21 специализированная AI-персона (Product Manager, Architect, Developer, QA...)
- "Party Mode" для multi-agent collaboration
- Scale-adaptive: автоматически регулирует глубину планирования
- Полное покрытие agile-цикла от брейнсторма до деплоя
- YAML-конфиг, CLI-команды

### I2C

```
PRD → ADR → RFC → Implementation Plan → Code + Tests → Verification
```

- 7 специализированных агентов с чёткими ролями (Supervisor, Researcher, Architect, Critic, Writer, Test Writer, Failure Analyst)
- Каждый документ проходит конвейер: Supervisor → [Researcher] → Architect → Critic → Writer → Supervisor
- `MEMORY.md` как единый источник истины — принятые решения не переоткрываются
- Pipeline state для resume прерванных сессий
- Verification Cycle: тесты пишутся из RFC (не из кода), Failure Analyst анализирует падения

---

## Ключевые отличия

### Что делает Spec Kit лучше

- **Экосистема:** 25+ IDE, 40+ extensions, 83K stars. Самое большое сообщество.
- **Простота старта:** 1-2 дня на освоение. Установка через `uv`, slash-команды сразу работают.
- **Agent-agnostic:** работает с любым AI-ассистентом, не привязан к Claude.
- **Constitution:** явный документ для cross-cutting concerns (стиль, NFR), которые не теряются между спеками.

### Что делает BMAD лучше

- **Масштабируемость процесса:** scale-adaptive intelligence — от баг-фиксов до enterprise-систем.
- **Полнота agile-цикла:** 21 персона покрывает весь lifecycle, включая QA и deployment.
- **Гибкость ролей:** можно добавлять/настраивать персоны под команду.
- **Сообщество:** активный Discord, masterclass-серия, обширная документация.

### Что делает I2C лучше

- **Critic как архитектурный инвариант:** ни один документ не становится финальным без критического разбора. В Spec Kit и BMAD ревью — опциональный шаг.
- **Verification Cycle:** Test Writer пишет тесты из RFC **не видя реализацию** (тест = контракт). Failure Analyst анализирует каждый упавший тест (CODE_BUG / TEST_BUG / AMBIGUOUS). RFC — единственный арбитр при расхождении теста и кода. У конкурентов нет аналога.
- **Pipeline resume:** `pipeline_state.json` позволяет продолжить с точки прерывания. Spec Kit и BMAD теряют контекст при обрыве сессии.
- **MEMORY.md как закон:** зафиксированные решения не переоткрываются последующими агентами. Предотвращает "архитектурный дрейф" в длинных проектах.
- **Протокол ревизий:** Writer #1 → Architect #2 → Human-in-the-loop. Эскалация структурирована, человек привлекается только после двух неудач.
- **Минимальный footprint:** устанавливается в конкретный проект, не загрязняет глобальный конфиг. Оркестратор загружается on-demand.

---

## Честные слабые стороны

### I2C

- **Узкая поддержка IDE:** только Claude Code и Qwen Code. Нет Cursor, Copilot, Gemini.
- **Нет сообщества:** indie-проект без community extensions и Discord.
- **Нет Constitution-аналога:** cross-cutting concerns (стиль кода, NFR) не вынесены в отдельный документ — они размазаны по ADR и MEMORY.md.
- **Жёсткий конвейер:** каждый документ проходит полный pipeline (5-6 агентов). Для мелких изменений это overkill.
- **Нет scale-adaptive:** одинаковая глубина планирования для бага и enterprise-фичи.

### Spec Kit

- **Overkill для малого:** Martin Fowler отметил, что фикс бага генерирует страницы markdown.
- **Faux context:** сгенерированные спеки часто дублируют информацию без реальной глубины (Scott Logic).
- **Агенты игнорируют спеки:** агенты часто не следуют детальным инструкциям из спецификации.
- **Нет Verification Cycle:** после реализации нет структурированной проверки кода против AC.
- **Потеря контекста:** каждая новая сессия стартует с нуля.

### BMAD-METHOD

- **Крутая кривая обучения:** ~2 месяца на продвинутые техники.
- **Error propagation:** если один агент выдал ошибочный артефакт, downstream-агенты могут не обнаружить ошибку.
- **Overkill для малых команд:** 21 персона и 50+ workflows для проекта на 1-2 человека — чрезмерно.
- **Нет встроенного Verification:** как и Spec Kit, нет аналога Failure Analyst / Verification Cycle.

---

## Когда что выбрать

| Ситуация | Рекомендация |
|----------|-------------|
| Команда из 5+ разработчиков с разными IDE | **Spec Kit** — agent-agnostic, большое сообщество |
| Enterprise с полным agile-процессом | **BMAD** — 21 персона, scale-adaptive, CI/CD |
| Один разработчик / малая команда с Claude Code | **I2C** — лёгкий, pipeline resume, MEMORY.md как source of truth |
| Проект где корректность критична (fintech, healthcare) | **I2C** — Verification Cycle, Failure Analyst, RFC-as-arbiter |
| Быстрый прототип / hackathon | **Spec Kit** — быстрый старт, минимальный overhead |
| Brownfield (существующий код) | **I2C** — Discovery mode, verify-rfc для существующего кода |

---

## Матрица фич

| Фича | I2C | Spec Kit | BMAD |
|------|-----|----------|------|
| Specification → Code pipeline | ✅ | ✅ | ✅ |
| Multi-agent architecture | ✅ 7 агентов | ❌ single-agent | ✅ 21 персона |
| Обязательный Critic/Review | ✅ инвариант | ❌ опционально | ⚠️ зависит от настройки |
| Verification Cycle (тесты из спеки) | ✅ | ❌ | ❌ |
| Failure Analyst | ✅ | ❌ | ❌ |
| Pipeline resume | ✅ | ❌ | ❌ |
| Memory / Decision log | ✅ MEMORY.md | ⚠️ Constitution (частично) | ⚠️ артефакты (частично) |
| Constitution / NFR document | ❌ | ✅ | ⚠️ через персоны |
| Agent-agnostic (25+ IDE) | ❌ 2 IDE | ✅ | ⚠️ 2-3 IDE |
| Scale-adaptive depth | ❌ | ❌ | ✅ |
| Extension system | ❌ | ✅ 40+ | ⚠️ через персоны |
| Community & ecosystem | ❌ | ✅✅ | ✅ |
| Brownfield support | ✅ Discovery | ⚠️ | ⚠️ |

---

*Источники: [GitHub Spec Kit](https://github.com/github/spec-kit), [BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD), [Martin Fowler: Understanding SDD](https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html), [Scott Logic: Putting Spec Kit Through Its Paces](https://blog.scottlogic.com/2025/11/26/putting-spec-kit-through-its-paces-radical-idea-or-reinvented-waterfall.html)*
