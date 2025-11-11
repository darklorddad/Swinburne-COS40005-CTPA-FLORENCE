# 🔄 Admin Platform Process Flows

Visual diagrams of key workflows and user journeys for the GlucoGuide Admin Platform.

---

## 1. 🏢 Organization Setup Flow (Super Admin)

```
[Super Admin Logs In]
        │
        ▼
[Navigate to Organizations > All Organizations]
        │
        ▼
[Click "Create Organization"]
        │
        ▼
[Fill Organization Form]
    ├─ Organization Name: "Acme Hospital"
    ├─ Custom Login URL: "acme.glucoguide.com"
    ├─ Address: "123 Main St, Kuching"
    ├─ Phone: "+60 82-123456"
    │
    └─ Admin Details:
        ├─ Name: "Dr. Ahmad Ibrahim"
        ├─ Email: "ahmad@acmehospital.com"
        └─ Username: "ahmad.admin"
        │
        ▼
[Submit Form]
        │
        ▼
[System Validates]
    ├─ Check Name Unique ────────┐
    ├─ Check Login URL Unique ───┤
    ├─ Check Admin Email Unique ─┤
    └─ Check Admin Username Unique
        │                        │
        ▼                        │
    [Valid?] ─── NO ─────────────┘
        │YES                     │
        ▼                        ▼
[Create Organization]    [Show Error Messages]
        │                        │
        ▼                        ▼
[Create Admin User]         [User Fixes Errors]
        │                        │
        ▼                        │
[Send Welcome Email]            │
        │                        │
        ▼                        │
[Redirect to Organization Detail]◄┘
        │
        ▼
[Admin Receives Email]
        │
        ▼
[Admin Clicks "Reset Password" Link]
        │
        ▼
[Admin Sets Password]
        │
        ▼
[Admin Logs In to acme.glucoguide.com]
        │
        ▼
[Admin Configures Organization]
    ├─ Set Language (English/Malay/Chinese)
    ├─ Set Timezone (Asia/Kuala_Lumpur)
    ├─ Set Blood Glucose Unit (mg/dL)
    ├─ Set Other Units
    └─ Configure Preferences
        │
        ▼
[Create Roles for Organization]
    ├─ "Nurse" role
    ├─ "Doctor" role
    └─ "Dietitian" role
        │
        ▼
[Create Users]
    ├─ Create Doctors
    ├─ Create Nurses
    └─ Create Dietitians
        │
        ▼
[Add Patients]
    ├─ Create manually (w/o APP)
    └─ Link from mobile app (w/ APP)
        │
        ▼
[Create Practice Groups]
    ├─ "Ward A Patients"
    ├─ "Ward B Patients"
    └─ "Outpatient Clinic"
        │
        ▼
[Organization Setup Complete! ✅]
```

---

## 2. 👥 User Management Flow (Hospital Admin)

```
[Hospital Admin Logs In]
        │
        ▼
[Navigate to Users > List]
        │
        ▼
[View Current Users in Organization]
        │
    ┌───┴───┐
    │       │
[Search] [Create New User]
    │       │
    │       ▼
    │   [Click "Create Professional"]
    │       │
    │       ▼
    │   [Fill User Form]
    │       ├─ Full Name: "Dr. Sarah Lee"
    │       ├─ Gender: Female
    │       ├─ Email: "sarah@acmehospital.com"
    │       ├─ Username: "sarah.lee"
    │       ├─ Phone: "+60 12-345-6789"
    │       ├─ Role: "Doctor" (dropdown)
    │       ├─ Profession Type: "General Practitioner"
    │       └─ Permissions:
    │           ├─ ☑ View Patients (default)
    │           ├─ ☑ Edit Patients (default)
    │           ├─ ☐ Create External Patients (allowed, not default)
    │           └─ ☑ Manage Appointments (default)
    │       │
    │       ▼
    │   [Submit Form]
    │       │
    │       ▼
    │   [System Validates]
    │       ├─ Email Unique?
    │       ├─ Username Unique?
    │       └─ Required Fields Filled?
    │       │
    │       ▼
    │   [Valid?] ─── NO ──→ [Show Errors] ──→ [Fix & Retry]
    │       │YES                                    │
    │       ▼                                       │
    │   [Create User Account]◄──────────────────────┘
    │       │
    │       ▼
    │   [Auto-set Organization to "Acme Hospital"]
    │       │
    │       ▼
    │   [Send Welcome Email with Reset Password Link]
    │       │
    │       ▼
    │   [Redirect to User Detail Page]
    │       │
    │       ▼
    │   [User Receives Email]
    │       │
    │       ▼
    │   [User Sets Password]
    │       │
    │       ▼
    │   [User Logs In]
    │       │
    │       ▼
    │   [User Can Access System ✅]
    │       │
    ▼       ▼
[User Management Complete]
```

