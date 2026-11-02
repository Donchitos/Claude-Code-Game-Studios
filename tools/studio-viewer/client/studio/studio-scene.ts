import Phaser from "phaser";
import {
  GUEST_DEPARTMENT,
  MAIN_AGENT,
  USER_AGENT,
  type RosterAgent,
  type StudioConfig,
} from "../../shared/protocol.ts";
import { displayName } from "../../shared/tool-summary.ts";
import { AgentActor } from "./agent-actor.ts";
import {
  FIRE_FRAMES,
  PAINTING_VARIANTS,
  PLANT_VARIANTS,
  POSTER_VARIANTS,
  RAIN_FRAMES,
  createEnvironmentTextures,
  ensureWallTextures,
  floorTextureKey,
  wallFaceKey,
  wallFrontKey,
  wallpaperColorFor,
} from "./environment-art.ts";
import {
  TILE_SIZE,
  walkingPixel,
  type FloorStyle,
  type Furniture,
  type Room,
  type Seat,
  type StudioLayout,
  type TilePoint,
  type Workstation,
} from "./layout.ts";
import { LIGHT_DEPTH, StudioLighting } from "./lighting.ts";
import type { OverlayLayer } from "./overlay.ts";
import { createCharacterTexture, hashString, shade, type CharacterStyle } from "./pixel-art.ts";
import { StudioCat } from "./studio-cat.ts";
import { STUDIO_POSTFX_KEY, StudioPostFx } from "./studio-postfx.ts";
import { StudioDirector, type StudioCast } from "./studio-director.ts";

export interface StudioSceneOptions {
  roster: RosterAgent[];
  config: StudioConfig;
  layout: StudioLayout;
  overlay: OverlayLayer;
  visibleFraction(): number;
  onSelect(agentName: string | null): void;
  onReady(scene: StudioScene): void;
}

interface GuestPlacement {
  actor: AgentActor;
  station: Workstation | null;
  overflow: Seat | null;
}

const MAX_ZOOM = 5;
const DRAG_THRESHOLD = 5;
const SPOTLIGHT_INTERVAL_MS = 2500;
const FOCUS_ZOOM = 2.6;
const BACKGROUND = "#2a1f2e";
const DAY_BACKGROUND = "#eadbc6";
const NIGHT_BACKGROUND = "#171a36";
const GROUND_DEPTH = -10;
const SHADOW_DEPTH = -6;
const WALL_DECOR_DEPTH = -8;
const SUNBEAM_ROTATION = -0.42;
const DOCUMENT_FLIGHT_MS = 650;
const FIRE_FRAME_MS = 140;
const RAIN_FRAME_MS = 110;
const FAIRY_SPACING_PX = 12;
const FAIRY_SWAG_PX = 48;
const FAIRY_SAG_PX = 5;
const CLOCK_TICK_MS = 1000;
const WALL_LABEL_BLOCKERS = new Set<Furniture["kind"]>([
  "painting",
  "pinboard",
  "wall-clock",
  "wall-screen",
  "neon-sign",
  "poster",
  "whiteboard",
  "bookshelf",
  "fireplace",
  "tv",
  "hanging-plant",
]);
const WALL_DECOR_CENTER_OFFSET = 5;
const FLAT_SPRITES: Partial<Record<Furniture["kind"], { key: string; width: number }>> = {
  bookshelf: { key: "bookshelf", width: 32 },
  printer: { key: "printer", width: 16 },
  "water-cooler": { key: "water-cooler", width: 12 },
  fridge: { key: "fridge", width: 16 },
  tv: { key: "tv", width: 64 },
  "server-rack": { key: "server-rack-0", width: 16 },
  lamp: { key: "lamp", width: 12 },
};
const DESK_SPRITES: Partial<Record<Furniture["kind"], { key: string; height: number }>> = {
  desk: { key: "desk", height: 20 },
  "executive-desk": { key: "executive-desk", height: 22 },
  "reception-desk": { key: "reception-desk", height: 24 },
};
const NO_SHADOW = new Set<Furniture["kind"]>([
  "rug",
  "welcome-mat",
  "poster",
  "coffee-machine",
  "whiteboard",
  "tv",
  "fireplace",
  "hanging-plant",
]);

function colorNumber(hexColor: string): number {
  return Number.parseInt(hexColor.slice(1), 16);
}

function shadeNumber(color: number, amount: number): number {
  return colorNumber(shade(`#${color.toString(16).padStart(6, "0")}`, amount));
}

function variantFor(rect: Furniture["rect"], count: number): number {
  return hashString(`${rect.column},${rect.row}`) % count;
}

