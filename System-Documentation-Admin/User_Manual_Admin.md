# FLORENCE: Admin Portal User Manual

## 1. Introduction
This centralized dashboard is designed exclusively for system administrators to oversee the AI-Enabled Digital Health Platform for Chronic Disease Monitoring. Through this portal, administrators can monitor high-risk patients, manage healthcare organizations, onboard clinicians, and track system security via comprehensive audit logs.

## 2. Getting Started (Authentication)
Access to the Admin Portal is strictly governed by Role-Based Access Control (RBAC). Only users provisioned with global ADMIN credentials may access these interfaces.
To log in:
- Navigate to the Admin Login portal.
- Enter your authorized administrator Email and Password.
- Click Sign In.
![alt text](admin-login-screen.png)

## 3. The Admin Dashboard
The Dashboard serves as your mission control, providing a high-level overview of system health and immediate clinical alerts.
### 3.1 Key Performance Index
At the top of the dashboard, four metric cards display real-time system data:
- Total Patients: The total number of active patient profiles.
- High-Risk Patients: Patients requiring manual oversight.
- Hypoglycemia & Hyperglycemia: Real-time AI-flagged alerts based on recent blood glucose vitals.
![alt text](KPI-dashboard.png)

### 3.2 Action Required Feed
This feed dynamically surfaces patients who need immediate attention. If a patient's vitals cross predefined safety thresholds, the system will flag them here with a specific alert (e.g., "Hypoglycemic Event").
- Click View All to navigate directly to the Patient Directory.
![alt text](action-feed.png)

### 3.3 Quick Actions
Use the Quick Actions grid on the right side of the screen to rapidly execute common workflows, such as Register Patient without navigating through the sidebar menu.
![alt text](quick-actions.png)

## 4. Patient Management
The Patient Directory allows administrators to search, filter, and manage all patient records across the platform.
![alt text](patient-directory.png)

### 4.1 Searching & Filtering
1. Navigate to Patients using the left sidebar.
2. Use the Search Bar to find a patient by Name, Email, or Patient ID.
3. Use the Risk Level Dropdown to filter the table (e.g., select "High Risk" to only view critical patients).
![alt text](detailed-patient-directory.png)

### 4.2 Editing Patient Details & Risk Levels
Administrators can manually override risk assessments or update emergency contact details.
1. Click the Edit (Pencil) Icon next to a patient in the directory.
![alt text](edit-patient-detail.png)
2. Under the Risk Assessment section, select a new Risk Level (Low, Medium, or High).
![alt text](change-risk-level.png)
3. Click Save Changes. The system will automatically log this action and timestamp the new assessment.
![alt text](updated-risk-level.png)

### 4.3 Assigning or Unassigning a Clinician
1. Open the Patient Detail screen.
2. Locate the Assigned Clinician card.
3. To assign a doctor, enter their clinician ID.
![alt text](assign-clinician.png)
4. To remove a doctor, click the red Unassign button.
![alt text](unassign-clinician.png)

## 5. Organisation Management
The Organisations module is used to onboard and manage the various healthcare facilities, clinics, and hospitals utilising the platform.
![alt text](organisations.png)

### 5.1 Viewing Organisations
1. Navigate to Organizations using the left sidebar.
2. The data table displays each facility's Sector, Type, State, and current active user count (Patients and Clinicians).
3. Click the View (Eye) Icon to open the split-view Detail Screen, which separates "Facility Details" from "System Usage" metrics.
![alt text](facility-details.png)

### 5.2 Creating a New Organisation
1. From the Organizations Directory, click the Add Organization button.
2. Fill in the required fields, including Organization Name, Sector (e.g., Public, Private), and Facility Type (e.g., Hospital, Clinic).
3. Toggle the 24 Hours Operation switch if applicable. (If toggled off, you may manually enter the facility's operating hours).
4. Click Save Changes.
![alt text](add-organisation.png)