---

## 3. 🏥 Patient Onboarding Flow

### Flow A: Create Patient Without Mobile App

```
[Professional Logs In]
        │
        ▼
[Navigate to Patients > List]
        │
        ▼
[Click "Create Patient"]
        │
        ▼
[Select: "Create Patient (w/o APP)"]
        │
        ▼
[Fill Patient Form]
    ├─ Full Name: "Ahmad bin Abdullah"
    ├─ Gender: Male
    ├─ Date of Birth: 1965-05-15
    ├─ Diabetes Type: Type 2
    ├─ Patient Number: "P2025-0001"
    ├─ Date of Diagnosis: 2020-03-10
    ├─ Mobile Phone: "+60 12-987-6543" (optional)
    └─ Emergency Contact: "Fatimah (wife) +60 12-987-6544"
        │
        ▼
[Click "Submit"]
        │
        ▼
[System Validates Required Fields]
        │
        ▼
[System Checks for Similar Accounts]
    ├─ Match by: Name + DOB + Gender
    │
    ▼
[Similar Account Found?]
    │
    ├─── YES ──→ [Show Popup]
    │               ├─ "Similar account exists!"
    │               ├─ Show existing patient details
    │               ├─ Button: "Go to Account"
    │               └─ Button: "Continue Anyway"
    │                   │
    │                   ├─ [Go to Account] ──→ [Navigate to Existing Patient]
    │                   │                           │
    │                   │                           ▼
    │                   │                      [End Flow]
    │                   │
    │                   └─ [Continue] ──┐
    │                                   │
    └─── NO ────────────────────────────┤
                                        │
                                        ▼
                            [Show Confirmation Popup]
                                ├─ Review entered details
                                ├─ "Create this patient?"
                                └─ Button: "Confirm"
                                        │
                                        ▼
                                [User Confirms]
                                        │
                                        ▼
                            [Create Patient Record]
                                        │
                                        ▼
                            [Assign Patient Number]
                                        │
                                        ▼
                            [Set Organization]
                                        │
                                        ▼
                            [Create Default Target Range (70-180 mg/dL)]
                                        │
                                        ▼
                            [Redirect to Patient About Page]
                                        │
                                        ▼
                            [Professional Can Now:]
                                ├─ Add Health Data
                                ├─ Schedule Appointments
                                ├─ Add Medications
                                ├─ Add to Practice Groups
                                └─ Add Clinical Remarks
                                        │
                                        ▼
                            [Patient Onboarding Complete! ✅]
```

### Flow B: Add Patient With Mobile App

```
[Professional Logs In]
        │
        ▼
[Navigate to Patients > List]
        │
        ▼
[Click "Add Patient From App"]
        │
        ▼
[Enter Patient's Phone Number]
    └─ e.g., "+60 12-345-6789"
        │
        ▼
[Click "Search"]
        │
        ▼
[System Searches]
    ├─ Check mobile app registration database
    ├─ Check if already added to Web DMS
    └─ Check if patient belongs to another org
        │
        ▼
[Search Result?]
    │
    ├─── Phone Not Found ──→ [Show: "No unassigned patients with that mobile number"]
    │                           │
    │                           ▼
    │                      [Try Another Number]
    │                           │
    ├─── Already Added ────→ [Show: "Patient already in system"]
    │                           ├─ Display patient card
    │                           └─ Button: "View Account" ──→ [Navigate to Patient]
    │                                                               │
    │                                                               ▼
    │                                                          [End Flow]
    │
    └─── Found & Not Added ──→ [Show Patient Details]
                                    ├─ Profile Picture
                                    ├─ Full Name
                                    ├─ Email
                                    ├─ Date of Birth
                                    ├─ Gender
                                    └─ Registration Date
                                        │
                                        ▼
                                [Request Data Sharing Approval]
                                    ├─ Send notification to patient's mobile app
                                    └─ Show "Pending Approval" status
                                        │
                                        ▼
                                [Patient Sees Notification on Mobile App]
                                        │
                                        ▼
                                [Patient Reviews Request]
                                    ├─ Organization Name
                                    ├─ Healthcare Professional Name
                                    └─ Data to be shared
                                        │
                                    ┌───┴───┐
                                    │       │
                            [Approve]   [Decline]
                                │           │
                                │           ▼
                                │   [Notify Professional]
                                │           │
                                │           ▼
                                │   [Show: "Patient declined"]
                                │           │
                                │           ▼
                                │   [End Flow]
                                │
                                ▼
                    [Link Patient to Organization]
                                │
                                ▼
                    [Sync Patient Data]
                        ├─ Health Profile
                        ├─ Health Readings
                        ├─ Meal Logs
                        └─ Activity Logs
                                │
                                ▼
                    [Assign Patient Number]
                                │
                                ▼
                    [Add to Organization]
                                │
                                ▼
                    [Notify Professional: "Patient Added"]
                                │
                                ▼
                    [Redirect to Patient About Page]
                                │
                                ▼
                    [Professional Can Access All Patient Data ✅]
```