export class StudioScene extends Phaser.Scene implements StudioCast {
  head!: AgentActor;
  user!: AgentActor;
  director!: StudioDirector;
  readonly layout: StudioLayout;
  private readonly options: StudioSceneOptions;
  private readonly actors = new Map<string, AgentActor>();
  private readonly rosterNames = new Set<string>();
  private readonly guests = new Map<string, GuestPlacement>();
  private readonly monitors = new Map<Workstation, Phaser.GameObjects.Image>();
  private readonly serverRacks: Phaser.GameObjects.Image[] = [];
  private readonly monitorGlows = new Map<Workstation, Phaser.GameObjects.Image>();
  private readonly rainSheets: Phaser.GameObjects.Sprite[] = [];
  private readonly clockHands: Array<{ hands: Phaser.GameObjects.Graphics; x: number; y: number }> = [];
  private lighting!: StudioLighting;
  private cat: StudioCat | null = null;
  private selectionRing!: Phaser.GameObjects.Ellipse;
  private selected: AgentActor | null = null;
  private followEnabled = false;
  private lastSpotlightAt = 0;
  private dragStart: { pointerX: number; pointerY: number; scrollX: number; scrollY: number } | null = null;
  private dragged = false;

  constructor(options: StudioSceneOptions) {
    super("studio");
    this.options = options;
    this.layout = options.layout;
  }

  create(): void {
    createEnvironmentTextures(this);
    this.cameras.main.setBackgroundColor(BACKGROUND);
    this.lighting = new StudioLighting(
      this,
      this.layout.columns * TILE_SIZE,
      this.layout.rows * TILE_SIZE,
      this.options.config.visuals,
    );
    this.drawGround();
    this.drawWindows();
    this.drawFairyLights();
    for (const piece of this.layout.furniture) this.drawFurniture(piece);
    this.createWorkstationProps();
    this.createActors();
    this.addWorldLabels();
    this.drawSunlight();
    this.cat = new StudioCat(this, this.layout, this.options.overlay, {
      workingPositions: () => this.allActors().filter((actor) => actor.isWorking).map((actor) => actor.anchorPoint()),
    });
    this.selectionRing = this.add.ellipse(0, 0, 18, 7).setStrokeStyle(1.5, 0xffe066).setVisible(false);
    this.setupCamera();
    this.setupInput();
    this.applyCameraEffects(true);
    this.director = new StudioDirector(this, this.options.config.timing);
    this.time.addEvent({ delay: 650, loop: true, callback: () => this.blinkServerRacks() });
    this.animateRain();
    this.tickClocks();
    this.time.addEvent({ delay: CLOCK_TICK_MS, loop: true, callback: () => this.tickClocks() });
    this.game.events.on(Phaser.Core.Events.POST_RENDER, () => this.options.overlay.sync(this.cameras.main));
    this.options.onReady(this);
  }

  override update(time: number): void {
    for (const actor of this.actors.values()) actor.update();
    this.cat?.update();
    this.lighting.update(time);
    if (this.selected) {
      this.selectionRing.setPosition(this.selected.sprite.x, this.selected.sprite.y - 1);
      this.selectionRing.setDepth(this.selected.sprite.depth - 0.5);
    }
    this.director.tick(time);
  }

  rosterActors(): AgentActor[] {
    return [...this.rosterNames].map((name) => this.actors.get(name)).filter((actor): actor is AgentActor => !!actor);
  }

  allActors(): AgentActor[] {
    return [...this.actors.values()];
  }

  findActor(agentName: string): AgentActor | undefined {
    return this.actors.get(agentName);
  }

  summonGuest(agentType: string, arriveInstantly: boolean): AgentActor {
    const existing = this.actors.get(agentType);
    if (existing) return existing;
    const usedStations = new Set([...this.guests.values()].map((placement) => placement.station));
    const usedOverflow = new Set([...this.guests.values()].map((placement) => placement.overflow));
    const station = this.layout.guestStations.find((candidate) => !usedStations.has(candidate)) ?? null;
    const overflow = station ? null : (this.layout.guestOverflowSpots.find((spot) => !usedOverflow.has(spot)) ?? null);
    const fallbackSeat = overflow ?? this.layout.guestOverflowSpots[0]!;
    const home: Workstation = station ?? {
      agentName: agentType,
      seat: fallbackSeat,
      visitorSpot: fallbackSeat,
      roomId: "hot-desks",
      deskKind: "pod",
      deskRect: { column: fallbackSeat.tile.column, row: fallbackSeat.tile.row, width: 1, height: 1 },
      accentColor: this.guestColor(),
    };
    const entrance = this.layout.entrance;
    const start: Seat = arriveInstantly
      ? home.seat
      : { tile: entrance, facing: "up", seated: false, pixel: walkingPixel(entrance) };
    const actor = this.createActor(agentType, `${displayName(agentType)} (contractor)`, "guest", this.guestColor(), home, start, true);
    this.guests.set(agentType, { actor, station, overflow });
    return actor;
  }

  dismissGuest(actor: AgentActor): void {
    this.guests.delete(actor.name);
    this.actors.delete(actor.name);
    if (this.selected === actor) this.select(null);
    actor.destroy();
  }

  spotlight(actor: AgentActor): void {
    if (!this.followEnabled) return;
    const now = this.time.now;
    if (now - this.lastSpotlightAt < SPOTLIGHT_INTERVAL_MS) return;
    this.lastSpotlightAt = now;
    this.cameras.main.pan(actor.sprite.x, actor.sprite.y - 10, 700, "Sine.easeInOut");
  }

