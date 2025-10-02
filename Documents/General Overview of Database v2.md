---

### **Project Backend & Database: The Full Overview**

This document serves as the definitive guide for the backend and database implementation. It covers the data structure, the API contract for communication, and the critical business rules for access control.

### 1. Database Schema (The Blueprint)

This is the foundational structure of your data storage, designed for a Supabase environment.

#### **Entity Relationship Diagram (ERD)**

```
+------------------+         +--------------------------+
|  organisations   |         |  auth.users (Supabase)   |
|------------------|         |--------------------------|
| id (PK)          |<--------| id (PK, UUID)            |
| name             |  (FK)   | email (UNIQUE)           |
+------------------+         +--------------------------+
                                        ^
                                (1 to 1)|
            +---------------------------+-------------------------------+
            |                                                           |
+----------------------+                                +-------------------------------+
|  clinician_profiles  |                                |        patient_profiles       |
|----------------------|                                |-------------------------------|
| id (PK)              |                                | id (PK)                       |
| user_id (FK -> users)|                                | user_id (FK -> users)         |
| name, phone_number   |                                | name, phone_number            |
| organisation_id (FK) |<-------------------------------| emergency_contact_*           |
|   **(NOT NULL)**     |                                | risk_level (ENUM)             |
+----------------------+                                | last_risk_assessment          |
                                                        | organisation_id (FK, nullable)|
                                                        | clinician_id (FK, nullable)   o--+
                                                        +-------------------------------+  |
                                                             |  |  |       |               |
                    (1 to many)                              |  |  |       |               |
        +----------------------------------------------------+  |  |       |               |
        |  (1 to many)                                          |  |       |               |
+---------------------+   +--------------------------+   +--------------------+       (1 to many)
|   clinician_notes   |   |   daily_patient_logs     |   |patient_monitor_data|   +-----------------------+
|---------------------|   |--------------------------|   |--------------------|   |  patient_thresholds   |
| id (PK)             |   | id (PK)                  |   | id (PK)            |   |-----------------------|
| patient_id (FK) ----+   | patient_id (FK) ---------+   | patient_id (FK) ---+---+ patient_id (FK)       |
| clinician_id (FK) <-+---| log_date, meal_time(ENUM)|   | data_type (ENUM)   |   | data_type (ENUM)      |
| note_content (TEXT) |   | diet_log                 |   | value (NUMREIC(8, 2))| | min_value, max_value  |
| ...                 |   | ...                      |   | measured_at        |   +-----------------------+
+---------------------+   +--------------------------+   +--------------------+
```

#### **Detailed Table Definitions**

*   **`auth.users` (Supabase Authentication)**
    *   Managed by Supabase. Its `id` (UUID) is the foreign key link to our profile tables.

*   **`organisations`**
    *   `id` (PK, INT, Auto-increment)
    *   `name` (VARCHAR, NOT NULL)

*   **`patient_profiles`** (1-to-1 with `auth.users`)
    *   `id` (PK, INT, Auto-increment)
    *   `user_id` (FK to `auth.users.id`, UNIQUE, NOT NULL)
    *   `name` (VARCHAR)
    *   `phone_number` (VARCHAR)
    *   `organisation_id` (FK to `organisations.id`, NULLABLE)
    *   `clinician_id` (FK to `clinician_profiles.id`, NULLABLE)
    *   `emergency_contact_name` (VARCHAR)
    *   `emergency_contact_relationship` (VARCHAR)
    *   `emergency_contact_phone` (VARCHAR)
    *   `risk_level` (ENUM('LOW', 'MEDIUM', 'HIGH'), DEFAULT 'LOW', NOT NULL)
    *   `last_risk_assessment` (TIMESTAMPTZ, NULLABLE)

*   **`clinician_profiles`** (1-to-1 with `auth.users`)
    *   `id` (PK, INT, Auto-increment)
    *   `user_id` (FK to `auth.users.id`, UNIQUE, NOT NULL)
    *   `name` (VARCHAR)
    *   `phone_number` (VARCHAR)
    *   `organisation_id` (FK to `organisations.id`, **NOT NULL**)

