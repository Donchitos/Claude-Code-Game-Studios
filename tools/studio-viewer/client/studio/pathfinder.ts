import type { TilePoint } from "./layout.ts";

interface HeapEntry {
  key: number;
  priority: number;
}

class MinHeap {
  private readonly entries: HeapEntry[] = [];

  get size(): number {
    return this.entries.length;
  }

  push(key: number, priority: number): void {
    this.entries.push({ key, priority });
    let index = this.entries.length - 1;
    while (index > 0) {
      const parent = (index - 1) >> 1;
      if (this.entries[parent]!.priority <= this.entries[index]!.priority) break;
      this.swap(parent, index);
      index = parent;
    }
  }

  pop(): number {
    const top = this.entries[0]!;
    const last = this.entries.pop()!;
    if (this.entries.length > 0) {
      this.entries[0] = last;
      let index = 0;
      for (;;) {
        const left = index * 2 + 1;
        const right = left + 1;
        let smallest = index;
        if (left < this.entries.length && this.entries[left]!.priority < this.entries[smallest]!.priority) smallest = left;
        if (right < this.entries.length && this.entries[right]!.priority < this.entries[smallest]!.priority) smallest = right;
        if (smallest === index) break;
        this.swap(smallest, index);
        index = smallest;
      }
    }
    return top.key;
  }

  private swap(first: number, second: number): void {
    const held = this.entries[first]!;
    this.entries[first] = this.entries[second]!;
    this.entries[second] = held;
  }
}

const NEIGHBOUR_OFFSETS: ReadonlyArray<readonly [number, number]> = [
  [1, 0],
  [-1, 0],
  [0, 1],
  [0, -1],
];

export function findPath(walkable: boolean[][], start: TilePoint, goal: TilePoint): TilePoint[] | null {
  const rows = walkable.length;
  const columns = walkable[0]?.length ?? 0;
  const isInside = (column: number, row: number) => column >= 0 && row >= 0 && column < columns && row < rows;
  const isOpen = (column: number, row: number) => isInside(column, row) && walkable[row]![column] === true;
  if (!isInside(start.column, start.row) || !isOpen(goal.column, goal.row)) return null;
  if (start.column === goal.column && start.row === goal.row) return [];

  const keyOf = (column: number, row: number) => row * columns + column;
  const estimate = (column: number, row: number) => Math.abs(column - goal.column) + Math.abs(row - goal.row);
  const startKey = keyOf(start.column, start.row);
  const goalKey = keyOf(goal.column, goal.row);
  const costSoFar = new Map<number, number>([[startKey, 0]]);
  const cameFrom = new Map<number, number>();
  const closed = new Set<number>();
  const open = new MinHeap();
  open.push(startKey, estimate(start.column, start.row));

  while (open.size > 0) {
    const current = open.pop();
    if (current === goalKey) return reconstructPath(cameFrom, current, startKey, columns);
    if (closed.has(current)) continue;
    closed.add(current);
    const column = current % columns;
    const row = Math.floor(current / columns);
    const nextCost = (costSoFar.get(current) ?? 0) + 1;
    for (const [columnOffset, rowOffset] of NEIGHBOUR_OFFSETS) {
      const neighbourColumn = column + columnOffset;
      const neighbourRow = row + rowOffset;
      if (!isOpen(neighbourColumn, neighbourRow)) continue;
      const neighbourKey = keyOf(neighbourColumn, neighbourRow);
      if (nextCost >= (costSoFar.get(neighbourKey) ?? Number.POSITIVE_INFINITY)) continue;
      costSoFar.set(neighbourKey, nextCost);
      cameFrom.set(neighbourKey, current);
      open.push(neighbourKey, nextCost + estimate(neighbourColumn, neighbourRow));
    }
  }
  return null;
}

function reconstructPath(cameFrom: Map<number, number>, goalKey: number, startKey: number, columns: number): TilePoint[] {
  const path: TilePoint[] = [];
  let current = goalKey;
  while (current !== startKey) {
    path.push({ column: current % columns, row: Math.floor(current / columns) });
    const previous = cameFrom.get(current);
    if (previous === undefined) break;
    current = previous;
  }
  return path.reverse();
}
