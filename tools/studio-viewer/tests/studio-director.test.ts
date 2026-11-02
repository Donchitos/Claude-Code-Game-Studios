import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { MAIN_AGENT, USER_AGENT, type StudioEvent } from "../shared/protocol.ts";
import type { AgentActor } from "../client/studio/agent-actor.ts";
import { buildStudioLayout, type Facing, type Seat, type TilePoint, type Workstation } from "../client/studio/layout.ts";
import { StudioDirector, type StudioCast } from "../client/studio/studio-director.ts";
import { ROSTER, STUDIO_CONFIG } from "./fixtures.ts";

const layout = buildStudioLayout(ROSTER, STUDIO_CONFIG);
const FAKE_WALK_MS = 3000;

function key(point: TilePoint): string {
  return `${point.column},${point.row}`;
}

class FakeActor {
  readonly tasks = new Map<string, unknown>();
  readonly log: string[] = [];
  status = "";
  externalBusy = false;
  hovered = false;
  workSeat: Seat | null = null;
  private seatedAt: Seat | null;

  constructor(
    readonly name: string,
    readonly home: Workstation | null,
    readonly isGuest = false,
  ) {
    this.seatedAt = home?.seat ?? null;
  }

  get label(): string {
    return this.name;
  }

  get isWorking(): boolean {
    return this.tasks.size > 0 || this.externalBusy;
  }

  get isBusy(): boolean {
    return false;
  }

  run(_kind: string, script: (token: { cancelled: boolean }) => Promise<void>): Promise<void> {
    return script({ cancelled: false });
  }

  async walkTo(tile: TilePoint, token?: { cancelled: boolean }): Promise<void> {
    this.seatedAt = null;
    this.log.push(`walk-start ${key(tile)}`);
    await new Promise((resolve) => globalThis.setTimeout(resolve, FAKE_WALK_MS));
    if (token?.cancelled) {
      this.log.push(`walk-cancelled ${key(tile)}`);
      return;
    }
    this.log.push(`walk ${key(tile)}`);
  }

  async sitAt(seat: Seat): Promise<void> {
    this.seatedAt = seat;
    this.log.push(`sit ${key(seat.tile)}`);
  }

  async goToWork(): Promise<void> {
    const seat = this.workSeat ?? this.home?.seat;
    if (seat) await this.sitAt(seat);
  }

  async goHome(): Promise<void> {
    if (this.home) await this.sitAt(this.home.seat);
  }

  isAtWorkSeat(): boolean {
    const seat = this.workSeat ?? this.home?.seat ?? null;
    return seat !== null && this.seatedAt === seat;
  }

  isAtHome(): boolean {
    return this.home !== null && this.seatedAt === this.home.seat;
  }

  wait(): Promise<void> {
    return Promise.resolve();
  }

  say(text: string): void {
    this.log.push(`say ${text}`);
  }

  face(_facing: Facing): void {}
  showActivity(): void {}
  clearActivity(): void {}
  updateNameTag(): void {}
  cancelAmbient(): void {}
  refreshWorkState(): void {}
  teleportHome(): void {
    this.seatedAt = this.home?.seat ?? null;
  }
}

class FakeCast implements StudioCast {
  readonly layout = layout;
  readonly documents: string[] = [];
  readonly actors = new Map<string, FakeActor>();
  readonly head = new FakeActor(MAIN_AGENT, layout.headStation) as unknown as AgentActor;
  readonly user = new FakeActor(USER_AGENT, null) as unknown as AgentActor;

  constructor() {
    for (const [name, station] of layout.workstations) this.actors.set(name, new FakeActor(name, station));
  }

  actor(name: string): FakeActor {
    if (name === MAIN_AGENT) return this.head as unknown as FakeActor;
    return this.actors.get(name)!;
  }

  rosterActors(): AgentActor[] {
    return [...this.actors.values()] as unknown as AgentActor[];
  }

  findActor(agentName: string): AgentActor | undefined {
    return this.actors.get(agentName) as unknown as AgentActor | undefined;
  }

  summonGuest(agentType: string): AgentActor {
    const guest = new FakeActor(agentType, layout.guestStations[0]!, true);
    this.actors.set(agentType, guest);
    return guest as unknown as AgentActor;
  }

  dismissGuest(actor: AgentActor): void {
    this.actors.delete(actor.name);
  }

  spotlight(): void {}

  async flyDocument(from: AgentActor, to: AgentActor, completed: boolean): Promise<void> {
    this.documents.push(`${from.name}->${to.name}${completed ? " done" : ""}`);
  }
}

function assigned(taskId: string, agentType: string, parentAgent = MAIN_AGENT): StudioEvent {
  return { kind: "agent_assigned", taskId, agentType, description: `${agentType} task`, prompt: "brief", parentAgent };
}

function mainText(): StudioEvent {
  return { kind: "main_text", messageId: "message", text: "Agents dispatched." };
}

let cast: FakeCast;
let director: StudioDirector;

beforeEach(() => {
  vi.useFakeTimers();
  cast = new FakeCast();
  director = new StudioDirector(cast, STUDIO_CONFIG.timing);
});

afterEach(() => {
  vi.useRealTimers();
});

