import type Phaser from "phaser";
import type { FloorStyle } from "./layout.ts";
import { createCanvasTexture, hashString, seededRandom, shade } from "./pixel-art.ts";

type Painter = (context: CanvasRenderingContext2D, random: () => number) => void;

const GOLD = "#f2c14e";
const WALL_CAP = "#5a4470";
const WALL_CAP_LIGHT = "#7a5f94";
const CORRIDOR_WALLPAPER = "#e9d9c0";
export const PLANT_VARIANTS = 4;
export const POSTER_VARIANTS = 4;

function paintTexture(scene: Phaser.Scene, key: string, width: number, height: number, painter: Painter): void {
  const canvas = createCanvasTexture(scene, key, width, height);
  if (!canvas) return;
  painter(canvas.context, seededRandom(hashString(key)));
  canvas.texture.refresh();
}

function fill(context: CanvasRenderingContext2D, color: string, left: number, top: number, width: number, height: number): void {
  context.fillStyle = color;
  context.fillRect(left, top, width, height);
}

function speckle(context: CanvasRenderingContext2D, random: () => number, color: string, count: number, width = 16, height = 16): void {
  for (let index = 0; index < count; index += 1) {
    fill(context, color, Math.floor(random() * width), Math.floor(random() * height), 1, 1);
  }
}

const FLOOR_PAINTERS: Record<FloorStyle, Painter> = {
  wood: (context, random) => {
    fill(context, "#c98a50", 0, 0, 16, 16);
    for (const plankTop of [0, 4, 8, 12]) {
      fill(context, "#b0733f", 0, plankTop + 3, 16, 1);
      fill(context, "#b0733f", (plankTop * 5) % 16, plankTop, 1, 3);
      fill(context, "#d99c62", 0, plankTop, 16, 1);
    }
    speckle(context, random, "#dca46c", 8);
  },
  parquet: (context) => {
    fill(context, "#e9cfa4", 0, 0, 16, 16);
    for (let step = 0; step < 4; step += 1) {
      fill(context, "#d8b483", step * 4, step * 4, 4, 1);
      fill(context, "#d8b483", (step * 4 + 8) % 16, step * 4, 1, 4);
      fill(context, "#f5ddb8", step * 4 + 1, step * 4 + 1, 2, 1);
    }
    fill(context, "#d8b483", 0, 15, 16, 1);
  },
  carpet: (context, random) => {
    fill(context, "#9c3d55", 0, 0, 16, 16);
    for (const [column, row] of [
      [3, 3],
      [11, 11],
      [11, 3],
      [3, 11],
    ] as const) {
      fill(context, "#c25a6f", column, row, 2, 2);
      fill(context, GOLD, column + 4, row + 4, 1, 1);
    }
    speckle(context, random, "#8a3349", 10);
  },
  lab: (context, random) => {
    fill(context, "#4a6b94", 0, 0, 16, 16);
    fill(context, "#5a7fae", 0, 0, 16, 1);
    fill(context, "#5a7fae", 0, 0, 1, 16);
    fill(context, "#6d93c2", 7, 7, 2, 2);
    speckle(context, random, "#41608a", 6);
  },
  meeting: (context, random) => {
    fill(context, "#2f8577", 0, 0, 16, 16);
    speckle(context, random, "#3a9a8a", 16);
    fill(context, "#47ab98", 4, 4, 1, 1);
    fill(context, "#47ab98", 12, 12, 1, 1);
  },
  lounge: (context, random) => {
    fill(context, "#7a58a8", 0, 0, 16, 16);
    speckle(context, random, "#8a68b8", 18);
    fill(context, "#a07fd0", 8, 8, 1, 1);
  },
  lobby: (context) => {
    fill(context, "#f3e6d0", 0, 0, 8, 8);
    fill(context, "#f3e6d0", 8, 8, 8, 8);
    fill(context, "#e6b98f", 8, 0, 8, 8);
    fill(context, "#e6b98f", 0, 8, 8, 8);
    fill(context, "#fff6e6", 1, 1, 3, 1);
    fill(context, "#f0c9a1", 9, 9, 3, 1);
  },
  kitchen: (context) => {
    fill(context, "#fff4dc", 0, 0, 16, 16);
    fill(context, "#9fd9c6", 0, 0, 8, 8);
    fill(context, "#9fd9c6", 8, 8, 8, 8);
  },
  corridor: (context, random) => {
    fill(context, "#9b6e4a", 0, 0, 16, 16);
    for (const plankTop of [0, 8]) {
      fill(context, "#86593a", 0, plankTop + 7, 16, 1);
      fill(context, "#86593a", plankTop === 0 ? 5 : 11, plankTop, 1, 7);
      fill(context, "#ab7d57", 0, plankTop, 16, 1);
    }
    speckle(context, random, "#a77a54", 6);
  },
  closet: (context) => {
    fill(context, "#2e3342", 0, 0, 16, 16);
    fill(context, "#3a4154", 0, 0, 16, 1);
    fill(context, "#3a4154", 0, 8, 16, 1);
  },
};