*   **`patient_monitor_data`** (Patient's recorded health metrics)
    *   `id` (PK, INT, Auto-increment)
    *   `patient_id` (FK to `patient_profiles.id`, NOT NULL)
    *   `data_type` (ENUM('BLOOD_PRESSURE_SYSTOLIC', 'BLOOD_PRESSURE_DIASTOLIC', 'GLUCOSE', 'BMI', 'HBA1C', 'ECG', 'CHOLESTEROL'), NOT NULL)
    *   `value` (NUMERIC(8, 2), NOT NULL)
    *   `measured_at` (TIMESTAMP, NOT NULL)

*   **`patient_thresholds`** (Thresholds for alerting)
    *   `id` (PK, INT, Auto-increment)
    *   `patient_id` (FK to `patient_profiles.id`, NOT NULL)
    *   `data_type` (ENUM('BLOOD_PRESSURE_SYSTOLIC', 'BLOOD_PRESSURE_DIASTOLIC', 'GLUCOSE', 'BMI', 'HBA1C', 'ECG', 'CHOLESTEROL'), NOT NULL)
    *   `min_value` (NUMERIC(8, 2), NOT NULL)
    *   `max_value` (NUMERIC(8, 2), NOT NULL)
    *   *Constraint:* `UNIQUE(patient_id, data_type)`

*   **`daily_patient_logs`**
    *   `id` (PK, INT, Auto-increment)
    *   `patient_id` (FK to `patient_profiles.id`, NOT NULL)
    *   `meal_time` (ENUM('BREAKFAST', 'LUNCH', 'DINNER'), NOT NULL)
    *   `glucose_before_meal` (NUMERIC(8, 2), NOT NULL)
    *   `glucose_after_meal` (NUMERIC(8, 2), NOT NULL)

*   **`clinician_notes`**
    *   `id` (PK, INT, Auto-increment)
    *   `patient_id` (FK to `patient_profiles.id`, NOT NULL)
    *   `clinician_id` (FK to `clinician_profiles.id`, NOT NULL)
    *   `note_content` (TEXT, NOT NULL)

---

### 2. API Endpoint Design (The Interactions)

| Method    | Endpoint                                          | Description                                                               | Who Can Access?   |
| :---      | :---                                              | :---                                                                      | :---              |
| **Authentication**                                                                                                                        |
| `POST`    | `/auth/register`                                  | Register new Patient/Clinician.                                           | Public            |
| `POST`    | `/auth/login`                                     | Log in to get an access token (JWT).                                      | Public            |
| `GET`	    | `/auth/me`                    	                | Get profile of the currently logged-in user.	                            | Authenticated     |
| **Patient (Self-Service)**                                                                                                                |
| `GET`     | `/patients/me`                                    | Get my own full patient profile.                                          | Patient           |
| `PUT`     | `/patients/me`                                    | Update my own patient profile.                                            | Patient           |
| `GET`     | `/patients/me/monitor-data`                       | Get all my monitor data (BP, Hba1c, etc.).                                | Patient           |
| `POST`    | `/patients/me/monitor-data`                       | Add a new monitor data point for myself.                                  | Patient           |
| `PUT`     | `/patients/me/monitor-data/{dataId}`              | Update one of my monitor data entries.                                    | Patient           |
| `GET`     | `/patients/me/thresholds`                         | Get my own defined health thresholds.                                     | Patient           |
| **Clinician (Management)**                                                                                                                |
| `GET`     | `/clinicians/me`                                  | Get my own clinician profile.                                             | Clinician         |
| `GET`     | `/clinicians/me/patients`                         | Get a list of all patients **assigned to me**.                            | Clinician         |
| `GET`     | `/clinicians/me/patients/{patientId}`             | Get full profile & data for **an assigned patient only**.                 | Clinician         |
| `PUT`     | `/clinicians/me/patients/{patientId}/assess-risk` | Update the risk level for **an assigned patient only**.                   | Clinician         |
| `POST`    | `/clinicians/me/patients/{patientId}/notes`       | Add a new note for **an assigned patient only**.                          | Clinician         |
| `GET`     | `/clinicians/me/patients/{patientId}/thresholds`  | Get thresholds for an assigned patient.                                   | Clinician         |
| `PUT`     | `/clinicians/me/patients/{patientId}/thresholds`  | Set/Update thresholds for an assigned patient.                            | Clinician         |
| **Admin (Global Management)**                                                                                                             |
| `GET`     | `/admin/patients`                                 | Get a list of all patients.                                               | Admin             |
| `PUT`     | `/admin/patients/{patientId}`                     | Edit any patient (including risk level).                                  | Admin             |
| `PUT`     | `/admin/patients/{patientId}/assign-clinician`    | Assign/unassign a clinician to a patient.                                 | Admin             |
| `PUT`     | `/admin/patients/{patientId}/thresholds`          | Set/Update thresholds for any patient.                                    | Admin             |

---

### 3. Roles & Permissions Matrix (The Rules)

| Action | Patient | Clinician | Admin | Backend Logic Notes |
| :--- | :-: | :-: | :-: | :--- |
| **Patient Onboarding** |
| Create Patient Profile | ✅ | - | ✅ | **CRITICAL WORKFLOW:** Upon creation of a `patient_profiles` record, the backend **MUST** immediately populate the `patient_thresholds` table with a complete set of default min/max values for every `data_type` for that new patient. |
| **Account & Profile** |
| Edit own account/profile | ✅ | ✅ | ✅ | Scope to `user_id`. Clinician cannot unset `organisation_id`. |
| **Patient Data Access** |
| Add/View/Edit own monitor data | ✅ | - | - | Patient can `INSERT`, `SELECT`, and `UPDATE` their own records. Queries must be scoped by `patient_id`. |
| View full profile of *assigned* patient| - | ✅ | ✅ | **CRITICAL CHECK:** Backend must verify `patient.clinician_id == my_clinician_id` before querying. |
| View data of *unassigned* patient | ❌ | ❌ | ✅ | Clinician access must be denied. Admin has global read access. |
| See Clinician Notes about them | ❌ | - | - | **Important Privacy Rule:** Deny access to users with 'PATIENT' role. |
| **Threshold Management** |
| View own thresholds | ✅ | - | - | Patient has read-only access to their own thresholds. |
| View thresholds of *assigned* patient | - | ✅ | ✅ | Same critical assignment check as other data access. |
| Edit thresholds of *assigned* patient | ❌ | ✅ | ✅ | Patient access is denied. The update payload must provide valid numeric values. |
| **Clinician Data Access** |
| Add/View notes for *assigned* patient| - | ✅ | ✅ | Check `patient.clinician_id` before allowing the action. |
| Assess risk of *assigned* patient | ❌ | ✅ | ✅ | Patient access denied. Clinician updates `risk_level` and `last_risk_assessment`. |
| View other Clinician data | ❌ | ❌ | ✅ | Clinicians are isolated from each other. |
| **Admin Powers** |
| View/Edit/Delete ANY Patient | - | - | ✅ | Global CRUD access. Includes changing risk level and thresholds. |
| Assign/Unassign a patient | - | - | ✅ | Admin updates the `clinician_id` field on the `patient_profiles` table. |

### 4. Notes on Data Types and Units

#### **1. GLUCOSE**
*   **Unit:** `mg/dL` (milligrams per deciliter)
*   **Description:** This measures the concentration of glucose (sugar) in the blood at a specific moment. The provided range (70-180 mg/dL) is typical for daily monitoring, often for individuals with diabetes.
*   **Critical Note:** This unit is standard in the United States. Many other parts of the world (e.g., UK, Canada, Australia) use `mmol/L` (millimoles per liter). Your app **must** be clear about which unit it uses or allow the user to select their preference.

#### **2. HBA1C**
*   **Unit:** `%` (Percentage)
*   **Description:** Hemoglobin A1c is a measure of your average blood glucose level over the past 2-3 months. It's a key indicator for long-term glucose control. A value of 7% corresponds to an estimated average glucose of ~154 mg/dL.

#### **3. BMI**
*   **Unit:** `kg/m²`
*   **Description:** Body Mass Index is a calculated value derived from a person's weight (in kilograms) and height (in meters squared). It's used as a general indicator of body fat and to categorize weight status (underweight, normal weight, overweight, obesity). While its unit is technically kg/m², the result is usually presented as a unitless number (e.g., "BMI of 22.5").

#### **4. CHOLESTEROL**
*   **Unit:** `mg/dL` (milligrams per deciliter)
*   **Description:** This likely refers to **Total Cholesterol**, which is the overall amount of cholesterol in the blood. It's a key metric for assessing cardiovascular risk.
*   **Note:** Like glucose, the alternate unit is `mmol/L`. It's also important to note that a full cholesterol panel breaks this down into LDL ("bad"), HDL ("good"), and Triglycerides, which have their own specific thresholds.

#### **5. ECG**
*   **Unit:** `bpm` (beats per minute)
*   **Description:** The value you are storing represents the **Heart Rate**, which is often derived from an ECG (Electrocardiogram). An ECG itself is a test that records the electrical activity of the heart, but the most common single-value metric taken from it for monitoring is the heart rate. The range 60-100 bpm is considered the normal resting heart rate for most adults.

#### **6. BLOOD_PRESSURE_SYSTOLIC**
*   **Unit:** `mmHg` (millimeters of mercury)
*   **Description:** This is the **"top number"** in a blood pressure reading. It measures the maximum pressure your heart exerts while beating, pushing blood through your arteries.

#### **7. BLOOD_PRESSURE_DIASTOLIC**
*   **Unit:** `mmHg` (millimeters of mercury)
*   **Description:** This is the **"bottom number"** in a blood pressure reading. It measures the amount of pressure in your arteries when the heart is resting between beats.

### **Summary Table for Quick Reference**

| `data_type` | Unit | Description |
| :--- | :--- | :--- |
| `GLUCOSE` | `mg/dL` | Instantaneous blood sugar level. |
| `HBA1C` | `%` | Average blood sugar over 2-3 months. |
| `BMI` | `kg/m²` | Index of body fat based on height and weight. |
| `CHOLESTEROL` | `mg/dL` | Total cholesterol level in the blood. |
| `ECG` | `bpm` | Heart Rate (beats per minute), derived from ECG. |
| `BLOOD_PRESSURE_SYSTOLIC`| `mmHg` | Top number: pressure when heart beats. |
| `BLOOD_PRESSURE_DIASTOLIC`| `mmHg` | Bottom number: pressure when heart rests. |