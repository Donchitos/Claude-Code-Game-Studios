import { describe, expect, it, vi } from "vitest";

vi.mock("phaser", () => ({ default: {} }));

const { CHARACTER_FRAMES, CHARACTER_HEIGHT, CHARACTER_WIDTH, characterTemplateRows, shade } = await import(
  "../client/studio/pixel-art.ts"
);

const STYLES = ["director", "lead", "specialist", "engine-lead", "engine-specialist", "guest", "head", "user"] as const;

describe("character templates", () => {
  it.each(STYLES)("every %s frame is a full 16x20 grid", (style) => {
    const frames = characterTemplateRows(style);
    for (const frameName of CHARACTER_FRAMES) {
      const rows = frames[frameName];
      expect(rows).toHaveLength(CHARACTER_HEIGHT);
      for (const row of rows) expect(row).toHaveLength(CHARACTER_WIDTH);
    }
  });

  it("gives specialists no tie and directors a tie", () => {
    expect(characterTemplateRows("specialist")["down-0"].join("")).not.toContain("t");
    expect(characterTemplateRows("director")["down-0"].join("")).toContain("t");
  });
});

describe("shade", () => {
  it("darkens and lightens a colour", () => {
    expect(shade("#808080", -0.5)).toBe("#404040");
    expect(shade("#000000", 1)).toBe("#ffffff");
  });
});
