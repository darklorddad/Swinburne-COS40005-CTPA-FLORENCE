# Slide 0: Team Introduction
**Visual:** Photos/Names of all team members with their roles.
**Content:**
*   **[Member 1 Name]:** [Major] - [Contribution, e.g., Frontend & State Management]
*   **[Member 2 Name]:** [Major] - [Contribution, e.g., Backend API & Database]
*   **[Member 3 Name]:** [Major] - [Contribution, e.g., AI Services & Integration]
*   **[Member 4 Name]:** [Major] - [Contribution, e.g., UI/UX & Testing]

**Script:**
"Hello, we are the team behind Florence.
I am [Name], and I focused on [Contribution].
[Name] handled [Contribution].
[Name] worked on [Contribution].
And [Name] led our [Contribution].
Together, we've developed Florence to transform chronic disease management."

---

# Slide 1: Title Slide
**Visual:** The Florence Logo (Heart icon) centered on a clean blue background.
**Title:** Florence: Intelligent Chronic Disease Management Platform
**Subtitle:** Bridging the gap between patients and clinicians with AI-driven insights.
**Presenter:** [Your Name/Team Name]

**Script:**
"Good morning everyone. Thank you for joining us. We are here to present Florence.
Chronic disease management today is broken. It is often reactive, disjointed, and overwhelming. Patients are drowning in data points they don't understand, and clinicians are burnt out trying to monitor hundreds of patients with limited time.
Florence is our solution to this crisis. It is a comprehensive digital health platform designed to move healthcare from reactive data logging to proactive, intelligent care."

---

# Slide 2: The Problem Landscape
**Visual:** A split-screen graphic.
*   **Left (Patient View):** A chaotic mix of paper logs, different apps for food and meds, and a confused user looking at a glucose meter. Text overlay: "Am I okay?"
*   **Right (Clinician View):** A doctor looking at a generic list of names, with a red "Urgent" stamp buried under paperwork. Text overlay: "Who needs me most?"
**Bullet Points:**
*   **Data Silos:** Glucose, blood pressure, and diet data live in different places.
*   **Context Gap:** A high glucose reading means nothing without knowing *why* it happened (e.g., after a meal vs. fasting).
*   **Delayed Intervention:** Doctors often only see the data weeks later during appointments, missing critical windows for prevention.

**Script:**
"Let's look at the reality. A patient with diabetes might log their sugar levels, but they don't know if a reading of 140 is 'good' or 'bad' in their specific context. They log food in one app and steps in another.
On the other side, the clinician has no real-time visibility. They might have 500 patients. They can't check every file every day. This means critical warning signs—like a trend of hypoglycemia or missed medications—go unnoticed until the patient is sitting in the emergency room. We need a bridge."

---

# Slide 3: The Solution - A Unified Ecosystem
**Visual:** A connected workflow diagram: Patient App -> AI Cloud -> Clinician Dashboard.

**1. The Patient Companion (Mobile)**
*   **Unified Tracking:** Logs Glucose, BP, Diet, and Activity in one seamless interface.
*   **Instant Feedback:** Visual cues help patients understand their status immediately.

**2. The Intelligent Core (AI & Backend)**
*   **Contextual Analysis:** DeepSeek AI correlates lifestyle choices with health outcomes.
*   **24/7 Safety:** Automated pattern detection catches spikes and missed meds.

**3. The Clinical Bridge (Web Dashboard)**
*   **Smart Triage:** Automatically prioritizes high-risk patients for the care team.
*   **Deep Analytics:** Visualizes long-term trends for evidence-based decisions.

**Script:**
"Florence unites care through three key pillars:
First, the **Patient Companion**. A mobile app that makes tracking health effortless, giving patients immediate clarity on their status.
Second, the **Intelligent Core**. Our AI engine runs in the background, connecting the dots between diet, meds, and vitals to detect patterns that human review might miss.
Third, the **Clinical Bridge**. A specialized dashboard that filters out the noise, using risk scoring to show doctors exactly who needs attention today."

---

# Slide 4: System Architecture
**Visual:** A tech stack diagram showing the data flow:
[Flutter Frontend] <--> [Python Microservices] <--> [Supabase & LLM Providers]
**Bullet Points:**
*   **Frontend:** Flutter & Riverpod for a reactive, cross-platform experience.
*   **Microservices:**
    *   *Data Service:* FastAPI for core logic and validation.
    *   *Chatbot Service:* Dedicated Python service for AI orchestration.
