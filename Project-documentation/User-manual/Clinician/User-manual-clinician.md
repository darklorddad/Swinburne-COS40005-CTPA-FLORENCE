# FLORENCE: Clinician Dashboard - User Manual

## 1. Introduction
The FLORENCE Clinician Dashboard is built for speed and secured for healthcare. It provides medical professionals with a streamlined, high-priority command centre that turns scattered patient logs into actionable clinical insights. The goal: Less noise. More signal.

---

## 2. Dashboard & Dynamic Risk Engine (Home Screen)

### 2.1 Overview of the Home Screen
Upon logging in, the clinician is presented with the main command centre. This screen is designed to highlight patients requiring immediate attention.

![Clinician Home Screen](2.1-1.png)

---

### 2.2 Key Features of the Home Screen
1.  **Search & Filter [Box 1]**: Quickly find patients by typing a name or ID. Tapping the filter icon expands advanced filters (e.g. filtering by specific risk levels or update recency).
2.  **Dynamic Sorting [Box 2]**: The patient list is NOT alphabetical. It is driven by a live Dynamic Risk Engine. Patients flagged as "High" or "Medium" risk automatically float to the top of the queue based on real-time continuous data flows from the patient app.
3.  **Priority Alerts [Box 3]**: If a patient breaches critical thresholds (e.g. consecutive fasting glucose readings > 10.0 mmol/L or hypertensive crisis readings), a **Priority Alert** card appears here. It displays the patient's name, the specific trigger and the time elapsed. Selecting **View Details** allows immediate investigation.

---

## 3. Patient Overview & Demographics

### 3.1 Holistic Patient View
Clicking on any patient from the list opens a comprehensive profile, defaulting to the **Overview** tab.

![Patient Overview Tab](3.1-1.png)

---

### 3.2 Understanding the Overview Tab
1.  **Demographics & Baseline [Box 1]**: Displays essential patient identifiers, age, gender and emergency contact details. It also features an **Edit** button (pencil icon) to update profile details.
2.  **Current Status Grid [Box 2]**: A stack of vital metrics cards showing the latest logged values. Each card is colour-coded by its current risk status:
    *   **Green (Normal)**: On track and within target thresholds.
    *   **Amber (Elevated/Low)**: Out of range; requires monitoring.
    *   **Red (High/Critical)**: Significantly out of range; requires immediate clinical review.
    *   **Grey (No Data)**: No readings logged yet.
3.  **Clinical Notes [Box 3]**: Displays persistent, chronological notes from the clinician and the clinical team. Selecting the **Add Note** icon appends a new entry.

---

## 4. Historical Data & Dynamic Analytics

### 4.1 Navigating to Historical Data
To view detailed trends and long-term patient data, the clinician navigates to the **Historical Data** tab.

![alt text](4.1-1.png)
![alt text](image-2.png)

---

### 4.2 Glucose Analytics Screen
Clicking on the **Glucose** summary card in the **Historical Data** tab opens the dedicated Glucose Analytics Screen.

![alt text](image-3.png)
![alt text](image-4.png)


#### **Key Features:**
1.  **Timeframe Filters [Box 1]**: Toggle between daily, weekly and monthly views. The chevron arrows allow navigation back and forth in time.
2.  **Smart Charts [Box 2]**: The charts dynamically scale their intervals so that even months of daily data remain readable without label overlap. Shaded bands represent the patient's personalised target safe zones.
3.  **Status Pills [Box 3]**: Below the charts, individual logged entries are listed chronologically and flagged with status pills (e.g. "ABOVE TARGET", "BELOW TARGET", "NORMAL") for rapid clinical assessment.

---

### 4.3 HbA1c Analytics Screen
Clicking on the **HbA1c** summary card in the **Historical Data** tab opens the dedicated HbA1c Analytics Screen.

![alt text](image-5.png)
![alt text](image-6.png)

