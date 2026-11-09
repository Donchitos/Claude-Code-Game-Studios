import {
  MAIN_AGENT,
  type ActiveTask,
  type MainStatus,
  type StudioEvent,
  type TaskOutcome,
  type TimingConfig,
} from "../../shared/protocol.ts";
import { toolIcon, truncate } from "../../shared/tool-summary.ts";
import type { AgentActor, CancelToken } from "./agent-actor.ts";
import { standingSeat, type Seat, type StudioLayout } from "./layout.ts";
import type { BubbleStyle } from "./overlay.ts";

export interface StudioCast {
  readonly layout: StudioLayout;
  readonly head: AgentActor;
  readonly user: AgentActor;
  rosterActors(): AgentActor[];
  findActor(agentName: string): AgentActor | undefined;
  summonGuest(agentType: string, arriveInstantly: boolean): AgentActor;
  dismissGuest(actor: AgentActor): void;
  spotlight(actor: AgentActor): void;
  flyDocument(from: AgentActor, to: AgentActor, completed: boolean): Promise<void>;
}

type AssignedEvent = Extract<StudioEvent, { kind: "agent_assigned" }>;

interface DispatchBurst {
  events: AssignedEvent[];
  timer: ReturnType<typeof setTimeout> | undefined;
  meeting: boolean;
}

interface Barrier {
  ready: Promise<void>;
  arrive(): void;
}

const AMBIENT_TICK_MS = 1000;
const REPORT_PAUSE_MS = 1300;
const SHORT_PAUSE_MS = 500;
const DOCUMENT_STAGGER_MS = 260;
const NOTICE_MS = 2500;
const LINGER_POLL_MS = 500;
const BRIEF_LENGTH = 110;
const SPEECH_LENGTH = 150;
const AMBIENT_EMOTES = ["😌", "📱", "🎮", "📖", "🎧"];
const OUTCOME_REPORTS: Record<TaskOutcome, { icon: string; style: BubbleStyle; fallback: string }> = {
  completed: { icon: "✅", style: "success", fallback: "Done" },
  failed: { icon: "⚠️", style: "warning", fallback: "Ran into a problem" },
  stopped: { icon: "⏹", style: "warning", fallback: "Stopped" },
};

function createErrand(): CancelToken {
  return {
    cancelled: false,
    cancel() {
      this.cancelled = true;
    },
  };
}

function createBarrier(count: number, timeoutMs: number): Barrier {
  let arrived = 0;
  let release: () => void = () => undefined;
  const ready = new Promise<void>((resolve) => {
    release = resolve;
    globalThis.setTimeout(resolve, timeoutMs);
  });
  return {
    ready,
    arrive: () => {
      arrived += 1;
      if (arrived >= count) release();
    },
  };
}

function tail(text: string, maxLength: number): string {
  const singleLine = text.replace(/\s+/g, " ").trim();
  return singleLine.length <= maxLength ? singleLine : `…${singleLine.slice(-(maxLength - 1))}`;
}

function randomBetween(minimum: number, maximum: number): number {
  return minimum + Math.random() * (maximum - minimum);
}

function randomItem<T>(items: readonly T[]): T {
  return items[Math.floor(Math.random() * items.length)]!;
}

function plural(count: number, word: string): string {
  return `${count} ${word}${count === 1 ? "" : "s"}`;
}

export class StudioDirector {
  private readonly bursts = new Map<string, DispatchBurst>();
  private readonly taskParents = new Map<string, string>();
  private readonly nextAmbientAt = new Map<string, number>();
  private readonly occupiedLoungeSpots = new Set<Seat>();
  private readonly occupiedMeetingSeats = new Set<Seat>();
  private readonly pendingDeliveries = new Map<AgentActor, number>();
  private readonly meetingHosts = new Set<AgentActor>();
  private readonly deliveryErrands = new Map<AgentActor, CancelToken[]>();
  private headDraft = "";
  private briefingIndex = 0;
  private ambientEnabled = true;
  private ambientWalkers = 0;
  private nextTickAt = 0;

  constructor(
    private readonly cast: StudioCast,
    private readonly timing: TimingConfig,
  ) {}

