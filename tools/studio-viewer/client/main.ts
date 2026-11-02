import Phaser from "phaser";
import { withVisualDefaults, type ServerMessage, type StudioEvent } from "../shared/protocol.ts";
import "./styles.css";
import { StudioSocket } from "./socket.ts";
import { buildStudioLayout } from "./studio/layout.ts";
import { OverlayLayer } from "./studio/overlay.ts";
import { StudioScene } from "./studio/studio-scene.ts";
import { ViewProjection } from "./studio/view-projection.ts";
import { ActivityLog } from "./ui/activity-log.ts";
import { ChatPanel } from "./ui/chat-panel.ts";
import { byId, element, readStoredValue, writeStoredValue } from "./ui/dom.ts";
import { Inspector } from "./ui/inspector.ts";
import { ActivityTicker } from "./ui/ticker.ts";
import { TopBar } from "./ui/top-bar.ts";

type HelloMessage = Extract<ServerMessage, { type: "hello" }>;

const CHAT_WIDTH_KEY = "ccgs-studio-chat-width";
const NIGHT_KEY = "ccgs-studio-night";
const MIN_CHAT_WIDTH = 300;
const MAX_CHAT_WIDTH = 760;
const INSPECTOR_REFRESH_MS = 1000;

const socketProtocol = window.location.protocol === "https:" ? "wss" : "ws";
const socket = new StudioSocket(`${socketProtocol}://${window.location.host}/studio-socket`);
const stage = byId("studio-stage");
const diorama = byId("studio-diorama");
const projection = new ViewProjection({ enabled: false, degrees: 0, perspectiveFactor: 2 });
const overlay = new OverlayLayer(byId("studio-overlay"), projection);
const activity = new ActivityLog();
const ticker = new ActivityTicker(byId("activity-ticker"));
let scene: StudioScene | null = null;
let inspector: Inspector | null = null;
let gameStarted = false;
let pendingHello: HelloMessage | null = null;
const bufferedEvents: StudioEvent[] = [];

function initialNight(): boolean {
  const stored = readStoredValue(NIGHT_KEY);
  if (stored !== null) return stored === "true";
  return window.matchMedia("(prefers-color-scheme: dark)").matches;
}

let night = initialNight();
document.documentElement.dataset["theme"] = night ? "night" : "day";

function applyNight(enabled: boolean): void {
  night = enabled;
  document.documentElement.dataset["theme"] = enabled ? "night" : "day";
  writeStoredValue(NIGHT_KEY, String(enabled));
  scene?.setNight(enabled);
}

function applyTilt(enabled: boolean): void {
  projection.setEnabled(enabled);
  diorama.style.transform = projection.cssTransform();
  scene?.applyCameraEffects(enabled);
  scene?.fitView();
}

const topBar = new TopBar(byId("top-bar"), {
  fit: () => scene?.fitView(),
  setTilt: applyTilt,
  setFollow: (enabled) => scene?.setFollowEnabled(enabled),
  setAmbient: (enabled) => scene?.director.setAmbientEnabled(enabled),
  setLabels: (enabled) => overlay.setLabelsVisible(enabled),
  setNight: applyNight,
}, night);

const chat = new ChatPanel(byId("chat-pane"), {
  send: (message) => socket.send(message),
  onAgentClick: (agentName) => scene?.focusAgent(agentName),
});

function busyAgentCount(): number {
  return scene?.allActors().filter((actor) => actor.tasks.size > 0).length ?? 0;
}

function startGame(hello: HelloMessage): void {
  gameStarted = true;
  const layout = buildStudioLayout(hello.roster, hello.config);
  inspector = new Inspector(byId("inspector"), {
    roster: hello.roster,
    config: hello.config,
    activity,
    actorSnapshot: (agentName) => {
      const actor = scene?.findActor(agentName);
      return actor ? { label: actor.label, status: actor.status, tasks: [...actor.tasks.values()] } : null;
    },
    onAsk: (agentName) => chat.prefill(`Use the ${agentName} agent to `),
    onFocus: (agentName) => scene?.focusAgent(agentName),
    onClose: () => scene?.select(null),
  });
  const studioScene = new StudioScene({
    roster: hello.roster,
    config: hello.config,
    layout,
    overlay,
    visibleFraction: () => 1 / projection.overscanFactor,
    onSelect: (agentName) => inspector?.show(agentName),
    onReady: (readyScene) => {
      scene = readyScene;
      Object.assign(window, {
        ccgsStudio: {
          scene: readyScene,
          game: readyScene.game,
          replayEvent: (event: StudioEvent) => handleEvent(Date.now(), event),
        },
      });
      readyScene.setNight(night, false);
      const snapshot = pendingHello ?? hello;
      pendingHello = null;
      readyScene.director.applySnapshot(snapshot.activeTasks);
      for (const event of bufferedEvents.splice(0)) readyScene.director.handle(event);
      topBar.setBusyAgents(busyAgentCount());
    },
  });
  const visuals = hello.config.visuals;
  projection.configure({ enabled: true, degrees: visuals.tiltDegrees, perspectiveFactor: visuals.perspectiveFactor });
  projection.setViewport(stage.clientWidth, stage.clientHeight);
  diorama.style.transform = projection.cssTransform();
  const game = new Phaser.Game({
    type: Phaser.AUTO,
    parent: "studio-canvas",
    pixelArt: true,
    backgroundColor: "#2a1f2e",
    width: Math.max(1, stage.clientWidth),
    height: Math.max(1, stage.clientHeight),
    scale: { mode: Phaser.Scale.NONE },
    scene: [studioScene],
  });
  game.events.once(Phaser.Core.Events.READY, () => routePointerThroughTilt(game));
  new ResizeObserver(() => {
    const width = Math.max(1, stage.clientWidth);
    const height = Math.max(1, stage.clientHeight);
    projection.setViewport(width, height);
    diorama.style.transform = projection.cssTransform();
    game.scale.resize(width, height);
  }).observe(stage);
}