---

## 4. 🏃 Practice Group Management Flow

```
[Professional Logs In]
        │
        ▼
[Navigate to Practice Groups > My Working Groups]
        │
        ▼
[View List of Groups]
        │
    ┌───┴───┐
    │       │
[View    [Create New Group]
Existing]    │
    │        ▼
    │   [Click "Create Practice Group"]
    │        │
    │        ▼
    │   [Fill Group Form]
    │        ├─ Title: "Ward A Diabetes Patients"
    │        ├─ Subtitle: "Morning shift monitoring"
    │        ├─ Dangerously High: 250 mg/dL
    │        └─ Dangerously Low: 60 mg/dL
    │        │
    │        ▼
    │   [System Validates]
    │        ├─ Title required?
    │        └─ Danger Low < Danger High?
    │        │
    │        ▼
    │   [Create Group]
    │        │
    ▼        ▼
[Click on Group Card]
        │
        ▼
[View Group Detail Page]
        │
        ├─ Group Info (title, subtitle, thresholds)
        ├─ Statistics (# patients, # professionals, avg BG)
        ├─ Patients Table (empty initially)
        └─ Professionals Table (empty initially)
        │
        ▼
[Add Patients to Group]
        │
        ▼
[Click "Add Patient" Button]
        │
        ▼
[Modal Opens: "Add Patient To Group"]
        │
        ├─ Top Section: "Current Patients In Group" (empty)
        └─ Bottom Section: "Available Patients"
            ├─ List all patients in organization
            ├─ Not yet in this group
            └─ Each with checkbox (unchecked)
        │
        ▼
[Select Patients]
    ├─ ☑ Ahmad bin Abdullah (P2025-0001)
    ├─ ☑ Siti Nurhaliza (P2025-0002)
    └─ ☐ Lee Wei Ming (P2025-0003)
        │
        ▼
[Click "Add" Button]
        │
        ▼
[System Updates Group Membership]
        │
        ▼
[Modal Closes]
        │
        ▼
[Group Detail Page Refreshes]
        │
        ├─ Patients Table Now Shows:
        │   ├─ Ahmad bin Abdullah
        │   └─ Siti Nurhaliza
        └─ Each patient row shows:
            ├─ Patient Number
            ├─ Name
            ├─ Age
            ├─ Latest BG Reading (color-coded)
            ├─ BG Range Status
            └─ Date Joined Group
        │
        ▼
[Add Professionals to Group]
        │
        ▼
[Click "Add Professional" Button]
        │
        ▼
[Modal Opens: "Add Professional To Group"]
        │
        ├─ Current Professionals (empty initially)
        └─ Available Professionals
            └─ List all professionals in organization
        │
        ▼
[Select Professionals]
    ├─ ☑ Dr. Sarah Lee
    └─ ☑ Nurse Fatimah
        │
        ▼
[Click "Add"]
        │
        ▼
[System Updates]
        │
        ▼
[Professionals Table Shows Members]
        │
        ▼
[Set Time Period Filter]
    └─ Select "Last 7 Days"
        │
        ▼
[View Patient Data in Table]
        │
        ├─ Each patient shows glucose readings for period
        ├─ Color-coded status indicators
        ├─ Highlights patients outside range
        └─ Average BG per patient
        │
        ▼
[Identify Problem Patients]
    └─ Ahmad: 3 red alerts (high readings)
        │
        ▼
[Click "View" Icon on Ahmad's Row]
        │
        ▼
[Patient Summary Modal Opens]
        ├─ Patient Number: P2025-0001
        ├─ Name: Ahmad bin Abdullah
        ├─ Latest BG: 220 mg/dL (RED)
        ├─ Average BG (7d): 185 mg/dL
        ├─ Time in Range: 65%
        ├─ Mini Trend Chart
        └─ Buttons:
            ├─ View Full Profile
            ├─ Add Remark
            └─ Schedule Appointment
        │
        ▼
[Professional Takes Action]
    ├─ Add Clinical Remark about high readings
    ├─ Schedule follow-up appointment
    └─ Adjust medication dosage
        │
        ▼
[Generate Group Report]
        │
        ▼
[Click "Generate Report"]
        │
        ▼
[Report Options Modal]
        ├─ Time Range: Last 30 Days
        ├─ Personnel: All Patients in Group
        └─ Format: Excel
        │
        ▼
[Click "Export"]
        │
        ▼
[System Generates Report]
        │
        ▼
[Download Starts]
        │
        ▼
[Excel File Downloaded with:]
    ├─ Patient Demographics
    ├─ Glucose Readings
    ├─ Average BG per Patient
    ├─ Time in Range Statistics
    ├─ Hyper/Hypo Event Counts
    └─ Compliance Rates
        │
        ▼
[Practice Group Management Complete! ✅]
```

