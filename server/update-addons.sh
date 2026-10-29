#!/usr/bin/env bash
# Обновляет уже подключённые модули без перезаписи server credentials.

set -euo pipefail

readonly PRODUCER_SKILLS=(producer-orchestrator trend-hunter video-transcriber scenario-writer presentation-maker lead-magnet-maker)
readonly MONTAGE_REPOSITORY="https://github.com/lomakinigor/AutoMontage-Agent.git"
readonly PRODUCER_REPOSITORY="https://github.com/lomakinigor/content-na-vibe.git"

dry_run=false
if [[ "${1:-}" == "--dry-run" ]]; then
  dry_run=true
  shift
fi

agent_home="${1:-/home/agent}"
workspace="$agent_home/workspace"
claude_skills="$workspace/.claude/skills"
agent_skills="$workspace/.agents/skills"
montage="$agent_home/packages/avtomontazh/engine"
producer="$agent_home/packages/content-na-vibe"
packages="$agent_home/packages"

fail() {
  echo "Ошибка: $*" >&2
  exit 1
}

run() {
  if "$dry_run"; then
    printf '+ '
    printf '%q ' "$@"
    printf '\n'
  else
    "$@"
  fi
}

test -d "$workspace" || fail "Не найден workspace: $workspace"
test -d "$claude_skills" || fail "Не найдена папка skills: $claude_skills"
test -d "$montage" || fail "Не найден установленный AutoMontage-Agent: $montage"
test -d "$producer" || fail "Не найден установленный content-na-vibe: $producer"

refresh_module() {
  local target="$1"
  local repository="$2"
  local name="$3"

  if [[ -d "$target/.git" ]]; then
    run git -C "$target" pull --ff-only
    return
  fi

  if "$dry_run"; then
    echo "+ download clean $name release and overlay published files"
    return
  fi

  local stage voice_backup env_backup
  stage="$(mktemp -d "$packages/.${name}.update.XXXXXX")"
  voice_backup="$(mktemp)"
  env_backup="$(mktemp)"
  trap 'rm -rf -- "$stage"; rm -f -- "$voice_backup" "$env_backup"' RETURN

  git clone --quiet --depth 1 "$repository" "$stage/source"
  if [[ -f "$target/voice/author-voice.md" ]]; then
    cp "$target/voice/author-voice.md" "$voice_backup"
  fi
  if [[ -f "$target/.env" ]]; then
    cp "$target/.env" "$env_backup"
  fi
  (cd "$stage/source" && tar --exclude=.git --exclude=.venv --exclude=.env -cf - .) | (cd "$target" && tar -xf -)
  if [[ -s "$voice_backup" ]]; then
    mkdir -p "$target/voice"
    cp "$voice_backup" "$target/voice/author-voice.md"
  fi
  if [[ -s "$env_backup" ]]; then
    cp "$env_backup" "$target/.env"
  fi
}

refresh_module "$montage" "$MONTAGE_REPOSITORY" "avtomontazh"
refresh_module "$producer" "$PRODUCER_REPOSITORY" "content-na-vibe"
run npm ci --prefix "$montage"
if [[ ! -x "$producer/.venv/bin/pip" ]]; then
  run python3 -m venv "$producer/.venv"
fi
run "$producer/.venv/bin/pip" install --disable-pip-version-check -r "$producer/requirements.txt"

if "$dry_run"; then
  echo "Будут обновлены AutoMontage-Agent и content-na-vibe, затем skills в $workspace"
  exit 0
fi

install_skill() {
  local source="$1"
  local name="$2"
  local link="$agent_skills/$name"

  test -f "$source/SKILL.md" || fail "В обновлённом модуле нет skill: $name"
  mkdir -p "$claude_skills/$name" "$agent_skills"
  cp -R "$source/." "$claude_skills/$name/"
  if [[ -e "$link" && ! -L "$link" ]]; then
    fail "Не перезаписываю существующий нессылочный skill: $link"
  fi
  if [[ ! -e "$link" ]]; then
    ln -s "../../.claude/skills/$name" "$link"
  fi
}

install_skill "$montage/.claude/skills/avtomontazh" "avtomontazh"
for skill in "${PRODUCER_SKILLS[@]}"; do
  install_skill "$producer/skills/$skill" "$skill"
done

if id agent >/dev/null 2>&1; then
  chown -R agent:agent "$agent_home/packages/avtomontazh" "$producer" "$claude_skills" "$agent_skills"
fi

echo "Готово: модули и skills обновлены в $workspace"
