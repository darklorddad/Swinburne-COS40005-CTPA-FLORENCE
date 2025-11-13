# Florence Authentication Flow

This document outlines the authentication architecture for the Florence platform, which uses a backend-driven model with client-side session management.

## Architectural Overview

The model is designed to centralise authentication logic on the backend while leveraging the `supabase_flutter` library on the client for secure and efficient session management.

-   **Backend (FastAPI Service):** Acts as the single point of contact for all initial authentication events (registration, login, email verification). It communicates with the Supabase authentication service using a secure service role key.
-   **Frontend (Flutter App):** Is responsible for UI and user interaction. It initiates authentication requests to the backend and manages the session it receives using the `supabase_flutter` library. It does not perform initial authentication itself.

---

## 1. Registration Flow

1.  **Client:** The user enters their details (name, email, password) into the registration form.
2.  **Client → Backend:** The app sends a POST request with the user's details to the `/auth/register` endpoint.
3.  **Backend:**
    a. Receives the request.
    b. Calls the Supabase `sign_up` function.
    c. Configures the verification email to contain a link pointing to a custom backend endpoint (e.g., `https://api.florence.com/auth/verify-email`).
    d. Creates the corresponding `patient_profile` record in the database.
4.  **Backend → Client:** Returns a success message, prompting the user to check their email.

---

## 2. Email Verification and First Sign-in Flow

This flow describes the secure "hand-off" of an authenticated session from the backend to the mobile client.

1.  **User Action:** The user clicks the verification link in their email.
2.  **Browser → Backend:** The link opens a web browser and navigates to the backend's `/auth/verify-email` endpoint, including a verification token from Supabase.
3.  **Backend:**
    a. Validates the token with the Supabase authentication service, which marks the user's email as confirmed.
    b. Generates a **new, secure, single-use token**.
    c. Redirects the user's browser to a custom app deep link, embedding the single-use token (e.g., `florence://login-with-token?one-time-token=...`).
4.  **OS → Client:** The mobile operating system opens the Florence app and passes the deep link to it.
5.  **Client → Backend:** The app starts, extracts the `one-time-token`, and immediately sends it to a new backend endpoint (e.g., `/auth/exchange-token`).
6.  **Backend:**
    a. Validates the single-use token.
    b. If valid, it generates a full, long-lived session with Supabase and receives a `refresh_token`.
7.  **Backend → Client:** The backend sends this `refresh_token` back to the app.
8.  **Client (Session Management):** The app calls `supabase.auth.setSession(refreshToken)`. The `supabase_flutter` library takes over, securely stores the session, and the app navigates to the dashboard.

---

## 3. Standard Login Flow

1.  **Client:** The user enters their email and password.
2.  **Client → Backend:** The app sends the credentials to the `/auth/login` endpoint.
3.  **Backend:**
    a. Validates the credentials with Supabase's `sign_in_with_password` function.
    b. On success, receives a session object containing a `refresh_token`.
4.  **Backend → Client:** The backend sends the `refresh_token` to the app.
5.  **Client (Session Management):** The app calls `supabase.auth.setSession(refreshToken)`, and the `supabase_flutter` library begins managing the session.

---

## 4. Session Refresh Flow (Client-Side)

Once a session is established, your custom backend is no longer involved in routine session maintenance.

1.  **Token Expiry:** The `access_token` managed by the `supabase_flutter` library expires (e.g., after one hour).
2.  **Automatic Refresh:** The library automatically uses the stored `refresh_token` to request a new `access_token` directly from the Supabase authentication service.
3.  **Local Update:** The library updates the session data stored securely on the device. This process is seamless and does not involve your custom backend.

---

## 5. Logout Flow

1.  **Client:** The user taps "Sign Out".
2.  **Client → Backend:** The app sends a request to a `/auth/logout` endpoint on the backend.
3.  **Backend:** Uses its admin privileges to instruct Supabase to invalidate the user's session on the server, making the refresh token unusable.
4.  **Backend → Client:** Returns a success message.
5.  **Client (Session Management):** Upon success, the app calls `supabase.auth.signOut()` to clear the session data from the device's local storage, which triggers navigation back to the login screen.
