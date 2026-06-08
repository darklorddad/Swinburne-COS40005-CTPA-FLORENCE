# FLORENCE Testing Documentation

## 1. Overview
This document outlines the testing strategies and methodologies employed to ensure the FLORENCE platform is secure, reliable, and user-friendly. Given the healthcare context of the application, rigorous testing is applied across all layers of the architecture.

## 2. Testing Methodologies

### 2.1 Unit Testing
Unit tests are written to verify the logic of individual functions, methods, and classes in isolation.
- **Frontend (Flutter)**: Tests for state management providers, data parsing (e.g., parsing `BmiReading` from raw JSON), and utility functions (e.g., risk level calculation algorithms).
- **Backend (Python)**: Tests for specific endpoints in the Data Service, ensuring proper validation of incoming payloads (e.g., verifying that a new clinical note contains valid text and patient IDs). Tests for the LLM parsing logic to ensure it extracts correct variables from mock lab report texts.

### 2.2 Integration Testing
Integration tests ensure that different modules of the system work together correctly.
- **API Integration**: Testing the `ApiService` in the Flutter frontend against mock responses to ensure it correctly handles 200 OKs, 4xx errors, and 5xx errors.
- **Service Integration**: Testing that the `DataService` properly integrates with the Supabase database, respecting Row-Level Security (RLS) policies.

### 2.3 End-to-End (E2E) Testing
E2E testing simulates real user scenarios across the entire platform.
- **Scenario 1 (The Trigger)**: Simulate a patient logging a high glucose reading (> 11.6 mmol/L) in the Patient App. Verify that the backend processes this, triggers the Dynamic Risk Engine, and correctly flags the patient as "HIGH RISK". Finally, verify that the Clinician Dashboard immediately surfaces this Priority Alert at the top of the queue.
- **Scenario 2 (Clinical Action)**: Simulate a clinician adding a note and updating a risk threshold on the Clinician Dashboard. Verify the REST API correctly updates the database and the changes reflect on the frontend.

### 2.4 UI/UX Testing
Ensures the interfaces are responsive, accessible, and consistent.
- **Responsiveness**: Testing the Clinician Dashboard across desktop, tablet, and mobile views to ensure complex charts (e.g., dynamic interval charts) scale properly without overlapping labels.
- **Aesthetic Consistency**: Manual verification that the "Unified Ecosystem UX" is maintained. Ensuring that Risk colors (Green, Amber, Red) match exactly between the Patient and Clinician apps.

## 3. Security Testing
Given the strict "Zero Direct Database" policy, security testing is critical.
- **Authentication**: Verifying that invalid or expired JWT tokens are rejected by the Python middleware.
- **Authorization**: Attempting to fetch a patient's details using a clinician token that is *not* assigned to that patient to ensure RLS and API boundaries hold.
- **Endpoint Security**: Running tests in `florence/security_tests/` to verify that direct database queries from the frontend are impossible and that all data must route through the secure REST API.

## 4. Performance & Load Testing
- Ensuring the Clinician Dashboard's Dynamic Risk Engine can sort and render a queue of hundreds of patients without UI lag.
- Verifying the LLM Engine Service can handle concurrent requests for "Meal Vision" and "Lab Report Reader" without timing out.