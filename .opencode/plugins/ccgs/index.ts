/**
 * CCGS OpenCode adapter.
 *
 * Reuses the canonical Claude Code hook scripts in `.claude/hooks/` so the two
 * harnesses share one validation implementation. OpenCode emits different event
 * names and payloads; this file translates them into the JSON each script
 * already understands.
 *
 * The plugin deliberately imports nothing from `@opencode/plugin`. A plain
 * object with `id` and `setup` is enough for the V2 runtime, which keeps the
 * template working after a clone without a package install step.
 */

import { spawn } from "node:child_process"
import { appendFileSync, existsSync, readFileSync, readdirSync } from "node:fs"
import { basename, join, relative } from "node:path"

const DEBUG = process.env.CCGS_DEBUG === "1"
function debug(message: string): void {
  if (!DEBUG) return
  try {
    appendFileSync("/tmp/ccgs-debug.log", `${new Date().toISOString()} ${message}\n`)
  } catch {}
}

type HookResult = { code: number; stdout: string; stderr: string }

type Rule = {
  name: string
  patterns: string[]
  body: string
  matchers: RegExp[]
}

const HOOK_TIMEOUT_MS = 15_000

function runHook(
  root: string,
  script: string,
  payload: Record<string, unknown>,
  timeout = HOOK_TIMEOUT_MS,
): Promise<HookResult> {
  const path = join(root, ".claude", "hooks", script)
  if (!existsSync(path)) {
    return Promise.resolve({ code: 0, stdout: "", stderr: "" })
  }

  return new Promise((resolvePromise) => {
    const child = spawn("bash", [path], {
      cwd: root,
      env: {
        ...process.env,
        CLAUDE_PROJECT_DIR: root,
        CLAUDE_SESSION_ID: String(payload.session_id ?? ""),
      },
      stdio: ["pipe", "pipe", "pipe"],
    })

    let stdout = ""
    let stderr = ""
    let settled = false
    let timer: ReturnType<typeof setTimeout> | undefined
    const finish = (result: HookResult) => {
      if (settled) return
      settled = true
      if (timer) clearTimeout(timer)
      resolvePromise(result)
    }
    timer = setTimeout(() => {
      try {
        child.kill("SIGKILL")
      } catch {}
      finish({ code: 124, stdout, stderr: stderr + "\n[ccgs] hook timed out" })
    }, timeout)

    child.stdout.on("data", (chunk) => {
      stdout += chunk.toString()
    })
    child.stderr.on("data", (chunk) => {
      stderr += chunk.toString()
    })
    child.on("error", (error) => {
      finish({ code: 1, stdout, stderr: stderr + String(error) })
    })
    child.on("close", (code) => {
      finish({ code: code ?? 0, stdout, stderr })
    })

    try {
      child.stdin.end(JSON.stringify(payload))
    } catch {
      finish({ code: 1, stdout, stderr: stderr + "\n[ccgs] could not write hook payload" })
    }
  })
}

/** Claude hooks sometimes return JSON (`systemMessage`, additionalContext). */
function hookMessage(result: HookResult): string {
  const stdout = result.stdout.trim()
  if (stdout) {
    try {
      const parsed = JSON.parse(stdout) as {
        systemMessage?: unknown
        hookSpecificOutput?: { additionalContext?: unknown }
      }
      const parts: string[] = []
      if (typeof parsed.systemMessage === "string") parts.push(parsed.systemMessage)
      const context = parsed.hookSpecificOutput?.additionalContext
      if (typeof context === "string") parts.push(context)
      if (parts.length > 0) return parts.join("\n\n").trim()
    } catch {
      // Plain text is the other supported shape.
    }
    return stdout
  }
  return result.stderr.trim()
}

function blockMessage(result: HookResult): string {
  return (result.stderr.trim() || hookMessage(result) || "Blocked by a CCGS validation hook.").trim()
}

