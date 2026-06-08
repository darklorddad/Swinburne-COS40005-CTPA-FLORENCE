# FLORENCE: Patient App - User Manual

## 1. Introduction
Welcome to the FLORENCE Patient App. FLORENCE is your AI-powered health companion designed to monitor your chronic conditions, guide your daily habits, and alert you and your clinician when things go out of range. It sits with you every single day between doctor visits.

FLORENCE is also built to be easy to read and comfortable to use for patients of all ages, with large text and clear, high-contrast colors throughout.

## 2. Getting Started
### 2.1 Login / Registration

<img src="login.png" width="250" alt="Login screen" />

*Figure 1: The login screen.*

- Open the FLORENCE app on your device.
- Log in using your registered email and password.
- If you are a new patient, follow the on-screen prompts to set up your profile, including your baseline health metrics (Height, Weight, Condition).

### 2.2 The Dashboard
Every morning, when you open the app, you will see your unified health dashboard:

<img src="ai-daily-insight.png" width="250" alt="Dashboard with the AI Daily Insight and live health metric cards" />

*Figure 2: The dashboard, with your AI Daily Insight and health metric cards.*

- **AI Daily Insight**: A concise, AI-generated summary of your current health status and what to focus on, refreshed from your most recent logs (for example noting that your glucose is stable and prompting you to keep up your medication routine). It gives you the key takeaways the moment you open the app, so you always know where you stand without digging through the data yourself. Tap the insight banner to open the full **Insights** screen with your Vitality Index and recommendations. The insight appears once you have logged some data, and sharpens as you add more.
- **Health Metric Cards**: Quick glances at your Glucose, Blood Pressure, HbA1c, BMI, and other tracked vitals, each color-coded by status (for example Normal or High).
- **Streaks & Habits**: Visual indicators of your medication adherence and logging consistency.

When you are new and have not logged anything yet, the dashboard greets you with a friendly prompt inviting you to start logging:

<img src="dashboard-empty.png" width="250" alt="Dashboard before any data is logged" />

*Figure 3: The dashboard before any data is logged.*

### 2.3 Navigating the App
The bottom navigation bar gives you quick access to the main areas of FLORENCE:
- **Home**: your dashboard, with the AI Daily Insight and your health metric cards.
- **Chatbot**: the AI health assistant.
- **Center (+) button**: opens the "Log Health Data" menu to record a new reading.
- **Profile**: view and edit your personal and health profile.
- **Settings**: manage your preferences, including how often FLORENCE checks your data, and sign out.

## 3. Logging Your Data
Logging your daily health data is crucial for FLORENCE to understand your patterns.

### 3.1 Vital Health Data
- Navigate to the **Log Data** section.
- Select the vital you wish to log (Blood Glucose, HbA1c, Blood Pressure, Cholesterol, Activity, BMI).
- Enter the value and the time of the reading, then tap **Save**.

<img src="log-data-menu.png" width="250" alt="Log Health Data menu" />

*Figure 4: The Log Health Data menu, where you choose which vital to record.*

<img src="log-vital-reading.png" width="250" alt="Logging a vital reading" />

*Figure 5: Entering a vital reading.*

### 3.2 Meals & Meal Vision AI
- **Manual Entry**: Type in the food you ate and its estimated calories.
- **Meal Vision**: Tap the camera icon and take a photo of your meal. FLORENCE's AI analyzes the image, identifies the food, and estimates the calories and macronutrients (carbohydrates, protein, and fat) for you, then logs them automatically. You can review and adjust any value before saving, so you stay in control of what gets recorded. No manual typing required.

<img src="meal-logging.png" width="250" alt="Meal logging" />

*Figure 6: Logging a meal.*

### 3.3 Medication
- Add your prescribed medications to your schedule.
- Receive daily dosage reminders.
- Tap the checkmark next to a medication to log it as taken, maintaining your adherence streak.

### 3.4 Health Records & Lab Reports
- **Symptoms**: Log any unusual symptoms you feel.
- **Lab Report Reader**: Tap **Upload Report** and take a photo of your physical blood test or lab results. FLORENCE's AI reads the document and extracts the key metrics (for example HbA1c, total cholesterol, LDL, HDL, and triglycerides), logs each value to the right place, and explains in plain language what the numbers mean for your condition. This saves you from typing results in by hand and helps you understand them without medical jargon.

## 4. AI Features & Guidance
The **Insights** screen is your personal AI guidance hub. Open it by tapping the AI Daily Insight banner at the top of your dashboard.

### 4.1 Vitality Index & Personalized Recommendations

<img src="insights-recommendations.png" width="250" alt="Insights and recommendations screen" />

*Figure 7: The Insights screen, with the Vitality Index and your recommendations.*

At the top of the Insights screen, the **Vitality Index** gives you a single score out of 100 that sums up how on-track your health is right now, shown as a colored ring with a status label:
- **Thriving** (75 and above): you are doing really well.
- **Rising** (50 to 74): solid progress, with a few things to tidy up.
- **Straining** (30 to 49): several areas need attention.
- **Depleted** (below 30): time to focus on the basics.

The score reflects four things: how often your glucose stays in range, your physical activity, your medication adherence, and how consistently you log your data. Tap the **information (i) icon** in the header to open "About Insights & Vitality Index", which explains exactly how the score is worked out. Just below the ring, FLORENCE tells you how many **active health signals** it has found in your recent logs.

