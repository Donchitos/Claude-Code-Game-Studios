import sys
import argparse
from py_orchestrator.orchestrator import Orchestrator

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
    while True:
        try:
            user_input = input("\nYou: ")
            if user_input.lower() in ['exit', 'quit']:
                break

            if not user_input.strip():
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
