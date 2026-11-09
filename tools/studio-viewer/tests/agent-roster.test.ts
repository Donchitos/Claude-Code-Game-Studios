import { describe, expect, it } from "vitest";
import { buildRoster, parseAgentDefinition, parseRosterTiers } from "../server/agent-roster.ts";
import { STUDIO_CONFIG } from "./fixtures.ts";

const AGENT_FILE = [
  "---",
  "name: producer",
  'description: "Production concerns — sprint planning, milestone tracking."',
  "tools: Read, Glob",
  "model: opus",
  "---",
  "",
  "You are the Producer.",
].join("\r\n");

const ROSTER_DOCUMENT = [
  "# Agent Roster",
  "## Tier 1 -- Leadership Agents",
  "| Agent | Domain | When to Use |",
  "|-------|--------|-------------|",
  "| `producer` | Production | Sprints |",
  "## Tier 2 -- Department Lead Agents",
  "| `qa-lead` | QA | Tests |",
  "## Tier 3 -- Specialist Agents",
  "| `qa-tester` | QA | Cases |",
  "## Engine-Specific Agents",
  "### Engine Leads",
  "| `godot-specialist` | Godot 4 | Patterns |",
  "### Godot Sub-Specialists",
  "| `godot-shader-specialist` | Shaders | Materials |",
].join("\n");

describe("parseAgentDefinition", () => {
  it("reads name, unquoted description and model from frontmatter", () => {
    expect(parseAgentDefinition(AGENT_FILE, "fallback")).toEqual({
      name: "producer",
      description: "Production concerns — sprint planning, milestone tracking.",
      model: "opus",
    });
  });

  it("falls back to the file name and inherit when frontmatter is missing", () => {
    expect(parseAgentDefinition("No frontmatter here", "writer")).toEqual({ name: "writer", description: "", model: "inherit" });
  });
});

describe("parseRosterTiers", () => {
  it("maps each table row to the tier of its heading", () => {
    const tiers = parseRosterTiers(ROSTER_DOCUMENT);
    expect(Object.fromEntries(tiers)).toEqual({
      producer: "director",
      "qa-lead": "lead",
      "qa-tester": "specialist",
      "godot-specialist": "engine-lead",
      "godot-shader-specialist": "engine-specialist",
    });
  });
});

describe("buildRoster", () => {
  it("assigns departments from config and treats unknown agents as contractors", () => {
    const roster = buildRoster(
      [
        { name: "qa-tester", description: "", model: "inherit" },
        { name: "brand-new-agent", description: "", model: "inherit" },
      ],
      parseRosterTiers(ROSTER_DOCUMENT),
      STUDIO_CONFIG,
    );
    expect(roster.map(({ name, department, tier }) => ({ name, department, tier }))).toEqual([
      { name: "brand-new-agent", department: "guests", tier: "guest" },
      { name: "qa-tester", department: "quality", tier: "specialist" },
    ]);
  });
});
