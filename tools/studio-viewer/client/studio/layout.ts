import {
  GUEST_DEPARTMENT,
  MAIN_AGENT,
  type DepartmentConfig,
  type RosterAgent,
  type StudioConfig,
} from "../../shared/protocol.ts";
import { displayName } from "../../shared/tool-summary.ts";

export const TILE_SIZE = 16;
export const STUDIO_COLUMNS = 66;
export const STUDIO_ROWS = 44;

const DIRECTOR_OFFICE_COUNT = 3;
const DIRECTOR_OFFICE_PITCH = 10;
const LEAD_OFFICE_PITCH = 7;
const MAX_LEAD_OFFICES = 8;
const CORRIDOR_ROW_RANGES: ReadonlyArray<readonly [number, number]> = [
  [10, 10],
  [19, 19],
  [34, 34],
];
const DESK_PITCH = 3;
const POD_GAP = 3;
const POD_ROW_GAP = 1;
const POD_HEIGHT = 5;
const GUEST_DESK_COUNT = 6;
const LEADERSHIP_GOLD = "#e0a93b";

const WALLPAPER = {
  director: "#f4cfae",
  meeting: "#b7dccb",
  cafe: "#f3d3c0",
  openFloor: "#f7e7bb",
  engineLab: "#c3d6ee",
  lobby: "#f6d2c6",
  hotDesks: "#d9e7b8",
  closet: "#5b6175",
} as const;


export type CellKind = "void" | "floor" | "wall" | "door";
export type Facing = "up" | "down";
export type FloorStyle =
  | "carpet"
  | "wood"
  | "parquet"
  | "lab"
  | "meeting"
  | "lounge"
  | "lobby"
  | "kitchen"
  | "corridor"
  | "closet";
export type RoomKind =
  | "director-office"
  | "lead-office"
  | "open-floor"
  | "engine-lab"
  | "meeting"
  | "lounge"
  | "lobby"
  | "hot-desks"
  | "kitchen"
  | "cafe"
  | "closet";
export type DeskKind = "executive" | "office" | "pod" | "reception";
export type FurnitureKind =
  | "desk"
  | "executive-desk"
  | "reception-desk"
  | "plant"
  | "bookshelf"
  | "sofa"
  | "coffee-machine"
  | "counter"
  | "water-cooler"
  | "fridge"
  | "arcade"
  | "whiteboard"
  | "server-rack"
  | "meeting-table"
  | "kitchen-table"
  | "tv"
  | "rug"
  | "printer"
  | "lamp"
  | "poster"
  | "welcome-mat"
  | "fireplace"
  | "armchair"
  | "beanbag"
  | "hanging-plant"
  | "painting"
  | "pinboard"
  | "wall-clock"
  | "wall-screen"
  | "neon-sign";

export interface TilePoint {
  column: number;
  row: number;
}

export interface TileRect {
  column: number;
  row: number;
  width: number;
  height: number;
}

export interface PixelPoint {
  x: number;
  y: number;
}

export interface Seat {
  tile: TilePoint;
  facing: Facing;
  seated: boolean;
  pixel: PixelPoint;
}

export interface Room {
  id: string;
  label: string;
  kind: RoomKind;
  rect: TileRect;
  floor: FloorStyle;
  wallColor: string;
  ownerAgent: string | null;
  accentColor: string | null;
}

export interface Workstation {
  agentName: string | null;
  seat: Seat;
  visitorSpot: Seat;
  roomId: string;
  deskKind: DeskKind;
  deskRect: TileRect;
  accentColor: string;
}

export interface Furniture {
  kind: FurnitureKind;
  rect: TileRect;
  blocking: boolean;
  color: string | null;
}

export interface PodLabel {
  label: string;
  color: string;
  tile: TilePoint;
  width: number;
}