  flyDocument(from: AgentActor, to: AgentActor, completed: boolean): Promise<void> {
    const start = { x: from.sprite.x, y: from.sprite.y - 12 };
    const end = { x: to.sprite.x, y: to.sprite.y - 12 };
    const arcHeight = Math.max(14, Math.hypot(end.x - start.x, end.y - start.y) * 0.35);
    const documentImage = this.add
      .image(start.x, start.y, completed ? "document-done" : "document")
      .setDepth(LIGHT_DEPTH - 1)
      .setScale(0.6);
    const flight = { progress: 0 };
    return new Promise((resolve) => {
      this.tweens.add({
        targets: flight,
        progress: 1,
        duration: DOCUMENT_FLIGHT_MS,
        ease: "Sine.easeInOut",
        onUpdate: () => {
          const progress = flight.progress;
          documentImage.setPosition(
            start.x + (end.x - start.x) * progress,
            start.y + (end.y - start.y) * progress - Math.sin(progress * Math.PI) * arcHeight,
          );
          documentImage.setScale(0.6 + Math.sin(progress * Math.PI) * 0.6).setRotation(progress * Math.PI * 2);
        },
        onComplete: () => {
          documentImage.destroy();
          resolve();
        },
      });
    });
  }

  setNight(night: boolean, animate = true): void {
    this.lighting.setNight(night, animate);
    this.cameras.main.setBackgroundColor(night ? NIGHT_BACKGROUND : DAY_BACKGROUND);
  }

  private animateRain(): void {
    if (this.rainSheets.length === 0) return;
    let frameIndex = 0;
    this.time.addEvent({
      delay: RAIN_FRAME_MS,
      loop: true,
      callback: () => {
        frameIndex = (frameIndex + 1) % RAIN_FRAMES.length;
        for (const sheet of this.rainSheets) sheet.setFrame(RAIN_FRAMES[frameIndex]!);
      },
    });
  }

  setFollowEnabled(enabled: boolean): void {
    this.followEnabled = enabled;
  }

  fitView(): void {
    const camera = this.cameras.main;
    camera.setZoom(this.fitZoom());
    camera.centerOn((this.layout.columns * TILE_SIZE) / 2, (this.layout.rows * TILE_SIZE) / 2);
  }

  focusAgent(agentName: string): void {
    const actor = this.actors.get(agentName);
    if (!actor) return;
    this.select(actor);
    const camera = this.cameras.main;
    camera.pan(actor.sprite.x, actor.sprite.y - 10, 600, "Sine.easeInOut");
    camera.zoomTo(Math.max(camera.zoom, FOCUS_ZOOM), 600);
  }

  select(actor: AgentActor | null): void {
    this.selected = actor;
    this.selectionRing.setVisible(actor !== null);
    this.options.onSelect(actor?.name ?? null);
  }

  applyCameraEffects(tiltShiftEnabled: boolean): void {
    const camera = this.cameras.main;
    if (this.game.renderer.type !== Phaser.WEBGL) return;
    const renderer = this.game.renderer as Phaser.Renderer.WebGL.WebGLRenderer;
    if (!renderer.pipelines.getPostPipeline(STUDIO_POSTFX_KEY)) renderer.pipelines.addPostPipeline(STUDIO_POSTFX_KEY, StudioPostFx);
    let postFx = camera.getPostPipeline(StudioPostFx) as StudioPostFx | StudioPostFx[] | undefined;
    if (!postFx || (Array.isArray(postFx) && postFx.length === 0)) {
      camera.setPostPipeline(StudioPostFx);
      postFx = camera.getPostPipeline(StudioPostFx) as StudioPostFx | StudioPostFx[];
    }
    const pipeline = Array.isArray(postFx) ? postFx[0] : postFx;
    if (!pipeline) return;
    const visuals = this.options.config.visuals;
    pipeline.blurRadius = tiltShiftEnabled ? visuals.tiltShift.radiusPx : 0;
    pipeline.band = visuals.tiltShift.band;
    pipeline.saturation = visuals.saturation;
    pipeline.vignette = visuals.vignetteStrength;
  }

  private guestColor(): string {
    return this.options.config.departments.find((department) => department.id === GUEST_DEPARTMENT)?.color ?? "#8d939c";
  }

  private interiorRooms(): Array<Array<Room | null>> {
    const { columns, rows, rooms } = this.layout;
    const grid: Array<Array<Room | null>> = Array.from({ length: rows }, () => Array<Room | null>(columns).fill(null));
    for (const room of rooms) {
      for (let row = room.rect.row + 1; row < room.rect.row + room.rect.height - 1; row += 1) {
        for (let column = room.rect.column + 1; column < room.rect.column + room.rect.width - 1; column += 1) {
          grid[row]![column] = room;
        }
      }
    }
    return grid;
  }