export function floorTextureKey(style: FloorStyle): string {
  return `floor-${style}`;
}

export function wallpaperColorFor(roomWallColor: string | null): string {
  return roomWallColor ?? CORRIDOR_WALLPAPER;
}

function paintWallpaper(context: CanvasRenderingContext2D, color: string, top: number, height: number): void {
  fill(context, color, 0, top, 16, height);
  const stripe = shade(color, 0.22);
  const shadow = shade(color, -0.1);
  for (const column of [2, 10]) fill(context, stripe, column, top, 2, height);
  for (let row = top + 2; row < top + height; row += 5) fill(context, shadow, 6, row, 1, 1);
}

export function wallFrontKey(color: string): string {
  return `wall-front-${color.slice(1)}`;
}

export function wallFaceKey(color: string): string {
  return `wall-face-${color.slice(1)}`;
}

export function ensureWallTextures(scene: Phaser.Scene, color: string): void {
  paintTexture(scene, wallFrontKey(color), 16, 16, (context) => {
    fill(context, WALL_CAP, 0, 0, 16, 6);
    fill(context, WALL_CAP_LIGHT, 0, 0, 16, 2);
    fill(context, shade(WALL_CAP, -0.25), 0, 5, 16, 1);
    paintWallpaper(context, color, 6, 10);
    fill(context, shade(color, 0.35), 0, 6, 16, 1);
  });
  paintTexture(scene, wallFaceKey(color), 16, 16, (context) => {
    paintWallpaper(context, color, 0, 12);
    fill(context, "#7a4f33", 0, 12, 16, 3);
    fill(context, "#9a6a46", 0, 12, 16, 1);
    fill(context, "rgba(0,0,0,0.18)", 0, 15, 16, 1);
  });
}

function paintRadial(context: CanvasRenderingContext2D, size: number, stops: Array<[number, string]>): void {
  const gradient = context.createRadialGradient(size / 2, size / 2, 0, size / 2, size / 2, size / 2);
  for (const [offset, color] of stops) gradient.addColorStop(offset, color);
  context.fillStyle = gradient;
  context.fillRect(0, 0, size, size);
}

function paintPlants(scene: Phaser.Scene): void {
  const pot = (context: CanvasRenderingContext2D, color: string) => {
    fill(context, shade(color, -0.2), 4, 17, 8, 7);
    fill(context, color, 3, 16, 10, 3);
    fill(context, shade(color, 0.25), 4, 16, 8, 1);
  };
  paintTexture(scene, "plant-0", 16, 24, (context, random) => {
    for (let leaf = 0; leaf < 30; leaf += 1) {
      const column = 2 + Math.floor(random() * 12);
      const row = 3 + Math.floor(random() * 12);
      fill(context, random() > 0.5 ? "#3f9a4e" : "#5cc06a", column, row, 2, 2);
    }
    fill(context, "#7be08a", 6, 5, 2, 1);
    pot(context, "#d0643f");
  });
  paintTexture(scene, "plant-1", 16, 24, (context) => {
    for (const [column, height, color] of [
      [5, 12, "#2f8a55"],
      [7, 15, "#3fa866"],
      [9, 13, "#2f8a55"],
      [11, 10, "#4cbf78"],
    ] as const) {
      fill(context, color, column, 16 - height, 2, height);
      fill(context, "#d8e86a", column, 16 - height, 1, height);
    }
    pot(context, "#e8e0d0");
  });
  paintTexture(scene, "plant-2", 16, 24, (context, random) => {
    for (let leaf = 0; leaf < 22; leaf += 1) {
      fill(context, random() > 0.5 ? "#3f9a4e" : "#2f7f40", 2 + Math.floor(random() * 12), 5 + Math.floor(random() * 10), 2, 2);
    }
    for (let flower = 0; flower < 7; flower += 1) {
      const color = ["#ff7aa8", "#ffd447", "#ff9a5c", "#c58cff"][flower % 4]!;
      fill(context, color, 2 + Math.floor(random() * 11), 3 + Math.floor(random() * 9), 2, 2);
    }
    pot(context, "#5b8def");
  });
  paintTexture(scene, "plant-3", 16, 24, (context) => {
    for (const [column, row] of [
      [1, 6],
      [8, 3],
      [3, 10],
      [9, 9],
      [5, 1],
    ] as const) {
      fill(context, "#2e8b57", column, row, 6, 5);
      fill(context, "#4cbf78", column + 1, row + 1, 4, 1);
      fill(context, "#1f6b41", column + 3, row, 1, 5);
    }
    fill(context, "#1f6b41", 7, 10, 2, 6);
    pot(context, "#f2c14e");
  });
}

