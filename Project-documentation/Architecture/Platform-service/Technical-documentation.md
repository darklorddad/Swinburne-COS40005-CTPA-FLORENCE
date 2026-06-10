# Florence Platform Service Documentation

## Overview
The Florence Platform Service is a comprehensive cross-platform frontend application built with Flutter. It provides the user interface for all system participants including patients, clinicians and administrators. The application communicates with external backend services to manage health data, trigger artificial intelligence analyses and display real-time clinical insights.

## Architecture
The application follows a feature-first architectural pattern. It heavily utilises Riverpod for reactive state management and dependency injection. The system connects directly to Supabase solely for secure user authentication and session persistence. All other data operations route through the external backend to ensure strict business logic enforcement and data validation.

## Environment Configuration
The system requires specific environment variables to connect to the backend services. The developer must supply these values during the build process.

* DATA_SERVICE_URL: The endpoint for the primary data backend.
* LLM_CHATBOT_SERVICE_URL: The endpoint for the conversational agent.
* LLM_ENGINE_SERVICE_URL: The endpoint for the artificial intelligence engine.
* SUPABASE_URL: The project URL provided by the authentication host.
* SUPABASE_ANON_KEY: The public key required for client-side authentication.

## Directory Structure
The repository contains several core files and directories that govern the frontend functionality.

* lib/main.dart: The primary entry point that initialises the environment and application binding.
* lib/app.dart: The core application widget that manages global routing and authentication state transitions.
* lib/features/: A directory containing all domain-specific logic separated by user role (patient, clinician and admin).
* lib/core/: A directory housing global utilities, configuration files, network services and notification handlers.
* lib/config/: A directory containing global routing definitions and theme configurations.
* lib/shared/: A directory containing reusable user interface components.
* pubspec.yaml: The configuration file that defines Flutter dependencies and asset paths.
* shorebird.yaml: The configuration file for over-the-air application updates.
* vercel.json: The deployment configuration file for web hosting.

## Package Management
The developer should note that this repository contains a Dart and Flutter application. It does not utilise the uv package manager used in the Python backend services. Instead, the project relies on the standard Flutter pub package manager to resolve dependencies. The application also integrates Shorebird to enable seamless over-the-air updates for deployed applications.

## Installation Instructions
The developer must follow these steps to prepare the local environment.

1. Install the Flutter software development kit on the host system.
2. Execute the package retrieval command to install the required dependencies.
3. Define the required environment variables during the build process or via a configuration file.
4. Launch the application on a web browser, simulator or physical device.

## Application Modules

### Authentication Module
The authentication module manages the login and registration workflows. The system automatically routes users to their specific dashboard based on their assigned role upon successful authentication. It maintains session state via deep links and background token refreshes.

### Patient Module
The patient module provides the primary interface for individuals managing chronic conditions. The module includes a comprehensive dashboard, interactive charts for biometric trends, a unified data logging interface and a medication adherence tracker. Patients can also interact with the artificial intelligence chatbot and review personalised health recommendations.

### Clinician Module
The clinician module enables healthcare professionals to monitor their assigned patients. The interface presents a dashboard highlighting critical alerts, risk level assessments and detailed biometric analytics. Clinicians can adjust patient health thresholds, prescribe medications and record private clinical notes.

### Administrator Module
The administrator module delivers global oversight capabilities. Authorised administrators can view all system users, manage healthcare organisations and assign clinicians to specific patients. The module includes a dedicated simulation interface that triggers the external language model to generate realistic synthetic patient data for testing purposes.