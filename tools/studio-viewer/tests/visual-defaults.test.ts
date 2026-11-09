import { describe, expect, it } from "vitest";
import { DEFAULT_VISUALS, withVisualDefaults, type StudioConfig } from "../shared/protocol.ts";
import { STUDIO_CONFIG } from "./fixtures.ts";

describe("withVisualDefaults", () => {
  it("fills in every visual setting when an older config has no visuals block", () => {
    const { visuals: _visuals, ...olderConfig } = STUDIO_CONFIG;
    const resolved = withVisualDefaults(olderConfig as StudioConfig);
    expect(resolved.visuals).toEqual(DEFAULT_VISUALS);
  });

  it("keeps configured values and fills only the missing ones", () => {
    const partial = { ...STUDIO_CONFIG, visuals: { tiltDegrees: 30, tiltShift: { radiusPx: 7 } } } as unknown as StudioConfig;
    const resolved = withVisualDefaults(partial);
    expect(resolved.visuals.tiltDegrees).toBe(30);
    expect(resolved.visuals.tiltShift.radiusPx).toBe(7);
    expect(resolved.visuals.tiltShift.band).toBe(DEFAULT_VISUALS.tiltShift.band);
    expect(resolved.visuals.saturation).toBe(DEFAULT_VISUALS.saturation);
  });
});
