#!/usr/bin/env bash
# A/B in ONE document: a Base embed renders, a Sheet embed does not.
# Prereq: npm i -g univer-cli
set -e
rm -f ab.univer
univer new ab.univer
WT=$(univer worktree add ab.univer --json | node -pe 'JSON.parse(require("fs").readFileSync(0)).worktreeId')
DOC=$(univer unit add ab.univer --worktree "$WT" --type doc   --name Brief   --json | node -pe 'JSON.parse(require("fs").readFileSync(0)).unitId')
SHEET=$(univer unit add ab.univer --worktree "$WT" --type sheet --name Model --json | node -pe 'JSON.parse(require("fs").readFileSync(0)).unitId')
BASE=$(univer unit add ab.univer --worktree "$WT" --type base  --name Registry --json | node -pe 'JSON.parse(require("fs").readFileSync(0)).unitId')

univer execute ab.univer --worktree "$WT" --unit "$SHEET" -e '
  const sh = workbook.getActiveSheet();
  sh.getRange("A1").setValue("SHEET EMBED — if you can read this, the sheet rendered");
  for (let r = 2; r <= 6; r++) { sh.getRange("A"+r).setValue("row "+r); sh.getRange("B"+r).setValue(r*100); }
  return "sheet seeded";'

univer execute ab.univer --worktree "$WT" --unit "$BASE" -e '
  const t = api.getBase("'"$BASE"'").getTables()[0];
  const FK = api.Enum.BaseFieldKeyEnum;
  const primary = t.getFields()[0].getName();
  t.addRecords([1,2,3].map(i => ({ values: { [primary]: "BASE EMBED row " + i }, fieldKey: FK.Name })));
  return "base seeded rows=" + t.getRecords().length;'

univer execute ab.univer --worktree "$WT" --unit "$DOC" -e '
  let md = "# A/B embed test\n\nBelow: one Base embed and one Sheet embed, same document, same DocBlock surface.\n\n";
  for (let i = 1; i <= 6; i++) md += "Filler paragraph " + i + ".\n\n";
  const t = api.getDocument("'"$DOC"'");
  const p = t.getParagraphs();
  t.replaceRange({ startOffset: p[0].getRange().startOffset, endOffset: p[p.length-1].getRange().endOffset }, api.convertMarkdown(md));
  return "paragraphs=" + t.getParagraphs().length;'

echo "--- embed BOTH into the same doc ---"
univer execute ab.univer --worktree "$WT" --unit "$DOC" -e '
  const S = api.Enum.FEmbedHostSurface, UT = api.Enum.UniverInstanceType;
  const a = api.createEmbed({ embedId: "base-block", host: { unitId: "'"$DOC"'", surface: S.DocBlock, context: {} },
    content: { unitType: UT.UNIVER_BASE, ref: "#unit='"$BASE"'&type=base" }, interaction: "interactive" });
  const ca = await a.loadAsync();
  const b = api.createEmbed({ embedId: "sheet-block", host: { unitId: "'"$DOC"'", surface: S.DocBlock, context: {} },
    content: { unitType: UT.UNIVER_SHEET, ref: "#unit='"$SHEET"'&type=sheet" }, interaction: "interactive" });
  const cb = await b.loadAsync();
  return "base=" + ca.getId() + " sheet=" + cb.getId() + " embeds=" + api.listEmbeds({hostUnitId:"'"$DOC"'"}).length;'

echo "--- where is the embedded sheet scrolled to? ---"
univer execute ab.univer --worktree "$WT" --unit "$SHEET" -e '
  const sh = workbook.getActiveSheet();
  return "data lives in A1:B6; used range = " + sh.getDataRange().getA1Notation();'

echo "--- open and look: the Base grid shows its rows; the Sheet grid opens scrolled past its data ---"
univer open ab.univer --worktree "$WT" --unit "$DOC"

# leave the file merged so it opens without a "Locked" banner
univer worktree ready ab.univer --worktree "$WT" >/dev/null
univer worktree merge ab.univer --worktree "$WT" >/dev/null
echo "merged — open ab.univer in the viewer"