export interface StudioLayout {
  columns: number;
  rows: number;
  cells: CellKind[][];
  walkable: boolean[][];
  rooms: Room[];
  furniture: Furniture[];
  windows: TilePoint[];
  podLabels: PodLabel[];
  workstations: Map<string, Workstation>;
  guestStations: Workstation[];
  guestOverflowSpots: Seat[];
  headStation: Workstation;
  userSpot: Seat;
  entrance: TilePoint;
  briefingSpots: Seat[];
  meetingSeats: Seat[];
  meetingHeadSpot: Seat;
  loungeSpots: Seat[];
  coffeeSpot: Seat;
  coolerSpots: Seat[];
}

interface PodRequest {
  label: string;
  color: string;
  agents: Array<string | null>;
  roomId: string;
}

export function tilePoint(column: number, row: number): TilePoint {
  return { column, row };
}

export function walkingPixel(point: TilePoint): PixelPoint {
  return { x: (point.column + 0.5) * TILE_SIZE, y: point.row * TILE_SIZE + 14 };
}

export function standingSeat(point: TilePoint, facing: Facing, pairCentered = false): Seat {
  const centerX = (pairCentered ? point.column + 1 : point.column + 0.5) * TILE_SIZE;
  return { tile: point, facing, seated: false, pixel: { x: centerX, y: point.row * TILE_SIZE + 14 } };
}

export function chairSeat(point: TilePoint, facing: Facing, pairCentered = false): Seat {
  const centerX = (pairCentered ? point.column + 1 : point.column + 0.5) * TILE_SIZE;
  const feetY = facing === "down" ? (point.row + 1) * TILE_SIZE + 6 : (point.row + 1) * TILE_SIZE - 6;
  return { tile: point, facing, seated: true, pixel: { x: centerX, y: feetY } };
}

function sofaSeat(point: TilePoint): Seat {
  return {
    tile: point,
    facing: "up",
    seated: true,
    pixel: { x: (point.column + 0.5) * TILE_SIZE, y: point.row * TILE_SIZE + 12 },
  };
}

function rect(column: number, row: number, width: number, height: number): TileRect {
  return { column, row, width, height };
}

function pastel(hexColor: string, amount: number): string {
  const value = Number.parseInt(hexColor.slice(1), 16);
  const channels = [(value >> 16) & 255, (value >> 8) & 255, value & 255].map((channel) =>
    Math.round(channel + (255 - channel) * amount),
  );
  return `#${channels.map((channel) => channel.toString(16).padStart(2, "0")).join("")}`;
}

class LayoutBuilder {
  readonly cells: CellKind[][];
  readonly blocked: boolean[][];
  readonly rooms: Room[] = [];
  readonly furniture: Furniture[] = [];
  readonly windows: TilePoint[] = [];
  readonly podLabels: PodLabel[] = [];
  private readonly pendingDoors: TilePoint[] = [];

  constructor(
    readonly columns: number,
    readonly rows: number,
  ) {
    this.cells = Array.from({ length: rows }, () => Array<CellKind>(columns).fill("void"));
    this.blocked = Array.from({ length: rows }, () => Array<boolean>(columns).fill(false));
  }

  addRoom(room: Room, doors: TilePoint[]): void {
    this.rooms.push(room);
    const { column: left, row: top, width, height } = room.rect;
    for (let row = top; row < top + height; row += 1) {
      for (let column = left; column < left + width; column += 1) {
        const onBorder = row === top || row === top + height - 1 || column === left || column === left + width - 1;
        this.setCell(column, row, onBorder ? "wall" : "floor");
      }
    }
    this.pendingDoors.push(...doors);
  }

  addWindows(row: number, columns: number[]): void {
    for (const column of columns) this.windows.push(tilePoint(column, row));
  }

  addCorridors(): void {
    for (const [firstRow, lastRow] of CORRIDOR_ROW_RANGES) {
      for (let row = firstRow; row <= lastRow; row += 1) {
        for (let column = 0; column < this.columns; column += 1) {
          const isEdge = column === 0 || column === this.columns - 1;
          this.setCell(column, row, isEdge ? "wall" : "floor");
        }
      }
    }
  }

