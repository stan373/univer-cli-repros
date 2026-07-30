#!/usr/bin/env bash
# Board element authoring: three APIs that report success but produce nothing usable.
# Prereq: npm i -g univer-cli
set -e
rm -f board.univer
univer new board.univer
WT=$(univer worktree add board.univer --json | node -pe 'JSON.parse(require("fs").readFileSync(0)).worktreeId')
BD=$(univer unit add board.univer --worktree "$WT" --type board --name Canvas --json | node -pe 'JSON.parse(require("fs").readFileSync(0)).unitId')

echo "--- A) insertInk: called without error, element never appears ---"
univer execute board.univer --worktree "$WT" --unit "$BD" -e '
  const before = board.describeElements().length;
  const pts = []; for (let i = 0; i < 20; i++) pts.push({ x: 100 + i * 8, y: 100 + (i % 5) * 4 });
  board.insertInk({ model: { kind: "brush", points: pts, color: "#3E3C8F", width: 3, opacity: 1 },
                    style: { color: "#3E3C8F", width: 3 } });
  return "insertInk returned; elements before=" + before + " after=" + board.describeElements().length;
'

echo "--- B) setCustomGeometry: persists in the snapshot, never renders ---"
univer execute board.univer --worktree "$WT" --unit "$BD" -e '
  const T = api.Enum.ShapeTypeEnum;
  const s = board.insertShape({ shapeType: T.Rect, left: 300, top: 100, width: 160, height: 200,
                                fillColor: "#FFFFFF", strokeColor: "#F0509B", strokeWidth: 3 });
  const id = s.id || (s.getId && s.getId());
  board.getShape(id).setCustomGeometry({ pathLst: [{ w: 100, h: 100, fill: "none", stroke: true,
    data: "M 50,10 C 34,20 24,64 22,92 L 78,92 C 76,64 66,20 50,10 z" }] });
  return "customGeometry set on " + id + "; elements=" + board.describeElements().length;
'

echo "--- CONTROL) an identical rect WITHOUT custom geometry, to compare against B ---"
univer execute board.univer --worktree "$WT" --unit "$BD" -e '
  const T = api.Enum.ShapeTypeEnum;
  board.insertShape({ shapeType: T.Rect, left: 520, top: 100, width: 160, height: 200,
                      fillColor: "#FFFFFF", strokeColor: "#8FC5D6", strokeWidth: 3 });
  return "control rect added; elements=" + board.describeElements().length;
'

echo "--- open and compare ---"
univer open board.univer --worktree "$WT" --unit "$BD"