function paintPosters(scene: Phaser.Scene): void {
  const frame = (context: CanvasRenderingContext2D) => {
    fill(context, "#3a2a20", 0, 0, 12, 15);
  };
  paintTexture(scene, "poster-0", 12, 15, (context) => {
    frame(context);
    fill(context, "#7fd0ff", 1, 1, 10, 13);
    fill(context, "#ffd447", 7, 2, 3, 3);
    fill(context, "#4a7f5a", 1, 9, 10, 5);
    fill(context, "#6fbf5a", 3, 7, 4, 3);
    fill(context, "#ffffff", 4, 7, 2, 1);
  });
  paintTexture(scene, "poster-1", 12, 15, (context) => {
    frame(context);
    fill(context, "#2a2340", 1, 1, 10, 13);
    for (const [column, row] of [
      [3, 5],
      [7, 5],
      [2, 6],
      [8, 6],
      [3, 8],
      [7, 8],
      [4, 9],
      [6, 9],
      [5, 10],
    ] as const) {
      fill(context, "#ff5c7a", column, row, 2, 2);
    }
  });
  paintTexture(scene, "poster-2", 12, 15, (context) => {
    frame(context);
    fill(context, "#ffd8a8", 1, 1, 10, 13);
    fill(context, "#d97757", 2, 6, 8, 4);
    fill(context, "#2a2340", 3, 7, 1, 2);
    fill(context, "#2a2340", 8, 7, 1, 1);
    fill(context, "#2a2340", 7, 8, 1, 1);
  });
  paintTexture(scene, "poster-3", 12, 15, (context) => {
    frame(context);
    fill(context, "#9b6bd1", 1, 1, 10, 13);
    fill(context, GOLD, 5, 3, 2, 2);
    fill(context, GOLD, 3, 5, 6, 2);
    fill(context, GOLD, 4, 7, 4, 2);
    fill(context, GOLD, 3, 9, 2, 2);
    fill(context, GOLD, 7, 9, 2, 2);
  });
}

function paintDesks(scene: Phaser.Scene): void {
  const desk = (context: CanvasRenderingContext2D, width: number, top: string, face: string, accent: string) => {
    fill(context, face, 0, 11, width, 6);
    fill(context, shade(face, -0.3), 0, 16, width, 1);
    fill(context, shade(face, -0.35), 1, 17, 2, 3);
    fill(context, shade(face, -0.35), width - 3, 17, 2, 3);
    fill(context, top, 0, 0, width, 12);
    fill(context, shade(top, 0.18), 1, 1, width - 2, 2);
    fill(context, accent, 0, 11, width, 1);
  };
  paintTexture(scene, "desk", 32, 20, (context) => {
    desk(context, 32, "#d39a5e", "#9a6236", "#e8b27a");
    fill(context, "#fbf6ea", 21, 5, 6, 4);
    fill(context, "#d97757", 5, 4, 3, 3);
    fill(context, "#ffffff", 6, 4, 1, 1);
  });
  paintTexture(scene, "executive-desk", 64, 22, (context) => {
    desk(context, 64, "#7a4a33", "#4e2c1e", GOLD);
    fill(context, "#2f8a55", 48, 3, 8, 6);
    fill(context, "#fbf6ea", 8, 4, 7, 5);
    fill(context, GOLD, 30, 3, 3, 3);
  });
  paintTexture(scene, "reception-desk", 128, 24, (context) => {
    desk(context, 128, "#fff4e2", "#d97757", "#f2a07f");
    for (let column = 8; column < 128; column += 16) fill(context, "#c45f40", column, 13, 8, 3);
    fill(context, GOLD, 100, 3, 6, 5);
    fill(context, "#5bc0a0", 14, 3, 5, 5);
  });
}

