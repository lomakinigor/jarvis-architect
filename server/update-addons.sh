#!/usr/bin/env bash
# Обновляет уже подключённые модули без перезаписи server credentials.

set -euo pipefail

readonly PRODUCER_SKILLS=(producer-orchestrator trend-hunter video-transcriber scenario-writer presentation-maker lead-magnet-maker)

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
test -d "$montage/.git" || fail "Не найден установленный AutoMontage-Agent: $montage"
test -d "$producer/.git" || fail "Не найден установленный content-na-vibe: $producer"

run git -C "$montage" pull --ff-only
run git -C "$producer" pull --ff-only
run npm ci --prefix "$montage"
if [[ -x "$producer/.venv/bin/pip" ]]; then
  run "$producer/.venv/bin/pip" install --disable-pip-version-check -r "$producer/requirements.txt"
fi

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
