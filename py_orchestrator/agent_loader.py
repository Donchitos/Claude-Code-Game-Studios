import os
import yaml

class AgentDefinition:
    def __init__(self, name, description, tools, model, max_turns, skills, instructions):
        self.name = name
        self.description = description
        self.tools = tools
        self.model = model
        self.max_turns = max_turns
        self.skills = skills
        self.instructions = instructions

def load_agent(agent_name, agents_dir=".claude/agents"):
    file_path = os.path.join(agents_dir, f"{agent_name}.md")
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"Agent file not found: {file_path}")

    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Parse YAML frontmatter
    if content.startswith('---'):
        parts = content.split('---', 2)
        if len(parts) >= 3:
            frontmatter_str = parts[1]
            instructions = parts[2].strip()

            try:
                frontmatter = yaml.safe_load(frontmatter_str)
            except yaml.YAMLError as e:
                raise ValueError(f"Error parsing YAML frontmatter in {file_path}: {e}")

            # Parse tools (handle both string and list format)
            tools_val = frontmatter.get('tools', [])
            if isinstance(tools_val, str):
                tools_list = [t.strip() for t in tools_val.split(',') if t.strip()]
            elif isinstance(tools_val, list):
                tools_list = [str(t).strip() for t in tools_val]
            else:
                tools_list = []

            return AgentDefinition(
                name=frontmatter.get('name', agent_name),
                description=frontmatter.get('description', ''),
                tools=tools_list,
                model=frontmatter.get('model', 'sonnet'),
                max_turns=frontmatter.get('maxTurns', 10),
                skills=frontmatter.get('skills', []),
                instructions=instructions
            )

    raise ValueError(f"Invalid agent file format in {file_path}")