function paintAppliances(scene: Phaser.Scene): void {
  paintTexture(scene, "monitor-off", 14, 11, (context) => {
    fill(context, "#2a2a35", 0, 0, 14, 9);
    fill(context, "#1d2330", 1, 1, 12, 7);
    fill(context, "#3a3a48", 5, 9, 4, 2);
  });
  for (const variant of [0, 1]) {
    paintTexture(scene, `monitor-on-${variant}`, 14, 11, (context, random) => {
      fill(context, "#2a2a35", 0, 0, 14, 9);
      fill(context, "#1d4a78", 1, 1, 12, 7);
      const lineColors = ["#7fd1ff", "#ffd447", "#9be37a", "#ff8fa3"];
      for (let line = 0; line < 3; line += 1) {
        const width = 3 + Math.floor(random() * 7) + variant;
        fill(context, lineColors[(line + variant) % lineColors.length]!, 2 + (line % 2), 2 + line * 2, Math.min(width, 10), 1);
      }
      fill(context, "#3a3a48", 5, 9, 4, 2);
    });
  }
  paintTexture(scene, "chair", 12, 12, (context) => {
    fill(context, "#2f6f8a", 1, 0, 10, 4);
    fill(context, "#3f8aa8", 0, 4, 12, 6);
    fill(context, "#5aa6c4", 1, 5, 10, 2);
    fill(context, "#24323d", 5, 10, 2, 2);
  });
  paintTexture(scene, "bookshelf", 32, 26, (context, random) => {
    fill(context, "#7a4a2e", 0, 0, 32, 26);
    fill(context, "#9a6240", 0, 0, 32, 2);
    const bookColors = ["#e05a5a", "#5b8def", "#6fbf5a", "#ffd447", "#9b6bd1", "#4ac0d9", "#ff9a5c", "#ff7aa8"];
    for (const shelfTop of [3, 10, 17]) {
      fill(context, "#4e2c1e", 1, shelfTop + 6, 30, 1);
      let column = 2;
      while (column < 30) {
        const width = 1 + Math.floor(random() * 2);
        fill(context, bookColors[Math.floor(random() * bookColors.length)]!, column, shelfTop + Math.floor(random() * 2), width, 6);
        column += width + (random() > 0.8 ? 2 : 1);
      }
    }
  });
  paintTexture(scene, "printer", 16, 14, (context) => {
    fill(context, "#eef0f5", 1, 3, 14, 10);
    fill(context, "#b8bcc8", 1, 11, 14, 2);
    fill(context, "#ffffff", 4, 0, 8, 5);
    fill(context, "#5bd17a", 12, 5, 2, 1);
  });
  paintTexture(scene, "coffee-machine", 14, 20, (context) => {
    fill(context, "#c0392b", 1, 0, 12, 18);
    fill(context, "#e05a4a", 2, 1, 10, 4);
    fill(context, "#ffd447", 10, 2, 2, 2);
    fill(context, "#2a1a1a", 4, 9, 6, 6);
    fill(context, "#fbf6ea", 5, 12, 4, 3);
  });
  paintTexture(scene, "water-cooler", 12, 26, (context) => {
    fill(context, "#8fd3ff", 2, 0, 8, 10);
    fill(context, "#c8ecff", 3, 1, 3, 7);
    fill(context, "#f2f2f6", 1, 10, 10, 15);
    fill(context, "#5b8def", 4, 14, 4, 2);
  });
  paintTexture(scene, "fridge", 16, 30, (context) => {
    fill(context, "#9fd9c6", 1, 0, 14, 30);
    fill(context, "#7fc1ad", 1, 11, 14, 1);
    fill(context, "#c8efe2", 2, 1, 12, 2);
    fill(context, "#e8e8ee", 12, 4, 1, 5);
    fill(context, "#e8e8ee", 12, 14, 1, 8);
    fill(context, "#ff7aa8", 4, 15, 3, 3);
  });
  for (const [name, color] of [
    ["arcade-pink", "#e05a7a"],
    ["arcade-blue", "#4ab0d9"],
  ] as const) {
    paintTexture(scene, name, 16, 30, (context) => {
      fill(context, color, 1, 0, 14, 30);
      fill(context, shade(color, -0.35), 1, 24, 14, 6);
      fill(context, "#141420", 3, 4, 10, 8);
      fill(context, "#7fffd4", 4, 5, 3, 2);
      fill(context, "#ffe066", 8, 8, 3, 2);
      fill(context, "#222", 3, 15, 10, 3);
      fill(context, GOLD, 5, 15, 2, 2);
      fill(context, "#e05a3a", 9, 16, 2, 2);
    });
  }
  paintTexture(scene, "tv", 64, 22, (context) => {
    fill(context, "#1d1d26", 0, 0, 64, 18);
    fill(context, "#ff9a5c", 2, 2, 60, 14);
    fill(context, "#ffd447", 2, 2, 60, 5);
    fill(context, "#6fbf5a", 2, 11, 60, 5);
    fill(context, "#2a2340", 40, 6, 6, 5);
    fill(context, "#1d1d26", 28, 18, 8, 4);
  });
  for (const variant of [0, 1]) {
    paintTexture(scene, `server-rack-${variant}`, 16, 32, (context, random) => {
      fill(context, "#1b1e26", 1, 0, 14, 32);
      for (let slot = 0; slot < 7; slot += 1) {
        fill(context, "#2c313d", 2, 2 + slot * 4, 12, 3);
        const lit = (slot + variant) % 2 === 0 || random() > 0.6;
        fill(context, lit ? "#5bd17a" : "#1f5130", 11, 3 + slot * 4, 1, 1);
        fill(context, random() > 0.5 ? GOLD : "#3a3320", 9, 3 + slot * 4, 1, 1);
      }
    });
  }
  paintTexture(scene, "welcome-mat", 64, 32, (context) => {
    fill(context, "#7a4e32", 0, 0, 64, 32);
    fill(context, "#c98a50", 2, 2, 60, 28);
    fill(context, "#d97757", 6, 14, 52, 4);
  });
  paintTexture(scene, "lamp", 12, 32, (context) => {
    fill(context, "#3a2a20", 3, 29, 6, 3);
    fill(context, "#c9a24a", 5, 10, 2, 20);
    fill(context, "#fff2c8", 1, 1, 10, 9);
    fill(context, "#ffe08a", 0, 7, 12, 3);
    fill(context, "#fffbe8", 3, 2, 3, 4);
  });
}