describe("StudioDirector choreography", () => {
  it("calls a meeting when Claude dispatches a second agent seconds later, and both work at the table", async () => {
    director.handle(assigned("first", "qa-tester"));
    await vi.advanceTimersByTimeAsync(7000);
    director.handle(assigned("second", "ux-designer"));
    director.handle(mainText());
    await vi.runAllTimersAsync();

    const tester = cast.actor("qa-tester");
    const designer = cast.actor("ux-designer");
    expect(layout.meetingSeats).toContain(tester.workSeat);
    expect(layout.meetingSeats).toContain(designer.workSeat);
    expect(tester.workSeat).not.toBe(designer.workSeat);
    expect(tester.isAtWorkSeat()).toBe(true);
    expect(designer.isAtWorkSeat()).toBe(true);
    expect(cast.actor(MAIN_AGENT).log).toContain(`sit ${key(layout.meetingHeadSpot.tile)}`);
    expect(cast.documents).toContain(`${MAIN_AGENT}->ux-designer`);
    expect(cast.actor(MAIN_AGENT).log.at(-1)).toBe(`sit ${key(layout.headStation.seat.tile)}`);
  });

  it("starts walking to hand over a single task right away, without waiting", async () => {
    director.handle(assigned("only", "qa-tester"));
    await vi.advanceTimersByTimeAsync(0);

    const visitor = layout.workstations.get("qa-tester")!.visitorSpot;
    expect(cast.actor(MAIN_AGENT).log).toContain(`walk-start ${key(visitor.tile)}`);

    await vi.runAllTimersAsync();
    expect(cast.actor(MAIN_AGENT).log).toContain(`walk ${key(visitor.tile)}`);
    expect(cast.documents).toEqual([`${MAIN_AGENT}->qa-tester`]);
    expect(cast.actor(MAIN_AGENT).log.at(-1)).toBe(`sit ${key(layout.headStation.seat.tile)}`);
    expect(cast.actor("qa-tester").workSeat).toBeNull();
  });

  it("cancels the walk to the first desk when the dispatch turns into a meeting", async () => {
    director.handle(assigned("first", "qa-tester"));
    await vi.advanceTimersByTimeAsync(1000);
    director.handle(assigned("second", "ux-designer"));
    await vi.runAllTimersAsync();

    const visitor = layout.workstations.get("qa-tester")!.visitorSpot;
    const headLog = cast.actor(MAIN_AGENT).log;
    expect(headLog).toContain(`walk-cancelled ${key(visitor.tile)}`);
    expect(headLog).not.toContain(`walk ${key(visitor.tile)}`);
    expect(headLog).toContain(`sit ${key(layout.meetingHeadSpot.tile)}`);
  });

  it("hands results over at the table while the giver is still in the meeting", async () => {
    director.handle(assigned("first", "qa-tester"));
    director.handle(assigned("second", "ux-designer"));
    await vi.advanceTimersByTimeAsync(2000);
    director.handle({ kind: "agent_finished", taskId: "first", agentType: "qa-tester", outcome: "completed", summary: "Done fast" });
    await vi.runAllTimersAsync();

    const tester = cast.actor("qa-tester");
    expect(cast.documents).toContain(`qa-tester->${MAIN_AGENT} done`);
    expect(tester.log.some((entry) => entry.startsWith("walk-start") && layout.briefingSpots.some((spot) => entry.endsWith(key(spot.tile))))).toBe(false);
    expect(tester.isAtHome()).toBe(true);
  });

  it("lets a third agent join a meeting that is already running", async () => {
    director.handle(assigned("first", "qa-tester"));
    director.handle(assigned("second", "ux-designer"));
    await vi.advanceTimersByTimeAsync(8000);
    director.handle(assigned("third", "level-designer"));
    await vi.runAllTimersAsync();

    const joiner = cast.actor("level-designer");
    expect(layout.meetingSeats).toContain(joiner.workSeat);
    expect(joiner.isAtWorkSeat()).toBe(true);
    expect(cast.documents).toContain(`${MAIN_AGENT}->level-designer`);
  });

  it("has an agent walk over to the agent it delegates to", async () => {
    director.handle(assigned("lead", "qa-tester"));
    director.handle(mainText());
    director.handle(assigned("nested", "ux-designer", "qa-tester"));
    director.handle({ kind: "agent_tool", taskId: "lead", agentType: "qa-tester", toolName: "Read", summary: "brief.md" });
    await vi.runAllTimersAsync();

    const visitor = layout.workstations.get("ux-designer")!.visitorSpot;
    expect(cast.actor("qa-tester").log).toContain(`walk ${key(visitor.tile)}`);
    expect(cast.documents).toContain("qa-tester->ux-designer");
  });

  it("brings the finished result back to the giver and frees the meeting seat", async () => {
    director.handle(assigned("first", "qa-tester"));
    director.handle(assigned("second", "ux-designer"));
    director.handle(mainText());
    await vi.runAllTimersAsync();

    director.handle({ kind: "agent_finished", taskId: "first", agentType: "qa-tester", outcome: "completed", summary: "Tests planned" });
    await vi.runAllTimersAsync();

    const tester = cast.actor("qa-tester");
    expect(cast.documents.at(-1)).toBe(`qa-tester->${MAIN_AGENT} done`);
    expect(tester.log).toContain("say ✅ Tests planned");
    expect(tester.workSeat).toBeNull();
    expect(tester.isAtHome()).toBe(true);
  });

  it("sends two agents to the meeting room to discuss when one messages the other", async () => {
    director.handle({ kind: "agent_message", fromAgent: "qa-tester", toAgent: "ux-designer", text: "Can we align on menus?" });
    await vi.runAllTimersAsync();

    const meetingTiles = new Set(layout.meetingSeats.map((seat) => key(seat.tile)));
    const satInMeeting = (actor: FakeActor) => actor.log.some((entry) => entry.startsWith("sit ") && meetingTiles.has(entry.slice(4)));
    expect(satInMeeting(cast.actor("qa-tester"))).toBe(true);
    expect(satInMeeting(cast.actor("ux-designer"))).toBe(true);
    expect(cast.actor("qa-tester").log).toContain("say 💬 Can we align on menus?");
    expect(cast.actor("qa-tester").isAtHome()).toBe(true);
  });
});
