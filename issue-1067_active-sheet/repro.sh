#!/usr/bin/env bash
# Two problems with "which worksheet is active" once a unit is embedded as a sheet tab.
# Prereq: npm i -g univer-cli
set -e
rm -f act.univer
univer new act.univer
WT=$(univer worktree add act.univer --json | node -pe 'JSON.parse(require("fs").readFileSync(0)).worktreeId')
SHEET=$(univer unit add act.univer --worktree "$WT" --type sheet --name Model --json | node -pe 'JSON.parse(require("fs").readFileSync(0)).unitId')
DOC=$(univer unit add act.univer --worktree "$WT" --type doc --name Notes --json | node -pe 'JSON.parse(require("fs").readFileSync(0)).unitId')

univer execute act.univer --worktree "$WT" --unit "$SHEET" -e '
  const sh = workbook.getActiveSheet();
  sh.setName("Budget");
  sh.getRange("A1").setValue("Budget data lives here");
  return "first worksheet = " + sh.getSheetName();'

echo "--- embed the doc as a sheet tab ---"
univer execute act.univer --worktree "$WT" --unit "$SHEET" -e '
  const S = api.Enum.FEmbedHostSurface, UT = api.Enum.UniverInstanceType;
  const e = api.createEmbed({ embedId: "notes-tab",
    host: { unitId: "'"$SHEET"'", surface: S.SheetTab, context: {} },
    content: { unitType: UT.UNIVER_DOC, ref: "#unit='"$DOC"'&type=doc" }, interaction: "interactive" });
  await e.loadAsync();
  return "embedded";'

echo "--- PROBLEM 1: getActiveSheet() now returns the 1x1 embed placeholder ---"
univer execute act.univer --worktree "$WT" --unit "$SHEET" -e '
  const a = workbook.getActiveSheet();
  let read = "";
  try { read = "read A4 ok: " + a.getRange("A4").getValue(); }
  catch (e) { read = "read A4 THREW: " + e.message.slice(0, 90); }
  return "getActiveSheet() = " + a.getSheetName() + " (" + a.getMaxRows() + "r x " + a.getMaxColumns() + "c) | " + read;'

echo "--- PROBLEM 2: setActiveSheet() does not persist ---"
univer execute act.univer --worktree "$WT" --unit "$SHEET" -e '
  const b = workbook.getSheetByName("Budget");
  workbook.setActiveSheet(b);
  b.getRange("A1").activate();
  return "set in this session -> " + workbook.getActiveSheet().getSheetName();'

univer worktree ready act.univer --worktree "$WT" >/dev/null
univer worktree merge act.univer --worktree "$WT" >/dev/null
W2=$(univer worktree add act.univer --json | node -pe 'JSON.parse(require("fs").readFileSync(0)).worktreeId')
univer execute act.univer --worktree "$W2" --unit "$SHEET" -e '
  return "after merge, fresh session -> " + workbook.getActiveSheet().getSheetName();'

echo "--- and this is what a visitor lands on ---"
univer open act.univer --unit "$SHEET"
