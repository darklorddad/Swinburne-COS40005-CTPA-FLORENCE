# Florence: User Manual - Patient Portal

---

## 1. Introduction
Welcome to the Florence Patient Portal. Florence is an AI-powered health companion designed to monitor chronic conditions, guide daily habits and alert the patient and clinician when things go out of range. It supports the patient every single day between doctor visits.

Florence is also built to be easy to read and comfortable to use for patients of all ages, with large text and clear, high-contrast colours throughout.

---

## 2. Getting Started

### 2.1. Login/Registration

![alt text](login.png)
*Figure 1: The login screen.*

1. The patient opens the Florence app on the device.
2. The patient logs in using a registered Email and Password.
3. New patients can create an account by tapping *Sign Up*, where they will be asked to provide their Name, Email and a secure Password (email verification may be required).
4. Once logged in, patients should navigate to the *Profile* tab to complete their setup by adding baseline health metrics such as Height, Weight and medical conditions (Medication Cabinet for current prescription, Disease Log for current diagnosed health issues, if any).

### 2.2. The Dashboard
Upon opening the app, the patient is presented with a unified health dashboard.

![alt text](ai-daily-insight.png)
*Figure 2: The dashboard, with the AI daily insight and health metric cards.*

- **AI Daily Insight**: A concise, AI-generated summary of the patient's current health status and focus areas, refreshed from the most recent logs (for example, noting that glucose is stable and prompting the patient to maintain the medication routine). It provides key takeaways the moment the app is opened, so the patient is informed without needing to dig through the data. Tapping the insight banner opens the full *Insights* screen with the Vitality Index, Daily and Weekly Recommendations, and History. The insight appears once some data has been logged and sharpens as more is added.
- **Health Metric Cards**: Quick glances at Glucose, Blood Pressure, HbA1c, BMI and other tracked vitals, each colour-coded by status (for example, Normal or High).
- **Streaks and Habits**: Visual indicators of medication adherence and logging consistency.

When a patient is new and has not logged any data yet, the dashboard displays a friendly prompt inviting the patient to start logging.

![alt text](dashboard-empty.png)
*Figure 3: The dashboard before any data is logged.*

### 2.3. Navigating the App
The bottom navigation bar gives quick access to the main areas of Florence:
- **Home**: The dashboard, with the AI Daily Insight, Health Metric Cards and Quick Actions. Tapping any metric card opens its detailed *Analytics* screen. 
- **Chatbot**: The AI health assistant.
- **Centre (+) button**: Opens the "Log Health Data" menu to record a new reading.
- **Notifications (bell icon)**: View all alerts, reminders and achievements.
- **Profile**: Allows the patient to view and edit personal info, medical records, thresholds and settings.

---

## 3. Logging Data
Logging daily health data is crucial for Florence to understand patient patterns.

### 3.1. Vital Health Data
1. The patient navigates to the *Log Health Data* pop up via clicking the centre (+) button.
2. The patient selects the vital to log (Blood Glucose, HbA1c, Blood Pressure, Cholesterol, Activity or BMI).
3. The patient enters the value and the time of the reading (time will autofill but patient can still change it), then taps the save button.

![alt text](log-data-menu.png)
*Figure 4: The Log Health Data menu, where you choose which vital to record.*

![alt text](log-vital-reading.png)
*Figure 5: Entering a vital reading.*

### 3.2. Meals and Meal Vision AI
- **Manual entry**: The patient types in the food consumed and its estimated calories.
- **Meal vision**: The patient taps the camera icon and takes a photo of the meal. Florence's AI analyses the image, identifies the food and estimates the calories, and macronutrients (carbohydrates, protein and fat), then auto fills them automatically. The patient can review and adjust any value before saving, maintaining control of what gets recorded. No manual typing is required.

![alt text](meal-logging.png)
*Figure 6: Logging a meal.*

### 3.3. Physical Activity
- The patient can log physical activity by providing the duration and type of exercise.
- **AI calorie estimation**: Based on the activity duration, description and the patient's physical profile (Height, Weight, Age and Gender), Florence can automatically estimate the calories burned.

### 3.4. Medication
- Prescribed medications can be added to the schedule from the *Medication Cabinet*.
- The *Today's Schedule* view shows pending and taken medications.
- Tapping the medication logs it as taken, maintaining the adherence streak.
- Doses can also be unlogged if marked by mistake.

