#!/usr/bin/env bash
# Cross-unit Formula Shape binds but never calculates; the same-unit control does.
# Prereq: npm i -g univer-cli
set -e
rm -f fs-repro.univer
univer new fs-repro.univer
WT=$(univer worktree add fs-repro.univer --json | node -pe 'JSON.parse(require("fs").readFileSync(0)).worktreeId')
SHEET=$(univer unit add fs-repro.univer --worktree "$WT" --type sheet --name "Q3 Revenue Model" --json | node -pe 'JSON.parse(require("fs").readFileSync(0)).unitId')
BOARD=$(univer unit add fs-repro.univer --worktree "$WT" --type board --name Canvas --json | node -pe 'JSON.parse(require("fs").readFileSync(0)).unitId')

echo "--- seed the sheet and run the SAME-UNIT control ---"
univer execute fs-repro.univer --worktree "$WT" --unit "$SHEET" -e '
  const sh = workbook.getActiveSheet();
  sh.getRange("F1").setValue(200000); sh.getRange("F2").setValue(231121.6);
  const T = api.Enum.ShapeTypeEnum;
  const shp = sh.insertShape({ shapeType: T.Rect, transform: { left: 500, top: 40, width: 220, height: 60 } });
  const id = shp.getId ? shp.getId() : shp.id;
  sh.getShape(id).setFormula({ formula: "=SUM(F1:F2)", externalReferences: [] });
  api.getFormula().executeCalculation();
  await api.getFormula().onCalculationResultApplied(30000);
  return "same-unit result = " + JSON.stringify(sh.getShape(id).getFormulaResult());'

echo "--- CROSS-UNIT case: shape on the board, source is the sheet ---"
univer execute fs-repro.univer --worktree "$WT" --unit "$BOARD" -e '
  const T = api.Enum.ShapeTypeEnum;
  const source = api.getWorkbook("'"$SHEET"'");
  const formula = api.getFormula();
  const shape = board.insertShape({ shapeType: T.Rect, transform: { left: 60, top: 60, width: 340, height: 100 } });
  const id = shape.getId ? shape.getId() : shape.id;
  const reference = formula.buildReference({
    hostUnitId: "'"$BOARD"'",
    unit: { unitId: source.getId(), formulaQualifier: "Q3 Revenue Model" },
    target: { kind: "sheetRange", sheetName: source.getActiveSheet().getSheetName(), range: "F1:F2" },
  });
  board.getShape(id).setFormula({ formula: "=SUM(" + reference + ")", externalReferences: [] });
  formula.executeCalculation();
  await formula.onCalculationResultApplied(30000);
  const s = board.getShape(id);
  return "reference = " + reference +
         " | isFormulaShape = " + (s.isFormulaShape ? s.isFormulaShape() : "n/a") +
         " | cross-unit result = " + JSON.stringify(s.getFormulaResult());'

univer worktree ready fs-repro.univer --worktree "$WT" >/dev/null
univer worktree merge fs-repro.univer --worktree "$WT" >/dev/null
echo "merged — open fs-repro.univer in the viewer"
