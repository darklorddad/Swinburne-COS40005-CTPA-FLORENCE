Of course. Here is the complete and final overview of your project's backend and database architecture. This single document consolidates all requirements and clarifications we've discussed into a comprehensive blueprint.

---

### **Project Backend & Database: The Full Overview**

This document serves as the definitive guide for the backend and database implementation. It covers the data structure, the API contract for communication, and the critical business rules for access control.

### 1. Database Schema (The Blueprint)

This is the foundational structure of your data storage.

#### **Entity Relationship Diagram (ERD)**

```
+------------------+           +----------------------+
|  organisations   |           |        users         |
|------------------|           |----------------------|
| id (PK)          |<----------| id (PK)              |
| name             |  (FK)     | email (UNIQUE)       |
| ...              |           | password_hash        |
+------------------+           | role (ENUM)          |
                               | is_verified (BOOL)   |
                               | created_at, updated_at |
                               +----------------------+
                                     |  ^
                                (1 to 1) |
             +---------------------------+---------------------------+
             |                                                       |
+----------------------+                                +------------------------+
|  clinician_profiles  |                                |    patient_profiles    |
|----------------------|                                |------------------------|
| id (PK)              |                                | id (PK)                |
| user_id (FK -> users)|                                | user_id (FK -> users)  |
| name, gender, ...    |                                | name, gender, ...      |
| organisation_id (FK) |<------------------------------| organisation_id (FK, nullable) |
|   **(NOT NULL)**     |                                | clinician_id (FK, nullable) o--+
+----------------------+                                | emergency_contact_...  |     |
                                                        +------------------------+     |
                                                               |  |  |                |
                       (1 to many)                             |  |  |                |
          +----------------------------------------------------+  |  |                |
          |  (1 to many)                                          |  |                |
+---------------------+   +--------------------------+   +--------------------+     |
|   clinician_notes   |   |   daily_patient_logs     |   |patient_monitor_data|     |
|---------------------|   |--------------------------|   |--------------------|     |
| id (PK)             |   | id (PK)                  |   | id (PK)            |     |
| patient_id (FK) ----+   | patient_id (FK) ---------+   | patient_id (FK) ---+     |
| clinician_id (FK) <-+---|                                                         |
| note_content (TEXT) |   | log_date, meal_time (ENUM) |   | data_type (ENUM)   |
| created_at          |   | diet_log, glucose_value  |   | value   |
+---------------------+   | ...                      |   | measured_at        |
                          +--------------------------+   +--------------------+
```

#### **Detailed Table Definitions**

*   **`users`** (Core identity and access control)
    *   `id` (PK, INT, Auto-increment)
    *   `email` (VARCHAR, UNIQUE, NOT NULL)
    *   `password_hash` (VARCHAR, NOT NULL) - **Store a salted hash (e.g., bcrypt), never plaintext.**
    *   `role` (ENUM('PATIENT', 'CLINICIAN', 'ADMIN'), NOT NULL)
    *   `is_verified` (BOOLEAN, DEFAULT false)
    *   `created_at`, `updated_at` (TIMESTAMPS)

*   **`organisations`**
    *   `id` (PK, INT, Auto-increment)
    *   `name` (VARCHAR, NOT NULL)

*   **`patient_profiles`** (1-to-1 with `users` where `role`='PATIENT')
    *   `id` (PK, INT, Auto-increment)
    *   `user_id` (FK to `users.id`, UNIQUE, NOT NULL)
    *   `name`, `gender`, `phone_number` (VARCHAR)
    *   `date_of_birth` (DATE)
    *   `emergency_contact_name`, `emergency_contact_phone` (VARCHAR)
    *   `organisation_id` (FK to `organisations.id`, NULLABLE)
    *   `clinician_id` (FK to `clinician_profiles.id`, NULLABLE)

*   **`clinician_profiles`** (1-to-1 with `users` where `role`='CLINICIAN')
    *   `id` (PK, INT, Auto-increment)
    *   `user_id` (FK to `users.id`, UNIQUE, NOT NULL)
    *   `name`, `gender`, `phone_number` (VARCHAR)
    *   `date_of_birth` (DATE)
    *   `organisation_id` (FK to `organisations.id`, **NOT NULL**) - **Enforces mandatory organization.**

