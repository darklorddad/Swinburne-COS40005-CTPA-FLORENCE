# Patient Data Generation and Exploratory Analysis

This repository contains a set of files for generating a synthetic patient health dataset and performing an initial exploratory data analysis (EDA). The project is designed to help understand and visualize data related to patient health, with a focus on diabetes management.

## Files

*   **`generate_data.py`**: A Python script that creates a synthetic dataset of patient health records based on the configuration in `config.yaml`.
*   **`config.yaml`**: A configuration file that allows you to customize the dataset, including the number of patients, data ranges, and output format.
*   **`run_analysis.py`**: The main script to run the entire pipeline. It generates the data and then executes the Jupyter Notebook for analysis using Python libraries, bypassing the need for a separate `jupyter` command.
*   **`patient_data.csv` & `patient_data.json`**: The generated synthetic datasets.
*   **`PatientDataExploratory.ipynb`**: A Jupyter Notebook that provides a detailed walkthrough of the exploratory data analysis. It covers data loading, preprocessing, statistical summaries, and data visualization. The output cells will be populated automatically when `run_analysis.py` is executed.
*   **`requirements.txt`**: A list of all the Python libraries required to run the scripts and notebook.

## Getting Started

Follow these steps to set up the environment and run the analysis.

### Step 1: Install Dependencies

You'll need Python installed on your system. Once you have Python, you can install all the required libraries using `pip`. It's recommended to do this in a virtual environment.

```bash
pip install -r requirements.txt

```

### Step 2: Run the Analysis Pipeline
This single command will generate the patient data and automatically execute the analysis notebook, saving the results directly to the notebook file.
code
``` Bash
python run_analysis.py

```
This will create a patient_data.csv and patient_data.json file in the same directory, and the executed output will be saved inside PatientDataExploratory.ipynb.