#!/usr/bin/env bash
# Prints the personal cheatsheet: the loop, the installed /t- commands by group, and common bd commands.
set -euo pipefail

SKILLS_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"

COMMAND_GUIDE='Understand|research|How does X work? Cited answer, changes nothing
Shape|plan|Request -> one slice with examples and scope
Shape|interview|Settle a big outcome, one question at a time
Shape|craft-goal|Write a bounded prompt for a long-running /goal
Build|implement|Make the change, run checks, report what ran
Build|test|Write tests that fail without the fix
Judge|review|Advisory opinion on a plan or diff
Judge|validate|PASS / FAIL / NOT_PROVEN (run in a NEW session)
End to end|rpi|Plan -> implement -> check -> done, for one change
Remember|memory|Save or find a lesson or agent rule
Setup|init|Set up Beads in this repo
Setup|help|This cheatsheet'

print_command() {
  printf '  %-18s %s\n' "/$1" "$2"
}

print_guided_commands() {
  local group skill summary current_group=""
  while IFS='|' read -r group skill summary; do
    [ -f "$SKILLS_DIR/t-$skill/SKILL.md" ] || continue
    if [ "$group" != "$current_group" ]; then
      printf '\n%s\n' "$(echo "$group" | tr '[:lower:]' '[:upper:]')"
      current_group="$group"
    fi
    print_command "t-$skill" "$summary"
  done <<< "$COMMAND_GUIDE"
}

print_unguided_commands() {
  local skill_dir skill header_printed=""
  for skill_dir in "$SKILLS_DIR"/t-*/; do
    skill="$(basename "$skill_dir")"
    skill="${skill#t-}"
    grep -q "|$skill|" <<< "$COMMAND_GUIDE" && continue
    [ -n "$header_printed" ] || { printf '\nOTHER\n'; header_printed=1; }
    print_command "t-$skill" "$(skill_summary "$skill_dir/SKILL.md")"
  done
}

skill_summary() {
  awk '
    NR == 1 && /^---$/ { inside = 1; next }
    inside && /^---$/  { exit }
    inside && /^description: / {
      summary = substr($0, 14)
      gsub(/^'\''|'\''$/, "", summary)
      sub(/ Use when:.*/, "", summary)
      print summary
      exit
    }
  ' "$1"
}

cat <<'EOF'
THE LOOP
  1 /t-research      how does this part work?
  2 /t-plan          behavior + 1-3 examples (given/when/then)   big outcome: /t-interview
  3 /t-implement     change + checks (fail before, pass after)
  4 /t-test          tests missing, or doubt a green result?     CI is the final gate
  5 /t-validate      only when a mistake is costly, NEW session  opinion only: /t-review
  6 /t-memory        lesson worth keeping; then commit, bd close <id>

    /t-rpi <change>  steps 3-5 in one go, for an accepted change
EOF

print_guided_commands
print_unguided_commands

cat <<'EOF'

BEADS
  bd ready                     what can I work on?
  bd create "Title" -t task    add work (bug, feature, task, epic, chore)
  bd update <id> --claim       start it
  bd show <id>                 details and notes
  bd close <id> -r "why"       done

MAINTAIN
  ./install.sh                 in the agentops checkout: refresh /t- commands
EOF