#### **Key Features:**
1.  **Actual vs. Goal [Box 1]**: A clean, side-by-side bar chart comparing the patient's latest HbA1c reading against the target. A status card below immediately flags whether the patient is within target.
2.  **HbA1c Trends [Box 2]**: A line chart showing long-term control over months. Shaded bands represent the patient's target safe zones.
3.  **Status Pills [Box 3]**: Below the charts, individual logged entries are listed chronologically and flagged with status pills (e.g. "ABOVE TARGET", "BELOW TARGET", "NORMAL") for rapid clinical assessment.

---

### 4.4 Blood Pressure Analytics Screen
Clicking on the **Blood Pressure** summary card in the **Historical Data** tab opens the dedicated Blood Pressure Analytics Screen.

![alt text](image-7.png)
![alt text](image-8.png)

#### **Key Features:**
1.  **Target Ranges [Box 1]**: Displays the patient's personalised target ranges for both Systolic and Diastolic pressure.
2.  **Averages [Box 2]**: Displays the patient's average Systolic and Diastolic pressure for the selected period.
3.  **Blood Pressure Trends [Box 3]**: A line chart showing both Systolic and Diastolic lines. Shaded bands represent the patient's target safe zones.
4.  **Status Pills [Box 4]**: Below the charts, individual logged entries are listed chronologically and flagged with status pills (e.g. "HIGH", "NORMAL", "LOW") for rapid clinical assessment.

---

### 4.5 Cholesterol Analytics Screen
Clicking on the **Cholesterol** summary card in the **Historical Data** tab opens the dedicated Cholesterol Analytics Screen.
![alt text](image-9.png)
![alt text](image-10.png)

#### **Key Features:**
1.  **Cholesterol Ratio [Box 1]**: A clean, circular gauge comparing the patient's HDL against non-HDL cholesterol. A status card below immediately flags whether the patient is within target.
2.  **Metric Selector [Box 2]**: Toggle between Total, LDL, HDL and Triglycerides views.
3.  **Cholesterol Breakdown [Box 3]**: A line chart showing long-term control over months. Shaded bands represent the patient's target safe zones.
4.  **Status Pills [Box 4]**: Below the charts, individual logged entries are listed chronologically and flagged with status pills (e.g. "HIGH", "NORMAL", "LOW") for rapid clinical assessment.

---

### 4.6 Physical Activity Analytics Screen
Clicking on the **Physical Activity** summary card in the **Historical Data** tab opens the dedicated Physical Activity Analytics Screen.

![alt text](image-15.png)
![alt text](image-16.png)

#### **Key Features:**
1.  **Today's Movement [Box 1]**: Displays the patient's active minutes and sessions for today.
2.  **Activity Streak [Box 2]**: A 28-day heatmap grid showing a visual representation of the patient's activity. Green represents active days, light green represents less active days and grey represents inactive days.
3.  **Weekly Consistency [Box 3]**: A bar chart showing the patient's steps vs target. Green represents days where the target was met, amber represents days where the target was partially met and red represents days where the target was not met.

---

### 4.7 Diet Log & Nutrition Summary
Clicking on the **Diet Log** summary card in the **Historical Data** tab opens the dedicated Diet Log & Nutrition Summary Screen.


![alt text](image-17.png)
![alt text](image-18.png)

#### **Key Features:**
1.  **Diet Log List [Box 1]**: Displays the patient's logged meals chronologically. Each entry shows the meal type, timestamp and food items.
2.  **Nutrient Chips [Box 2]**: Displays the patient's macronutrient breakdown for each meal.
3.  **Automated Actions Log [Box 3]**: Displays the patient's automated actions log. Each entry shows the action type, timestamp and description.

---

## 5. Taking Clinical Action

### 5.1 Managing Medical Conditions & Medications
The clinician navigates to the **Medical Profile** tab to manage the patient's clinical background, target thresholds and active prescriptions. This tab serves as the clinical core for personalising patient care.

![alt text](image-23.png)

---

#### **Detailed Button Functions & Clinical Workflows:**

##### **1. Medical Conditions Card [Box 1]**

