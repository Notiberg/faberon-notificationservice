# Развёртывание на Railway

## Обязательные переменные окружения

Установите следующие переменные окружения в Railway:

### Database (PostgreSQL)
```
DB_HOST=<ваш-railway-postgres-host>
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=<ваш-пароль>
DB_NAME=smc_notificationservice
DB_SSLMODE=require
```

### Telegram Bot
```
TELEGRAM_BOT_TOKEN=<ваш-токен-от-botfather>
```

### HTTP Server
```
HTTP_PORT=8085
```

### Logs
```
LOG_LEVEL=info
LOG_FILE=/app/logs/app.log
```

### UserService Integration
```
USERSERVICE_URL=<url-вашего-userservice>
USERSERVICE_TIMEOUT=10
```

### Worker Configuration
```
WORKER_PROCESSOR_INTERVAL=30
WORKER_PROCESSOR_BATCH_SIZE=50
```

### Metrics (опционально)
```
METRICS_ENABLED=true
METRICS_PATH=/metrics
METRICS_SERVICE_NAME=notificationservice
```

## Как это работает

1. **Dockerfile** автоматически:
   - Копирует миграции в контейнер
   - Копирует `migrate.sh` скрипт
   - Создаёт `entrypoint.sh` который:
     - Запускает миграции перед приложением
     - Ждёт, пока база данных будет готова
     - Запускает приложение

2. **migrate.sh** скрипт:
   - Подключается к PostgreSQL используя переменные окружения
   - Ждёт, пока база данных будет доступна (до 30 попыток)
   - Запускает все `.up.sql` файлы из папки `migrations/`
   - Выходит с ошибкой, если миграция не удалась

## Проверка статуса

После развёртывания на Railway:

1. Проверьте логи контейнера - должны быть сообщения:
   ```
   Running database migrations...
   Connecting to database: <host>:5432/smc_notificationservice
   Database is ready!
   Running migrations...
   Executing: ./migrations/001_create_notifications_table.up.sql
   ✓ ./migrations/001_create_notifications_table.up.sql completed successfully
   All migrations completed successfully!
   Starting application...
   ```

2. Проверьте health endpoint:
   ```
   curl https://<ваш-railway-url>/health
   ```

3. Проверьте, что таблица создана:
   ```
   psql -h <host> -U postgres -d smc_notificationservice -c "SELECT * FROM notifications LIMIT 1;"
   ```

## Если миграции не запустились

1. **Проверьте логи Railway контейнера** - ищите сообщения о миграциях
2. **Убедитесь, что все переменные окружения установлены:**
   - `DB_HOST` - должен быть `postgres.railway.internal` (для Railway)
   - `DB_PORT` - должен быть `5432`
   - `DB_USER` - обычно `postgres`
   - `DB_PASSWORD` - пароль от базы данных
   - `DB_NAME` - имя базы данных
   - `DB_SSLMODE` - должен быть `require` (для Railway)
3. **Убедитесь, что база данных доступна** из контейнера (проверьте сетевые правила Railway)
4. **Проверьте, что пароль не содержит специальные символы** - если содержит, экранируйте их
5. **Проверьте логи на ошибку `fe_sendauth: no password supplied`** - это означает, что переменная `PGPASSWORD` не передана правильно

## Откат миграций (если нужно)

Используйте `migrate.sh` с флагом `down`:

```bash
./migrate.sh down
```

Но это требует дополнительной конфигурации. Текущий скрипт запускает только `up` миграции.
