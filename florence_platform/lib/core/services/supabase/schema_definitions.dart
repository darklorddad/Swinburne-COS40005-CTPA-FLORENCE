/// Supabase Database Schema Definitions
/// This file contains the table schemas for the FLORENCE platform
/// These schemas are NOT YET CONNECTED to Supabase
library;

/*
 * ============================================================================
 * SUPABASE DATABASE SCHEMA FOR FLORENCE DIGITAL HEALTH PLATFORM
 * ============================================================================
 *
 * This file documents the database schema for when Supabase integration
 * is enabled. Currently, the app uses in-memory data management.
 *
 * To enable Supabase:
 * 1. Create tables in your Supabase project using these schemas
 * 2. Update environment.dart to set ENABLE_SUPABASE = true
 * 3. Configure Supabase credentials in supabase_config.dart
 *
 * ============================================================================
 */

/*
-- ============================================================================
-- TABLE: patients
-- ============================================================================
CREATE TABLE patients (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users NOT NULL,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  phone TEXT,
  date_of_birth DATE,
  gender TEXT CHECK (gender IN ('Male', 'Female', 'Other', 'Prefer not to say')),
  diabetes_type TEXT CHECK (diabetes_type IN ('Type 1', 'Type 2', 'Pre-diabetes', 'Gestational')),
  diagnosis_date DATE,
  height_cm DECIMAL,
  weight_kg DECIMAL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Row Level Security
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own patient data"
  ON patients FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own patient data"
  ON patients FOR UPDATE
  USING (auth.uid() = user_id);

-- ============================================================================
-- TABLE: glucose_readings
-- ============================================================================
CREATE TABLE glucose_readings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id UUID REFERENCES patients(id) ON DELETE CASCADE NOT NULL,
  timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
  value DECIMAL NOT NULL CHECK (value > 0 AND value < 1000),
  context TEXT,
  notes TEXT,
  is_flagged BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_glucose_patient_timestamp ON glucose_readings(patient_id, timestamp DESC);

ALTER TABLE glucose_readings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own glucose readings"
  ON glucose_readings FOR SELECT
  USING (patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid()));

CREATE POLICY "Users can insert their own glucose readings"
  ON glucose_readings FOR INSERT
  WITH CHECK (patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid()));

CREATE POLICY "Users can update their own glucose readings"
  ON glucose_readings FOR UPDATE
  USING (patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid()));

CREATE POLICY "Users can delete their own glucose readings"
  ON glucose_readings FOR DELETE
  USING (patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid()));

-- ============================================================================
-- TABLE: meals
-- ============================================================================
CREATE TABLE meals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id UUID REFERENCES patients(id) ON DELETE CASCADE NOT NULL,
  timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
  meal_type TEXT CHECK (meal_type IN ('Breakfast', 'Lunch', 'Dinner', 'Snack')),
  description TEXT NOT NULL,
  carbs DECIMAL CHECK (carbs >= 0),
  calories INTEGER CHECK (calories >= 0),
  protein DECIMAL CHECK (protein >= 0),
  fat DECIMAL CHECK (fat >= 0),
  photo_url TEXT,
  notes TEXT,
  tags TEXT[],
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_meals_patient_timestamp ON meals(patient_id, timestamp DESC);

ALTER TABLE meals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own meal logs"
  ON meals FOR ALL
  USING (patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid()));

-- ============================================================================
-- TABLE: activities
-- ============================================================================
CREATE TABLE activities (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id UUID REFERENCES patients(id) ON DELETE CASCADE NOT NULL,
  timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
  activity_type TEXT NOT NULL,
  duration INTEGER NOT NULL CHECK (duration > 0), -- in minutes
  intensity TEXT CHECK (intensity IN ('Low', 'Moderate', 'High')),
  calories_burned INTEGER CHECK (calories_burned >= 0),
  distance DECIMAL CHECK (distance >= 0), -- in km
  steps INTEGER CHECK (steps >= 0),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_activities_patient_timestamp ON activities(patient_id, timestamp DESC);

ALTER TABLE activities ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own activity logs"
  ON activities FOR ALL
  USING (patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid()));

-- ============================================================================
-- TABLE: medications
-- ============================================================================
CREATE TABLE medications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id UUID REFERENCES patients(id) ON DELETE CASCADE NOT NULL,
  medication_name TEXT NOT NULL,
  dosage TEXT NOT NULL,
  frequency TEXT NOT NULL,
  prescribed_date DATE NOT NULL,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE medications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own medications"
  ON medications FOR ALL
  USING (patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid()));

-- ============================================================================
-- TABLE: medication_doses
-- ============================================================================
CREATE TABLE medication_doses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  medication_id UUID REFERENCES medications(id) ON DELETE CASCADE NOT NULL,
  scheduled_time TIMESTAMP WITH TIME ZONE NOT NULL,
  taken_time TIMESTAMP WITH TIME ZONE,
  taken BOOLEAN DEFAULT FALSE,
  skipped BOOLEAN DEFAULT FALSE,
  skip_reason TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_doses_medication_scheduled ON medication_doses(medication_id, scheduled_time DESC);

ALTER TABLE medication_doses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own medication doses"
  ON medication_doses FOR ALL
  USING (medication_id IN (
    SELECT id FROM medications WHERE patient_id IN (
      SELECT id FROM patients WHERE user_id = auth.uid()
    )
  ));

-- ============================================================================
-- TABLE: hba1c_results
-- ============================================================================
CREATE TABLE hba1c_results (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id UUID REFERENCES patients(id) ON DELETE CASCADE NOT NULL,
  test_date DATE NOT NULL,
  value DECIMAL NOT NULL CHECK (value > 0 AND value < 20),
  notes TEXT,
  lab_name TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_hba1c_patient_date ON hba1c_results(patient_id, test_date DESC);

ALTER TABLE hba1c_results ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own HbA1c results"
  ON hba1c_results FOR ALL
  USING (patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid()));

-- ============================================================================
-- TABLE: sleep_logs
-- ============================================================================
CREATE TABLE sleep_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id UUID REFERENCES patients(id) ON DELETE CASCADE NOT NULL,
  bed_time TIMESTAMP WITH TIME ZONE NOT NULL,
  wake_time TIMESTAMP WITH TIME ZONE NOT NULL,
  quality INTEGER CHECK (quality >= 1 AND quality <= 10),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_sleep_patient_bedtime ON sleep_logs(patient_id, bed_time DESC);

ALTER TABLE sleep_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own sleep logs"
  ON sleep_logs FOR ALL
  USING (patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid()));

-- ============================================================================
-- TABLE: recommendations (AI-generated)
-- ============================================================================
CREATE TABLE recommendations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id UUID REFERENCES patients(id) ON DELETE CASCADE NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('Meal', 'Activity', 'Sleep', 'Medication', 'Lifestyle', 'Timing')),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  rationale TEXT, -- AI explanation
  priority TEXT CHECK (priority IN ('Urgent', 'High', 'Medium', 'Low')),
  status TEXT DEFAULT 'Active' CHECK (status IN ('Active', 'Completed', 'Dismissed')),
  generated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expires_at TIMESTAMP WITH TIME ZONE,
  data_sources JSONB, -- References to glucose readings, meals, etc. that triggered this
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_recommendations_patient_status ON recommendations(patient_id, status, generated_at DESC);

ALTER TABLE recommendations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own recommendations"
  ON recommendations FOR ALL
  USING (patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid()));

-- ============================================================================
-- TABLE: notifications (automation triggers)
-- ============================================================================
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id UUID REFERENCES patients(id) ON DELETE CASCADE NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('Alert', 'Reminder', 'Educational', 'Motivational', 'Summary')),
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  priority TEXT CHECK (priority IN ('Critical', 'High', 'Medium', 'Low')),
  read BOOLEAN DEFAULT FALSE,
  action_url TEXT, -- Deep link to relevant screen
  triggered_by JSONB, -- Data that triggered this notification
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  read_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_notifications_patient_unread ON notifications(patient_id, read, created_at DESC);

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own notifications"
  ON notifications FOR SELECT
  USING (patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid()));

CREATE POLICY "Users can update their own notifications"
  ON notifications FOR UPDATE
  USING (patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid()));

-- ============================================================================
-- TABLE: chat_messages (AI chatbot)
-- ============================================================================
CREATE TABLE chat_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id UUID REFERENCES patients(id) ON DELETE CASCADE NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
  content TEXT NOT NULL,
  context JSONB, -- Health data context used for AI response
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_chat_patient_created ON chat_messages(patient_id, created_at DESC);

ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own chat messages"
  ON chat_messages FOR ALL
  USING (patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid()));

-- ============================================================================
-- TABLE: health_summaries (AI-generated summaries)
-- ============================================================================
CREATE TABLE health_summaries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id UUID REFERENCES patients(id) ON DELETE CASCADE NOT NULL,
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  summary_type TEXT CHECK (summary_type IN ('Daily', 'Weekly', 'Monthly', 'Custom')),
  ai_summary TEXT NOT NULL, -- AI-generated narrative summary
  statistics JSONB NOT NULL, -- Structured data: avg glucose, time in range, etc.
  insights JSONB, -- AI-generated insights and patterns
  recommendations_count INTEGER DEFAULT 0,
  generated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_summaries_patient_period ON health_summaries(patient_id, period_end DESC);

ALTER TABLE health_summaries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own summaries"
  ON health_summaries FOR SELECT
  USING (patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid()));

-- ============================================================================
-- FUNCTIONS & TRIGGERS
-- ============================================================================

-- Automatic updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables with updated_at
CREATE TRIGGER update_patients_updated_at BEFORE UPDATE ON patients FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_glucose_updated_at BEFORE UPDATE ON glucose_readings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_meals_updated_at BEFORE UPDATE ON meals FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_activities_updated_at BEFORE UPDATE ON activities FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_medications_updated_at BEFORE UPDATE ON medications FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_doses_updated_at BEFORE UPDATE ON medication_doses FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_hba1c_updated_at BEFORE UPDATE ON hba1c_results FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_sleep_updated_at BEFORE UPDATE ON sleep_logs FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_recommendations_updated_at BEFORE UPDATE ON recommendations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

-- Already created above with tables, but listing here for reference:
-- - idx_glucose_patient_timestamp
-- - idx_meals_patient_timestamp
-- - idx_activities_patient_timestamp
-- - idx_doses_medication_scheduled
-- - idx_hba1c_patient_date
-- - idx_sleep_patient_bedtime
-- - idx_recommendations_patient_status
-- - idx_notifications_patient_unread
-- - idx_chat_patient_created
-- - idx_summaries_patient_period

-- ============================================================================
-- SAMPLE VIEWS (Optional - for reporting)
-- ============================================================================

-- View for recent patient activity
CREATE OR REPLACE VIEW patient_recent_activity AS
SELECT
  p.id as patient_id,
  p.first_name,
  p.last_name,
  (SELECT COUNT(*) FROM glucose_readings WHERE patient_id = p.id AND timestamp > NOW() - INTERVAL '7 days') as glucose_readings_7d,
  (SELECT COUNT(*) FROM meals WHERE patient_id = p.id AND timestamp > NOW() - INTERVAL '7 days') as meals_7d,
  (SELECT COUNT(*) FROM activities WHERE patient_id = p.id AND timestamp > NOW() - INTERVAL '7 days') as activities_7d,
  (SELECT AVG(value) FROM glucose_readings WHERE patient_id = p.id AND timestamp > NOW() - INTERVAL '7 days') as avg_glucose_7d
FROM patients p;

*/