  setAmbientEnabled(enabled: boolean): void {
    this.ambientEnabled = enabled;
    if (enabled) return;
    for (const actor of this.cast.rosterActors()) actor.cancelAmbient();
  }

  handle(event: StudioEvent): void {
    switch (event.kind) {
      case "agent_assigned":
        this.onAssigned(event);
        return;
      case "agent_tool": {
        const actor = this.actorFor(event.agentType);
        actor.showActivity(`${toolIcon(event.toolName)} ${event.summary}`, "tool", actor.isWorking ? 0 : this.timing.toolBubbleMs);
        this.cast.spotlight(actor);
        return;
      }
      case "agent_text":
        this.closeBurst(event.agentType);
        this.actorFor(event.agentType).say(truncate(event.text, SPEECH_LENGTH), "speech", this.timing.speechBubbleMs);
        return;
      case "agent_thinking": {
        const actor = this.actorFor(event.agentType);
        actor.showActivity("💭 thinking…", "thought", actor.isWorking ? 0 : this.timing.toolBubbleMs);
        return;
      }
      case "agent_finished":
        this.onFinished(event.taskId, event.agentType, event.outcome, event.summary);
        return;
      case "agent_message":
        this.onMessage(event.fromAgent, event.toAgent, event.text);
        return;
      case "main_status":
        this.onMainStatus(event.status);
        return;
      case "main_text_delta":
        this.headDraft += event.text;
        this.cast.head.say(tail(this.headDraft, SPEECH_LENGTH), "speech", this.timing.speechBubbleMs);
        return;
      case "main_text":
        this.closeBurst(MAIN_AGENT);
        this.headDraft = "";
        this.cast.head.say(truncate(event.text, SPEECH_LENGTH), "speech", this.timing.speechBubbleMs + 1500);
        return;
      case "main_tool":
        this.closeBurst(MAIN_AGENT);
        this.cast.head.showActivity(`${toolIcon(event.toolName)} ${event.summary}`, "tool", this.timing.toolBubbleMs);
        return;
      case "user_text":
        this.cast.user.say(truncate(event.text, SPEECH_LENGTH), "user", this.timing.speechBubbleMs + 1000);
        return;
      case "turn_finished":
        this.closeBurst(MAIN_AGENT);
        this.headDraft = "";
        if (event.isError) this.cast.head.say(`⚠️ ${truncate(event.resultText || "Turn failed", 120)}`, "warning", 6000);
        return;
      case "session_exited":
        this.onMainStatus("idle");
        return;
      default:
        return;
    }
  }

  applySnapshot(activeTasks: ActiveTask[]): void {
    for (const burst of this.bursts.values()) globalThis.clearTimeout(burst.timer);
    this.bursts.clear();
    this.taskParents.clear();
    this.occupiedMeetingSeats.clear();
    this.pendingDeliveries.clear();
    this.meetingHosts.clear();
    this.deliveryErrands.clear();
    this.headDraft = "";
    for (const actor of this.cast.rosterActors()) {
      actor.tasks.clear();
      actor.workSeat = null;
      actor.cancelAmbient();
      actor.clearActivity();
      actor.teleportHome();
      actor.refreshWorkState();
    }
    for (const task of activeTasks) {
      const actor = this.actorFor(task.agentType, true);
      actor.tasks.set(task.taskId, {
        taskId: task.taskId,
        description: task.description,
        prompt: "",
        parentAgent: task.parentAgent,
        startedAt: Date.now(),
      });
      this.taskParents.set(task.taskId, task.parentAgent);
      actor.teleportHome();
      actor.refreshWorkState();
    }
    this.onMainStatus("idle");
  }

  tick(now: number): void {
    if (!this.ambientEnabled || now < this.nextTickAt) return;
    this.nextTickAt = now + AMBIENT_TICK_MS;
    for (const actor of this.cast.rosterActors()) {
      if (actor.isWorking || actor.isBusy) continue;
      const dueAt = this.nextAmbientAt.get(actor.name) ?? this.scheduleAmbient(actor, now);
      if (now < dueAt) continue;
      this.scheduleAmbient(actor, now);
      if (this.ambientWalkers >= this.timing.maxAmbientWalkers) continue;
      this.startAmbient(actor);
    }
  }