  applyDoors(): void {
    for (const door of this.pendingDoors) this.setCell(door.column, door.row, "door");
  }

  addFurniture(kind: FurnitureKind, area: TileRect, blocking: boolean, color: string | null = null): void {
    this.furniture.push({ kind, rect: area, blocking, color });
    if (!blocking) return;
    for (let row = area.row; row < area.row + area.height; row += 1) {
      for (let column = area.column; column < area.column + area.width; column += 1) {
        if (this.inside(column, row)) this.blocked[row]![column] = true;
      }
    }
  }

  walkable(): boolean[][] {
    return this.cells.map((cellRow, row) =>
      cellRow.map((cell, column) => (cell === "floor" || cell === "door") && !this.blocked[row]![column]),
    );
  }

  private inside(column: number, row: number): boolean {
    return column >= 0 && row >= 0 && column < this.columns && row < this.rows;
  }

  private setCell(column: number, row: number, kind: CellKind): void {
    if (this.inside(column, row)) this.cells[row]![column] = kind;
  }
}

function podWidth(agentCount: number): number {
  return Math.max(1, Math.ceil(agentCount / 2)) * DESK_PITCH - 1;
}

function rowWidth(requests: PodRequest[]): number {
  return requests.reduce((total, request) => total + podWidth(request.agents.length), 0) + POD_GAP * (requests.length - 1);
}

function arrangePodRows(requests: PodRequest[], availableWidth: number): PodRequest[][] {
  const greedyRows: PodRequest[][] = [];
  for (const request of requests) {
    const currentRow = greedyRows[greedyRows.length - 1];
    if (currentRow && rowWidth([...currentRow, request]) <= availableWidth) currentRow.push(request);
    else greedyRows.push([request]);
  }
  if (greedyRows.length <= 1) return greedyRows;
  const perRow = Math.ceil(requests.length / greedyRows.length);
  const balancedRows: PodRequest[][] = [];
  for (let start = 0; start < requests.length; start += perRow) balancedRows.push(requests.slice(start, start + perRow));
  return balancedRows.every((row) => rowWidth(row) <= availableWidth) ? balancedRows : greedyRows;
}

function placePod(builder: LayoutBuilder, request: PodRequest, left: number, top: number): Workstation[] {
  builder.podLabels.push({
    label: request.label,
    color: request.color,
    tile: tilePoint(left, top),
    width: podWidth(request.agents.length),
  });
  const topCount = Math.ceil(request.agents.length / 2);
  return request.agents.map((agentName, index) => {
    const isTopRow = index < topCount;
    const slot = isTopRow ? index : index - topCount;
    const deskColumn = left + slot * DESK_PITCH;
    const deskRect = rect(deskColumn, isTopRow ? top + 2 : top + 3, 2, 1);
    const chairRow = isTopRow ? top + 1 : top + 4;
    const facing = isTopRow ? "down" : "up";
    builder.addFurniture("desk", deskRect, true, request.color);
    return {
      agentName,
      seat: chairSeat(tilePoint(deskColumn, chairRow), facing, true),
      visitorSpot: standingSeat(tilePoint(deskColumn + 2, chairRow), facing),
      roomId: request.roomId,
      deskKind: "pod" as const,
      deskRect,
      accentColor: request.color,
    };
  });
}

function packPods(builder: LayoutBuilder, area: TileRect, requests: PodRequest[]): Workstation[] {
  const podRows = arrangePodRows(requests, area.width);
  const totalHeight = podRows.length * POD_HEIGHT + Math.max(0, podRows.length - 1) * POD_ROW_GAP;
  let top = area.row + Math.max(0, Math.floor((area.height - totalHeight) / 2));
  const stations: Workstation[] = [];
  for (const podRow of podRows) {
    let left = area.column + Math.max(0, Math.floor((area.width - rowWidth(podRow)) / 2));
    for (const request of podRow) {
      stations.push(...placePod(builder, request, left, top));
      left += podWidth(request.agents.length) + POD_GAP;
    }
    top += POD_HEIGHT + POD_ROW_GAP;
  }
  return stations;
}

