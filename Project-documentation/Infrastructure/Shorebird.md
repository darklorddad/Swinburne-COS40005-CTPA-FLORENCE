# Florence: Infrastructure - Shorebird

---

## 1. Overview and Purpose
Shorebird provides Over-The-Air (OTA) update capabilities for the Florence Flutter application. It allows the development team to push critical bug fixes, UI tweaks and performance improvements directly to user devices without requiring a full release.

---

## 2. Configuration and Secrets Management
| Environment Variable/Secret | Description | Where it is stored | Required By |
| :--- | :--- | :--- | :--- |
| `SHOREBIRD_TOKEN` | Authentication token for the Shorebird CLI. | GitHub Secrets | GitHub Actions CI/CD |
| `app_id` | Unique identifier for the Florence app (`518a6fe4-4e94-4d82-9984-b2f513f9f78a`). | `shorebird.yaml` (Source Code) | Flutter App, Shorebird CLI |

---

## 3. Technical Implementation Details
*   **App Configuration:** The application is registered in Shorebird with the designated App ID. The `shorebird.yaml` file is committed to version control to ensure the build pipeline can correctly identify the target application during compilation.
*   **Automatic Updates:** The `auto_update` feature is currently enabled by default. When a user launches the Florence app it will silently check for and download available patches in the background ensuring users always have the latest stable code.
*   **Release vs Patch Strategy:** 
    *   **Full Releases:** When the `version` in `pubspec.yaml` is incremented, the CI/CD pipeline executes `shorebird release android` to compile a new binary and upload it to Firebase App Distribution.
    *   **OTA Patches:** When code is merged to the production branch without a version bump the pipeline executes `shorebird patch android`. This pushes the Dart and Flutter changes directly to the Shorebird servers.
*   **Tracks:** Patches are published to the default `stable` track. Shorebird also supports `beta` or custom tracks which can be utilised in the future for percentage-based rollouts or internal testing groups (pro plan might be required for this).
*   **Flutter Engine:** The application is currently compiled against Flutter version 3.38.4. 

---

## 4. Billing Limits and Day 2 Operations
*   **Current Tier:** Free
*   **Patching Constraints:** OTA patches can only modify Dart and Flutter code. They cannot modify native Android or iOS code, add new native dependencies to `pubspec.yaml` or change the underlying Flutter engine version. If native changes or new third-party packages are required, a full release must be triggered by bumping the version number.
*   **Day 2 Operations:** To push a hotfix the development team simply merges the corrected Dart code into the `production` branch. The GitHub Actions workflow will automatically detect the lack of a version change and deploy the patch via Shorebird.

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
</style>