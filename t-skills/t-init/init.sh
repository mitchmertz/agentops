#!/usr/bin/env bash
# Sets up Beads for Claude Code at the root of the current Git repository; safe to re-run.
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

if [ -d .beads ]; then
  echo "bd already initialized in $repo_root"
else
  bd init --non-interactive
fi

bd setup claude
bd setup claude --check
