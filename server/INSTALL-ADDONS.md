# Подключение монтажёра и продюсера

После базовой установки Jarvis запустите на сервере от root:

```bash
git clone https://github.com/lomakinigor/jarvis-architect.git /tmp/jarvis-architect
bash /tmp/jarvis-architect/server/install-addons.sh
```

Скрипт скачивает два чистых модуля в `/home/agent/packages/`, устанавливает их зависимости и подключает skills в workspace Usjarvis. Он намеренно останавливается, если на сервере уже есть модуль или skill с таким именем: существующую рабочую установку не перезаписывает.

Для предварительной проверки без изменений:

```bash
bash /tmp/jarvis-architect/server/install-addons.sh --dry-run
```

## Обновление уже установленных модулей

Скрипт не удаляет существующие пакеты. Он обновляет их только через `git pull --ff-only`, поэтому остановится, если на сервере есть незакоммиченные изменения, а не перезапишет их.

```bash
git clone https://github.com/lomakinigor/jarvis-architect.git /tmp/jarvis-architect
bash /tmp/jarvis-architect/server/update-addons.sh
```

Предварительная проверка:

```bash
bash /tmp/jarvis-architect/server/update-addons.sh --dry-run
```
