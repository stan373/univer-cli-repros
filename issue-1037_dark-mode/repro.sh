#!/usr/bin/env bash
# Reproduces: FUniver.toggleDarkMode() is not persisted.
# Prereq: npm i -g univer-cli
set -e
rm -f dark.univer
univer new dark.univer
WT=$(univer worktree add dark.univer --json | node -pe 'JSON.parse(require("fs").readFileSync(0)).worktreeId')
U=$(univer unit add dark.univer --worktree "$WT" --type sheet --name Sheet1 --json | node -pe 'JSON.parse(require("fs").readFileSync(0)).unitId')

echo "--- STEP 1  enable dark mode in a session ---"
univer execute dark.univer --worktree "$WT" --unit "$U" -e '
  workbook.getActiveSheet().getRange("A1").setValue("dark mode test");
  api.toggleDarkMode(true);
  return "toggleDarkMode(true) returned without error";
'

echo "--- STEP 2  is anything about it stored in the snapshot? ---"
echo -n "occurrences of darkMode/theme keys in the .univer snapshot: "
strings dark.univer | grep -icE 'darkmode|dark_mode|"theme"' || true

echo "--- STEP 3  open the viewer and look ---"
univer open dark.univer --worktree "$WT" --unit "$U"
echo "The unit still renders with the light theme."
