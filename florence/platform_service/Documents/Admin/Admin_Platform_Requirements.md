# 🏥 GlucoGuide Admin Platform - Complete Requirements Document

**Project:** GlucoGuide AI-Powered Diabetes Management Platform  
**Phase:** Admin-Side Development  
**Document Version:** 1.0  
**Last Updated:** October 26, 2025

---

## 📋 Table of Contents

1. [Role Definitions & Hierarchy](#role-definitions--hierarchy)
2. [Role Capabilities Matrix](#role-capabilities-matrix)
3. [Module-by-Module Requirements](#module-by-module-requirements)
4. [Process Flows](#process-flows)
5. [Screen Requirements](#screen-requirements)
6. [Technical Architecture](#technical-architecture)
7. [Security & Permissions](#security--permissions)
8. [Data Models](#data-models)

---

## 🎭 Role Definitions & Hierarchy

### Role Hierarchy

```
┌─────────────────────┐
│   SUPER ADMIN       │  ← Highest level
│   (System Owner)    │
└──────────┬──────────┘
           │
           │ manages all organizations
           │
┌──────────▼──────────┐
│  HOSPITAL ADMIN     │  ← Organization level
│  (Organization)     │
└──────────┬──────────┘
           │
           │ manages within organization
           │
┌──────────▼──────────┐
│   PROFESSIONAL      │  ← Individual practitioner
│   (Healthcare Pro)  │
└─────────────────────┘
```

---

### 1. **SUPER ADMIN** 🔴

**Description:**  
System-level administrator with full access across all organizations. Can create and manage organizations, users, and system-wide settings.

**Primary Responsibilities:**
- Manage all organizations
- Create and configure new organizations
- Manage users across all organizations
- View and analyze system-wide data
- Configure system settings
- Monitor system health
- Access all audit logs
- Manage roles and permissions globally

**Access Level:** **FULL SYSTEM ACCESS**

---

### 2. **HOSPITAL ADMIN** 🟡

**Description:**  
Organization-level administrator who manages their own organization's data, users, and settings. Limited to their organization only.

**Primary Responsibilities:**
- Manage users within their organization
- Manage patients within their organization
- Configure organization settings
- View organization-level reports
- Manage practice groups
- Monitor organization activity
- Cannot access other organizations

**Access Level:** **ORGANIZATION-SCOPED ACCESS**

---

### 3. **PROFESSIONAL** 🟢

**Description:**  
Healthcare professional (doctor, nurse, dietitian) who provides direct patient care. Can view and manage patients assigned to them.

**Primary Responsibilities:**
- View and manage assigned patients
- Log patient data (glucose, meals, medications, activities)
- View patient trends and analytics
- Provide recommendations
- Manage appointments
- Add clinical notes and remarks
- Limited administrative capabilities

**Access Level:** **PATIENT-SCOPED ACCESS**

---

## 📊 Role Capabilities Matrix

### Legend
- ✅ **Full Access** - Can view, create, edit, delete
- 👁️ **View Only** - Can only view
- 🔒 **No Access** - Cannot access
- ⚠️ **Restricted** - Limited access with conditions

| **Feature/Module** | **Super Admin** | **Hospital Admin** | **Professional** |
|-------------------|-----------------|-------------------|------------------|
| **ORGANIZATION MANAGEMENT** |
| View All Organizations | ✅ | 🔒 | 🔒 |
| View Own Organization | ✅ | ✅ | 👁️ |
| Create Organization | ✅ | 🔒 | 🔒 |
| Edit Any Organization | ✅ | 🔒 | 🔒 |
| Edit Own Organization | ✅ | ✅ | 🔒 |
| Delete Organization | ✅ | 🔒 | 🔒 |
| **USER MANAGEMENT** |
| View Users (All Orgs) | ✅ | 🔒 | 🔒 |
| View Users (Own Org) | ✅ | ✅ | 👁️ |
| Create User (Any Org) | ✅ | 🔒 | 🔒 |
| Create User (Own Org) | ✅ | ✅ | 🔒 |
| Edit User (Any Org) | ✅ | 🔒 | 🔒 |
| Edit User (Own Org) | ✅ | ✅ | 🔒 |
| Disable User (Any Org) | ✅ | 🔒 | 🔒 |
| Disable User (Own Org) | ✅ | ✅ | 🔒 |
| **PATIENT MANAGEMENT** |
| View Patients (All Orgs) | ✅ | 🔒 | 🔒 |
| View Patients (Own Org) | ✅ | ✅ | ✅ |
| Create Patient (External) | ✅ | 🔒 | 🔒 |
| Create Patient (Own Org) | ✅ | ✅ | ✅ |
| Edit Patient (Any Org) | ✅ | 🔒 | 🔒 |
| Edit Patient (Own Org) | ✅ | ✅ | ✅ |
| Merge Patients | ✅ | ✅ | ✅ |
| View Patient Health Data | ✅ | ✅ | ✅ |
| **PRACTICE GROUPS** |
| View Groups (All Orgs) | ✅ | 🔒 | 🔒 |
| View Groups (Own Org) | ✅ | ✅ | ⚠️ Assigned only |
| Create Practice Group | ✅ | ✅ | ✅ |
| Edit Practice Group | ✅ | ✅ | ✅ |
| Add Patients to Group | ✅ | ✅ | ✅ |
| Add Professionals to Group | ✅ | ✅ | ✅ |
| Generate Group Reports | ✅ | ✅ | ✅ |
| **ROLES & PERMISSIONS** |
| View All Roles | ✅ | ⚠️ Own org only | 🔒 |
| Create Role | ✅ | 🔒 | 🔒 |
| Edit Role | ✅ | ⚠️ Own org only | 🔒 |
| View All Permissions | ✅ | 🔒 | 🔒 |
| Create Permission | ✅ | 🔒 | 🔒 |
| Edit Permission | ✅ | 🔒 | 🔒 |
| **AUDIT LOGS** |
| View Login Logs (All) | ✅ | 🔒 | 🔒 |
| View Login Logs (Own Org) | ✅ | 👁️ | 🔒 |
| View Activity Logs (All) | ✅ | 🔒 | 🔒 |
| View Activity Logs (Own Org) | ✅ | 👁️ | 🔒 |
| View Device Logs (All) | ✅ | 🔒 | 🔒 |
| View Device Logs (Own Org) | ✅ | 👁️ | 🔒 |
| **EVENTS MONITORING** |
| View Hyper/Hypo Events (All) | ✅ | 🔒 | 🔒 |
| View Hyper/Hypo Events (Own Org) | ✅ | ✅ | ✅ |
| Set Event Criteria | ✅ | ✅ | ✅ |
| **APPOINTMENTS** |
| View Appointments (All) | ✅ | 🔒 | 🔒 |
| View Appointments (Own Org) | ✅ | ✅ | ✅ |
| Create Appointment | ✅ | ✅ | ✅ |
| Edit Appointment | ✅ | ✅ | ✅ |
| Delete Appointment | ✅ | ✅ | ✅ |
| **MEDICATIONS** |
| View Medication Library | ✅ | ✅ | ✅ |
| Add Medication to Library | ✅ | 🔒 | 🔒 |
| Edit Medication in Library | ✅ | 🔒 | 🔒 |
| Delete Medication from Library | ✅ | 🔒 | 🔒 |
| Import Medications (Bulk) | ✅ | 🔒 | 🔒 |
| **PATIENT MEDICATIONS** |
| View Patient Medications | ✅ | ✅ | ✅ |
| Add Patient Medication | ✅ | ✅ | ✅ |
| Edit Patient Medication | ✅ | ✅ | ✅ |
| Delete Patient Medication | ✅ | ✅ | ✅ |
| Manage Patient Allergies | ✅ | ✅ | ✅ |
| Manage Patient Diagnosis | ✅ | ✅ | ✅ |
| **REMARKS & NOTES** |
| View Patient Remarks | ✅ | ✅ | ✅ |
| Create Patient Remark | ✅ | ✅ | ✅ |
| Edit Patient Remark | ✅ | ✅ | ✅ |
| Delete Patient Remark | ✅ | ✅ | ✅ |
| **HEALTH DATA** |
| View Patient Health Data | ✅ | ✅ | ✅ |
| Create Health Data Entry | ✅ | ✅ | ✅ |
| Edit Health Data Entry | ✅ | ✅ | ✅ |
| Delete Health Data Entry | ✅ | ✅ | ✅ |
| Export Health Data | ✅ | ✅ | ✅ |
| **LOGBOOK & ANALYTICS** |
| View Patient Logbook | ✅ | ✅ | ✅ |
| View Glucose Trends | ✅ | ✅ | ✅ |
| View Charts & Graphs | ✅ | ✅ | ✅ |
| Generate Reports | ✅ | ✅ | ✅ |
| **AI FEATURES** |
| View AI Recommendations | ✅ | ✅ | ✅ |
| Manage Recommendation Templates | ✅ | 🔒 | 🔒 |
| Configure AI Settings | ✅ | 🔒 | 🔒 |
| **SYSTEM ADMINISTRATION** |
| View System Health | ✅ | 🔒 | 🔒 |
| Configure System Settings | ✅ | 🔒 | 🔒 |
| Manage Feature Flags | ✅ | 🔒 | 🔒 |
| View System Analytics | ✅ | 🔒 | 🔒 |

---

## 📦 Module-by-Module Requirements

### Module 1: Organization Management

#### **Super Admin View**

**Capabilities:**
- ✅ View list of all organizations across the system
- ✅ Create new organizations
- ✅ Edit any organization's details
- ✅ Configure organization settings
- ✅ Assign organization administrators
- ✅ Deactivate/activate organizations
- ✅ View organization statistics

**Key Screens:**
1. **Organizations List Screen**
2. **Create Organization Screen**
3. **Organization Detail Screen**
4. **Edit Organization Screen**

**Data to Display:**
- Organization Code (unique identifier)
- Organization Name
- Contact Number
- Address
- Custom Login URL
- Admin User Details (name, email, username)
- Number of Users
- Number of Patients
- Active Status
- Date Created
- Language Preference
- Region/Timezone
- Blood Glucose Unit Setting (mg/dL or mmol/L)
- Other Health Data Units

**Actions:**
- Create new organization
- Edit organization details
- View organization dashboard
- Deactivate organization
- View organization users
- View organization patients
- Generate organization report

---

#### **Hospital Admin View**

**Capabilities:**
- ✅ View own organization details
- ✅ Edit own organization details (if permission granted)
- ✅ Configure organization preferences
- 🔒 Cannot view other organizations
- 🔒 Cannot create organizations

**Key Screens:**
1. **My Organization Screen**
2. **Edit Organization Screen**

**Data to Display:**
- Same as Super Admin but limited to own organization

**Actions:**
- Edit organization details (if permitted)
- Configure preferences (language, units, timezone)
- View organization statistics

---

#### **Professional View**

**Capabilities:**
- 👁️ View own organization details (read-only)
- 🔒 Cannot edit organization
- 🔒 Cannot access other organizations

**Key Screens:**
1. **My Organization Screen** (read-only)

---

### Module 2: User/Account Management

#### **Super Admin View**

**Capabilities:**
- ✅ View all users across all organizations
- ✅ Create users in any organization
- ✅ Edit users in any organization
- ✅ Assign roles and permissions
- ✅ Disable/enable users
- ✅ Reset passwords
- ✅ View user activity logs

**Key Screens:**
1. **Users List Screen** (filterable by organization)
2. **Create User Screen**
3. **User Detail Screen**
4. **Edit User Screen**

**Data to Display:**
- User Profile:
  - Full Name
  - Email Address
  - Username
  - Gender
  - Phone Number
  - Organization
  - Role(s)
  - Profession Type (for professionals)
  - Account Status (Active/Disabled)
  - Date Created
  - Last Login
  - Total Logins

**Actions:**
- Create new user (any organization)
- Edit user details
- Assign/change role
- Modify permissions
- Disable/enable account
- Reset password (email link)
- View user activity
- Delete user (with confirmation)

**Form Fields (Create/Edit):**
- Full Name (required)
- Gender (required)
- Email Address (required, unique)
- Username (required, unique)
- Phone Number (country code + number)
- Organization (dropdown - all organizations)
- Role (dropdown based on organization)
- Profession Type (dropdown if professional role)
- Password (create only, auto-generated or manual)
- Permissions (checkboxes - allowed & default)

**Validation Rules:**
- Email must be valid format
- Username must be unique system-wide
- Password must meet strength requirements
- Phone number must be valid format
- All required fields must be filled

---

#### **Hospital Admin View**

**Capabilities:**
- ✅ View users in own organization
- ✅ Create users in own organization
- ✅ Edit users in own organization
- ✅ Assign roles (own org only)
- ✅ Disable/enable users (own org only)
- 🔒 Cannot create users in other organizations
- 🔒 Cannot edit users in other organizations

**Key Screens:**
1. **Users List Screen** (own organization only)
2. **Create User Screen**
3. **User Detail Screen**
4. **Edit User Screen**

**Important Security:**
- Organization field should be auto-set to own organization
- Cannot change organization during creation
- System validates organization ownership on backend
- Even if form is tampered, backend enforces organization boundary

---

#### **Professional View**

**Capabilities:**
- 👁️ View users in own organization (read-only list)
- 🔒 Cannot create users
- 🔒 Cannot edit users
- 🔒 Cannot disable users

**Key Screens:**
1. **Users List Screen** (read-only, own organization)

---

### Module 3: Patient Management

This is one of the most important modules for all roles.

#### **Super Admin View**

**Capabilities:**
- ✅ View all patients across all organizations
- ✅ Filter: "Patients with Organization" or "Patients without Organization"
- ✅ Create patient (w/o APP) - manual creation
- ✅ Add patient (w/ APP) - link existing mobile app user
- ✅ Edit patient in any organization
- ✅ Merge duplicate patients
- ✅ View patient health data
- ✅ Manage patient across organizations

**Key Screens:**
1. **Patients List Screen**
2. **Create Patient Screen** (w/o APP)
3. **Add Patient Screen** (w/ APP - phone number search)
4. **Patient About/Detail Screen**
5. **Edit Patient Screen**
6. **Merge Patients Screen**

**Patients List Screen:**

*Filters:*
- Patient With Organization
- Patient Without Organization
- Organization (dropdown)
- Diabetes Type
- Date Range (date of diagnosis)

*Search:*
- By Name
- By Patient Number
- By Phone Number
- By Email

*Table Columns:*
- Patient Number
- Full Name
- Age (calculated from DOB)
- Gender
- Diabetes Type
- Organization Name
- Last Glucose Reading
- Date of Last Reading
- Account Status (Active/Inactive)
- Date Created

*Actions per row:*
- View Patient (eye icon)
- Edit Patient (pencil icon)

---

**Create Patient (w/o APP) Screen:**

This is for patients who don't have the mobile app.

*Required Fields:*
- Full Name
- Gender (dropdown: Male, Female, Other)
- Diabetes Type (dropdown: Type 1, Type 2, Prediabetic, Gestational)
- Date of Birth (date picker)
- Patient Number (unique identifier)
- Organization (dropdown - only if "create external patient" permission)
- Date of Diagnosis (date picker)

*Optional Fields:*
- Mobile Phone Number (with country code)
- Emergency Contact Person Name
- Emergency Contact Phone Number

*Process Flow:*
1. User fills form
2. Clicks "Submit"
3. System validates:
   - All required fields filled?
   - Patient Number unique?
   - Valid formats?
4. System checks for similar accounts:
   - Match by: Name + DOB + Gender
   - If similar found:
     - Show popup with similar account details
     - Options: "Go to Account" or "Continue"
     - If Continue: Show confirmation popup
5. If no similar account:
   - Show confirmation popup with entered details
6. User confirms
7. Patient created
8. Redirect to Patient About page

**Validation Rules:**
- Patient Number must be unique across organization
- Date of Birth must be in the past
- Date of Diagnosis must be after Date of Birth
- Phone number must be valid format if provided

---

**Add Patient (w/ APP) Screen:**

This is for linking patients who already registered via mobile app.

*Process:*
1. Enter patient's phone number
2. Click "Search"
3. System checks:
   - **Case A:** Phone number not found
     - Show: "No unassigned patients with that mobile number"
   - **Case B:** Patient already added to web DMS
     - Show: Patient card with "View Account" button
   - **Case C:** Patient found and not yet added
     - Show: Patient details
     - Request approval for data sharing
     - Button: "Add Patient"

*Data to Display (when found):*
- Profile picture (if available)
- Full Name
- Email Address
- Phone Number
- Date of Birth
- Gender
- Date Registered

*Approval Process:*
- Patient must approve data sharing from mobile app
- Shows pending approval status
- Once approved, patient is linked to organization

---

**Patient About/Detail Screen:**

This is the main patient profile view.

*Sections:*

1. **Patient Header**
   - Profile Picture (if available)
   - Full Name
   - Patient Number
   - Age (calculated)
   - Gender
   - Diabetes Type
   - Organization Name
   - Edit Button (pencil icon)

2. **Personal Information Card**
   - Date of Birth
   - Phone Number
   - Email (if from app)
   - Date of Diagnosis
   - Emergency Contact Name
   - Emergency Contact Phone

3. **Health Profile Card**
   - Diabetes Type
   - Target Glucose Range (min - max mg/dL)
   - Current HbA1c (if available)
   - Date of Last HbA1c

4. **Quick Stats Grid** (2x3 or 3x2)
   - Latest Glucose Reading
     - Value + Unit
     - Timestamp
     - Color-coded status
   - Average Glucose (7 days)
   - Time in Range % (7 days)
   - Total Readings (7 days)
   - Active Days (this week)
   - Compliance Score

5. **Navigation Tabs/Cards**
   - Health Data (glucose, BP, weight, etc.)
   - Medications & Allergies
   - Appointments
   - Practice Groups
   - Remarks/Notes
   - Logbook (glucose trends)
   - Events (hypo/hyper events)

6. **Quick Actions**
   - Add Health Data
   - Schedule Appointment
   - Add Remark
   - View Full Analytics
   - Generate Report
   - Send Message (if chat feature)

---

**Edit Patient Screen:**

*Editable Fields:*
- Full Name
- Gender
- Diabetes Type
- Date of Birth
- Patient Number (careful - may break references)
- Organization (if permission granted)
- Date of Diagnosis
- Mobile Phone
- Emergency Contact Name
- Emergency Contact Phone

*Validation:*
- Same as Create Patient
- Check for duplicates on save

---

**Merge Patients Screen:**

For handling duplicate patient accounts.

*Automatic Detection:*
System automatically finds potential duplicates based on:
- Exact or similar name (fuzzy matching)
- Same phone number
- Same date of birth
- Same gender

*Merge Process:*
1. View list of potential duplicate pairs
2. Select a duplicate pair
3. Click "Start Merging"
4. Review both accounts side by side:
   - Patient A details
   - Patient B details
5. Select which data to keep for each field:
   - Full Name (radio buttons: Keep A / Keep B)
   - Date of Birth
   - Phone Number
   - Organization
   - Etc.
6. Review health data to merge:
   - Blood Glucose Entries (count shown)
   - Patient Health Data
   - Organization Health Data
   - Patient Allergies
   - Patient Diagnosis
   - Patient Medication
   - Patient Practice Groups
   - Devices (Meters)
   - Mobile Devices
   - Appointments
   - Daily Schedules
   - Weekly Testing Schedules
7. Click "Execute Merge"
8. System merges:
   - Primary account kept (you choose)
   - Secondary account data transferred
   - Secondary account deleted or marked as merged
   - All references updated
9. Redirect to merged patient's About page

*Important:*
- Cannot be undone (add confirmation)
- Creates audit log entry
- Notifies patient if they have app access

---

#### **Hospital Admin View**

**Capabilities:**
- ✅ View patients in own organization
- ✅ Create patient (own organization only)
- ✅ Edit patient (own organization only)
- ✅ Merge patients (own organization only)
- 🔒 Cannot view patients in other organizations
- 🔒 Cannot create patients in other organizations

**Security:**
- All patient operations scoped to own organization
- Backend enforces organization boundary
- Returns 403 Unauthorized if attempting to access other org patients

---

#### **Professional View**

**Capabilities:**
- ✅ View patients in own organization
- ✅ View patients assigned to them (in practice groups)
- ✅ Create patient (own organization only)
- ✅ Edit patient (own organization only)
- ✅ Merge patients (own organization only)
- 🔒 Cannot view patients in other organizations

---

### Module 4: Practice Groups

Practice groups help organize patients and professionals into teams for better care coordination.

#### **All Roles View** (with different scopes)

**Capabilities:**

*Super Admin:*
- ✅ View all practice groups in any organization
- ✅ Create practice groups in any organization
- ✅ Edit any practice group
- ✅ Add/remove patients from any group
- ✅ Add/remove professionals from any group

*Hospital Admin:*
- ✅ View practice groups in own organization
- ✅ Create practice groups in own organization
- ✅ Edit groups in own organization
- ✅ Add/remove patients (own org)
- ✅ Add/remove professionals (own org)

*Professional:*
- ✅ View practice groups they belong to
- ✅ Create practice groups in own organization
- ✅ Edit groups they manage
- ✅ Add/remove patients to their groups
- ✅ Add/remove professionals to their groups

**Key Screens:**
1. **Practice Groups List Screen** ("My Working Groups")
2. **Practice Group Detail Screen**
3. **Create Practice Group Screen**
4. **Edit Practice Group Screen**
5. **Add Patients to Group Screen**
6. **Add Professionals to Group Screen**
7. **Generate Report Screen**

---

**Practice Groups List Screen:**

*Display Cards for each group showing:*
- Group Title
- Group Subtitle
- Number of Professionals in group
- Number of Patients in group
- Average BG Level (all patients)
- Today's Hyper Events count
- Today's Hypo Events count
- % Patients with Hyper events today
- % Patients with Hypo events today

*Actions:*
- View Group Details (click on card)
- Create New Group (button)

---

**Practice Group Detail Screen:**

*Header Section:*
- Group Title
- Group Subtitle
- Edit Group Button
- Delete Group Button
- Add Patient Button
- Add Professional Button
- Generate Report Button

*Critical Glucose Range Settings:*
- Dangerously High Threshold (e.g., >250 mg/dL)
- Dangerously Low Threshold (e.g., <60 mg/dL)
- Target Range (e.g., 70-180 mg/dL)

*Statistics Cards (4 cards):*
1. Total Patients in Group
2. Total Professionals in Group
3. Average BG Level (7 days)
4. Compliance Rate

*Time Period Filter:*
- Today
- Yesterday
- Last 3 days
- Last 7 days
- Last 14 days
- Last 30 days

*Patients Table:*

Columns:
- Patient Number
- Full Name
- Age
- Account Status
- Latest BG Reading
  - Value + color-coded
  - Timestamp
- BG Range Status:
  - Green check: In range
  - Yellow warning: Near limits
  - Red alert: Dangerously high/low
- Ideal BG Range (patient-specific)
- Date Joined Group
- Actions:
  - View Summary (modal popup)
  - Remove from Group (checkbox system)

*Patient Summary Modal (on clicking View icon):*
- Patient Number
- Full Name
- Age
- Gender
- Diabetes Type
- Latest BG Reading (large display)
- Average BG (7 days)
- Time in Range %
- Total Readings (7 days)
- Last Measurement Time
- Quick View Charts:
  - 7-day glucose trend
  - Meal times vs glucose
- Buttons:
  - View Full Profile
  - Add Remark
  - Schedule Appointment

*Professionals Table:*

Columns:
- Name
- Email
- Role
- Profession Type
- Date Added
- Actions:
  - View Profile
  - Remove from Group (checkbox)

*Search & Filter:*
- Search by name, patient number
- Filter by:
  - BG status (In range, High, Low, Critical)
  - Diabetes Type
  - Age range
  - Gender

---

**Create Practice Group Screen:**

*Form Fields:*
- Group Title (required)
  - e.g., "Diabetes Care Team A"
- Group Subtitle (optional)
  - e.g., "Morning shift patients"
- Critical Glucose Ranges:
  - Dangerously High (required, number, mg/dL)
    - Default: 250
    - Min: 180
  - Dangerously Low (required, number, mg/dL)
    - Default: 60
    - Max: 70
  - Validation: Dangerously Low < Dangerously High

*Buttons:*
- Add (submit)
- Cancel

*On Submit:*
- Validates fields
- Creates group
- Redirects to group detail page

*Error Messages:*
- "This field is required" (if empty)
- "The danger low must be less than danger high" (if validation fails)

---

**Add Patients to Group Screen:**

Shown as a modal popup.

*Sections:*

1. **Current Patients In Group** (top section)
   - List of patients already in the group
   - Each with checkbox (checked)
   - Shows: Name, Patient Number, Age

2. **Available Patients** (bottom section)
   - List of patients NOT in group (from same organization)
   - Each with checkbox (unchecked)
   - Shows: Name, Patient Number, Age, Diabetes Type

*Search Bar:*
- Search by name or patient number

*Process:*
1. Check/uncheck patients
   - Check = Add to group
   - Uncheck (from current) = Remove from group
2. Click "Add" button
3. System updates group membership
4. Closes modal
5. Group detail page refreshes

---

**Add Professionals to Group Screen:**

Same as Add Patients but for professionals.

*Sections:*

1. **Current Professionals In Group**
   - List with checkboxes
   - Shows: Name, Email, Role, Profession Type

2. **Available Professionals**
   - From same organization
   - Shows: Name, Email, Role, Profession Type

---

**Edit Practice Group Screen:**

*Editable Fields:*
- Group Title
- Group Subtitle
- Dangerously High threshold
- Dangerously Low threshold

*Button:*
- Update

---

**Delete Practice Group:**

*Process:*
1. Click "Delete Group" button
2. Modal popup appears
3. User must type the group name to confirm
4. "Delete" button enabled only when name matches
5. Click Delete
6. Confirmation: "Are you sure?"
7. Group deleted
8. Redirect to Practice Groups list

*Effects of Deletion:*
- Group removed
- Patient memberships removed
- Professional memberships removed
- Group data archived (for audit)
- Cannot be undone

---

**Generate Report Screen:**

*Options:*

1. **Time Range:**
   - Last 7 days
   - Last 14 days
   - Last 30 days
   - Custom range (date pickers)

2. **Report Personnel:**
   - All Patients in Group
   - Select Specific Patients (multi-select)

3. **Report Format:**
   - Excel (.xlsx)
   - CSV (.csv)

4. **Report Contents** (checkboxes):
   - Patient Demographics
   - Glucose Readings
   - Average BG by Patient
   - Time in Range Statistics
   - Hyper/Hypo Event Counts
   - Compliance Rates
   - Meal Logs
   - Activity Logs
   - Medication Adherence
   - Appointments Attended

*Button:*
- Export

*Process:*
1. User selects options
2. Clicks Export
3. Loading indicator
4. File generated server-side
5. Download starts
6. Success message

---

### Module 5: Roles & Permissions Management

This module allows creating custom roles with specific permissions.

#### **Super Admin View**

**Capabilities:**
- ✅ View all permissions (system-wide)
- ✅ Create new permissions
- ✅ Edit permissions
- ✅ View all roles (all organizations)
- ✅ Create roles for any organization
- ✅ Edit any role
- ✅ Delete roles

**Key Screens:**
1. **Permissions List Screen**
2. **Create Permission Screen**
3. **Edit Permission Screen**
4. **Roles List Screen**
5. **Create Role Screen**
6. **Edit Role Screen**

---

**Permissions List Screen:**

*Table Columns:*
- Permission Name (e.g., "View Patients")
- Permission Code (e.g., "patient.view")
- Category (e.g., "Patient Management")
- Description
- Created Date
- Actions:
  - View Details
  - Edit

*Search:*
- By permission name or code

*Actions:*
- Create New Permission (button)

---

**Create/Edit Permission Screen:**

*Form Fields:*
- Permission Name (required)
  - e.g., "Edit External Patients"
- Permission Code (required, unique)
  - e.g., "patient.edit.external"
  - Format: module.action.scope
- Category (dropdown)
  - Patient Management
  - User Management
  - Organization Management
  - Practice Groups
  - Reports
  - System Administration
- Description (optional)
  - e.g., "Allows editing patients from other organizations"

*Validation:*
- Permission name must be unique
- Permission code must be unique
- Format: lowercase, dots, no spaces

---

**Roles List Screen:**

*Filter Options:*
- All Organizations (Super Admin only)
- Specific Organization (dropdown)

*Table Columns:*
- Role Name (e.g., "Hospital Administrator")
- Organization Name
- Number of Users with this Role
- Number of Permissions
- Created Date
- Actions:
  - View Details
  - Edit
  - Delete

*Actions:*
- Create New Role (button)

---

**Create Role Screen:**

*Form Fields:*

1. **Basic Information:**
   - Role Name (required)
     - e.g., "Diabetes Nurse"
   - Organization (dropdown, required)
     - Super Admin: Can select any organization
     - Hospital Admin: Auto-set to own organization

2. **Permissions Configuration:**

   Two types of permissions:
   
   a) **Allowed Permissions** (checkboxes)
      - Permissions that CAN be assigned to users with this role
      - Not automatically given, but available to select
   
   b) **Default Permissions** (checkboxes, subset of allowed)
      - Permissions automatically assigned when user gets this role
      - Must be subset of allowed permissions
      - Selected by default in user creation form

*Example:*
```
Role: "Junior Diabetes Nurse"

Allowed Permissions:
☑ View Patients (Internal)
☑ View Patients (External) 
☑ Edit Patients (Internal)
☐ Edit Patients (External)  ← Not allowed
☑ Add Health Data
☑ View Health Data

Default Permissions:
☑ View Patients (Internal)  ← Auto-selected
☐ View Patients (External)  ← Allowed but not default
☐ Edit Patients (Internal)  ← Allowed but not default
☑ Add Health Data           ← Auto-selected
☑ View Health Data          ← Auto-selected
```

*Permission Categories (Collapsible sections):*
- Patient Management (expand/collapse)
  - ☐ View Internal Patients
  - ☐ View External Patients
  - ☐ Create Internal Patients
  - ☐ Create External Patients
  - ☐ Edit Internal Patients
  - ☐ Edit External Patients
  - ☐ Merge Patients
  - ...
- User Management
  - ☐ View Users
  - ☐ Create Users (Own Org)
  - ☐ Edit Users (Own Org)
  - ...
- Organization Management
  - ☐ View Own Organization
  - ☐ Edit Own Organization
  - ☐ View All Organizations
  - ...
- Practice Groups
  - ☐ View Practice Groups
  - ☐ Create Practice Groups
  - ☐ Edit Practice Groups
  - ...
- Health Data
  - ☐ View Health Data
  - ☐ Add Health Data
  - ☐ Edit Health Data
  - ☐ Delete Health Data
  - ...
- Reports & Analytics
  - ☐ View Reports
  - ☐ Generate Reports
  - ☐ Export Data
  - ...
- Audit & Logs
  - ☐ View Login Logs
  - ☐ View Activity Logs
  - ☐ View Device Logs
  - ...
- System Administration
  - ☐ Manage Permissions
  - ☐ Manage Roles
  - ☐ Configure System Settings
  - ...

*Buttons:*
- Create Role
- Cancel

*Validation:*
- Role name must be unique within organization
- At least one permission must be selected
- Default permissions must be subset of allowed

---

**Edit Role Screen:**

*Super Admin:*
- Can edit all fields:
  - Role Name
  - Organization
  - Allowed Permissions
  - Default Permissions

*Hospital Admin:*
- Can only edit:
  - Default Permissions (not allowed permissions)
- Cannot change:
  - Role Name
  - Organization
  - Allowed Permissions (set by Super Admin)

*Shows warning when editing:*
"⚠️ Changing this role will affect X users who currently have this role."

*Effects of Editing:*
- Users with this role get updated permissions
- May need to log out and log back in to see changes

---

#### **Hospital Admin View**

**Capabilities:**
- ✅ View roles in own organization
- 🔒 Cannot create roles
- ✅ Edit roles (default permissions only)
- 🔒 Cannot view/edit permissions

---

#### **Professional View**

**Capabilities:**
- 🔒 No access to roles or permissions management

---

### Module 6: Audit Logs

Comprehensive logging for security, compliance, and troubleshooting.

#### **Super Admin View**

**Capabilities:**
- ✅ View all logs system-wide
- ✅ Filter by organization
- ✅ Export logs

**Types of Logs:**
1. Login Logs
2. Activity Logs
3. Device Logs
4. Patient APP Data Logs

**Key Screens:**
1. **Login Logs Screen**
2. **Activity Logs Screen**
3. **Device Logs Screen**
4. **Patient APP Data Screen**

---

**Login Logs Screen:**

Tracks all login attempts and logouts.

*Table Columns:*
- IP Address
- User Name (if successful login)
- Organization
- Log Type:
  - "Login Attempted"
  - "Login Successful"
  - "Logout"
  - "Login Failed"
- Action Status:
  - Success (green check)
  - Failed (red X)
- Failure Reason (if failed):
  - Wrong password
  - User not found
  - Account disabled
  - Wrong organization ID
- Date & Time
- Device Info (browser, OS)

*Filter Options:*
- Date Range
- Organization (Super Admin only)
- Log Type (Login/Logout)
- Status (Success/Failed)
- User (search by name)

*Search:*
- By IP Address
- By Username
- By Organization

*Actions:*
- View Details (modal)
- Export to CSV

*Login Log Detail Modal:*
- All above fields
- Session ID
- Duration (for logout events)
- Location (approximate from IP)
- Browser Details
- Operating System

---

**Activity Logs Screen:**

Tracks all CRUD operations and important actions.

*Table Columns:*
- Causer Name (who did it)
- Causer Model (role type):
  - Super Admin
  - Hospital Admin
  - Professional
- Organization
- Log Type (Action):
  - Created
  - Updated
  - Deleted
  - Viewed
  - Downloaded
  - Exported
- Subject Type (what was affected):
  - Patient
  - User
  - Organization
  - Practice Group
  - Medication
  - Appointment
  - Role
  - Permission
- Subject Name (identifier)
- Subject ID
- Date & Time
- Actions:
  - View Details

*Filter Options:*
- Date Range
- Organization
- Causer (user who did it)
- Log Type
- Subject Type

*Activity Log Detail Modal:*

Shows two columns side by side:

1. **Before Change** (if Update action):
   - All field values before the change
   - JSON format, prettified
   
2. **After Change**:
   - All field values after the change
   - Highlights what changed

*For Create Actions:*
- Shows all created fields

*For Delete Actions:*
- Shows all fields of deleted record

*Example:*
```
Causer: Dr. Sarah Johnson (Professional)
Action: Updated Patient
Subject: Ahmad bin Abdullah (P12345)
Date: 2025-10-24 14:35:22

Changes:
┌─────────────────┬──────────────┬──────────────┐
│ Field           │ Old Value    │ New Value    │
├─────────────────┼──────────────┼──────────────┤
│ Full Name       │ Ahmad bin Ab │ Ahmad bin    │
│                 │              │ Abdullah     │
│ Phone Number    │ +60123456789 │ +60129876543 │
│ Diabetes Type   │ Type 2       │ Type 2       │ (unchanged)
│ Target Range    │ 70-180       │ 70-160       │
└─────────────────┴──────────────┴──────────────┘
```

---

**Device Logs Screen:**

Tracks glucose meters and devices paired with patients.

*Table Columns:*
- Device UUID
- Serial Number
- Device Model/Type
- Firmware Version
- Mode (Active/Standby/Maintenance)
- Status:
  - Bound (linked to patient)
  - Unbound (not linked)
- Patient Name (if bound)
- Patient Number (if bound)
- Last Data Sync
- Last Updated
- Actions:
  - View Details

*Filter Options:*
- Status (Bound/Unbound)
- Device Model
- Organization
- Patient

*Device Detail Modal:*

1. **Meter Details:**
   - Device UUID
   - Serial Number
   - Model
   - Manufacturer
   - Firmware Version
   - Mode
   - Battery Level (if available)
   - Last Calibration Date

2. **Patient Details** (if bound):
   - Patient Name
   - Patient Number
   - Date Bound
   - Total Readings from This Device

3. **Recent 20 Measurements:**
   - Table showing:
     - Reading Date/Time
     - Glucose Value
     - Unit
     - Context (Before Meal, etc.)
   - Sorted by most recent first

---

**Patient APP Data Screen:**

Shows patients who have the mobile app and their device usage.

*Table Columns:*
- Patient Name
- Age
- Diabetes Type
- Organization
- Account Type:
  - "Mobile App User" (registered via app)
  - "Web Only" (created manually)
- Last Recorded BG (date/time)
- Total Readings
- App Version (if mobile user)
- Actions:
  - View Details

*Filter Options:*
- Organization
- Diabetes Type
- Account Type
- Last Active (date range)

*Patient APP Data Detail Modal:*

1. **Mobile Devices:**
   - Table of devices used to access app:
     - Device Model (e.g., iPhone 14 Pro)
     - OS Version (e.g., iOS 17.2)
     - App Version
     - Device ID
     - Last Login
     - IP Address

2. **Meter Details:**
   - If patient has paired glucose meter:
     - Serial Number
     - Model
     - Firmware Version
     - Date Paired
     - Last Sync

3. **Recent 20 Measurements:**
   - Glucose readings
   - Source (Manual entry vs Device)
   - Timestamp

---

#### **Hospital Admin View**

**Capabilities:**
- 👁️ View logs for own organization only
- 🔒 Cannot view logs from other organizations
- 🔒 Read-only access

---

#### **Professional View**

**Capabilities:**
- 🔒 No access to any logs

---

### Module 7: Events (Hyper/Hypo Monitoring)

Monitors and alerts for dangerous glucose levels.

#### **All Roles View** (with different scopes)

**Capabilities:**
- ✅ View hyper/hypo events
- ✅ Set event criteria
- ✅ Filter by date range and criteria
- ✅ Export event reports

**Key Screens:**
1. **Hyper Events Screen** (Blood Glucose)
2. **Hyper Events Screen** (Blood Pressure)
3. **Hypo Events Screen** (Blood Glucose)
4. **Hypo Events Screen** (Blood Pressure)

---

**Event Criteria:**

For each event type (Hyper BG, Hypo BG, Hyper BP, Hypo BP), there are typically 2-3 criteria levels:

*Hyper Glucose Criteria:*
- **Criteria 1:** Very High
  - Glucose > 250 mg/dL
  - Within last X hours
  
- **Criteria 2:** Dangerously High
  - Glucose > 300 mg/dL
  - Any time

- **Target Range:** Above Target
  - Glucose > patient's target max
  - Within last X days

*Hypo Glucose Criteria:*
- **Criteria 1:** Low
  - Glucose < 70 mg/dL
  - Within last X hours
  
- **Criteria 2:** Dangerously Low
  - Glucose < 60 mg/dL
  - Any time

- **Target Range:** Below Target
  - Glucose < patient's target min
  - Within last X days

---

**Hyper Event (Blood Glucose) Screen:**

*Search Form:*
- Organization (dropdown - Super Admin only)
- Practice Group (dropdown - optional)
- Criteria Type (tabs):
  - Criteria 1
  - Criteria 2
  - Target Range
- Time Period (for Criteria 1 & Target Range):
  - Last 6 hours
  - Last 12 hours
  - Last 24 hours
  - Last 3 days
  - Last 7 days
  - Custom range
- Glucose Threshold (editable):
  - For Criteria 1: Default 250 mg/dL
  - For Criteria 2: Default 300 mg/dL
  - For Target Range: Uses patient's target max
- Button: Search

*Results Table:*
- Patient Number
- Patient Name
- Age
- Diabetes Type
- Reading Value (highlighted in red)
- Unit (mg/dL or mmol/L)
- Reading Context (Before Meal, After Meal, etc.)
- Date & Time of Reading
- Patient's Target Range
- Status: "⚠️ HYPER - Criteria 1" (or 2, or Target Range)
- Actions:
  - View Patient
  - View Trends
  - Add Remark

*Summary Statistics (top of page):*
- Total Events Found
- Number of Patients Affected
- Average Glucose in Events
- Highest Reading
- Most Common Time of Day

*Visualization (optional):*
- Chart showing events by time of day
- Chart showing events by patient

---

**Process Flow:**
1. User selects criteria type (tab)
2. User sets time period and threshold
3. User clicks "Search"
4. System queries database:
   - Filters by organization/practice group
   - Filters by date range
   - Filters by glucose threshold
   - Returns matching readings
5. Results displayed in table
6. User can:
   - View patient details
   - Add clinical remarks
   - Export list

---

**Hypo Event Screens:**

Same structure as Hyper, but for low glucose.

**Blood Pressure Events:**

Similar structure, but:
- Separate criteria for Systolic and Diastolic
- Hyper BP: High blood pressure
- Hypo BP: Low blood pressure

---

### Module 8: Appointments

Manages patient appointments with healthcare professionals.

#### **All Roles View**

**Capabilities:**
- ✅ View appointments
- ✅ Create appointments
- ✅ Edit appointments
- ✅ Delete appointments
- Scope: Own organization only (Hospital Admin & Professional)

**Key Screens:**
1. **Appointments Calendar/List Screen**
2. **Create Appointment Screen** (modal)
3. **Edit Appointment Screen** (modal)

---

**Appointments Screen:**

*View Options:*
- Calendar View (month grid)
- List View (table)
- Week View
- Day View

*Calendar View:*
- Month grid with dates
- Each date shows appointments as colored blocks:
  - Blue: Upcoming
  - Green: Completed
  - Red: Missed/Cancelled
- Click date to see all appointments that day

*List View Table:*
- Patient Name
- Patient Number
- Professional Name
- Appointment Date
- Appointment Time
- Duration
- Appointment Type:
  - Consultation
  - Follow-up
  - Check-up
  - Lab Results Review
  - Education Session
- Status:
  - Scheduled (blue)
  - Completed (green)
  - Cancelled (gray)
  - No-show (red)
- Notes (preview)
- Actions:
  - Edit (pencil icon)
  - Delete (trash icon)

*Filter Options:*
- Date Range
- Professional (dropdown)
- Patient (search)
- Appointment Type
- Status

*Actions:*
- Add Appointment (button)
- Export Schedule (CSV/Excel)

---

**Create Appointment Modal:**

*Form Fields:*
- Patient (required, searchable dropdown)
  - Search by name or patient number
  - Shows: Name, Patient Number, Age
- Professional (required, dropdown)
  - List of professionals in organization
  - Shows: Name, Role, Specialty
- Appointment Date (required, date picker)
  - Cannot be in the past
- Appointment Time (required, time picker)
  - Options in 15-min intervals
- Duration (required, dropdown)
  - 15 minutes
  - 30 minutes
  - 45 minutes
  - 1 hour
  - 1.5 hours
  - 2 hours
- Appointment Type (required, dropdown)
  - Consultation
  - Follow-up
  - Check-up
  - Lab Results Review
  - Education Session
  - Other
- Notes (optional, text area)
  - Max 500 characters
  - Reminder or special instructions

*Validation:*
- Date must be today or future
- Time must be during business hours (configurable)
- Check for conflicting appointments:
  - Same professional at same time
  - Same patient at same time
- Show warning if conflict detected

*Buttons:*
- Save Changes
- Cancel

*On Save:*
- Appointment created
- Email notification sent to patient (if email available)
- SMS notification sent to patient (if phone available)
- Calendar entry added
- Success message

---

**Edit Appointment Modal:**

*Same fields as Create, but:*
- Pre-filled with existing appointment data
- Can change any field
- Can update status:
  - Scheduled
  - Completed
  - Cancelled
  - No-show

*Additional Fields (for Completed appointments):*
- Actual Duration
- Outcome Notes
- Next Appointment Recommendation

---

**Delete Appointment:**

*Process:*
1. Click delete icon
2. Confirmation popup:
   "Are you sure you want to delete this appointment?
   Patient: [Name]
   Date: [Date]
   Time: [Time]"
3. Options:
   - Delete (red button)
   - Cancel (gray button)
4. If Delete clicked:
   - Appointment deleted
   - Cancellation notification sent to patient
   - Success message

---

### Module 9: Medications

System-wide medication library management.

#### **Super Admin View**

**Capabilities:**
- ✅ View all medications in library
- ✅ Add new medications
- ✅ Edit medications
- ✅ Delete medications
- ✅ Import medications (bulk upload via Excel)

**Key Screens:**
1. **Medications Library Screen**
2. **Add Medication Screen** (modal)
3. **Edit Medication Screen** (modal)
4. **Import Medications Screen** (modal)

---

**Medications Library Screen:**

*Table Columns:*
- Medication Name
- Generic Name
- Brand Name(s)
- Medication Type:
  - Tablet
  - Capsule
  - Injection
  - Liquid
  - Inhaler
  - Topical
- Common Dosages
  - e.g., "500mg, 1000mg"
- Category:
  - Insulin
  - Oral Hypoglycemic
  - Blood Pressure
  - Cholesterol
  - Other
- Status:
  - Active (green)
  - Inactive (gray)
- Date Added
- Actions:
  - Edit (pencil icon)
  - Delete (trash icon)

*Search:*
- By medication name (generic or brand)

*Filter Options:*
- Medication Type
- Category
- Status (Active/Inactive)

*Actions:*
- Add Medication (button)
- Import Medications (button)
- Export Library (Excel/CSV)

---

**Add Medication Modal:**

*Form Fields:*
- Medication Name (required)
  - Primary name (usually generic)
- Generic Name (optional, if different from above)
- Brand Names (optional, text area)
  - One per line
  - e.g., "Glucophage\nMetformin XR"
- Medication Type (required, dropdown)
  - Tablet
  - Capsule
  - Injection
  - Liquid
  - Inhaler
  - Topical
  - Other
- Category (required, dropdown)
  - Insulin
  - Oral Hypoglycemic (Metformin, etc.)
  - Blood Pressure
  - Cholesterol
  - Antioxidant
  - Vitamin/Supplement
  - Other
- Common Dosages (text area)
  - One per line
  - e.g., "500mg\n1000mg\n850mg"
- Instructions (optional, text area)
  - Standard usage instructions
  - e.g., "Take with meals"
- Side Effects (optional, text area)
  - Common side effects
- Contraindications (optional, text area)
  - When not to use
- Status (dropdown)
  - Active
  - Inactive

*Buttons:*
- Save Changes
- Cancel

*Validation:*
- Medication name required
- Type and category required
- Check for duplicates (warn if similar name exists)

---

**Import Medications Screen:**

For bulk importing medications from Excel file.

*Process:*
1. Download template Excel file (button)
2. Fill in template:
   - Columns: Name, Generic Name, Brand Names, Type, Category, Dosages, Instructions, Side Effects, Contraindications
3. Upload filled Excel file
4. System validates:
   - Required fields present
   - Valid types and categories
   - Checks for duplicates
5. Show preview of medications to be imported:
   - Table showing all rows
   - Highlights duplicates in red
   - Shows: Name, Type, Category, Status
6. Options:
   - Skip Duplicates (checkbox)
   - Update Existing (checkbox)
7. Click "Import"
8. Progress bar
9. Success message:
   "X medications imported successfully
   Y duplicates skipped
   Z errors"

*Template Format:*
```
| Name | Generic Name | Brand Names | Type | Category | Dosages | Instructions | Side Effects | Contraindications |
```

---

#### **Hospital Admin & Professional View**

**Capabilities:**
- 👁️ View medications library (read-only)
- 🔒 Cannot add/edit/delete medications
- 🔒 Cannot import medications

**Purpose:**
- Browse medications to prescribe to patients
- Reference information

---

### Module 10: Patient Medications, Allergies & Diagnosis

Managing patient-specific medication regimens, allergies, and diagnoses.

#### **All Roles View** (with scope restrictions)

**Capabilities:**
- ✅ View patient medications, allergies, diagnoses
- ✅ Add patient medications
- ✅ Edit patient medications
- ✅ Delete patient medications
- ✅ Add/remove patient allergies
- ✅ Add/edit/delete patient diagnoses

**Key Screens:**
1. **Patient Medications Screen**
2. **Add Allergy Modal**
3. **Add Diagnosis Modal**
4. **Edit Diagnosis Modal**
5. **Add Patient Medication Modal**
6. **Edit Patient Medication Modal**

---

**Patient Medications Screen:**

Accessed from Patient About page > Medications tab.

*Layout Structure:*

```
┌─────────────────────────────────────────┐
│  ALLERGIES                              │
│  ┌─────────────────────┐                │
│  │ Penicillin [X]      │                │
│  │ Sulfa Drugs [X]     │                │
│  └─────────────────────┘                │
│  [+ Add Allergy]                        │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│  DIAGNOSES                              │
│                                         │
│  ┌───────────────────────────────┐     │
│  │ Type 2 Diabetes [Edit] [X]    │     │
│  │ Added: 2023-05-15              │     │
│  │ Notes: Well-controlled         │     │
│  │                                │     │
│  │ [+ Add Medication]             │     │
│  │                                │     │
│  │ Medications:                   │     │
│  │ • Metformin 500mg [Edit] [X]  │     │
│  │   Twice daily, with meals      │     │
│  │                                │     │
│  │ • Insulin Glargine [Edit] [X] │     │
│  │   10 units, before bed         │     │
│  └───────────────────────────────┘     │
│                                         │
│  ┌───────────────────────────────┐     │
│  │ Hypertension [Edit] [X]        │     │
│  │ Added: 2022-01-20              │     │
│  │                                │     │
│  │ [+ Add Medication]             │     │
│  │                                │     │
│  │ Medications:                   │     │
│  │ • Lisinopril 10mg [Edit] [X]  │     │
│  │   Once daily, morning          │     │
│  └───────────────────────────────┘     │
│                                         │
│  [+ Add Diagnosis]                      │
└─────────────────────────────────────────┘
```

---

**Add Allergy Modal:**

*Form Fields:*
- Allergy Name (required, text input)
  - e.g., "Penicillin", "Peanuts", "Latex"
- Allergy Type (dropdown):
  - Medication
  - Food
  - Environmental
  - Other
- Severity (dropdown):
  - Mild
  - Moderate
  - Severe
  - Life-threatening
- Reaction (text area)
  - Describe reaction symptoms
  - e.g., "Rash and itching"
- Date Identified (date picker, optional)

*Buttons:*
- Save Changes
- Cancel

*On Save:*
- Allergy added
- Shows in allergies list
- Warning badge appears on patient profile

---

**Delete Allergy:**

*Process:*
1. Click [X] next to allergy
2. Confirmation popup:
   "Remove allergy: [Allergy Name]?"
3. Click OK
4. Allergy removed

---

**Add Diagnosis Modal:**

*Form Fields:*
- Diagnosis Name (required, text input)
  - e.g., "Type 2 Diabetes Mellitus"
- ICD-10 Code (optional)
  - e.g., "E11.9"
- Date Diagnosed (date picker, required)
- Diagnosed By (text input, optional)
  - Doctor's name
- Severity (dropdown):
  - Mild
  - Moderate
  - Severe
  - Critical
- Status (dropdown):
  - Active
  - Resolved
  - Chronic
  - Under Monitoring
- Notes (text area, optional)
  - Additional clinical notes

*Buttons:*
- Add Diagnosis
- Cancel

*On Save:*
- Diagnosis card created
- Shows in diagnoses section
- Empty medications list
- Ready to add medications

---

**Edit Diagnosis Modal:**

*Same fields as Add Diagnosis*
- Can update any field
- Can change status

---

**Delete Diagnosis:**

*Process:*
1. Click [X] on diagnosis card
2. Confirmation popup:
   "⚠️ Delete diagnosis: [Diagnosis Name]?
   This will also delete all medications under this diagnosis.
   This action cannot be undone."
3. Click Delete
4. Diagnosis and all associated medications deleted

---

**Add Patient Medication Modal:**

Opened from within a diagnosis card.

*Form Fields:*
- Medication (required, searchable dropdown)
  - Search from medications library
  - Shows: Name, Type, Category
  - Displays medication details on selection
- Dosage (required, text input)
  - e.g., "500mg", "10 units", "2 tablets"
- Frequency (required, dropdown)
  - Once daily
  - Twice daily
  - Three times daily
  - Four times daily
  - Every other day
  - Once weekly
  - As needed
  - Custom
- Timing (dropdown)
  - Before meals
  - After meals
  - With meals
  - Bedtime
  - Morning
  - Afternoon
  - Evening
  - Custom times
- Custom Times (if Custom selected)
  - Time picker (multiple)
  - e.g., 08:00, 14:00, 20:00
- Route (dropdown):
  - Oral
  - Injection (subcutaneous)
  - Injection (intramuscular)
  - Injection (intravenous)
  - Topical
  - Inhaled
  - Other
- Start Date (required, date picker)
- End Date (optional, date picker)
  - Leave blank for ongoing
- Instructions (text area)
  - Special instructions
  - e.g., "Take with food", "Avoid alcohol"
- Notes (text area, optional)

*Buttons:*
- Save Changes
- Cancel

*Validation:*
- Dosage required
- Start date required
- End date must be after start date (if provided)

*On Save:*
- Medication added under diagnosis
- Shows in diagnosis card medications list

---

**Edit Patient Medication Modal:**

*Same fields as Add*
- Pre-filled with current data
- Can update any field
- Additional field:
  - Status (dropdown):
    - Active
    - Stopped
    - On Hold

---

**Delete Patient Medication:**

*Process:*
1. Click [X] next to medication
2. Confirmation popup:
   "Stop medication: [Medication Name] [Dosage]?"
3. Click OK
4. Medication removed (or marked as stopped)

---

**Empty States:**

*No Allergies:*
- "No known allergies recorded."
- [+ Add Allergy] button

*No Diagnoses:*
- "No diagnoses recorded for this patient."
- [+ Add Diagnosis] button

*No Medications (within a diagnosis):*
- "No medications prescribed for this diagnosis."
- [+ Add Medication] button

---

### Module 11: Remarks & Clinical Notes

Healthcare professionals add clinical notes and observations.

#### **All Roles View**

**Capabilities:**
- ✅ View patient remarks
- ✅ Add remarks
- ✅ Edit own remarks
- ✅ Delete own remarks
- Scope: Organization-specific

**Key Screens:**
1. **Patient Remarks Screen**
2. **Create Remark Screen**
3. **Edit Remark Screen**

---

**Patient Remarks Screen:**

Accessed from Patient About page > Remarks tab.

*Layout:*

```
[+ Add Remark] button (top right)

┌─────────────────────────────────────────┐
│ 📝 Follow-up after glucose spike       │
│ Dr. Sarah Johnson • Oct 24, 2025 14:30 │
│                                         │
│ Patient reported glucose spike to 220  │
│ mg/dL after lunch. Discussed meal      │
│ composition and portion sizes. Patient │
│ understood the impact of white rice.   │
│                                         │
│ Action: Scheduled nutrition session    │
│ with dietitian.                        │
│                                         │
│ [Edit] [Delete]                        │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ 📌 Medication adjustment               │
│ Dr. Ahmad Khalid • Oct 20, 2025 09:15  │
│                                         │
│ Increased Metformin dosage from 500mg  │
│ to 1000mg due to persistent high       │
│ morning glucose levels. Patient        │
│ tolerated previous dose well.          │
│                                         │
│ Next review: 2 weeks                   │
│                                         │
│ [Edit] [Delete]                        │
└─────────────────────────────────────────┘
```

*Remark Card Elements:*
- Icon (emoji or colored dot)
  - 📝 General note
  - 📌 Important
  - ⚠️ Warning
  - ✅ Follow-up complete
  - 🔔 Reminder
- Title/Subject
- Author Name (professional who created)
- Timestamp (date and time)
- Remark Content (text)
- Action items (if any)
- Attachments (if any) - future feature
- Edit button (if author)
- Delete button (if author)

*Filter Options:*
- Date Range
- Author (all professionals or specific)
- Type (General, Important, Warning, etc.)

*Sort Options:*
- Newest first (default)
- Oldest first
- By author

---

**Create Remark Screen:**

Full page or large modal.

*Form Fields:*
- Subject/Title (required)
  - e.g., "Follow-up after hospital visit"
- Remark Type (dropdown):
  - General Note
  - Important
  - Warning
  - Follow-up Needed
  - Reminder
  - Education Provided
- Content (required, rich text editor)
  - Large text area
  - Support for:
    - Bold, italic, underline
    - Bullet lists
    - Numbered lists
    - Links
  - Min 10 characters
  - Max 5000 characters
- Action Items (optional, text area)
  - What needs to be done
- Related Data (optional, multi-select)
  - Link to specific glucose readings
  - Link to appointments
  - Link to medications
- Visibility (dropdown):
  - All Professionals (default)
  - Assigned Practice Group Only
  - Private (only me)
- Tags (optional, chip input)
  - e.g., "diet", "medication", "compliance"

*Buttons:*
- Submit
- Cancel

*On Submit:*
- Remark created
- Author auto-set (current user)
- Timestamp auto-set (now)
- Redirect back to remarks list
- Success message

---

**Edit Remark Screen:**

*Same fields as Create*
- Pre-filled with existing data
- Shows "Last edited: [date]"
- Can only edit if author or Super Admin

---

**Delete Remark:**

*Process:*
1. Click Delete button
2. Confirmation popup:
   "Delete remark: [Subject]?
   This action cannot be undone."
3. Click Delete
4. Remark deleted
5. Success message

*Permissions:*
- Can only delete if:
  - You are the author, OR
  - You are Super Admin

---

### Module 12: Health Data Management

Comprehensive health data entry, viewing, and export.

#### **All Roles View**

**Capabilities:**
- ✅ View patient health data
- ✅ Add health data entries
- ✅ Edit health data entries
- ✅ Delete health data entries
- ✅ Export health data

**Key Screens:**
1. **Patient Health Data Screen**
2. **Add Health Data Screen**
3. **Edit Health Data Screen**

---

**Patient Health Data Screen:**

Accessed from Patient About page > Health Data tab.

*Tab Structure:*

Tabs for different data types:
- All (default)
- Glucose
- Blood Pressure
- Weight
- Heart Rate
- HbA1c
- Meals
- Activities
- Medications Taken
- Other

*Table View:*

Columns:
- Date & Time
- Data Type (icon + name)
  - 🩸 Glucose
  - ❤️ Blood Pressure
  - ⚖️ Weight
  - 💓 Heart Rate
  - 🔬 HbA1c
  - 🍽️ Meal
  - 🏃 Activity
  - 💊 Medication
- Value
  - For glucose: "120 mg/dL" (color-coded)
  - For BP: "120/80 mmHg"
  - For weight: "75.5 kg"
- Context (for glucose)
  - Before Meal
  - After Meal
  - Fasting
  - Bedtime
- Reading Source
  - Manual Entry
  - Device (meter serial)
  - Mobile App
  - Admin Entry
- Notes (preview)
- Actions:
  - Edit (pencil icon)
  - Delete (trash icon)

*Filter Options:*
- Date Range (quick filters):
  - Today
  - Last 7 days
  - Last 14 days
  - Last 30 days
  - Last 90 days
  - Custom range
- Data Type (multi-select)
- Reading Source
- Value Range (min-max)

*Sort Options:*
- Newest first (default)
- Oldest first
- By value (high to low)
- By value (low to high)

*Actions:*
- Add Health Data (button)
- Export Data (button)
  - Excel
  - CSV
  - PDF Report

---

**Add Health Data Screen:**

*Data Type Selector (top):*
- Large icons/cards for each type
- Click to select type
- Shows form for selected type

*Form for Glucose:*
- Glucose Value (required, number)
  - Min: 20
  - Max: 600
  - Unit: mg/dL or mmol/L (based on org setting)
- Context (required, dropdown)
  - Before Meal
  - After Meal (1 hour)
  - After Meal (2 hours)
  - Fasting
  - Bedtime
  - Random
- Date (required, date picker)
  - Default: today
- Time (required, time picker)
  - Default: now
- Notes (optional, text area)

*Form for Blood Pressure:*
- Systolic (required, number)
  - Min: 40
  - Max: 300
- Diastolic (required, number)
  - Min: 20
  - Max: 200
- Unit: mmHg
- Measurement Position (dropdown)
  - Sitting
  - Standing
  - Lying down
- Date & Time
- Notes

*Form for Weight:*
- Weight (required, number)
  - Min: 1
  - Max: 500
- Unit (dropdown)
  - kg
  - lbs
- Date & Time
- Notes

*Form for HbA1c:*
- HbA1c Value (required, number)
  - Min: 3.0
  - Max: 20.0
- Unit: % (percentage)
- Lab Name (optional)
- Date (required)
- Notes

*Form for Meal:*
- Meal Name (required)
- Meal Type (dropdown)
  - Breakfast
  - Lunch
  - Dinner
  - Snack
- Carbs (optional, grams)
- Protein (optional, grams)
- Fat (optional, grams)
- Calories (optional, calculated if macros entered)
- Date & Time
- Notes

*Form for Activity:*
- Activity Name (optional)
- Activity Type (dropdown)
  - Walking
  - Running
  - Cycling
  - Swimming
  - Gym
  - Yoga
  - Sports
  - Other
- Duration (required, minutes)
- Intensity (dropdown)
  - Light
  - Moderate
  - Vigorous
- Calories Burned (optional)
- Date & Time
- Notes

*Buttons:*
- Add (submit)
- Cancel

*On Submit:*
- Validates form
- Saves health data
- Updates patient's latest reading
- Triggers any alerts if thresholds breached
- Redirect back to health data list
- Success message

---

**Edit Health Data Screen:**

*Same form as Add*
- Pre-filled with existing data
- Can update any field
- Shows "Recorded by: [Name]" (who created)
- Shows "Last edited: [Date]" if edited before

---

**Delete Health Data:**

*Process:*
1. Click delete icon
2. Confirmation popup:
   "Delete health data entry?
   Type: [Glucose]
   Value: [120 mg/dL]
   Date: [Oct 24, 2025]"
3. Click Delete
4. Entry deleted
5. Success message

---

**Export Health Data:**

*Export Options Modal:*

1. **Date Range:**
   - All time
   - Last 30 days
   - Last 90 days
   - Last 6 months
   - Last year
   - Custom range

2. **Data Types** (checkboxes):
   - ☑ Glucose Readings
   - ☑ Blood Pressure
   - ☑ Weight
   - ☑ HbA1c
   - ☑ Meals
   - ☑ Activities
   - ☑ Medications Taken

3. **Format:**
   - Excel (.xlsx)
   - CSV (.csv)
   - PDF Report (formatted)

4. **Additional Options:**
   - Include notes (checkbox)
   - Include charts (PDF only)
   - Include summary statistics (PDF only)

*Button:* Export

*Process:*
1. User selects options
2. Clicks Export
3. Loading indicator
4. File generated
5. Download starts
6. Success message

---

### Module 13: Logbook & Trend Analysis

Visual representation of patient's glucose patterns and trends.

#### **All Roles View**

**Capabilities:**
- ✅ View glucose logbook
- ✅ View charts and graphs
- ✅ Analyze patterns
- ✅ Generate reports

**Key Screens:**
1. **Logbook Screen** (with 3 views)
   - Log View (list)
   - Chart View (line graph)
   - Table View (structured table)

---

**Logbook Screen:**

Accessed from Patient About page > Logbook tab.

*View Selector (tabs):*
- Log (default)
- Chart
- Table

*Time Period Selector:*
- Today
- Yesterday
- Last 7 days
- Last 14 days
- Last 30 days
- Last 90 days
- Custom range

---

**Log View:**

List format showing glucose readings chronologically.

*Layout:*

```
Oct 24, 2025 - Wednesday
┌────────────────────────────────┐
│ 08:15 AM    Before Breakfast   │
│ 110 mg/dL   🟢 Normal          │
│ Notes: Fasting reading         │
└────────────────────────────────┘
┌────────────────────────────────┐
│ 10:30 AM    After Breakfast    │
│ 145 mg/dL   🟢 Normal          │
│ Meal: Oatmeal with fruits      │
└────────────────────────────────┘
┌────────────────────────────────┐
│ 01:00 PM    Before Lunch       │
│ 105 mg/dL   🟢 Normal          │
└────────────────────────────────┘

Oct 23, 2025 - Tuesday
...
```

*Each Entry Shows:*
- Time
- Context (Before/After meal, etc.)
- Glucose Value (large)
- Status indicator (color-coded circle):
  - 🟢 Normal (70-180 mg/dL)
  - 🟡 Low (<70 mg/dL)
  - 🔴 High (>180 mg/dL)
- Associated meal (if logged)
- Notes (if any)
- Source (device icon if from meter)

---

**Chart View:**

Interactive line chart.

*Features:*

1. **Line Chart:**
   - X-axis: Time/Date
   - Y-axis: Glucose (mg/dL)
   - Data points as circles:
     - Green: Normal
     - Yellow: Low
     - Red: High
   - Reference lines:
     - Upper limit (180 mg/dL)
     - Lower limit (70 mg/dL)
     - Target range shaded green
   - Hover tooltips show:
     - Exact value
     - Time
     - Context
     - Meal info

2. **Time of Day Shading:**
   - Light yellow: Breakfast time (6-9 AM)
   - Light orange: Lunch time (12-2 PM)
   - Light blue: Dinner time (6-8 PM)

3. **Meal Markers:**
   - 🍽️ Icons on chart showing when meals logged
   - Click to see meal details

4. **Pattern Highlights:**
   - Trend line showing overall pattern
   - Areas of concern highlighted

*Statistics Panel (right side):*
- Average Glucose: 125 mg/dL
- Time in Range: 78%
- Time Above Range: 15%
- Time Below Range: 7%
- Standard Deviation: 32 mg/dL
- Highest: 220 mg/dL
- Lowest: 62 mg/dL
- Total Readings: 28

*Export Chart:*
- Button to save as PNG
- Button to generate PDF report

---

**Table View:**

Structured table format for detailed analysis.

*Table Structure:*

Rows: Each day
Columns: Time slots (before/after meals)

```
┌──────┬─────────┬─────────┬─────────┬─────────┬─────────┬─────────┬─────────┐
│ Date │  Before │  After  │  Before │  After  │  Before │  After  │ Bedtime │
│      │ B'fast  │ B'fast  │  Lunch  │  Lunch  │ Dinner  │ Dinner  │         │
├──────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│ Oct  │   110   │   145   │   105   │   168   │   98    │   182   │   120   │
│ 24   │   🟢    │   🟢    │   🟢    │   🟢    │   🟢    │   🔴    │   🟢    │
├──────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│ Oct  │   115   │   150   │   110   │   170   │   102   │   178   │   115   │
│ 23   │   🟢    │   🟢    │   🟢    │   🟢    │   🟢    │   🟢    │   🟢    │
└──────┴─────────┴─────────┴─────────┴─────────┴─────────┴─────────┴─────────┘
```

*Features:*
- Each cell shows:
  - Glucose value
  - Color-coded status
- Click cell to see details
- Hover to see time and notes
- Empty cells if no reading
- Row average at end
- Column average at bottom

*Pattern Recognition:*
- Highlights problem times (e.g., consistently high after dinner)
- Shows missing readings

*Export:*
- Excel format maintains table structure
- PDF format with formatting

---

**Additional Features:**

1. **Pattern Analysis:**
   - System identifies patterns:
     - "Glucose tends to spike after dinner"
     - "Morning readings consistently in range"
     - "Low readings often at 3 PM"
   - Shows as insight cards

2. **Compliance Tracking:**
   - Shows expected readings vs actual
   - e.g., "Expected 28 readings (4/day), logged 25 (89% compliance)"

3. **Comparison Mode:**
   - Compare this week vs last week
   - Compare this month vs last month
   - Shows improvement or deterioration

---

## 🔄 Key Process Flows

### Process Flow 1: Complete Patient Management Flow

```
[Login as Hospital Admin]
        ↓
[Navigate to Patients List]
        ↓
[Search or Filter patients]
        ↓
    ┌───┴───┐
    │       │
[Create] [View Existing Patient]
    │       │
    │       ↓
    │   [Patient About Page]
    │       │
    │       ↓
    │   [Select Module:]
    │       ├─→ Health Data
    │       ├─→ Medications
    │       ├─→ Appointments
    │       ├─→ Practice Groups
    │       ├─→ Remarks
    │       └─→ Logbook
    │       │
    │       ↓
    │   [Perform Actions]
    │       │
    ↓       ↓
[Patient Created/Updated]
```

### Process Flow 2: Practice Group Management

```
[Login as Professional]
        ↓
[Navigate to My Working Groups]
        ↓
[View list of groups I belong to]
        ↓
    ┌───┴───┐
    │       │
[Create] [Select Existing Group]
New Group    │
    │        ↓
    │    [Group Detail Page]
    │        │
    │        ↓
    │    [View Patients Table]
    │        │
    │        ├─→ Filter by time period
    │        ├─→ Search patients
    │        └─→ View patient summaries
    │        │
    │        ↓
    │    [Manage Group:]
    │        ├─→ Add patients
    │        ├─→ Remove patients
    │        ├─→ Add professionals
    │        ├─→ Remove professionals
    │        ├─→ Edit settings
    │        └─→ Generate report
    │        │
    ↓        ↓
[Group Management Complete]
```

### Process Flow 3: Event Monitoring & Response

```
[Login as Professional]
        ↓
[Navigate to Events > Hyper Events]
        ↓
[Set Search Criteria:]
    ├─→ Select Criteria Type (1, 2, or Target)
    ├─→ Set Time Period
    └─→ Set Threshold
        ↓
[Click Search]
        ↓
[View Results Table]
        ↓
[Identify High-Risk Patients]
        ↓
    ┌───┴───┐
    │       │
[View     [View
Patient]  Trends]
    │       │
    └───┬───┘
        ↓
[Take Action:]
    ├─→ Add Clinical Remark
    ├─→ Adjust Medications
    ├─→ Schedule Appointment
    └─→ Add to Priority Practice Group
        ↓
[Patient Flagged for Follow-up]
```

### Process Flow 4: Organization Setup (Super Admin)

```
[Login as Super Admin]
        ↓
[Navigate to Organizations > All Organizations]
        ↓
[Click "Create Organization"]
        ↓
[Fill Form:]
    ├─→ Organization Name
    ├─→ Custom Login URL
    ├─→ Address & Phone
    └─→ Admin Details (Name, Email, Username)
        ↓
[System Validates]
        ↓
    [Unique?] ─No─→ [Show Error] ─→ [Fix]
        │Yes                           │
        ↓                              │
[Create Organization]←─────────────────┘
        ↓
[Send Welcome Email to Admin]
        ↓
[Admin Sets Password]
        ↓
[Admin Logs In]
        ↓
[Admin Configures Organization:]
    ├─→ Settings (units, timezone, language)
    ├─→ Create Roles for organization
    ├─→ Create Users (Hospital Admin, Professionals)
    └─→ Import or Create Patients
        ↓
[Organization Setup Complete]
```

---

## 📱 Screen Requirements Summary

### Total Screens Needed: ~25-30 screens

#### Authentication (2 screens)
1. Admin Login Screen
2. Admin Forgot Password Screen

#### Dashboard (1 screen)
3. Admin Dashboard Screen

#### Organizations (4 screens)
4. Organizations List Screen
5. Create Organization Screen
6. Organization Detail Screen
7. Edit Organization Screen

#### Users (4 screens)
8. Users List Screen
9. Create User Screen
10. User Detail Screen
11. Edit User Screen

#### Patients (6 screens)
12. Patients List Screen
13. Create Patient (w/o APP) Screen
14. Add Patient (w/ APP) Screen
15. Patient About/Detail Screen
16. Edit Patient Screen
17. Merge Patients Screen

#### Practice Groups (6 screens)
18. Practice Groups List Screen
19. Practice Group Detail Screen
20. Create Practice Group Screen
21. Edit Practice Group Screen
22. Generate Report Screen (modal)
23. Manage Group Members Screen (modal)

#### Roles & Permissions (6 screens)
24. Permissions List Screen
25. Create/Edit Permission Screen
26. Roles List Screen
27. Create Role Screen
28. Edit Role Screen
29. Role Detail Screen

#### Audit Logs (4 screens)
30. Login Logs Screen
31. Activity Logs Screen
32. Device Logs Screen
33. Patient APP Data Screen

#### Events (4 screens)
34. Hyper Events (Glucose) Screen
35. Hyper Events (BP) Screen
36. Hypo Events (Glucose) Screen
37. Hypo Events (BP) Screen

#### Appointments (1 screen + modals)
38. Appointments Calendar Screen

#### Medications (2 screens + modals)
39. Medications Library Screen
40. Import Medications Screen

#### Patient Modules (5 screens)
41. Patient Medications Screen
42. Patient Remarks Screen
43. Create Remark Screen
44. Patient Health Data Screen
45. Patient Logbook Screen

#### System Settings (2 screens)
46. System Settings Screen
47. System Health Monitor Screen

---

## 🔐 Security & Permissions Implementation

### Backend Security Rules (Critical)

**1. Organization Boundary Enforcement:**

```
Rule: Users can only access data within their organization
Exception: Super Admin has full access

Implementation:
- Every database query must filter by organization_id
- Backend validates user's organization matches resource organization
- Return 403 Forbidden if cross-organization access attempted
```

**2. Role-Based Access Control:**

```
For EVERY endpoint:
1. Verify user is authenticated
2. Check user's role
3. Check required permission for action
4. If role + permission match: Allow
5. Else: Return 403 Forbidden

Example:
Endpoint: POST /api/patients
Required Permission: "patient.create"
User Role: "Hospital Admin"
Role Permissions: ["patient.create", "patient.view", ...]
Result: ✅ Allowed
```

**3. Form Tampering Protection:**

```
Issue: User modifies form data in browser before submit
Example: Hospital Admin changes organization_id to another org

Solution:
- Backend ignores organization_id from form if user is Hospital Admin
- Backend auto-sets organization_id to user's organization
- Validation: resource.organization_id == user.organization_id

Code:
if (user.role !== 'super_admin') {
    data.organization_id = user.organization_id;
}
```

**4. Audit Logging:**

```
Log ALL critical actions:
- Create, Update, Delete operations
- Login attempts (success/failure)
- Permission changes
- Data exports
- Patient data access

Log Format:
{
    user_id: "...",
    action: "patient.update",
    resource_type: "Patient",
    resource_id: "P12345",
    changes: {before: {...}, after: {...}},
    ip_address: "...",
    timestamp: "...",
    status: "success"
}
```

### Frontend Security

**1. Permission-Based UI:**

```dart
// Don't just hide buttons - disable features
Widget buildCreateButton() {
  final canCreate = user.hasPermission('patient.create');
  
  return ElevatedButton(
    onPressed: canCreate ? () => createPatient() : null,
    child: Text('Create Patient'),
  );
}

// Hide entire sections if no access
if (user.role == 'super_admin') {
  return AllOrganizationsView();
} else {
  return OwnOrganizationView();
}
```

**2. Data Validation:**

```dart
// Validate on frontend AND backend
String? validatePatientNumber(String? value) {
  if (value == null || value.isEmpty) {
    return 'Patient number is required';
  }
  if (!RegExp(r'^[A-Z0-9]+$').hasMatch(value)) {
    return 'Invalid format';
  }
  return null;
}
```

---

## 💾 Data Models

### Organization Model

```dart
class Organization {
  String id;
  String code; // Unique organization code
  String name;
  String? loginUrl; // Custom subdomain: acme.glucoguide.com
  String? address;
  String? phoneNumber;
  String language; // 'en', 'ms', 'zh'
  String timezone; // 'Asia/Kuala_Lumpur'
  String glucoseUnit; // 'mg/dL' or 'mmol/L'
  Map<String, String> otherUnits; // weight, height, etc.
  bool isActive;
  DateTime createdAt;
  DateTime updatedAt;
}
```

### User Model

```dart
class User {
  String id;
  String organizationId;
  String email;
  String username;
  String fullName;
  String gender;
  String phoneNumber;
  String role; // 'super_admin', 'hospital_admin', 'professional'
  String? professionType; // 'doctor', 'nurse', 'dietitian', etc.
  List<String> permissions;
  bool isActive;
  DateTime? lastLogin;
  DateTime createdAt;
}
```

### Patient Model

```dart
class Patient {
  String id;
  String organizationId;
  String patientNumber;
  String fullName;
  String gender;
  DateTime dateOfBirth;
  String diabetesType; // 'Type 1', 'Type 2', 'Prediabetic'
  DateTime dateOfDiagnosis;
  double? targetGlucoseMin;
  double? targetGlucoseMax;
  String? phoneNumber;
  String? email;
  String? emergencyContactName;
  String? emergencyContactPhone;
  bool hasApp; // Registered via mobile app?
  String? appUserId; // Link to app user
  bool isActive;
  DateTime createdAt;
}
```

### PracticeGroup Model

```dart
class PracticeGroup {
  String id;
  String organizationId;
  String title;
  String? subtitle;
  double dangerouslyHigh; // mg/dL
  double dangerouslyLow; // mg/dL
  List<String> patientIds;
  List<String> professionalIds;
  DateTime createdAt;
  DateTime updatedAt;
}
```

### HealthReading Model

```dart
class HealthReading {
  String id;
  String patientId;
  String type; // 'glucose', 'blood_pressure', 'weight', etc.
  
  // Glucose specific
  double? glucoseValue;
  String? glucoseUnit;
  String? glucoseContext;
  
  // Blood pressure specific
  int? systolic;
  int? diastolic;
  
  // Weight specific
  double? weight;
  String? weightUnit;
  
  // Common fields
  DateTime timestamp;
  String? notes;
  String source; // 'manual', 'device', 'app', 'admin'
  String? deviceId;
  String createdBy; // User ID who created
  DateTime createdAt;
}
```

### Role Model

```dart
class Role {
  String id;
  String organizationId;
  String name;
  List<String> allowedPermissions;
  List<String> defaultPermissions;
  int usersCount;
  DateTime createdAt;
  DateTime updatedAt;
}
```

### AuditLog Model

```dart
class AuditLog {
  String id;
  String userId;
  String? organizationId;
  String action; // 'create', 'update', 'delete', 'login', etc.
  String resourceType; // 'Patient', 'User', 'Organization', etc.
  String? resourceId;
  Map<String, dynamic>? changes; // {before: {...}, after: {...}}
  String ipAddress;
  String? userAgent;
  String status; // 'success', 'failed'
  String? errorMessage;
  DateTime timestamp;
}
```

---

## 🎯 Technical Architecture

### Frontend (Flutter)

```
lib/
├── features/
│   └── admin/
│       ├── auth/
│       │   └── screens/
│       │       └── admin_login_screen.dart
│       ├── dashboard/
│       │   ├── screens/
│       │   │   └── admin_dashboard_screen.dart
│       │   └── widgets/
│       │       ├── stats_card.dart
│       │       ├── recent_activity.dart
│       │       └── system_health.dart
│       ├── organizations/
│       │   ├── screens/
│       │   │   ├── organizations_list_screen.dart
│       │   │   ├── create_organization_screen.dart
│       │   │   ├── organization_detail_screen.dart
│       │   │   └── edit_organization_screen.dart
│       │   └── widgets/
│       │       └── organization_card.dart
│       ├── users/
│       │   ├── screens/
│       │   │   ├── users_list_screen.dart
│       │   │   ├── create_user_screen.dart
│       │   │   ├── user_detail_screen.dart
│       │   │   └── edit_user_screen.dart
│       │   └── widgets/
│       │       ├── user_card.dart
│       │       └── role_selector.dart
│       ├── patients/
│       │   ├── screens/
│       │   │   ├── patients_list_screen.dart
│       │   │   ├── create_patient_screen.dart
│       │   │   ├── add_patient_from_app_screen.dart
│       │   │   ├── patient_about_screen.dart
│       │   │   ├── edit_patient_screen.dart
│       │   │   └── merge_patients_screen.dart
│       │   └── widgets/
│       │       ├── patient_card.dart
│       │       ├── patient_stats.dart
│       │       └── patient_search.dart
│       ├── practice_groups/
│       │   ├── screens/
│       │   │   ├── groups_list_screen.dart
│       │   │   ├── group_detail_screen.dart
│       │   │   ├── create_group_screen.dart
│       │   │   └── edit_group_screen.dart
│       │   └── widgets/
│       │       ├── group_card.dart
│       │       └── group_stats.dart
│       ├── roles/
│       │   ├── screens/
│       │   │   ├── permissions_list_screen.dart
│       │   │   ├── create_permission_screen.dart
│       │   │   ├── roles_list_screen.dart
│       │   │   ├── create_role_screen.dart
│       │   │   └── edit_role_screen.dart
│       │   └── widgets/
│       │       ├── permission_checkbox.dart
│       │       └── permission_category.dart
│       ├── audit/
│       │   ├── screens/
│       │   │   ├── login_logs_screen.dart
│       │   │   ├── activity_logs_screen.dart
│       │   │   ├── device_logs_screen.dart
│       │   │   └── patient_app_data_screen.dart
│       │   └── widgets/
│       │       └── log_detail_modal.dart
│       ├── events/
│       │   ├── screens/
│       │   │   ├── hyper_glucose_screen.dart
│       │   │   ├── hypo_glucose_screen.dart
│       │   │   ├── hyper_bp_screen.dart
│       │   │   └── hypo_bp_screen.dart
│       │   └── widgets/
│       │       ├── event_criteria_form.dart
│       │       └── event_results_table.dart
│       ├── appointments/
│       │   ├── screens/
│       │   │   └── appointments_screen.dart
│       │   └── widgets/
│       │       ├── calendar_view.dart
│       │       ├── create_appointment_modal.dart
│       │       └── edit_appointment_modal.dart
│       ├── medications/
│       │   ├── screens/
│       │   │   ├── medications_library_screen.dart
│       │   │   └── import_medications_screen.dart
│       │   └── widgets/
│       │       ├── medication_card.dart
│       │       ├── add_medication_modal.dart
│       │       └── edit_medication_modal.dart
│       ├── patient_medications/
│       │   ├── screens/
│       │   │   └── patient_medications_screen.dart
│       │   └── widgets/
│       │       ├── allergy_card.dart
│       │       ├── diagnosis_card.dart
│       │       ├── medication_list.dart
│       │       ├── add_allergy_modal.dart
│       │       ├── add_diagnosis_modal.dart
│       │       ├── add_medication_modal.dart
│       │       └── edit_medication_modal.dart
│       ├── remarks/
│       │   ├── screens/
│       │   │   ├── patient_remarks_screen.dart
│       │   │   ├── create_remark_screen.dart
│       │   │   └── edit_remark_screen.dart
│       │   └── widgets/
│       │       └── remark_card.dart
│       ├── health_data/
│       │   ├── screens/
│       │   │   ├── patient_health_data_screen.dart
│       │   │   ├── add_health_data_screen.dart
│       │   │   └── edit_health_data_screen.dart
│       │   └── widgets/
│       │       ├── data_type_selector.dart
│       │       └── health_data_form.dart
│       └── logbook/
│           ├── screens/
│           │   └── patient_logbook_screen.dart
│           └── widgets/
│               ├── log_view.dart
│               ├── chart_view.dart
│               └── table_view.dart
└── shared/
    └── admin/
        └── widgets/
            ├── admin_app_bar.dart
            ├── admin_drawer.dart
            ├── data_table.dart
            ├── filter_bar.dart
            ├── search_bar.dart
            ├── pagination.dart
            └── export_button.dart
```

### Backend (Supabase)

**Database Tables:**

1. **organizations**
2. **users**
3. **patients**
4. **practice_groups**
5. **practice_group_members** (junction table)
6. **health_readings**
7. **roles**
8. **permissions**
9. **role_permissions** (junction table)
10. **user_permissions** (junction table)
11. **medications_library**
12. **patient_medications**
13. **patient_allergies**
14. **patient_diagnoses**
15. **appointments**
16. **patient_remarks**
17. **audit_logs**
18. **device_logs**

**Row Level Security (RLS) Policies:**

Example for `patients` table:
```sql
-- Super Admin: Full access
CREATE POLICY "super_admin_all_patients"
ON patients FOR ALL
TO authenticated
USING (
  auth.jwt() ->> 'role' = 'super_admin'
);

-- Hospital Admin: Own organization only
CREATE POLICY "hospital_admin_own_org_patients"
ON patients FOR ALL
TO authenticated
USING (
  organization_id = (
    SELECT organization_id 
    FROM users 
    WHERE id = auth.uid()
  )
  AND
  auth.jwt() ->> 'role' = 'hospital_admin'
);

-- Professional: Own organization only
CREATE POLICY "professional_own_org_patients"
ON patients FOR ALL
TO authenticated
USING (
  organization_id = (
    SELECT organization_id 
    FROM users 
    WHERE id = auth.uid()
  )
  AND
  auth.jwt() ->> 'role' = 'professional'
);
```

---

## ✅ Development Checklist

### Phase 1: Foundation (Week 1)
- [ ] Set up admin folder structure
- [ ] Create admin navigation/routing
- [ ] Build admin app bar & drawer
- [ ] Create reusable admin widgets (tables, filters, etc.)
- [ ] Set up role-based access control
- [ ] Implement admin authentication
- [ ] Create admin dashboard

### Phase 2: Core Modules (Week 2)
- [ ] Organizations management (Super Admin)
- [ ] Users/Account management
- [ ] Patients management
- [ ] Patient detail/about page
- [ ] Practice Groups management

### Phase 3: Clinical Features (Week 3)
- [ ] Appointments management
- [ ] Medications library
- [ ] Patient medications & allergies
- [ ] Health data management
- [ ] Patient remarks/notes
- [ ] Logbook & trends

### Phase 4: Monitoring & Reports (Week 4)
- [ ] Events monitoring (hyper/hypo)
- [ ] Audit logs (login, activity, device)
- [ ] Roles & permissions management
- [ ] Report generation
- [ ] Data export features

### Phase 5: Testing & Polish (Week 5)
- [ ] Backend security testing
- [ ] Permission enforcement testing
- [ ] Cross-organization access prevention
- [ ] UI/UX polish
- [ ] Documentation
- [ ] Deployment preparation

---

## 📝 Next Steps

1. **Review this document** and clarify any questions
2. **Prioritize features** - what to build first?
3. **Set up development environment** for admin side
4. **Create database schema** in Supabase
5. **Implement RLS policies** for security
6. **Start with Authentication & Dashboard**
7. **Build incrementally**, module by module

---

**Document End**

*This document provides complete specifications for building the GlucoGuide admin platform. Each role, feature, screen, and process flow is documented in detail for implementation.*

*For questions or clarifications, refer to the original source documents or contact the project team.*
