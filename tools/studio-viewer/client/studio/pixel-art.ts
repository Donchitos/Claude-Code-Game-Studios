import Phaser from "phaser";
import type { AgentTier } from "../../shared/protocol.ts";

export const CHARACTER_WIDTH = 16;
export const CHARACTER_HEIGHT = 20;
export const CHARACTER_FRAMES = ["down-0", "down-1", "down-2", "up-0", "up-1", "up-2", "type-0", "type-1"] as const;
export type CharacterFrame = (typeof CHARACTER_FRAMES)[number];
export type CharacterStyle = AgentTier | "head" | "user";

export interface CharacterLook {
  seed: string;
  style: CharacterStyle;
  shirt: string;
  accent: string;
}

const OUTLINE = "#231c2b";
const COLLAR = "#f4f0e6";
const SHOES = "#2c2433";
const GLASSES = "#3a3550";
const HEADSET = "#55505f";
const LAB_COAT = "#e9e6df";
const GOLD = "#f2c14e";
const HAIR_COLORS = ["#2b1d14", "#5a3825", "#8a5a2b", "#c99a4b", "#1c1c1c", "#7a7a7a", "#a23b2a", "#3d2b56", "#d8d0c0"];
const SKIN_TONES = ["#f5d0b5", "#e8b996", "#c98e66", "#a8704a", "#7a4e32", "#f0c8a0"];
const PANTS_COLORS = ["#2f3445", "#3b3044", "#28323a", "#4a3b2f", "#2d2d33"];

const FRONT_HALF = [
  "........",
  ".....kkk",
  "....khhh",
  "...khhhh",
  "...khsss",
  "...ksess",
  "...kssss",
  "....ksss",
  "......ks",
  "...kcccw",
  "..kcccct",
  "..kCccct",
  "..ksccct",
  "..kscccc",
  "...kpppp",
  "...kpppp",
  "...kpppk",
  "...kpppk",
  "...kbbbk",
  "....kkk.",
];

const BACK_OVERRIDES: Record<number, string> = {
  4: "...khhhh",
  5: "...khhhh",
  6: "...khhhh",
  7: "....khhh",
  9: "...kcccc",
  10: "..kccccc",
  11: "..kCcccc",
  12: "..kscccc",
  13: "..kscccc",
};

const TYPE_OVERRIDES: ReadonlyArray<Record<number, string>> = [
  { 12: "..kCccct", 13: "...ksccc" },
  { 12: "..kCscct", 13: "...kcccc" },
];

const WALK_LEG_ROWS: Record<number, string> = {
  17: "...kbbbkkpppk...",
  18: "....kkk.kbbbk...",
  19: "..........kkk...",
};

const ENGINE_CAP: Record<number, string> = {
  1: ".....kkk",
  2: "....kHHH",
  3: "...kHHHH",
  4: "..kHHHHH",
};

function mirrorRow(half: string): string {
  return half + [...half].reverse().join("");
}

function reverseRow(row: string): string {
  return [...row].reverse().join("");
}

export function hashString(text: string): number {
  let hash = 2166136261;
  for (const character of text) {
    hash ^= character.codePointAt(0) ?? 0;
    hash = Math.imul(hash, 16777619);
  }
  return hash >>> 0;
}

export function seededRandom(seed: number): () => number {
  let state = seed || 1;
  return () => {
    state = (Math.imul(state, 1664525) + 1013904223) >>> 0;
    return state / 4294967296;
  };
}

export function shade(hexColor: string, amount: number): string {
  const value = Number.parseInt(hexColor.slice(1), 16);
  const channels = [(value >> 16) & 255, (value >> 8) & 255, value & 255].map((channel) => {
    const target = amount < 0 ? 0 : 255;
    return Math.round(channel + (target - channel) * Math.abs(amount));
  });
  return `#${channels.map((channel) => channel.toString(16).padStart(2, "0")).join("")}`;
}

function pick<T>(items: readonly T[], seed: number): T {
  return items[seed % items.length]!;
}

