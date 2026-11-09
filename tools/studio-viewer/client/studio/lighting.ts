import Phaser from "phaser";
import type { VisualConfig } from "../../shared/protocol.ts";

export const LIGHT_DEPTH = 50_000;
const SHADE_DEPTH = LIGHT_DEPTH - 10;
const TRANSITION_MS = 1400;

interface GlowEntry {
  target: { setAlpha(alpha: number): unknown };
  dayAlpha: number;
  nightAlpha: number;
  flicker: number;
  speed: number;
  phase: number;
}

interface FlickerOptions {
  flicker?: number;
  speed?: number;
}

function colorNumber(hexColor: string): number {
  return Number.parseInt(hexColor.slice(1), 16);
}

export class StudioLighting {
  private readonly glows: GlowEntry[] = [];
  private readonly dayOnly: Array<{ setVisible(visible: boolean): unknown }> = [];
  private readonly windows: Phaser.GameObjects.Image[] = [];
  private readonly dayWarmth: Phaser.GameObjects.Rectangle;
  private readonly nightShade: Phaser.GameObjects.Rectangle;
  private blend = 0;
  private night = false;

  constructor(
    private readonly scene: Phaser.Scene,
    worldWidth: number,
    worldHeight: number,
    private readonly visuals: VisualConfig,
  ) {
    this.dayWarmth = scene.add
      .rectangle(0, 0, worldWidth, worldHeight, colorNumber(visuals.dayWarmthColor))
      .setOrigin(0)
      .setBlendMode(Phaser.BlendModes.MULTIPLY)
      .setDepth(SHADE_DEPTH);
    this.nightShade = scene.add
      .rectangle(0, 0, worldWidth, worldHeight, colorNumber(visuals.nightShadeColor))
      .setOrigin(0)
      .setBlendMode(Phaser.BlendModes.MULTIPLY)
      .setDepth(SHADE_DEPTH + 1);
    this.applyBlend();
  }

  get isNight(): boolean {
    return this.night;
  }

  addGlow(target: GlowEntry["target"], dayAlpha: number, nightAlpha: number, options: FlickerOptions = {}): void {
    this.glows.push({
      target,
      dayAlpha,
      nightAlpha,
      flicker: options.flicker ?? 0,
      speed: options.speed ?? 0.002,
      phase: Math.random() * Math.PI * 2,
    });
  }

  addDayOnly(target: { setVisible(visible: boolean): unknown }): void {
    this.dayOnly.push(target);
  }

  addWindow(image: Phaser.GameObjects.Image): void {
    this.windows.push(image);
  }

  setNight(night: boolean, animate = true): void {
    this.night = night;
    const target = night ? 1 : 0;
    if (!animate) {
      this.blend = target;
      this.applyBlend();
      return;
    }
    this.scene.tweens.add({
      targets: this,
      blend: target,
      duration: TRANSITION_MS,
      ease: "Sine.easeInOut",
      onUpdate: () => this.applyBlend(),
    });
  }

  update(time: number): void {
    for (const glow of this.glows) {
      const base = glow.dayAlpha + (glow.nightAlpha - glow.dayAlpha) * this.blend;
      const wave = glow.flicker === 0 ? 1 : 1 + glow.flicker * Math.sin(time * glow.speed + glow.phase);
      glow.target.setAlpha(Math.max(0, base * wave));
    }
  }

  private applyBlend(): void {
    this.dayWarmth.setAlpha(this.visuals.dayWarmthAlpha * (1 - this.blend));
    this.nightShade.setAlpha(this.visuals.nightShadeAlpha * this.blend);
    const showNight = this.blend >= 0.5;
    for (const windowImage of this.windows) windowImage.setTexture(showNight ? "window-night" : "window-day");
    for (const target of this.dayOnly) target.setVisible(!showNight);
  }
}
