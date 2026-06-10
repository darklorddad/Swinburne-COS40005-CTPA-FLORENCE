# Florence Platform Service Documentation

---

## Overview
The Florence Platform Service is a highly scalable cross-platform frontend application built with the Flutter framework. It provides the primary user interface for all system participants including patients, clinicians and administrators. The application delegates complex processing to external backend services to manage health data, trigger artificial intelligence pipelines and display real-time clinical insights. The system enforces a strict separation of concerns where the frontend handles state representation and the backend manages data integrity.

---

## Architecture and State Management
The application follows a feature-first architectural pattern to group related screens, providers and data models. It heavily utilises the Riverpod package for reactive state management, dependency injection and asynchronous data caching. The system connects directly to the Supabase client solely for secure user authentication, deep link resolution and session persistence. 

All clinical data operations route through a custom singleton network service that automatically attaches the active JSON Web Token to outgoing requests. This design ensures the frontend never bypasses backend business logic. The application automatically invalidates all cached data providers upon sign-in or sign-out to guarantee state isolation between different user sessions.

## User Interface and Responsive Design
The platform implements a robust responsive layout system that adapts seamlessly across mobile, tablet and desktop environments. The system dynamically adjusts grid columns, font sizes and padding metrics based on the active viewport. It utilises distinct theme configurations for different user roles to provide immediate visual context. The application employs advanced graphical libraries to render highly interactive medical charts, performance gauges and activity heatmaps.

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
The repository contains modular directories that segregate the frontend functionality by domain.

* `lib/main.dart`: The primary entry point that initialises the environment and application binding.
* `lib/app.dart`: The core widget that manages global routing and listens to authentication state transitions.
* `lib/config/`: A directory defining global routing maps, application constants and colour palettes.
* `lib/core/`: A directory housing global utilities, data formatters, input validators, network services and the responsive layout engine.
* `lib/shared/`: A directory containing reusable components such as custom buttons, loading indicators and empty state illustrations.
* `lib/features/patient/`: A directory containing the patient application including the unified dashboard, logging forms, analytics screens, medication trackers and chatbot interface.
* `lib/features/clinician/`: A directory containing the healthcare professional portal including caseload overviews, alert feeds and patient detail views.
* `lib/features/admin/`: A directory containing the administrative console including user management, organisation registration and the synthetic data simulator.

---

## Security and Privacy
The platform implements dedicated services to process sensitive clinical information securely.

* **Encryption Service**: The system provides utilities to hash passwords, generate secure tokens and encrypt specific data payloads before transit.
* **Data Anonymisation**: The application includes algorithms to mask personally identifiable information. The system can obscure names, email addresses, phone numbers and identification strings to produce safe analytical datasets.

---

## Package Management
This repository contains a Dart and Flutter application. It relies on the standard Flutter pub package manager to resolve dependencies such as Riverpod, graphical charting libraries, Markdown renderers and image processing tools. The application integrates Shorebird to enable seamless over-the-air updates for deployed mobile applications.

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
The application implements a central network service to execute all HTTP requests and multipart file uploads. The service intercepts outgoing calls to append the active JSON Web Token. It includes logic to automatically refresh expired sessions and retry transient network failures. It explicitly short-circuits data requests if the user is unauthenticated to prevent console errors during logout transitions.

### Pattern Detection
The frontend includes a local pattern detection service to identify critical health events immediately after a user logs data. The system evaluates new readings against personalised clinical thresholds to generate real-time alerts for severe glucose spikes, consecutive high readings, missed medications or prolonged physical inactivity.

### Notification System
The notification service acts upon the patterns detected in the health data. It generates local alerts, educational tips and motivational messages within the application. If the user records a dangerously high blood pressure or an extreme glucose drop, the system immediately surfaces a critical priority alert prompting them to seek medical attention.

---

## Patient Application Features

### Home Dashboard
The patient dashboard provides a high-level summary of the user health state. It displays a dynamically generated artificial intelligence insight card with a unique scanning animation. It features a grid of quick actions for rapid data entry and compact cards summarising recent biometrics such as glucose, blood pressure and body mass index.

### Health Analytics
The system offers dedicated analytical views for every supported biometric. Each detail screen presents interactive charts that plot historical readings against target safe zones.