  private actorFor(agentName: string, arriveInstantly = false): AgentActor {
    if (agentName === MAIN_AGENT) return this.cast.head;
    return this.cast.findActor(agentName) ?? this.cast.summonGuest(agentName, arriveInstantly);
  }

  private visitSpotFor(host: AgentActor): Seat {
    if (host === this.cast.head && !host.workSeat) {
      const spots = this.cast.layout.briefingSpots;
      const spot = spots[this.briefingIndex % spots.length]!;
      this.briefingIndex += 1;
      return spot;
    }
    const tableSeat = host.workSeat;
    if (tableSeat) return standingSeat({ column: tableSeat.tile.column + 1, row: tableSeat.tile.row }, tableSeat.facing);
    return host.home?.visitorSpot ?? this.cast.layout.headStation.visitorSpot;
  }

  private onAssigned(event: AssignedEvent): void {
    const receiver = this.actorFor(event.agentType);
    const giver = this.actorFor(event.parentAgent);
    receiver.tasks.set(event.taskId, {
      taskId: event.taskId,
      description: event.description,
      prompt: event.prompt,
      parentAgent: event.parentAgent,
      startedAt: Date.now(),
    });
    receiver.cancelAmbient();
    receiver.updateNameTag();
    this.taskParents.set(event.taskId, event.parentAgent);
    if (receiver.isGuest && !receiver.isAtWorkSeat()) {
      void receiver.run("task", async (token) => {
        receiver.status = "Arriving at the studio";
        await receiver.goToWork(token);
      });
    }
    receiver.say("❗", "brief", NOTICE_MS);
    this.cast.spotlight(receiver);
    const giverName = event.parentAgent;
    const burst = this.bursts.get(giverName);
    if (!burst) {
      this.bursts.set(giverName, { events: [event], timer: this.burstTimer(giverName), meeting: false });
      this.deliver(giver, event);
      return;
    }
    globalThis.clearTimeout(burst.timer);
    burst.timer = this.burstTimer(giverName);
    burst.events.push(event);
    const receivers = new Set(burst.events.map((candidate) => candidate.agentType).filter((agentType) => agentType !== giverName));
    if (burst.meeting) {
      this.joinMeeting(giver, event);
      return;
    }
    if (receivers.size >= 2) {
      burst.meeting = true;
      this.holdMeeting(giver, burst.events);
      return;
    }
    this.deliver(giver, event);
  }

  private burstTimer(giverName: string): ReturnType<typeof setTimeout> {
    return globalThis.setTimeout(() => this.closeBurst(giverName), this.timing.dispatchQuietMs);
  }

  private closeBurst(giverName: string): void {
    const burst = this.bursts.get(giverName);
    if (!burst) return;
    globalThis.clearTimeout(burst.timer);
    this.bursts.delete(giverName);
  }

  private deliver(giver: AgentActor, event: AssignedEvent): void {
    const receiver = this.actorFor(event.agentType);
    if (receiver === giver) {
      void receiver.run("task", (token) => receiver.goToWork(token));
      return;
    }
    this.pendingDeliveries.set(giver, (this.pendingDeliveries.get(giver) ?? 0) + 1);
    const errand = createErrand();
    this.deliveryErrands.set(giver, [...(this.deliveryErrands.get(giver) ?? []), errand]);
    void receiver.run("task", async (token) => {
      await receiver.goToWork(token);
    });
    void giver.run("task", async () => {
      if (errand.cancelled) return;
      giver.status = `Bringing a task to ${receiver.label}`;
      const spot = this.visitSpotFor(receiver);
      await giver.walkTo(spot.tile, errand);
      if (errand.cancelled) return;
      const token = errand;
      giver.face(spot.facing);
      giver.say(`📋 ${truncate(event.description, BRIEF_LENGTH)}`, "brief", this.timing.meetingTurnMs + 900);
      await this.cast.flyDocument(giver, receiver, false);
      receiver.say("On it!", "speech", 1600);
      await giver.wait(SHORT_PAUSE_MS);
      const remaining = (this.pendingDeliveries.get(giver) ?? 1) - 1;
      this.pendingDeliveries.set(giver, remaining);
      if (remaining <= 0 && !this.meetingHosts.has(giver)) {
        giver.status = "Heading back";
        await giver.goToWork(token);
      }
    });
    this.cast.spotlight(giver);
  }

