# Florence: User Manual - Admin Portal

---

## 1. Introduction
This centralised dashboard is designed exclusively for system administrators to oversee the AI-Enabled Digital Health Platform for Chronic Disease Monitoring (Florence). Through this portal, administrators can monitor high-risk patients, manage healthcare organisations and onboard clinicians.

---

## 2. Getting Started (Authentication)
Access to the Admin Portal is governed by Role-Based Access Control (RBAC). Only users provisioned with global ADMIN credentials may access these interfaces.

**To log in:**
1. The administrator navigates to the Login Portal.
2. The administrator enters the authorised administrator Email and Password.
3. Selecting *Sign In* completes the process.

    ![alt text](admin-login-screen.png)

---

## 3. The Admin Dashboard
The dashboard serves as mission control, providing a high-level overview of system and immediate clinical alerts.

### 3.1. Key Performance Index
At the top of the dashboard, four metric cards display real-time system data:
- **Total Patients:** The total number of active patient profiles.
- **High-Risk Patients:** Patients requiring manual oversight.
- **Hypoglycaemia and Hyperglycaemia:** Real-time AI-flagged alerts based on recent blood glucose vitals.

    ![alt text](KPI-dashboard.png)

### 3.2. Action Required Feed
This feed dynamically surfaces patients who need immediate attention. If a patient's vitals cross predefined safety thresholds, user or clinician set thresholds, the system will flag them here with a specific alert (e.g. Hypoglycaemic Event).

- Selecting *View All* navigates directly to the Patients directory.

    ![alt text](action-feed.png)

### 3.3. Quick Actions
The Quick Actions grid on the right side of the screen allows execution of common workflows, such as Register Patient without navigating through the sidebar menu.

![alt text](quick-actions.png)

---

## 4. Patient Management
The Patients directory allows administrators to search, filter and manage all patient records across the platform.

![alt text](patient-directory.png)

### 4.1. Searching and Filtering
1. The administrator navigates to *Patients* using the left sidebar.
2. The search bar is used to find a patient by name, email or patient ID.
3. The risk level dropdown is used to filter the table (e.g. selecting "High Risk" displays only critical patients).

    ![alt text](detailed-patient-directory.png)

### 4.2. Editing Patient Details and Risk Levels
Administrators can manually override risk assessments or update emergency contact details.

1. The administrator clicks the *Edit* icon (pencil) next to a patient in the directory.

    ![alt text](edit-patient-detail.png)

2. Inside the Admin Oversight card, Oversight Risk Level section, the administrator selects a new risk level (Low, Medium or High).

    ![alt text](change-risk-level.png)

3. Once the administrator select a risk level, the system will automatically log this action and timestamp the new assessment.

    ![alt text](updated-risk-level.png)

### 4.3. Assigning or Unassigning a Clinician
1. The administrator opens the Patient Detail screen by clicking the *Edit* icon (pencil) next to a patient in the directory.
2. The administrator locates the Assigned Clinician section inside the Admin Oversight card.
3. To assign a clinician, the clinician ID is entered.
4. Selecting *Assign* completes the process.

    ![alt text](assign-clinician.png)

5. To remove a clinician, the administrator clicks the red *Unassign* button.

    ![alt text](unassign-clinician.png)

---

## 5. Organisation Management
The Organisations module is used to onboard and manage the various healthcare facilities, clinics and hospitals utilising the platform.

![alt text](organisations.png)

### 5.1. Viewing Organisations
1. The administrator navigates to *Organisations* using the left sidebar.
2. The data table displays each facility's sector, type, state and current active user count (includes patients and clinicians).
3. The administrator clicks the *View* icon (eye) to open the split-view Organisation Detail screen, which separates "Facility Details" from "System Usage" metrics.

    ![alt text](facility-details.png)

### 5.2. Creating a New Organisation
1. From the Organisations directory, the administrator clicks the *Add Organisation* button.
2. The administrator fills in the required fields, including organisation name, sector (e.g. Public, Private, etc.) and facility type (e.g. Hospital, Clinic, etc.)
3. The 24 Hours Operation switch is toggled if applicable. (If toggled off, the facility's operating hours may be manually entered).
4. Selecting *Save Changes* completes the process.

    ![alt text](add-organisation.png)

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

    img {
        display: block;
        margin: 0 auto;
        max-height: 11cm !important;
    }

    @media print {
        hr {
            page-break-after: avoid;
            break-after: avoid;
        }
    }
</style>