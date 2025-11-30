Sprint Report
Portfolio Task 2/3/4

Unit code: COS40005/EAT40005
Unit name: Computing/Engineering Technology Project A

Submission date: 28th of November, 2025

Group 7:
Daniel Tiong (102777801)
Alif Harriz (102782711)
Ashley Jong (102780087)
Basil Agas (102778888)
Edison Ho (102779496)

1. Contribution Summary (This Sprint)
All team members should complete the following table together. You can provide a yes/no response or a brief comment where appropriate.

| Team Member | Daniel Tiong | Alif Harriz | Ashley Jong | Basil Agas | Edison Ho |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Contribution**<br>Finished tasks in time or on time with an acceptable quality | Yes | Yes | Yes | Yes | Yes |
| **Initiatives**<br>Self-assigned tasks and proactively found solutions to problems | Yes | Yes | Yes | Yes | Yes |
| **Communication**<br>Attended all team meetings | Yes | Yes | Yes | Yes | Yes |
| **Communication**<br>Attended all supervisor meetings | Yes | Yes | Yes | Yes | Yes |
| **Communication**<br>Attended all client meetings | Yes | Yes | Yes | Yes | Yes |
| **Communication**<br>Replied every time within an acceptable timeframe | Yes | Yes | Yes | Yes | Yes |
| **Communication**<br>Kept the team updated about the status | Yes | Yes | Yes | Yes | Yes |
| **Respect**<br>The student respected others and listened to different opinions | Yes | Yes | Yes | Yes | Yes |

2. Contribution Details (This Sprint)

2.1. Daniel (Project Lead and AI Engineer)
In this final and most critical sprint, my responsibilities transitioned from active development to high-level project orchestration and release management. Recognizing the tight deadline and the complexity of the proposed AI features, I made the executive decision—in consultation with the team—to pivot our strategy towards stability and core functionality. This involved a rigorous review of the entire `florence` monorepo, where I managed the merging of 15+ pull requests, resolving complex merge conflicts between the frontend and backend services. I took ownership of the final deployment pipeline, ensuring that the backend services on Vercel and the database on Supabase were production-ready. Additionally, I authored the comprehensive 'System Architecture Documentation' and the 'Final Project Report', synthesizing the technical contributions of the entire team into a cohesive narrative for the examiners.

**Evidence of Work**
*   **GitHub Commits:** Managed the final merge requests for the `florence` monorepo, ensuring a stable `main` branch.
*   **Documentation:** Finalised the Technical Architecture document and User Guides.
*   **Deployment:** Configured Vercel production environments and Supabase connection pooling.

2.2. Alif (Frontend Developer - Patient Dashboard)
My primary focus was transforming the Patient Dashboard from a collection of screens into a cohesive, robust application. I led the integration of the `fl_chart` library with the live `ApiService`, replacing static mock data with real-time streams from the backend. This required implementing complex data transformation logic within the Flutter frontend to parse JSON responses into the specific formats required by the charting widgets. I also implemented the 'Quick Log' feature, ensuring robust input validation and error handling to prevent bad data from reaching the server. A significant portion of my time was dedicated to UI/UX refinement; I conducted a heuristic evaluation of the interface, improving touch targets, contrast ratios, and navigation flows. To adhere to the 'Basic Prototype' scope, I strategically disabled the 'AI Insights' and 'Chatbot' tabs using feature flags, ensuring that the user is presented with a polished, error-free experience without encountering work-in-progress features.

**Evidence of Work**
*   **UI Polish:** Finalised the "My Health" and "Log Data" screens with responsive layouts.
*   **Integration:** Connected `fl_chart` widgets to the new Data Service endpoints with error handling.
*   **Feature Flags:** Implemented a configuration file to toggle AI features off for the demo.

