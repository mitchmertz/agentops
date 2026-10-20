---
name: t-help
description: Show the personal cheatsheet with the workflow loop, the installed /t- commands and common bd commands.
disable-model-invocation: true
allowed-tools: Bash(${CLAUDE_SKILL_DIR}/cheatsheet.sh)
---

Reply with the cheatsheet below exactly as printed, inside one code block, and add nothing else.

!`${CLAUDE_SKILL_DIR}/cheatsheet.sh`