function styleHalfRows(style: CharacterStyle, baseHalf: string[]): string[] {
  const rows = [...baseHalf];
  const replace = (index: number, row: string) => {
    rows[index] = row;
  };
  if (style === "lead" || style === "engine-lead") replace(5, "...kgegs");
  if (style === "engine-lead" || style === "engine-specialist") {
    for (const [index, row] of Object.entries(ENGINE_CAP)) replace(Number(index), row);
  }
  if (style === "head") {
    replace(4, rows[4]!.replace(/^\.\.\./, "..m"));
    replace(5, rows[5]!.replace(/^\.\.\./, "..m"));
  }
  const keepsTie = style === "director" || style === "lead" || style === "engine-lead" || style === "head" || style === "guest";
  return rows.map((row) => {
    let styled = keepsTie ? row : row.replace(/t/g, "c");
    if (style === "user") styled = styled.replace(/w/g, "c");
    if (style === "guest") styled = styled.replace(/t/g, "y");
    return styled;
  });
}

function buildFrames(style: CharacterStyle): Record<CharacterFrame, string[]> {
  const frontHalf = styleHalfRows(style, FRONT_HALF);
  const backHalf = styleHalfRows(
    style,
    FRONT_HALF.map((row, index) => BACK_OVERRIDES[index] ?? row),
  );
  const front = frontHalf.map(mirrorRow);
  const back = backHalf.map(mirrorRow);
  const withWalk = (rows: string[], mirrored: boolean) =>
    rows.map((row, index) => {
      const legRow = WALK_LEG_ROWS[index];
      if (!legRow) return row;
      return mirrored ? reverseRow(legRow) : legRow;
    });
  const typing = TYPE_OVERRIDES.map((overrides) =>
    styleHalfRows(
      style,
      FRONT_HALF.map((row, index) => overrides[index] ?? row),
    ).map(mirrorRow),
  );
  return {
    "down-0": front,
    "down-1": withWalk(front, false),
    "down-2": withWalk(front, true),
    "up-0": back,
    "up-1": withWalk(back, false),
    "up-2": withWalk(back, true),
    "type-0": typing[0]!,
    "type-1": typing[1]!,
  };
}

export function characterTemplateRows(style: CharacterStyle): Record<CharacterFrame, string[]> {
  return buildFrames(style);
}

function characterPalette(look: CharacterLook): Record<string, string> {
  const seed = hashString(look.seed);
  const engineStyle = look.style === "engine-lead" || look.style === "engine-specialist";
  const shirt = engineStyle ? LAB_COAT : look.shirt;
  const tieColor =
    look.style === "director" || look.style === "head" ? GOLD : look.style === "engine-lead" ? look.accent : shade(shirt, -0.4);
  return {
    k: OUTLINE,
    h: pick(HAIR_COLORS, seed),
    s: pick(SKIN_TONES, seed >>> 4),
    e: OUTLINE,
    c: shirt,
    C: shade(shirt, -0.25),
    t: tieColor,
    w: COLLAR,
    p: pick(PANTS_COLORS, seed >>> 8),
    b: SHOES,
    g: GLASSES,
    m: HEADSET,
    H: look.accent,
    y: GOLD,
  };
}

function paintRows(
  context: CanvasRenderingContext2D,
  rows: string[],
  palette: Record<string, string>,
  offsetX: number,
  offsetY: number,
): void {
  rows.forEach((row, rowIndex) => {
    [...row].forEach((symbol, columnIndex) => {
      const color = palette[symbol];
      if (!color) return;
      context.fillStyle = color;
      context.fillRect(offsetX + columnIndex, offsetY + rowIndex, 1, 1);
    });
  });
}

export function createCanvasTexture(
  scene: Phaser.Scene,
  key: string,
  width: number,
  height: number,
): { texture: Phaser.Textures.CanvasTexture; context: CanvasRenderingContext2D } | null {
  if (scene.textures.exists(key)) return null;
  const texture = scene.textures.createCanvas(key, width, height);
  if (!texture) return null;
  return { texture, context: texture.getContext() };
}

export function createCharacterTexture(scene: Phaser.Scene, key: string, look: CharacterLook): void {
  const canvas = createCanvasTexture(scene, key, CHARACTER_WIDTH * CHARACTER_FRAMES.length, CHARACTER_HEIGHT);
  if (!canvas) return;
  const frames = buildFrames(look.style);
  const palette = characterPalette(look);
  CHARACTER_FRAMES.forEach((frameName, frameIndex) => {
    const offsetX = frameIndex * CHARACTER_WIDTH;
    paintRows(canvas.context, frames[frameName], palette, offsetX, 0);
    canvas.texture.add(frameName, 0, offsetX, 0, CHARACTER_WIDTH, CHARACTER_HEIGHT);
  });
  canvas.texture.refresh();
}