If you are new and have not logged anything yet, the Vitality Index starts at 0 with a "Depleted" label and FLORENCE invites you to begin logging. As soon as you record your first readings, the score and your recommendations come to life.

FLORENCE then turns those signals into clear, prioritized actions, grouped into two sections:
- **Daily Recommendations**: the most important things to act on today.
- **Weekly Action Plan**: longer-term habits to maintain or build.

Each recommendation card shows:
- A **category** (for example Medication, Meal, Activity, Sleep, Lifestyle, or Timing),
- A **priority pill** showing how urgent it is, from **Urgent** (act now), through **Moderate**, down to **On Track** (you are doing well, keep it up),
- A short, actionable title, such as "Medication Adherence Review" or "Maintain High Activity Levels".

Tap any recommendation card to expand it and reveal the full detail:

<img src="recommendation-expanded.png" width="250" alt="Expanded recommendation card showing the metric, rationale, steps to take, and data analysed" />

*Figure 8: An expanded recommendation card.*

- A key **metric** behind the recommendation (for example "Adherence from Thursday: 0%").
- A short **explanation** of why it matters (for example how consistent medication use prevents glucose spikes and reduces long-term risk).
- **Steps to Take**: clear, numbered actions you can follow right away.
- **Data Analysed Based On**: the type of data FLORENCE used to generate the recommendation, so you can see what it is responding to.

For example, if your glucose is high at night, FLORENCE might recommend a 15-minute post-dinner walk.

**Recommendation History.** Once you have acted on a recommendation or it is no longer current, it moves into a **History** section further down the screen, so you can always look back at past guidance.

<img src="recommendation-history.png" width="250" alt="Recommendation History showing past, dismissed recommendations with pagination" />

*Figure 9: The Recommendation History, with past recommendations across multiple pages.*

**Keeping recommendations up to date.** FLORENCE refreshes your Daily Recommendations about once a day, or sooner if you log new data, and your Weekly Action Plan about once a week. When the guidance is due for an update you will see a "Stale, tap to refresh" hint. Because recommendations are generated from your own logged data, the more you log, the more tailored they become. Tap the **refresh** icon next to a section to regenerate it at any time.

### 4.2 AI Health Chatbot

<img src="chatbot.png" width="250" alt="AI chatbot" />

*Figure 10: The AI Health Chatbot.*

- Tap the **Chat** icon to talk to FLORENCE.
- Ask any health-related question in plain language, for example "Why was my glucose high after dinner?" or "What does my latest HbA1c mean?".
- FLORENCE has access to your medical history and recent logs, so it answers in the context of your specific condition instead of giving generic advice.
- Your conversation is saved so you can pick it up later, and you can clear it at any time.
- FLORENCE is a guidance and education tool. It will not diagnose you or change your prescription. For those decisions, it will always point you back to your clinician.

### 4.3 Smart Notifications

<img src="smart-notifications.png" width="250" alt="Smart notifications" />

*Figure 11: Smart notifications.*

FLORENCE watches your data in two ways so nothing important slips through:
- **Right after you log**: if a reading is out of your safe range (for example a very high or low glucose, or high blood pressure), FLORENCE alerts you straight away with what happened and what to do about it.
- **In the background**: FLORENCE also reviews your recent logs on a regular schedule to catch developing patterns, even when you are not actively using the app.
- **Achievements**: you will also receive encouraging notifications for hitting logging streaks and reaching your health targets.

You can adjust how often the background checks run from the notification settings.

## 5. Understanding FLORENCE's AI

FLORENCE uses AI to make your health data easier to understand and act on. Here is what that means for you.

- **It works from your own data.** Every insight, recommendation, and chatbot answer is based on the health information you log. The more consistently you log, the more accurate and tailored FLORENCE becomes.
- **It is a guide, not a doctor.** FLORENCE helps you understand your data and build better habits, but it does not diagnose conditions or change your medication. For any medical decision, it will encourage you to speak with your clinician.
- **Your data stays private.** Your information is kept secure and is never shared publicly. The AI only ever uses the data needed to help you, and only you and your assigned clinician can see your records.
- **The AI has been safety-tested.** Before release, FLORENCE's AI features were tested against deliberate attempts to trick them into giving unsafe or off-topic advice, and against revealing your private data. The AI resisted these attempts, so you can trust it to stay focused on supporting your health.
- **Always sense-check AI estimates.** Features like Meal Vision and the Lab Report Reader give best-effort estimates from a photo. They are designed to save you typing, so review the values before saving, and confirm anything important with your clinician.

## 6. Getting Help

If something does not look right, these steps usually help:
- **A reading looks wrong.** Open the metric from your dashboard, check the logged entry, and edit or re-log it if needed.
- **Recommendations or insights seem out of date.** Tap the refresh icon on the Insights screen to regenerate them from your latest data.
- **You are not receiving notifications.** Make sure notifications are enabled for FLORENCE in your device settings, then check the Health Check Interval in the app's Settings.
- **You need to update your details.** Edit your personal or health profile from the Profile tab.
- **Your data and privacy.** Your records are private to you and your assigned clinician. To request changes to your account or data, contact your clinic or the FLORENCE support team.

Remember that FLORENCE supports your care between visits, but it does not replace your clinician. For any medical concern, contact your healthcare provider.