---

## 5. 🩺 Health Data Management Flow

```
[Professional Logs In]
        │
        ▼
[Navigate to Patients > List]
        │
        ▼
[Search for Patient: "Ahmad bin Abdullah"]
        │
        ▼
[Click "View" on Ahmad's Row]
        │
        ▼
[Patient About Page Opens]
        │
        ▼
[Click "Health Data" Tab]
        │
        ▼
[View Health Data Screen]
        │
        ├─ Tabs: All | Glucose | BP | Weight | HbA1c | Meals | Activities
        ├─ Table showing all health readings
        └─ Filters: Date Range, Data Type, Source
        │
        ▼
[Click "Add Health Data" Button]
        │
        ▼
[Add Health Data Screen Opens]
        │
        ▼
[Data Type Selector (Large Icons)]
    ├─ 🩸 Glucose
    ├─ ❤️ Blood Pressure
    ├─ ⚖️ Weight
    ├─ 🔬 HbA1c
    ├─ 🍽️ Meal
    ├─ 🏃 Activity
    └─ 💊 Medication Taken
        │
    ┌───┴───┐
    │       │
[Select  [Select Other Type]
Glucose]    │
    │       └─→ [Type-Specific Form]
    ▼
[Glucose Entry Form]
    ├─ Glucose Value: 185 (mg/dL)
    │   └─ Real-time color coding shows "High"
    ├─ Context: "After Meal (2 hours)"
    ├─ Date: Today
    ├─ Time: 14:30
    └─ Notes: "Had nasi lemak for lunch"
        │
        ▼
[System Validates]
    ├─ Value in range (20-600)?
    ├─ Required fields filled?
    └─ Valid date/time?
        │
        ▼
[Click "Add"]
        │
        ▼
[System Checks Against Target Range]
    ├─ Patient's Target: 70-180 mg/dL
    └─ Reading: 185 mg/dL (Above target)
        │
        ▼
[System Creates Health Reading Record]
        │
        ▼
[Check if Triggers Event Alert]
    └─ 185 > 180 but < 250 (Criteria 1)
        │
        ▼
[Log to Activity Logs]
    └─ "Professional added glucose reading: 185 mg/dL for Ahmad"
        │
        ▼
[Update Patient Statistics]
    ├─ Latest reading: 185 mg/dL
    ├─ Recalculate 7-day average
    └─ Recalculate time in range %
        │
        ▼
[Show Success Message]
    └─ "✅ Glucose reading added successfully"
        │
        ▼
[Redirect to Health Data List]
        │
        ▼
[New Entry Appears at Top of Table]
    └─ Oct 24, 2025 14:30 | Glucose | 185 mg/dL 🔴 High | After Meal
        │
        ▼
[Professional Reviews Recent Readings]
        │
        ├─ Oct 24, 14:30 | 185 mg/dL (High)
        ├─ Oct 24, 08:00 | 120 mg/dL (Normal)
        ├─ Oct 23, 20:00 | 195 mg/dL (High)
        └─ Oct 23, 14:00 | 210 mg/dL (High)
        │
        ▼
[Pattern Identified: Post-meal highs]
        │
        ▼
[Professional Decides to Take Action]
        │
    ┌───┴───┐
    │       │
[Add      [Schedule
Clinical  Appointment]
Remark]      │
    │        ▼
    │   [Create Appointment]
    │        ├─ Type: "Follow-up"
    │        ├─ Date: Next week
    │        └─ Purpose: "Discuss post-meal glucose management"
    │        │
    ▼        ▼
[Navigate to Remarks Tab]
        │
        ▼
[Click "Add Remark"]
        │
        ▼
[Create Remark Form]
    ├─ Subject: "Post-meal glucose spikes"
    ├─ Type: "Important"
    ├─ Content: "Patient experiencing consistent glucose 
    │           spikes after meals, particularly lunch.
    │           Readings consistently >180 mg/dL post-meal.
    │           
    │           Dietary review needed. Consider:
    │           - Portion control
    │           - Carbohydrate timing
    │           - Pre-meal medication timing
    │           
    │           Scheduled follow-up next week."
    ├─ Action Items: "Dietary counseling
    │                 Medication timing review"
    └─ Visibility: "All Professionals"
        │
        ▼
[Click "Submit"]
        │
        ▼
[Remark Created and Visible to Team]
        │
        ▼
[Health Data Management Complete! ✅]
```

