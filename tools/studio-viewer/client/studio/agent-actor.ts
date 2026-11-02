import type Phaser from "phaser";
import { walkingPixel, type Facing, type PixelPoint, type Seat, type TilePoint, type Workstation } from "./layout.ts";
import { GLYPH_FRAMES } from "./environment-art.ts";
import type { BubbleStyle, OverlayAnchor, OverlayLayer } from "./overlay.ts";
import { findPath } from "./pathfinder.ts";

export class CancelToken {
  cancelled = false;

  cancel(): void {
    this.cancelled = true;
  }
}

export interface ActorTask {
  taskId: string;
  description: string;
  prompt: string;
  parentAgent: string;
  startedAt: number;
}

export type ScriptKind = "task" | "ambient";
export type ActorScript = (token: CancelToken) => Promise<void>;

export interface AgentActorOptions {
  scene: Phaser.Scene;
  name: string;
  label: string;
  textureKey: string;
  walkable: boolean[][];
  overlay: OverlayLayer;
  walkTilesPerSecond: number;
  home: Workstation | null;
  monitor: Phaser.GameObjects.Image | null;
  monitorGlow: Phaser.GameObjects.Image | null;
  start: Seat;
  isGuest: boolean;
  alwaysTagged: boolean;
}

const SEAT_SETTLE_MS = 140;
const TYPING_INTERVAL_MS = 230;
const GLYPH_INTERVAL_MS = 420;
const GLYPH_DEPTH_OFFSET = 30;
const BACK_VIEW_BOB = 0.95;

export class AgentActor implements OverlayAnchor {
  readonly anchorId: string;
  readonly name: string;
  readonly label: string;
  readonly isGuest: boolean;
  readonly sprite: Phaser.GameObjects.Sprite;
  private readonly shadow: Phaser.GameObjects.Image;
  readonly tasks = new Map<string, ActorTask>();
  home: Workstation | null;
  monitor: Phaser.GameObjects.Image | null;
  monitorGlow: Phaser.GameObjects.Image | null;
  status = "Idle at desk";
  externalBusy = false;
  workSeat: Seat | null = null;
  private glyphs: Phaser.GameObjects.Particles.ParticleEmitter | null = null;
  private laptop: Phaser.GameObjects.Image | null = null;
  hovered = false;
  private readonly scene: Phaser.Scene;
  private readonly overlay: OverlayLayer;
  private readonly walkable: boolean[][];
  private readonly stepDurationMs: number;
  private readonly alwaysTagged: boolean;
  private currentTile: TilePoint;
  private facing: Facing;
  private seated: boolean;
  private scriptChain: Promise<void> = Promise.resolve();
  private pendingScripts = 0;
  private ambientToken: CancelToken | null = null;
  private typingTimer: Phaser.Time.TimerEvent | null = null;
  private typingFrame = 0;
  private walkFrame = 0;
  private destroyed = false;

  constructor(options: AgentActorOptions) {
    this.scene = options.scene;
    this.name = options.name;
    this.anchorId = `actor-${options.name}`;
    this.label = options.label;
    this.isGuest = options.isGuest;
    this.overlay = options.overlay;
    this.walkable = options.walkable;
    this.stepDurationMs = 1000 / options.walkTilesPerSecond;
    this.alwaysTagged = options.alwaysTagged;
    this.home = options.home;
    this.monitor = options.monitor;
    this.monitorGlow = options.monitorGlow;
    this.currentTile = options.start.tile;
    this.facing = options.start.facing;
    this.seated = options.start.seated;
    this.sprite = options.scene.add
      .sprite(options.start.pixel.x, options.start.pixel.y, options.textureKey, `${this.facing}-0`)
      .setOrigin(0.5, 1);
    this.shadow = options.scene.add.image(this.sprite.x, this.sprite.y, "shadow").setOrigin(0.5, 0.6);
    this.update();
    this.updateNameTag();
  }

  get isBusy(): boolean {
    return this.pendingScripts > 0;
  }

  get isWandering(): boolean {
    return this.ambientToken !== null;
  }

  get isWorking(): boolean {
    return this.tasks.size > 0 || this.externalBusy;
  }

  anchorPoint(): PixelPoint {
    return { x: this.sprite.x, y: this.sprite.y };
  }