  private drawGround(): void {
    const { columns, rows, cells, rooms } = this.layout;
    for (const room of rooms) ensureWallTextures(this, room.wallColor);
    const roomAt = this.interiorRooms();
    const ground = this.add.renderTexture(0, 0, columns * TILE_SIZE, rows * TILE_SIZE).setOrigin(0).setDepth(GROUND_DEPTH);
    ground.beginDraw();
    for (let row = 0; row < rows; row += 1) {
      for (let column = 0; column < columns; column += 1) {
        const cell = cells[row]![column];
        const left = column * TILE_SIZE;
        const top = row * TILE_SIZE;
        const room = roomAt[row]![column] ?? null;
        if (cell === "floor") {
          const style: FloorStyle = room?.floor ?? "corridor";
          ground.batchDrawFrame(floorTextureKey(style), undefined, left, top);
          if (room && cells[row - 1]?.[column] === "wall") ground.batchDrawFrame(wallFaceKey(room.wallColor), undefined, left, top);
        } else if (cell === "door") {
          ground.batchDrawFrame("door", undefined, left, top);
        } else if (cell === "wall") {
          const below = cells[row + 1]?.[column];
          const facesViewer = below === "floor" || below === "door";
          if (!facesViewer) {
            ground.batchDrawFrame("wall-cap", undefined, left, top);
            continue;
          }
          const roomBelow = roomAt[row + 1]?.[column] ?? null;
          ground.batchDrawFrame(wallFrontKey(wallpaperColorFor(roomBelow?.wallColor ?? null)), undefined, left, top);
        }
      }
    }
    ground.endDraw();
  }

  private drawWindows(): void {
    const visuals = this.options.config.visuals;
    for (const windowTile of this.layout.windows) {
      const left = windowTile.column * TILE_SIZE;
      const bottom = (windowTile.row + 1) * TILE_SIZE - 3;
      const windowImage = this.add.image(left, bottom, "window-day").setOrigin(0, 1).setDepth(WALL_DECOR_DEPTH);
      this.lighting.addWindow(windowImage);
      const moonlight = this.add
        .image(left + 16, bottom - 14, "glow")
        .setScale(0.7, 0.5)
        .setTint(0x9fb8ff)
        .setBlendMode(Phaser.BlendModes.ADD)
        .setDepth(LIGHT_DEPTH);
      this.lighting.addGlow(moonlight, 0, 0.35);
      if (visuals.rain) {
        this.rainSheets.push(this.add.sprite(left + 2, bottom - 26, "rain", RAIN_FRAMES[0]).setOrigin(0).setDepth(WALL_DECOR_DEPTH + 0.5));
      }
    }
  }

  private drawSunlight(): void {
    const visuals = this.options.config.visuals;
    const tint = colorNumber(visuals.sunbeamTint);
    const beamLength = visuals.sunbeamLengthTiles * TILE_SIZE;
    for (const windowTile of this.layout.windows) {
      const originX = (windowTile.column + 1) * TILE_SIZE;
      const originY = (windowTile.row + 1) * TILE_SIZE - 8;
      const beam = this.add
        .image(originX, originY, "sunbeam")
        .setOrigin(0.5, 0)
        .setRotation(SUNBEAM_ROTATION)
        .setDisplaySize(30, beamLength)
        .setTint(tint)
        .setBlendMode(Phaser.BlendModes.ADD)
        .setDepth(LIGHT_DEPTH);
      this.lighting.addGlow(beam, visuals.sunbeamAlpha, 0, { flicker: 0.25, speed: 0.0011 });
      const drift = beamLength * Math.sin(-SUNBEAM_ROTATION);
      const motes = this.add
        .particles(0, 0, "mote", {
          emitZone: {
            type: "random",
            source: new Phaser.Geom.Rectangle(originX - 6, originY + 6, drift + 10, beamLength * 0.8),
            quantity: 1,
          },
          lifespan: { min: 2600, max: 5200 },
          speedX: { min: -3, max: 5 },
          speedY: { min: -4, max: 4 },
          scale: { min: 0.4, max: 1 },
          alpha: { start: 0.9, end: 0 },
          frequency: 900,
          tint: 0xfff2c8,
          blendMode: Phaser.BlendModes.ADD,
        })
        .setDepth(LIGHT_DEPTH + 1);
      this.lighting.addDayOnly(motes);
    }
  }

  private drawFairyLights(): void {
    const colors = [0xffd27a, 0xff9ab0, 0x9fe0ff, 0xb8f0a0, 0xffe9b8];
    let bulbIndex = 0;
    const sagAt = (offset: number) => Math.sin((offset / FAIRY_SWAG_PX) * Math.PI) ** 2 * FAIRY_SAG_PX;
    for (const room of this.layout.rooms) {
      if (room.kind === "closet") continue;
      const left = room.rect.column * TILE_SIZE + 10;
      const right = (room.rect.column + room.rect.width) * TILE_SIZE - 10;
      const top = (room.rect.row + 1) * TILE_SIZE + 2;
      const cord = this.add.graphics().setDepth(WALL_DECOR_DEPTH + 1).lineStyle(1, 0x5a4a3a, 0.8);
      cord.beginPath();
      cord.moveTo(left, top);
      for (let offset = 2; offset <= right - left; offset += 2) cord.lineTo(left + offset, top + sagAt(offset));
      cord.strokePath();
      for (let offset = FAIRY_SPACING_PX / 2; offset < right - left; offset += FAIRY_SPACING_PX) {
        const bulbX = left + offset;
        const bulbY = top + sagAt(offset) + 2;
        const color = colors[bulbIndex % colors.length]!;
        bulbIndex += 1;
        this.add.image(bulbX, bulbY, "bulb").setTint(color).setDepth(LIGHT_DEPTH - 1);
        const glow = this.add
          .image(bulbX, bulbY + 1, "glow")
          .setScale(0.22)
          .setTint(color)
          .setBlendMode(Phaser.BlendModes.ADD)
          .setDepth(LIGHT_DEPTH);
        this.lighting.addGlow(glow, 0.18, 0.85, { flicker: 0.3, speed: 0.0015 + Math.random() * 0.002 });
      }
    }
  }

