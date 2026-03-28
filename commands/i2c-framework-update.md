Обновить I2C фреймворк до последней версии.

Скачивает обновления из git-репозитория фреймворка и переустанавливает в текущий проект.
State-файлы (.i2c/config.md, MEMORY.md, GOALS.md, JOURNAL.md, pipeline_state.json) сохраняются.

**Аргументы:** не требуются.
**Пример:** `/i2c-framework-update`

Выполни следующие шаги:
1. Прочитай файл `.i2c/framework/.source` — это путь к git-репозиторию фреймворка
2. Запусти `cd <source_path> && git pull` (используй Bash tool)
3. Определи target по наличию директорий: если есть `.claude/` → `--target=claude`, если `.qwen/` → `--target=qwen`
4. Запусти `<source_path>/install.sh <путь к проекту> --target=<target>` (используй Bash tool)
5. Покажи пользователю changelog: `cd <source_path> && git log --oneline -10`
