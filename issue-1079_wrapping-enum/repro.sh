#!/usr/bin/env bash
# The enum named in every drawing signature, TextWrappingStyle, is not exposed on api.Enum.
# Prereq: npm i -g univer-cli
set -e
rm -f enum.univer
univer new enum.univer
WT=$(univer worktree add enum.univer --json | node -pe 'JSON.parse(require("fs").readFileSync(0)).worktreeId')
DOC=$(univer unit add enum.univer --worktree "$WT" --type doc --name T --json | node -pe 'JSON.parse(require("fs").readFileSync(0)).unitId')
univer execute enum.univer --worktree "$WT" --unit "$DOC" -e "
  return ['TextWrappingStyle','ImageSourceType','DocsImageWrappingStyle','DocsShapeWrappingStyle']
    .map(n => n + '=' + (api.Enum[n] === undefined ? 'undefined' : 'ok')).join('  ');"