function addPlants(builder: LayoutBuilder, spots: ReadonlyArray<readonly [number, number]>): void {
  for (const [column, row] of spots) builder.addFurniture("plant", rect(column, row, 1, 1), true);
}

function buildDirectorOffices(builder: LayoutBuilder, directors: RosterAgent[]): Workstation[] {
  const stations: Workstation[] = [];
  for (let slot = 0; slot < DIRECTOR_OFFICE_COUNT; slot += 1) {
    const director = directors[slot];
    const left = slot * DIRECTOR_OFFICE_PITCH;
    const centerColumn = left + 5;
    const roomId = `office-${director?.name ?? `vacant-${slot}`}`;
    builder.addRoom(
      {
        id: roomId,
        label: director ? displayName(director.name) : "Vacant Office",
        kind: "director-office",
        rect: rect(left, 0, 11, 10),
        floor: "carpet",
        wallColor: WALLPAPER.director,
        ownerAgent: director?.name ?? null,
        accentColor: LEADERSHIP_GOLD,
      },
      [tilePoint(centerColumn - 1, 9), tilePoint(centerColumn, 9)],
    );
    builder.addWindows(1, [left + 6]);
    builder.addFurniture("rug", rect(centerColumn - 3, 3, 6, 5), false, LEADERSHIP_GOLD);
    const deskRect = rect(centerColumn - 2, 4, 4, 1);
    builder.addFurniture("executive-desk", deskRect, true);
    builder.addFurniture("bookshelf", rect(left + 1, 1, 2, 1), true);
    builder.addFurniture("poster", rect(left + 4, 1, 1, 1), false, LEADERSHIP_GOLD);
    builder.addFurniture("hanging-plant", rect(left + 9, 1, 1, 1), false);
    builder.addFurniture("lamp", rect(left + 9, 3, 1, 1), true);
    addPlants(builder, [
      [left + 1, 8],
      [left + 9, 8],
    ]);
    if (!director) continue;
    stations.push({
      agentName: director.name,
      seat: chairSeat(tilePoint(centerColumn - 1, 3), "down", true),
      visitorSpot: standingSeat(tilePoint(centerColumn - 1, 6), "up", true),
      roomId,
      deskKind: "executive",
      deskRect,
      accentColor: LEADERSHIP_GOLD,
    });
  }
  return stations;
}

function buildMeetingRoom(builder: LayoutBuilder): { seats: Seat[]; headSpot: Seat } {
  builder.addRoom(
    {
      id: "meeting",
      label: "Meeting Room",
      kind: "meeting",
      rect: rect(30, 0, 19, 10),
      floor: "meeting",
      wallColor: WALLPAPER.meeting,
      ownerAgent: null,
      accentColor: "#3fb59a",
    },
    [tilePoint(39, 9), tilePoint(40, 9)],
  );
  builder.addWindows(1, [31, 44]);
  builder.addFurniture("rug", rect(33, 2, 13, 6), false, "#3fb59a");
  builder.addFurniture("meeting-table", rect(34, 4, 11, 2), true);
  builder.addFurniture("whiteboard", rect(37, 1, 5, 1), true);
  builder.addFurniture("hanging-plant", rect(47, 1, 1, 1), false);
  builder.addFurniture("lamp", rect(47, 3, 1, 1), true);
  addPlants(builder, [
    [31, 8],
    [47, 8],
  ]);
  const seats: Seat[] = [];
  for (let column = 35; column <= 43; column += 2) {
    seats.push(chairSeat(tilePoint(column, 3), "down"));
    seats.push(chairSeat(tilePoint(column, 6), "up"));
  }
  return { seats, headSpot: standingSeat(tilePoint(32, 5), "down") };
}

