import subprocess
import os
import sys
import time # Added for the startup delay
from patient_gui import PatientDataGUI
import tkinter as tk
import yaml


def run_analysis_pipeline():
    """
    This script is the entry point for the GUI application.
    It will start the continuous data generation in the background
    and then launch the GUI to display the analysis.
    """
    print("--- Step 1: Starting continuous data generation in a separate process... ---")
    
    # Use subprocess to run generate_data.py independently
    # This allows the data file to be continuously updated in the background
    try:
        # Popen is used to run the script asynchronously
        subprocess.Popen([sys.executable, "generate_data.py"])
        print("Data generation script started. Data files will be created and updated.")
        
        # Add a delay to allow the data script to start up and create the initial files.
        # This fixes the race condition where the GUI tries to read a non-existent file.
        print("Waiting for 3 seconds for initial data generation...")
        time.sleep(3) 

    except Exception as e:
        print(f"Error starting data generation process: {e}")
        # The GUI will display an error message if data generation fails,
        # so we can continue to launch the GUI.
        pass

    print("\n--- Step 2: Launching the Patient Data Analytics GUI... ---")
    try:
        app = PatientDataGUI()
        app.mainloop()
    except Exception as e:
        print(f"Error launching GUI: {e}")

if __name__ == "__main__":
    run_analysis_pipeline()
