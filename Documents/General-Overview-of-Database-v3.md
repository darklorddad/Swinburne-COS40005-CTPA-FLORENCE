### Project Backend & Database: The Full Overview (Updated)

This document serves as the definitive guide for the backend and database implementation. It covers the data structure, the API contract for communication, and the critical business rules for access control.

---

### 1. Database Schema (The Blueprint)

This is the foundational structure of your data storage, designed for a Supabase environment.

#### Entity Relationship Diagram (ERD)

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
| gender               |                                | gender, date_of_birth         |
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
+---------------------+   | meal_desc (TEXT)         |   +--------------------+
                          +--------------------------+
```

#### Detailed Table Definitions

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
    *   `gender` (VARCHAR, NULLABLE)
    *   `date_of_birth` (DATE, NULLABLE)
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
    *   `gender` (VARCHAR, NULLABLE)
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
    *   `meal_desc` (TEXT, NULLABLE)
    *   *Constraint:* `UNIQUE(patient_id, log_date, meal_time)`
    *   *Constraint:* `CHECK (glucose_before_meal IS NOT NULL OR glucose_after_meal IS NOT NULL)`

*   **`clinician_notes`**
    *   `id` (PK, INT, Auto-increment)
    *   `patient_id` (FK to `patient_profiles.id`, NOT NULL)
    *   `clinician_id` (FK to `clinician_profiles.id`, NULLABLE)
    *   `clinician_name_snapshot` (TEXT, NULLABLE)
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
| `DELETE`  | `/patients/me`                                    | Delete my own patient profile.                                            | Patient           |
| `GET`     | `/patients/me/monitor-data`                       | Get paginated list of my monitor data (supports filtering).               | Patient           |
| `POST`    | `/patients/me/monitor-data`                       | Add a new monitor data point for myself.                                  | Patient           |
| `PUT`     | `/patients/me/monitor-data/{dataId}`              | Update one of my monitor data entries.                                    | Patient           |
| `GET`     | `/patients/me/daily-logs`                         | Get paginated list of my daily logs (supports filtering).                 | Patient           |
| `POST`    | `/patients/me/daily-logs`                         | Add a new daily log for myself.                                           | Patient           |
| `GET`     | `/patients/me/thresholds`                         | Get my own defined health thresholds.                                     | Patient           |
| **Clinician (Management)**                                                                                                                |
| `GET`     | `/clinicians/me`                                  | Get my own clinician profile.                                             | Clinician         |
| `DELETE`  | `/clinicians/me`                                  | Delete my own clinician profile.                                          | Clinician         |
| `GET`     | `/clinicians/me/patients`                         | Get a list of all patients **assigned to me**.                            | Clinician         |
| `GET`     | `/clinicians/me/patients/{patientId}`             | Get full profile & data for **an assigned patient only**.                 | Clinician         |
| `PUT`     | `/clinicians/me/patients/{patientId}/assess-risk` | Update the risk level for **an assigned patient only**.                   | Clinician         |
| `POST`    | `/clinicians/me/patients/{patientId}/notes`       | Add a new note for **an assigned patient only**.                          | Clinician         |
| `GET`     | `/clinicians/me/patients/{patientId}/thresholds`  | Get thresholds for an assigned patient.                                   | Clinician         |
| `PUT`     | `/clinicians/me/patients/{patientId}/thresholds`  | Set/Update thresholds for an assigned patient.                            | Clinician         |
| **Admin (Global Management)**                                                                                                             |
| `GET`     | `/admin/patients`                                 | Get a list of all patients.                                               | Admin             |
| `POST`    | `/admin/patients`                                 | Add a new patient.                                                        | Admin             |
| `GET`     | `/admin/clinicians`                               | Get a list of all clinicians and their assigned patients.                 | Admin             |
| `POST`    | `/admin/clinicians`                               | Add a new clinician.                                                      | Admin             |
| `GET`     | `/admin/organisations`                            | Get a list of all organisations.                                          | Admin             |
| `GET`     | `/admin/daily-logs`                               | Get a list of all daily patient logs.                                     | Admin             |
| `POST`    | `/admin/daily-logs`                               | Add a daily patient log for a specific patient.                           | Admin             |
| `DELETE`  | `/admin/daily-logs/{logId}`                       | Remove a daily patient log.                                               | Admin             |
| `GET`     | `/admin/monitor-data`                             | Get a list of all patient monitor data.                                   | Admin             |
| `POST`    | `/admin/monitor-data`                             | Add a patient monitor data point for a specific patient.                  | Admin             |
| `DELETE`  | `/admin/monitor-data/{dataId}`                    | Remove a patient monitor data point.                                      | Admin             |
| `GET`     | `/admin/thresholds`                               | Get a list of all patient thresholds.                                     | Admin             |
| `PUT`     | `/admin/organisations/{organisationId}`           | Edit any organisation.                                                    | Admin             |
| `DELETE`  | `/admin/organisations/{organisationId}`           | Remove any organisation.                                                  | Admin             |
| `PUT`     | `/admin/clinicians/{clinicianId}`                 | Edit any clinician's profile.                                             | Admin             |
| `DELETE`  | `/admin/clinicians/{clinicianId}`                 | Remove any clinician.                                                     | Admin             |
| `PUT`     | `/admin/patients/{patientId}`                     | Edit any patient (including risk level & clinician assignment).           | Admin             |
| `PUT`     | `/admin/daily-logs/{logId}`                       | Edit any daily patient log.                                               | Admin             |
| `PUT`     | `/admin/monitor-data/{dataId}`                    | Edit any patient monitor data point.                                      | Admin             |
| `PUT`     | `/admin/thresholds/{thresholdId}`                 | Edit any patient threshold.                                               | Admin             |
| `PUT`     | `/admin/notes/{noteId}`                           | Edit any clinician note.                                                  | Admin             |
| `DELETE`  | `/admin/patients/{patientId}`                     | Remove any patient.                                                       | Admin             |
| `...`     | `...`                                             | (Similar CRUD endpoints for all data types)                               | Admin             |

---

### 3. Roles & Permissions Matrix (The Rules)

| Action                                        | Patient   | Clinician | Admin | Backend Logic Notes |
| :-------------------------------------------: | :-------: | :-------: | :---: | :-----------------: |
| **User Onboarding**                                                                                   |
| Create Patient/Clinician                      | ✅ | ✅ | ✅ | Backend API handles profile creation. |
| Create Admin                                  | ❌ | ❌ | ✅ | Admin created via secure API or manually. |
| **Account & Profile**                                                                                         |
| Edit own account/profile                      | ✅ | ✅ | ✅ | Scoped to `user_id`. |
| View profile of *assigned* patient            |  -  | ✅ | ✅ | RLS: `patient.clinician_id == my_clinician_id`. |
| View profile of *unassigned* patient          | ❌ | ❌ | ✅ | Clinician access denied. Admin has global access. |
| **Monitor Data (`patient_monitor_data`)**     |
| Add/View/Edit own data                        | ✅ | -  | -  | RLS: `patient_id` must match user's profile ID. |
| View data of *assigned* patient               | -  | ✅ | ✅ | RLS: `SELECT` only. |
| Add/Edit data of *any* patient                | ❌ | ❌ | ✅ | RLS: Admin has full `INSERT/UPDATE` access. |
| **Daily Logs (`daily_patient_logs`)**         |
| Add/View/Edit own logs                        | ✅ | -  | -   | RLS: `patient_id` must match user's profile ID. |
| View logs of *assigned* patient               | -  | ✅ | ✅  | RLS: `SELECT` only. |
| Add/Edit logs of *any* patient                | ❌ | ❌ | ✅  | RLS: Admin has full `INSERT/UPDATE` access. |
| **Thresholds (`patient_thresholds`)**         |
| View own thresholds                           | ✅ | -  | -  | RLS: `SELECT` only. |
| View/Edit thresholds of *assigned* patient    | -  | ✅ | ✅ | RLS: `SELECT` and `UPDATE` allowed. |
| View/Edit thresholds of *any* patient         | ❌ | ❌ | ✅ | RLS: Admin has full `SELECT/UPDATE` access. |
| **Clinician Notes (`clinician_notes`)** |
| See *any* notes about them                    | ❌ | -  | -  | **Privacy Rule:** Patient access is completely denied. |
| Add/View notes for *assigned* patient         | -  | ✅ | ✅ | RLS: `patient.clinician_id` checked. |


### 4. SQL Editor Code
-- =================================================================
-- Part 1: Table Creation
-- =================================================================
-- Note: Run this section only once during the initial setup.

-- Create Organisations Table
CREATE TABLE IF NOT EXISTS public.organisations (
    id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULL
);

-- Create Clinician Profiles Table
CREATE TABLE IF NOT EXISTS public.clinician_profiles (
    id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
    name TEXT,
    phone_number TEXT,
    gender TEXT,
    organisation_id BIGINT NOT NULL REFERENCES public.organisations(id)
);

-- Create Patient Profiles Table
CREATE TABLE IF NOT EXISTS public.patient_profiles (
    id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
    name TEXT,
    phone_number TEXT,
    gender TEXT,
    date_of_birth DATE,
    organisation_id BIGINT REFERENCES public.organisations(id),
    clinician_id BIGINT REFERENCES public.clinician_profiles(id),
    emergency_contact_name TEXT,
    emergency_contact_relationship TEXT,
    emergency_contact_phone TEXT,
    risk_level TEXT CHECK (risk_level IN ('LOW', 'MEDIUM', 'HIGH')) DEFAULT 'LOW' NOT NULL,
    last_risk_assessment TIMESTAMPTZ
);

-- Create Patient Monitor Data Table
CREATE TABLE IF NOT EXISTS public.patient_monitor_data (
    id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    patient_id BIGINT NOT NULL REFERENCES public.patient_profiles(id) ON DELETE CASCADE,
    data_type TEXT CHECK (data_type IN ('BLOOD_PRESSURE_SYSTOLIC', 'BLOOD_PRESSURE_DIASTOLIC', 'GLUCOSE', 'BMI', 'HBA1C', 'ECG', 'CHOLESTEROL')) NOT NULL,
    value NUMERIC(8, 2) NOT NULL,
    measured_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Create Patient Thresholds Table
CREATE TABLE IF NOT EXISTS public.patient_thresholds (
    id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    patient_id BIGINT NOT NULL REFERENCES public.patient_profiles(id) ON DELETE CASCADE,
    data_type TEXT CHECK (data_type IN ('BLOOD_PRESSURE_SYSTOLIC', 'BLOOD_PRESSURE_DIASTOLIC', 'GLUCOSE', 'BMI', 'HBA1C', 'ECG', 'CHOLESTEROL')) NOT NULL,
    min_value NUMERIC(8, 2) NOT NULL,
    max_value NUMERIC(8, 2) NOT NULL,
    UNIQUE(patient_id, data_type)
);

-- Create Daily Patient Logs Table
CREATE TABLE IF NOT EXISTS public.daily_patient_logs (
    id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    patient_id BIGINT NOT NULL REFERENCES public.patient_profiles(id) ON DELETE CASCADE,
    log_date DATE NOT NULL,
    meal_time TEXT CHECK (meal_time IN ('BREAKFAST', 'LUNCH', 'DINNER')) NOT NULL,
    glucose_before_meal NUMERIC(8, 2),
    glucose_after_meal NUMERIC(8, 2),
    meal_desc TEXT, -- <-- UPDATE: Added meal description field
    UNIQUE(patient_id, log_date, meal_time),
    CHECK (glucose_before_meal IS NOT NULL OR glucose_after_meal IS NOT NULL)
);

-- Create Clinician Notes Table
CREATE TABLE IF NOT EXISTS public.clinician_notes (
    id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    patient_id BIGINT NOT NULL REFERENCES public.patient_profiles(id) ON DELETE CASCADE,
    clinician_id BIGINT REFERENCES public.clinician_profiles(id),
    clinician_name_snapshot TEXT,
    note_content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =================================================================
-- Part 1.5: Indexes for Performance
-- =================================================================
-- Note: Indexes are crucial for query performance, especially on large tables.

-- Index for fetching a patient's monitor data, sorted by time.
CREATE INDEX IF NOT EXISTS idx_patient_data_measured_at 
ON public.patient_monitor_data (patient_id, measured_at DESC);

-- Index for fetching a patient's daily logs, sorted by date.
CREATE INDEX IF NOT EXISTS idx_patient_logs_date 
ON public.daily_patient_logs (patient_id, log_date DESC);


-- =================================================================
-- Part 2: Custom Functions for RLS
-- =================================================================
-- Note: These functions are required for the RLS policies to work correctly.

CREATE OR REPLACE FUNCTION public.get_user_role()
RETURNS TEXT
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN (
    SELECT raw_app_meta_data->>'role' FROM auth.users WHERE id = auth.uid()
  );
END;
$$;

-- =================================================================
-- Part 3: Enable Row Level Security (RLS) on all tables
-- =================================================================
ALTER TABLE public.organisations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clinician_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patient_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patient_monitor_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patient_thresholds ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_patient_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clinician_notes ENABLE ROW LEVEL SECURITY;

-- =================================================================
-- Part 4: RLS Policies
-- =================================================================
-- Note: Run this section to apply the security rules. It is safe to re-run.

-- Drop all policies to ensure a clean slate
DROP POLICY IF EXISTS "Enable read access for all authenticated users" ON public.organisations;
DROP POLICY IF EXISTS "Admins can manage all organisations" ON public.organisations;
DROP POLICY IF EXISTS "Admins can manage all clinician profiles" ON public.clinician_profiles;
DROP POLICY IF EXISTS "Clinicians can see their own profile" ON public.clinician_profiles;
DROP POLICY IF EXISTS "Clinicians can update their own profile" ON public.clinician_profiles;
DROP POLICY IF EXISTS "Admins can manage all patient profiles" ON public.patient_profiles;
DROP POLICY IF EXISTS "Patients can see their own profile" ON public.patient_profiles;
DROP POLICY IF EXISTS "Patients can update their own profile" ON public.patient_profiles;
DROP POLICY IF EXISTS "Clinicians can see their assigned patients' profiles" ON public.patient_profiles;
DROP POLICY IF EXISTS "Clinicians can update their assigned patients' profiles" ON public.patient_profiles;
DROP POLICY IF EXISTS "Admins can manage all monitor data" ON public.patient_monitor_data;
DROP POLICY IF EXISTS "Patients can manage their own monitor data" ON public.patient_monitor_data;
DROP POLICY IF EXISTS "Clinicians can view assigned patients monitor data" ON public.patient_monitor_data;
DROP POLICY IF EXISTS "Admins can manage all daily logs" ON public.daily_patient_logs;
DROP POLICY IF EXISTS "Patients can manage their own daily logs" ON public.daily_patient_logs;
DROP POLICY IF EXISTS "Clinicians can view assigned patients daily logs" ON public.daily_patient_logs;
DROP POLICY IF EXISTS "Admins can manage all patient thresholds" ON public.patient_thresholds;
DROP POLICY IF EXISTS "Patients can view their own thresholds" ON public.patient_thresholds;
DROP POLICY IF EXISTS "Clinicians can manage assigned patients thresholds" ON public.patient_thresholds;
DROP POLICY IF EXISTS "Admins can manage all clinician notes" ON public.clinician_notes;
DROP POLICY IF EXISTS "Clinicians can manage notes for their patients" ON public.clinician_notes;


-- Policies for organisations
CREATE POLICY "Enable read access for all authenticated users" ON public.organisations FOR SELECT TO authenticated USING (true);
CREATE POLICY "Admins can manage all organisations" ON public.organisations FOR ALL TO authenticated USING (public.get_user_role() = 'admin') WITH CHECK (public.get_user_role() = 'admin');

-- Policies for clinician_profiles
CREATE POLICY "Admins can manage all clinician profiles" ON public.clinician_profiles FOR ALL TO authenticated USING (public.get_user_role() = 'admin') WITH CHECK (public.get_user_role() = 'admin');
CREATE POLICY "Clinicians can see their own profile" ON public.clinician_profiles FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "Clinicians can update their own profile" ON public.clinician_profiles FOR UPDATE TO authenticated USING (user_id = auth.uid());

-- Policies for patient_profiles
CREATE POLICY "Admins can manage all patient profiles" ON public.patient_profiles FOR ALL TO authenticated USING (public.get_user_role() = 'admin') WITH CHECK (public.get_user_role() = 'admin');
CREATE POLICY "Patients can see their own profile" ON public.patient_profiles FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "Patients can update their own profile" ON public.patient_profiles FOR UPDATE TO authenticated USING (user_id = auth.uid());
CREATE POLICY "Clinicians can see their assigned patients' profiles" ON public.patient_profiles FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM public.clinician_profiles WHERE user_id = auth.uid() AND id = public.patient_profiles.clinician_id));
CREATE POLICY "Clinicians can update their assigned patients' profiles" ON public.patient_profiles FOR UPDATE TO authenticated USING (EXISTS (SELECT 1 FROM public.clinician_profiles WHERE user_id = auth.uid() AND id = public.patient_profiles.clinician_id));

-- Policies for patient_monitor_data
CREATE POLICY "Admins can manage all monitor data" ON public.patient_monitor_data FOR ALL TO authenticated USING (public.get_user_role() = 'admin') WITH CHECK (public.get_user_role() = 'admin');
CREATE POLICY "Patients can manage their own monitor data" ON public.patient_monitor_data FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM public.patient_profiles WHERE user_id = auth.uid() AND id = public.patient_monitor_data.patient_id)) WITH CHECK (EXISTS (SELECT 1 FROM public.patient_profiles WHERE user_id = auth.uid() AND id = public.patient_monitor_data.patient_id));
CREATE POLICY "Clinicians can view assigned patients monitor data" ON public.patient_monitor_data FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM public.patient_profiles pp JOIN public.clinician_profiles cp ON pp.clinician_id = cp.id WHERE cp.user_id = auth.uid() AND pp.id = public.patient_monitor_data.patient_id));

-- Policies for daily_patient_logs
CREATE POLICY "Admins can manage all daily logs" ON public.daily_patient_logs FOR ALL TO authenticated USING (public.get_user_role() = 'admin') WITH CHECK (public.get_user_role() = 'admin');
CREATE POLICY "Patients can manage their own daily logs" ON public.daily_patient_logs FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM public.patient_profiles WHERE user_id = auth.uid() AND id = public.daily_patient_logs.patient_id)) WITH CHECK (EXISTS (SELECT 1 FROM public.patient_profiles WHERE user_id = auth.uid() AND id = public.daily_patient_logs.patient_id));
CREATE POLICY "Clinicians can view assigned patients daily logs" ON public.daily_patient_logs FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM public.patient_profiles pp JOIN public.clinician_profiles cp ON pp.clinician_id = cp.id WHERE cp.user_id = auth.uid() AND pp.id = public.daily_patient_logs.patient_id));

-- Policies for patient_thresholds
CREATE POLICY "Admins can manage all patient thresholds" ON public.patient_thresholds FOR ALL TO authenticated USING (public.get_user_role() = 'admin') WITH CHECK (public.get_user_role() = 'admin');
CREATE POLICY "Patients can view their own thresholds" ON public.patient_thresholds FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM public.patient_profiles WHERE user_id = auth.uid() AND id = public.patient_thresholds.patient_id));
CREATE POLICY "Clinicians can manage assigned patients thresholds" ON public.patient_thresholds FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM public.patient_profiles pp JOIN public.clinician_profiles cp ON pp.clinician_id = cp.id WHERE cp.user_id = auth.uid() AND pp.id = public.patient_thresholds.patient_id)) WITH CHECK (EXISTS (SELECT 1 FROM public.patient_profiles pp JOIN public.clinician_profiles cp ON pp.clinician_id = cp.id WHERE cp.user_id = auth.uid() AND pp.id = public.patient_thresholds.patient_id));

-- Policies for clinician_notes
CREATE POLICY "Admins can manage all clinician notes" ON public.clinician_notes FOR ALL TO authenticated USING (public.get_user_role() = 'admin') WITH CHECK (public.get_user_role() = 'admin');
CREATE POLICY "Clinicians can manage notes for their patients" ON public.clinician_notes FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM public.clinician_profiles WHERE user_id = auth.uid() AND id = public.clinician_notes.clinician_id)) WITH CHECK (EXISTS (SELECT 1 FROM public.patient_profiles pp JOIN public.clinician_profiles cp ON pp.clinician_id = cp.id WHERE cp.user_id = auth.uid() AND pp.id = public.clinician_notes.patient_id));

-- =================================================================
-- Part 5: Template for Creating First Admin User
-- =================================================================

-- Run this command to create your first admin user.
-- Remember to set up the 'get_user_role' custom claim in Supabase Auth Settings.
-- INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, created_at, updated_at)
-- VALUES (
--   '00000000-0000-0000-0000-000000000000',
--   uuid_generate_v4(),
--   'authenticated',
--   'authenticated',
--   'admin@example.com',
--   crypt('your-secure-password', gen_salt('bf')),
--   now(),
--   '{"provider": "email", "providers": ["email"], "role": "admin"}',
--   now(),
--   now()
-- );
