# 📄 01_GITHUB_AND_SOURCE_CONTROL.md

## 1. Overview & Purpose
*   **Repository Name:** `Swinburne-COS40005-CTPA-FLORENCE`
*   **Repository URL:** `https://github.com/darklorddad/Swinburne-COS40005-CTPA-FLORENCE`
*   **Current Owner:** Daniel Tiong (`darklorddad`)
*   **Purpose:** This repository serves as the single source of truth and centralised version control system for the entire Florence (BioTective) platform. It is structured as a monorepo containing the cross-platform Flutter frontend (Patient, Clinician and Admin dashboards) and the Python-based backend microservices.

## 2. Access & Ownership Transfer
*   **Current Access Level:** Admin (Owner)
*   **Transfer Steps for Client or IT Staff:** 
    1. Navigate to **Settings** and then **Collaborators and teams** (under the "Access" tab).
    2. Click **Add people** and search for the required GitHub username or email address.
    3. Assign the **Admin** role to allow full management of repository settings, secrets and branch protection rules.
*   *Note:* If full ownership transfer of the repository to a BioTective organisation is required in the future, this can be done via **Settings** and then **General** and then **Transfer ownership** (scroll to the Danger Zone).

## 3. Repository Structure (The Monorepo)
The codebase is organised into distinct service folders to separate concerns whilst keeping all project artefacts centralised:
*   📂 **`florence/platform_service/`**: The Flutter frontend application. Contains the Patient, Clinician and Admin dashboards. Includes `shorebird.yaml` for mobile OTA updates and `vercel.json` for web hosting.
*   📂 **`florence/data_service/`**: Python FastAPI microservice. Handles all CRUD operations, Supabase database proxying, role-based access control (RBAC) and file uploads.
*   📂 **`florence/llm_chatbot_service/`**: Python FastAPI microservice. Powers the patient-facing conversational AI chatbot using LangChain.
*   📂 **`florence/llm_engine_service/`**: Python FastAPI microservice. Handles background AI tasks including nutrition analysis (meal photos), risk assessment, biometric parsing and daily insight generation.
*   📂 **`System-Documentation/`**: Contains the compiled User Manuals, Architecture diagrams and Handover documents.
*   📂 **`.github/`**: Contains GitHub Actions workflows (`.yml` files) that automate CI/CD pipelines.

## 4. Branching Strategy & Version Control
The team utilises a streamlined branching model optimised for continuous integration, rapid deployment and repository hygiene:

*   **`main` branch:** The primary integration branch for all ongoing development. All new features, bug fixes and updates are merged here. This represents the latest stable development state.
*   **`production` branch:** The stable, release-ready branch. Code is strictly merged from `main` to `production` when a milestone is reached or a stable release is ready for deployment to live production environments and app stores.
*   **Feature & Backup Branches:** Created dynamically from `main` for isolated feature development or as backup snapshots before major refactors. To maintain a clean repository, these branches are constantly managed and deleted once they are merged or no longer needed.
*   **Pull Requests (PRs):** Used to merge feature branches into `main` to allow for code review and automated CI checks before integration.

## 5. GitHub Environments and Vercel Integration
To manage deployments securely and separate staging from live systems, the repository utilises GitHub Environments. These environments are directly managed and triggered by Vercel to handle continuous deployment for the backend microservices and the web frontend.

| Environment Name | Purpose | Target Service |
| :--- | :--- | :--- |
| **Preview - ds** | Staging and preview deployment for the Data Service | `data_service` |
| **Production - ds** | Live production deployment for the Data Service | `data_service` |
| **Preview - llmcs** | Staging and preview deployment for the Chatbot Service | `llm_chatbot_service` |
| **Production - llmcs** | Live production deployment for the Chatbot Service | `llm_chatbot_service` |
| **Preview - llmes** | Staging and preview deployment for the AI Engine | `llm_engine_service` |
| **Production - llmes** | Live production deployment for the AI Engine | `llm_engine_service` |
| **Production - web** | Live production deployment for Flutter Web (Admin and Clinician dashboards) | `platform_service` |

Vercel monitors the repository and automatically routes deployments to the correct GitHub Environment based on the branch and directory structure. This ensures that preview links are generated for pull requests whilst production environments are strictly updated only when code is merged into the designated release branches.

## 6. Secrets Management
GitHub Secrets are used to securely pass credentials to GitHub Actions without exposing them in the source code. The following **Repository-level Secrets** are currently configured:

| Secret Name | Description & Usage |
| :--- | :--- |
| `CREDENTIAL_FILE_CONTENT` | Used for authenticating backend services or CI/CD pipelines with cloud providers. |
| `FIREBASE_APP_ID` | The unique identifier for the Firebase project, used by CI/CD to target the correct project for App Distribution (beta testing). |
| `FIREBASE_SERVICE_ACCOUNT_JSON_BASE64` | Base64 encoded service account key. Allows GitHub Actions to authenticate with Firebase securely to deploy builds or manage App Distribution. |
| `FIREBASE_TOKEN` | CLI token used for Firebase hosting deployments or automated testing environments. |
| `SHOREBIRD_TOKEN` | Authentication token for the Shorebird CLI. Allows GitHub Actions to push Over-The-Air (OTA) patches to the Flutter mobile app without requiring App Store or Play Store review. |

*Note: Environment-specific secrets (like Vercel tokens, Supabase URLs or OpenRouter API keys) are injected directly via the Vercel dashboard or specific GitHub Environment secrets to keep the main repository secrets clean and focused on CI/CD authentication.*

## 7. Local Development Setup (Quick Start)
For a new developer or IT staff member to clone and work with the repository:

1.  **Clone the repo:** 
    ```bash
    git clone https://github.com/darklorddad/Swinburne-COS40005-CTPA-FLORENCE.git
    cd Swinburne-COS40005-CTPA-FLORENCE
    ```
2.  **Checkout the development branch:**
    ```bash
    git checkout main
    ```
3.  **Pull latest changes:**
    ```bash
    git pull origin main
    ```
*(Refer to the respective backend and frontend documentation for environment setup, dependency installation and local execution commands).*