---

## 6. 🚨 Event Monitoring & Response Flow

```
[Professional Logs In]
        │
        ▼
[Navigate to Events > Hyper Events (Glucose)]
        │
        ▼
[Hyper Events Screen Opens]
        │
        ├─ Criteria Tabs: Criteria 1 | Criteria 2 | Target Range
        ├─ Search Form (empty)
        └─ Results Table (empty)
        │
        ▼
[Set Search Criteria]
        │
        ├─ Select Tab: "Criteria 1" (Very High)
        ├─ Time Period: "Last 24 hours"
        ├─ Threshold: 250 mg/dL (default)
        └─ Practice Group: "Ward A" (optional filter)
        │
        ▼
[Click "Search"]
        │
        ▼
[System Queries Database]
    └─ SELECT * FROM health_readings
        WHERE type = 'glucose'
        AND glucose_value > 250
        AND timestamp > NOW() - INTERVAL '24 hours'
        AND patient_id IN (my_organization_patients)
        ORDER BY glucose_value DESC
        │
        ▼
[Results Table Populated]
        │
        ├─ Summary Stats (top):
        │   ├─ Total Events: 8
        │   ├─ Patients Affected: 5
        │   ├─ Highest Reading: 320 mg/dL
        │   └─ Most Common Time: 2-4 PM
        │
        └─ Event Records:
            │
            ├─ Row 1:
            │   ├─ Patient: Rashid bin Omar (P2025-0045)
            │   ├─ Value: 320 mg/dL 🔴
            │   ├─ Context: After Meal
            │   ├─ Time: Oct 24, 15:30
            │   ├─ Target Range: 70-180
            │   └─ Status: ⚠️ HYPER - Criteria 1
            │
            ├─ Row 2:
            │   ├─ Patient: Ahmad bin Abdullah (P2025-0001)
            │   ├─ Value: 285 mg/dL 🔴
            │   └─ ...
            │
            └─ (6 more events)
        │
        ▼
[Identify Highest Priority Patient]
    └─ Rashid bin Omar (320 mg/dL)
        │
        ▼
[Click "View Patient" on Rashid's Row]
        │
        ▼
[Patient About Page Opens]
        │
        ├─ Patient Header:
        │   ├─ Name: Rashid bin Omar
        │   ├─ Patient #: P2025-0045
        │   ├─ Age: 58
        │   ├─ Diabetes Type: Type 2
        │   └─ Latest Reading: 320 mg/dL 🔴 (HIGH ALERT)
        │
        ├─ Quick Stats:
        │   ├─ Average BG (7d): 195 mg/dL
        │   ├─ Time in Range: 45% (Low!)
        │   └─ Total Readings: 21
        │
        └─ Quick Actions
        │
        ▼
[Click "View Trends"]
        │
        ▼
[Navigate to Logbook Tab]
        │
        ▼
[View Chart]
    └─ Last 7 days line chart shows:
        ├─ Consistent pattern of post-meal spikes
        ├─ Multiple readings >250 mg/dL
        └─ Morning readings relatively stable
        │
        ▼
[Professional Analyzes Pattern]
    └─ Problem identified: Post-meal glucose control
        │
        ▼
[Take Immediate Actions]
        │
    ┌───┴───┐
    │       │
Action 1:  Action 2:
Add Clinical Schedule
Remark      Urgent Appointment
    │           │
    │           ▼
    │       [Click "Schedule Appointment"]
    │           │
    │           ▼
    │       [Create Appointment Form]
    │           ├─ Patient: Rashid bin Omar
    │           ├─ Professional: Dr. Sarah Lee
    │           ├─ Date: Tomorrow
    │           ├─ Time: 09:00 AM
    │           ├─ Type: "Urgent Consultation"
    │           ├─ Duration: 30 minutes
    │           └─ Notes: "Critical glucose levels - 
    │                     medication adjustment needed"
    │           │
    │           ▼
    │       [System Validates]
    │           │
    │           ▼
    │       [Create Appointment]
    │           │
    │           ▼
    │       [Send Notification to Patient]
    │           │
    │           ▼
    │       [Send Email/SMS]
    │           │
    ▼           ▼
[Navigate to Remarks]
        │
        ▼
[Click "Add Remark"]
        │
        ▼
[Create Remark Form]
    ├─ Subject: "URGENT: Critical glucose levels"
    ├─ Type: "⚠️ Warning"
    ├─ Content: 
    │   "Patient presented with critically high glucose
    │    of 320 mg/dL at 15:30, post-meal.
    │    
    │    Recent pattern shows:
    │    - Consistent post-meal spikes >250 mg/dL
    │    - Poor time in range (45%)
    │    - Average BG: 195 mg/dL
    │    
    │    ACTIONS TAKEN:
    │    1. Urgent appointment scheduled for tomorrow
    │    2. Patient contacted and educated on symptoms
    │    3. Advised to monitor closely and contact if
    │       symptoms worsen
    │    
    │    NEXT STEPS:
    │    - Medication adjustment likely needed
    │    - Dietary review
    │    - Possibly increase testing frequency"
    │
    ├─ Action Items:
    │   ├─ "Review medication regimen"
    │   ├─ "Adjust insulin dosage"
    │   └─ "Refer to dietitian"
    │
    └─ Visibility: "All Professionals" (team alert)
        │
        ▼
[Click "Submit"]
        │
        ▼
[Remark Created]
        │
        ▼
[All Professionals in Organization Notified]
    └─ Dashboard shows alert badge
        │
        ▼
[Navigate Back to Events Screen]
        │
        ▼
[Mark Event as "Addressed"]
    └─ (Future feature: flag system)
        │
        ▼
[Proceed to Next Priority Patient]
    └─ Ahmad bin Abdullah (285 mg/dL)
        │
        ▼
[Repeat Process for Other High-Risk Patients]
        │
        ▼
[End of Shift Review]
        │
        ├─ 8 Hyper Events Identified
        ├─ 5 Patients Contacted
        ├─ 3 Urgent Appointments Scheduled
        └─ All Events Documented
        │
        ▼
[Event Monitoring Complete! ✅]
```

