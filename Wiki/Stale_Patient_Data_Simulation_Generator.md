# Stale Patient Data Simulation Generator Documentation

## 1. Introduction

The `Patient_Data_Simulation_Generator` is a standalone GUI application built with `tkinter`. Its purpose is to generate and visualize simulated patient data. This tool is likely used for testing and development purposes, allowing developers to work with realistic-looking data without using real patient information.

## 2. Core Components

- **`PatientDataGUI`**: This is the main class for the application. It creates the GUI, manages the data, and updates the plots. The GUI has two tabs: one for a constant dataset and one for a real-time changing dataset.

## 3. Functionality

- **Data Loading**: The application loads patient data from CSV files (`constant_patient_data.csv` and `changing_patient_data.csv`).
- **Data Processing**: It processes the raw data to extract numerical values for plotting.
- **Data Visualization**: It uses `matplotlib` and `seaborn` to create several plots, including:
    - Distribution of Glucose Readings
    - Distribution of HbA1c Readings
    - Correlation between Glucose and HbA1c
    - Glucose Level over Time (for the changing dataset)
- **Real-time Updates**: The "Real-Time Changing Dataset" tab periodically updates to simulate a real-time data feed.

## 4. Usage

The application is intended to be run via `run_analysis.py`. It reads a `config.yaml` file for configuration settings, such as the data update interval.
