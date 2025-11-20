# Florence Data Service

This directory contains the FastAPI backend for the Florence platform, which serves as the primary API layer between the frontend applications and the Supabase database.

## Prerequisites

- Python 3.8+
- A Supabase project.

## Setup

1.  **Configure Environment Variables:**

    Create a `.env` file in the project root directory (i.e., the parent of the `florence` directory). This file will store your Supabase credentials.

    ```
    # .env
    SUPABASE_URL="your-supabase-project-url"
    SUPABASE_SERVICE_KEY="your-supabase-service-role-key"
    ```

    -   `SUPABASE_URL`: Found in your Supabase project's "API" settings.
    -   `SUPABASE_SERVICE_KEY`: The `service_role` key, also found in the "API" settings. **Do not use the `anon` key.**

2.  **Install Dependencies:**

    Navigate to the `florence\data_service` directory and install the required Python packages.

    ```bash
    pip install -r requirements.txt
    ```

## Running the Service

To run the FastAPI server locally, execute the following command from the project root directory:

```bash
uvicorn florence.data_service.main:app --reload --host 0.0.0.0
```

This command is intended for local development. The `--reload` flag automatically restarts the server when code changes are detected, and `--host 0.0.0.0` makes the server accessible on your local network.

The API will be available at `http://127.0.0.1:8000`, and the interactive documentation (Swagger UI) can be accessed at `http://127.0.0.1:8000/docs`.

## Developer Tool

A simple GUI tool is provided to help with common development tasks like seeding test data.

To run the tool, execute the following command from the project root directory:

```bash
python -m florence.data_service.data_service_devtool.devtool
```

---

## Running the Complete Florence Platform

To run the complete platform (backend + frontend), you need to start both services.

### Frontend Prerequisites

- **Flutter 3.0+** - [Install Flutter](https://flutter.dev/docs/get-started/install)
- **Chrome Browser** - For web development

### Running Both Services

Open **two separate terminal windows**:

#### Terminal 1: Backend (FastAPI)

```bash
# Navigate to project root
cd Swinburne-COS40005-CTPA-FLORENCE

# Start backend
python -m uvicorn florence.data_service.main:app --reload --host 0.0.0.0 --port 8000
```

#### Terminal 2: Frontend (Flutter)

```bash
# Navigate to project root
cd Swinburne-COS40005-CTPA-FLORENCE

# Navigate to Flutter project
cd florence/platform_service

# Install dependencies (first time only)
flutter pub get

# Run the app in Chrome
flutter run -d chrome
```

**Expected output:**
```
Launching lib\main.dart on Chrome in debug mode...
Waiting for connection from debug service on Chrome...
This app is linked to the debug service: ws://127.0.0.1:XXXXX
Flutter application is running
```

Chrome will automatically open with the Florence app.

---

## Troubleshooting

### Backend Issues

**Problem: `uvicorn: command not found`**

```bash
# Solution: Use Python module syntax
python -m uvicorn florence.data_service.main:app --reload --host 0.0.0.0 --port 8000
```

**Problem: "Invalid API key" error when trying to login/register**

- Verify your `.env` file exists in the **project root directory** (parent of `florence` folder)
- Ensure you're using the `service_role` key, **NOT** the `anon` key
- The `.env` file should look like this:
  ```
  SUPABASE_URL="https://your-project.supabase.co"
  SUPABASE_SERVICE_KEY="eyJhbGc..."
  ```
- Restart the backend after creating/updating the `.env` file

**Problem: Port 8000 already in use**

```bash
# Solution: Use a different port
python -m uvicorn florence.data_service.main:app --reload --host 0.0.0.0 --port 8001

# Remember to update the Flutter config:
# Edit: florence/platform_service/lib/core/config/environment.dart
# Change: static const String apiUrl = 'http://127.0.0.1:8001';
```

### Frontend Issues

**Problem: "Failed to fetch" or "ClientException" errors**

- Ensure the **backend is running** on port 8000
- Verify the backend terminal shows `Application startup complete`
- Check that `florence/platform_service/lib/core/config/environment.dart` has:
  ```dart
  static const String apiUrl = 'http://127.0.0.1:8000';  // For Chrome
  ```
- Try refreshing the Chrome page or press `r` in the Flutter terminal for hot reload

**Problem: Flutter dependencies conflict**

```bash
# Solution: Clean and reinstall
cd florence/platform_service
flutter clean
flutter pub get
```

**Problem: Chrome doesn't open automatically**

```bash
# Check available devices
flutter devices

# Explicitly run on Chrome
flutter run -d chrome
```

### Connection Issues

**Problem: Frontend can't connect to backend**

1. Verify backend is running:
   - Open http://127.0.0.1:8000/docs in Chrome
   - You should see the Swagger API documentation

2. Check for CORS errors in Chrome DevTools (F12 → Console)
   - The backend already has CORS configured to allow all origins

3. Ensure both services are using the same host:
   - Backend: `0.0.0.0:8000`
   - Frontend config: `http://127.0.0.1:8000`

---

## Using the Application

### First Time Usage

1. **Start both backend and frontend** (as described above)

2. **Register a new account:**
   - Click "Sign Up" or "Create Account"
   - Enter your email and password (password must meet requirements)
   - Choose your role (Patient or Clinician)
   - Fill in required information
   - Click "Create Account"

3. **Login:**
   - Enter your registered email and password
   - Click "Sign In"
   - You should be redirected to the dashboard

4. **Explore the platform:**
   - Navigate through the dashboard
   - Add health data
   - View insights and analytics

---

## API Documentation

Once the backend is running, access the interactive API documentation:

- **Swagger UI:** http://127.0.0.1:8000/docs
- **ReDoc:** http://127.0.0.1:8000/redoc

These provide detailed information about all available endpoints, request/response schemas, and allow you to test API calls directly from the browser.
