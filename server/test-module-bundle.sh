#!/usr/bin/env bash
set -euo pipefail

bundle_root="${1:-$(cd "$(dirname "$0")/../.." && pwd)}"
jarvis="$bundle_root/jarvis-architect"
montage="$bundle_root/AutoMontage-Agent"
producer="$bundle_root/${PRODUCER_DIR:-content-na-vibe}"

require_file() {
  if [ ! -f "$1" ]; then
    echo "Missing required file: $1" >&2
    exit 1
  fi
}

require_dir() {
  if [ ! -d "$1" ]; then
    echo "Missing required directory: $1" >&2
    exit 1
  fi
}

require_file "$jarvis/server/install-addons.sh"
require_file "$jarvis/server/update-addons.sh"
require_file "$montage/.claude/skills/avtomontazh/SKILL.md"

for skill in producer-orchestrator trend-hunter video-transcriber scenario-writer presentation-maker lead-magnet-maker; do
  require_file "$producer/skills/$skill/SKILL.md"
done

for repo in "$jarvis" "$montage" "$producer"; do
  if find "$repo" -type f \( -name '.env' -o -path '*/node_modules/*' -o -path '*/.venv/*' \) -print -quit | grep -q .; then
    echo "Private or generated file found in $repo" >&2
    exit 1
  fi
done

if grep -RIl --exclude='env.example' -E 'Дмитри[йя]|Ледовских|macbookledovskih|mcdenil|neurobussines|/Users/' "$producer" >/dev/null 2>&1; then
  echo "Producer still contains donor-personal settings" >&2
  exit 1
fi

test_agent="$bundle_root/test-agent"
mkdir -p "$test_agent/workspace/.claude/skills"
dry_run_output="$(bash "$jarvis/server/install-addons.sh" --dry-run "$test_agent")"
if [[ "$dry_run_output" != *"Будут подключены skills"* ]]; then
  echo "Installer dry run did not describe the skills" >&2
  exit 1
fi
if [[ "$dry_run_output" != *"packages/avtomontazh"* ]]; then
  echo "Installer dry run does not create the montage parent directory" >&2
  exit 1
fi

echo "Module bundle checks passed"
