import json
import ollama
from py_orchestrator.agent_loader import load_agent
from py_orchestrator.tools import TOOL_REGISTRY

MODEL_MAP = {
    "opus": "qwen2.5-coder:32b",   # Mapped to a strong 32B model
    "sonnet": "qwen2.5-coder:32b", # Mapped to a strong 32B model
    "haiku": "llama3.1:8b"         # Mapped to an 8B model
}

class Orchestrator:
    def __init__(self, agent_name="producer", depth=0, max_depth=3):
        self.agent = load_agent(agent_name)
        self.local_model = MODEL_MAP.get(self.agent.model, "qwen2.5-coder:32b")
        self.depth = depth
        self.max_depth = max_depth

        # Build the available tools dynamically for this instance
        self.available_tools = []
        self.tool_functions = {}

        for t_name in self.agent.tools:
            if t_name in TOOL_REGISTRY:
                self.available_tools.append(TOOL_REGISTRY[t_name]["schema"])
                self.tool_functions[t_name] = TOOL_REGISTRY[t_name]["function"]

        # Inject the "Task" tool if the agent has it in its tools list
        if "Task" in self.agent.tools:
            self.available_tools.append({
                "type": "function",
                "function": {
                    "name": "Task",
                    "description": "Spawn a subagent to perform a specific task and return the result.",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "agent_name": {"type": "string", "description": "The name of the agent to spawn (e.g. 'game-designer')."},
                            "instructions": {"type": "string", "description": "The explicit instructions or task for the subagent to complete."}
                        },
                        "required": ["agent_name", "instructions"]
                    }
                }
            })
            self.tool_functions["Task"] = self.execute_task_tool

        self.messages = [
            {"role": "system", "content": f"You are {self.agent.name}. {self.agent.description}\n\n{self.agent.instructions}"}
        ]

    def execute_task_tool(self, agent_name: str, instructions: str) -> str:
        """Spawns a subagent to execute a task."""
        if self.depth >= self.max_depth:
            return "Task failed: Maximum subagent depth exceeded to prevent infinite loops."

        print(f"\n[{self.agent.name}] Spawning subagent: {agent_name}...")
        try:
            subagent = Orchestrator(agent_name=agent_name, depth=self.depth + 1, max_depth=self.max_depth)
            result = subagent.chat(f"Parent Agent ({self.agent.name}) has delegated a task to you. Execute this task, use tools if necessary, and provide a final summary of your findings or actions.\n\nTask: {instructions}")
            print(f"[{self.agent.name}] Subagent {agent_name} completed task.")
            return f"Subagent {agent_name} completed the task. Result:\n{result}"
        except Exception as e:
            print(f"[{self.agent.name}] Subagent {agent_name} failed: {e}")
            return f"Failed to execute task via subagent {agent_name}. Error: {e}"

    def chat(self, user_input: str):
        self.messages.append({"role": "user", "content": user_input})

        while True:
            response = ollama.chat(
                model=self.local_model,
                messages=self.messages,
                tools=self.available_tools if self.available_tools else None
            )

            message = response['message']
            self.messages.append(message)

            if not message.get('tool_calls'):
                return message.get('content')

            # Handle tool calls
            for tool_call in message['tool_calls']:
                tool_name = tool_call['function']['name']
                tool_args = tool_call['function']['arguments']

                # Print indicator for tool use, indent based on depth
                indent = "  " * self.depth
                print(f"{indent}[{self.agent.name} executing {tool_name} with args {tool_args}]")

                if tool_name in self.tool_functions:
                    func = self.tool_functions[tool_name]
                    try:
                        result = func(**tool_args)
                    except Exception as e:
                        result = str(e)
                else:
                    result = f"Tool {tool_name} not found."

                self.messages.append({
                    "role": "tool",
                    "content": str(result),
                    "name": tool_name
                })
