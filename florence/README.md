# Florence Authentication Architecture

This document outlines the authentication architecture for the Florence platform.

## Architectural Overview

The platform uses a **hybrid authentication model**. This approach splits responsibilities between the backend service and the frontend client to achieve an optimal balance of security, efficiency, and implementation simplicity.

-   **Backend (FastAPI Service):** Handles user registration and login. This is a deliberate choice that allows the backend to couple authentication with critical business logic (e.g., creating a `patient_profile` record) in a secure, transactional manner.
-   **Frontend (Flutter App):** Handles session management, sign-out, and the email verification flow. It leverages the `supabase_flutter` library to securely manage the session on the device after the initial login.

---

## Detailed Authentication Flows

### 1. Registration Flow (Backend-Handled)

1.  **Client:** The user enters their details (name, email, password) in the registration screen.
2.  **Client → Backend:** The app sends a POST request with the user's details to the `/auth/register` endpoint.
3.  **Backend:**
    a. Receives the request and calls the Supabase `sign_up` function. It configures the verification email to contain a deep link back to the app (e.g., `florence://login-callback`).
    b. After the Supabase user is created, the backend creates a corresponding `patient_profile` record in the database, linking it to the new user's ID.
4.  **Backend → Client:** Returns a success message, prompting the user to check their email for verification.

### 2. Login Flow (Backend-Handled)

1.  **Client:** The user enters their email and password in the login screen.
2.  **Client → Backend:** The app sends a POST request with the credentials to the `/auth/login` endpoint.
3.  **Backend:**
    a. Validates the credentials by calling Supabase's `sign_in_with_password` function.
    b. On success, receives a full session object from Supabase.
4.  **Backend → Client:** The backend returns the session object, which includes a `refresh_token`, to the client.
5.  **Client (Session Management):** The app calls `supabase.auth.setSession(refreshToken)`. This hands the session over to the `supabase_flutter` library, which securely stores it on the device and begins managing its lifecycle.

### 3. Email Verification Flow (Client-Side)

This flow bypasses the custom backend entirely for maximum efficiency.

1.  **User Action:** The user clicks the verification link in their email (e.g., `florence://login-callback#access_token=...`).
2.  **OS → Client:** The mobile operating system opens the Florence app due to the custom `florence://` URL scheme.
3.  **Client (Supabase SDK):**
    a. The `supabase_flutter` library, initialised at app startup, automatically intercepts the incoming deep link.
    b. It parses the `access_token` and `refresh_token` from the URL fragment.
    c. It communicates **directly with the Supabase Auth service** to confirm the email verification.
    d. It creates and securely stores the session locally on the device.
4.  **Client (Navigation):** The successful creation of the session triggers the app's central `onAuthStateChange` listener, which automatically navigates the user from the splash/login screen to the main dashboard.

### 4. Session Refresh Flow (Client-Side)

Once a session is established, the `supabase_flutter` library handles refreshes automatically.

1.  **Token Expiry:** The `access_token` has a short lifespan (e.g., one hour).
2.  **Automatic Refresh:** When the token expires, the library automatically uses the stored `refresh_token` to request a new `access_token` directly from the Supabase Auth service, without involving your custom backend.
3.  **Local Update:** The library updates the session data stored securely on the device. This process is seamless to the user.

### 5. Logout Flow (Client-Side)

1.  **Client:** The user taps "Sign Out".
2.  **Client (Supabase SDK):** The app directly calls `supabase.auth.signOut()`. This single function performs two critical actions:
    a. It sends a request to the Supabase Auth service to invalidate the session on the server.
    b. It clears the session data from the device's local storage.
3.  **Client (Navigation):** The `onAuthStateChange` listener detects the sign-out event and navigates the user back to the login screen.

---

## Rationale for the Hybrid Architecture

This model was chosen for the following reasons:

-   **Security & Business Logic:** Handling registration and login on the backend allows for secure, transactional operations. For example, we can guarantee that a `patient_profile` is created if, and only if, the authentication user is successfully created.
-   **Efficiency & Simplicity:** Using the client-side SDK for email verification and logout leverages the library's optimised, built-in functionality. This avoids the complexity of a fully backend-driven email verification flow (which would require multiple redirects and token exchanges) while maintaining a strong security posture.
-   **Best of Both Worlds:** The architecture combines the control of a custom backend for critical, multi-step processes with the convenience and performance of the client-side SDK for standard, self-contained authentication tasks.
