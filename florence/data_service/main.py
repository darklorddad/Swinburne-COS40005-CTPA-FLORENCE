# main.py
import os
from fastapi import FastAPI, Depends, HTTPException, Header, Request
from fastapi.middleware.cors import CORSMiddleware
from typing import Optional, Dict, Any

# Import the router from your new authentication file
from .routers import authentication, patients, clinicians, admin, chat_history
# Import the Supabase client from its dedicated file
from .client import supabase

app = FastAPI()

# Add CORS middleware to allow requests from the Flutter web app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods
    allow_headers=["*"],  # Allows all headers
)

# Include the authentication router in your main application
app.include_router(authentication.router)
app.include_router(patients.router)
app.include_router(clinicians.router)
app.include_router(admin.router)
app.include_router(chat_history.router)

@app.get("/all-data")
def get_all_database_info():
    """
    An endpoint to automatically discover and fetch all records from all tables
    in the public schema of the database.
    """
    all_data = {}
    try:
        # Step 1: Call the RPC to get all table names.
        # This requires the 'get_all_table_names' function created in the Supabase SQL Editor.
        tables_response = supabase.rpc('get_all_table_names', {}).execute()
        
        if tables_response.data:
            table_names = [item['table_name'] for item in tables_response.data]

            # Step 2: Loop through each table name and fetch its data.
            for table_name in table_names:
                records_response = supabase.table(table_name).select('*').execute()
                all_data[table_name] = records_response.data
        
        return all_data

    except Exception as e:
        error_message = str(e)
        # Provide a helpful error if the user forgot to create the SQL function.
        if "function public.get_all_table_names() does not exist" in error_message:
            raise HTTPException(
                status_code=500, 
                detail="Error: The helper function 'get_all_table_names' was not found in your database. Please create it using the Supabase SQL Editor."
            )
        raise HTTPException(status_code=500, detail=f"An error occurred: {error_message}")


@app.delete("/delete/{table_name}/{record_id}")
async def delete_record(table_name: str, record_id: int):
    """
    An endpoint to delete a single record from a specified table by its ID.
    """
    try:
        # Perform the delete operation targeting the specific record by its 'id'
        response = supabase.table(table_name).delete().eq("id", record_id).execute()

        # If the data list is empty, it means no record was found with that ID to delete.
        if not response.data:
            raise HTTPException(status_code=404, detail=f"Record with id {record_id} not found in table {table_name}.")

        return {"message": f"Successfully deleted record {record_id} from {table_name}", "data": response.data}

    except HTTPException as http_exc:
        # Re-raise the HTTPException to ensure the correct status code (e.g., 404) is sent.
        raise http_exc
    except Exception as e:
        error_message = str(e)
        raise HTTPException(status_code=500, detail=f"An error occurred: {error_message}")


# --- Functions to retrieve all data from specific tables ---

@app.get("/organisations")
def get_organisations():
    """Fetches all records from the 'organisations' table."""
    try:
        response = supabase.table('organisations').select('*').execute()
        return response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/patient_profiles")
def get_patient_profiles():
    """Fetches all records from the 'patient_profiles' table."""
    try:
        response = supabase.table('patient_profiles').select('*').execute()
        return response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/clinician_profiles")
def get_clinician_profiles():
    """Fetches all records from the 'clinician_profiles' table."""
    try:
        response = supabase.table('clinician_profiles').select('*').execute()
        return response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/daily_patient_logs")
def get_daily_patient_logs():
    """Fetches all records from the 'daily_patient_logs' table."""
    try:
        response = supabase.table('daily_patient_logs').select('*').execute()
        return response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/patient_monitor_data")
def get_patient_monitor_data():
    """Fetches all records from the 'patient_monitor_data' table."""
    try:
        response = supabase.table('patient_monitor_data').select('*').execute()
        return response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/clinician_notes")
def get_clinician_notes():
    """Fetches all records from the 'clinician_notes' table."""
    try:
        response = supabase.table('clinician_notes').select('*').execute()
        return response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.put("/update/{table_name}/{record_id}")
async def update_table(table_name: str, record_id: int, request: Request):
    """
    An endpoint to update a single record in a specified table by its ID.
    The request body should be a JSON object with the columns to update.
    e.g., {"name": "New Name"}
    """
    try:
        update_data: Dict[str, Any] = await request.json()

        # Perform the update operation targeting the specific record by its 'id'
        response = supabase.table(table_name).update(update_data).eq("id", record_id).execute()

        # Supabase returns data if the update was successful. If not, the list will be empty.
        if not response.data:
            raise HTTPException(status_code=404, detail=f"Record with id {record_id} not found in table {table_name}.")

        return {"message": f"Successfully updated record {record_id} in {table_name}", "data": response.data}

    except HTTPException as http_exc:
        # Re-raise the HTTPException to ensure the correct status code (e.g., 404) is sent.
        raise http_exc
    except Exception as e:
        error_message = str(e)
        raise HTTPException(status_code=500, detail=f"An error occurred: {error_message}")


@app.post("/insert/{table_name}")
async def insert_table(table_name: str, request: Request):
    """
    An endpoint to insert a single record into a specified table.
    The request body should be a JSON object representing the row to insert.
    e.g., {"column1": "value1", "column2": "value2"}
    """
    try:
        # Get the JSON data from the request body
        record_data: Dict[str, Any] = await request.json()

        # Insert the data into the specified table
        response = supabase.table(table_name).insert(record_data).execute()
        
        return {"message": f"Successfully inserted data into {table_name}", "data": response.data}

    except Exception as e:
        # Catch potential errors, like table not found, or constraint violation.
        error_message = str(e)
        raise HTTPException(status_code=500, detail=f"An error occurred: {error_message}")
