#!/usr/bin/env bash
# Installs a chosen subset of AgentOps skills as personal /t-<skill> commands,
# links the personal skills in t-skills/, and disables the agentops plugin so
# only this subset is loaded. Restart Claude Code afterwards.
#
#   ./install.sh              install or refresh (safe to re-run)
#   ./install.sh --uninstall  remove the /t- commands and re-enable the plugin
set -euo pipefail

AGENTOPS_SKILLS=(
  research
  plan
  implement
  test
  review
  validate
  memory
  rpi
  interview
  craft-goal
)

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
PLUGIN_ID="agentops@agentops-marketplace"
WRAPPER_MARKER=".t-wrapper"

frontmatter_line() {
  local skill_md="$1" key="$2"
  awk -v key="$key" '
    NR == 1 && /^---$/ { inside = 1; next }
    inside && /^---$/  { exit }
    inside && index($0, key ": ") == 1 { print; exit }
  ' "$skill_md"
}

write_wrapper() {
  local skill="$1"
  local source_md="$REPO/skills/$skill/SKILL.md"
  local target="$SKILLS_DIR/t-$skill"

  if [ ! -f "$source_md" ]; then
    echo "error: no AgentOps skill named '$skill' in $REPO/skills" >&2
    exit 1
  fi

  mkdir -p "$target"
  touch "$target/$WRAPPER_MARKER"
  {
    echo "---"
    echo "name: t-$skill"
    frontmatter_line "$source_md" description
    frontmatter_line "$source_md" disable-model-invocation
    echo "---"
    echo
    echo "Read $source_md in full and follow it as this skill's instructions."
    echo "Resolve its relative links against $REPO/skills/$skill/."
    echo "Other AgentOps skills it names are available as /t-<name> when installed,"
    echo "and otherwise readable at $REPO/skills/<name>/SKILL.md."
  } > "$target/SKILL.md"
}

link_personal_skills() {
  local source_dir
  for source_dir in "$REPO"/t-skills/*/; do
    ln -s "${source_dir%/}" "$SKILLS_DIR/$(basename "$source_dir")"
  done
}

remove_installed() {
  local entry
  for entry in "$SKILLS_DIR"/t-*; do
    if [ -L "$entry" ] && [[ "$(readlink "$entry")" == "$REPO/t-skills/"* ]]; then
      rm "$entry"
    elif [ ! -L "$entry" ] && [ -f "$entry/$WRAPPER_MARKER" ]; then
      rm -rf "$entry"
    fi
  done
}

plugin_enabled() {
  claude plugin list --json | python3 -c '
import json, sys
plugins = {p["id"]: p for p in json.load(sys.stdin)}
sys.exit(0 if plugins.get(sys.argv[1], {}).get("enabled") else 1)
' "$PLUGIN_ID"
}

install() {
  mkdir -p "$SKILLS_DIR"
  remove_installed
  local skill
  for skill in "${AGENTOPS_SKILLS[@]}"; do
    write_wrapper "$skill"
  done
  link_personal_skills

  if plugin_enabled; then
    claude plugin disable "$PLUGIN_ID"
  fi

  echo "Installed into $SKILLS_DIR:"
  ls -d "$SKILLS_DIR"/t-* | xargs -n1 basename | sed 's|^|  /|'
  echo "Restart Claude Code, then run /t-help."
}

uninstall() {
  remove_installed
  if ! plugin_enabled; then
    claude plugin enable "$PLUGIN_ID"
  fi
  echo "Removed the /t- commands and re-enabled $PLUGIN_ID. Restart Claude Code."
}

case "${1:-}" in
  "") install ;;
  --uninstall) uninstall ;;
  *) echo "usage: $0 [--uninstall]" >&2; exit 2 ;;
esac
