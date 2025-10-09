import json
import random
import yaml
import pandas as pd
from datetime import datetime, timedelta
import os
import numpy as np
import time # <--- NEW: Import the time module

def load_config(filepath="config.yaml"):
    """
    Loads configuration settings from a YAML file.
    """
    try:
        with open(filepath, 'r') as file:
            config = yaml.safe_load(file)
        return config
    except FileNotFoundError:
        print(f"Error: The file {filepath} was not found.")
        return None
    except yaml.YAMLError as e:
        print(f"Error parsing YAML file: {e}")
        return None

def generate_patient_data(config):
    """
    Generates a more realistic patient dataset with logical event sequences.
    """
    if not config:
        return []

    dataset_config = config.get("dataset", {})
    patient_config = config.get("patient_attributes", {})
    gen_config = config.get("data_generation", {})
    num_patients = dataset_config.get("num_patients", 10)

    first_names = ["Jordan", "Alex", "Casey", "Taylor", "Morgan", "Sam", "Jamie"]
    last_names = ["Smith", "Jones", "Williams", "Brown", "Davis", "Miller", "Wilson"]

    records = []
    end_date = datetime.now()
    start_date = end_date - timedelta(days=gen_config.get("past_days_to_simulate", 7))

    for i in range(num_patients):
        patient_id = i + 1
        base_hba1c = round(random.uniform(*patient_config.get("hba1c_level_range", [5.5, 12.0])), 1)
        
        patient_info = {
            "name": f"{random.choice(first_names)} {random.choice(last_names)}",
            "age": random.randint(*patient_config.get("age_range", [20, 80])),
            "diabetes_type": random.choice(patient_config.get("diabetes_types", ["Type 1", "Type 2"])),
        }

        current_date = start_date
        while current_date <= end_date:
            hba1c_reading = base_hba1c + round(random.uniform(-0.5, 0.5), 1)
            hba1c_status = "Stable"
            if hba1c_reading > base_hba1c + 0.2:
                hba1c_status = "Increased"
            elif hba1c_reading < base_hba1c - 0.2:
                hba1c_status = "Decreased"

            glucose_level = round(random.uniform(6.0, 8.0), 1)
            glucose_status = f"Stable ({glucose_level} mmol/L)"
            diet_log = "Normal balanced diet"
            activity_log = "Moderate activity"

            if random.random() < gen_config.get("hyper_event_probability", 0.2):
                glucose_level = round(random.uniform(*patient_config.get("glucose_hyper_range_mmol_l", [10.0, 15.0])), 1)
                glucose_status = f"Hyper Event ({glucose_level} mmol/L after dinner)"
                diet_log = "Double cheeseburger, white bread, coffee"
                activity_log = "Exercised a total of 35 minutes"
            
            if random.random() < gen_config.get("hypo_event_probability", 0.15):
                glucose_level = round(random.uniform(*patient_config.get("glucose_hypo_range_mmol_l", [3.0, 4.5])), 1)
                glucose_status = f"Hypo Event ({glucose_level} mmol/L before exercise)"
                diet_log = "Tofu stir-fry with mixed vegetables"
                activity_log = "Swam for 40 minutes"

            records.append({
                "patient_id": patient_id,
                "name": patient_info["name"],
                "age": patient_info["age"],
                "diabetes_type": patient_info["diabetes_type"],
                "hba1c_reading": f"{hba1c_reading}%",
                "hba1c_status": hba1c_status,
                "date": current_date.strftime('%Y-%m-%d'),
                "glucose_reading": glucose_status,
                "diet_log": diet_log,
                "activity": activity_log,
            })
            current_date += timedelta(days=1)
            
    return pd.DataFrame(records)