  private reserveMeetingSeats(count: number): Seat[] {
    const free = this.cast.layout.meetingSeats.filter((seat) => !this.occupiedMeetingSeats.has(seat));
    const reserved = free.slice(0, count);
    for (const seat of reserved) this.occupiedMeetingSeats.add(seat);
    return reserved;
  }

  private releaseMeetingSeat(actor: AgentActor): void {
    if (!actor.workSeat) return;
    this.occupiedMeetingSeats.delete(actor.workSeat);
    actor.workSeat = null;
  }

  private cancelDeliveries(giver: AgentActor): void {
    for (const errand of this.deliveryErrands.get(giver) ?? []) errand.cancel();
    this.deliveryErrands.delete(giver);
    this.pendingDeliveries.delete(giver);
  }

  private holdMeeting(giver: AgentActor, events: AssignedEvent[]): void {
    this.cancelDeliveries(giver);
    const briefs = new Map<AgentActor, string[]>();
    for (const event of events) {
      const actor = this.actorFor(event.agentType);
      if (actor === giver) continue;
      briefs.set(actor, [...(briefs.get(actor) ?? []), event.description]);
    }
    const members = [...briefs.keys()];
    const seats = this.reserveMeetingSeats(members.length);
    const seated = members.slice(0, seats.length);
    for (const extra of members.slice(seats.length)) {
      for (const event of events.filter((candidate) => this.actorFor(candidate.agentType) === extra)) this.deliver(giver, event);
    }
    const arrival = createBarrier(seated.length + 1, this.timing.meetingArrivalTimeoutMs);
    const turn = this.timing.meetingTurnMs;
    seated.forEach((member, index) => {
      this.releaseMeetingSeat(member);
      member.workSeat = seats[index]!;
      this.occupiedMeetingSeats.add(member.workSeat);
      const description = (briefs.get(member) ?? []).join(" · ");
      void member.run("task", async (token) => {
        member.status = `Heading to a meeting with ${giver.label}`;
        await member.goToWork(token);
        arrival.arrive();
        await arrival.ready;
        member.status = `In a meeting with ${giver.label}`;
        await member.wait(turn * (index + 1) + DOCUMENT_STAGGER_MS * seated.length);
        member.say(`🗣️ I'll take: ${truncate(description, BRIEF_LENGTH)}`, "speech", turn + 600);
        await member.wait(turn * (seated.length - index));
      });
    });
    this.meetingHosts.add(giver);
    void giver.run("task", async (token) => {
      giver.status = `Calling a meeting with ${plural(seated.length, "agent")}`;
      await giver.sitAt(this.cast.layout.meetingHeadSpot, token);
      arrival.arrive();
      await arrival.ready;
      giver.status = `Running a meeting with ${plural(seated.length, "agent")}`;
      giver.say(`📋 Kickoff: ${plural(seated.length, "task")} to split`, "brief", turn + 400);
      for (const member of seated) {
        void this.cast.flyDocument(giver, member, false);
        await giver.wait(DOCUMENT_STAGGER_MS);
      }
      await giver.wait(turn * (seated.length + 1));
      giver.say("Great, let's go!", "speech", 1600);
      while (this.bursts.has(giver.name)) {
        await new Promise((resolve) => globalThis.setTimeout(resolve, LINGER_POLL_MS));
      }
      this.meetingHosts.delete(giver);
      giver.status = "Heading back";
      await giver.goToWork(token);
    });
    this.cast.spotlight(giver);
  }