  private drawShadow(left: number, bottom: number, width: number): void {
    this.add
      .image(left + width / 2 + 2, bottom - 1, "shadow")
      .setDisplaySize(width * 1.05, 9)
      .setAlpha(0.85)
      .setDepth(SHADOW_DEPTH);
  }

  private drawFurniture(piece: Furniture): void {
    const left = piece.rect.column * TILE_SIZE;
    const top = piece.rect.row * TILE_SIZE;
    const width = piece.rect.width * TILE_SIZE;
    const height = piece.rect.height * TILE_SIZE;
    const bottom = top + height;
    if (!NO_SHADOW.has(piece.kind) && piece.blocking) this.drawShadow(left, bottom + 3, width);
    switch (piece.kind) {
      case "rug": {
        const color = colorNumber(piece.color ?? "#888888");
        this.add
          .graphics()
          .setDepth(SHADOW_DEPTH - 1)
          .fillStyle(color, 0.45)
          .fillRoundedRect(left, top, width, height, 8)
          .lineStyle(2, shadeNumber(color, 0.35), 0.85)
          .strokeRoundedRect(left + 3, top + 3, width - 6, height - 6, 6)
          .lineStyle(1, 0xffffff, 0.3)
          .strokeRoundedRect(left + 6, top + 6, width - 12, height - 12, 4);
        return;
      }
      case "meeting-table":
      case "kitchen-table":
      case "counter": {
        const wood = piece.kind === "counter" ? 0xf0e4cc : piece.kind === "meeting-table" ? 0x9a5f3a : 0xe0aa6e;
        const table = this.add
          .graphics()
          .setDepth(bottom + 4)
          .fillStyle(shadeNumber(wood, -0.35), 1)
          .fillRect(left, top + height - 4, width, 8)
          .fillStyle(wood, 1)
          .fillRoundedRect(left, top - 2, width, height, 3)
          .fillStyle(shadeNumber(wood, 0.22), 1)
          .fillRect(left + 3, top, width - 6, 2);
        if (piece.kind !== "counter") {
          table.fillStyle(0xfff4e2, 1).fillCircle(left + width / 2, top + height / 2 - 2, 3);
          table.fillStyle(0xd97757, 1).fillCircle(left + 10, top + 6, 2).fillCircle(left + width - 10, top + height - 8, 2);
        }
        return;
      }
      case "sofa": {
        const color = colorNumber(piece.color ?? "#4f86c6");
        this.add
          .graphics()
          .setDepth(bottom + 2)
          .fillStyle(shadeNumber(color, -0.3), 1)
          .fillRoundedRect(left - 2, top + 1, width + 4, height + 1, 4)
          .fillStyle(color, 1)
          .fillRoundedRect(left, top + 2, width, height - 4, 3)
          .fillStyle(shadeNumber(color, 0.25), 1)
          .fillRect(left + 3, top + 4, width - 6, 2)
          .fillStyle(0xf2c14e, 1)
          .fillRoundedRect(left + 3, top + 3, 6, 6, 2)
          .fillStyle(0xff9ab0, 1)
          .fillRoundedRect(left + width - 9, top + 3, 6, 6, 2);
        return;
      }
      case "whiteboard": {
        const board = this.add
          .graphics()
          .setDepth(bottom)
          .fillStyle(0xc9ced8, 1)
          .fillRect(left, top - 10, width, height + 4)
          .fillStyle(0xfdfdfd, 1)
          .fillRect(left + 2, top - 8, width - 4, height);
        [0xe05a3a, 0x4f81bd, 0x3fb59a, 0xffb000].forEach((strokeColor, index) => {
          board.lineStyle(1, strokeColor, 1).lineBetween(left + 5 + index * 9, top - 4 + index * 2, left + 16 + index * 11, top - 5 + index * 3);
        });
        return;
      }
      case "fireplace":
        this.drawFireplace(left, bottom, width);
        return;
      case "armchair":
      case "beanbag":
        this.add
          .image(left + width / 2, bottom + 2, piece.kind)
          .setOrigin(0.5, 1)
          .setTint(colorNumber(piece.color ?? "#c0504d"))
          .setDepth(bottom + 3);
        return;
      case "hanging-plant":
        this.add.image(left + width / 2, top - 6, "hanging-plant").setOrigin(0.5, 0).setDepth(WALL_DECOR_DEPTH + 2);
        return;
      case "painting":
        this.add
          .image(left + width / 2, top + WALL_DECOR_CENTER_OFFSET, `painting-${variantFor(piece.rect, PAINTING_VARIANTS)}`)
          .setDepth(WALL_DECOR_DEPTH);
        return;
      case "pinboard":
        this.add.image(left + width / 2, top + WALL_DECOR_CENTER_OFFSET, "pinboard").setDepth(WALL_DECOR_DEPTH);
        return;
      case "wall-clock":
        this.drawWallClock(left + width / 2, top + WALL_DECOR_CENTER_OFFSET - 2);
        return;
      case "wall-screen":
        this.drawGlowingWallPiece("wall-screen", left + width / 2, top + WALL_DECOR_CENTER_OFFSET, piece.color ?? "#7fc8ff", 0.12, 0.5);
        return;
      case "neon-sign":
        this.drawGlowingWallPiece(
          piece.rect.width >= 4 ? "neon-logo" : "neon-code",
          left + width / 2,
          top + WALL_DECOR_CENTER_OFFSET,
          piece.color ?? "#ff6fa8",
          0.25,
          0.9,
          true,
        );
        return;
      case "arcade":
        this.add.image(left, bottom, piece.color === "#4ab0d9" ? "arcade-blue" : "arcade-pink").setOrigin(0, 1).setDepth(bottom);
        return;
      case "plant":
        this.add.image(left + width / 2, bottom, `plant-${variantFor(piece.rect, PLANT_VARIANTS)}`).setOrigin(0.5, 1).setDepth(bottom);
        return;
      case "poster":
        this.add.image(left + width / 2, top + 6, `poster-${variantFor(piece.rect, POSTER_VARIANTS)}`).setOrigin(0.5, 0.5).setDepth(WALL_DECOR_DEPTH);
        return;
      case "welcome-mat":
        this.add.image(left, top, "welcome-mat").setOrigin(0).setDepth(SHADOW_DEPTH - 1);
        return;
      case "coffee-machine":
        this.add.image(left + width / 2, bottom - 4, "coffee-machine").setOrigin(0.5, 1).setDepth(bottom + 6);
        return;
      default:
        break;
    }
    const desk = DESK_SPRITES[piece.kind];
    if (desk) {
      this.add.image(left, top, desk.key).setOrigin(0).setDepth(top + desk.height);
      return;
    }
    const flat = FLAT_SPRITES[piece.kind];
    if (!flat) return;
    const image = this.add.image(left + (width - flat.width) / 2, bottom, flat.key).setOrigin(0, 1).setDepth(bottom);
    if (piece.kind === "server-rack") this.serverRacks.push(image);
    if (piece.kind === "lamp") this.addLampGlow(left + width / 2, bottom);
  }