function normalizePath(root: string, value: unknown): string | undefined {
  if (typeof value !== "string" || !value.trim()) return undefined
  const absolute = value.startsWith("/") || /^[A-Za-z]:[\\/]/.test(value)
  const path = absolute ? relative(root, value) : value
  return path.replace(/\\/g, "/").replace(/^\.\//, "")
}

function patchPaths(patchText: unknown): string[] {
  if (typeof patchText !== "string") return []
  const paths: string[] = []
  const re = /^\*\*\* (?:Add|Update|Delete) File: (.+)$/gm
  let match: RegExpExecArray | null
  while ((match = re.exec(patchText)) !== null) {
    paths.push(match[1].trim())
  }
  return paths
}

function pathsForTool(tool: string, input: Record<string, unknown>): string[] {
  if (tool === "read" || tool === "write" || tool === "edit") {
    const path = input.path ?? input.filePath ?? input.file_path
    return typeof path === "string" ? [path] : []
  }
  if (tool === "patch") return patchPaths(input.patchText ?? input.patch)
  return []
}

function expandBraces(pattern: string): string[] {
  const match = pattern.match(/\{([^{}]+)\}/)
  if (!match || match.index === undefined) return [pattern]
  const before = pattern.slice(0, match.index)
  const after = pattern.slice(match.index + match[0].length)
  return match[1]
    .split(",")
    .flatMap((part) => expandBraces(before + part + after))
}

function globToRegex(pattern: string): RegExp {
  let source = ""
  for (let index = 0; index < pattern.length; index += 1) {
    const char = pattern[index]
    if (char === "*") {
      if (pattern[index + 1] === "*") {
        index += 1
        if (pattern[index + 1] === "/") {
          index += 1
          source += "(?:[^/]+/)*"
        } else {
          source += ".*"
        }
      } else {
        source += "[^/]*"
      }
    } else if (char === "?") {
      source += "[^/]"
    } else if ("\\^$+?.()|[]{}".includes(char)) {
      source += "\\" + char
    } else {
      source += char
    }
  }
  return new RegExp("^" + source + "$")
}

function loadRules(root: string): Rule[] {
  const directory = join(root, ".claude", "rules")
  if (!existsSync(directory)) return []

  return readdirSync(directory)
    .filter((name) => name.endsWith(".md"))
    .map((name) => {
      const text = readFileSync(join(directory, name), "utf8")
      const match = text.match(/^---\n([\s\S]*?)\n---\n?/)
      if (!match) return undefined
      const meta = match[1]
      const body = text.slice(match[0].length).trim()
      const patterns: string[] = []
      let inPaths = false
      for (const line of meta.split("\n")) {
        if (/^paths:/.test(line)) {
          inPaths = true
          continue
        }
        if (!inPaths) continue
        const item = line.match(/^\s*-\s*["']?(.+?)["']?\s*$/)
        if (item) {
          patterns.push(item[1].trim())
        } else if (line.trim() && !line.startsWith(" ")) {
          break
        }
      }
      if (patterns.length === 0) return undefined
      return {
        name: basename(name, ".md"),
        patterns,
        body,
        matchers: patterns.flatMap(expandBraces).map(globToRegex),
      }
    })
    .filter((rule): rule is Rule => Boolean(rule))
}

async function setInstruction(
  ctx: Record<string, any>,
  sessionID: string,
  key: string,
  text: string,
): Promise<void> {
  if (!text.trim()) return
  try {
    await ctx.session.instructions.entry.put({ sessionID, key, value: text })
  } catch (error) {
    // Instruction entries are the non-interrupting channel. Never fall back to
    // a synthetic message here: that would start another model turn.
    console.error("[ccgs] could not write instruction entry", key, error)
  }
}

async function synthetic(ctx: Record<string, any>, sessionID: string, text: string): Promise<void> {
  if (!text.trim()) return
  try {
    await ctx.session.synthetic({ sessionID, text })
  } catch {
    // Non-blocking advisory; never break a tool call over it.
  }
}

export default {
  id: "ccgs",

  async setup(ctx: Record<string, any>) {
    const root: string =
      ctx.location?.project?.canonical ?? ctx.location?.directory ?? process.cwd()
    debug(`setup root=${root}`)
    const rules = loadRules(root)
    const injectedRules = new Map<string, Set<string>>()
    const lastStop = new Map<string, number>()
    const startedSessions = new Set<string>()
    const cachedContext = new Map<string, string>()
    const primarySessions = new Map<string, boolean>()
    const contextLoads = new Map<string, Promise<string>>()

    const payloadBase = (sessionID: string, agent?: string) => ({
      session_id: sessionID,
      cwd: root,
      ...(agent ? { agent_type: agent } : {}),
    })

    const isPrimarySession = async (sessionID: string): Promise<boolean> => {
      const cached = primarySessions.get(sessionID)
      if (cached !== undefined) return cached
      try {
        const info = await ctx.session.get({ sessionID })
        const primary = !(info as Record<string, any>)?.parentID
        primarySessions.set(sessionID, primary)
        return primary
      } catch {
        // If the session cannot be read, assume primary. The alternative is a
        // silent no-op for every session, which is worse than duplicate context.
        return true
      }
    }

    const loadSessionContext = async (sessionID: string, source: string): Promise<string> => {
      const pending = contextLoads.get(sessionID)
      if (pending) return pending
      const load = (async () => {
        const payload = {
          session_id: sessionID,
          cwd: root,
          hook_event_name: "SessionStart",
          source,
        }
        const [start, gaps] = await Promise.all([
          runHook(root, "session-start.sh", payload),
          runHook(root, "detect-gaps.sh", payload),
        ])
        const text = [hookMessage(start), hookMessage(gaps)]
          .filter((part) => part.trim().length > 0)
          .join("\n\n")
        cachedContext.set(sessionID, text)
        return text
      })()
      contextLoads.set(sessionID, load)
      try {
        return await load
      } finally {
        contextLoads.delete(sessionID)
      }
    }

    const wrapContext = (text: string): string =>
      `<studio-session-context>\n${text.trim()}\n</studio-session-context>`

    try {
      await ctx.session.hook("prompt", async (event: Record<string, any>) => {
        const sessionID = String(event.sessionID ?? "")
        if (!sessionID || startedSessions.has(sessionID)) return
        startedSessions.add(sessionID)
        if (!(await isPrimarySession(sessionID))) return
        // Warm the cache before the first model dispatch. The context hook below
        // is what actually adds the block to the system prompt.
        await loadSessionContext(sessionID, "startup")
      })
    } catch (error) {
      console.error("[ccgs] prompt hook unavailable", error)
    }

    try {
      await ctx.session.hook("context", async (event: Record<string, any>) => {
        const sessionID = String(event.sessionID ?? "")
        if (!sessionID || !(await isPrimarySession(sessionID))) return
        const system = Array.isArray(event.system) ? event.system : []
        const already = system.some(
          (part: Record<string, any>) =>
            typeof part?.text === "string" && part.text.includes("<studio-session-context>"),
        )
        if (already) return
        const context = cachedContext.get(sessionID) ?? (await loadSessionContext(sessionID, "resume"))
        if (!context.trim()) return
        system.push({ type: "text", text: wrapContext(context) })
        event.system = system
      })
    } catch (error) {
      console.error("[ccgs] context hook unavailable", error)
    }

    const injectRules = async (sessionID: string, paths: string[]) => {
      if (paths.length === 0) return
      let loaded = injectedRules.get(sessionID)
      if (!loaded) {
        loaded = new Set()
        injectedRules.set(sessionID, loaded)
      }
      for (const rawPath of paths) {
        const path = normalizePath(root, rawPath)
        if (!path) continue
        for (const rule of rules) {
          if (!rule.matchers.some((matcher) => matcher.test(path))) continue
          if (loaded.has(rule.name)) continue
          loaded.add(rule.name)
          await setInstruction(
            ctx,
            sessionID,
            `ccgs/rule/${rule.name}`,
            `# Project Rule: ${rule.name}\n\n${rule.body}`,
          )
        }
      }
    }

    await ctx.tool.hook("execute.before", async (event: Record<string, any>) => {
      const tool = String(event.tool ?? "")
      const input = (event.input ?? {}) as Record<string, unknown>
      const sessionID = String(event.sessionID)
      const base = payloadBase(sessionID, event.agent)
      const paths = pathsForTool(tool, input)
      await injectRules(sessionID, paths)

      if (tool === "shell" || tool === "bash") {
        const command = String(input.command ?? input.cmd ?? "")
        if (!command) return
        const payload = {
          ...base,
          hook_event_name: "PreToolUse",
          tool_name: "Bash",
          tool_input: { command },
        }
        const results = await Promise.all([
          runHook(root, "validate-commit.sh", payload),
          runHook(root, "validate-push.sh", payload),
        ])
        for (const result of results) {
          if (result.code === 2) throw new Error(blockMessage(result))
          const message = hookMessage(result)
          if (message) await synthetic(ctx, sessionID, message)
        }
        return
      }

      if (tool === "read") {
        const path = normalizePath(root, input.path ?? input.filePath ?? input.file_path)
        if (!path) return
        const payload = {
          ...base,
          hook_event_name: "PreToolUse",
          tool_name: "Read",
          tool_input: {
            file_path: path,
            ...(input.offset !== undefined ? { offset: input.offset } : {}),
            ...(input.limit !== undefined ? { limit: input.limit } : {}),
          },
        }
        const result = await runHook(root, "validate-read.sh", payload)
        if (result.code === 2) throw new Error(blockMessage(result))
        const message = hookMessage(result)
        if (message) await synthetic(ctx, sessionID, message)
        return
      }

      if (tool === "write" || tool === "edit") {
        const path = normalizePath(root, input.path ?? input.filePath ?? input.file_path)
        if (!path) return
        const toolName = tool === "write" ? "Write" : "Edit"
        const toolInput: Record<string, unknown> = { file_path: path }
        if (tool === "write") {
          toolInput.content = input.content ?? ""
        } else {
          toolInput.old_string = input.oldString ?? input.old_string ?? ""
          toolInput.new_string = input.newString ?? input.new_string ?? ""
          toolInput.replace_all = input.replaceAll ?? input.replace_all ?? false
        }
        const payload = {
          ...base,
          hook_event_name: "PreToolUse",
          tool_name: toolName,
          tool_input: toolInput,
        }
        const results = await Promise.all([
          runHook(root, "validate-write.sh", payload),
          runHook(root, "validate-registry.sh", payload),
        ])
        for (const result of results) {
          if (result.code === 2) throw new Error(blockMessage(result))
          const message = hookMessage(result)
          if (message) await synthetic(ctx, sessionID, message)
        }
        return
      }

      if (tool === "patch") {
        // The patch tool can touch many files. Content-based guards need the
        // post-image of each file, which patch does not expose. Rules still
        // apply; the editor/write path is guarded normally.
        return
      }
    })

    await ctx.tool.hook("execute.after", async (event: Record<string, any>) => {
      if (event.status !== "completed") return
      const tool = String(event.tool ?? "")
      if (tool !== "write" && tool !== "edit") return
      const input = (event.input ?? {}) as Record<string, unknown>
      const path = normalizePath(root, input.path ?? input.filePath ?? input.file_path)
      if (!path) return
      const sessionID = String(event.sessionID)
      const toolName = tool === "write" ? "Write" : "Edit"
      const payload = {
        ...payloadBase(sessionID, event.agent),
        hook_event_name: "PostToolUse",
        tool_name: toolName,
        tool_input: {
          file_path: path,
          ...(tool === "write"
            ? { content: input.content ?? "" }
            : {
                old_string: input.oldString ?? input.old_string ?? "",
                new_string: input.newString ?? input.new_string ?? "",
              }),
        },
      }
      const results = await Promise.all([
        runHook(root, "validate-assets.sh", payload),
        runHook(root, "validate-skill-change.sh", payload),
      ])
      for (const result of results) {
        if (result.code === 2) {
          await synthetic(ctx, sessionID, blockMessage(result))
        } else {
          const message = hookMessage(result)
          if (message) await synthetic(ctx, sessionID, message)
        }
      }
    })

    // Safety net for child sessions where tool hooks may not fire. Permission
    // evaluation runs in the child session's own permission context.
    await ctx.permission.hook("evaluate", async (event: Record<string, any>) => {
      if (event.action !== "shell") return
      const resources = Array.isArray(event.resources)
        ? event.resources.map(String)
        : [String(event.resources ?? "")]
      for (const command of resources) {
        if (!/git\s+(commit|push)\b/i.test(command)) continue
        const payload = {
          session_id: String(event.sessionID ?? ""),
          cwd: root,
          hook_event_name: "PreToolUse",
          tool_name: "Bash",
          tool_input: { command },
        }
        const results = await Promise.all([
          runHook(root, "validate-commit.sh", payload),
          runHook(root, "validate-push.sh", payload),
        ])
        for (const result of results) {
          if (result.code === 2) {
            event.effect = "deny"
            event.message = blockMessage(result)
            return
          }
        }
      }
    })

    const controller = new AbortController()

    void (async () => {
      for await (const event of ctx.event.subscribe({
        signal: controller.signal,
      })) {
        const data = (event as Record<string, any>).data ?? {}
        const sessionID = String(data.sessionID ?? "")
        debug(`event ${event.type} session=${sessionID}`)
        if (!sessionID) continue

        if (event.type === "session.compaction.started") {
          startedSessions.delete(sessionID)
          cachedContext.delete(sessionID)
          void runHook(root, "pre-compact.sh", {
            session_id: sessionID,
            cwd: root,
            hook_event_name: "PreCompact",
            trigger: "auto",
          })
          continue
        }

        if (event.type === "session.compaction.ended") {
          startedSessions.delete(sessionID)
          cachedContext.delete(sessionID)
          if (await isPrimarySession(sessionID)) {
            await loadSessionContext(sessionID, "compact")
          }
          continue
        }

        if (
          event.type === "session.idle" ||
          event.type === "session.execution.succeeded" ||
          event.type === "session.execution.failed" ||
          event.type === "session.execution.interrupted"
        ) {
          if (!(await isPrimarySession(sessionID))) continue
          const now = Date.now()
          if ((lastStop.get(sessionID) ?? 0) + 1500 > now) continue
          lastStop.set(sessionID, now)
          void runHook(root, "session-stop.sh", {
            session_id: sessionID,
            cwd: root,
            hook_event_name: "Stop",
          })
          continue
        }

        if (event.type === "session.deleted") {
          injectedRules.delete(sessionID)
          lastStop.delete(sessionID)
          startedSessions.delete(sessionID)
          cachedContext.delete(sessionID)
          primarySessions.delete(sessionID)
        }
      }
    })().catch((error) => {
      console.error("[ccgs] event loop stopped:", error)
    })

    return () => controller.abort()
  },
}