### 3.5. Health Records and Lab Reports
- **Symptoms**: The patient can log any unusual symptoms experienced.
- **Lab report reader**: The patient taps *Upload Report* and takes a photo of the physical blood test or lab results, or upload a PDF. Florence's AI reads the document and extracts the key metrics (for example HbA1c, total cholesterol, LDL, HDL and triglycerides), auto fills each value to the correct place. This saves the patient from typing results in by hand. The patient can then review the auto filled values and save them if everything is correct.

---

## 4. Analytics and Trends
Tapping on any health metric card on the dashboard opens its detailed analytics screen, which provides deep insights into historical data:
- **Glucose Analytics**: View Time in Range, Glucose Management Indicator (GMI), Variability and a modal day chart overlapping 24-hour patterns.
- **Blood Pressure Analytics**: Track Average Systolic/Diastolic, Pulse Pressure and view a scatter plot correlating Systolic vs. Diastolic readings.
- **Diet Analytics**: Features a "Traffic Light Consistency Calendar" showing 28 days of meal control and charts tracking the average glucose spike per meal type (Breakfast, Lunch and Dinner).
- **Activity Analytics**: Review movement volume, a 28-day GitHub-style streak heatmap, Weekly Consistency and calculate how specific activities impacted glucose levels.
- **BMI and weight**: Gauge relative to target, trends and correlation with HbA1c.
- **Cholesterol and HbA1c**: Visualises Cholesterol Ratios (HDL vs Non-HDL), LDL target tracking and plots HbA1c against BMI trends to spot weight-correlation patterns.

---

## 5. Profile, Medical Records and Settings
The profile section is the central hub for managing personal information and app preferences:
- **Personal and Care Team**: Update height, weight, emergency contacts and view the assigned clinician.
- **Medical conditions**: Maintain a Disease Log of "Active" and "Resolved" conditions.
- **Medication Cabinet**: Add new medications, set dosage frequencies (e.g. Twice daily, Before meals, etc.) and move discontinued medications to "Past".
- **Health thresholds**: Customise personal target ranges for Glucose, Blood Pressure, BMI, HbA1c and Cholesterol, or have the patient's care team determine the thresholds. Florence uses these exact bounds to colour-code the dashboard and trigger alerts.
- **Settings**: Toggle Dark Mode, switch measurement units (mmol/L vs mg/dL), enable/disable Quick Actions on the dashboard and adjust the background Health Check Interval (e.g. 15, 30 or 60 minutes).

---

## 6. AI Features and Guidance
The *Insights* screen is a personal AI guidance hub. It is opened by tapping the AI daily insight banner/card at the top of the dashboard.

### 6.1. Vitality Index and Personalised Recommendations

![alt text](insights-recommendations.png)
*Figure 7: The Insights screen, with the Vitality Index and recommendations.*

At the top of the Insights screen, the *Vitality Index* provides a single score out of 100 that sums up how on-track health is right now, shown as a coloured ring with a status label:
- **Thriving (75 and above):** The patient is doing really well.
- **Rising (50 to 74):** Solid progress, with a few areas to improve.
- **Straining (30 to 49):** Several areas need attention.
- **Depleted (below 30):** The patient needs to focus on the basics.

The score reflects four things: how often glucose stays in range, physical activity, medication adherence and how consistently data is logged. Tapping the *information (i) icon* in the header opens "About Insights and Vitality Index", which explains exactly how the score is calculated. Just below the ring, Florence displays how many *active health signals*.

If the patient is new and has not logged anything yet, the Vitality Index starts at 0 with a "Depleted" label and Florence invites the patient to begin logging. As soon as the first readings are recorded, the score and recommendations come to life.

Florence then turns those signals into clear, prioritised actions, grouped into two sections:
- **Daily Recommendations:** The most important things to act on today.
- **Weekly Action Plan:** Longer-term habits to maintain or build.

Each recommendation card shows:
- A *category* (for example Medication, Meal, Activity, Sleep, Lifestyle or Timing).
- A *priority pill* showing how urgent it is, from *Urgent* (act now), through *Moderate*, down to *On Track* (the patient is doing well and should keep it up).
- A short, actionable title, such as "Medication Adherence Review" or "Maintain High Activity Levels".

Tapping any recommendation card expands it to reveal the full detail:

![alt text](recommendation-expanded.png)
*Figure 8: An expanded recommendation card.*