function buildCafe(builder: LayoutBuilder): { loungeSpots: Seat[]; coffeeSpot: Seat; coolerSpots: Seat[] } {
  builder.addRoom(
    {
      id: "cafe",
      label: "Café",
      kind: "cafe",
      rect: rect(48, 0, 18, 10),
      floor: "lounge",
      wallColor: WALLPAPER.cafe,
      ownerAgent: null,
      accentColor: "#e06c5a",
    },
    [tilePoint(56, 9), tilePoint(57, 9)],
  );
  builder.addWindows(1, [57]);
  builder.addFurniture("rug", rect(50, 2, 8, 5), false, "#e58fb8");
  builder.addFurniture("fireplace", rect(52, 1, 4, 1), true);
  builder.addFurniture("armchair", rect(51, 4, 1, 1), false, "#c0504d");
  builder.addFurniture("armchair", rect(56, 4, 1, 1), false, "#4f86c6");
  builder.addFurniture("beanbag", rect(53, 6, 1, 1), false, "#f2c14e");
  builder.addFurniture("beanbag", rect(55, 6, 1, 1), false, "#9b6bd1");
  builder.addFurniture("water-cooler", rect(49, 1, 1, 1), true);
  builder.addFurniture("counter", rect(59, 1, 5, 1), true);
  builder.addFurniture("coffee-machine", rect(61, 1, 1, 1), false);
  builder.addFurniture("arcade", rect(64, 1, 1, 1), true, "#e05a7a");
  builder.addFurniture("kitchen-table", rect(59, 5, 4, 2), true);
  builder.addFurniture("hanging-plant", rect(51, 1, 1, 1), false);
  addPlants(builder, [
    [49, 8],
    [64, 8],
  ]);
  const sittingSpots = [
    sofaSeat(tilePoint(51, 4)),
    sofaSeat(tilePoint(56, 4)),
    sofaSeat(tilePoint(53, 6)),
    sofaSeat(tilePoint(55, 6)),
    chairSeat(tilePoint(60, 4), "down"),
    chairSeat(tilePoint(62, 4), "down"),
    chairSeat(tilePoint(60, 7), "up"),
    chairSeat(tilePoint(62, 7), "up"),
    standingSeat(tilePoint(64, 2), "up"),
  ];
  return {
    loungeSpots: sittingSpots,
    coffeeSpot: standingSeat(tilePoint(61, 2), "up"),
    coolerSpots: [standingSeat(tilePoint(49, 2), "up"), standingSeat(tilePoint(50, 2), "up")],
  };
}

function buildLeadOffices(
  builder: LayoutBuilder,
  leads: RosterAgent[],
  departments: Map<string, DepartmentConfig>,
): Workstation[] {
  const stations = leads.map((lead, index) => {
    const left = index * LEAD_OFFICE_PITCH;
    const accentColor = departments.get(lead.department)?.color ?? LEADERSHIP_GOLD;
    const roomId = `office-${lead.name}`;
    builder.addRoom(
      {
        id: roomId,
        label: displayName(lead.name),
        kind: "lead-office",
        rect: rect(left, 11, 8, 8),
        floor: "wood",
        wallColor: pastel(accentColor, 0.62),
        ownerAgent: lead.name,
        accentColor,
      },
      [tilePoint(left + 3, 11), tilePoint(left + 4, 11), tilePoint(left + 3, 18), tilePoint(left + 4, 18)],
    );
    builder.addFurniture(index % 2 === 0 ? "painting" : "pinboard", rect(left + 5, 12, 2, 1), false, accentColor);
    builder.addFurniture("rug", rect(left + 2, 13, 4, 4), false, accentColor);
    const deskRect = rect(left + 3, 15, 2, 1);
    builder.addFurniture("desk", deskRect, true, accentColor);
    builder.addFurniture("bookshelf", rect(left + 1, 12, 2, 1), true);
    builder.addFurniture("lamp", rect(left + 1, 15, 1, 1), true);
    addPlants(builder, [[left + 6, 17]]);
    return {
      agentName: lead.name,
      seat: chairSeat(tilePoint(left + 3, 14), "down", true),
      visitorSpot: standingSeat(tilePoint(left + 3, 16), "up", true),
      roomId,
      deskKind: "office" as const,
      deskRect,
      accentColor,
    };
  });
  const closetLeft = leads.length * LEAD_OFFICE_PITCH;
  if (STUDIO_COLUMNS - closetLeft >= 5) {
    builder.addRoom(
      {
        id: "server-room",
        label: "Server Room",
        kind: "closet",
        rect: rect(closetLeft, 11, STUDIO_COLUMNS - closetLeft, 8),
        floor: "closet",
        wallColor: WALLPAPER.closet,
        ownerAgent: null,
        accentColor: "#5bd17a",
      },
      [],
    );
    for (let column = closetLeft + 2; column < STUDIO_COLUMNS - 2; column += 2) {
      builder.addFurniture("server-rack", rect(column, 13, 1, 2), true);
    }
  }
  return stations;
}

