# AI-Enabled Digital Health Platform

## Sprint Progress & Project Update

**Group 7**
**Date: 4th November 2025**

---

## Project Recap

### Project Vision
To build a prototype AI-enabled digital health platform for chronic disease monitoring.

### Core Problem
-   Fragmented health data for patients.
-   Lack of real-time, AI-powered insights.
-   Reactive, not proactive, care.

### Our Solution
-   **Patient Dashboard:** Unified view of health data (Glucose, Diet, Activity).
-   **Clinician Dashboard:** At-a-glance patient monitoring and risk assessment.
-   **AI Core (LAM):** Personalised recommendations, alerts, and chatbot functionality.

---

## System Architecture

A modern, decoupled system designed for scalability, security, and rapid development.

```mermaid
graph TD
    subgraph "User Interface"
        A[Flutter App <br>(Mobile & Web)]
    end

    subgraph "Backend Services"
        B[FastAPI Backend <br>(Serverless Functions)]
    end

    subgraph "AI Core"
        C[LangChain Agent]
        D[LLM <br>(e.g., GPT-4)]
        E[Custom Tools <br>(DB Query, etc.)]
    end

    subgraph "Backend as a Service (BaaS)"
        F[Supabase]
        G[PostgreSQL DB <br>with RLS]
        H[Authentication]
        I[Storage]
    end

    A --> B
    B --> C
    B --> F
    C --> D
    C --> E
    E --> G
    B --> G
    A -- "Auth" --> H
```

---

## Key Technologies

| Category | Technology | Rationale |
| :--- | :--- | :--- |
| **Frontend** | Flutter & Dart | True cross-platform (iOS, Android, Web) from a single codebase. |
| **Backend** | Python & FastAPI | Unmatched AI/ML ecosystem and high-performance asynchronous API. |
| **AI Core** | LangChain | Powerful agentic framework for building tool-using AI systems. |
| **Database & BaaS** | Supabase & PostgreSQL | Open-source, relational power with Row-Level Security (RLS). |
| **Visualisation** | `fl_chart` | Highly customisable and feature-rich charting library for Flutter. |
| **DevOps** | Git & GitHub | Industry-standard version control with GitFlow and CI/CD actions. |

---

## Sprint 1 - Foundation & Patient View

### Sprint 1 Goals (Completed)
-   **T1.1:** Establish project infrastructure (GitHub, CI/CD).
-   **T1.2:** Design and implement database schema in Supabase.
-   **T1.3:** Implement secure user authentication (Patient & Clinician).
-   **T1.4:** Develop a realistic patient data simulator.
-   **T2.1:** Build the patient-facing dashboard with data visualisations.

---

## Sprint 1 - Key Achievements

-   **Solid Foundation:** Project repository, branching strategy (GitFlow), and CI pipeline are fully operational.
-   **Data Backend Ready:** Supabase project is live with a complete PostgreSQL schema. Row-Level Security (RLS) policies are in place for basic data protection.
-   **Authentication Complete:** Users can securely sign up, log in, and log out. JWT-based session management is functional.
-   **Realistic Test Data:** A Python script now populates the database with simulated multi-patient data, enabling realistic development and testing.
-   **Patient Dashboard v1:** The initial Flutter-based patient dashboard is complete. It successfully fetches and displays key health metrics (glucose, activity) using `fl_chart`.

---

## Sprint 2 - AI Core & Automation

### Sprint 2 Goals (Completed)
-   **T3.1:** Develop a LangChain agent capable of reasoning and using tools to query the database.
-   **T3.2:** Generate and display personalised health recommendations on the patient dashboard.
-   **T4.1:** Create a serverless automation layer (LAM Triggers) to detect abnormal patterns.
-   **T4.2:** Implement a notification system for timely reminders (e.g., post-meal walk).

---

## Sprint 2 - Key Achievements

-   **Intelligent Agent Created:** A core LangChain agent has been developed. It is equipped with custom tools (`get_recent_glucose`, `get_diet_history`) to interact with the Supabase backend.
-   **Personalised Insights:** The agent can now synthesise patient data to generate and deliver contextual recommendations directly to the patient's dashboard.
-   **Proactive Monitoring:** A serverless function runs on a schedule to query for trigger conditions (e.g., glucose spikes, low activity), forming the basis of our "Large Action Model" (LAM).
-   **Automated Reminders:** The system can now trigger events for notifications, such as reminding a patient to take a walk after a detected high-carb meal and subsequent glucose spike.

---

## Sprint 3 - Clinician View & Finalisation

### Current Sprint Goals (In Progress)
-   **T5.1:** Build the clinician dashboard for monitoring assigned patients and identifying high-risk individuals.
-   **T5.2:** Implement the patient-facing chatbot for interactive Q&A about health data.
-   **T6.1:** Conduct comprehensive end-to-end system testing.
-   **T6.2:** Finalise all project documentation for submission.

---

## Current Work & Progress

### What We're Working On Now
-   **Clinician Dashboard UI:** Development is underway for the clinician's main view, focusing on a clear, actionable patient roster.
    -   *Status: UI components are being built. RLS policies are being refined for clinician access.*
-   **Chatbot Integration:** Connecting the LangChain agent to a new chat interface in the patient app.
    -   *Status: Basic chat UI is complete. Backend endpoint for the agent is being integrated.*
-   **Testing & Refinement:** Continuously testing integrations between the frontend, backend, and AI services.

---

## Live Demo Preview

### Key Features to Showcase
1.  **Patient Onboarding:** Secure login and view of the personalised dashboard.
2.  **Data Visualisation:** Interactive charts showing glucose trends over time.
3.  **AI-Powered Recommendation:** A live example of the system generating an insight based on recent data (e.g., a meal log).
4.  **LAM Trigger in Action:** Demonstrating an automated alert based on a simulated event (e.g., a glucose spike).
5.  **(In-Progress) Chatbot:** A preview of the patient asking the AI a question about their data.

---

## Next Steps

### Path to Completion
-   **Complete Clinician Dashboard:** Finalise the UI and risk-scoring logic.
-   **Finalise Chatbot:** Ensure robust and accurate responses from the AI agent.
-   **Rigorous E2E Testing:** Execute the full test plan across all user stories.
-   **Documentation:** Complete the user guide and technical documentation.
-   **Final Presentation & Handover:** Prepare for the final project demonstration.

---

## Questions?
