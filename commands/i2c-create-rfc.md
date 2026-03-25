Создать RFC (Request for Comments) для одного компонента системы.

Запускает: Supervisor → Researcher → Architect → Critic → Writer → Supervisor.
Результат сохраняется в `docs/rfc/RFC-NNN-slug.md`.
Один RFC = один компонент. Нельзя создавать RFC раньше его зависимостей.

**Аргумент:** название компонента (обязательно).
**Пример:** `/i2c-create-rfc Core Data Model` или `/i2c-create-rfc Payment Processing`

Если `$ARGUMENTS` пуст — спроси пользователя: "Введи название компонента для RFC (например: 'Core Data Model', 'Auth Service', 'Payment Pipeline'):"
Дождись ответа и используй его как аргумент.

Выполни команду I2C `create-rfc $ARGUMENTS` из инструкций оркестратора.
