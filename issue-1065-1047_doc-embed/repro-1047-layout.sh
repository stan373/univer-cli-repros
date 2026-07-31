#!/usr/bin/env bash
# Reproduces: a DocBlock embed does not take part in document layout, so it paints over the text.
# Prereq: npm i -g univer-cli
set -e
rm -f docblock.univer
univer new docblock.univer
WT=$(univer worktree add docblock.univer --json | node -pe 'JSON.parse(require("fs").readFileSync(0)).worktreeId')
DOC=$(univer unit add docblock.univer --worktree "$WT" --type doc   --name Brief --json | node -pe 'JSON.parse(require("fs").readFileSync(0)).unitId')
SHEET=$(univer unit add docblock.univer --worktree "$WT" --type sheet --name Model --json | node -pe 'JSON.parse(require("fs").readFileSync(0)).unitId')

univer execute docblock.univer --worktree "$WT" --unit "$SHEET" -e '
  const sh = workbook.getActiveSheet();
  sh.getRange("A1").setValue("Model");
  for (let r = 2; r <= 12; r++) { sh.getRange("A"+r).setValue("row "+r); sh.getRange("B"+r).setValue(r*100); }
  return "sheet seeded";
'

echo "--- write a multi-paragraph document ---"
univer execute docblock.univer --worktree "$WT" --unit "$DOC" -e '
  let md = "# Brief\n\n";
  for (let i = 1; i <= 12; i++) md += "Paragraph " + i + ". This line exists so the overlap is obvious.\n\n";
  const target = api.getDocument("'"$DOC"'");
  const p = target.getParagraphs();
  target.replaceRange({ startOffset: p[0].getRange().startOffset, endOffset: p[p.length-1].getRange().endOffset }, api.convertMarkdown(md));
  return "paragraphs=" + target.getParagraphs().length;
'

echo "--- layout BEFORE the embed ---"
univer inspect document docblock.univer --unit "$DOC" --worktree "$WT" --bbox | head -6

echo "--- embed the sheet as a DocBlock ---"
univer execute docblock.univer --worktree "$WT" --unit "$DOC" -e '
  const S = api.Enum.FEmbedHostSurface, UT = api.Enum.UniverInstanceType;
  const e = api.createEmbed({ embedId: "model-block",
    host: { unitId: "'"$DOC"'", surface: S.DocBlock, context: {} },
    content: { unitType: UT.UNIVER_SHEET, ref: "#unit='"$SHEET"'&type=sheet" }, interaction: "interactive" });
  const c = await e.loadAsync();
  return "embedded=" + c.getId();
'

echo "--- layout AFTER the embed (identical: no height reserved) ---"
univer inspect document docblock.univer --unit "$DOC" --worktree "$WT" --bbox | head -6

echo "--- open it and look: the sheet paints on top of the paragraphs ---"
univer open docblock.univer --worktree "$WT" --unit "$DOC"

# leave the file merged so it opens without a "Locked" banner
univer worktree ready docblock.univer --worktree "$WT" >/dev/null
univer worktree merge docblock.univer --worktree "$WT" >/dev/null
echo "merged — open docblock.univer in the viewer"