---

## 7. 📋 Appointment Management Flow

```
[Professional Logs In]
        │
        ▼
[Navigate to Appointments]
        │
        ▼
[Appointments Screen Opens]
        │
        ├─ View: Calendar (default)
        ├─ Month: October 2025
        └─ Today: Oct 24
        │
        ▼
[View Today's Schedule]
    ├─ 09:00 - Ahmad bin Abdullah (Follow-up)
    ├─ 10:00 - Siti Nurhaliza (Check-up)
    ├─ 14:00 - Lee Wei Ming (Lab Results)
    └─ 15:30 - (Free slot)
        │
        ▼
[Patient Walk-in: New Patient Needs Appointment]
        │
        ▼
[Click "Add Appointment"]
        │
        ▼
[Create Appointment Modal Opens]
        │
        ▼
[Fill Appointment Form]
    ├─ Patient: 
    │   └─ Type to search: "Rashid"
    │       └─ Dropdown shows:
    │           └─ "Rashid bin Omar (P2025-0045)"
    │               └─ Click to select
    │
    ├─ Professional:
    │   └─ Select from dropdown
    │       └─ "Dr. Sarah Lee (Doctor)"
    │
    ├─ Date: Oct 24, 2025 (Today)
    │
    ├─ Time: 
    │   └─ Check available slots...
    │       └─ Select "15:30"
    │
    ├─ Duration: 30 minutes
    │
    ├─ Type: "Consultation"
    │
    └─ Notes: "Initial consultation - new patient"
        │
        ▼
[System Validates]
    │
    ├─ Date not in past? ✓
    ├─ Check for conflicts...
    │   ├─ Professional availability? ✓
    │   └─ Patient availability? ✓
    │
    └─ All required fields? ✓
        │
        ▼
[Click "Save Changes"]
        │
        ▼
[Appointment Created]
        │
        ├─ Added to calendar
        ├─ Email sent to patient
        └─ SMS sent to patient
        │
        ▼
[Calendar Updates]
    └─ 15:30 slot now shows:
        "Rashid bin Omar - Consultation"
        │
        ▼
[Later: Time for Appointment]
        │
        ▼
[Patient Arrives]
        │
        ▼
[Professional Conducts Consultation]
        │
        ▼
[After Consultation]
        │
        ▼
[Click on Appointment in Calendar]
        │
        ▼
[Click "Edit" Icon]
        │
        ▼
[Edit Appointment Modal Opens]
        │
        ▼
[Update Appointment Status]
    ├─ Status: Change to "Completed"
    │
    ├─ Actual Duration: 35 minutes
    │
    ├─ Outcome Notes:
    │   "Patient education completed.
    │    Discussed:
    │    - Blood glucose monitoring
    │    - Medication timing
    │    - Dietary recommendations
    │    
    │    Patient receptive and understanding.
    │    Provided educational materials."
    │
    └─ Next Appointment: 
        └─ Recommend: "Follow-up in 2 weeks"
        │
        ▼
[Click "Save Changes"]
        │
        ▼
[Appointment Updated]
    └─ Calendar shows as "Completed" (green)
        │
        ▼
[Professional Checks: "Next Appointment Recommendation"]
        │
        ▼
[Click "Add Appointment" Again]
        │
        ▼
[Pre-fill with Recommended Date]
    ├─ Patient: Rashid bin Omar (already selected)
    ├─ Date: Nov 7, 2025 (2 weeks from today)
    ├─ Professional: Dr. Sarah Lee
    ├─ Time: (select available slot)
    ├─ Type: "Follow-up"
    └─ Notes: "2-week follow-up post initial consultation"
        │
        ▼
[Create Follow-up Appointment]
        │
        ▼
[Appointment Management Complete! ✅]
```

