# Florence Platform Service Documentation

---

## Overview
The Florence Platform Service is a comprehensive cross-platform frontend application built with the Flutter framework. It provides the primary user interface for all system participants including patients, clinicians and administrators. The application delegates complex processing to external backend services to manage health data, trigger artificial intelligence pipelines and display real-time clinical insights. The system enforces a strict separation of concerns where the frontend handles state representation and the backend manages data integrity.

---

## Architecture
The application follows a feature-first architectural pattern to group related screens, providers and models. It heavily utilises the Riverpod package for reactive state management and dependency injection. The system connects directly to the Supabase client solely for secure user authentication and token persistence. All clinical data operations route through a custom application programming interface service that attaches the active session token to outgoing requests. This design ensures the frontend never bypasses backend business logic.

---

## Core Configuration
The system requires specific environment variables to resolve backend endpoints and authenticate with the infrastructure. The developer must supply these values during the build process using Dart define flags.

* `DATA_SERVICE_URL`: The endpoint for the primary data backend.
* `LLM_CHATBOT_SERVICE_URL`: The endpoint for the conversational agent.
* `LLM_ENGINE_SERVICE_URL`: The endpoint for the artificial intelligence engine.
* `SUPABASE_URL`: The project URL provided by the authentication host.
* `SUPABASE_ANON_KEY`: The public key required for client-side authentication.

---

## Directory Structure
The repository contains modular directories that govern the frontend functionality.

* `lib/main.dart`: The primary entry point that initialises the environment and application binding.
* `lib/app.dart`: The core application widget that manages global routing and authentication state transitions.
* `lib/features/`: A directory containing all domain-specific logic separated by user role (patient, clinician and admin).
* `lib/core/`: A directory housing global utilities, configuration files, network services and notification handlers.
* `lib/config/`: A directory containing global routing definitions and theme configurations.
* `lib/shared/`: A directory containing reusable user interface components.
* `pubspec.yaml`: The configuration file that defines Flutter dependencies and asset paths.
* `shorebird.yaml`: The configuration file for over-the-air application updates.
* `vercel.json`: The deployment configuration file for web hosting.

---

## Security and Privacy
The platform implements dedicated services to handle sensitive clinical information.

* **Encryption Service**: The system provides utilities to hash passwords, generate secure tokens and encrypt specific data payloads before transit.
* **Data Anonymisation**: The application includes algorithms to mask personally identifiable information. The system can obscure names, email addresses, phone numbers and identification strings to produce safe analytical datasets.

---

## Package Management
This repository contains a Dart and Flutter application. It relies on the standard Flutter pub package manager to resolve dependencies such as Riverpod, graphical charting libraries and image processing tools. The application integrates Shorebird to enable seamless over-the-air updates for deployed mobile applications.

---

## Installation Instructions
The developer must follow these steps to prepare the local environment.

1. Install the Flutter software development kit on the host system.
2. Execute the package retrieval command to install the required dependencies.
3. Define the required environment variables during the build process or via a configuration file.
4. Launch the application on a web browser, simulator or physical device.

---

## Core Services

### Network Management
The application implements a central network service to execute all HTTP requests. The service intercepts outgoing calls to append the active JSON Web Token. It includes logic to automatically refresh expired sessions and retry transient network failures. It explicitly short-circuits data requests if the user is unauthenticated to prevent console errors during logout transitions.

### Pattern Detection
The frontend includes a local pattern detection service to identify critical health events immediately after a user logs data. The system evaluates new readings against personalised thresholds to generate real-time alerts for glucose spikes, consecutive high readings or prolonged inactivity.

### Notification System
The notification service acts upon the patterns detected in the health data. It generates local alerts, educational tips and motivational messages. If the user records a dangerously high blood pressure or an extreme glucose drop, the system immediately surfaces a critical priority alert prompting them to seek medical attention.

---

## Patient Interface Features

### Home Dashboard
The patient dashboard provides a high-level summary of the user health state. It displays a dynamically generated artificial intelligence insight card, a grid of quick actions for data entry and compact cards summarising recent biometrics such as glucose, blood pressure and physical activity.

### Health Analytics
The system offers dedicated analytical views for every supported biometric. Each detail screen presents interactive charts that plot historical readings against target safe zones.

* **Glucose**: Displays linear trends, time in range percentages and a twenty-four hour modal view mapping daily patterns.
* **Blood Pressure**: Plots systolic and diastolic readings simultaneously and calculates average pulse pressure.
* **Cholesterol**: Features a breakdown chart dividing total cholesterol into distinct lipid types and evaluates the overall ratio.
* **Body Mass Index**: Tracks weight fluctuations and categorises the current index into standard or personalised risk brackets.
* **Activity**: Renders a GitHub style heatmap to track daily activity streaks and logs total active minutes.
* **Diet**: Evaluates the glucose impact of meals by correlating pre-meal and post-meal readings to calculate the average spike.

### Data Logging
The platform provides robust data entry forms with strict input validation to prevent clinically impossible values. 

* **Artificial Intelligence Auto-Fill**: When logging a meal or uploading a laboratory report, the user can utilise artificial intelligence features. The system transmits the selected image to the external vision model which returns estimated calories, meal descriptions or parsed lipid panel values to automatically populate the input fields.

### Medication Management
The medication section features a tabbed interface splitting the daily schedule from the permanent clinical cabinet. The daily schedule acts as a checklist allowing patients to tap doses to mark them as taken or skipped. The application automatically calculates adherence rates based on these interactions.

### Clinical Insights
The platform synthesises recent data to produce actionable guidance.

* **Vitality Index**: The frontend calculates a proprietary score out of one hundred based on glucose control, activity levels, medication adherence and logging consistency. 
* **Recommendations**: The system displays a tiered list of health recommendations generated by the external language model. Each recommendation includes specific action items and references the exact data points that triggered the advice.

### Conversational Agent
The application includes a chat interface where patients can ask questions about their health data. The system renders the agent responses using Markdown to support lists and bold formatting. 

---

## Clinician Interface Features

### Caseload Dashboard
The clinician dashboard provides immediate visibility into patient status. It features a priority alerts feed highlighting patients who breached clinical thresholds. The primary patient list supports rapid filtering by calculated risk level or the date of their last logged entry.

### Patient Oversight
When reviewing a specific patient, the clinician has access to a comprehensive profile.

* **Medical Profile**: The clinician can review active and resolved diseases, adjust customised clinical thresholds and manage the active medication schedule.
* **Analytics**: The clinician views the exact same interactive charts available to the patient but framed within the context of clinical supervision.
* **Clinical Notes**: The system provides a private scratchpad where the clinician can log secure observations regarding the patient treatment plan.

---

## Administrator Interface Features

### Access Control
The administrative system enforces strict role-based access. Global administrators possess full visibility across all system organisations while hospital administrators are restricted to managing users within their specific facility. The frontend utilises a dedicated permission guard widget to conditionally render buttons and navigation links based on these roles.

### System Management
The administrative dashboard presents key performance indicators including total user counts and system-wide critical alerts.

* **Organisations**: Administrators can register new clinics or hospitals, defining their operating hours and contact details.
* **Users**: The interface provides tools to register new clinicians, assign them to specific facilities and manage their authentication credentials.
* **Patients**: Administrators can review the global patient directory, assign patients to specific clinicians or permanently wipe health data.

### Simulation Engine
The administration module includes a testing interface to generate synthetic data. The administrator can input a mock patient name and select a clinical persona. The application then instructs the external language model engine to orchestrate thirty days of realistic meals, activities and biometric readings to populate the test account.

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