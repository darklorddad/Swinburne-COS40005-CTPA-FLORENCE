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

The API will be available at `http://127.0.0.1:8000`, and the interactive documentation (Swagger UI) can be accessed at `http://127.0.0.1:8000/docs`.

## Developer Tool

A simple GUI tool is provided to help with common development tasks like seeding test data.

To run the tool, execute the following command from the project root directory:

```bash
python -m florence.data_service.data_service_devtool.devtool
```