function routePointerThroughTilt(game: Phaser.Game): void {
  game.input.transformPointer = (pointer, pageX, pageY, wasMove) => {
    const bounds = stage.getBoundingClientRect();
    const local = projection.unproject({ x: pageX - window.scrollX - bounds.left, y: pageY - window.scrollY - bounds.top });
    pointer.prevPosition.x = pointer.position.x;
    pointer.prevPosition.y = pointer.position.y;
    const smoothing = pointer.smoothFactor;
    if (!wasMove || smoothing === 0) {
      pointer.position.x = local.x;
      pointer.position.y = local.y;
      return;
    }
    pointer.position.x = local.x * smoothing + pointer.prevPosition.x * (1 - smoothing);
    pointer.position.y = local.y * smoothing + pointer.prevPosition.y * (1 - smoothing);
  };
}

function showStartupError(error: unknown): void {
  const message = error instanceof Error ? error.message : String(error);
  stage.append(
    element(
      "div",
      "startup-error",
      element("strong", "", "The studio floor could not start."),
      element("p", "", message),
      element("p", "", "Restart the studio server (npm run studio) and refresh this page."),
    ),
  );
}

function handleHello(message: HelloMessage): void {
  const hello: HelloMessage = { ...message, config: withVisualDefaults(message.config) };
  activity.clear();
  for (const entry of hello.history) activity.record(entry.at, entry.event);
  chat.reset(hello.history, hello.session);
  topBar.updateSession(hello.session);
  if (!gameStarted) {
    try {
      startGame(hello);
    } catch (error) {
      showStartupError(error);
    }
    return;
  }
  if (!scene) {
    pendingHello = hello;
    bufferedEvents.length = 0;
    return;
  }
  scene.director.applySnapshot(hello.activeTasks);
  inspector?.refresh();
  topBar.setBusyAgents(busyAgentCount());
}

function handleEvent(at: number, event: StudioEvent): void {
  activity.record(at, event);
  chat.handle(at, event);
  ticker.push(event);
  if (scene) scene.director.handle(event);
  else bufferedEvents.push(event);
  inspector?.refresh();
  topBar.setBusyAgents(busyAgentCount());
}

socket.onMessage((message) => {
  switch (message.type) {
    case "hello":
      handleHello(message);
      return;
    case "event":
      handleEvent(message.at, message.event);
      return;
    case "session":
      chat.updateSession(message.session);
      topBar.updateSession(message.session);
      return;
  }
});

socket.onState((state) => {
  topBar.setConnection(state);
  chat.setConnected(state === "open");
});

window.setInterval(() => inspector?.refresh(), INSPECTOR_REFRESH_MS);

function applyChatWidth(width: number): void {
  const clamped = Math.round(Math.min(MAX_CHAT_WIDTH, Math.max(MIN_CHAT_WIDTH, width)));
  document.documentElement.style.setProperty("--chat-width", `${clamped}px`);
}

function setupResizer(): void {
  const stored = Number(readStoredValue(CHAT_WIDTH_KEY));
  if (stored) applyChatWidth(stored);
  const resizer = byId("pane-resizer");
  resizer.addEventListener("pointerdown", (downEvent) => {
    resizer.setPointerCapture(downEvent.pointerId);
    const onMove = (moveEvent: PointerEvent) => applyChatWidth(window.innerWidth - moveEvent.clientX);
    const onUp = (upEvent: PointerEvent) => {
      resizer.releasePointerCapture(upEvent.pointerId);
      resizer.removeEventListener("pointermove", onMove);
      resizer.removeEventListener("pointerup", onUp);
      const width = Number.parseInt(getComputedStyle(document.documentElement).getPropertyValue("--chat-width"), 10);
      if (width) writeStoredValue(CHAT_WIDTH_KEY, String(width));
    };
    resizer.addEventListener("pointermove", onMove);
    resizer.addEventListener("pointerup", onUp);
  });
}

setupResizer();
socket.connect();
