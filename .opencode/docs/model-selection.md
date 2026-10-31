# Model Selection for OpenCode

The studio is deliberately model-agnostic. The generated agents and commands do
not contain `model:` pins: every one inherits the model selected in the OpenCode
session. This is what makes the template usable with local open-weight models.

## What the model must be able to do

The editing workflows are tool-driven. A model that cannot call tools reliably
can still help with read-only planning, but it cannot run `/dev-story`,
`/create-architecture`, or the `team-*` workflows end to end.

| Capability | Requirement |
|---|---|
| Tool calling | **Required** for any workflow that reads or writes files |
| Instruction following | **Required**; the studio uses long, numbered procedures |
| Context window | 64k tokens recommended; 32k practical minimum |
| Structured output | Helpful; the `question` tool and phase verdicts use it |
| Reasoning / thinking | Optional; not assumed by any skill |

## Pick a model in OpenCode

Use `/models` in the TUI, or set the default in `opencode.jsonc`:

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "model": "ollama/qwen3-coder:30b"
}
```

The root `model` is the default for new work. A session that already selected a
model keeps it.

## Local providers

### Ollama

```jsonc
{
  "model": "ollama/qwen3-coder:30b",
  "providers": {
    "ollama": {
      "settings": {
        "baseURL": "http://127.0.0.1:11434/v1"
      }
    }
  }
}
```

Ollama models are discovered automatically. Omit `apiKey` when the endpoint does
not require one.

### LM Studio

```jsonc
{
  "model": "lmstudio/qwen/qwen3-coder-30b",
  "providers": {
    "lmstudio": {
      "settings": {
        "baseURL": "http://127.0.0.1:1234/v1"
      }
    }
  }
}
```

### vLLM

```jsonc
{
  "model": "vllm/Qwen/Qwen3-Coder-30B-A3B-Instruct",
  "providers": {
    "vllm": {
      "settings": {
        "baseURL": "http://127.0.0.1:8000/v1",
        "apiKey": "{env:VLLM_API_KEY}"
      }
    }
  }
}
```

vLLM needs server-side tool-call flags, such as `--enable-auto-tool-choice` and
`--tool-call-parser`, before it advertises tool support to OpenCode.

### Another OpenAI-compatible server

```jsonc
{
  "model": "local/coder",
  "providers": {
    "local": {
      "name": "Local server",
      "package": "@opencode/ai/providers/openai-compatible",
      "settings": {
        "baseURL": "http://127.0.0.1:8080/v1"
      },
      "models": {
        "coder": {
          "modelID": "model-name-on-server",
          "capabilities": {
            "tools": true,
            "input": ["text"],
            "output": ["text"]
          },
          "limit": {
            "context": 65536,
            "output": 16384
          }
        }
      }
    }
  }
}
```

Custom model capabilities are not detected. Set `tools: true` only when the
server really handles tool calls.

## Hosted open-weight models

OpenRouter and similar providers can serve open-weight models:

```jsonc
{
  "model": "openrouter/qwen/qwen3-coder"
}
```

The exact model ID must match the provider catalog. Use `/models` to find it
rather than guessing.

## Assigning models by role

The default is one model for the whole studio. To vary it:

```jsonc
{
  "agents": {
    "creative-director": { "model": "openrouter/qwen/qwen3-235b-a22b" },
    "help": { "model": "ollama/qwen3:8b" }
  }
}
```

Or put `model: provider/model` in a single agent file. Commands can also carry a
`model` override. Keep overrides few: every additional model is another tool-
calling profile to validate.

## Context tips for smaller models

- Run `/start` and one workflow at a time; the studio is designed for incremental
  state files, not one giant prompt.
- Disable engine specialists that do not match the project. See
  `.opencode/docs/opencode-setup.md`.
- Skills that are not relevant can set `metadata.opencode/autoinvoke: false`; the
  five internal skills already do this.
- Lower retained tool output in `opencode.jsonc` if a model drowns in results:

  ```jsonc
  {
    "tool_output": { "max_lines": 800, "max_bytes": 24000 }
  }
  ```

- The large skills read reference files on demand. Do not read a whole GDD or
  `effects-map.md`; use `grep` and ranged `read`.

## No model pins in generated files

If you see `model: sonnet`, `model: opus`, or `model: haiku` in `.opencode/`,
something is stale. Run:

```bash
python3 tools/sync-opencode.py
python3 tools/validate-opencode.py
```