def generate_single_record(config):
    """Generates a single new patient record in the detailed format."""
    patient_config = config.get("patient_attributes", {})
    gen_config = config.get("data_generation", {})

    first_names = ["Jordan", "Alex", "Casey", "Taylor", "Morgan", "Sam", "Jamie"]
    last_names = ["Smith", "Jones", "Williams", "Brown", "Davis", "Miller", "Wilson"]

    patient_id = random.randint(1, config.get("dataset", {}).get("num_patients", 10))
    base_hba1c = round(random.uniform(*patient_config.get("hba1c_level_range", [5.5, 12.0])), 1)
    
    patient_info = {
        "name": f"{random.choice(first_names)} {random.choice(last_names)}",
        "age": random.randint(*patient_config.get("age_range", [20, 80])),
        "diabetes_type": random.choice(patient_config.get("diabetes_types", ["Type 1", "Type 2"])),
    }

    hba1c_reading = base_hba1c + round(random.uniform(-0.5, 0.5), 1)
    hba1c_status = "Stable"
    if hba1c_reading > base_hba1c + 0.2:
        hba1c_status = "Increased"
    elif hba1c_reading < base_hba1c - 0.2:
        hba1c_status = "Decreased"

    glucose_level = round(random.uniform(6.0, 8.0), 1)
    glucose_status = f"Stable ({glucose_level} mmol/L)"
    diet_log = "Normal balanced diet"
    activity_log = "Moderate activity"

    if random.random() < gen_config.get("hyper_event_probability", 0.2):
        glucose_level = round(random.uniform(*patient_config.get("glucose_hyper_range_mmol_l", [10.0, 15.0])), 1)
        glucose_status = f"Hyper Event ({glucose_level} mmol/L after dinner)"
        diet_log = "Double cheeseburger, white bread, coffee"
        activity_log = "Exercised a total of 35 minutes"
    
    if random.random() < gen_config.get("hypo_event_probability", 0.15):
        glucose_level = round(random.uniform(*patient_config.get("glucose_hypo_range_mmol_l", [3.0, 4.5])), 1)
        glucose_status = f"Hypo Event ({glucose_level} mmol/L before exercise)"
        diet_log = "Tofu stir-fry with mixed vegetables"
        activity_log = "Swam for 40 minutes"

    return pd.DataFrame([{
        "patient_id": patient_id,
        "name": patient_info["name"],
        "age": patient_info["age"],
        "diabetes_type": patient_info["diabetes_type"],
        "hba1c_reading": f"{hba1c_reading}%",
        "hba1c_status": hba1c_status,
        "date": datetime.now().strftime('%Y-%m-%d'),
        "glucose_reading": glucose_status,
        "diet_log": diet_log,
        "activity": activity_log,
    }])


def continuous_data_update(file_path, config):
    """
    Continuously updates the 'changing' dataset by adding and dropping records.
    """
    updates_per_cycle = config['data_generation']['updates_per_cycle']
    update_interval_seconds = config['data_generation']['update_interval_seconds']

    print(f"Continuous data generation started. Updating '{file_path}' every {update_interval_seconds} seconds...")

    try:
        while True:
            # Load the current DataFrame
            if os.path.exists(file_path):
                df_changing = pd.read_csv(file_path)
            else:
                df_changing = pd.DataFrame()

            # 1. Drop old records
            if not df_changing.empty and len(df_changing) > updates_per_cycle:
                rows_to_drop = np.random.choice(range(len(df_changing)), updates_per_cycle, replace=False)
                df_changing = df_changing.drop(rows_to_drop).reset_index(drop=True)
            else:
                df_changing = pd.DataFrame() # Clear the DataFrame if it's too small

            # 2. Add new records
            new_records_list = []
            for _ in range(updates_per_cycle):
                new_records_list.append(generate_single_record(config))
            new_records = pd.concat(new_records_list, ignore_index=True)
            
            df_changing = pd.concat([df_changing, new_records], ignore_index=True)

            # Save the updated DataFrame to the CSV file
            df_changing.to_csv(file_path, index=False)
            print(f"Updated '{updates_per_cycle}' records. Total records: {len(df_changing)}")

            # Wait for the specified interval
            time.sleep(update_interval_seconds)

    except KeyboardInterrupt:
        print("\nContinuous data update stopped by user.")


def main_generate_data():
    """
    Main function to load config, generate data, and export it.
    Generates and exports two initial datasets: one constant and one for the changing data stream.
    """
    config = load_config()
    if not config:
        return
        
    # Generate and export the constant dataset
    df_constant = generate_patient_data(config)
    df_constant.to_csv("constant_patient_data.csv", index=False)
    print("Successfully exported 'constant_patient_data.csv'")

    # Generate and export an initial version of the changing dataset
    df_changing_initial = generate_patient_data(config)
    df_changing_initial.to_csv("changing_patient_data.csv", index=False)
    print("Successfully exported initial 'changing_patient_data.csv'")

    # Start the continuous data update for the changing dataset
    continuous_data_update("changing_patient_data.csv", config)


if __name__ == "__main__":
    main_generate_data()
