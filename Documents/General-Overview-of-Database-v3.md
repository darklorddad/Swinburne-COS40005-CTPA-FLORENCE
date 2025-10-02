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
| note_content (TEXT) |   | glucose_before_meal      |   | value (NUMERIC(8, 2))| | min_value, max_value  |
|                     |   | glucose_after_meal       |   | measured_at        |   +-----------------------+
+---------------------+   +--------------------------+   +--------------------+
```

#### **Detailed Table Definitions**

*   **`auth.users` (Supabase Authentication)**
    *   Managed by Supabase. Its `id` (UUID) is the foreign key link to our profile tables. An admin role is stored in `raw_app_meta_data`.

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
    *   `emergency_contact_name`, `emergency_contact_relationship`, `emergency_contact_phone` (VARCHAR)
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
    *   `log_date` (DATE, NOT NULL)
    *   `meal_time` (ENUM('BREAKFAST', 'LUNCH', 'DINNER'), NOT NULL)
    *   `glucose_before_meal` (NUMERIC(8, 2))
    *   `glucose_after_meal` (NUMERIC(8, 2))
    *   *Constraint:* `UNIQUE(patient_id, log_date, meal_time)`
    *   *Constraint:* `CHECK (glucose_before_meal IS NOT NULL OR glucose_after_meal IS NOT NULL)`

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
| `POST`    | `/auth/register_admin`                            | Register new user with Admin role in `app_metadata`.                      | Authenticated Admin|
| `POST`    | `/auth/login`                                     | Log in to get an access token (JWT).                                      | Public            |
| `GET`	    | `/auth/me`                    	                | Get profile of the currently logged-in user.	                            | Authenticated     |
| **Patient (Self-Service)**                                                                                                                |
| `GET`     | `/patients/me`                                    | Get my own full patient profile.                                          | Patient           |
| `PUT`     | `/patients/me`                                    | Update my own patient profile.                                            | Patient           |
| `GET`     | `/patients/me/monitor-data`                       | Get all my monitor data.                                                  | Patient           |
| `POST`    | `/patients/me/monitor-data`                       | Add a new monitor data point for myself.                                  | Patient           |
| `GET`     | `/patients/me/daily-logs`                         | Get all my daily logs.                                                    | Patient           |
| `POST`    | `/patients/me/daily-logs`                         | Add a new daily log for myself.                                           | Patient           |
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
| `DELETE`  | `/admin/patients/{patientId}`                     | Remove any patient.                                                       | Admin             |
| `PUT`     | `/admin/patients/{patientId}/assign-clinician`    | Assign/unassign a clinician to a patient.                                 | Admin             |
| `...`     | `...`                                             | (Similar CRUD endpoints for all data types)                               | Admin             |

---

### 3. Roles & Permissions Matrix (The Rules)

| Action | Patient | Clinician | Admin | Backend Logic Notes |
| :--- | :-: | :-: | :-: | :--- |
| **User Onboarding** |
| Create Patient/Clinician | ✅ | ✅ | ✅ | Backend API handles profile creation. |
| Create Admin | ❌ | ❌ | ✅ | Admin created via secure API or manually. |
| **Account & Profile** |
| Edit own account/profile | ✅ | ✅ | ✅ | Scoped to `user_id`. |
| View profile of *assigned* patient| - | ✅ | ✅ | RLS: `patient.clinician_id == my_clinician_id`. |
| View profile of *unassigned* patient | ❌ | ❌ | ✅ | Clinician access denied. Admin has global access. |
| **Monitor Data (`patient_monitor_data`)** |
| Add/View/Edit own data | ✅ | - | - | RLS: `patient_id` must match user's profile ID. |
| View data of *assigned* patient | - | ✅ | ✅ | RLS: `SELECT` only. |
| Add/Edit data of *any* patient | ❌ | ❌ | ✅ | RLS: Admin has full `INSERT/UPDATE` access. |
| **Daily Logs (`daily_patient_logs`)** |
| Add/View/Edit own logs | ✅ | - | - | RLS: `patient_id` must match user's profile ID. |
| View logs of *assigned* patient | - | ✅ | ✅ | RLS: `SELECT` only. |
| Add/Edit logs of *any* patient | ❌ | ❌ | ✅ | RLS: Admin has full `INSERT/UPDATE` access. |
| **Thresholds (`patient_thresholds`)** |
| View own thresholds | ✅ | - | - | RLS: `SELECT` only. |
| View/Edit thresholds of *assigned* patient | - | ✅ | ✅ | RLS: `SELECT` and `UPDATE` allowed. |
| View/Edit thresholds of *any* patient | ❌ | ❌ | ✅ | RLS: Admin has full `SELECT/UPDATE` access. |
| **Clinician Notes (`clinician_notes`)** |
| See *any* notes about them | ❌ | - | - | **Privacy Rule:** Patient access is completely denied. |
| Add/View notes for *assigned* patient| - | ✅ | ✅ | RLS: `patient.clinician_id` checked. |