---

## 8. 💊 Medication Management Flow

```
[Professional Logs In]
        │
        ▼
[Navigate to Patient: Ahmad bin Abdullah]
        │
        ▼
[Click "Medications" Tab]
        │
        ▼
[Patient Medications Screen]
        │
        ├─ ALLERGIES section (top)
        │   └─ Currently: No allergies recorded
        │
        └─ DIAGNOSES section (below)
            └─ Currently: Empty
        │
        ▼
[Step 1: Add Allergy (if any)]
        │
        ▼
[Click "+ Add Allergy"]
        │
        ▼
[Add Allergy Modal]
    ├─ Allergy Name: "Sulfonamides"
    ├─ Type: Medication
    ├─ Severity: Moderate
    ├─ Reaction: "Rash and itching"
    └─ Date Identified: 2020-03-10
        │
        ▼
[Click "Save Changes"]
        │
        ▼
[Allergy Added]
    └─ Shows in allergies section with [X] to remove
        │
        ▼
[Step 2: Add Primary Diagnosis]
        │
        ▼
[Click "+ Add Diagnosis"]
        │
        ▼
[Add Diagnosis Modal]
    ├─ Diagnosis Name: "Type 2 Diabetes Mellitus"
    ├─ ICD-10 Code: "E11.9"
    ├─ Date Diagnosed: 2020-03-10
    ├─ Diagnosed By: "Dr. Ahmad Khalid"
    ├─ Severity: Moderate
    ├─ Status: Chronic
    └─ Notes: "Well-controlled with oral medication"
        │
        ▼
[Click "Add Diagnosis"]
        │
        ▼
[Diagnosis Card Created]
    │
    ┌────────────────────────────────┐
    │ Type 2 Diabetes [Edit] [X]     │
    │ Added: 2020-03-10              │
    │ Status: Chronic                │
    │                                │
    │ [+ Add Medication]             │
    │                                │
    │ Medications: (empty)           │
    └────────────────────────────────┘
        │
        ▼
[Step 3: Add Medication to Diagnosis]
        │
        ▼
[Click "+ Add Medication" under Diabetes card]
        │
        ▼
[Add Patient Medication Modal]
        │
        ▼
[Fill Medication Form]
    ├─ Medication:
    │   └─ Search: "metformin"
    │       └─ Select: "Metformin (Oral Hypoglycemic)"
    │
    ├─ Dosage: "500mg"
    │
    ├─ Frequency: "Twice daily"
    │
    ├─ Timing: "After meals"
    │
    ├─ Custom Times:
    │   ├─ 08:30 (after breakfast)
    │   └─ 20:00 (after dinner)
    │
    ├─ Route: "Oral"
    │
    ├─ Start Date: 2020-03-15
    │
    ├─ End Date: (leave blank - ongoing)
    │
    ├─ Instructions:
    │   "Take with food to minimize stomach upset.
    │    Swallow whole with water."
    │
    └─ Notes: "Patient tolerates well"
        │
        ▼
[Click "Save Changes"]
        │
        ▼
[Medication Added]
    │
    ┌────────────────────────────────┐
    │ Type 2 Diabetes [Edit] [X]     │
    │ Added: 2020-03-10              │
    │                                │
    │ [+ Add Medication]             │
    │                                │
    │ Medications:                   │
    │ • Metformin 500mg [Edit] [X]  │
    │   Twice daily, after meals     │
    │   Times: 08:30, 20:00          │
    └────────────────────────────────┘
        │
        ▼
[Add Second Medication]
        │
        ▼
[Click "+ Add Medication" again]
        │
        ▼
[Fill Form for Insulin]
    ├─ Medication: "Insulin Glargine (Lantus)"
    ├─ Dosage: "10 units"
    ├─ Frequency: "Once daily"
    ├─ Timing: "Bedtime"
    ├─ Custom Times: 22:00
    ├─ Route: "Injection (subcutaneous)"
    ├─ Start Date: 2023-06-01
    ├─ Instructions:
    │   "Inject in abdomen or thigh.
    │    Rotate injection sites.
    │    Store in refrigerator."
    └─ Notes: "Patient self-administers"
        │
        ▼
[Save]
        │
        ▼
[Updated Diagnosis Card]
    │
    ┌────────────────────────────────┐
    │ Type 2 Diabetes [Edit] [X]     │
    │ Added: 2020-03-10              │
    │                                │
    │ [+ Add Medication]             │
    │                                │
    │ Medications:                   │
    │ • Metformin 500mg [Edit] [X]  │
    │   Twice daily, after meals     │
    │                                │
    │ • Insulin Glargine 10u [Edit] │
    │   [X] Once daily, bedtime      │
    └────────────────────────────────┘
        │
        ▼
[Step 4: Add Secondary Diagnosis]
        │
        ▼
[Click "+ Add Diagnosis" again]
        │
        ▼
[Add: "Hypertension"]
    ├─ ICD-10: I10
    ├─ Date: 2022-01-20
    └─ Status: Chronic
        │
        ▼
[Add Medication to Hypertension]
    ├─ Medication: "Lisinopril"
    ├─ Dosage: "10mg"
    ├─ Frequency: "Once daily"
    ├─ Timing: "Morning"
    └─ Time: 08:00
        │
        ▼
[Final Patient Medications Screen Shows]
        │
    ┌─────────────────────────────────┐
    │ ALLERGIES                       │
    │ • Sulfonamides (Moderate) [X]  │
    └─────────────────────────────────┘
    
    ┌─────────────────────────────────┐
    │ DIAGNOSES                       │
    │                                 │
    │ ┌───────────────────────────┐  │
    │ │ Type 2 Diabetes [Edit] [X]│  │
    │ │ [+ Add Medication]         │  │
    │ │                            │  │
    │ │ Medications:               │  │
    │ │ • Metformin 500mg         │  │
    │ │ • Insulin Glargine 10u    │  │
    │ └───────────────────────────┘  │
    │                                 │
    │ ┌───────────────────────────┐  │
    │ │ Hypertension [Edit] [X]   │  │
    │ │ [+ Add Medication]         │  │
    │ │                            │  │
    │ │ Medications:               │  │
    │ │ • Lisinopril 10mg         │  │
    │ └───────────────────────────┘  │
    └─────────────────────────────────┘
        │
        ▼
[Medication Management Complete! ✅]
        │
        ▼
[System Benefits:]
    ├─ Medication list viewable by all professionals
    ├─ Allergy warnings shown when prescribing
    ├─ Medication schedule clear for patient
    ├─ Drug interaction checking (future feature)
    └─ Adherence tracking (future feature)
```