2.3. Ashley (Frontend Developer - Clinician Dashboard)
I spearheaded the completion of the Clinician Dashboard, a critical component for demonstrating the platform's value to healthcare providers. I implemented the complex 'Patient List' interface, which includes dynamic filtering and sorting capabilities, allowing clinicians to prioritize patients based on risk levels. I developed the 'Patient Detail View', a data-rich screen that aggregates glucose, blood pressure, and activity data into interactive time-series charts. A key technical challenge I overcame was ensuring data consistency between the patient and clinician views; I implemented a polling mechanism to refresh the dashboard data periodically, ensuring clinicians see the latest updates. Furthermore, I conducted a comprehensive UI audit, aligning the Clinician Dashboard's design system (typography, color palette, component styling) with the Patient App to ensure a unified brand identity across the platform.

**Evidence of Work**
*   **Feature Completion:** Completed the "Patient Detail View" and "Alert History" screens.
*   **Testing:** Verified data consistency between Patient and Clinician views.
*   **UI Audit:** Standardised the `AppTheme` across the clinician application.

2.4. Basil (Lead AI Engineer and Data Architect)
Although the deployment of user-facing AI features was deferred, my work in this sprint was foundational for the project's future. I executed a complete architectural refactor of the `llm_chatbot_service`, decoupling it from the main application logic and establishing it as an independent microservice using FastAPI. This involved defining clear Pydantic models for request/response structures and documenting the API endpoints using Swagger/OpenAPI. Simultaneously, I significantly enhanced the `Data Seeding Utility`. I wrote complex Python scripts to generate realistic, longitudinal health datasets, simulating physiological patterns such as post-prandial glucose spikes and circadian heart rate variations. This synthetic data was crucial for the final demonstration, allowing us to showcase the platform's analytical capabilities without compromising patient privacy or relying on sparse manual entry.

**Evidence of Work**
*   **Service Refactor:** Restructured the `llm_chatbot_service` to be a standalone microservice.
*   **Data Engineering:** Updated the seeding utility to support complex query scenarios for the demo.
*   **API Documentation:** Generated OpenAPI specs for the future AI service integration.

2.5. Edison (Backend Developer)
I was responsible for hardening the backend infrastructure to support the final submission. I conducted a performance audit of the FastAPI endpoints, identifying and resolving N+1 query bottlenecks in the `get_patient_summary` and `get_clinician_roster` endpoints. This optimization reduced API response times by approximately 40%. I also finalized the security posture of the application by implementing rigorous Row-Level Security (RLS) policies in Supabase. I wrote SQL policies to ensure strict data isolation: patients can only access their own records, and clinicians can only access records of patients explicitly assigned to them. Throughout the sprint, I acted as the bridge between the database and the frontend teams, troubleshooting CORS issues, debugging authentication token failures, and ensuring the API contract was strictly adhered to.

**Evidence of Work**
*   **API Optimisation:** Refined `patients` and `clinicians` endpoints for faster response times.
*   **Security:** Finalised RLS policies for all database tables.
*   **Debugging:** Resolved critical CORS and JWT validation issues.

3. Sprint Plan
The sprint began with an ambitious backlog that aimed to deliver a fully integrated AI recommendation engine and a proactive alert system. However, during the mid-sprint review, it became evident that the complexity of integrating the Large Action Model (LAM) with the real-time database triggers was introducing significant instability. The risk of delivering a buggy, albeit feature-rich, prototype was deemed too high. Consequently, we revised the sprint goal to: 'Deliver a rock-solid, crash-free Basic Prototype that flawlessly executes the core loop of data logging, visualization, and patient-clinician data synchronization.' This strategic pivot required a significant restructuring of the backlog. We de-prioritized 'AI Meal Recommendations', 'Automated Push Notifications', and 'Chatbot Context Awareness', moving them to the 'Future Work' backlog for the next semester. In their place, we prioritized 'API Error Handling', 'UI Responsiveness on Mobile', 'End-to-End Integration Testing', and 'Final Documentation'.

**Revised Goal:** Deliver a robust, crash-free "Basic Prototype" that demonstrates the core value proposition (Data Logging, Visualisation, Patient-Clinician Connection) without relying on experimental AI features.

**Backlog Adjustments:**
*   **De-prioritised:** Advanced AI Triggers, Automated Interventions, Chatbot Context Awareness.
*   **Prioritised:** API Stability, UI/UX Polish, End-to-End Data Flow, Documentation, Integration Testing.

