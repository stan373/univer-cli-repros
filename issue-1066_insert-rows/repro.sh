#!/usr/bin/env bash
# insertRows / insertRowsAfter / insertRowBefore report success but never add rows.
# Prereq: npm i -g univer-cli
set -e
rm -f rows.univer
univer new rows.univer
WT=$(univer worktree add rows.univer --json | node -pe 'JSON.parse(require("fs").readFileSync(0)).worktreeId')
U=$(univer unit add rows.univer --worktree "$WT" --type sheet --name Sheet1 --json | node -pe 'JSON.parse(require("fs").readFileSync(0)).unitId')

echo "--- default sheet, then trim it with deleteRows (which works) ---"
univer execute rows.univer --worktree "$WT" --unit "$U" -e '
  const sh = workbook.getActiveSheet();
  const before = sh.getMaxRows();
  sh.deleteRows(20, before - 20);
  return "deleteRows: " + before + " -> " + sh.getMaxRows();'

echo "--- now try every documented way to add rows back ---"
univer execute rows.univer --worktree "$WT" --unit "$U" -e '
  const sh = workbook.getActiveSheet();
  const out = [];
  const t = (label, fn) => { const b = sh.getMaxRows(); try { fn(); } catch (e) { out.push(label + " threw: " + e.message.slice(0,40)); return; } out.push(label + ": " + b + " -> " + sh.getMaxRows()); };
  t("insertRows(20, 30)",        () => sh.insertRows(20, 30));
  t("insertRowsAfter(20, 30)",   () => sh.insertRowsAfter(20, 30));
  t("insertRowAfter(20)",        () => sh.insertRowAfter(20));
  t("insertRowBefore(20)",       () => sh.insertRowBefore(20));
  t("appendRow([...])",          () => sh.appendRow(["x"]));
  return out.join(" | ");'

echo "--- for contrast, a brand new sheet created with an explicit row count ---"
univer execute rows.univer --worktree "$WT" --unit "$U" -e '
  const s = workbook.create("Wide", 500, 12);
  return "create(\"Wide\", 500, 12) -> " + s.getMaxRows() + " rows";'

# leave the file merged so it opens without a "Locked" banner
univer worktree ready rows.univer --worktree "$WT" >/dev/null
univer worktree merge rows.univer --worktree "$WT" >/dev/null
echo "merged — open rows.univer in the viewer"