![alt text](image-19.png)
This card displays the patient's active and resolved diagnoses.
*   **Add New Condition Button (Plus Icon)**: Tapping this button opens the **Add Medical Condition** dialog.
    *   *Condition Name*: The clinician enters the diagnosis (e.g. "Type 2 Diabetes", "Hypertension").
    *   *Status Context Dropdown*: The clinician selects **Active** (for ongoing management) or **Resolved** (for historical context).
    *   *Diagnosed Date*: Tapping this opens a calendar date picker to log the exact onset date.
    *   *Add Entry Button*: Submits the record to the backend, immediately updating the patient's clinical profile.
*   **Active / Resolved / All Segmented Filter**: Tapping these segments instantly filters the list. This helps the clinician quickly isolate active issues during a consultation without being distracted by resolved history.
*   **More Options Button (Three-Dot Icon)**: Located next to each condition. Tapping this opens a context menu:
    *   *Mark as Resolved / Active*: Instantly toggles the condition's status and moves it to the appropriate filtered list.
    *   *Edit Details*: Re-opens the dialog to correct names or onset dates.
    *   *Remove*: Permanently deletes the condition from the patient's record after a confirmation prompt.
---
##### **2. Health Thresholds Card [Box 2]**

![alt text](image-21.png)
This card displays the patient's personalised target ranges for vitals (Glucose, Blood Pressure, HbA1c, Cholesterol and BMI). These thresholds are critical because the **Dynamic Risk Engine** uses them to calculate the patient's risk level and float the patient to the top of the home screen queue.
*   **Edit Button (Pencil Icon)**: Tapping this opens the **Health Thresholds** management dialog.
    *   *Threshold List*: Displays all vitals with their current min/max values.
    *   *Edit Single Threshold (Pencil Icon)*: Tapping the edit icon next to any vital (e.g. Glucose) opens the **Edit Threshold** dialog.
    *   *Minimum / Maximum Value Fields*: The clinician enters the new clinical targets. The units automatically match the preferred clinician settings (e.g. mmol/L or mg/dL).
    *   *Save Button*: Securely updates the targets via the REST API. The patient's app and the risk engine sync instantly.
---
##### **3. Current Medications Card [Box 3]**

![alt text](image-22.png)
This card displays the patient's active prescriptions and schedule.
*   **Add New Medication Button (Plus Icon)**: Tapping this opens the comprehensive **Add Medication** form.
    *   *Medication Name (Smart Autocomplete)*: Typing a brand or generic name queries the global medication dictionary in real-time to prevent spelling errors and ensure clinical accuracy. A custom name can also be typed if it is not in the dictionary.
    *   *Amount & Type*: The clinician enters the dosage quantity (e.g. "1", "500") and selects the form (e.g. "Tablet", "Capsule", "Injection" or "ml").
    *   *Frequency Dropdown*: The clinician selects how often the medication should be taken (e.g. "Twice daily", "Three times daily").
    *   *Specific Timings (Dynamic Fields)*: The form dynamically generates dropdown fields based on the selected frequency (e.g. showing "1st Dose" and "2nd Dose" for twice-daily frequency). The clinician selects precise clinical instructions for each dose (e.g. "BEFORE_BREAKFAST", "AFTER_DINNER" or "BEFORE_BED").
    *   *Add Medication Button*: Saves the prescription. This automatically generates a daily logging schedule in the patient's mobile app.
*   **More Options Button (Three-Dot Icon)**: Located next to each medication. Tapping this allows the clinician to:
    *   *Edit Details*: Modify dosage, frequency or timing instructions.
    *   *Remove*: Discontinue and delete the medication from the patient's active schedule.

---

### 5.2 Adding Clinical Notes
To record observations, treatment adjustments or consultation summaries, the clinician taps the **Add Note** button on the patient's Overview tab.

![alt text](image-24.png)
![alt text](image-26.png)
![alt text](image-27.png)

#### **Clinical Actions:**
1.  **Enter Note [Box 1]**: The clinician types clinical observations or treatment adjustments.
2.  **Save Note [Box 2]**: The clinician taps **Save Note**. Because the dashboard operates on a strict "Zero Direct Database" policy, the note is securely routed through the FLORENCE middleware REST API. The note immediately syncs across the platform, updating the priority queue and context for the entire clinical team in real-time.

