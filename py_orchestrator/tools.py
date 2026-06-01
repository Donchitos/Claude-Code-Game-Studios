import subprocess
import os
import glob
import re

def tool_bash(command: str) -> str:
    """Executes a bash command and returns the output."""
    try:
        result = subprocess.run(
            command,
            shell=True,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        return result.stdout if result.stdout else "Command executed successfully (no output)."
    except subprocess.CalledProcessError as e:
        return f"Error executing command: {e.stderr}"

def tool_read(filepath: str) -> str:
    """Reads the content of a file."""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            return f.read()
    except Exception as e:
        return f"Error reading file {filepath}: {e}"

def tool_write(filepath: str, content: str) -> str:
    """Writes content to a file, creating directories if needed."""
    try:
        os.makedirs(os.path.dirname(os.path.abspath(filepath)), exist_ok=True)
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        return f"Successfully wrote to {filepath}"
    except Exception as e:
        return f"Error writing to file {filepath}: {e}"

def tool_glob(pattern: str) -> str:
    """Find files matching a glob pattern."""
    try:
        matches = glob.glob(pattern, recursive=True)
        if not matches:
            return "No files found matching pattern."
        return "\n".join(matches)
    except Exception as e:
        return f"Error executing glob: {e}"

def tool_grep(pattern: str, filepath: str) -> str:
    """Search for a regex pattern within a specific file."""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            lines = f.readlines()

        compiled_pattern = re.compile(pattern)
        matches = []
        for i, line in enumerate(lines):
            if compiled_pattern.search(line):
                matches.append(f"{i+1}: {line.strip()}")

        if not matches:
            return "No matches found."
        return "\n".join(matches)
    except Exception as e:
        return f"Error executing grep: {e}"

# Tool registry maps string names to Python functions and JSON schema for Ollama
TOOL_REGISTRY = {
    "Bash": {
        "function": tool_bash,
        "schema": {
            "type": "function",
            "function": {
                "name": "Bash",
                "description": "Execute a bash command.",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "command": {"type": "string", "description": "The bash command to run."}
                    },
                    "required": ["command"]
                }
            }
        }
    },
    "Read": {
        "function": tool_read,
        "schema": {
            "type": "function",
            "function": {
                "name": "Read",
                "description": "Read the contents of a file.",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "filepath": {"type": "string", "description": "The path to the file."}
                    },
                    "required": ["filepath"]
                }
            }
        }
    },
    "Write": {
        "function": tool_write,
        "schema": {
            "type": "function",
            "function": {
                "name": "Write",
                "description": "Write contents to a file.",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "filepath": {"type": "string", "description": "The path to the file to write."},
                        "content": {"type": "string", "description": "The content to write."}
                    },
                    "required": ["filepath", "content"]
                }
            }
        }
    },
    "Glob": {
        "function": tool_glob,
        "schema": {
            "type": "function",
            "function": {
                "name": "Glob",
                "description": "Find files matching a glob pattern.",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "pattern": {"type": "string", "description": "The glob pattern (e.g. src/**/*.py)."}
                    },
                    "required": ["pattern"]
                }
            }
        }
    },
    "Grep": {
        "function": tool_grep,
        "schema": {
            "type": "function",
            "function": {
                "name": "Grep",
                "description": "Search for a regex pattern within a specific file.",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "pattern": {"type": "string", "description": "The regex pattern to search for."},
                        "filepath": {"type": "string", "description": "The file to search in."}
                    },
                    "required": ["pattern", "filepath"]
                }
            }
        }
    }
}
