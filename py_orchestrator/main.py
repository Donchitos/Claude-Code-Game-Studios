import sys
import os
import argparse
from py_orchestrator.orchestrator import Orchestrator

def load_skill(skill_name, skills_dir=".claude/skills"):
    """Loads the content of a skill file."""
    skill_path = os.path.join(skills_dir, skill_name, "SKILL.md")
    if not os.path.exists(skill_path):
        return None

    try:
        with open(skill_path, 'r', encoding='utf-8') as f:
            return f.read()
    except Exception as e:
        print(f"Error reading skill {skill_name}: {e}")
        return None

def main():
    parser = argparse.ArgumentParser(description="Claude Code Game Studios - Ollama Orchestrator")
    parser.add_argument("--agent", type=str, default="producer", help="The name of the agent to load (e.g., producer, creative-director)")
    args = parser.parse_args()

    print("Welcome to the Claude Code Game Studios - Ollama Orchestrator")
    try:
        orchestrator = Orchestrator(agent_name=args.agent)
        print(f"Loaded agent: {orchestrator.agent.name} (Mapped to model: {orchestrator.local_model})")
    except Exception as e:
        print(f"Error initializing orchestrator: {e}")
        return

    print("\nType your message below. Type 'exit' or 'quit' to stop.")
    print("Use '/<skill-name>' to invoke a skill (e.g., /start, /brainstorm).")

    while True:
        try:
            user_input = input("\nYou: ")
            if user_input.lower() in ['exit', 'quit']:
                break

            if not user_input.strip():
                continue

            # Intercept slash commands
            if user_input.startswith('/'):
                command_parts = user_input.strip().split(maxsplit=1)
                skill_name = command_parts[0][1:] # Remove the '/'
                extra_args = command_parts[1] if len(command_parts) > 1 else ""

                skill_content = load_skill(skill_name)

                if skill_content:
                    print(f"\n[System] Invoking skill: {skill_name}...")
                    user_input = (
                        f"The user has invoked the '{skill_name}' skill command"
                        f"{' with arguments: ' + extra_args if extra_args else ''}.\n"
                        f"Please execute the following skill workflow exactly as defined:\n\n"
                        f"{skill_content}"
                    )
                else:
                    print(f"\n[System] Skill '{skill_name}' not found in .claude/skills/ directory.")
                    continue

            print(f"\n{orchestrator.agent.name} is thinking...")
            response = orchestrator.chat(user_input)
            print(f"\n{orchestrator.agent.name}: {response}")

        except KeyboardInterrupt:
            print("\nExiting...")
            break
        except Exception as e:
            print(f"\nError during chat: {e}")

if __name__ == "__main__":
    main()
