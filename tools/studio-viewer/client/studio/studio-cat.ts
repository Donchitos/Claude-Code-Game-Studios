import type Phaser from "phaser";
import { TILE_SIZE, walkingPixel, type PixelPoint, type StudioLayout, type TilePoint } from "./layout.ts";
import type { OverlayAnchor, OverlayLayer } from "./overlay.ts";
import { findPath } from "./pathfinder.ts";

const STEP_MS = 300;
const NAP_MIN_MS = 9000;
const NAP_MAX_MS = 16000;
const VISIT_MS = 7000;
const PAUSE_MS = 2500;
const RANDOM_TILE_ATTEMPTS = 40;

export interface CatNeighbours {
  workingPositions(): PixelPoint[];
}

function randomBetween(minimum: number, maximum: number): number {
  return minimum + Math.random() * (maximum - minimum);
}

function randomItem<T>(items: readonly T[]): T | undefined {
  return items[Math.floor(Math.random() * items.length)];
}

export class StudioCat implements OverlayAnchor {
  readonly anchorId = "studio-cat";
  private readonly sprite: Phaser.GameObjects.Sprite;
  private readonly cozyTiles: TilePoint[];
  private tile: TilePoint;
  private walkFrame = 0;
  private stopped = false;

  constructor(
    private readonly scene: Phaser.Scene,
    private readonly layout: StudioLayout,
    private readonly overlay: OverlayLayer,
    private readonly neighbours: CatNeighbours,
  ) {
    this.cozyTiles = this.findCozyTiles();
    this.tile = this.cozyTiles[0] ?? layout.entrance;
    const start = walkingPixel(this.tile);
    this.sprite = scene.add.sprite(start.x, start.y, "cat", "cat-sleep").setOrigin(0.5, 1);
    this.sprite.setInteractive({ useHandCursor: true });
    this.sprite.on("pointerup", () => this.overlay.showBubble(this, "speech", "Meow! 🐾", "ambient", 2000));
    this.update();
    void this.live();
  }

  anchorPoint(): PixelPoint {
    return { x: this.sprite.x, y: this.sprite.y + 8 };
  }

  update(): void {
    this.sprite.setDepth(this.sprite.y);
  }

  destroy(): void {
    this.stopped = true;
    this.overlay.removeAnchor(this);
    this.sprite.destroy();
  }

  private findCozyTiles(): TilePoint[] {
    const tiles: TilePoint[] = [];
    for (const piece of this.layout.furniture) {
      if (piece.kind !== "rug" && piece.kind !== "fireplace") continue;
      const row = piece.kind === "fireplace" ? piece.rect.row + 1 : piece.rect.row + Math.floor(piece.rect.height / 2);
      for (let column = piece.rect.column; column < piece.rect.column + piece.rect.width; column += 1) {
        if (this.layout.walkable[row]?.[column]) tiles.push({ column, row });
      }
    }
    return tiles;
  }

  private randomFloorTile(): TilePoint | undefined {
    for (let attempt = 0; attempt < RANDOM_TILE_ATTEMPTS; attempt += 1) {
      const room = randomItem(this.layout.rooms.filter((candidate) => candidate.kind !== "closet"));
      if (!room) return undefined;
      const column = room.rect.column + 1 + Math.floor(Math.random() * (room.rect.width - 2));
      const row = room.rect.row + 2 + Math.floor(Math.random() * Math.max(1, room.rect.height - 3));
      if (this.layout.walkable[row]?.[column]) return { column, row };
    }
    return undefined;
  }

  private tileBeside(position: PixelPoint): TilePoint | undefined {
    const column = Math.floor(position.x / TILE_SIZE);
    const row = Math.floor((position.y - 1) / TILE_SIZE);
    const candidates = [
      { column: column + 1, row },
      { column: column - 1, row },
      { column, row: row + 1 },
      { column: column + 1, row: row + 1 },
    ];
    return candidates.find((candidate) => this.layout.walkable[candidate.row]?.[candidate.column]);
  }

  private async live(): Promise<void> {
    await this.pause(randomBetween(1000, 4000));
    while (!this.stopped) {
      const roll = Math.random();
      if (roll < 0.4) await this.nap();
      else if (roll < 0.75) await this.visitWorker();
      else await this.wander();
      await this.pause(PAUSE_MS);
    }
  }

  private async nap(): Promise<void> {
    const spot = randomItem(this.cozyTiles);
    if (!spot) return;
    await this.walkTo(spot);
    this.sprite.setFrame("cat-sleep");
    this.overlay.showBubble(this, "speech", "💤", "ambient", NAP_MIN_MS);
    await this.pause(randomBetween(NAP_MIN_MS, NAP_MAX_MS));
  }

  private async visitWorker(): Promise<void> {
    const target = randomItem(this.neighbours.workingPositions());
    const spot = target ? this.tileBeside(target) : undefined;
    if (!spot) {
      await this.wander();
      return;
    }
    await this.walkTo(spot);
    this.sprite.setFrame("cat-sit");
    this.overlay.showBubble(this, "speech", "♥", "ambient", 2500);
    await this.pause(VISIT_MS);
  }

  private async wander(): Promise<void> {
    const spot = this.randomFloorTile();
    if (!spot) return;
    await this.walkTo(spot);
    this.sprite.setFrame("cat-sit");
  }

  private async walkTo(goal: TilePoint): Promise<void> {
    const path = findPath(this.layout.walkable, this.tile, goal) ?? [];
    for (const step of path) {
      if (this.stopped) return;
      const target = walkingPixel(step);
      if (target.x !== this.sprite.x) this.sprite.setFlipX(target.x < this.sprite.x);
      this.walkFrame = this.walkFrame === 0 ? 1 : 0;
      this.sprite.setFrame(`cat-walk-${this.walkFrame}`);
      await new Promise<void>((resolve) => {
        this.scene.tweens.add({ targets: this.sprite, x: target.x, y: target.y, duration: STEP_MS, onComplete: () => resolve() });
      });
      this.tile = step;
    }
  }

  private pause(durationMs: number): Promise<void> {
    return new Promise((resolve) => this.scene.time.delayedCall(durationMs, () => resolve()));
  }
}
