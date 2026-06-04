# FLORENCE System Architecture

## 1. Executive Summary
FLORENCE is an AI-Enabled Digital Health Platform built with a modern, decoupled architecture. It ensures enterprise-grade security, scalability, and seamless integration between patients, clinicians, and administrators. 

## 2. High-Level Architecture
The platform is composed of three primary user-facing frontends that communicate with a suite of backend microservices via a secure REST API.

### 2.1 Frontends (Flutter)
- **Patient App**: A mobile-first application focused on daily logging, AI insights, and habit tracking.
- **Clinician Dashboard**: A responsive, tablet/desktop-optimized interface featuring the Dynamic Risk Engine, historical analytics, and patient oversight tools.
- **Admin Portal**: A web-based management console for user onboarding, metric tracking, and clinician-patient assignment.

### 2.2 Strict "Zero Direct Database" Policy
To comply with healthcare security standards, **none of the frontend applications connect directly to the database**. All read/write operations are routed through the secure middleware REST API. 

## 3. Backend Microservices (Python / FastAPI)
The backend is split into dedicated microservices to handle specific domains:

### 3.1 Data Service (`florence/data_service`)
- Acts as the primary CRUD interface between the frontends and the database.
- Handles endpoints like `/clinicians/me/patients/{id}` and `/clinicians/me/patients/{id}/assess-risk`.
- Enforces Row-Level Security (RLS) policies by passing authenticated tokens.

### 3.2 LLM Chatbot Service (`florence/llm_chatbot_service`)
- Manages the conversational AI agent within the Patient App.
- Has access to the patient's medical history to provide context-aware answers.

### 3.3 LLM Engine Service (`florence/llm_engine_service`)
- Powers the asynchronous AI features.
- Handles the **Meal Vision AI** (processing images to extract calories/macros).
- Handles the **Lab Report Reader** (extracting metrics from uploaded blood tests).
- Generates the **AI Daily Insight** and **Personalized Recommendations** based on nightly batch processing of user logs.

## 4. Database Layer (Supabase / PostgreSQL)
- **Central Storage**: Houses all user profiles, vital logs, clinical notes, and system configurations.
- **Security**: Utilizes PostgreSQL Row-Level Security (RLS) to ensure patients can only see their own data, and clinicians can only see data for assigned patients.
- **Authentication**: JWT-based authentication managed via Supabase Auth, passed seamlessly to the Python middleware.

## 5. Unified Ecosystem UX
Despite the architectural separation, the platform shares a unified design language (defined in `AppTheme`). Color-coding (e.g., Green for On Track, Red for High Risk) is universally applied across the Patient, Clinician, and Admin interfaces, ensuring zero translation gap between users.