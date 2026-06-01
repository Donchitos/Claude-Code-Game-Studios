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
    def __init__(self, agent_name="producer"):
        self.agent = load_agent(agent_name)
        self.local_model = MODEL_MAP.get(self.agent.model, "qwen2.5-coder:32b")

        # Load available tools based on the agent's definition
        self.available_tools = []
        for t_name in self.agent.tools:
            if t_name in TOOL_REGISTRY:
                self.available_tools.append(TOOL_REGISTRY[t_name]["schema"])

        self.messages = [
            {"role": "system", "content": f"You are {self.agent.name}. {self.agent.description}\n\n{self.agent.instructions}"}
        ]

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

                print(f"[{self.agent.name} executing {tool_name} with args {tool_args}]")

                if tool_name in TOOL_REGISTRY:
                    func = TOOL_REGISTRY[tool_name]['function']
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
