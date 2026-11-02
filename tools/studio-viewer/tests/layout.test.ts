import { describe, expect, it } from "vitest";
import { buildStudioLayout, type Seat, type TilePoint } from "../client/studio/layout.ts";
import { findPath } from "../client/studio/pathfinder.ts";
import { ROSTER, STUDIO_CONFIG } from "./fixtures.ts";

const layout = buildStudioLayout(ROSTER, STUDIO_CONFIG);

function key(point: TilePoint): string {
  return `${point.column},${point.row}`;
}

function allSpots(): Array<[string, Seat]> {
  const spots: Array<[string, Seat]> = [];
  for (const [name, station] of layout.workstations) {
    spots.push([`${name} seat`, station.seat], [`${name} visitor`, station.visitorSpot]);
  }
  layout.guestStations.forEach((station, index) => spots.push([`guest ${index}`, station.seat]));
  spots.push(["head seat", layout.headStation.seat], ["user", layout.userSpot], ["coffee", layout.coffeeSpot]);
  spots.push(["meeting head", layout.meetingHeadSpot]);
  layout.briefingSpots.forEach((spot, index) => spots.push([`briefing ${index}`, spot]));
  layout.meetingSeats.forEach((spot, index) => spots.push([`meeting ${index}`, spot]));
  layout.loungeSpots.forEach((spot, index) => spots.push([`lounge ${index}`, spot]));
  layout.coolerSpots.forEach((spot, index) => spots.push([`cooler ${index}`, spot]));
  layout.guestOverflowSpots.forEach((spot, index) => spots.push([`overflow ${index}`, spot]));
  return spots;
}

describe("buildStudioLayout", () => {
  it("gives every roster agent except contractors a workstation", () => {
    const placed = ROSTER.filter((agent) => agent.department !== "guests").map((agent) => agent.name);
    expect([...layout.workstations.keys()].sort()).toEqual([...placed].sort());
    expect(layout.workstations.has("mystery-agent")).toBe(false);
  });

  it("puts directors in executive offices and leads in private offices", () => {
    expect(layout.workstations.get("producer")?.deskKind).toBe("executive");
    expect(layout.workstations.get("qa-lead")?.deskKind).toBe("office");
    expect(layout.workstations.get("gameplay-programmer")?.deskKind).toBe("pod");
    expect(layout.workstations.get("godot-specialist")?.roomId).toBe("engine-lab");
  });

  it("never seats two agents on the same tile", () => {
    const seats = [...layout.workstations.values(), ...layout.guestStations, layout.headStation].map((station) => key(station.seat.tile));
    expect(new Set(seats).size).toBe(seats.length);
  });

  it("can walk from the entrance to every seat and spot", () => {
    const unreachable = allSpots()
      .filter(([, spot]) => findPath(layout.walkable, layout.entrance, spot.tile) === null)
      .map(([name]) => name);
    expect(unreachable).toEqual([]);
  });

  it("keeps every seat inside the studio grid", () => {
    for (const [, spot] of allSpots()) {
      expect(spot.tile.column).toBeGreaterThanOrEqual(0);
      expect(spot.tile.row).toBeGreaterThanOrEqual(0);
      expect(spot.tile.column).toBeLessThan(layout.columns);
      expect(spot.tile.row).toBeLessThan(layout.rows);
    }
  });
});
