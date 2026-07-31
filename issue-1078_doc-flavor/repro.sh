#!/usr/bin/env bash
# `inspect document` reports [paginated] for a Modern (non-paginated) Doc.
# Prereq: npm i -g univer-cli
set -e
rm -f flavor.univer
univer new flavor.univer
WT=$(univer worktree add flavor.univer --json | node -pe 'JSON.parse(require("fs").readFileSync(0)).worktreeId')
DOC=$(univer unit add flavor.univer --worktree "$WT" --type doc --name ModernDoc --json | node -pe 'JSON.parse(require("fs").readFileSync(0)).unitId')

echo "--- what the facade reports ---"
univer execute flavor.univer --worktree "$WT" --unit "$DOC" -e "
  const d = api.getDocument('$DOC');
  return 'documentFlavor=' + d.getDocumentFlavor() + ' isModern=' + d.isModern() + ' isTraditional=' + d.isTraditional();"

echo "--- what inspect reports ---"
univer inspect document flavor.univer --unit "$DOC" --worktree "$WT" | head -1

# leave the file merged so it opens without a "Locked" banner
univer worktree ready flavor.univer --worktree "$WT" >/dev/null
univer worktree merge flavor.univer --worktree "$WT" >/dev/null
echo "merged — open flavor.univer in the viewer"