  private drawWallClock(centerX: number, centerY: number): void {
    this.add.image(centerX, centerY, "wall-clock").setDepth(WALL_DECOR_DEPTH);
    const hands = this.add.graphics().setDepth(WALL_DECOR_DEPTH + 0.5);
    this.clockHands.push({ hands, x: centerX, y: centerY });
  }

  private tickClocks(): void {
    const now = new Date();
    const minuteAngle = ((now.getMinutes() + now.getSeconds() / 60) / 60) * Math.PI * 2;
    const hourAngle = (((now.getHours() % 12) + now.getMinutes() / 60) / 12) * Math.PI * 2;
    for (const clock of this.clockHands) {
      clock.hands.clear();
      clock.hands.lineStyle(1, 0x2a1c14, 1);
      clock.hands.lineBetween(clock.x, clock.y, clock.x + Math.sin(hourAngle) * 2.5, clock.y - Math.cos(hourAngle) * 2.5);
      clock.hands.lineStyle(1, 0xd97757, 1);
      clock.hands.lineBetween(clock.x, clock.y, clock.x + Math.sin(minuteAngle) * 4, clock.y - Math.cos(minuteAngle) * 4);
    }
  }

  private drawGlowingWallPiece(
    key: string,
    centerX: number,
    centerY: number,
    color: string,
    dayGlow: number,
    nightGlow: number,
    tinted = false,
  ): void {
    const tint = colorNumber(color);
    const image = this.add.image(centerX, centerY, key).setDepth(LIGHT_DEPTH - 1);
    if (tinted) image.setTint(tint);
    const glow = this.add
      .image(centerX, centerY + 4, "glow")
      .setScale(image.width / 40, 0.9)
      .setTint(tint)
      .setBlendMode(Phaser.BlendModes.ADD)
      .setDepth(LIGHT_DEPTH);
    this.lighting.addGlow(glow, dayGlow, nightGlow, { flicker: tinted ? 0.08 : 0.04, speed: tinted ? 0.02 : 0.004 });
  }

