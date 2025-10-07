### Data Logging Strategy and Frequency for Chronic Disease Monitoring Prototype

Date: 7th of October, 2025

---

### 1. Executive Summary

This report outlines a comprehensive data logging strategy for the prototype of an AI-enabled digital health platform for chronic disease monitoring. The strategy focuses on manual user input and defines the optimal frequency, timing, and format for key biometric and health data points. The primary data types identified are Glucose, HbA1c, Blood Pressure, Cholesterol, BMI, Heart Rate, ECG, Activity Data, and Diet Logs. The specifications detailed herein are designed to ensure the collection of high-quality, actionable data to power the platform's AI-driven recommendation and analysis features while maintaining a user-friendly experience.

---

### 2. Introduction

The development of a digital health platform for chronic disease management requires a robust data collection framework. As the initial prototype will rely on manual data entry by users, it is critical to establish clear and practical guidelines for what data to log, when, and in what format. This document provides a detailed specification for each required data type, balancing the need for clinical detail with the practicalities of user-led data logging.

---

### 3. Data Logging Specifications

This section details the logging requirements for each identified health data type.

#### 3.1. Glucose
- **Best Frequency (non-range):** 7 times a day
- **Best Frequency (range):** 4-8 times a day
- **Best Time:** Upon waking, before meals, 2 hours after meals, and before bed.
- **When:** When fasting, and before and after main meals.
- **Format/Metric:** Single numerical value, with units specified as `mmol/L` or `mg/dL`.

#### 3.2. HbA1c
- **Best Frequency (non-range):** Every 3 months
- **Best Frequency (range):** Every 3-6 months
- **When:** After receiving official lab test results.
- **Format/Metric:** Single numerical value, with units specified as `%` or `mmol/mol`.

#### 3.3. Blood Pressure
- **Best Frequency (non-range):** Once daily
- **Best Frequency (range):** 1-2 times daily
- **Best Time:** Morning, at a consistent time each day before food or medication.
- **Format/Metric:** Two separate integer values for Systolic and Diastolic, with units in `mmHg`.

#### 3.4. Cholesterol (Full Panel)
- **Best Frequency (non-range):** Every 6 months
- **Best Frequency (range):** Every 6-12 months
- **When:** After receiving official lab test results.
- **Format/Metric:** Four separate numerical values for Total Cholesterol, LDL, HDL, and Triglycerides, with units in `mg/dL` or `mmol/L`.

#### 3.5. BMI (Body Mass Index)
- **Best Frequency (non-range):** Weekly
- **Best Frequency (range):** Weekly to monthly
- **Best Time:** Morning, after waking and before breakfast.
- **When:** When logging the weekly/monthly weight measurement.
- **Format/Metric:** A calculated float value derived from user-inputted height (`cm`) and weight (`kg`).

#### 3.6. Heart Rate
- **Best Frequency (non-range):** Once daily
- **Best Frequency (range):** 1-3 times daily
- **Best Time:** Morning, at rest upon waking.
- **Format/Metric:** Average `BPM` (Beats Per Minute) over a 30-second (non-range) or 30-60 second (range) measurement period.

#### 3.7. ECG (Electrocardiogram)

##### 3.7.1. ECG (Classification)
- **Best Frequency (non-range):** Once daily (for a periodic self-check).
- **Best Frequency (range):** From daily to weekly for periodic checks, or on-demand as needed.
- **When:** When symptoms (e.g., palpitations) occur, as part of a routine self-check, or as advised by a clinician.
- **Format/Metric:** A text string for the classification (e.g., "Normal Sinus Rhythm") and the Average `BPM` over a 30-second (non-range) or 30-60 second (range) measurement period.

##### 3.7.2. ECG (Raw)
- **Frequency:** Continuous, typically for a prescribed 24-48 hour period.
- **Note:** This data type is captured by clinical devices (e.g., Holter monitor) and is not intended for manual user entry in the prototype. It is included for contextual understanding.
- **Format/Metric:** Time-series data stream (voltage vs. time).

#### 3.8. Activity Data
- **Best Frequency (non-range):** After each session
- **Best Frequency (range):** 1-3 times daily
- **When:** After completing an exercise or activity session.
- **Format/Metric:** A text string for the activity type and an integer for the duration in minutes.

