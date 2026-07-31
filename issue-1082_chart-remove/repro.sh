#!/usr/bin/env bash
# FDocumentCharts.remove() always rejects with an internal TypeError; a doc chart cannot be deleted.
# Prereq: npm i -g univer-cli
set -e
rm -f chartremove.univer
univer new chartremove.univer
WT=$(univer worktree add chartremove.univer --json | node -pe 'JSON.parse(require("fs").readFileSync(0)).worktreeId')
DOC=$(univer unit add chartremove.univer --worktree "$WT" --type doc --name ChartRemove --json | node -pe 'JSON.parse(require("fs").readFileSync(0)).unitId')

univer execute chartremove.univer --worktree "$WT" --unit "$DOC" -e '
  const d = api.getDocument("'"$DOC"'");
  const p0 = d.getParagraphs();
  d.replaceRange({ startOffset: p0[0].getRange().startOffset, endOffset: p0[p0.length-1].getRange().endOffset },
    api.convertMarkdown("# Chart removal\n\nAnchor paragraph.\n\nTail paragraph.\n"));
  let i = -1; d.getParagraphs().forEach((x, k) => { if ((x.getText()||"").startsWith("Anchor")) i = k; });
  const CT = api.Enum.ChartTypeString;
  const b = d.charts.create().setType(CT.Column).setData([["A","B"],["x",1],["y",2]])
    .setCategoryField(0).setValueFields([1]).setAnchor({ kind: "paragraph", index: i, where: "after" }).setInline();
  const c = await d.charts.insert(b);
  const out = ["inserted, count=" + d.charts.list().length];
  try { await d.charts.remove(c.getId()); out.push("remove(id): resolved"); }
  catch (e) { out.push("remove(id) REJECTED: " + e.message); }
  try { await d.charts.remove(d.charts.list()[0]); out.push("remove(builder): resolved"); }
  catch (e) { out.push("remove(builder) REJECTED: " + e.message); }
  out.push("final count=" + d.charts.list().length);
  return out.join(" | ");'
