#!/usr/bin/env bash
set -euo pipefail

readonly MONTAGE_REPOSITORY="https://github.com/lomakinigor/AutoMontage-Agent.git"
readonly PRODUCER_REPOSITORY="https://github.com/lomakinigor/content-na-vibe.git"
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
packages="$agent_home/packages"
montage="$packages/avtomontazh"
producer="$packages/content-na-vibe"

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

[ -d "$workspace" ] || fail "Не найден workspace: $workspace"
[ -d "$claude_skills" ] || fail "Не найдена папка skills: $claude_skills"
[ ! -e "$montage" ] || fail "Папка монтажёра уже существует: $montage"
[ ! -e "$producer" ] || fail "Папка продюсера уже существует: $producer"

for skill in avtomontazh "${PRODUCER_SKILLS[@]}"; do
  [ ! -e "$claude_skills/$skill" ] || fail "Skill уже существует: $claude_skills/$skill"
done

run mkdir -p "$packages" "$claude_skills" "$agent_skills"
run git clone --depth 1 "$MONTAGE_REPOSITORY" "$montage/engine"
run git clone --depth 1 "$PRODUCER_REPOSITORY" "$producer"
run npm ci --prefix "$montage/engine"
run python3 -m venv "$producer/.venv"
run "$producer/.venv/bin/pip" install --disable-pip-version-check -r "$producer/requirements.txt"

if "$dry_run"; then
  echo "Будут подключены skills: avtomontazh и ${PRODUCER_SKILLS[*]}"
  exit 0
fi

install_skill() {
  local source="$1"
  local name="$2"
  mkdir -p "$claude_skills/$name"
  cp -R "$source/." "$claude_skills/$name/"
  ln -s "../../.claude/skills/$name" "$agent_skills/$name"
}

install_skill "$montage/engine/.claude/skills/avtomontazh" "avtomontazh"
for skill in "${PRODUCER_SKILLS[@]}"; do
  install_skill "$producer/skills/$skill" "$skill"
done

if id agent >/dev/null 2>&1; then
  chown -R agent:agent "$montage" "$producer" "$claude_skills" "$agent_skills"
fi

echo "Готово: монтажёр и продюсер подключены к $workspace"
