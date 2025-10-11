from chutes_lam import ChutesLAM
from tools import TOOLS_SCHEMA, AVAILABLE_TOOLS

def main():
    print("Welcome to the Chutes LAM Proof of Concept!")
    print("This LAM supports multi-turn conversations and tool calling.")
    print("Try asking: 'What is the glucose level for patient123?'")
    print("Type 'exit' to end the conversation.")

    lam = ChutesLAM(tools_schema=TOOLS_SCHEMA, available_tools=AVAILABLE_TOOLS)

    while True:
        user_input = input("\nYou: ")
        if user_input.lower() == 'exit':
            break
        
        response = lam.chat(user_input)
        print(f"AI: {response}")

if __name__ == "__main__":
    main()
