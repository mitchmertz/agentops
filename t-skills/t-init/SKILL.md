---
name: t-init
description: Set up Beads for Claude Code in the current repository (bd init + bd setup claude).
disable-model-invocation: true
---

Run `${CLAUDE_SKILL_DIR}/init.sh` with the Bash tool from the current repository and show its output.
If it fails, report the error and stop; do not try other setup commands.