- A key *metric* behind the recommendation (for example "Adherence from Thursday: 0%").
- A short *explanation* of why it matters (for example how consistent medication use prevents glucose spikes and reduces long-term risk).
- **Steps to Take:** Clear, numbered actions to follow right away.
- **Data Analysed Based On:** The type of data Florence used to generate the recommendation, showing what is being responded to.

For example, if glucose is high at night, Florence might recommend a 15-minute post-dinner walk.

**Recommendation History**
Once a recommendation has been acted on or is no longer current, it moves into a *History* section further down the screen, allowing past guidance to be reviewed.

![alt text](recommendation-history.png)
*Figure 9: The Recommendation History, with past recommendations across multiple pages.*

**Keeping Recommendations Up to Date**
Florence refreshes the Daily Recommendations about once a day, or sooner if new data is logged and the Weekly Action Plan about once a week. Because recommendations are generated from logged data, the more data is logged, the more tailored they become. Tapping the *refresh* icon next to a section regenerates it at any time.

### 6.2. AI Health Chatbot

![alt text](chatbot.png)
*Figure 10: The AI Health Chatbot.*

- Tapping the *Chat* icon opens the conversation with Florence.
- Health-related questions can be asked in plain language, for example "Why was glucose high after dinner?" or "What does the latest HbA1c mean?".
- Florence has access to the medical history and recent logs, so it answers in the context of the patient's specific condition instead of giving generic advice.
- The conversation is saved so it can be resumed later and it can be cleared at any time.
- Florence is a guidance and education tool. It will not diagnose the patient or change a prescription. For those decisions, it will always point the patient back to the clinician.

### 6.3. Smart Notifications

![alt text](smart-notifications.png)
*Figure 11: Smart notifications.*

Florence monitors data in two ways so nothing important is missed:
- **Right after logging**: If a reading is out of the safe range (for example, a very high or low glucose, or high blood pressure), Florence alerts the patient straight away with what happened and what to do about it.
- **In the background**: Florence also reviews recent logs on a regular schedule to catch developing patterns, even when the app is not actively being used.
- **Achievements**: Encouraging notifications are received for hitting logging streaks and reaching health targets.

The frequency of background checks can be adjusted from the settings.

---

## 7. Understanding Florence's AI

Florence uses AI to make health data easier to understand and act on. Here is what that means for the patient.

- *It works from logged data.* Every insight, recommendation and chatbot answer is based on the health information logged. The more consistently data is logged, the more accurate and tailored Florence becomes.
- *It is a guide, not a doctor.* Florence helps the patient understand data and build better habits, but it does not diagnose conditions or change medication. For any medical decision, it will encourage the patient to speak with the clinician.
- *Data stays private.* Information is kept secure and is never shared publicly. The AI only ever uses the data needed to help the patient and only the patient, and the assigned clinician can see the records.
- *The AI has been safety-tested.* Before release, Florence's AI features were tested against deliberate attempts to trick them into giving unsafe or off-topic advice, and against revealing private data. The AI resisted these attempts, so it can be trusted to stay focused on supporting health.
- *Always sense-check AI estimates.* Features like Meal Vision and the Lab Report Reader give best-effort estimates from a photo. They are designed to save typing, so the patient should review the values before saving and confirm anything important with the clinician.

---

## 8. Getting Help

If something does not look right, these steps usually help:
- *A reading looks wrong.* The patient can open the metric from the dashboard, check the logged entry.
- *Recommendations or insights seem out of date.* Tapping the refresh icon on the Insights screen regenerates them from the latest data.
- *Notifications are not being received.* Ensure notifications are enabled for Florence in the device settings, then check the Health Check Interval in the app's Settings.
- *Details need to be updated.* The patient can edit the personal or health profile from the Profile tab.
- *Data and privacy.* Records are private to the patient and the assigned clinician. To request changes to the account or data, the clinic or the Florence support team should be contacted.

Remember that Florence supports care between visits, but it does not replace the clinician. For any medical concern, the healthcare provider should be contacted.

<style>
    @import url('https://fonts.googleapis.com/css2?family=Funnel+Display&display=swap');

    .markdown-preview {
        font-family: 'Funnel Display', sans-serif;
        text-align: justify;
    }

    .markdown-preview h1,
    .markdown-preview h2,
    .markdown-preview h3,
    .markdown-preview h4,
    .markdown-preview h5,
    .markdown-preview h6 {
        text-align: left; 
    }
</style>