  private drawFireplace(left: number, bottom: number, width: number): void {
    const centerX = left + width / 2;
    this.add.image(centerX, bottom + 2, "fireplace").setOrigin(0.5, 1).setDepth(bottom);
    const fire = this.add.sprite(centerX, bottom - 2, "fire", FIRE_FRAMES[0]).setOrigin(0.5, 1).setDepth(LIGHT_DEPTH - 1);
    let frameIndex = 0;
    this.time.addEvent({
      delay: FIRE_FRAME_MS,
      loop: true,
      callback: () => {
        frameIndex = (frameIndex + 1) % FIRE_FRAMES.length;
        fire.setFrame(FIRE_FRAMES[frameIndex]!);
      },
    });
    const hearthGlow = this.add
      .image(centerX, bottom + 10, "glow")
      .setScale(2.6, 1.6)
      .setTint(0xff8a3c)
      .setBlendMode(Phaser.BlendModes.ADD)
      .setDepth(LIGHT_DEPTH);
    this.lighting.addGlow(hearthGlow, 0.35, 0.95, { flicker: 0.18, speed: 0.012 });
  }

  private addLampGlow(centerX: number, bottom: number): void {
    const visuals = this.options.config.visuals;
    const alpha = visuals.lampGlowAlpha;
    const nightAlpha = Math.min(1, alpha * visuals.nightGlowBoost);
    const shadeGlow = this.add
      .image(centerX, bottom - 26, "glow")
      .setScale(1.3)
      .setTint(0xffc46b)
      .setBlendMode(Phaser.BlendModes.ADD)
      .setDepth(LIGHT_DEPTH);
    this.lighting.addGlow(shadeGlow, alpha, nightAlpha, { flicker: 0.1, speed: 0.003 });
    const floorPool = this.add
      .image(centerX, bottom + 2, "glow")
      .setScale(2.2, 1.1)
      .setTint(0xffb050)
      .setBlendMode(Phaser.BlendModes.ADD)
      .setDepth(LIGHT_DEPTH);
    this.lighting.addGlow(floorPool, alpha * 0.4, nightAlpha * 0.7);
  }

  private createWorkstationProps(): void {
    const stations = [...this.layout.workstations.values(), ...this.layout.guestStations, this.layout.headStation];
    for (const station of stations) {
      const seat = station.seat;
      this.add.image(seat.pixel.x, seat.pixel.y + (seat.facing === "down" ? -2 : 3), "chair").setOrigin(0.5, 1).setDepth(seat.pixel.y - 2);
      const deskLeft = station.deskRect.column * TILE_SIZE;
      const deskTop = station.deskRect.row * TILE_SIZE;
      const deskWidth = station.deskRect.width * TILE_SIZE;
      const deskHeight = DESK_SPRITES[station.deskKind === "pod" || station.deskKind === "office" ? "desk" : station.deskKind === "executive" ? "executive-desk" : "reception-desk"]?.height ?? 20;
      const monitorX = station.deskKind === "pod" || station.deskKind === "office" ? deskLeft + deskWidth / 2 : seat.pixel.x + 14;
      const monitor = this.add
        .image(monitorX, deskTop + 9, "monitor-off")
        .setOrigin(0.5, 1)
        .setDepth(deskTop + deskHeight + 1);
      this.monitors.set(station, monitor);
      const screenGlow = this.add
        .image(monitorX, deskTop + 4, "glow")
        .setScale(0.55)
        .setTint(0x7fc8ff)
        .setBlendMode(Phaser.BlendModes.ADD)
        .setDepth(LIGHT_DEPTH)
        .setVisible(false);
      this.lighting.addGlow(screenGlow, 0.18, 0.7, { flicker: 0.12, speed: 0.02 });
      this.monitorGlows.set(station, screenGlow);
    }
  }

  private createActors(): void {
    const departments = new Map(this.options.config.departments.map((department) => [department.id, department]));
    for (const agent of this.options.roster) {
      const station = this.layout.workstations.get(agent.name);
      if (!station) continue;
      const color = departments.get(agent.department)?.color ?? this.guestColor();
      this.createActor(agent.name, displayName(agent.name), agent.tier, color, station, station.seat, false);
      this.rosterNames.add(agent.name);
    }
    const config = this.options.config;
    const headStation = this.layout.headStation;
    this.head = this.createActor(MAIN_AGENT, config.studioHeadLabel, "head", config.studioHeadColor, headStation, headStation.seat, false, true);
    this.user = this.createActor(USER_AGENT, config.userLabel, "user", config.userColor, null, this.layout.userSpot, false, true);
    this.head.status = "Waiting for your next message";
    this.user.status = "Directing the studio";
  }

  private createActor(
    name: string,
    label: string,
    style: CharacterStyle,
    color: string,
    home: Workstation | null,
    start: Seat,
    isGuest: boolean,
    alwaysTagged = false,
  ): AgentActor {
    const textureKey = `agent-${name}`;
    createCharacterTexture(this, textureKey, { seed: name, style, shirt: color, accent: color });
    const actor = new AgentActor({
      scene: this,
      name,
      label,
      textureKey,
      walkable: this.layout.walkable,
      overlay: this.options.overlay,
      walkTilesPerSecond: this.options.config.timing.walkTilesPerSecond,
      home,
      monitor: home ? (this.monitors.get(home) ?? null) : null,
      monitorGlow: home ? (this.monitorGlows.get(home) ?? null) : null,
      start,
      isGuest,
      alwaysTagged,
    });
    actor.sprite.setInteractive({ useHandCursor: true });
    actor.sprite.on("pointerover", () => {
      actor.hovered = true;
      actor.updateNameTag();
    });
    actor.sprite.on("pointerout", () => {
      actor.hovered = false;
      actor.updateNameTag();
    });
    actor.sprite.on("pointerup", () => {
      if (!this.dragged) this.select(actor);
    });
    this.actors.set(name, actor);
    return actor;
  }

