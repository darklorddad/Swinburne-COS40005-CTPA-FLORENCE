Here is the professional Markdown draft for **Document 6**, focusing on your Shorebird configuration and Over-The-Air update strategy. It is written in British English, strictly avoids the Oxford comma and contains no em dashes.

***

# 📄 06_SHOREBIRD.md

## 1. Overview and Purpose
Shorebird provides Over-The-Air (OTA) update capabilities for the Florence Flutter application. It allows the development team to push critical bug fixes, UI tweaks and performance improvements directly to user devices without requiring a full release through the Google Play Store or Apple App Store review processes.

## 2. Access and Ownership Transfer
*   **Current Owner:** Daniel Tiong (`danieltiong000@gmail.com`)
*   **App Name:** florence
*   **Transfer Steps for Client or IT Staff:**
    1. Log into the Shorebird Console.
    2. Navigate to the App Settings and scroll to the Danger Zone.
    3. Select "Transfer Ownership" to move the application to a BioTective organisation or another designated account.

## 3. Configuration and Secrets Management
| Environment Variable / Secret | Description | Where it is stored | Required By |
| :--- | :--- | :--- | :--- |
| `SHOREBIRD_TOKEN` | Authentication token for the Shorebird CLI. | GitHub Secrets | GitHub Actions CI/CD |
| `app_id` | Unique identifier for the Florence app (`518a6fe4-4e94-4d82-9984-b2f513f9f78a`). | `shorebird.yaml` (Source Code) | Flutter App, Shorebird CLI |

## 4. Technical Implementation Details
*   **App Configuration:** The application is registered in Shorebird with the designated App ID. The `shorebird.yaml` file is committed to version control to ensure the build pipeline can correctly identify the target application during compilation.
*   **Automatic Updates:** The `auto_update` feature is currently enabled by default. When a user launches the Florence app it will silently check for and download available patches in the background ensuring users always have the latest stable code.
*   **Release vs Patch Strategy:** 
    *   **Full Releases:** When the `version` in `pubspec.yaml` is incremented the CI/CD pipeline executes `shorebird release android` to compile a new binary and upload it to Firebase App Distribution or the respective app store.
    *   **OTA Patches:** When code is merged to the production branch without a version bump the pipeline executes `shorebird patch android`. This pushes the Dart and Flutter changes directly to the Shorebird servers.
*   **Tracks:** Patches are published to the default `stable` track. Shorebird also supports `beta` or custom tracks which can be utilised in the future for percentage-based rollouts or internal testing groups.
*   **Flutter Engine:** The application is currently compiled against Flutter version 3.38.4. 

## 5. Billing Limits and Day 2 Operations
*   **Current Tier:** Pro.
*   **Patching Constraints:** OTA patches can only modify Dart and Flutter code. They cannot modify native Android or iOS code, add new native dependencies to `pubspec.yaml` or change the underlying Flutter engine version. If native changes or new third-party packages are required a full store release must be triggered by bumping the version number.
*   **Day 2 Operations:** To push a hotfix the development team simply merges the corrected Dart code into the `production` branch. The GitHub Actions workflow will automatically detect the lack of a version change and deploy the patch via Shorebird.

***

### Next Steps
You can copy and paste this directly into your `/docs/handover/` folder. 

Would you like to move on to **Document 7: Firebase App Distribution** next?