*   **`daily_patient_logs`** (Patient's daily entries)
    *   `id` (PK, INT, Auto-increment)
    *   `patient_id` (FK to `patient_profiles.id`, NOT NULL)
    *   `log_date` (DATE, NOT NULL)
    *   `meal_time` (ENUM('BREAKFAST_BEFORE', 'BREAKFAST_AFTER', 'LUNCH_BEFORE', 'LUNCH_AFTER', 'DINNER_BEFORE', 'DINNER_AFTER'), NOT NULL)
    *   `diet_log` (TEXT)
    *   `created_at` (TIMESTAMP)

*   **`patient_monitor_data`** (Patient's periodic health metrics)
    *   `id` (PK, INT, Auto-increment)
    *   `patient_id` (FK to `patient_profiles.id`, NOT NULL)
    *   `data_type` (ENUM('BLOOD_PRESSURE', 'GLUCOSE', 'BMI', 'HBA1C', 'ECG', 'CHOLESTEROL'), NOT NULL)
    *   `value` (VARCHAR, NOT NULL)
    *   `measured_at` (TIMESTAMP, NOT NULL)

*   **`clinician_notes`** (Private notes from clinicians about patients)
    *   `id` (PK, INT, Auto-increment)
    *   `patient_id` (FK to `patient_profiles.id`, NOT NULL)
    *   `clinician_id` (FK to `clinician_profiles.id`, NOT NULL) - Tracks the author.
    *   `note_content` (TEXT, NOT NULL)
    *   `created_at`, `updated_at` (TIMESTAMPS)

---

### 2. API Endpoint Design (The Interactions)

This RESTful API defines how clients interact with the backend.

| Method    | Endpoint                                          | Description                                                               | Who Can Access?   |
| :---      | :---                                              | :---                                                                      | :---              |
| **Authentication**                                                                                                                        |
| `POST`    | `/auth/register`                                  | Register new Patient/Clinician. Clinician must provide `organisation_id`. | Public            |
| `POST`    | `/auth/login`                                     | Log in to get an access token (JWT).                                      | Public            |
| `GET`     | `/auth/me`                                        | Get profile of the currently logged-in user.                              | Authenticated     |
| **Patient (Self-Service)**                                                                                                                |
| `GET`     | `/patients/me`                                    | Get my own full patient profile.                                          | Patient           |
| `PUT`     | `/patients/me`                                    | Update my own patient profile.                                            | Patient |
| `GET`     | `/patients/me/daily-logs`                         | Get all **my own** daily diet/glucose logs.                               | Patient |
| `POST`    |`/patients/me/daily-logs`                          | Add a new daily log for myself.                                           | Patient |
| `GET`     | `/patients/me/monitor-data`                       | Get all my monitor data (BP, Hba1c, etc.).                                | Patient |
| `POST`    | `/patients/me/monitor-data`                       | Add a new monitor data point for myself.                                  | Patient |
| **Clinician (Management)** |
| `GET`     | `/clinicians/me`                                  | Get my own clinician profile, including organization details.             | Clinician |
| `PUT`     | `/clinicians/me`                                  | Update my own clinician profile. Cannot set `organisation_id` to null.    | Clinician |
| `GET`     | `/clinicians/me/patients`                         | Get a list of all patients **assigned to me**.                            | Clinician |
| `GET`     | `/clinicians/me/patients/{patientId}`             | Get full profile & data for **an assigned patient only**.                 | Clinician |
| `GET`     | `/clinicians/me/patients/{patientId}/daily-logs`  | Get all daily logs for **an assigned patient only**.                      | Clinician |
| `GET`     | `/clinicians/me/patients/{patientId}/notes`       | Get clinician notes for **an assigned patient only**.                     | Clinician |
| `POST`    | `/clinicians/me/patients/{patientId}/notes`       | Add a new note for **an assigned patient only**.                          | Clinician |
| **Admin (Global Management)**                                                                                                             |
| `GET`     | `/admin/users/unverified`                         | Get list of users waiting for verification.                               | Admin |
| `POST`    | `/admin/users/{userId}/verify`                    | Verify a user account.                                                    | Admin |
| `GET`     | `/admin/patients`                                 | Get a list of all patients.                                               | Admin |
| `POST`    | `/admin/patients`                                 | Create a new patient.                                                     | Admin |
| `GET`     | `/admin/patients/{patientId}`                     | Get full data for any patient.                                            | Admin |
| `PUT`     | `/admin/patients/{patientId}`                     | Edit any patient.                                                         | Admin |
| `DELETE`  | `/admin/patients/{patientId}`                     | Remove any patient.                                                       | Admin |
| `PUT`     | `/admin/patients/{patientId}/assign-clinician`    | Assign/unassign a clinician to a patient.                                 | Admin |
| `GET`     | `/admin/clinicians`                               | Get a list of all clinicians.                                             | Admin |
| `...`     | `...`                                             | (Similar CRUD endpoints for Clinicians & Organisations)                   | Admin |

---

### 3. Roles & Permissions Matrix (The Rules)

This matrix dictates the business logic your backend code must enforce.

| Action | Patient | Clinician | Admin | Backend Logic Notes |
| :--- | :-: | :-: | :-: | :--- |
| **Account & Profile** |
| Register self | ✅ | ✅ | ✅ | **Clinician registration payload MUST include a valid `organisation_id`.** |
| Edit own account/profile | ✅ | ✅ | ✅ | Scope to `user_id`. Clinician cannot unset `organisation_id`. |
| View assigned Organisation | ✅ | ✅ | ✅ | Join profile with `organisations` table. |
| View assigned Clinician profile | ✅ | - | - | Patient can view profile of `clinician_id` on their record. |
| **Patient Data Access** |
| Add/View/Edit own data/logs | ✅ | - | - | Queries must be scoped: `WHERE patient_id = my_profile_id`. |
| **View diet/glucose logs of *assigned* patient** | - | ✅ | ✅ | **CRITICAL CHECK:** Backend must verify `patient.clinician_id == my_clinician_id` before querying logs. |
| View full profile of *assigned* patient| - | ✅ | ✅ | Same critical check as above. |
| View data of *unassigned* patient | ❌ | ❌ | ✅ | Clinician access must be denied. Admin has global read access. |
| See Clinician Notes about them | ❌ | - | - | **Important Privacy Rule:** Deny access to users with 'PATIENT' role. |
| **Clinician Data Access** |
| Add/View notes for *assigned* patient| - | ✅ | ✅ | Check `patient.clinician_id` before allowing the action. |
| View other Clinician data | ❌ | ❌ | ✅ | Clinicians are isolated from each other. |
| **Admin Powers** |
| View/Edit/Delete ANY Patient | - | - | ✅ | Global CRUD access. |
| View/Edit/Delete ANY Clinician | - | - | ✅ | Global CRUD access. |
| Assign/Unassign a patient | - | - | ✅ | Admin updates the `clinician_id` field on the `patient_profiles` table. |
| Verify new user registrations | - | - | ✅ | Admin updates `users.is_verified` from `false` to `true`. |