function podRequests(
  agents: RosterAgent[],
  departments: DepartmentConfig[],
  zone: DepartmentConfig["zone"],
  roomId: string,
): PodRequest[] {
  return departments
    .filter((department) => department.zone === zone)
    .map((department) => {
      const members = agents
        .filter((agent) => agent.department === department.id)
        .sort((first, second) => Number(second.tier === "engine-lead") - Number(first.tier === "engine-lead"));
      return { label: department.label, color: department.color, agents: members.map((agent) => agent.name), roomId };
    })
    .filter((request) => request.agents.length > 0);
}

function buildOpenFloor(builder: LayoutBuilder, agents: RosterAgent[], departments: DepartmentConfig[]): Workstation[] {
  const doors = [6, 7, 19, 20, 32, 33].flatMap((column) => [tilePoint(column, 20), tilePoint(column, 33)]);
  builder.addRoom(
    {
      id: "open-floor",
      label: "Open Floor",
      kind: "open-floor",
      rect: rect(0, 20, 40, 14),
      floor: "parquet",
      wallColor: WALLPAPER.openFloor,
      ownerAgent: null,
      accentColor: "#e0a93b",
    },
    doors,
  );
  builder.addFurniture("pinboard", rect(3, 21, 2, 1), false);
  builder.addFurniture("wall-screen", rect(13, 21, 3, 1), false, "#6fbf5a");
  builder.addFurniture("wall-clock", rect(20, 21, 1, 1), false);
  builder.addFurniture("painting", rect(25, 21, 2, 1), false);
  builder.addFurniture("pinboard", rect(35, 21, 2, 1), false);
  builder.addFurniture("poster", rect(10, 21, 1, 1), false, "#5b8def");
  builder.addFurniture("poster", rect(29, 21, 1, 1), false, "#d16ba5");
  builder.addFurniture("hanging-plant", rect(17, 21, 1, 1), false);
  builder.addFurniture("hanging-plant", rect(22, 21, 1, 1), false);
  builder.addFurniture("lamp", rect(1, 27, 1, 1), true);
  builder.addFurniture("lamp", rect(38, 27, 1, 1), true);
  addPlants(builder, [
    [1, 32],
    [38, 32],
  ]);
  return packPods(builder, rect(2, 22, 36, 11), podRequests(agents, departments, "open-floor", "open-floor"));
}