* **Glucose**: Displays linear trends, time in range percentages and a twenty-four hour modal view mapping daily patterns.
* **Blood Pressure**: Plots systolic and diastolic readings simultaneously and calculates average pulse pressure.
* **Cholesterol**: Features a stacked bar chart dividing total cholesterol into distinct lipid types and evaluates the overall ratio via a custom painted pie chart.
* **Body Mass Index**: Tracks weight fluctuations, calculates the body mass index dynamically and categorises the current index into standard or personalised risk brackets using a custom visual gauge.
* **Activity**: Renders a GitHub style heatmap to track daily activity streaks and logs total active minutes.
* **Diet**: Evaluates the glucose impact of meals by correlating pre-meal and post-meal readings to calculate the average spike. It renders a traffic light calendar indicating daily dietary control.

### Data Logging
The platform provides robust data entry forms with strict input validation to prevent clinically impossible values. A unified sliding bottom sheet allows patients to quickly select which metric they wish to log.

* **Artificial Intelligence Auto-Fill**: When logging a meal or uploading a laboratory report, the user can utilise artificial intelligence features. The system transmits the selected image or document to the external vision model which returns estimated calories, meal descriptions, parsed lipid panel values or parsed blood sugar levels to automatically populate the input fields.

### Medication Management
The medication section features a tabbed interface splitting the daily schedule from the permanent clinical cabinet. The daily schedule acts as a dynamic checklist allowing patients to tap specific doses to mark them as taken or skipped. The application automatically calculates adherence rates based on these daily interactions. The clinical cabinet allows users to search a global medication dictionary to add new prescriptions.

### Clinical Insights
The platform synthesises recent data to produce actionable guidance.

* **Vitality Index**: The frontend calculates a proprietary score out of one hundred based on time in range, activity levels, medication adherence and logging consistency. It renders a circular progress gauge to display the score visually.
* **Recommendations**: The system displays a tiered list of health recommendations generated by the external language model. Each recommendation includes specific action items, an explanation of the expected impact and references the exact data points that triggered the advice.

### Conversational Agent
The application includes a persistent chat interface where patients can ask questions about their health data. The system renders the agent responses using Markdown to support complex text formatting. It includes suggested quick reply chips to help patients begin the conversation.

---

## Clinician Portal Features

### Caseload Dashboard
The clinician dashboard provides immediate visibility into patient status. It features a priority alerts feed highlighting patients who recently breached clinical thresholds or missed medications. The primary patient list supports rapid filtering by calculated risk level or the date of their last logged entry.

### Patient Oversight
When reviewing a specific patient, the clinician has access to a comprehensive clinical profile spanning multiple tabs.

* **Overview**: The clinician can review recent metrics, current risk levels and automated actions logged by the artificial intelligence engine.
* **Medical Profile**: The clinician can review active and resolved diseases, adjust customised clinical thresholds and prescribe new medications directly to the patient cabinet.
* **Analytics**: The clinician views detailed interactive charts framing patient data over varied time horizons to support diagnostic supervision.
* **Clinical Notes**: The system provides a private scratchpad where the clinician can log secure timestamped observations regarding the patient treatment plan.

---

## Administrative Console Features

### Access Control
The administrative system enforces strict role-based access. Global administrators possess full visibility across all system organisations while hospital administrators are restricted to managing users within their specific facility. The frontend utilises a dedicated permission guard widget to conditionally render user interface elements based on these roles.

### System Management
The administrative dashboard presents key performance indicators including total user counts, active clinician ratios and system-wide critical alerts.

* **Organisations**: Administrators can register new clinics or hospitals, specifying their facility type, operating hours and contact details.
* **Clinician Directory**: The interface provides tools to register new medical professionals, assign them to specific facilities and manage their authentication credentials.
* **Patient Directory**: Administrators can review the global patient list, manually assign patients to specific clinicians, modify risk tiers or permanently wipe protected health information.

### Simulation Engine
The administration module includes a sophisticated testing interface to generate synthetic data. The administrator can input a mock patient name and select a specific clinical persona. The application then instructs the external language model engine to orchestrate thirty days of realistic meals, activities and biometric readings to populate the test account automatically.

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