function paintLight(scene: Phaser.Scene): void {
  paintTexture(scene, "window", 32, 28, (context) => {
    fill(context, "#8a5a3a", 0, 0, 32, 26);
    const sky = context.createLinearGradient(0, 2, 0, 22);
    sky.addColorStop(0, "#7fc8ff");
    sky.addColorStop(0.6, "#bfe6ff");
    sky.addColorStop(1, "#fff1c4");
    context.fillStyle = sky;
    context.fillRect(2, 2, 28, 20);
    fill(context, "#ffffff", 5, 6, 6, 2);
    fill(context, "#ffffff", 8, 5, 3, 1);
    fill(context, "#8a5a3a", 15, 2, 2, 20);
    fill(context, "#8a5a3a", 2, 11, 28, 2);
    fill(context, "#fff8e0", 3, 3, 1, 7);
    fill(context, "#b07a52", 0, 22, 32, 4);
    fill(context, "#d39a6a", 0, 22, 32, 1);
    fill(context, "#e86a8a", 2, 24, 3, 2);
    fill(context, "#3f9a4e", 26, 23, 3, 3);
  });
  paintTexture(scene, "sunbeam", 64, 192, (context) => {
    const image = context.createImageData(64, 192);
    for (let row = 0; row < 192; row += 1) {
      const fade = Math.pow(1 - row / 192, 1.3);
      for (let column = 0; column < 64; column += 1) {
        const edge = Math.pow(Math.sin((Math.PI * (column + 0.5)) / 64), 0.9);
        const offset = (row * 64 + column) * 4;
        image.data[offset] = 255;
        image.data[offset + 1] = 255;
        image.data[offset + 2] = 255;
        image.data[offset + 3] = Math.round(255 * fade * edge);
      }
    }
    context.putImageData(image, 0, 0);
  });
  paintTexture(scene, "glow", 64, 64, (context) =>
    paintRadial(context, 64, [
      [0, "rgba(255,255,255,0.9)"],
      [0.35, "rgba(255,255,255,0.35)"],
      [1, "rgba(255,255,255,0)"],
    ]),
  );
  paintTexture(scene, "shadow", 16, 6, (context) => {
    context.fillStyle = "rgba(20,10,30,0.38)";
    context.beginPath();
    context.ellipse(8, 3, 7.5, 2.6, 0, 0, Math.PI * 2);
    context.fill();
  });
  paintTexture(scene, "mote", 2, 2, (context) => fill(context, "#ffffff", 0, 0, 2, 2));
}

