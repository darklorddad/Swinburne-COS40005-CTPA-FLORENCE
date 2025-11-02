# Project Manifest

This file is used to track the development plan, store notes, and keep temporary information.

---

## Event-Driven Architecture Decision

Ranking of event-driven architectures considered for real-time monitoring, from best to worst, accounting for project needs and ease of implementation.

1.  **Webhooks:** The best overall choice. They are event-driven, simple to implement (especially with services like Supabase), and promote a loosely coupled architecture that is easy to scale and maintain.

2.  **Direct Method Invocation:** The simplest and "laziest" method to implement. It is perfectly real-time as it's just a function call. However, it creates tight coupling and synchronous blocking, which harms scalability and long-term maintainability.

3.  **Database Triggers:** A very strong choice for simplicity and real-time response. They are easy to set up using SQL and keep the event logic close to the data.

4.  **WebSockets / Server-Sent Events (SSE):** Less suitable. These are more complex to implement and are better suited for real-time updates to user interfaces rather than for server-to-server processing.

5.  **Message Queues / Pub/Sub:** A powerful but high-effort solution. It offers excellent scalability and decoupling but requires setting up and managing separate infrastructure (a message broker).

6.  **Change Data Capture (CDC):** The worst option from an ease-of-implementation perspective. This is a complex, low-level pattern requiring specialised tools and configuration.

---

## LLM Development Plan (Recommendation Engine)

This section outlines the development plan for the AI-driven recommendation engine (Milestone 3). The chatbot interface (Milestone 5) will be handled by another team member.

### Development Plan

1.  **Data Aggregation:**
    *   Create a function in the Python backend (FastAPI) to fetch relevant, recent health data for a specific patient from the Supabase database. This includes glucose levels, diet logs, activity, etc.

2.  **Prompt Engineering:**
    *   Design and refine a detailed prompt that instructs the LLM to act as a health advisor.
    *   The prompt must include the aggregated patient data and ask for personalised recommendations with clear explanations (the "explainability feature").

3.  **LLM Integration:**
    *   Integrate an LLM service API (e.g., OpenAI, Google) into the backend.
    *   This involves creating a service that makes secure API calls with the engineered prompt and patient data.

4.  **Triggering Mechanism:**
    *   Define the logic for when to generate recommendations. This could be:
        *   **Scheduled:** A cron job or scheduled task that runs periodically (e.g., weekly) to generate a summary and new recommendations.
        *   **Event-Driven:** Triggered by specific data patterns detected by the automation layer (LAM Triggers, Milestone 4), such as a glucose spike.

### Key Considerations

*   **Choice of LLM:** Decide between a commercial API (e.g., OpenAI) and a self-hosted model. This impacts cost, complexity, and performance.
*   **Data Privacy:** Health data is sensitive. All data sent to third-party LLMs must be anonymised. Review the provider's data handling policies.
*   **Safety and Reliability:** LLMs can "hallucinate" incorrect medical advice. Implement "guardrails" (e.g., validation rules, keyword checks) to verify the LLM's output. The application must display clear disclaimers that the advice is AI-generated and not a substitute for professional medical consultation.
*   **System Architecture:** The Flutter client must **never** call the LLM provider directly. All LLM interactions must be proxied through the secure backend to protect API keys and manage data flow.
