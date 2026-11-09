export interface TiltSettings {
  enabled: boolean;
  degrees: number;
  perspectiveFactor: number;
}

export interface ProjectedPoint {
  x: number;
  y: number;
  scale: number;
}

const OVERSCAN_LIMIT = 3;
const OVERSCAN_STEPS = 40;

export class ViewProjection {
  private width = 1;
  private height = 1;
  private angle = 0;
  private perspective = 1;
  private overscan = 1;

  constructor(private settings: TiltSettings) {
    this.recompute();
  }

  get enabled(): boolean {
    return this.settings.enabled;
  }

  get overscanFactor(): number {
    return this.overscan;
  }

  configure(settings: TiltSettings): void {
    this.settings = settings;
    this.recompute();
  }

  setEnabled(enabled: boolean): void {
    this.settings = { ...this.settings, enabled };
    this.recompute();
  }

  setViewport(width: number, height: number): void {
    this.width = Math.max(1, width);
    this.height = Math.max(1, height);
    this.recompute();
  }

  cssTransform(): string {
    if (!this.settings.enabled) return "none";
    return `perspective(${this.perspective.toFixed(1)}px) rotateX(${this.settings.degrees}deg) scale(${this.overscan.toFixed(4)})`;
  }

  project(point: { x: number; y: number }): ProjectedPoint {
    if (!this.settings.enabled) return { x: point.x, y: point.y, scale: 1 };
    const centerX = this.width / 2;
    const centerY = this.height / 2;
    const scaledX = (point.x - centerX) * this.overscan;
    const scaledY = (point.y - centerY) * this.overscan;
    const depth = scaledY * Math.sin(this.angle);
    const factor = this.perspective / (this.perspective - depth);
    return {
      x: centerX + scaledX * factor,
      y: centerY + scaledY * Math.cos(this.angle) * factor,
      scale: factor * this.overscan,
    };
  }

  unproject(point: { x: number; y: number }): { x: number; y: number } {
    if (!this.settings.enabled) return { x: point.x, y: point.y };
    const centerX = this.width / 2;
    const centerY = this.height / 2;
    const offsetY = point.y - centerY;
    const denominator = this.perspective * Math.cos(this.angle) + offsetY * Math.sin(this.angle);
    const scaledY = denominator === 0 ? 0 : (offsetY * this.perspective) / denominator;
    const factor = this.perspective / (this.perspective - scaledY * Math.sin(this.angle));
    const scaledX = (point.x - centerX) / factor;
    return { x: centerX + scaledX / this.overscan, y: centerY + scaledY / this.overscan };
  }

  private recompute(): void {
    this.angle = (this.settings.degrees * Math.PI) / 180;
    this.perspective = Math.max(this.width, this.height) * this.settings.perspectiveFactor;
    this.overscan = this.settings.enabled ? this.minimumOverscan() : 1;
  }

  private coversViewport(overscan: number): boolean {
    const halfHeight = (this.height / 2) * overscan;
    const topFactor = this.perspective / (this.perspective + halfHeight * Math.sin(this.angle));
    const topHalfWidth = (this.width / 2) * overscan * topFactor;
    const topReach = halfHeight * Math.cos(this.angle) * topFactor;
    const bottomFactor = this.perspective / (this.perspective - halfHeight * Math.sin(this.angle));
    const bottomReach = halfHeight * Math.cos(this.angle) * bottomFactor;
    return topHalfWidth >= this.width / 2 && topReach >= this.height / 2 && bottomReach >= this.height / 2;
  }

  private minimumOverscan(): number {
    let low = 1;
    let high = OVERSCAN_LIMIT;
    if (!this.coversViewport(high)) return high;
    for (let step = 0; step < OVERSCAN_STEPS; step += 1) {
      const middle = (low + high) / 2;
      if (this.coversViewport(middle)) high = middle;
      else low = middle;
    }
    return high;
  }
}