function buildEngineLab(builder: LayoutBuilder, agents: RosterAgent[], departments: DepartmentConfig[]): Workstation[] {
  const doors = [47, 48, 57, 58].flatMap((column) => [tilePoint(column, 20), tilePoint(column, 33)]);
  builder.addRoom(
    {
      id: "engine-lab",
      label: "Engine Lab",
      kind: "engine-lab",
      rect: rect(39, 20, 27, 14),
      floor: "lab",
      wallColor: WALLPAPER.engineLab,
      ownerAgent: null,
      accentColor: "#478cbf",
    },
    doors,
  );
  builder.addFurniture("neon-sign", rect(41, 21, 3, 1), false, "#4ac0ff");
  builder.addFurniture("wall-screen", rect(51, 21, 3, 1), false, "#478cbf");
  builder.addFurniture("pinboard", rect(61, 21, 2, 1), false);
  builder.addFurniture("poster", rect(45, 21, 1, 1), false, "#478cbf");
  builder.addFurniture("hanging-plant", rect(55, 21, 1, 1), false);
  builder.addFurniture("lamp", rect(64, 27, 1, 1), true);
  addPlants(builder, [
    [40, 32],
    [64, 32],
  ]);
  return packPods(builder, rect(41, 22, 23, 11), podRequests(agents, departments, "engine-lab", "engine-lab"));
}

function buildLobby(
  builder: LayoutBuilder,
  config: StudioConfig,
): { headStation: Workstation; userSpot: Seat; entrance: TilePoint; briefingSpots: Seat[] } {
  const doors = [6, 7, 19, 20, 21, 22, 33, 34].map((column) => tilePoint(column, 35));
  const entranceDoors = [19, 20, 21, 22].map((column) => tilePoint(column, 43));
  builder.addRoom(
    {
      id: "lobby",
      label: "Lobby",
      kind: "lobby",
      rect: rect(0, 35, 42, 9),
      floor: "lobby",
      wallColor: WALLPAPER.lobby,
      ownerAgent: MAIN_AGENT,
      accentColor: config.studioHeadColor,
    },
    [...doors, ...entranceDoors],
  );
  builder.addFurniture("painting", rect(3, 36, 2, 1), false);
  builder.addFurniture("wall-clock", rect(12, 36, 1, 1), false);
  builder.addFurniture("neon-sign", rect(19, 36, 4, 1), false, "#ff6fa8");
  builder.addFurniture("painting", rect(28, 36, 2, 1), false);
  builder.addFurniture("pinboard", rect(37, 36, 2, 1), false);
  builder.addFurniture("rug", rect(11, 37, 20, 5), false, config.studioHeadColor);
  builder.addFurniture("welcome-mat", rect(19, 41, 4, 2), false);
  const deskRect = rect(17, 39, 8, 1);
  builder.addFurniture("reception-desk", deskRect, true, config.studioHeadColor);
  builder.addFurniture("sofa", rect(2, 40, 4, 1), true, "#3fb59a");
  builder.addFurniture("sofa", rect(36, 40, 4, 1), true, "#3fb59a");
  builder.addFurniture("lamp", rect(7, 40, 1, 1), true);
  builder.addFurniture("lamp", rect(34, 40, 1, 1), true);
  builder.addFurniture("poster", rect(9, 36, 1, 1), false, "#d97757");
  builder.addFurniture("poster", rect(31, 36, 1, 1), false, "#9b6bd1");
  builder.addFurniture("hanging-plant", rect(16, 36, 1, 1), false);
  builder.addFurniture("hanging-plant", rect(25, 36, 1, 1), false);
  addPlants(builder, [
    [1, 37],
    [40, 37],
    [15, 39],
    [26, 39],
  ]);
  const headStation: Workstation = {
    agentName: MAIN_AGENT,
    seat: chairSeat(tilePoint(20, 38), "down", true),
    visitorSpot: standingSeat(tilePoint(20, 40), "up", true),
    roomId: "lobby",
    deskKind: "reception",
    deskRect,
    accentColor: config.studioHeadColor,
  };
  const briefingSpots = [13, 15, 17, 24, 26, 28].map((column) => standingSeat(tilePoint(column, 40), "up"));
  return {
    headStation,
    userSpot: standingSeat(tilePoint(20, 41), "up", true),
    entrance: tilePoint(20, 42),
    briefingSpots,
  };
}

