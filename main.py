import os
import sys
from dotenv import load_dotenv
from core.orchestrator import AgentOrchestrator


def main():
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")

    # Load environment variables from .env file
    load_dotenv()

    # The user must set their NVIDIA API key before running.
    if not os.environ.get("NVIDIA_NIM_API_KEY"):
        print(
            "WARNING: NVIDIA_NIM_API_KEY not found in environment. Please add it to your .env file."
        )

    # Premium Startup Sequence
    os.system("cls" if os.name == "nt" else "clear")
    print("\033[1;36m" + "╔" + "═" * 50 + "╗" + "\033[0m")
    print(
        "\033[1;36m"
        + "║"
        + " " * 13
        + "🛡️  SAFECODE AGENT FRAMEWORK"
        + " " * 13
        + "║"
        + "\033[0m"
    )
    print(
        "\033[1;36m"
        + "║"
        + " " * 9
        + "Defense-in-Depth AI Code Orchestrator"
        + " " * 8
        + "║"
        + "\033[0m"
    )
    print("\033[1;36m" + "╚" + "═" * 50 + "╝" + "\033[0m")
    print("\033[2m" + "Initializing Secure Pipeline Components..." + "\033[0m")
    import time

    time.sleep(1)

    # Initialize Orchestrator
    orchestrator = AgentOrchestrator()
    time.sleep(0.5)
    print("\033[32m" + "✔ System Ready. Zero-Trust Monitoring Active." + "\033[0m")
    print("\033[90m" + "Type 'exit' to quit." + "\033[0m")

    while True:
        print("\n\033[1;34m" + "┌──(User)─[Task Request]" + "\033[0m")
        user_task = input("\033[1;34m" + "└─> " + "\033[0m").strip()

        if user_task.lower() in ["exit", "quit", "q"]:
            print("\033[1;33m" + "Session terminated." + "\033[0m")
            break

        if not user_task:
            continue

        orchestrator.run_pipeline(user_task)


if __name__ == "__main__":
    main()
