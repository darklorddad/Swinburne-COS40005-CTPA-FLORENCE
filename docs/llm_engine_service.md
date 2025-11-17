# LLM Engine Service Documentation

## 1. Introduction

The `llm_engine_service` is responsible for providing Large Language Model (LLM) capabilities to the Florence application. It uses the OpenRouter API to access various language models and is built using the LangChain library to manage interactions with the LLM, including tool-calling functionality.

## 2. Architecture

The `llm_engine_service` is a client that connects to the OpenRouter API. It is designed to be used by other services within the Florence module that require natural language processing.

```mermaid
graph TD
    subgraph "Florence Module"
        A[Application Logic]
    end

    subgraph "LLM Engine Service"
        B[OpenRouterLAM]
    end

    subgraph "External Services"
        C[OpenRouter API]
    end

    A --> B;
    B --> C;

    style C fill:#f9f,stroke:#333,stroke-width:2px
```

**Figure 1: LLM Engine Service Architecture**

## 3. Core Components

- **`OpenRouterLAM`**: This is the main class in the `llm_engine_service`. It encapsulates the logic for interacting with the OpenRouter API. It uses `ChatOpenAI` from the `langchain_openai` library to make API calls. The class is initialized with an API key and a model name.

- **`WeatherArgs` and `get_current_weather`**: These are example components that demonstrate the tool-calling functionality of the `OpenRouterLAM`. The `WeatherArgs` class defines the arguments for the `get_current_weather` tool, which is a simple function that returns mock weather data. This showcases how the LLM can be extended with custom tools to perform specific tasks.

## 4. Data Flow

The data flow for a typical tool-calling scenario is as follows:

```mermaid
sequenceDiagram
    participant A as Application
    participant B as OpenRouterLAM
    participant C as OpenRouter API
    participant D as Custom Tool (e.g., get_current_weather)

    A->>B: call_llm(messages, tools)
    B->>C: Invoke LLM with messages and tools
    C-->>B: Return AIMessage with tool_calls
    B->>D: Invoke tool with arguments
    D-->>B: Return tool_output
    B->>C: Invoke LLM with tool_output
    C-->>B: Return final response
    B-->>A: Return final response
```

**Figure 2: Tool-Calling Data Flow**
