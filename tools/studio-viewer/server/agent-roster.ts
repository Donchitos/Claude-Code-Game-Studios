import { readdir, readFile } from "node:fs/promises";
import path from "node:path";
import { GUEST_DEPARTMENT, type AgentTier, type RosterAgent, type StudioConfig } from "../shared/protocol.ts";

export interface AgentDefinition {
  name: string;
  description: string;
  model: string;
}

const TIER_HEADINGS: ReadonlyArray<readonly [RegExp, AgentTier]> = [
  [/tier 1/i, "director"],
  [/tier 2/i, "lead"],
  [/tier 3/i, "specialist"],
  [/engine leads/i, "engine-lead"],
  [/sub-specialists/i, "engine-specialist"],
];

function unquote(value: string): string {
  const quoted = /^"(.*)"$/.exec(value) ?? /^'(.*)'$/.exec(value);
  return quoted ? quoted[1]! : value;
}

export function parseAgentDefinition(markdown: string, fallbackName: string): AgentDefinition {
  const frontmatter = /^---\r?\n([\s\S]*?)\r?\n---/.exec(markdown);
  const fields = new Map<string, string>();
  for (const line of frontmatter?.[1]?.split(/\r?\n/) ?? []) {
    const match = /^([A-Za-z][\w-]*):\s*(.*)$/.exec(line);
    if (match) fields.set(match[1]!, unquote(match[2]!.trim()));
  }
  return {
    name: fields.get("name") || fallbackName,
    description: fields.get("description") ?? "",
    model: fields.get("model") || "inherit",
  };
}

export function parseRosterTiers(markdown: string): Map<string, AgentTier> {
  const tiers = new Map<string, AgentTier>();
  let currentTier: AgentTier | null = null;
  for (const line of markdown.split(/\r?\n/)) {
    const heading = /^#{2,4}\s+(.*)$/.exec(line);
    if (heading) {
      currentTier = TIER_HEADINGS.find(([pattern]) => pattern.test(heading[1]!))?.[1] ?? null;
      continue;
    }
    const row = /^\|\s*`([\w-]+)`\s*\|/.exec(line);
    if (row && currentTier && !tiers.has(row[1]!)) tiers.set(row[1]!, currentTier);
  }
  return tiers;
}

export function buildRoster(
  definitions: AgentDefinition[],
  tiers: Map<string, AgentTier>,
  config: StudioConfig,
): RosterAgent[] {
  const departmentByAgent = new Map<string, string>();
  for (const department of config.departments) {
    for (const agentName of department.agents) departmentByAgent.set(agentName, department.id);
  }
  return definitions
    .map((definition) => {
      const department = departmentByAgent.get(definition.name) ?? GUEST_DEPARTMENT;
      const fallbackTier: AgentTier = department === GUEST_DEPARTMENT ? "guest" : "specialist";
      return { ...definition, department, tier: tiers.get(definition.name) ?? fallbackTier };
    })
    .sort((first, second) => first.name.localeCompare(second.name));
}

export async function loadRoster(projectRoot: string, config: StudioConfig): Promise<RosterAgent[]> {
  const agentsDirectory = path.join(projectRoot, ".claude", "agents");
  const fileNames = (await readdir(agentsDirectory)).filter((fileName) => fileName.endsWith(".md"));
  const definitions = await Promise.all(
    fileNames.map(async (fileName) =>
      parseAgentDefinition(await readFile(path.join(agentsDirectory, fileName), "utf8"), path.basename(fileName, ".md")),
    ),
  );
  const rosterDocument = await readFile(path.join(projectRoot, ".claude", "docs", "agent-roster.md"), "utf8").catch(
    () => "",
  );
  return buildRoster(definitions, parseRosterTiers(rosterDocument), config);
}