  private clearWallColumn(room: Room): number {
    const wallRow = room.rect.row + 1;
    const occupied = new Set<number>();
    for (const piece of this.layout.furniture) {
      if (piece.rect.row !== wallRow || !WALL_LABEL_BLOCKERS.has(piece.kind)) continue;
      for (let column = piece.rect.column; column < piece.rect.column + piece.rect.width; column += 1) occupied.add(column);
    }
    for (const windowTile of this.layout.windows) {
      if (windowTile.row === wallRow) {
        occupied.add(windowTile.column);
        occupied.add(windowTile.column + 1);
      }
    }
    const center = Math.floor(room.rect.column + room.rect.width / 2);
    const isClear = (column: number) =>
      [-2, -1, 0, 1, 2].every((offset) => !occupied.has(column + offset)) &&
      column - 2 > room.rect.column &&
      column + 2 < room.rect.column + room.rect.width - 1;
    for (let distance = 0; distance < room.rect.width / 2; distance += 1) {
      if (isClear(center - distance)) return center - distance + 0.5;
      if (isClear(center + distance)) return center + distance + 0.5;
    }
    return room.rect.column + room.rect.width / 2;
  }

  private addWorldLabels(): void {
    const overlay = this.options.overlay;
    for (const room of this.layout.rooms) {
      const isOffice = room.kind === "director-office" || room.kind === "lead-office";
      const labelColumn = isOffice ? room.rect.column + room.rect.width / 2 : this.clearWallColumn(room);
      const labelY = (room.rect.row + (isOffice ? room.rect.height - 1.4 : 1.3)) * TILE_SIZE;
      overlay.addLabel(room.label, { x: labelColumn * TILE_SIZE, y: labelY }, `room-label room-${room.kind}`, isOffice ? 1.1 : 0.3, room.accentColor);
    }
    for (const podLabel of this.layout.podLabels) {
      const point = { x: (podLabel.tile.column + podLabel.width / 2) * TILE_SIZE, y: podLabel.tile.row * TILE_SIZE + 6 };
      overlay.addLabel(podLabel.label, point, "pod-label", 0.9, podLabel.color);
    }
  }

  private fitZoom(): number {
    const camera = this.cameras.main;
    const fullFit = Math.min(camera.width / (this.layout.columns * TILE_SIZE), camera.height / (this.layout.rows * TILE_SIZE));
    return fullFit * this.options.visibleFraction();
  }

  private setupCamera(): void {
    this.fitView();
    this.scale.on(Phaser.Scale.Events.RESIZE, () => {
      const camera = this.cameras.main;
      if (camera.zoom < this.fitZoom() * 1.02) this.fitView();
    });
  }

  private setupInput(): void {
    const camera = this.cameras.main;
    this.input.on("pointerdown", (pointer: Phaser.Input.Pointer) => {
      this.dragStart = { pointerX: pointer.x, pointerY: pointer.y, scrollX: camera.scrollX, scrollY: camera.scrollY };
      this.dragged = false;
    });
    this.input.on("pointermove", (pointer: Phaser.Input.Pointer) => {
      if (!this.dragStart || !pointer.isDown) return;
      const deltaX = pointer.x - this.dragStart.pointerX;
      const deltaY = pointer.y - this.dragStart.pointerY;
      if (!this.dragged && Math.hypot(deltaX, deltaY) < DRAG_THRESHOLD) return;
      this.dragged = true;
      camera.setScroll(this.dragStart.scrollX - deltaX / camera.zoom, this.dragStart.scrollY - deltaY / camera.zoom);
    });
    this.input.on("pointerup", (_pointer: Phaser.Input.Pointer, targets: Phaser.GameObjects.GameObject[]) => {
      if (!this.dragged && targets.length === 0) this.select(null);
      this.dragStart = null;
      window.setTimeout(() => {
        this.dragged = false;
      }, 0);
    });
    this.input.on("wheel", (pointer: Phaser.Input.Pointer, _over: unknown, _deltaX: number, deltaY: number) => {
      const before = camera.getWorldPoint(pointer.x, pointer.y);
      const nextZoom = Phaser.Math.Clamp(camera.zoom * (deltaY > 0 ? 0.88 : 1.14), this.fitZoom() * 0.8, MAX_ZOOM);
      camera.setZoom(nextZoom);
      camera.preRender();
      const after = camera.getWorldPoint(pointer.x, pointer.y);
      camera.setScroll(camera.scrollX + before.x - after.x, camera.scrollY + before.y - after.y);
    });
  }

  private blinkServerRacks(): void {
    for (const rack of this.serverRacks) {
      rack.setTexture(rack.texture.key === "server-rack-0" ? "server-rack-1" : "server-rack-0");
    }
  }
}