export const GLYPH_FRAMES = ["glyph-0", "glyph-1", "glyph-2", "glyph-3", "glyph-4", "glyph-5"];

const GLYPH_PATTERNS: ReadonlyArray<{ color: string; rows: string[] }> = [
  { color: "#7fd1ff", rows: ["..##", ".#..", "#...", ".#..", "..##"] },
  { color: "#7fd1ff", rows: ["##..", "..#.", "...#", "..#.", "##.."] },
  { color: "#ffd447", rows: ["...#", "..#.", ".#..", "#...", "...."] },
  { color: "#9be37a", rows: [".#.#", "####", ".#.#", "####", ".#.#"] },
  { color: "#ff8fa3", rows: ["#..#", ".##.", ".##.", "#..#", "...."] },
  { color: "#c58cff", rows: ["....", "...#", "#.#.", ".#..", "...."] },
];

function paintWorkProps(scene: Phaser.Scene): void {
  paintTexture(scene, "document", 10, 12, (context) => {
    fill(context, "#c9bfa8", 1, 1, 9, 11);
    fill(context, "#fffdf6", 0, 0, 9, 11);
    for (const row of [3, 5, 7]) fill(context, "#9aa3b5", 2, row, 5, 1);
    fill(context, "#d97757", 2, 1, 3, 1);
  });
  paintTexture(scene, "document-done", 10, 12, (context) => {
    fill(context, "#c9bfa8", 1, 1, 9, 11);
    fill(context, "#f2fff0", 0, 0, 9, 11);
    for (const row of [3, 5]) fill(context, "#9aa3b5", 2, row, 5, 1);
    fill(context, "#3fa866", 3, 8, 1, 1);
    fill(context, "#3fa866", 4, 9, 1, 1);
    fill(context, "#3fa866", 5, 8, 1, 1);
    fill(context, "#3fa866", 6, 7, 1, 1);
  });
  paintTexture(scene, "laptop", 14, 9, (context) => {
    fill(context, "#3a3a48", 1, 0, 12, 6);
    fill(context, "#1d4a78", 2, 1, 10, 4);
    fill(context, "#7fd1ff", 3, 2, 5, 1);
    fill(context, "#ffd447", 3, 3, 3, 1);
    fill(context, "#b8bcc8", 0, 6, 14, 3);
  });
  const canvas = createCanvasTexture(scene, "glyphs", GLYPH_FRAMES.length * 5, 5);
  if (!canvas) return;
  GLYPH_PATTERNS.forEach((pattern, index) => {
    pattern.rows.forEach((row, rowIndex) => {
      [...row].forEach((symbol, columnIndex) => {
        if (symbol === "#") fill(canvas.context, pattern.color, index * 5 + columnIndex, rowIndex, 1, 1);
      });
    });
    canvas.texture.add(GLYPH_FRAMES[index]!, 0, index * 5, 0, 4, 5);
  });
  canvas.texture.refresh();
}

export const CAT_FRAMES = ["cat-sit", "cat-walk-0", "cat-walk-1", "cat-sleep"] as const;
export const FIRE_FRAMES = ["fire-0", "fire-1", "fire-2"] as const;
export const RAIN_FRAMES = ["rain-0", "rain-1", "rain-2"] as const;