*   **Infrastructure:** Supabase for scalable database storage and auth.

**Script:**
"To deliver this experience, we built Florence on a modern, scalable architecture.
The frontend uses Flutter, ensuring a consistent high-performance experience on both web and mobile. We manage the complex app state using Riverpod.
The backend is split into specialized Microservices using Python FastAPI. This separation of concerns allows the AI Chatbot to process heavy reasoning tasks independently without slowing down the core Data Service used for logging vitals.
Finally, Supabase acts as our infrastructure backbone, handling real-time data synchronization across the entire ecosystem."

---

# Slide 5: The Patient Experience - Dashboard & Logging
**Visual:** Screenshot of `DashboardScreen` and the `QuickLogModal`.
**Bullet Points:**
*   **Holistic Tracking:** Supports Glucose, HbA1c, Blood Pressure, Cholesterol, BMI, and Activity.
*   **Quick Actions:** One-tap access to log vital stats.
*   **Visual Status:** Color-coded cards (Green/Yellow/Red) for immediate feedback based on clinical thresholds.

**Script:**
"For the patient, we focused on reducing cognitive load. The dashboard isn't a spreadsheet; it's a health companion.
At a glance, they see their latest metrics—Glucose, Blood Pressure, BMI—color-coded based on their personal thresholds.
We know that if logging is hard, patients won't do it. That's why we built the 'Quick Actions' grid. Whether they need to log a meal, a blood pressure reading, or a workout, it takes seconds. We handle the complexity of data validation and timestamping in the background."

---

# Slide 6: The AI Advantage - Contextual Intelligence
**Visual:** Screenshot of `ChatScreen` side-by-side with `DietAnalyticsScreen`.
**Bullet Points:**
*   **DeepSeek Integration:** Advanced LLM powered by patient-specific data.
*   **Data-Aware:** The AI "sees" your profile, recent logs, and thresholds.
*   **Query:** "Why is my sugar high?"
*   **Response:** "It looks like your dinner last night had higher carbs than usual, and you missed your evening walk."

**Script:**
"This is where Florence stands out. We've integrated a specialized Chatbot Service. This isn't a generic 'search engine.'
When a patient asks, 'Why is my sugar high?', the system packages their recent meal logs, activity data, and medication history into a secure prompt for the AI.
The AI analyzes this *specific* context and replies: 'It looks like your dinner was high in carbs, and you haven't logged any activity since.' It connects the dots between lifestyle choices and health outcomes, empowering the patient to make better decisions."

---

# Slide 7: Proactive Safety - Automated Pattern Detection
**Visual:** A graphic of the `PatternDetectionService` logic flow leading to a push notification.
**Bullet Points:**
*   **Real-time Analysis:** Runs 24/7 in the background.
*   **Detectable Patterns:**
    *   Glucose Spikes (>50 mg/dL rise).
    *   Hypoglycemia events (<70 mg/dL).
    *   Missed Medications.
    *   Low Physical Activity.
*   **Actionable Alerts:** "Alert: Glucose Drop Detected. Consuming a fast-acting carb is recommended."

**Script:**
"Florence doesn't just wait for questions; it watches over the patient. Our Pattern Detection Service runs continuously.
If a patient's glucose spikes rapidly after a meal, or if they drop dangerously low, the system detects the anomaly instantly. It triggers an alert—not just a beep, but an actionable notification. It might suggest a short walk to lower a spike, or remind a patient that they've missed two consecutive doses of medication. It's a safety net that never sleeps."

---

# Slide 8: The Clinician Dashboard - Intelligent Triage
**Visual:** Screenshot of `ClinicianHomeScreen` showing the patient list sorted by risk.
**Bullet Points:**
*   **Risk Scoring:** Patients are automatically categorized (Critical, High, Medium, Low).
*   **Smart Filters:** Filter by "Last Update" or "Risk Level."
*   **Efficiency:** Doctors see who needs help *today*.

