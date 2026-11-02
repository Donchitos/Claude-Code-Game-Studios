import { describe, expect, it } from "vitest";
import { ViewProjection } from "../client/studio/view-projection.ts";

function tilted(): ViewProjection {
  const projection = new ViewProjection({ enabled: true, degrees: 22, perspectiveFactor: 1.8 });
  projection.setViewport(1200, 800);
  return projection;
}

describe("ViewProjection", () => {
  it("leaves points untouched when the tilt is off", () => {
    const projection = new ViewProjection({ enabled: false, degrees: 22, perspectiveFactor: 1.8 });
    projection.setViewport(1200, 800);
    expect(projection.project({ x: 10, y: 20 })).toEqual({ x: 10, y: 20, scale: 1 });
    expect(projection.cssTransform()).toBe("none");
  });

  it("round-trips every point through project and unproject", () => {
    const projection = tilted();
    for (const point of [
      { x: 0, y: 0 },
      { x: 600, y: 400 },
      { x: 1200, y: 800 },
      { x: 137, y: 655 },
    ]) {
      const projected = projection.project(point);
      const recovered = projection.unproject(projected);
      expect(recovered.x).toBeCloseTo(point.x, 6);
      expect(recovered.y).toBeCloseTo(point.y, 6);
    }
  });

  it("draws the far edge smaller than the near edge", () => {
    const projection = tilted();
    expect(projection.project({ x: 0, y: 0 }).scale).toBeLessThan(projection.project({ x: 0, y: 800 }).scale);
  });

  it("scales the tilted canvas enough to cover the whole viewport", () => {
    const projection = tilted();
    const topLeft = projection.project({ x: 0, y: 0 });
    const bottomRight = projection.project({ x: 1200, y: 800 });
    expect(topLeft.x).toBeLessThanOrEqual(0.001);
    expect(topLeft.y).toBeLessThanOrEqual(0.001);
    expect(bottomRight.y).toBeGreaterThanOrEqual(799.999);
    expect(projection.cssTransform()).toMatch(/^perspective\(\d+\.\dpx\) rotateX\(22deg\) scale\(1\.\d{4}\)$/);
  });
});
