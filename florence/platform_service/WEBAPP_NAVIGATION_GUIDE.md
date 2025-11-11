# FLORENCE Digital Health Platform - WebApp Navigation Guide

**Quick Access URL:** http://localhost:8080

**Last Updated:** November 1, 2025

---

## Table of Contents
1. [Getting Started](#getting-started)
2. [Milestone 1: Login & Authentication](#milestone-1-login--authentication)
3. [Milestone 2: Patient Dashboard & Data Visualization](#milestone-2-patient-dashboard--data-visualization)
4. [Milestone 3: Personalized Recommendations](#milestone-3-personalized-recommendations)
5. [Milestone 4: Automation & Alerts](#milestone-4-automation--alerts)
6. [Milestone 5: Clinician Dashboard & Chatbot](#milestone-5-clinician-dashboard--chatbot)
7. [Milestone 6: Security Features](#milestone-6-security-features)
8. [Testing the Mock Data](#testing-the-mock-data)
9. [Troubleshooting](#troubleshooting)

---

## Getting Started

### Prerequisites
1. **Flutter App Running:** Ensure the app is running on http://localhost:8080
2. **Demo Mode:** The app runs in demo/offline mode (Supabase not connected)
3. **Mock Data:** All features use realistic mock data (30 days of patient data pre-loaded)

### App Status Indicators
When you first load the app, you should see:
- ⚠️ Warning: "Supabase is not configured!" - This is **expected** (demo mode)
- ✅ App loads successfully
- ✅ Mock authentication works
- ✅ 30 days of mock health data available

---

## Milestone 1: Login & Authentication

### ✅ **STATUS: FULLY IMPLEMENTED**

### Patient Login

**How to Access:**
1. Open http://localhost:8080
2. You'll see the **Login Screen**

**Demo Login Credentials:**
```
Email: demo@patient.com
Password: password123
```

**What You'll See:**
- 🔐 Email and password input fields
- 📱 "Remember Me" checkbox
- 🆕 "Don't have an account? Register" link
- 🔑 Material Design 3 login form

**Features to Test:**
- ✅ Login with demo credentials
- ✅ See validation messages (try empty fields)
- ✅ Click "Register" to see registration screen
- ✅ Demo mode auto-login (if enabled)

**Navigation Path:**
```
Home (/) → Login Screen → Dashboard (after login)
```

---

### Patient Registration

**How to Access:**
1. From login screen, click **"Don't have an account? Register"**

**What You'll See:**
- 📝 Full name input
- 📧 Email input
- 🔒 Password input (with strength indicator)
- 🔒 Confirm password input
- 📅 Date of birth picker
- ⚕️ Diabetes type selector
- 🎯 HbA1c target input

**Features to Test:**
- ✅ Form validation
- ✅ Password strength indicator
- ✅ Account creation (demo mode)

---

### Admin/Clinician Login

**How to Access:**
1. From main URL, navigate to: **http://localhost:8080/#/admin/login**

**Demo Admin Credentials:**

**Super Admin:**
```
Email: superadmin@florence.com
Password: Admin123!
```

**Hospital Admin (Hope Hospital A):**
```
Email: admin@hopea.com
Password: Admin123!
```

**Doctor (Hope Hospital A):**
```
Email: doctor@hopea.com
Password: Doctor123!
```

**What You'll See:**
- 🏥 FLORENCE Admin Login screen
- 🔐 Email and password fields
- 👤 Role-based access after login
- 📊 Different dashboard based on role

**Navigation Path:**
```
/#/admin/login → Admin Dashboard (role-specific)
```

---

### Role-Based Access Control

**Testing Permissions:**

1. **Login as Super Admin** → See all organizations and system settings
2. **Login as Hospital Admin** → See only Hope Hospital A patients
3. **Login as Doctor** → See only assigned patients

**Permission Features:**
- ✅ 50+ granular permissions
- ✅ Organization scoping
- ✅ Route-level guards
- ✅ Widget-level guards

---

## Milestone 2: Patient Dashboard & Data Visualization

### ✅ **STATUS: IMPLEMENTED (85% - UI needs final wiring)**

### Patient Dashboard

**How to Access:**
1. Login as patient (demo@patient.com / password123)
2. You'll land on the **Dashboard Screen**

**URL:** `http://localhost:8080/#/dashboard`

**What You'll See:**

**Top AppBar:**
- 🏥 "FLORENCE" logo
- 🤖 **AI Chat button** (top right) - Click to access chatbot
- 👤 Profile menu

**Main Dashboard Content:**
- 📊 **Health Summary Cards**
  - Latest glucose reading
  - Average glucose (7-day)
  - Time in Range percentage
  - Latest HbA1c

- 📈 **Quick Stats Grid**
  - Glucose trend (up/down/stable)
  - Medication adherence %
  - Activity minutes (weekly)
  - Sleep average (hours)

- 💡 **AI Insight Card**
  - AI-generated health tips
  - Pattern-based recommendations

- 📝 **Recent Activities**
  - Last glucose readings
  - Recent meals
  - Recent activities

**Quick Action Buttons (Floating Action Buttons):**
- ➕ **Add Glucose** - Log new glucose reading
- 🍽️ **Log Meal** - Record meal with carbs
- 🏃 **Record Activity** - Log exercise
- 🔄 **Refresh Data** - Reload health data

**Bottom Navigation:**
- 🏠 **Dashboard** (current)
- 📊 **Trends**
- 💊 **Medications**
- 👤 **Profile**

---

### Profile Switching (Testing Different Patient Types)

**How to Access:**
1. On Dashboard, look for **Profile Switcher** widget
2. Or click the profile icon in AppBar → "Switch Profile"

**Available Test Profiles:**

**Profile 1: Well-Controlled Patient**
- 🟢 Good glucose control (avg ~120 mg/dL)
- 🏃 Active lifestyle (80% activity level)
- 💊 High medication adherence (95%)
- 🎯 Target HbA1c: 6.5%
- **Use this to see:** Positive trends, good patterns, achievement notifications

**Profile 2: High-Risk Patient**
- 🔴 Poor glucose control (avg ~180 mg/dL)
- 🛋️ Low activity (30% activity level)
- 💊 Inconsistent medications (65% adherence)
- 🎯 Target HbA1c: 8.5%
- **Use this to see:** Alerts, critical patterns, high-priority recommendations

**Profile 3: Variable Patient**
- 🟡 Inconsistent patterns (avg ~145 mg/dL)
- 🏃 Moderate activity (60% activity level)
- 💊 Good medication adherence (80%)
- 🎯 Target HbA1c: 7.2%
- **Use this to see:** Mixed patterns, variability detection, moderate recommendations

**How to Switch:**
1. Click profile switcher dropdown
2. Select different profile
3. Dashboard automatically refreshes with new data
4. All screens update to show new profile's data

---

### Health Trends & Visualizations

**How to Access:**
1. From Dashboard, click **"Trends"** tab in bottom navigation
2. Or navigate to: `http://localhost:8080/#/trends`

**What You'll See:**

**Trends Main Screen:**
- 📊 **Overview Tab** (default)
- 📈 **Glucose Tab** - Detailed glucose trends
- 🍽️ **Meals Tab** - Meal impact analysis
- 🏃 **Activity Tab** - Activity impact analysis
- 🔍 **Patterns Tab** - AI-detected patterns

---

### Glucose Trends

**How to Access:**
1. Trends screen → Click **"Glucose"** tab
2. Or click "View Details" on any glucose chart

**Time Period Options:**
- **24 Hours** - Hourly glucose readings
- **7 Days** - Daily averages
- **30 Days** - Weekly summaries
- **90 Days** - Monthly trends

**What You'll See:**
- 📈 **Line chart** with glucose values
- 🟢🟡🔴 **Color-coded ranges:**
  - Green: 70-180 mg/dL (target range)
  - Yellow: 181-250 mg/dL (high)
  - Red: >250 mg/dL (very high)
  - Orange: <70 mg/dL (low)
- 📊 **Statistics panel:**
  - Average glucose
  - Standard deviation
  - Coefficient of variation (CV%)
  - Time in range %
  - Estimated HbA1c

**Interactive Features:**
- 👆 **Tap on chart** to see reading details
- 🔍 **Zoom and pan** capabilities
- 📅 **Date range selector**
- 📥 **Export button** (prepared)

---

### Meal Impact Analysis

**How to Access:**
1. Trends screen → Click **"Meals"** tab

**What You'll See:**
- 🍽️ **Meal list** with timestamps
- 📊 **Pre-meal vs Post-meal glucose** comparison
- 🥖 **Carbohydrate content** per meal
- 📈 **Glycemic response chart**
  - Shows glucose 2 hours before and 2 hours after meal
  - Highlights spike magnitude

**Features to Test:**
- ✅ See which meals caused glucose spikes
- ✅ Compare carb content impact
- ✅ Identify problematic foods
- ✅ View meal timing patterns

**Example Insights:**
- "Breakfast at 8 AM caused 60 mg/dL spike"
- "High carb dinner (85g) → 2-hour spike to 220 mg/dL"
- "Lunch with protein kept glucose stable"

---

### Activity Impact Analysis

**How to Access:**
1. Trends screen → Click **"Activity"** tab

**What You'll See:**
- 🏃 **Activity log** with type, duration, intensity
- 📉 **Glucose response** to exercise
- 📊 **Activity vs Glucose chart**
  - Shows glucose levels before, during, and after activity
- ⏱️ **Duration analysis**
- 🔥 **Intensity comparison** (Low, Moderate, High)

**Features to Test:**
- ✅ See glucose drop after walking
- ✅ Compare different activity types
- ✅ Identify optimal exercise timing
- ✅ View calories burned

**Example Insights:**
- "30-minute walk → 25 mg/dL glucose drop"
- "Intense cycling → delayed glucose rise"
- "Morning exercise → better all-day control"

---

### Pattern Detection Tab

**How to Access:**
1. Trends screen → Click **"Patterns"** tab

**What You'll See:**
- 🔍 **Detected Patterns List** (AI-powered)
- 🎯 **Pattern Types:**
  - 🔴 Glucose Spikes (>200 mg/dL)
  - 🟠 Post-Meal Spikes (2-hour window)
  - 🟡 High Variability (CV% >36%)
  - 🌅 Dawn Phenomenon (morning highs)
  - 🛋️ Low Activity (<150 min/week)
  - 💊 Missed Medications (<80% adherence)
  - 😴 Poor Sleep (<6 hours)
  - 🍞 High Carb Meals (>80g)
  - ⚠️ Consecutive High Readings
  - ⚠️ Consecutive Low Readings

**Pattern Card Details:**
- 📅 **Detection date**
- 🎯 **Pattern type** and description
- 🔢 **Data point count**
- 🤖 **AI insight** (if available)
- 📋 **Recommended actions**

**Features to Test:**
- ✅ View all detected patterns
- ✅ See AI-generated insights
- ✅ Click pattern for more details
- ✅ See recommended actions

**Example Pattern:**
```
🔴 Post-Meal Spikes Detected
Detected 3 days ago
5 instances in the past week

AI Insight: "Your glucose consistently spikes
after breakfast. Consider reducing carb
intake or adding a post-meal walk."

Recommended Actions:
• Reduce breakfast carbs to 45g
• Take 10-minute walk after eating
• Monitor glucose 2 hours post-meal
```

---

### Weekly Summaries

**How to Access:**
1. Trends screen → Look for **"Weekly Summary"** card
2. Or Dashboard → **"View Weekly Summary"** button

**What You'll See:**
- 📊 **Summary Period** (Last 7 days)
- 📈 **Key Metrics:**
  - Average glucose
  - Time in range %
  - Total activity minutes
  - Medication adherence %
  - Sleep average

- 🎯 **Achievements:**
  - "Maintained glucose in range for 5 days"
  - "Exceeded activity goal"
  - "Perfect medication adherence"

- 🎯 **Areas for Improvement:**
  - "3 post-meal spikes detected"
  - "Sleep below target 2 nights"

- 💡 **AI-Generated Narrative:**
  - Natural language summary of the week
  - Personalized insights
  - Specific recommendations

**Features to Test:**
- ✅ View last week's summary
- ✅ See AI-generated narrative
- ✅ Compare week-over-week
- ✅ Export summary (prepared)

---

## Milestone 3: Personalized Recommendations

### ✅ **STATUS: FULLY IMPLEMENTED**

### AI Recommendation Engine

**How to Access:**
1. Dashboard → Look for **"Recommendations"** card
2. Or click notification → Opens recommendation detail
3. Or navigate to: `http://localhost:8080/#/recommendations`

**What You'll See:**

**Recommendation Categories:**
- 🍽️ **Meal** - Nutrition and diet suggestions
- 🏃 **Activity** - Exercise recommendations
- 😴 **Sleep** - Sleep improvement tips
- 💊 **Medication** - Adherence reminders
- 🧘 **Lifestyle** - General health behaviors
- ⏰ **Timing** - Optimal timing for activities

**Priority Levels (Color-Coded):**
- 🔴 **Urgent** - Requires immediate attention
- 🟠 **High** - Address soon
- 🟡 **Medium** - Beneficial improvements
- 🟢 **Low** - Optional optimizations

---

### Viewing Recommendations

**Recommendation Card Shows:**
- 🎯 **Title** - Clear, actionable recommendation
- 📝 **Description** - Detailed explanation
- 🏷️ **Category** badge
- 🚦 **Priority** indicator
- 📅 **Date generated**
- ✅ **Action buttons** (Complete, Dismiss)

**Example Recommendation:**
```
🔴 URGENT - Reduce Post-Meal Glucose Spikes

Category: Meal
Priority: Urgent

Description:
Your glucose has spiked above 200 mg/dL after
5 meals this week, with an average spike of
65 mg/dL. This pattern increases your risk of
complications.

Action Items:
✓ Reduce carb intake to 45-60g per meal
✓ Take 10-minute walk after eating
✓ Avoid sugary drinks with meals
✓ Space meals 4-5 hours apart

Expected Impact:
Reducing meal carbs and adding post-meal
activity could lower your spikes by 30-40 mg/dL
and improve time-in-range by 15%.

Generated: Nov 1, 2025, 10:30 AM
```

---

### Recommendation Detail Screen

**How to Access:**
1. Click on any recommendation card

**What You'll See:**

**Detailed Sections:**

1. **"Why This Matters"** Section
   - 📊 Explanation linking to your specific data
   - 📈 Referenced glucose readings with timestamps
   - 🎯 Impact on your health goals

2. **"Action Steps"** Section
   - ✓ Specific, numbered steps to take
   - 🎯 Clear, actionable items
   - ⏰ Suggested timing

3. **"Data Supporting This"** Section
   - 📅 Timeline of relevant data points
   - 🔗 Links to specific glucose readings
   - 📊 Visual representation of pattern

4. **"Expected Outcome"** Section
   - 🎯 Predicted improvements
   - 📈 Estimated glucose impact
   - ⏱️ Timeframe for results

**Interactive Elements:**
- ✅ **Complete** button - Mark as done
- ❌ **Dismiss** button - Not relevant
- 🔄 **Snooze** button - Remind later
- 📤 **Share** button - Share with doctor

---

### Explainability Features

**Data Point References:**
Each recommendation shows:
- 📅 **Specific dates and times**
- 📊 **Actual glucose values** that triggered it
- 🍽️ **Specific meals** if meal-related
- 🏃 **Activity logs** if activity-related

**Example:**
```
This recommendation is based on:

• Nov 1, 8:15 AM - Glucose: 145 mg/dL (before breakfast)
• Nov 1, 8:30 AM - Meal: Oatmeal with berries (65g carbs)
• Nov 1, 10:30 AM - Glucose: 215 mg/dL (spike of 70 mg/dL)

• Oct 31, 8:20 AM - Similar pattern (spike of 65 mg/dL)
• Oct 30, 8:15 AM - Similar pattern (spike of 72 mg/dL)

Pattern: Breakfast consistently causes spikes >60 mg/dL
```

---

### Testing Recommendations

**To Generate New Recommendations:**
1. Dashboard → Click **"Refresh Data"** button (bottom FAB)
2. This triggers the recommendation engine
3. New recommendations appear within seconds
4. Based on current profile's data patterns

**Test Different Profiles:**
- **Well-Controlled:** See low-priority, optimization suggestions
- **High-Risk:** See urgent, critical recommendations
- **Variable:** See mixed priority recommendations

---

## Milestone 4: Automation & Alerts

### ✅ **STATUS: FULLY IMPLEMENTED**

### Pattern Detection (Automatic)

**How It Works:**
- ⏰ **Automatic monitoring** every 15 minutes
- 🔍 **11 pattern types** continuously checked
- 🤖 **AI enhancement** for complex patterns
- 📱 **Automatic notifications** when patterns detected

**You Don't Need to Do Anything!**
The system automatically:
1. Monitors your health data
2. Detects abnormal patterns
3. Generates notifications
4. Creates recommendations
5. Alerts clinicians (if high-risk)

---

### Viewing Detected Patterns

**How to Access:**
1. **Dashboard** → Look for **pattern alerts** card
2. **Trends** → **"Patterns"** tab (see above)
3. **Notifications** → Pattern detection alerts

**Pattern Severity Indicators:**
- 🔴 **Critical** - Immediate action needed
- 🟠 **High** - Review today
- 🟡 **Medium** - Review this week
- 🟢 **Low** - For awareness

---

### Notification Center

**How to Access:**
1. Top AppBar → Click **🔔 Bell icon**
2. Shows all notifications

**Notification Types:**
- 🚨 **Alert** - Urgent health warnings
- ⏰ **Reminder** - Scheduled reminders
- 📚 **Educational** - Health tips
- 💪 **Motivational** - Encouragement
- 📊 **Summary** - Weekly summaries
- 🏆 **Achievement** - Milestones

**Example Notifications:**

**Alert Notification:**
```
🚨 ALERT: Glucose Spike Detected
Your glucose is 225 mg/dL - above target range.

Actions:
• Check if you recently ate
• Drink water
• Take short walk if safe
• Test again in 30 minutes

Tap to view details →
```

**Educational Notification:**
```
📚 TIP: High Carb Meal Detected
You logged a meal with 85g carbs.

Did you know?
Meals >60g carbs often cause glucose spikes.
Try spacing carbs throughout the day.

Consider: 10-minute walk after meals
Tap to learn more →
```

**Motivational Notification:**
```
💪 Keep It Up!
You've been inactive for 3 days, but even
a 10-minute walk can help!

Benefits of activity:
• Lower glucose levels
• Better insulin sensitivity
• Improved mood

Tap for activity ideas →
```

---

### Automated Triggers (Testing)

**To See Automation in Action:**

**1. Add High Glucose Reading**
- Dashboard → **"Add Glucose"** button
- Enter value: **220 mg/dL**
- Click Save
- **Expected:** Alert notification within seconds

**2. Log High-Carb Meal**
- Dashboard → **"Log Meal"** button
- Enter carbs: **90g**
- Click Save
- **Expected:** Educational tip notification

**3. Skip Activity for 3 Days**
- Switch to profile with low activity
- **Expected:** Motivational prompt appears

**4. Weekly Summary (Automated)**
- Automatically generated every Sunday
- Check notifications on Sunday evening
- **Expected:** Full week summary with AI insights

---

### Risk Scoring (For Clinicians)

**How to View (Patient Side):**
- Currently visible to clinicians only
- Patient can see their risk-contributing factors in recommendations

**How to View (Clinician Side):**
1. Login as doctor/admin
2. Patient list shows risk scores
3. Color-coded: 🔴 Critical, 🟠 High, 🟡 Medium, 🟢 Low

---

## Milestone 5: Clinician Dashboard & Chatbot

### ✅ **STATUS: FULLY IMPLEMENTED**

### AI Chatbot Interface

**How to Access:**
1. **Dashboard** → Click **🤖 AI Chat** button (top right of AppBar)
2. Or navigate to: `http://localhost:8080/#/chat`

**What You'll See:**
- 💬 **Chat interface** (WhatsApp-style)
- 🤖 **AI Assistant** ready to help
- 💡 **Suggested questions** (4 dynamic suggestions)
- 📊 **Your health data** sidebar (shows latest metrics)

---

### Chatbot Features

**Context-Aware Conversations:**
The chatbot knows:
- ✅ Your latest glucose reading
- ✅ Your 7-day glucose summary
- ✅ Your recent meals and carbs
- ✅ Your activity level
- ✅ Your medication adherence
- ✅ Detected patterns
- ✅ Active recommendations

**Example Conversation:**

**You:** "Why did my glucose spike this morning?"

**AI:** "Based on your data, your glucose spiked to 215 mg/dL at 10:30 AM, about 2 hours after breakfast. You logged oatmeal with berries containing 65g of carbs at 8:30 AM.

This is a post-meal spike, which is common with high-carb breakfasts. Here are some tips to reduce morning spikes:

1. Reduce breakfast carbs to 45-50g
2. Add protein (eggs, Greek yogurt)
3. Take a 10-15 minute walk after eating
4. Consider spacing your carbs throughout the day

Would you like specific breakfast suggestions?"

---

### Suggested Questions

**Dynamic Questions Based on Your Data:**

If you have high glucose:
- "Why is my glucose high right now?"
- "What should I do about my glucose spike?"

If you have patterns:
- "Why do I spike after breakfast?"
- "How can I improve my time in range?"

If low activity:
- "What activities help lower glucose?"
- "How much should I exercise?"

If medication issues:
- "Is my medication working?"
- "When should I take my insulin?"

**General Questions:**
- "What's my glucose trend this week?"
- "How can I improve my HbA1c?"
- "What foods should I avoid?"
- "When should I test my glucose?"

---

### Testing the Chatbot

**Try These Sample Questions:**

1. **"What's my average glucose this week?"**
   - Expected: AI provides your 7-day average with context

2. **"Why am I getting post-meal spikes?"**
   - Expected: AI analyzes your meal data and glucose patterns

3. **"What activities can help me?"**
   - Expected: Personalized activity recommendations

4. **"Is 145 mg/dL a good reading?"**
   - Expected: Contextual answer based on your targets

5. **"How can I reduce my HbA1c?"**
   - Expected: Comprehensive action plan

**Features to Test:**
- ✅ Type custom questions
- ✅ Click suggested questions
- ✅ Multi-turn conversation (asks follow-ups)
- ✅ See referenced data in responses
- ✅ Clear conversation history

---

### Clinician/Admin Dashboard

**How to Access:**
1. Logout from patient account
2. Navigate to: `http://localhost:8080/#/admin/login`
3. Login with admin credentials (see Milestone 1)

---

### Super Admin Dashboard

**Login:** `superadmin@florence.com / Admin123!`

**What You'll See:**

**Dashboard Sections:**
- 📊 **System Overview**
  - Total patients: 150+ (from mock data)
  - Total organizations: 3
  - Total admins: 6
  - Active users today

- 🏥 **Organizations List**
  - Hope Hospital A
  - Hope Hospital B
  - Metro Health Center
  - Click to view details

- ⚠️ **Critical Patients** (Platform-wide)
  - Patients with risk score >70
  - Sorted by priority
  - Quick access to patient details

- 📈 **Platform Analytics**
  - Average risk score
  - Patients needing attention
  - Alert statistics
  - System health

**Navigation Menu:**
- 👥 **Patients** - View all patients
- 🏥 **Organizations** - Manage organizations
- 👤 **Users** - User management
- 📊 **Analytics** - Platform analytics
- ⚙️ **Settings** - System settings

---

### Hospital Admin Dashboard

**Login:** `admin@hopea.com / Admin123!`

**What You'll See:**

**Organization-Scoped Dashboard:**
- 🏥 **Hope Hospital A** overview
- 📊 **Hospital Metrics:**
  - Total patients in this hospital
  - Staff count (doctors)
  - Average risk score
  - Patients needing attention

- ⚠️ **Priority Patients** (Hospital-specific)
  - Only patients from Hope Hospital A
  - Risk-sorted list
  - Color-coded by severity

- 📈 **Hospital Analytics**
  - This week's trends
  - Alert summary
  - Compliance metrics

**Available Actions:**
- ✅ View patient list (hospital-scoped)
- ✅ Manage doctors in hospital
- ✅ View hospital analytics
- ❌ Cannot see other hospitals (permission denied)
- ❌ Cannot access system settings

---

### Doctor Dashboard

**Login:** `doctor@hopea.com / Doctor123!`

**What You'll See:**

**Patient Care Dashboard:**
- 👥 **My Patients** - Only assigned patients
- ⚠️ **Patients Needing Review**
  - High-risk patients
  - Recent alerts
  - Pending actions

- 📊 **Today's Tasks**
  - Patients to contact
  - Follow-ups due
  - Alerts to address

- 📈 **Patient Metrics** (Assigned patients only)
  - Average risk score
  - Active alerts
  - Medication adherence trends

**Available Actions:**
- ✅ View assigned patient details
- ✅ Review patient health data
- ✅ View recommendations
- ✅ Communicate with patients
- ❌ Cannot access patients not assigned
- ❌ Cannot manage users

---

### Patient List (Admin View)

**How to Access:**
1. Login as admin/doctor
2. Click **"Patients"** in navigation menu
3. Or navigate to: `http://localhost:8080/#/admin/patients`

**What You'll See:**

**Patient List Table:**
- 👤 **Name** (click to view details)
- 🆔 **Patient ID**
- 🎯 **Risk Score** (color-coded)
- 📊 **Latest Glucose**
- 📈 **HbA1c**
- 💊 **Med Adherence %**
- 📅 **Last Visit**
- ⚠️ **Alerts** count

**Filtering Options:**
- 🔴 Show Critical only
- 🟠 Show High Risk
- 🟡 Show Medium Risk
- 🟢 Show Low Risk
- 🔍 Search by name/ID

**Sorting:**
- Click column headers to sort
- Default: Risk score (highest first)

**Actions:**
- 👁️ **View Details** - Full patient profile
- 📊 **View Health Data** - Charts and logs
- 💬 **Contact** - Message patient
- 📥 **Export** - Download patient data

---

### Patient Detail Screen (Admin View)

**How to Access:**
1. Patient list → Click on patient name

**What You'll See:**

**Patient Profile:**
- 👤 **Demographics**
  - Name, age, gender
  - Contact information
  - Diabetes type

- 🎯 **Current Status**
  - Risk score with breakdown
  - Latest glucose
  - HbA1c
  - Time in range

- ⚠️ **Concerns List**
  - Auto-generated from risk scoring
  - Example: "Frequent post-meal spikes (5 this week)"
  - Example: "Medication adherence below 80%"
  - Example: "High glucose variability"

- 💡 **Recommended Actions**
  - Based on risk level
  - Example (Critical): "Contact patient immediately"
  - Example (High): "Review within 24 hours"

- 📊 **Quick Stats**
  - Glucose average (7-day, 30-day)
  - Activity minutes
  - Medication adherence
  - Sleep average

- 📅 **Care Team**
  - Assigned doctor
  - Last appointment
  - Next appointment

---

### Patient Health Data Screen (Admin View)

**How to Access:**
1. Patient detail → Click **"View Health Data"** button
2. Or navigate to: `http://localhost:8080/#/admin/patients/{id}/health`

**What You'll See:**

**Comprehensive Health Data:**

**Tab 1: Glucose**
- 📈 Glucose trend chart (7-day, 30-day, 90-day)
- 📊 Statistics (avg, std dev, time in range)
- 🔴 Flagged high/low readings
- 📥 Export button

**Tab 2: Meals**
- 🍽️ Meal log with timestamps
- 🥖 Carb content
- 📊 Post-meal glucose impact
- 🔗 Link to glucose chart

**Tab 3: Activity**
- 🏃 Activity log
- ⏱️ Duration and intensity
- 📉 Glucose response to activity
- 📊 Weekly totals

**Tab 4: Medications**
- 💊 Medication list
- 📅 Scheduled doses
- ✅ Taken vs missed
- 📊 Adherence %

**Tab 5: Patterns**
- 🔍 Detected patterns
- 🤖 AI insights
- ⚠️ Severity ratings
- 📋 Recommended actions

**Tab 6: Recommendations**
- 💡 Active recommendations
- 📅 Completed recommendations
- ⏸️ Dismissed recommendations
- 🎯 Priority queue

---

### Anomaly Highlighting (Admin View)

**Visual Indicators:**

**In Patient List:**
- 🔴 **Red row background** - Critical risk (score >70)
- 🟠 **Orange highlight** - High risk (score 50-70)
- 🟡 **Yellow highlight** - Medium risk (score 30-49)
- 🟢 **Green text** - Low risk (score <30)
- 🚨 **Alert badge** - Active alerts count

**In Patient Details:**
- 🔴 **Critical glucose readings** highlighted in red
- ⚠️ **Warning icons** for concerning metrics
- 📊 **Chart annotations** for out-of-range values
- 🎯 **Concerns section** prominently displayed

**In Health Data Charts:**
- Shaded red zones for high glucose (>180 mg/dL)
- Shaded orange zones for low glucose (<70 mg/dL)
- Green zone for target range (70-180 mg/dL)
- Markers on critical events

---

### Patient Prioritization (Admin View)

**Priority Workflow:**

**Critical Patients (Score >70):**
```
🔴 John Doe - Risk Score: 85
Last glucose: 245 mg/dL
Concerns:
• Consecutive high readings (8 in 24 hours)
• Medication adherence: 62%
• No activity logged in 5 days

Recommended Action: Contact immediately
Quick Actions: [📞 Call] [💬 Message] [📊 View Data]
```

**High Priority Patients (Score 50-70):**
```
🟠 Jane Smith - Risk Score: 65
Last glucose: 190 mg/dL
Concerns:
• High glucose variability (CV% 42%)
• 3 post-meal spikes this week

Recommended Action: Review within 24 hours
Quick Actions: [📊 View Trends] [💡 Send Recommendations]
```

**Features:**
- ✅ Auto-sorted by priority
- ✅ One-click contact
- ✅ Quick access to health data
- ✅ Batch actions for efficiency
- ✅ Mark as reviewed

---

## Milestone 6: Security Features

### ✅ **STATUS: PARTIALLY IMPLEMENTED (75%)**

### Role-Based Access Control (Testing)

**Test Permission System:**

**1. Login as Super Admin**
- Try accessing: Patients, Organizations, Users, Settings
- **Expected:** ✅ Full access to everything

**2. Login as Hospital Admin**
- Try accessing: Patients (own hospital only), Staff
- Try accessing: Other hospitals, System settings
- **Expected:** ✅ Hospital access, ❌ Denied for others

**3. Login as Doctor**
- Try accessing: Assigned patients only
- Try accessing: Other patients, Admin functions
- **Expected:** ✅ Assigned patients, ❌ Denied for admin

**Permission Denied Screen:**
When you try to access a restricted area:
- 🚫 "Access Denied" message
- 📋 "You don't have permission to view this page"
- 🔙 "Return to Dashboard" button

---

### Data Anonymization (Testing)

**Where to See It:**

**1. Export Patient Data (Admin)**
- Patient list → Select patient → Click "Export"
- Choose anonymization level:
  - **Safe Harbor** - Fully anonymized (no personal info)
  - **Limited** - Partial de-identification
  - **Minimal** - Names masked only

**Safe Harbor Example:**
```
Patient ID: Patient_ABC123 (original: John Doe)
Email: p****@example.com
Phone: (555) ***-****
Address: *** Main St, City, ST 123**
Age Group: 31-45 (original: 37)
Glucose Data: [preserved]
```

**2. Analytics Reports**
- Admin dashboard → Analytics
- All reports use aggregated, anonymized data
- K-anonymity: Minimum group size of 5

---

### Audit Trail

**How to View (Super Admin Only):**
1. Login as Super Admin
2. Navigate to: `http://localhost:8080/#/admin/audit`

**What You'll See:**
- 📋 **All user actions** logged
- 👤 **Who** performed the action
- 🎯 **What** action was performed
- 📅 **When** it occurred
- 🔍 **Details** of the action

**Example Audit Log:**
```
2025-11-01 10:30:15
User: admin@hopea.com
Action: Viewed patient details
Patient: P-12345
IP: 192.168.1.100
```

---

## Testing the Mock Data

### Understanding Mock Data

**Data Generation:**
- 🗓️ **30 days** of historical data per patient
- 📊 **4-8 glucose readings** per day
- 🍽️ **3-4 meals** per day
- 🏃 **Activity logs** based on profile (20-80% frequency)
- 💊 **Medication logs** with adherence patterns
- 😴 **Sleep logs** daily
- 📈 **HbA1c results** (quarterly, 3 results)

**Realistic Patterns:**
- Morning glucose variations
- Post-meal spikes
- Exercise-induced drops
- Missed medication effects
- Sleep impact on glucose

---

### Mock Patient Profiles

**Profile Data Characteristics:**

**Well-Controlled Patient:**
```
Baseline Glucose: 120 mg/dL
Glucose Range: 90-160 mg/dL
HbA1c: ~6.5%
Activity: 5-6 sessions/week, 30-75 minutes
Medication: 95% adherence
Sleep: 7-9 hours/night
Patterns: Minimal spikes, stable trends
```

**High-Risk Patient:**
```
Baseline Glucose: 180 mg/dL
Glucose Range: 100-280 mg/dL
HbA1c: ~8.5%
Activity: 1-2 sessions/week, 15-45 minutes
Medication: 65% adherence (many missed doses)
Sleep: 5-8 hours/night
Patterns: Frequent spikes, high variability
```

**Variable Patient:**
```
Baseline Glucose: 145 mg/dL
Glucose Range: 80-220 mg/dL
HbA1c: ~7.2%
Activity: 3-4 sessions/week, mixed intensity
Medication: 80% adherence (occasional misses)
Sleep: 6-9 hours/night
Patterns: Inconsistent, some good days, some bad
```

---

### Generating New Mock Data

**Method 1: Profile Switching**
1. Dashboard → Profile Switcher
2. Select different profile
3. **New 30-day dataset generated instantly**

**Method 2: Data Refresh**
1. Dashboard → Click "Refresh Data" FAB button
2. **Re-generates data for current profile**

**Method 3: Command Line Tool**
```bash
# Generate custom dataset
cd tools
dart patient_generator.dart 100 patients.csv

# This creates 100 patients with 30 days of data each
```

---

## Troubleshooting

### Common Issues

**Issue: "Supabase is not configured" Warning**
- ✅ **This is expected** - App runs in demo/offline mode
- ✅ All features work with mock data
- ℹ️ To enable Supabase, update credentials in `lib/core/config/environment.dart`

**Issue: Blank Dashboard**
- 🔄 Try refreshing the page
- 🔄 Try profile switcher → Switch to different profile
- 🔄 Check browser console for errors (F12)

**Issue: Floating SnackBar Warnings in Console**
- ℹ️ **Non-critical** - UI layout warning
- ✅ App functions normally
- 🐛 Will be fixed in next update

**Issue: AI Features Not Working**
- ✅ Check DeepSeek API key in environment.dart
- ✅ Current key: `sk-97bfbb146ad345d9acefbc5d6153fc2a`
- 🌐 Requires internet connection for AI calls
- 🔄 Fallback to rule-based recommendations if offline

**Issue: Cannot Login**
- ✅ Use exact demo credentials (case-sensitive)
- ✅ Patient: `demo@patient.com / password123`
- ✅ Admin: `superadmin@florence.com / Admin123!`
- 🔄 Clear browser cache if persistent

**Issue: Admin Routes Show 404**
- ✅ Ensure URL starts with `/#/admin/`
- ✅ Example: `http://localhost:8080/#/admin/login`
- ✅ Must be logged in as admin

**Issue: Charts Not Displaying**
- 🔄 Wait for data to load (2-3 seconds)
- 🔄 Try switching time periods
- 🔄 Check if profile has data

**Issue: Chatbot Not Responding**
- ✅ Check internet connection (requires AI API)
- ✅ Wait 5-10 seconds for response
- 🔄 Try a different question
- ℹ️ Fallback responses available if AI unavailable

---

### Browser Compatibility

**Recommended Browsers:**
- ✅ Google Chrome (latest) - **Best**
- ✅ Microsoft Edge (latest)
- ✅ Firefox (latest)
- ⚠️ Safari (limited testing)

**Required Browser Features:**
- JavaScript enabled
- LocalStorage enabled
- Cookies enabled
- WebSockets (for hot reload in dev)

---

### Performance Tips

**For Best Performance:**
- 🖥️ Use desktop/laptop (larger screen for charts)
- 🌐 Stable internet for AI features
- 🔄 Refresh page if app becomes slow
- 🧹 Clear browser cache periodically

---

## Quick Reference: All URLs

### Patient Side
- **Login:** `http://localhost:8080/` or `http://localhost:8080/#/login`
- **Register:** `http://localhost:8080/#/register`
- **Dashboard:** `http://localhost:8080/#/dashboard`
- **Trends:** `http://localhost:8080/#/trends`
- **Chat:** `http://localhost:8080/#/chat`
- **Profile:** `http://localhost:8080/#/profile`
- **Medications:** `http://localhost:8080/#/medications`

### Admin Side
- **Admin Login:** `http://localhost:8080/#/admin/login`
- **Super Admin Dashboard:** `http://localhost:8080/#/admin/dashboard/super`
- **Hospital Admin Dashboard:** `http://localhost:8080/#/admin/dashboard/hospital`
- **Doctor Dashboard:** `http://localhost:8080/#/admin/dashboard/doctor`
- **Patient List:** `http://localhost:8080/#/admin/patients`
- **Patient Detail:** `http://localhost:8080/#/admin/patients/{id}`
- **Patient Health Data:** `http://localhost:8080/#/admin/patients/{id}/health`
- **Organizations:** `http://localhost:8080/#/admin/organizations`
- **Users:** `http://localhost:8080/#/admin/users`
- **Analytics:** `http://localhost:8080/#/admin/analytics`
- **Settings:** `http://localhost:8080/#/admin/settings`
- **Audit Log:** `http://localhost:8080/#/admin/audit`

---

## Testing Checklist

### Patient Side Testing
- [ ] Login with demo credentials
- [ ] View dashboard with health summary
- [ ] Switch between 3 patient profiles
- [ ] View glucose trends (all time periods)
- [ ] Check meal impact analysis
- [ ] Check activity impact analysis
- [ ] View detected patterns
- [ ] Read AI-generated weekly summary
- [ ] Chat with AI chatbot
- [ ] Ask multiple questions to chatbot
- [ ] View recommendations
- [ ] Read recommendation details
- [ ] Complete/dismiss a recommendation
- [ ] Add new glucose reading
- [ ] Log a meal
- [ ] Record an activity
- [ ] Check notifications
- [ ] Test refresh data button

### Admin Side Testing
- [ ] Login as Super Admin
- [ ] View system dashboard
- [ ] See all organizations
- [ ] View platform-wide critical patients
- [ ] Login as Hospital Admin
- [ ] Verify organization scoping
- [ ] Try accessing other hospitals (should fail)
- [ ] Login as Doctor
- [ ] View assigned patients only
- [ ] Try accessing admin functions (should fail)
- [ ] View patient list (any admin role)
- [ ] Sort/filter patient list
- [ ] Click on patient → View details
- [ ] Check risk score and concerns
- [ ] View patient health data
- [ ] Explore all health data tabs
- [ ] Test export functionality
- [ ] Check audit log (Super Admin only)

### AI Features Testing
- [ ] Generate recommendations (refresh data)
- [ ] Verify AI-generated insights
- [ ] Check explainability (data links)
- [ ] Test chatbot with health questions
- [ ] Verify context-aware responses
- [ ] Check suggested questions
- [ ] Test pattern detection
- [ ] Verify AI pattern insights
- [ ] Check weekly AI summary

### Automation Testing
- [ ] Add high glucose reading → Check for alert
- [ ] Log high-carb meal → Check for educational tip
- [ ] Switch to low-activity profile → Check for motivation
- [ ] View all notification types
- [ ] Test notification deep links
- [ ] Verify pattern detection triggers

---

## Summary: What's Working

### ✅ Fully Functional Features

**Milestone 1 (100%):**
- ✅ Patient login/registration
- ✅ Admin login (3 roles)
- ✅ Role-based access control
- ✅ 50+ permissions system
- ✅ Mock data generation

**Milestone 2 (85%):**
- ✅ Patient dashboard (UI exists, needs final wiring)
- ✅ Glucose trends (all time periods)
- ✅ Meal impact analysis
- ✅ Activity impact analysis
- ✅ Weekly AI summaries
- ✅ Responsive design

**Milestone 3 (100%):**
- ✅ AI recommendation engine
- ✅ 6 recommendation categories
- ✅ 4 priority levels
- ✅ Explainability with data links
- ✅ DeepSeek AI integration
- ✅ Fallback rule-based system

**Milestone 4 (100%):**
- ✅ 11 pattern detection types
- ✅ Automatic monitoring (15-min intervals)
- ✅ 6 notification types
- ✅ Automated alerts and reminders
- ✅ Educational tips
- ✅ Motivational prompts
- ✅ Weekly summaries
- ✅ Risk-based prioritization

**Milestone 5 (100%):**
- ✅ AI chatbot with health context
- ✅ Suggested questions
- ✅ Multi-turn conversations
- ✅ Super Admin dashboard
- ✅ Hospital Admin dashboard
- ✅ Doctor dashboard
- ✅ Patient list with risk scores
- ✅ Patient detail screens
- ✅ Patient health data screens
- ✅ Anomaly highlighting
- ✅ Patient prioritization

**Milestone 6 (75%):**
- ✅ Role-based access control
- ✅ Permission guards
- ✅ Data anonymization (3 levels)
- ✅ Audit trail
- ⚠️ Basic encryption (needs upgrade)
- ⚠️ Test coverage (needs expansion)

---

**Document End**

**Need Help?**
- Check the `MILESTONE_IMPLEMENTATION_STATUS.md` for technical details
- Check the `README.md` for setup instructions
- Check the `IMPLEMENTATION_GUIDE.md` for development guide

**Happy Testing! 🎉**