4. Sprint Progress
Despite the reduction in scope, the sprint was intense and highly productive. The team successfully closed 24 issues, including 5 critical bugs identified during the integration phase. By de-scoping the complex AI features, we were able to focus on the quality of the core application.

*   **Backend:** The Data Service API is now 100% complete and stable. All endpoints are protected by JWT authentication and RLS policies. The database schema was finalized and locked for submission.
*   **Frontend:** Both the Patient and Clinician Flutter applications are fully integrated with the backend. The UI is responsive and handles edge cases (e.g., no internet, empty data states) gracefully.
*   **Data:** The database is populated with high-quality synthetic data for 50 patients, covering a 3-month period, enabling meaningful demonstrations.
*   **AI:** The Chatbot Microservice is deployed and functional via API tools (Postman), ready for UI integration in the next phase.

5. Sprint Review

5.1 Demonstration
The final demonstration to the project supervisor was a comprehensive walkthrough of the 'Integrated Digital Health Platform'. We executed a live, end-to-end scenario:
1.  **Patient Action:** We logged into the Patient App as 'John Doe' and logged a high glucose reading (180 mg/dL) via the 'Quick Log' feature.
2.  **System Response:** We showed the immediate update on the Patient Dashboard charts.
3.  **Clinician Action:** We simultaneously logged into the Clinician Dashboard on a separate device.
4.  **Verification:** We navigated to 'John Doe's' profile and verified that the new reading appeared instantly, triggering a 'High Glucose' visual indicator.
5.  **Data Integrity:** We demonstrated the security controls by attempting to access another patient's data, which was successfully blocked by the RLS policies.
6.  **Architecture:** We showed the clean separation of services (Frontend, Backend, Chatbot Microservice) and the live Vercel deployment.

5.2 Client Feedback
The feedback from the Project Supervisor was overwhelmingly positive regarding the strategic pivot.
*   **Feedback:** "The decision to prioritize a robust, working prototype over a fragile, feature-packed one demonstrates significant maturity. The platform feels professional and stable. The data visualization is clear, and the separation of concerns in the architecture is evident. Deferring the AI to the next semester allows you to do it justice rather than rushing it."
*   **Outcome:** The prototype was formally accepted as meeting all requirements for the unit, with the AI components noted as "Future Work" for the subsequent unit.

5.3 Critical Analysis
The decision to de-scope the advanced AI features was the turning point of the project. Had we persisted with the original plan, we would likely have spent the final week debugging the AI agent's hallucinations or connection timeouts, leaving the core app unpolished. By focusing on the 'Basic Prototype', we ensured that the foundational layer—data ingestion, storage, security, and visualization—is rock solid. This provides a stable platform upon which the AI agents can be safely deployed in the future. The revamped LLM service, while not fully utilised in the UI, is a valuable asset for the next phase.

6. Retrospect (Critical Review of The Process)
This sprint highlighted the importance of 'Product Management' over mere 'Coding'. The team learned that the value of software is not in the number of features, but in the reliability of the user experience. The 'crunch' period fostered a strong sense of camaraderie; we moved from siloed working to daily collaborative sessions where frontend and backend developers debugged issues together in real-time. We also realized the cost of technical debt; the time spent refactoring the monorepo in Sprint 2 paid massive dividends this sprint, as deployment and integration were seamless.

7. Lessons Learned
*   **Integration is the Bottleneck:** We underestimated the time required to connect the frontend widgets to the backend API. Future sprints will allocate 40% of the time specifically for integration and testing.
*   **Real Data vs. Mock Data:** Developing with mock data is efficient, but switching to real data exposes edge cases (e.g., null values, timezone offsets) that mock data hides. We will implement 'dev-prod parity' earlier in the next phase.
*   **The Power of 'No':** Learning to say 'no' to nice-to-have features was crucial. It allowed us to focus our limited resources on the critical path.
*   **Documentation as a Deliverable:** Treating documentation (API docs, setup guides) as a first-class deliverable ensured that team members could work independently without constantly blocking each other for information.
