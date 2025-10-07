### COS40005 Computing Technology Project A

### 4.1 Industry Project Proposal Template (Track 1)

---

#### Company/Organisation Background
BioTective Sdn Bhd is a Sarawak-based digital health technology company that develops innovative solutions for chronic disease monitoring and management. The company's mission is to enhance patient outcomes by leveraging real-time health data, predictive analytics, and user-friendly mobile platforms. Founded to address gaps in preventive healthcare, BioTective provides products and services such as mobile health apps, wearable integrations, and cloud-based dashboards for clinicians. The company collaborates with healthcare providers and academic institutions to improve accessibility and efficiency in chronic disease care. BioTective is positioned as an emerging player in the digital health industry in Malaysia, with ongoing R&D efforts focusing on AI-powered health monitoring and personalized care.

---

#### Client Background and Contact
Ts. Dr. Vong Wan Tze
Senior Lecturer & Project Supervisor
School of Information and Communication Technologies
Swinburne University of Technology Sarawak

---

#### Project Title
Prototype Development of an AI-Enabled Digital Health Platform for Chronic Disease Monitoring

---

#### Problem Statement
Chronic disease patients often struggle with fragmented health information and lack of real-time monitoring. Existing systems do not fully leverage AI to detect early warning signs or provide personalized recommendations. BioTective seeks a prototype solution that can integrate multi-source health data (e.g., glucose levels, activity, vitals) and provide actionable, AI-powered insights to support timely interventions by patients and healthcare providers.

---

#### Detailed Requirements

**Milestone 1 – Project Setup & Data Simulation**
The team will begin by defining the system architecture, assigning roles, and setting up the project environment. A data ingestion pipeline will be developed to capture health inputs such as glucose, HbA1c, diet logs, and activity data. Since access to real-world data may be limited, a patient data simulator will be created to generate realistic datasets. Basic security features, including secure login with role-based access for patients and clinicians, will also be implemented.

**Milestone 2 – Patient Dashboard & Visualization**
A functional patient dashboard will be built to display glucose readings, HbA1c levels, diet history, and activity logs. Visualizations such as trend charts will be added to highlight glucose spikes and provide weekly summaries. The dashboard will be designed to work seamlessly on both desktop and mobile platforms for accessibility.

**Milestone 3 – Personalized Recommendation Engine**
The next milestone will focus on developing a recommendation engine powered by either an LLM or rule-based NLP approach. This module will provide personalized suggestions such as meal substitutions, post-meal activity reminders, and sleep improvement tips. An explainability feature will be included to show how the system links its recommendations to specific patterns in the patient's data.

**Milestone 4 – Automation Layer (LAM Triggers)**
An automation layer will be introduced to detect abnormal health patterns and trigger appropriate actions. These actions may include reminders after glucose spikes, delivery of short educational tips after unhealthy meals, motivational prompts when activity levels drop, and automated weekly health summaries. A risk-based prioritization system will also be implemented to flag high-risk patients for clinician review.

**Milestone 5 – Clinician Dashboard & Chatbot Interface**
A clinician dashboard will be developed to provide an aggregated view of patient data, highlight anomalies, and prioritize patients who need urgent attention. Alongside this, a chatbot interface will be created to allow patients to ask questions about their health data and receive AI-generated responses. This feature will improve patient engagement and offer an interactive way to access personalized insights.

**Milestone 6 – Testing, Security & Final Integration**
The final milestone will focus on system testing and integration. End-to-end testing will be conducted using simulated multi-patient datasets to ensure all components function correctly. Data security will be strengthened through encryption, anonymization, and role-based access control. The project will conclude with final documentation, a user guide, and a demonstration of the functional prototype to BioTective.

---

#### Expected Deliverables
*   A working prototype of the digital health platform integrating patient and clinician views.
*   Functional patient dashboard with health data visualization and weekly summaries.
*   Functional clinician dashboard with aggregated data, anomaly detection, and patient prioritization.
*   AI-driven recommendation engine for personalized health suggestions with explainability features.
*   Automation module (LAM triggers) for alerts, reminders, motivational prompts, and weekly health summaries.
*   Chatbot interface for patient interaction and personalized Q&A.
*   Data security module with role-based access, encryption, and anonymization.
*   Documentation including system design, code, deployment instructions, and user guide.

#### Example Data Flow

**Patient Data**
*   **Name:** Jordan
*   **Age:** 55
*   **Diabetes:** Type 2
*   **Past 7 days**
    *   **Glucose Reading:** Hyper Event (10.0-12.5 mmol/L after dinner)
    *   **HbA1c Reading:** Increased (8.0%)
    *   **Diet log:** Double cheeseburger, white bread, coffee, grilled chicken
    *   **Activity:** Exercised a total of 35 minutes

**Personalized Health Recommendation (via LLM)**
> Hi Jordan, I've noticed your blood glucose tends to spike after dinner, likely related to your current meal choices. Consider replacing white bread with whole grains like brown rice or quinoa, which have a lower glycemic impact.
> Also, adding a short 20-minute walk after dinner can help reduce glucose levels more effectively. Improving your sleep quality by aiming for 7-8 hours per night may also enhance insulin sensitivity. Let's work on a simple evening routine to support these changes.

**LAM-Triggered Actions**
*   Send post-meal activity reminders after glucose spikes.
*   After a high-carb meal, suggest a 2-minute video on glycemic index.
*   Summarise patient status in the past 7 days.
*   Schedule follow-up labs for high HbA1c.
*   Trigger motivational prompts when physical activity falls below recommended levels.
*   Prioritize Patients for Review.

---

#### Others

N/A.