function buildHotDesks(builder: LayoutBuilder, guestColor: string): { stations: Workstation[]; overflow: Seat[] } {
  builder.addRoom(
    {
      id: "hot-desks",
      label: "Hot Desks",
      kind: "hot-desks",
      rect: rect(41, 35, 25, 9),
      floor: "wood",
      wallColor: WALLPAPER.hotDesks,
      ownerAgent: null,
      accentColor: guestColor,
    },
    [tilePoint(52, 35), tilePoint(53, 35)],
  );
  builder.addFurniture("pinboard", rect(44, 36, 2, 1), false);
  builder.addFurniture("wall-clock", rect(60, 36, 1, 1), false);
  builder.addFurniture("rug", rect(47, 37, 14, 5), false, "#9fd9c6");
  builder.addFurniture("lamp", rect(64, 38, 1, 1), true);
  builder.addFurniture("hanging-plant", rect(57, 36, 1, 1), false);
  addPlants(builder, [
    [42, 42],
    [64, 42],
  ]);
  const request: PodRequest = {
    label: "Contractors",
    color: guestColor,
    agents: Array<string | null>(GUEST_DESK_COUNT).fill(null),
    roomId: "hot-desks",
  };
  const stations = packPods(builder, rect(43, 37, 20, 5), [request]);
  const overflow: Seat[] = [];
  for (let column = 43; column <= 63; column += 2) overflow.push(standingSeat(tilePoint(column, 42), "up"));
  return { stations, overflow };
}

export function buildStudioLayout(roster: RosterAgent[], config: StudioConfig): StudioLayout {
  const builder = new LayoutBuilder(STUDIO_COLUMNS, STUDIO_ROWS);
  const departments = new Map(config.departments.map((department) => [department.id, department]));
  const guestColor = departments.get(GUEST_DEPARTMENT)?.color ?? "#8d939c";
  const directors = roster.filter((agent) => agent.tier === "director").slice(0, DIRECTOR_OFFICE_COUNT);
  const leads = roster.filter((agent) => agent.tier === "lead").slice(0, MAX_LEAD_OFFICES);
  const officeAgents = new Set([...directors, ...leads].map((agent) => agent.name));
  const podAgents = roster.filter(
    (agent) => !officeAgents.has(agent.name) && departments.has(agent.department) && agent.department !== GUEST_DEPARTMENT,
  );

  const stations = [
    ...buildDirectorOffices(builder, directors),
    ...buildLeadOffices(builder, leads, departments),
    ...buildOpenFloor(builder, podAgents, config.departments),
    ...buildEngineLab(builder, podAgents, config.departments),
  ];
  const meeting = buildMeetingRoom(builder);
  const cafe = buildCafe(builder);
  const lobby = buildLobby(builder, config);
  const hotDesks = buildHotDesks(builder, guestColor);
  builder.addCorridors();
  builder.applyDoors();

  const workstations = new Map<string, Workstation>();
  for (const station of stations) if (station.agentName) workstations.set(station.agentName, station);

  return {
    columns: builder.columns,
    rows: builder.rows,
    cells: builder.cells,
    walkable: builder.walkable(),
    rooms: builder.rooms,
    furniture: builder.furniture,
    windows: builder.windows,
    podLabels: builder.podLabels,
    workstations,
    guestStations: hotDesks.stations,
    guestOverflowSpots: hotDesks.overflow,
    headStation: lobby.headStation,
    userSpot: lobby.userSpot,
    entrance: lobby.entrance,
    briefingSpots: lobby.briefingSpots,
    meetingSeats: meeting.seats,
    meetingHeadSpot: meeting.headSpot,
    loungeSpots: cafe.loungeSpots,
    coffeeSpot: cafe.coffeeSpot,
    coolerSpots: cafe.coolerSpots,
  };
}
