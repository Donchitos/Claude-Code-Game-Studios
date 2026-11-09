import type Phaser from "phaser";
import type { PixelPoint } from "./layout.ts";
import { CHARACTER_HEIGHT } from "./pixel-art.ts";
import type { ViewProjection } from "./view-projection.ts";

export type BubbleStyle = "speech" | "thought" | "tool" | "ambient" | "success" | "warning" | "user" | "brief";
export type BubbleChannel = "speech" | "activity";

export interface OverlayAnchor {
  readonly anchorId: string;
  anchorPoint(): PixelPoint;
}

interface BubbleEntry {
  element: HTMLDivElement;
  anchor: OverlayAnchor;
  channel: BubbleChannel;
  hideAt: number;
}

interface LabelEntry {
  element: HTMLDivElement;
  point: PixelPoint;
  minZoom: number;
}

interface NameTagEntry {
  element: HTMLDivElement;
  anchor: OverlayAnchor;
}

const HEAD_CLEARANCE = 3;
const STACK_GAP = 4;

export class OverlayLayer {
  private readonly bubbles = new Map<string, BubbleEntry>();
  private readonly labels: LabelEntry[] = [];
  private readonly nameTags = new Map<string, NameTagEntry>();
  private labelsVisible = true;

  constructor(
    private readonly root: HTMLElement,
    private readonly projection: ViewProjection,
  ) {}

  showBubble(anchor: OverlayAnchor, channel: BubbleChannel, text: string, style: BubbleStyle, durationMs: number): void {
    const bubbleId = `${anchor.anchorId}:${channel}`;
    let entry = this.bubbles.get(bubbleId);
    if (!entry) {
      const element = document.createElement("div");
      this.root.append(element);
      entry = { element, anchor, channel, hideAt: 0 };
      this.bubbles.set(bubbleId, entry);
    }
    entry.element.className = `bubble bubble-${style} bubble-channel-${channel}`;
    entry.element.textContent = text;
    entry.hideAt = durationMs > 0 ? performance.now() + durationMs : Number.POSITIVE_INFINITY;
  }

  hideBubble(anchor: OverlayAnchor, channel: BubbleChannel): void {
    const bubbleId = `${anchor.anchorId}:${channel}`;
    this.bubbles.get(bubbleId)?.element.remove();
    this.bubbles.delete(bubbleId);
  }

  setNameTag(anchor: OverlayAnchor, text: string | null, className = ""): void {
    const existing = this.nameTags.get(anchor.anchorId);
    if (!text) {
      existing?.element.remove();
      this.nameTags.delete(anchor.anchorId);
      return;
    }
    const element = existing?.element ?? document.createElement("div");
    element.className = `name-tag ${className}`.trim();
    element.textContent = text;
    if (!existing) {
      this.root.append(element);
      this.nameTags.set(anchor.anchorId, { element, anchor });
    }
  }

  addLabel(text: string, point: PixelPoint, className: string, minZoom: number, color: string | null = null): void {
    const element = document.createElement("div");
    element.className = `world-label ${className}`;
    element.textContent = text;
    if (color) element.style.setProperty("--label-color", color);
    this.root.append(element);
    this.labels.push({ element, point, minZoom });
  }

  setLabelsVisible(visible: boolean): void {
    this.labelsVisible = visible;
  }

  removeAnchor(anchor: OverlayAnchor): void {
    this.hideBubble(anchor, "speech");
    this.hideBubble(anchor, "activity");
    this.setNameTag(anchor, null);
  }

  sync(camera: Phaser.Cameras.Scene2D.Camera): void {
    const now = performance.now();
    const view = camera.worldView;
    const zoom = camera.zoom;
    const toScreen = (point: PixelPoint) => {
      const projected = this.projection.project({ x: (point.x - view.x) * zoom, y: (point.y - view.y) * zoom });
      return { left: projected.x, top: projected.y };
    };

    for (const [bubbleId, entry] of this.bubbles) {
      if (now > entry.hideAt) {
        entry.element.remove();
        this.bubbles.delete(bubbleId);
      }
    }
    for (const entry of this.bubbles.values()) {
      const feet = entry.anchor.anchorPoint();
      const head = toScreen({ x: feet.x, y: feet.y - CHARACTER_HEIGHT - HEAD_CLEARANCE });
      let lift = 0;
      if (entry.channel === "speech") {
        const activity = this.bubbles.get(`${entry.anchor.anchorId}:activity`);
        if (activity) lift = activity.element.offsetHeight + STACK_GAP;
      }
      entry.element.style.transform = `translate(${head.left}px, ${head.top - lift}px) translate(-50%, -100%)`;
    }
    for (const entry of this.nameTags.values()) {
      const position = toScreen(entry.anchor.anchorPoint());
      entry.element.style.transform = `translate(${position.left}px, ${position.top + 2}px) translate(-50%, 0)`;
    }
    for (const label of this.labels) {
      const visible = this.labelsVisible && zoom >= label.minZoom;
      label.element.style.display = visible ? "" : "none";
      if (!visible) continue;
      const position = toScreen(label.point);
      label.element.style.transform = `translate(${position.left}px, ${position.top}px) translate(-50%, -50%)`;
    }
  }
}