---

## 🔑 Key Takeaways

### Security Checkpoints in Every Flow

1. **Authentication Check**
   - Every flow starts with verified login
   - Session validation
   - Role identification

2. **Permission Check**
   - Before any create/edit/delete action
   - Backend validates role + permission
   - Returns 403 if unauthorized

3. **Organization Boundary**
   - All data filtered by organization_id
   - Cross-org access prevented
   - Super Admin exception

4. **Audit Logging**
   - Every action logged
   - Who, what, when, where
   - Changes tracked (before/after)

### User Experience Patterns

1. **Search → Select → View → Action**
   - Common pattern across modules
   - Progressive disclosure
   - Context preservation

2. **List → Detail → Edit**
   - Standard CRUD pattern
   - Breadcrumb navigation
   - Quick actions available

3. **Modal for Quick Actions**
   - Add/Edit in modals for speed
   - Full page for complex forms
   - Consistent behavior

4. **Validation → Confirmation → Success**
   - Client-side validation (instant feedback)
   - Server-side validation (security)
   - Confirmation for destructive actions
   - Success messages for completed actions

### Data Flow

1. **Frontend → Backend → Database**
   - All data through backend API
   - Never direct database access
   - Backend enforces all rules

2. **Real-time Updates**
   - Supabase real-time subscriptions
   - Automatic UI refresh
   - Optimistic updates where appropriate

3. **Caching Strategy**
   - Cache reference data (organizations, roles)
   - Refresh patient data frequently
   - Invalidate on updates

---

*Process flows for GlucoGuide Admin Platform*  
*Use these diagrams to understand user journeys and implement features correctly*