---

## 6. Clinician Profile & Preferences

### Accessing the Profile
To view account details, update personal information or modify unit preferences, the clinician taps the **Profile** icon in the top-right corner of the Home Screen.

![alt text](image-28.png)
#### **Image Highlight Instructions (No image file, text-only directions for UI layout):**
Please capture a screenshot of the **Clinician Profile** screen and overlay **four red highlight boxes**, numbered as follows:
*   **[Box 1]** Around the **Account Information Card** (containing the clinician's name, gender and mobile number) with the **Edit Profile** button.
*   **[Box 2]** Around the **Unit Preferences Card** (containing Glucose Unit and Cholesterol Unit selectors).
*   **[Box 3]** Around the **System Information Card** (containing the clinician's email) and the **Organisation Information Card** (containing uneditable organisation details: name, email and phone number).
*   **[Box 4]** Around the **Logout Button** at the bottom.

---

#### **Detailed Card Descriptions & Clinical Actions:**

##### **1. Account Information Card [Box 1]**
![alt text](image.png)
This card displays the clinician's personal clinical identity details used across the platform.
*   **What it is**: A secure card containing editable profile details: **Full Name**, **Gender** and **Mobile Number**.
*   **What it does**: Allows the clinician to keep contact details and identity up to date so that patients and other clinical staff can identify and contact the clinician correctly.
*   **How to use it**:
    1.  The clinician taps the **Edit Profile** button in the bottom-right corner of the card. The fields will switch from read-only to editable text fields.
    2.  The clinician modifies the **Full Name** or **Mobile Number** as needed.
    3.  The clinician selects the **Gender** from the dropdown menu.
    4.  The clinician taps **Save Changes** to commit the updates to the backend database via the REST API, or taps **Cancel** to discard any edits and restore the previous values.

##### **2. Unit Preferences Card [Box 2]**
![alt text](image-1.png)
This card controls how clinical metrics are displayed throughout the entire dashboard.
*   **What it is**: A preference card containing selectors for **Glucose Unit** and **Cholesterol Unit**.
*   **What it does**: Customises the display units for all patient vitals across the dashboard. Changing these units automatically converts and displays all historical readings, charts and thresholds in the preferred format (e.g. converting glucose from mmol/L to mg/dL) without altering the underlying base data in the database.
*   **How to use it**:
    1.  The clinician taps the **Glucose Unit** row to open a bottom sheet selector and chooses between **mmol/L** and **mg/dL**.
    2.  The clinician taps the **Cholesterol Unit** row to open a bottom sheet selector and chooses between **mmol/L** and **mg/dL**.
    3.  The platform instantly recalculates and updates all charts, tables and status cards across the app. The preferences are saved to the profile via the REST API and persist across logins.

##### **3. System Information & Organisation Information Cards [Box 3]**

![alt text](image-11.png)
These cards display immutable system credentials and detailed organisational context.
*   **What they are**: Two read-only cards. The **System Information Card** displays the registered **Email Address**. The **Organisation Information Card** displays the assigned facility's **Organisation Name**, **Organisation Email** and **Organisation Phone Number**.
*   **What they do**: Provide essential system and facility context. The email is a unique login identifier, while the organisation details link the account to a specific healthcare facility, determining which patients, priority alerts and facility contact channels the clinician has permission to access.
*   **How to use them**: These sections are strictly read-only for security, compliance and audit purposes. If the email or organisation assignment needs to be changed, the system administrator should be contacted.

##### **4. Logout Button**
This button allows the clinician to securely terminate the active session.
*   **What it is**: A red-outlined button at the bottom of the profile screen.
*   **What it does**: Instantly invalidates the active Supabase authentication session, clears cached patient data from the device memory to prevent unauthorised access and returns the clinician to the secure login screen.
*   **How to use it**:
    1.  The clinician taps the **Logout** button.
    2.  A confirmation dialog will appear asking for confirmation to sign out.
    3.  The clinician taps **Sign Out** to confirm and is immediately redirected to the login screen.