**Script:**
"For clinicians, the biggest challenge is noise. They can't watch everyone. Florence solves this with Intelligent Triage.
Our backend calculates a dynamic 'Risk Score' for every patient based on their recent averages, variability, and alert frequency.
When a doctor logs in, they don't see an alphabetical list. They see a prioritized view. The 'Critical' patients are at the top. This allows the care team to focus their limited time exactly where it saves lives—intervening proactively rather than waiting for a scheduled 3-month checkup."

---

# Slide 9: Deep Dive Analytics
**Visual:** Collage of the specific analytics screens: `GlucoseAnalyticsScreen`, `BloodPressureAnalyticsScreen`, and `ActivityAnalyticsScreen`.
**Bullet Points:**
*   **Granular Data:** View history, averages, and standard deviation.
*   **Visual Trends:** Graphs showing "Time in Range" vs. "Out of Range."
*   **Correlation:** See how activity levels impact specific health metrics.

**Script:**
"When a clinician clicks on a patient, they get the full story. We provide deep-dive analytics for every metric.
They can see the Glucose trend lines with 'Safe Zones' clearly marked. They can analyze Blood Pressure variability. They can even see correlation data—for example, verifying if a patient's weight loss correlates with improved cholesterol numbers. This supports evidence-based decision-making."

---

# Slide 10: Security & Data Integrity
**Visual:** A diagram illustrating the "Security Walls": JWT Tokens -> Microservice Middleware -> Database RLS Policies.
**Bullet Points:**
*   **Zero-Trust Database:** Row-Level Security (RLS) policies physically isolate patient data at the database level.
*   **Secure Authentication:** End-to-end JWT validation prevents unauthorized access.
*   **Data Sanitation:** Backend middleware validates all inputs before processing.
*   **Auditability:** Comprehensive logs track every data access event.

**Script:**
"In healthcare, trust is currency. We designed Florence with a 'Security by Design' philosophy.
Regardless of the user interface, our security is enforced at the database level using Row-Level Security (RLS). This means it is physically impossible for one patient to access another's records, even in the event of an application error.
We utilize secure JWT tokens for authentication, ensuring that every request—whether from the mobile app or the clinician dashboard—is strictly validated. This architecture ensures compliance and protects sensitive patient privacy at all times."

---

# Slide 11: Reflection & Challenges
**Visual:** A "Challenge vs. Solution" comparison chart.
**Bullet Points:**
*   **Challenge:** Providing the AI with complete, up-to-date health context for every query.
    *   *Solution:* Built a dedicated **Aggregation Service** to fetch and format multi-source data on-the-fly.
*   **Challenge:** Managing complex state dependencies across the app.
    *   *Solution:* Implemented a reactive architecture using **Riverpod** to propagate updates instantly across UI components.
*   **Challenge:** Ensuring secure data handling across multiple services.
    *   *Solution:* Unified JWT validation middleware across all microservices.

**Script:**
"Building Florence presented significant technical challenges.
Our biggest hurdle was **Context Management** for the AI. To give safe advice, the AI needs to know the patient's latest glucose, meals, and activity *right now*. We solved this by building a dedicated aggregation service that pulls data from multiple sources and formats it into a secure prompt instantly for every request.
We also tackled state synchronization. By utilizing **Riverpod**, we ensured that when a user logs a meal, the dashboard charts and summary statistics update immediately without requiring a full page reload."

---

# Slide 12: Future Work (COS40006)
**Visual:** A Roadmap graphic divided into four key tracks.
**Bullet Points:**
*   **Admin Ecosystem:** Full implementation of Super Admin and Hospital Admin portals for organization management.
*   **Clinician Enhancements:** Advanced filtering, alerting, and deeper analytics for the Clinician Dashboard.
*   **AI Engine Evolution:** Moving beyond context injection to a more robust, proactive reasoning engine.
*   **UX & Stability:** Comprehensive polish of the user interface and rigorous stability testing.

**Script:**
"Looking ahead to next semester, our roadmap is clear.
First, we will complete the **Admin Ecosystem**, fully implementing the interfaces for Super Admins and Hospital staff to manage organizations and user roles.
Second, we will upgrade the **Clinician Dashboard**, adding advanced filtering and deeper analytical tools to help doctors work more efficiently.
Third, we plan to significantly develop the **AI Engine**, evolving it from simple responses to more complex, proactive health reasoning.
Finally, we will focus heavily on **UX and Stability**, polishing the interface and ensuring the platform is robust, crash-proof, and ready for real-world use."
