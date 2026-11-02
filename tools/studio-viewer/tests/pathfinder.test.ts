import { describe, expect, it } from "vitest";
import { findPath } from "../client/studio/pathfinder.ts";

function grid(rows: string[]): boolean[][] {
  return rows.map((row) => [...row].map((cell) => cell === "."));
}

describe("findPath", () => {
  it("walks around a wall with the shortest route", () => {
    const walkable = grid([".....", ".###.", "....."]);
    const path = findPath(walkable, { column: 0, row: 1 }, { column: 4, row: 1 });
    expect(path).not.toBeNull();
    expect(path).toHaveLength(6);
    expect(path?.at(-1)).toEqual({ column: 4, row: 1 });
  });

  it("returns an empty path when already at the goal", () => {
    expect(findPath(grid(["..."]), { column: 1, row: 0 }, { column: 1, row: 0 })).toEqual([]);
  });

  it("returns null when the goal is blocked or enclosed", () => {
    expect(findPath(grid([".#."]), { column: 0, row: 0 }, { column: 1, row: 0 })).toBeNull();
    expect(findPath(grid([".#."]), { column: 0, row: 0 }, { column: 2, row: 0 })).toBeNull();
  });

  it("can start from a blocked tile such as a chair", () => {
    const path = findPath(grid(["#.."]), { column: 0, row: 0 }, { column: 2, row: 0 });
    expect(path).toEqual([
      { column: 1, row: 0 },
      { column: 2, row: 0 },
    ]);
  });
});
