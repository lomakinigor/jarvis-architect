# Spec: обновление upstream-шаблона

## Problem statement

Локальная копия `lomakinigor/jarvis-architect` отстаёт от `Ntmib/jarvis-architect` и не содержит проверенные security-правки шаблона.

## User stories

- Maintainer обновляет базовый шаблон штатным merge из `upstream/main`.
- Серверные addon-модули и их документация остаются без изменений.
- Публичный шаблон не хранит дневники рабочей памяти.

## Acceptance criteria

- Изменения `upstream/main` смержены в `main` без потери `server/install-addons.sh`, `server/INSTALL-ADDONS.md` и `server/test-module-bundle.sh`.
- Новый template safety test проходит.
- `memory/2026-07-05.md` и `memory/2026-07-06.md` отсутствуют в текущем дереве публичной ветки.
- Новый `lomakinigor/agents-architect` создан как отдельный public-репозиторий на актуальном upstream-коммите.

## Affected files

- Upstream template files и security checks.
- Документация и скрипты server addon-модулей — только при конфликте merge.

## Test plan

1. Выполнить upstream test suite после merge.
2. Выполнить проверку addon bundle.
3. Сверить SHA ветки нового репозитория с upstream.

## Rollback plan

Откатить merge-коммит в старом репозитории; удалить новый репозиторий только по отдельному запросу пользователя.