#### 3.9. Diet Logs
- **Best Frequency (non-range):** 3 times a day
- **Best Frequency (range):** 3-5 times a day
- **When:** At each mealtime.
- **Format/Metric:** Free-text description of the meal.

---

### 4. Key Considerations and Clarifications

#### 4.1. Data Interdependencies
Glucose and Diet Logs are closely linked. The system should be designed to correlate a specific meal (Diet Log) with the glucose readings taken before and after it. This provides critical data for analysing the glycemic impact of different foods.

#### 4.2. Standalone vs. Paired Entries
To maximise user compliance and flexibility, the system should allow for:
- **Standalone Glucose Entry:** For readings not associated with a meal (e.g., fasting).
- **Standalone Diet Log Entry:** In cases where a user logs a meal but did not take a glucose reading.
- **Paired Entry:** The ideal scenario where a meal and its corresponding glucose readings are logged together.

#### 4.3. ECG Monitoring Explained
- **On-Demand vs. Continuous:** For the prototype's target user (self-monitoring), ECG is an on-demand action initiated by the user to capture symptoms or perform a spot-check. Continuous monitoring is a clinical diagnostic tool and is out of scope for manual entry.
- **External Classification:** The prototype will not analyse raw ECG data. Instead, the user will take a reading on an external consumer device (e.g., a smartwatch), which provides an instant classification. The user then manually enters this text-based classification into the app.
- **ECG vs. Heart Rate:** An ECG reading provides both a rhythm classification and a heart rate. However, a heart rate can be measured independently via optical sensors that do not capture the heart's electrical activity (ECG). Therefore, Heart Rate is treated as a separate, simpler data type.

---

### 5. Summary Table of Data Logging Specifications

| Data Type | Best Frequency (non-range) | Best Frequency (range) | Best Time | When | Format/Metric |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Glucose** | 7 times a day | 4-8 times a day | Upon waking, before meals, 2 hours after meals, and before bed | When fasting, before and after main meals | Single value (`mmol/L` or `mg/dL`) |
| **HbA1c** | Every 3 months | Every 3-6 months | Not applicable | After receiving lab test results | Single value (`%` or `mmol/mol`) |
| **Blood Pressure** | Once daily | 1-2 times daily | Morning | At the same time each day, before food or medication | Two integer values: Systolic/Diastolic (`mmHg`) |
| **Cholesterol (Full Panel)** | Every 6 months | Every 6-12 months | Not applicable | After receiving lab test results | Four values: Total, LDL, HDL, Triglycerides (`mg/dL` or `mmol/L`) |
| **BMI** | Weekly | Weekly to monthly | Morning | After waking and before breakfast (for the weight measurement) | Calculated float value from height (`cm`) and weight (`kg`) |
| **Heart Rate** | Once daily | 1-3 times daily | Morning | At rest, upon waking | Average `BPM` (Beats Per Minute) over a 30-second (non-range) or 30-60 second (range) measurement period |
| **ECG (Raw)** | Continuous | Continuous for 24-48 hours | Not applicable | During a prescribed monitoring period | Time-series data stream (voltage vs. time) |
| **ECG (Classification)** | Once daily (for periodic check) | From daily to weekly (for periodic checks), or on-demand (for symptoms) | Not applicable | When symptoms occur, as a periodic self-check, or as advised by a clinician | Text classification (e.g., "Normal Sinus Rhythm") and Average `BPM` over a 30-second (non-range) or 30-60 second (range) measurement period |
| **Activity Data** | After each session | 1-3 times daily | Not applicable | After completing an exercise or activity session | Type (text) and Duration (minutes) |
| **Diet Logs** | 3 times a day | 3-5 times a day | Not applicable | At each mealtime | Text description |

---

### 6. Conclusion

The data logging strategy defined in this document provides a clear and comprehensive framework for the manual collection of health data in the prototype. By specifying the optimal frequency, timing, and format for each data type, this strategy ensures that the platform will gather the rich, structured data necessary for its AI-powered features. The flexibility built into the logging process is intended to encourage consistent user engagement, which is paramount to the platform's success. These specifications will serve as a foundational guide for the development of the application's user interface and backend data models.