  private joinMeeting(giver: AgentActor, event: AssignedEvent): void {
    const member = this.actorFor(event.agentType);
    if (member === giver) return;
    const turn = this.timing.meetingTurnMs;
    const alreadySeated = member.workSeat !== null && this.occupiedMeetingSeats.has(member.workSeat);
    if (!alreadySeated) {
      const [seat] = this.reserveMeetingSeats(1);
      if (!seat) {
        this.deliver(giver, event);
        return;
      }
      member.workSeat = seat;
    }
    void member.run("task", async (token) => {
      member.status = `Joining the meeting with ${giver.label}`;
      await member.goToWork(token);
      await this.cast.flyDocument(giver, member, false);
      member.say(`🗣️ I'll take: ${truncate(event.description, BRIEF_LENGTH)}`, "speech", turn + 600);
      member.status = `In a meeting with ${giver.label}`;
    });
  }

  private onFinished(taskId: string, agentType: string, outcome: TaskOutcome, summary: string): void {
    const actor = this.cast.findActor(agentType);
    if (!actor) return;
    actor.tasks.delete(taskId);
    actor.updateNameTag();
    if (actor.tasks.size === 0) actor.clearActivity();
    const giverName = this.taskParents.get(taskId) ?? MAIN_AGENT;
    this.taskParents.delete(taskId);
    const giver = giverName === MAIN_AGENT ? this.cast.head : (this.cast.findActor(giverName) ?? this.cast.head);
    const report = OUTCOME_REPORTS[outcome];
    const reportText = `${report.icon} ${truncate(summary || report.fallback, 120)}`;
    void actor.run("task", async (token) => {
      const done = actor.tasks.size === 0;
      const giverAtSameTable = this.meetingHosts.has(giver) && actor.workSeat !== null;
      if (done) this.releaseMeetingSeat(actor);
      if (outcome !== "stopped" && giver !== actor) {
        actor.status = `Bringing results to ${giver.label}`;
        if (!giverAtSameTable) {
          const spot = this.visitSpotFor(giver);
          await actor.walkTo(spot.tile, token);
          actor.face(spot.facing);
        }
        actor.say(reportText, report.style, this.timing.speechBubbleMs);
        await this.cast.flyDocument(actor, giver, outcome === "completed");
        giver.say(outcome === "completed" ? "👍 Thanks!" : "Noted, thanks.", "speech", 1800);
        await actor.wait(REPORT_PAUSE_MS);
      } else {
        actor.say(reportText, report.style, this.timing.speechBubbleMs);
      }
      if (actor.isGuest && actor.tasks.size === 0) {
        actor.status = "Leaving the studio";
        await actor.walkTo(this.cast.layout.entrance, token);
        this.cast.dismissGuest(actor);
        return;
      }
      actor.status = done ? "Heading back to desk" : "Back to the next task";
      await actor.goToWork(token);
    });
    this.cast.spotlight(actor);
  }

  private onMessage(fromName: string, toName: string, text: string): void {
    const sender = fromName === MAIN_AGENT ? this.cast.head : (this.cast.findActor(fromName) ?? this.cast.head);
    const recipient = toName === MAIN_AGENT ? this.cast.head : this.cast.findActor(toName);
    if (!recipient || recipient === sender) {
      sender.say(`💬 ${truncate(text, BRIEF_LENGTH)}`, "speech", this.timing.speechBubbleMs);
      return;
    }
    const seats = this.reserveMeetingSeats(2);
    if (seats.length < 2) {
      for (const seat of seats) this.occupiedMeetingSeats.delete(seat);
      void sender.run("task", async (token) => {
        const spot = this.visitSpotFor(recipient);
        await sender.walkTo(spot.tile, token);
        sender.face(spot.facing);
        sender.say(`💬 ${truncate(text, BRIEF_LENGTH)}`, "speech", this.timing.meetingTurnMs + 600);
        await sender.wait(this.timing.meetingTurnMs);
        recipient.say("👌 Got it", "speech", 1500);
        await sender.wait(SHORT_PAUSE_MS);
        await sender.goToWork(token);
      });
      return;
    }
    const [senderSeat, recipientSeat] = seats as [Seat, Seat];
    const arrival = createBarrier(2, this.timing.meetingArrivalTimeoutMs);
    const turn = this.timing.meetingTurnMs;
    const discuss = (participant: AgentActor, seat: Seat, partner: AgentActor, line: string, speaksFirst: boolean) =>
      participant.run("task", async (token) => {
        participant.status = `Discussing with ${partner.label}`;
        await participant.sitAt(seat, token);
        arrival.arrive();
        await arrival.ready;
        if (!speaksFirst) await participant.wait(turn);
        participant.say(line, "speech", turn + 500);
        await participant.wait(speaksFirst ? turn * 2 : turn);
        this.occupiedMeetingSeats.delete(seat);
        await participant.goToWork(token);
      });
    void discuss(sender, senderSeat, recipient, `💬 ${truncate(text, BRIEF_LENGTH)}`, true);
    void discuss(recipient, recipientSeat, sender, "👌 Got it, let's do that.", false);
    this.cast.spotlight(sender);
  }