const CAT_PATTERNS: Record<(typeof CAT_FRAMES)[number], string[]> = {
  "cat-sit": [
    "..o...o.....",
    "..oo.oo.....",
    "..ooooo.....",
    "..oeoeo.....",
    "...ooo......",
    "..ooooo.....",
    ".oooooo..o..",
    ".oooooo.o...",
    "..o..o.oo...",
  ],
  "cat-walk-0": [
    "........o.o.",
    "........ooo.",
    "o.......oeoe",
    ".ooooooooooo",
    ".oooooooooo.",
    ".oooooooo...",
    ".o..o..o..o.",
    "o...o..o...o",
    "............",
  ],
  "cat-walk-1": [
    "........o.o.",
    "........ooo.",
    ".o......oeoe",
    "..oooooooooo",
    ".oooooooooo.",
    ".oooooooo...",
    "..o.o..o.o..",
    "..o.o..o.o..",
    "............",
  ],
  "cat-sleep": [
    "............",
    "............",
    "............",
    "....oooo....",
    "..oooooooo..",
    ".ooooooooooo",
    ".oo-oooooooo",
    "..oooooooo..",
    "............",
  ],
};

function paintFramedTexture(
  scene: Phaser.Scene,
  key: string,
  frameNames: readonly string[],
  frameWidth: number,
  frameHeight: number,
  painter: (context: CanvasRenderingContext2D, frameIndex: number, offsetX: number) => void,
): void {
  const canvas = createCanvasTexture(scene, key, frameWidth * frameNames.length, frameHeight);
  if (!canvas) return;
  frameNames.forEach((frameName, frameIndex) => {
    painter(canvas.context, frameIndex, frameIndex * frameWidth);
    canvas.texture.add(frameName, 0, frameIndex * frameWidth, 0, frameWidth, frameHeight);
  });
  canvas.texture.refresh();
}

function paintCozyProps(scene: Phaser.Scene): void {
  paintTexture(scene, "fireplace", 64, 34, (context) => {
    fill(context, "#9a4a3a", 0, 4, 64, 30);
    for (let row = 6; row < 34; row += 5) {
      for (let column = (row / 5) % 2 === 0 ? 0 : 4; column < 64; column += 9) fill(context, "#b45a46", column, row, 7, 3);
    }
    fill(context, "#e9dcc8", 0, 0, 64, 6);
    fill(context, "#fff4e2", 0, 0, 64, 2);
    fill(context, "#2a1414", 14, 12, 36, 22);
    fill(context, "#1a0c0c", 16, 14, 32, 20);
    fill(context, "#6b3a20", 18, 29, 28, 3);
    fill(context, "#f2c14e", 8, 1, 3, 3);
    fill(context, "#3f9a4e", 52, 0, 4, 4);
  });
  paintFramedTexture(scene, "fire", FIRE_FRAMES, 28, 18, (context, frameIndex, offsetX) => {
    const heights = [
      [10, 15, 12, 16, 9],
      [13, 11, 16, 12, 14],
      [11, 16, 10, 14, 12],
    ][frameIndex]!;
    heights.forEach((height, index) => {
      const column = offsetX + 2 + index * 5;
      fill(context, "#e8462a", column, 18 - height, 5, height);
      fill(context, "#ff9a3c", column + 1, 18 - height + 3, 3, height - 3);
      fill(context, "#ffe08a", column + 2, 18 - height + 7, 1, Math.max(1, height - 8));
    });
  });
  paintTexture(scene, "armchair", 18, 18, (context) => {
    fill(context, "#ffffff", 1, 0, 16, 7);
    fill(context, "#e6e6e6", 0, 5, 18, 10);
    fill(context, "#ffffff", 3, 6, 12, 5);
    fill(context, "#cfcfcf", 0, 14, 18, 3);
    fill(context, "#5b3a29", 2, 16, 2, 2);
    fill(context, "#5b3a29", 14, 16, 2, 2);
  });
  paintTexture(scene, "beanbag", 16, 12, (context) => {
    fill(context, "#ffffff", 2, 2, 12, 9);
    fill(context, "#ffffff", 0, 5, 16, 6);
    fill(context, "#e6e6e6", 1, 9, 14, 3);
    fill(context, "#f2f2f2", 4, 3, 5, 2);
  });
  paintTexture(scene, "hanging-plant", 16, 22, (context, random) => {
    fill(context, "#8a6a4a", 7, 0, 1, 7);
    fill(context, "#c06a48", 4, 7, 8, 5);
    fill(context, "#d98a62", 4, 7, 8, 1);
    for (let leaf = 0; leaf < 18; leaf += 1) {
      const column = 2 + Math.floor(random() * 12);
      const row = 9 + Math.floor(random() * 12);
      fill(context, random() > 0.5 ? "#3f9a4e" : "#5cc06a", column, row, 2, 2);
    }
  });
  paintTexture(scene, "bulb", 3, 4, (context) => {
    fill(context, "#ffffff", 0, 1, 3, 3);
    fill(context, "#6b5a4a", 1, 0, 1, 1);
  });
  paintFramedTexture(scene, "cat", CAT_FRAMES, 12, 9, (context, frameIndex, offsetX) => {
    const rows = CAT_PATTERNS[CAT_FRAMES[frameIndex]!];
    rows.forEach((row, rowIndex) => {
      [...row].forEach((symbol, columnIndex) => {
        const color = symbol === "o" ? "#f0a35a" : symbol === "e" ? "#2a1c14" : symbol === "-" ? "#c97a3a" : null;
        if (color) fill(context, color, offsetX + columnIndex, rowIndex, 1, 1);
      });
    });
  });
  paintWindowSky(scene, "window-day", ["#9fb4c8", "#c9d6e0", "#e8e2d4"], false);
  paintWindowSky(scene, "window-night", ["#0e1430", "#1c2550", "#2c3566"], true);
  paintFramedTexture(scene, "rain", RAIN_FRAMES, 28, 20, (context, frameIndex, offsetX) => {
    for (let streak = 0; streak < 9; streak += 1) {
      const column = offsetX + ((streak * 7 + frameIndex * 3) % 27);
      const row = (streak * 5 + frameIndex * 6) % 16;
      fill(context, "rgba(230,240,255,0.75)", column, row, 1, 3);
      fill(context, "rgba(230,240,255,0.35)", column, row + 3, 1, 2);
    }
  });
}

