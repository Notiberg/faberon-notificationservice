# Быстрое исправление ошибки миграций на Railway

## Проблема
```
[ERROR] Failed to fetch pending notifications: repository: failed to execute SQL query: 
GetPendingNotifications - execute query: pq: relation "notifications" does not exist
```

## Решение (3 шага)

### 1. Убедитесь, что в Railway установлены ВСЕ переменные окружения:

```
DB_HOST=postgres.railway.internal
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=<ваш-пароль>
DB_NAME=smc_notificationservice
DB_SSLMODE=require
TELEGRAM_BOT_TOKEN=<ваш-токен>
HTTP_PORT=8085
LOG_LEVEL=info
LOG_FILE=/app/logs/app.log
USERSERVICE_URL=<url-userservice>
USERSERVICE_TIMEOUT=10
WORKER_PROCESSOR_INTERVAL=30
WORKER_PROCESSOR_BATCH_SIZE=50
METRICS_ENABLED=true
```

**ВАЖНО:** Все переменные должны быть установлены, иначе приложение не запустится!

### 2. Пересоберите и переразвёртните контейнер на Railway

Просто нажмите "Redeploy" в Railway или сделайте новый push в репозиторий.

### 3. Проверьте логи

В логах Railway должны появиться сообщения:
```
Running database migrations...
Connecting to database: postgres.railway.internal:5432/smc_notificationservice as postgres
Database is ready!
Running migrations...
Executing: ./migrations/001_create_notifications_table.up.sql
✓ ./migrations/001_create_notifications_table.up.sql completed successfully
All migrations completed successfully!
Starting application...
```

## Что было исправлено

1. **Dockerfile** теперь автоматически запускает миграции перед приложением
2. **migrate.sh** скрипт правильно передаёт пароль в `psql`
3. **Entrypoint скрипт** ждёт готовности БД перед запуском миграций

## Если всё ещё не работает

1. Проверьте, что `DB_PASSWORD` не содержит специальные символы (или экранируйте их)
2. Проверьте, что `DB_HOST=postgres.railway.internal` (не localhost!)
3. Проверьте логи на ошибку `fe_sendauth: no password supplied` - это означает проблему с паролем
4. Убедитесь, что база данных доступна из контейнера (проверьте сетевые правила Railway)

## Дополнительная информация

Полная документация: см. `RAILWAY_DEPLOYMENT.md`
