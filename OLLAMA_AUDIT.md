# Ollama Migration Audit: Claude Code Game Studios

## Executive Summary
The goal is to migrate "Claude Code Game Studios" from depending on Anthropic's proprietary `claude-code` CLI to a local LLM stack using Ollama. After reviewing the repository's architecture, **this endeavor is highly feasible but requires building a custom orchestrator.**

The `claude-code` CLI natively handles complex behaviors like slash commands, git hook-like lifecycle events, specific tools (`Bash`, `Task`, `Write`), and context compression. Because open-source tools like Aider lack native support for the specific subagent delegation pattern (`Task` tool) and directory structures expected by this repo, we must build a custom Python-based orchestrator.

## Hardware & Model Strategy
The target hardware consists of dual Tesla V100 GPUs (16GB + 32GB = 48GB VRAM total). This is a strong setup for local inference.

The existing architecture categorizes agents by Anthropic models:
- **Directors (Opus)**
- **Leads (Sonnet)**
- **Specialists (Haiku)**

**Recommended Local Model Mapping:**
Given 48GB VRAM, we can comfortably run a high-quality 32B parameter model alongside a smaller 8B model.
- **Opus/Sonnet Tier:** `qwen2.5-coder:32b` or `deepseek-coder-v2-lite`. These models excel at coding, tool use, and complex reasoning, fitting comfortably within ~20-25GB VRAM (quantized), leaving room for context.
- **Haiku Tier:** `llama3.1:8b` or `qwen2.5-coder:7b`. These will handle fast, specialized tasks and consume ~5-6GB VRAM.

## Feature Parity Analysis

### 1. Agents (`.claude/agents/*.md`)
**Status:** Easy to migrate.
The agents are defined in Markdown files with YAML frontmatter specifying `name`, `description`, `tools`, `model`, `maxTurns`, and `skills`. Our Python orchestrator will easily parse this frontmatter to configure system prompts and available tools dynamically.

### 2. Tools (`Read`, `Write`, `Bash`, `Task`, etc.)
**Status:** Requires custom implementation.
- `Read`, `Write`, `Edit`, `Glob`, `Grep`, `Bash`: Standard ReAct/tool-calling implementations. We will build Python functions that interface with the local filesystem and `subprocess` to provide these.
- `Task`: This is the most complex. It requires spawning a *new* agent instance in a sub-loop, passing it a task, and returning its output to the parent agent. This recursive orchestration will be a core feature of the custom orchestrator.

### 3. Skills (`.claude/skills/*`)
**Status:** Moderate effort.
Currently invoked via slash commands (e.g., `/start`, `/brainstorm`). The orchestrator will need a command parser that reads the `SKILL.md` from the respective directory, injects it into the prompt or handles the predefined workflow, and executes the sequence.

### 4. Hooks (`.claude/settings.json`)
**Status:** Straightforward implementation.
The hooks define Bash scripts to run on events like `SessionStart`, `PreToolUse`, `PostToolUse`, etc. Our orchestrator's event loop will need to explicitly check `settings.json` and execute these bash scripts via `subprocess` at the appropriate times.

## Custom Python Orchestrator Architecture

The orchestrator will be built in Python to leverage mature AI/LLM tooling (like `litellm` or the official `ollama` python client) and ease of system scripting.

**Core Components:**
1. **Model Router:** Connects to the local Ollama API, translating `model: opus` in the frontmatter to the local 32B model, etc.
2. **Agent Loader:** Parses `.claude/agents/` and initializes stateful agent objects.
3. **Tool Registry:** Maps string names (e.g., `"Bash"`) to Python functions that execute the tool and return the string output. Supports Ollama's native tool calling format.
4. **Task/Subagent Manager:** A state machine that handles depth-first execution of subagents when the `Task` tool is called.
5. **Event Loop / Hook Engine:** Manages user input, slash commands, and fires shell scripts based on `settings.json` triggers.

## Iterative Implementation Plan

To ensure success, we will build the orchestrator iteratively:

- **Phase 1: MVP Orchestrator**
  - Python project setup.
  - Ollama API connection & chat loop.
  - Agent parsing (YAML + Markdown).
  - Basic tool implementations (`Read`, `Write`, `Bash`).
- **Phase 2: Advanced Tools & Subagents**
  - Implement `Glob`, `Grep`.
  - Implement the `Task` tool to allow agents to spawn other agents.
- **Phase 3: Lifecycle Hooks & Skills**
  - Read `settings.json` and implement `PreToolUse`, `PostToolUse`, `SessionStart` hooks.
  - Implement slash command parsing for `/skills`.
