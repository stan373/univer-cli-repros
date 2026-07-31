#!/usr/bin/env bash
# An image inserted at a table-cell offset is stored in the cell but never rendered.
# Prereq: npm i -g univer-cli
set -e
rm -f cellimg.univer
univer new cellimg.univer
WT=$(univer worktree add cellimg.univer --json | node -pe 'JSON.parse(require("fs").readFileSync(0)).worktreeId')
DOC=$(univer unit add cellimg.univer --worktree "$WT" --type doc --name CellImg --json | node -pe 'JSON.parse(require("fs").readFileSync(0)).unitId')

univer execute cellimg.univer --worktree "$WT" --unit "$DOC" -e '
  const d = api.getDocument("'"$DOC"'");
  const p0 = d.getParagraphs();
  d.replaceRange({ startOffset: p0[0].getRange().startOffset, endOffset: p0[p0.length-1].getRange().endOffset },
    api.convertMarkdown("# Cell image\n\nBefore table.\n"));
  const last = d.getParagraphs().slice(-1)[0];
  d.insertTableFromData([["Programme","Evidence"],["Brand campaign",""],["Martech",""]],
    { offset: last.getRange().endOffset, columnWidths: [150, 220], headerRowCount: 1 });
  const t = d.getTables()[0];
  const svg = "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"200\" height=\"60\"><rect width=\"200\" height=\"60\" rx=\"6\" fill=\"#3E3C8F\"/><text x=\"12\" y=\"36\" font-family=\"Helvetica\" font-size=\"13\" fill=\"#fff\">thumbnail</text></svg>";
  const url = "data:image/svg+xml;utf8," + encodeURIComponent(svg);
  const off = t.getCellInsertOffset(1, 1);
  const img = await d.insertImage({ source: url, imageSourceType: "URL", width: 180, height: 54,
    wrappingStyle: "inline", textRange: { startOffset: off, endOffset: off, collapsed: true } });
  return "cellInsertOffset=" + off + " insertImage returned=" + (img ? "an image" : "null") + " images in doc=" + d.getImages().length;'

univer worktree ready cellimg.univer --worktree "$WT" >/dev/null
univer worktree merge cellimg.univer --worktree "$WT" >/dev/null
echo "merged — open cellimg.univer in the viewer; the Evidence cell is empty"