  run(kind: ScriptKind, script: ActorScript): Promise<void> {
    if (this.destroyed) return Promise.resolve();
    if (kind === "task") this.cancelAmbient();
    else if (this.pendingScripts > 0) return Promise.resolve();
    const token = new CancelToken();
    if (kind === "ambient") this.ambientToken = token;
    this.pendingScripts += 1;
    const execution = this.scriptChain
      .then(() => (token.cancelled || this.destroyed ? undefined : script(token)))
      .catch((error: unknown) => console.warn(`Script for ${this.name} failed`, error))
      .finally(() => {
        this.pendingScripts -= 1;
        if (this.ambientToken === token) this.ambientToken = null;
        if (this.pendingScripts === 0) this.refreshWorkState();
      });
    this.scriptChain = execution;
    return execution;
  }

  cancelAmbient(): void {
    this.ambientToken?.cancel();
  }

  async walkTo(target: TilePoint, token?: CancelToken): Promise<void> {
    if (this.destroyed) return;
    this.standUp();
    const path = findPath(this.walkable, this.currentTile, target);
    if (path === null) {
      this.placeAt(walkingPixel(target), target);
      return;
    }
    for (const step of path) {
      if (token?.cancelled || this.destroyed) return;
      await this.stepTo(step);
    }
    this.setStandingFrame();
  }

  async sitAt(seat: Seat, token?: CancelToken): Promise<void> {
    await this.walkTo(seat.tile, token);
    if (token?.cancelled || this.destroyed) return;
    await this.tween(seat.pixel, SEAT_SETTLE_MS);
    this.facing = seat.facing;
    this.seated = seat.seated;
    this.setStandingFrame();
  }

  async goHome(token?: CancelToken): Promise<void> {
    if (!this.home) return;
    await this.sitAt(this.home.seat, token);
  }

  async goToWork(token?: CancelToken): Promise<void> {
    const seat = this.workPlace();
    if (seat) await this.sitAt(seat, token);
  }

  workPlace(): Seat | null {
    return this.workSeat ?? this.home?.seat ?? null;
  }

  isAtWorkSeat(): boolean {
    const seat = this.workPlace();
    return seat !== null && this.seated && this.currentTile.column === seat.tile.column && this.currentTile.row === seat.tile.row;
  }

  teleportHome(): void {
    if (!this.home) return;
    const seat = this.home.seat;
    this.placeAt(seat.pixel, seat.tile);
    this.facing = seat.facing;
    this.seated = seat.seated;
    this.setStandingFrame();
  }

  face(facing: Facing): void {
    this.facing = facing;
    this.setStandingFrame();
  }

  wait(durationMs: number): Promise<void> {
    return new Promise((resolve) => {
      if (this.destroyed) {
        resolve();
        return;
      }
      this.scene.time.delayedCall(durationMs, () => resolve());
    });
  }

  say(text: string, style: BubbleStyle, durationMs: number): void {
    if (!this.destroyed) this.overlay.showBubble(this, "speech", text, style, durationMs);
  }

  showActivity(text: string, style: BubbleStyle, durationMs: number): void {
    if (!this.destroyed) this.overlay.showBubble(this, "activity", text, style, durationMs);
  }

  clearActivity(): void {
    this.overlay.hideBubble(this, "activity");
  }

  isAtHome(): boolean {
    const seat = this.home?.seat;
    return (
      seat !== undefined &&
      this.seated &&
      this.currentTile.column === seat.tile.column &&
      this.currentTile.row === seat.tile.row
    );
  }

  refreshWorkState(): void {
    if (this.destroyed) return;
    const working = this.isWorking && this.isAtWorkSeat() && !this.isBusy;
    if (working) this.startTyping();
    else this.stopTyping();
    if (!this.isBusy) this.status = this.describeRest();
    this.updateNameTag();
  }

  updateNameTag(): void {
    if (this.destroyed) return;
    const visible = this.alwaysTagged || this.hovered || this.tasks.size > 0;
    const className = this.tasks.size > 0 ? "name-tag-working" : this.alwaysTagged ? "name-tag-fixed" : "";
    this.overlay.setNameTag(this, visible ? this.label : null, className);
  }

  update(): void {
    if (this.destroyed) return;
    this.sprite.setDepth(this.sprite.y);
    this.shadow.setPosition(this.sprite.x, this.sprite.y).setDepth(this.sprite.y - 1).setVisible(!this.seated);
    this.glyphs?.setDepth(this.sprite.y + GLYPH_DEPTH_OFFSET);
  }

