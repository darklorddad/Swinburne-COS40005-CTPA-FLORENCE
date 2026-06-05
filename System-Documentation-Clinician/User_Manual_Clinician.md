# FLORENCE Clinician Dashboard - User Manual

## 1. Introduction
The FLORENCE Clinician Dashboard is built for speed and secured for healthcare. It provides medical professionals with a streamlined, high-priority command center that turns scattered patient logs into actionable clinical insights. The goal: Less noise. More signal.

## 2. Dashboard & Dynamic Risk Engine
### 2.1 The Home Screen
Upon logging in, you will be presented with your patient list. 
![alt text](<Screenshot 2026-06-05 165416.png>)
- **Dynamic Sorting**: The list is NOT alphabetical. It is driven by a live Dynamic Risk Engine.
- **Priority Alerts**: Patients flagged as "High" or "Medium" risk float automatically to the top of your queue based on real-time continuous data flows from their patient app.

### 2.2 Reviewing Priority Alerts
- If a patient breaches critical thresholds (e.g., 3 consecutive fasting glucose readings > 11.6 mmol/L), a **Priority Alert** card will appear at the top of your dashboard.
- It displays the patient's anonymized ID, the specific trigger for the alert, and recent medication adherence.
- Tap **Review Patient File** to investigate immediately.

## 3. Patient Details & Overview
### 3.1 Holistic View
Clicking on any patient brings up their detailed profile.
![alt text](image.png)
- **Clinical Notes**: The top section displays persistent notes from you and your team.
- **Vital Metrics Cards**: A quick summary of Cholesterol, BMI, Diet, Activity, and Medication adherence, all color-coded by their current risk status (Green = On Track, Amber = Monitor, Red = High Risk).

### 3.2 Dynamic Analytics & Historical Data
![alt text](<Screenshot 2026-06-05 165545.png>)
Navigate to the **Historical Data** tab to view detailed trends.
- Select a specific metric (e.g., Glucose, Blood Pressure, BMI) to open its dedicated Analytics Screen.
![alt text](image-1.png)
- **Smart Charts**: The charts dynamically scale their intervals so that even months of daily data remain readable without label overlap.
- **Status Pills**: Below the charts, individual logged entries are flagged with status pills like "ABOVE TARGET" or "BELOW TARGET" for rapid assessment.

## 4. Taking Clinical Action
### 4.1 Updating Risk Levels & Thresholds
- From the patient's overview, tap the **Risk Level Badge** (e.g., the red "HIGH RISK" pill).
- A dialog box will appear allowing you to manually adjust the patient's overall risk status or tweak their specific target thresholds based on their evolving care plan.

### 4.2 Adding Clinical Notes
- Tap the **Add Note** button.
![alt text](<Screenshot 2026-06-05 165716.png>)
- Enter your observations or treatment adjustments.
- Because the dashboard operates on a strict "Zero Direct Database" policy, your note is securely routed through the FLORENCE middleware REST API.
- The note immediately syncs across the platform, updating the priority queue and context for your entire clinical team in real-time.