# 07 FIREBASE APP DISTRIBUTION

## 1. Overview and Purpose
Firebase App Distribution serves as the primary platform for distributing pre-release Android application builds to beta testers and the client. It allows the development team to gather feedback and conduct User Acceptance Testing before any potential public release on the Google Play Store.

## 2. Access and Ownership Transfer
*   **Current Owner:** Daniel Tiong / Group 7
*   **Project Name:** Swinburne-COS40005-FLORENCE
*   **Transfer Process for Client or IT Staff:**
    1. The Firebase Console is accessed and the Project Settings are opened.
    2. The "Users and permissions" tab is selected.
    3. Dr Vong or the BioTective IT team is invited via email and assigned the Owner role.
    4. Alternatively, the unrestricted invite link is shared directly with new testers.

## 3. Configuration and Secrets Management
The continuous integration pipeline utilises specific Firebase credentials to automatically upload compiled APK files after a successful build.

| Environment Variable | Description | Where it is stored | Required By |
| :--- | :--- | :--- | :--- |
| `FIREBASE_APP_ID` | The unique identifier for the Android application. | GitHub Secrets | GitHub Actions CI/CD |
| `FIREBASE_SERVICE_ACCOUNT_JSON_BASE64` | Base64 encoded service account key for secure API authentication. | GitHub Secrets | GitHub Actions CI/CD |
| `FIREBASE_TOKEN` | CLI token used for automated hosting or distribution tasks. | GitHub Secrets | GitHub Actions CI/CD |

## 4. Technical Implementation Details

### Project Architecture
*   **Project ID:** `swinburne-cos40005-florence`
*   **Project Number:** 609541142807
*   **Target Platform:** Android
*   **Package Name:** `com.vanq.florence`
*   **App ID:** `1:609541142807:android:5fd8a46d5d6a31e2b1df52`

### Tester Management
Testers are organised into groups to streamline the distribution process and ensure the correct builds reach the appropriate stakeholders.
*   **Tester Groups:** A primary group named `testers` is currently configured containing 6 members.
*   **Invite Links:** An unrestricted invite link (`https://appdistribution.firebase.dev/i/3eca3fb84c514316`) is active. This allows new testers to join the testing programme simply by clicking the link without requiring manual approval from the Firebase project owner.

### Automated Distribution
When code is merged into the `production` branch and a full release is triggered the GitHub Actions workflow compiles the Android APK and automatically uploads it to Firebase App Distribution. The release is instantly routed to the `testers` group and an email notification is sent to all members prompting them to update the application via the Firebase App Distribution tester app.

## 5. Billing Limits and Day 2 Operations
*   **Current Tier:** Free (Spark Plan). Firebase App Distribution is currently free to use for distributing pre-release apps to testers.
*   **Adding New Testers:** A new tester is added by sharing the unrestricted invite link or manually adding their email address to the `testers` group in the Firebase Console.
*   **Domain Restrictions:** The console currently warns that invitation restrictions cannot be enabled because the active invite link lacks domain restrictions. If the client wishes to restrict testing to a specific corporate email domain in the future they must delete the current unrestricted link and generate a new one with domain limitations applied.
*   **Day 2 Operations:** Testers should install the Firebase App Distribution application on their Android devices. When a new build is pushed via the CI/CD pipeline the tester will receive a notification and can update the Florence application directly from the distribution app.