  destroy(): void {
    this.destroyed = true;
    this.cancelAmbient();
    this.stopTyping();
    this.overlay.removeAnchor(this);
    this.glyphs?.destroy();
    this.shadow.destroy();
    this.sprite.destroy();
  }

  private describeRest(): string {
    if (this.isWorking) {
      if (!this.isAtWorkSeat()) return "Working";
      return this.workSeat ? "Working at the meeting table" : "Working at desk";
    }
    return this.isAtHome() ? "Idle at desk" : "Idle";
  }

  private standUp(): void {
    if (!this.seated) return;
    this.seated = false;
    this.stopTyping();
  }

  private async stepTo(step: TilePoint): Promise<void> {
    const target = walkingPixel(step);
    if (target.y < this.sprite.y - 1) this.facing = "up";
    else if (target.y > this.sprite.y + 1) this.facing = "down";
    this.walkFrame = (this.walkFrame + 1) % 2;
    this.sprite.setFrame(`${this.facing}-${this.walkFrame + 1}`);
    await this.tween(target, this.stepDurationMs);
    this.currentTile = step;
  }

  private tween(target: PixelPoint, durationMs: number): Promise<void> {
    return new Promise((resolve) => {
      if (this.destroyed) {
        resolve();
        return;
      }
      this.scene.tweens.add({
        targets: this.sprite,
        x: target.x,
        y: target.y,
        duration: durationMs,
        onComplete: () => resolve(),
        onStop: () => resolve(),
      });
    });
  }

  private placeAt(pixel: PixelPoint, tile: TilePoint): void {
    this.scene.tweens.killTweensOf(this.sprite);
    this.sprite.setPosition(pixel.x, pixel.y);
    this.currentTile = tile;
  }

  private setStandingFrame(): void {
    if (!this.destroyed) this.sprite.setFrame(`${this.facing}-0`);
  }

  private startTyping(): void {
    const awayFromDesk = this.workSeat !== null;
    if (!awayFromDesk) this.monitor?.setTexture("monitor-on-0");
    this.monitorGlow?.setVisible(!awayFromDesk);
    this.showLaptop(awayFromDesk);
    this.workingGlyphs().start();
    if (this.typingTimer) return;
    this.typingTimer = this.scene.time.addEvent({
      delay: TYPING_INTERVAL_MS,
      loop: true,
      callback: () => {
        this.typingFrame = this.typingFrame === 0 ? 1 : 0;
        if (this.facing === "down") this.sprite.setFrame(`type-${this.typingFrame}`);
        else this.sprite.setScale(1, this.typingFrame === 0 ? 1 : BACK_VIEW_BOB);
        if (this.workSeat === null) this.monitor?.setTexture(`monitor-on-${this.typingFrame}`);
      },
    });
  }

  private stopTyping(): void {
    this.typingTimer?.remove();
    this.typingTimer = null;
    this.monitor?.setTexture("monitor-off");
    this.monitorGlow?.setVisible(false);
    this.glyphs?.stop();
    this.showLaptop(false);
    if (!this.destroyed) this.sprite.setScale(1, 1);
    this.setStandingFrame();
  }

  private workingGlyphs(): Phaser.GameObjects.Particles.ParticleEmitter {
    if (this.glyphs) return this.glyphs;
    this.glyphs = this.scene.add.particles(0, 0, "glyphs", {
      frame: GLYPH_FRAMES,
      lifespan: { min: 900, max: 1500 },
      speedX: { min: -7, max: 7 },
      speedY: { min: -18, max: -10 },
      alpha: { start: 1, end: 0 },
      frequency: GLYPH_INTERVAL_MS,
      emitting: false,
    });
    this.glyphs.startFollow(this.sprite, 0, -16);
    return this.glyphs;
  }

  private showLaptop(visible: boolean): void {
    if (!visible || this.destroyed) {
      this.laptop?.destroy();
      this.laptop = null;
      return;
    }
    if (this.laptop) return;
    const offsetY = this.facing === "down" ? 4 : -9;
    this.laptop = this.scene.add
      .image(this.sprite.x, this.sprite.y + offsetY, "laptop")
      .setOrigin(0.5, 1)
      .setDepth(this.facing === "down" ? this.sprite.y + 40 : this.sprite.y - 2);
  }
}