/// Supabase table names as constants
class SupabaseTables {
  static const String patients = 'patients';
  static const String glucoseReadings = 'glucose_readings';
  static const String meals = 'meals';
  static const String activities = 'activities';
  static const String medications = 'medications';
  static const String medicationDoses = 'medication_doses';
  static const String hba1cResults = 'hba1c_results';
  static const String sleepLogs = 'sleep_logs';
  static const String recommendations = 'recommendations';
  static const String notifications = 'notifications';
  static const String chatMessages = 'chat_messages';
  static const String healthSummaries = 'health_summaries';
}

/// Column names for type-safe queries
class SupabaseColumns {
  // Common columns
  static const String id = 'id';
  static const String patientId = 'patient_id';
  static const String timestamp = 'timestamp';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';

  // Glucose readings
  static const String value = 'value';
  static const String context = 'context';
  static const String notes = 'notes';
  static const String isFlagged = 'is_flagged';

  // Meals
  static const String mealType = 'meal_type';
  static const String description = 'description';
  static const String carbs = 'carbs';
  static const String calories = 'calories';
  static const String protein = 'protein';
  static const String fat = 'fat';

  // Activities
  static const String activityType = 'activity_type';
  static const String duration = 'duration';
  static const String intensity = 'intensity';
  static const String caloriesBurned = 'calories_burned';
}
