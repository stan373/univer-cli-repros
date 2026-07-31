#!/usr/bin/env bash
# The Excel "hide value" number format `;;;` is stored but never applied.
# Prereq: npm i -g univer-cli
set -e
rm -f numfmt.univer
univer new numfmt.univer
WT=$(univer worktree add numfmt.univer --json | node -pe 'JSON.parse(require("fs").readFileSync(0)).worktreeId')
SHEET=$(univer unit add numfmt.univer --worktree "$WT" --type sheet --name Formats --json | node -pe 'JSON.parse(require("fs").readFileSync(0)).unitId')

univer execute numfmt.univer --worktree "$WT" --unit "$SHEET" -e '
  const sh = workbook.getActiveSheet();
  const t = (fmt, v) => { const r = sh.getRange("A1"); r.setValue(v); r.setNumberFormat(fmt);
    return fmt + " -> [" + r.getDisplayValue() + "]  (stored: " + r.getNumberFormat() + ")"; };
  return [t("$#,##0", 233628), t("0.0%", 0.411), t(";;;", 233628), t("\"\";;;", 233628)].join("\n");'
