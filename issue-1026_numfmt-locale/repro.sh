#!/usr/bin/env bash
# Reproduces: FWorkbook.setNumfmtLocal() is not persisted.
# Prereq: npm i -g univer-cli
set -e
rm -f numfmt.univer
univer new numfmt.univer
WT=$(univer worktree add numfmt.univer --json | node -pe 'JSON.parse(require("fs").readFileSync(0)).worktreeId')
U=$(univer unit add numfmt.univer --worktree "$WT" --type sheet --name Sheet1 --json | node -pe 'JSON.parse(require("fs").readFileSync(0)).unitId')

echo "--- STEP 1  same session: set 100000000 with #,##0, apply de_DE, read ---"
univer execute numfmt.univer --worktree "$WT" --unit "$U" -e '
  const sh = workbook.getActiveSheet();
  sh.getRange("A1").setValue(100000000).setNumberFormat("#,##0");
  workbook.setNumfmtLocal("de_DE");
  return "same-session A1 = " + sh.getRange("A1").getDisplayValue();
'

echo "--- STEP 2  fresh session: read the same cell again (no setNumfmtLocal) ---"
univer execute numfmt.univer --worktree "$WT" --unit "$U" -e '
  return "fresh-session A1 = " + workbook.getActiveSheet().getRange("A1").getDisplayValue();
'

# leave the file merged so it opens without a "Locked" banner
univer worktree ready numfmt.univer --worktree "$WT" >/dev/null
univer worktree merge numfmt.univer --worktree "$WT" >/dev/null
echo "merged — open numfmt.univer in the viewer"
