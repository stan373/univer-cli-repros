#!/usr/bin/env bash
# A DocBlock embed ignores the document zoom level: text scales, the embedded unit does not.
# Prereq: npm i -g univer-cli
set -e
rm -f zoom.univer
univer new zoom.univer
WT=$(univer worktree add zoom.univer --json | node -pe 'JSON.parse(require("fs").readFileSync(0)).worktreeId')
DOC=$(univer unit add zoom.univer --worktree "$WT" --type doc  --name Brief    --json | node -pe 'JSON.parse(require("fs").readFileSync(0)).unitId')
BASE=$(univer unit add zoom.univer --worktree "$WT" --type base --name Registry --json | node -pe 'JSON.parse(require("fs").readFileSync(0)).unitId')

univer execute zoom.univer --worktree "$WT" --unit "$BASE" -e '
  const t = api.getBase("'"$BASE"'").getTables()[0];
  const FK = api.Enum.BaseFieldKeyEnum;
  const primary = t.getFields()[0].getName();
  t.addRecords([1,2,3].map(i => ({ values: { [primary]: "record " + i }, fieldKey: FK.Name })));
  return "base seeded";'

univer execute zoom.univer --worktree "$WT" --unit "$DOC" -e '
  let md = "# Zoom test\n\n";
  for (let i = 1; i <= 8; i++) md += "Paragraph " + i + ". This text scales with the zoom control.\n\n";
  const t = api.getDocument("'"$DOC"'");
  const p = t.getParagraphs();
  t.replaceRange({ startOffset: p[0].getRange().startOffset, endOffset: p[p.length-1].getRange().endOffset }, api.convertMarkdown(md));
  return "doc written";'

univer execute zoom.univer --worktree "$WT" --unit "$DOC" -e '
  const S = api.Enum.FEmbedHostSurface, UT = api.Enum.UniverInstanceType;
  const e = api.createEmbed({ embedId: "reg", host: { unitId: "'"$DOC"'", surface: S.DocBlock, context: {} },
    content: { unitType: UT.UNIVER_BASE, ref: "#unit='"$BASE"'&type=base" }, interaction: "interactive" });
  await e.loadAsync(); return "embedded";'

echo "--- open the URL, then use the zoom control (bottom right) to go 100% -> 50% ---"
univer open zoom.univer --worktree "$WT" --unit "$DOC"

# leave the file merged so it opens without a "Locked" banner
univer worktree ready zoom.univer --worktree "$WT" >/dev/null
univer worktree merge zoom.univer --worktree "$WT" >/dev/null
echo "merged — open zoom.univer in the viewer"