function paintWindowSky(scene: Phaser.Scene, key: string, sky: [string, string, string], night: boolean): void {
  paintTexture(scene, key, 32, 28, (context, random) => {
    fill(context, "#8a5a3a", 0, 0, 32, 26);
    const gradient = context.createLinearGradient(0, 2, 0, 22);
    gradient.addColorStop(0, sky[0]);
    gradient.addColorStop(0.6, sky[1]);
    gradient.addColorStop(1, sky[2]);
    context.fillStyle = gradient;
    context.fillRect(2, 2, 28, 20);
    if (night) {
      for (let star = 0; star < 10; star += 1) fill(context, "#fff6c8", 3 + Math.floor(random() * 26), 3 + Math.floor(random() * 12), 1, 1);
      fill(context, "#fff2c0", 22, 4, 4, 4);
      fill(context, "#1c2550", 24, 4, 2, 2);
    } else {
      fill(context, "#e6ebf0", 4, 5, 8, 3);
      fill(context, "#e6ebf0", 18, 8, 9, 3);
    }
    fill(context, "#8a5a3a", 15, 2, 2, 20);
    fill(context, "#8a5a3a", 2, 11, 28, 2);
    fill(context, "#b07a52", 0, 22, 32, 4);
    fill(context, "#d39a6a", 0, 22, 32, 1);
    fill(context, "#e86a8a", 2, 24, 3, 2);
    fill(context, "#3f9a4e", 26, 23, 3, 3);
  });
}

export function createEnvironmentTextures(scene: Phaser.Scene): void {
  paintWorkProps(scene);
  paintCozyProps(scene);
  for (const [style, painter] of Object.entries(FLOOR_PAINTERS) as Array<[FloorStyle, Painter]>) {
    paintTexture(scene, floorTextureKey(style), 16, 16, painter);
  }
  paintTexture(scene, "wall-cap", 16, 16, (context) => {
    fill(context, WALL_CAP, 0, 0, 16, 16);
    fill(context, WALL_CAP_LIGHT, 0, 0, 16, 2);
    fill(context, shade(WALL_CAP, 0.08), 0, 7, 16, 1);
  });
  paintTexture(scene, "door", 16, 16, (context) => {
    fill(context, "#9b6e4a", 0, 0, 16, 16);
    fill(context, "#c9a24a", 0, 6, 16, 3);
    fill(context, "#e0bf6a", 0, 6, 16, 1);
  });
  ensureWallTextures(scene, CORRIDOR_WALLPAPER);
  paintPlants(scene);
  paintPosters(scene);
  paintDesks(scene);
  paintAppliances(scene);
  paintLight(scene);
}
