import subprocess
import os

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
    }
}