  private onMainStatus(status: MainStatus): void {
    const head = this.cast.head;
    head.externalBusy = status !== "idle";
    if (status === "thinking") head.showActivity("💭 thinking…", "thought", 0);
    else if (status === "idle" || status === "responding") head.clearActivity();
    if (status === "idle") head.status = "Waiting for your next message";
    else head.status = status === "thinking" ? "Thinking" : status === "responding" ? "Writing a reply" : "Using tools";
    if (!head.isBusy) head.refreshWorkState();
  }

  private scheduleAmbient(actor: AgentActor, now: number): number {
    const dueAt = now + randomBetween(this.timing.ambientMinDelayMs, this.timing.ambientMaxDelayMs);
    this.nextAmbientAt.set(actor.name, dueAt);
    return dueAt;
  }

  private startAmbient(actor: AgentActor): void {
    const roll = Math.random();
    if (roll < 0.35) this.ambientCoffee(actor);
    else if (roll < 0.7) this.ambientLounge(actor);
    else this.ambientChat(actor);
  }

  private trackWalker(actor: AgentActor, script: (token: CancelToken) => Promise<void>): void {
    this.ambientWalkers += 1;
    void actor
      .run("ambient", async (token) => {
        await script(token);
        if (!token.cancelled) await actor.goHome(token);
      })
      .finally(() => {
        this.ambientWalkers -= 1;
      });
  }

  private ambientCoffee(actor: AgentActor): void {
    const spot = this.cast.layout.coffeeSpot;
    this.trackWalker(actor, async (token) => {
      actor.status = "Grabbing a coffee";
      await actor.walkTo(spot.tile, token);
      if (token.cancelled) return;
      actor.face(spot.facing);
      actor.say("☕", "ambient", 2600);
      await actor.wait(2600);
    });
  }

  private ambientLounge(actor: AgentActor): void {
    const freeSpots = this.cast.layout.loungeSpots.filter((spot) => !this.occupiedLoungeSpots.has(spot));
    if (freeSpots.length === 0) {
      this.ambientCoffee(actor);
      return;
    }
    const spot = randomItem(freeSpots);
    this.occupiedLoungeSpots.add(spot);
    this.trackWalker(actor, async (token) => {
      try {
        actor.status = "Taking a break";
        await actor.sitAt(spot, token);
        if (token.cancelled) return;
        actor.say(randomItem(AMBIENT_EMOTES), "ambient", 5000);
        await actor.wait(randomBetween(5000, 9000));
      } finally {
        this.occupiedLoungeSpots.delete(spot);
      }
    });
  }

  private ambientChat(actor: AgentActor): void {
    const partner = this.cast
      .rosterActors()
      .find((candidate) => candidate !== actor && !candidate.isWorking && !candidate.isBusy);
    if (!partner) {
      this.ambientCoffee(actor);
      return;
    }
    const [firstSpot, secondSpot] = this.cast.layout.coolerSpots;
    if (!firstSpot || !secondSpot) return;
    const chat = async (participant: AgentActor, spot: Seat, line: string, delayMs: number, token: CancelToken) => {
      participant.status = "Chatting at the water cooler";
      await participant.walkTo(spot.tile, token);
      if (token.cancelled) return;
      participant.face(spot.facing);
      await participant.wait(delayMs);
      participant.say(line, "ambient", 2400);
      await participant.wait(3600 - delayMs);
    };
    this.trackWalker(actor, (token) => chat(actor, firstSpot, "…", 0, token));
    this.trackWalker(partner, (token) => chat(partner, secondSpot, "😄", 1400, token));
  }
}
