# Обновление от донора

База этого репозитория берётся из `https://github.com/Ntmib/jarvis-architect`.

Для обновления maintainer-копии:

```bash
git remote add upstream https://github.com/Ntmib/jarvis-architect.git
git fetch upstream --tags
git merge upstream/main
```

После разрешения конфликтов в файлах `server/install-addons.sh`, `server/INSTALL-ADDONS.md` и `server/test-module-bundle.sh` нужно запустить проверку связки и опубликовать результат в `main`.
