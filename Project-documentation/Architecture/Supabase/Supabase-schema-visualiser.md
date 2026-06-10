## Table `admin_profiles`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int8` | Primary Identity |
| `user_id` | `uuid` |  Unique |
| `name` | `text` |  Nullable |
| `phone_number` | `text` |  Nullable |

---

## Table `automated_actions`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int8` | Primary |
| `patient_id` | `int4` |  Nullable |
| `type` | `varchar` |  |
| `description` | `text` |  |
| `response` | `text` |  Nullable |
| `created_at` | `timestamptz` |  |

---

## Table `clinical_documents`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int8` | Primary Identity |
| `patient_id` | `int8` |  |
| `document_path` | `text` |  |
| `document_type` | `text` |  |
| `uploaded_at` | `timestamptz` |  |

---

## Table `clinician_notes`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int8` | Primary Identity |
| `patient_id` | `int8` |  |
| `clinician_id` | `int8` |  Nullable |
| `clinician_name_snapshot` | `text` |  Nullable |
| `note_content` | `text` |  |
| `created_at` | `timestamptz` |  Nullable |

---

## Table `clinician_profiles`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int8` | Primary Identity |
| `user_id` | `uuid` |  Unique |
| `name` | `text` |  Nullable |
| `phone_number` | `text` |  Nullable |
| `gender` | `text` |  Nullable |
| `organisation_id` | `int8` |  |
| `profile_picture_url` | `text` |  Nullable |

---

## Table `daily_patient_logs`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int8` | Primary Identity |
| `patient_id` | `int8` |  |
| `log_date` | `date` |  |
| `meal_time` | `text` |  |
| `glucose_before_meal` | `numeric` |  Nullable |
| `glucose_after_meal` | `numeric` |  Nullable |
| `meal_desc` | `text` |  Nullable |
| `glucose_before_meal_time` | `timestamptz` |  Nullable |
| `glucose_after_meal_time` | `timestamptz` |  Nullable |
| `calories` | `int4` |  Nullable |
| `photo_url` | `text` |  Nullable |

---

## Table `disease_logs`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int8` | Primary Identity |
| `patient_id` | `int8` |  |
| `condition_name` | `text` |  |
| `status` | `text` |  |
| `diagnosed_date` | `date` |  Nullable |
| `resolved_date` | `date` |  Nullable |
| `notes` | `text` |  Nullable |

---

## Table `dosage_frequencies`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int8` | Primary Identity |
| `latin_code` | `text` |  |
| `patient_text` | `text` |  |

---

## Table `medication_dictionary`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int8` | Primary Identity |
| `brand_name` | `text` |  |
| `generic_name` | `text` |  |
| `is_popular` | `bool` |  Nullable |

---

## Table `medication_intake_logs`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int8` | Primary Identity |
| `patient_id` | `int8` |  |
| `patient_medication_id` | `int8` |  |
| `taken_at` | `timestamptz` |  |
| `status` | `text` |  |
| `notes` | `text` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |

---

## Table `organisations`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int8` | Primary Identity |
| `name` | `text` |  |
| `phone_number` | `text` |  Nullable |
| `email` | `text` |  Nullable |
| `website` | `text` |  Nullable |
| `sector` | `text` |  Nullable |
| `facility_type` | `text` |  Nullable |
| `full_address` | `text` |  Nullable |
| `state` | `text` |  Nullable |
| `is_24_hours` | `bool` |  Nullable |
| `operating_hours` | `text` |  Nullable |

---

## Table `patient_activity_logs`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int8` | Primary Identity |
| `patient_id` | `int8` |  |
| `activity_description` | `text` |  |
| `active_duration_minutes` | `int4` |  |
| `created_at` | `timestamptz` |  |
| `start_time` | `timestamptz` |  Nullable |
| `end_time` | `timestamptz` |  Nullable |
| `calories_burned` | `int4` |  Nullable |

---

## Table `patient_chat_history`

Stores chat conversation history between patients and the AI assistant

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `patient_id` | `int8` |  |
| `role` | `text` |  |
| `content` | `text` |  |
| `timestamp` | `timestamptz` |  |
| `context` | `jsonb` |  Nullable |

---

## Table `patient_medications`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int8` | Primary Identity |
| `patient_id` | `int8` |  |
| `clinician_id` | `int8` |  Nullable |
| `medication_id` | `int8` |  Nullable |
| `frequency_id` | `int8` |  |
| `amount` | `text` |  |
| `status` | `text` |  |
| `notes` | `text` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |
| `updated_at` | `timestamptz` |  Nullable |
| `medication_type` | `text` |  Nullable |
| `custom_medication_name` | `text` |  Nullable |
| `timing_instructions` | `_text` |  Nullable |

---

## Table `patient_monitor_data`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int8` | Primary Identity |
| `patient_id` | `int8` |  |
| `data_type` | `text` |  |
| `value` | `numeric` |  |
| `measured_at` | `timestamptz` |  |
| `document_id` | `int8` |  Nullable |

---

## Table `patient_profiles`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int8` | Primary Identity |
| `user_id` | `uuid` |  Unique |
| `name` | `text` |  Nullable |
| `phone_number` | `text` |  Nullable |
| `gender` | `text` |  Nullable |
| `date_of_birth` | `date` |  Nullable |
| `organisation_id` | `int8` |  Nullable |
| `clinician_id` | `int8` |  Nullable |
| `emergency_contact_name` | `text` |  Nullable |
| `emergency_contact_relationship` | `text` |  Nullable |
| `emergency_contact_phone` | `text` |  Nullable |
| `risk_level` | `text` |  |
| `last_risk_assessment` | `timestamptz` |  Nullable |
| `profile_picture_url` | `text` |  Nullable |
| `height` | `numeric` |  Nullable |
| `weight` | `numeric` |  Nullable |
| `risk_rationale` | `text` |  Nullable |
| `daily_insight` | `text` |  Nullable |

---

## Table `patient_recommendations`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `text` | Primary |
| `patient_id` | `int8` |  |
| `timeframe` | `text` |  |
| `category` | `text` |  |
| `title` | `text` |  |
| `description` | `text` |  |
| `priority` | `text` |  |
| `status` | `text` |  |
| `generated_at` | `timestamptz` |  |
| `expires_at` | `timestamptz` |  Nullable |
| `action_items` | `_text` |  Nullable |
| `explanation` | `jsonb` |  Nullable |
| `data_sources` | `jsonb` |  Nullable |

---

## Table `patient_thresholds`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int8` | Primary Identity |
| `patient_id` | `int8` |  |
| `data_type` | `text` |  |
| `min_value` | `numeric` |  |
| `max_value` | `numeric` |  |

---

## Table `user_settings`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `user_id` | `uuid` | Primary |
| `glucose_unit` | `text` |  Nullable |
| `cholesterol_unit` | `text` |  Nullable |
| `updated_at` | `timestamptz` |  Nullable |
| `show_quick_actions` | `bool` |  Nullable |

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