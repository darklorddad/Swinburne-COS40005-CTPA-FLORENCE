import tkinter as tk
from tkinter import ttk
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg
import seaborn as sns
import yaml
import os
import time

# Function to load the configuration
def load_config():
    """Loads configuration settings from a YAML file."""
    try:
        with open("config.yaml", 'r') as file:
            config = yaml.safe_load(file)
        return config
    except FileNotFoundError:
        print("Error: The file config.yaml was not found.")
        return None
    except yaml.YAMLError as e:
        print(f"Error parsing YAML file: {e}")
        return None

# The main application class
class PatientDataGUI(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("Patient Data Analytics Dashboard")
        self.geometry("1200x1200") # Increased size to fit multiple plots
        
        self.config = load_config()
        if not self.config:
            self.destroy()
            return
        
        self.update_interval = self.config['data_generation']['update_interval_seconds'] * 1000  # in milliseconds

        # Create a notebook (tabbed interface)
        self.notebook = ttk.Notebook(self)
        self.notebook.pack(expand=True, fill="both")

        # Create frames for each tab
        self.constant_frame = ttk.Frame(self.notebook)
        self.changing_frame = ttk.Frame(self.notebook)
        
        self.notebook.add(self.constant_frame, text="Constant Dataset")
        self.notebook.add(self.changing_frame, text="Real-Time Changing Dataset")

        # Set up the Constant Data tab layout
        self.setup_constant_tab()

        # Set up the Changing Data tab layout
        self.setup_changing_tab()

        # Start the data updates for both tabs
        self.start_updates()

    def setup_constant_tab(self):
        """Sets up the layout for the Constant Data tab with multiple plots."""
        # Top section for information
        constant_info_frame = ttk.Frame(self.constant_frame, padding="10")
        constant_info_frame.pack(fill=tk.X)
        self.constant_info_label = ttk.Label(constant_info_frame, text="Loading constant data...", font=("Helvetica", 12))
        self.constant_info_label.pack(side=tk.LEFT)
        
        # Matplotlib plot area with multiple subplots
        self.fig_constant, (self.ax_constant_glucose, self.ax_constant_hba1c, self.ax_constant_correlation) = plt.subplots(3, 1, figsize=(10, 15))
        self.canvas_constant = FigureCanvasTkAgg(self.fig_constant, master=self.constant_frame)
        self.canvas_constant.get_tk_widget().pack(side=tk.TOP, fill=tk.BOTH, expand=True)
        plt.tight_layout()
        plt.close(self.fig_constant) # Prevents an extra plot window from appearing

    def setup_changing_tab(self):
        """Sets up the layout for the Changing Data tab with multiple plots."""
        # Top section for information
        changing_info_frame = ttk.Frame(self.changing_frame, padding="10")
        changing_info_frame.pack(fill=tk.X)
        self.changing_info_label = ttk.Label(changing_info_frame, text="Loading changing data...", font=("Helvetica", 12))
        self.changing_info_label.pack(side=tk.LEFT)

        # Matplotlib plot area with multiple subplots
        self.fig_changing, (self.ax_changing_glucose, self.ax_changing_hba1c, self.ax_changing_correlation, self.ax_changing_temporal) = plt.subplots(4, 1, figsize=(10, 20))
        self.canvas_changing = FigureCanvasTkAgg(self.fig_changing, master=self.changing_frame)
        self.canvas_changing.get_tk_widget().pack(side=tk.TOP, fill=tk.BOTH, expand=True)
        plt.tight_layout()
        plt.close(self.fig_changing) # Prevents an extra plot window from appearing

    def start_updates(self):
        """Starts the periodic updates for the tabs."""
        # Load constant data once at the beginning. It will retry if it fails.
        self.update_constant_data()
        # Start the continuous update loop for the changing data.
        self.update_changing_data()

    def process_data_for_plotting(self, df):
        """
        Processes the raw DataFrame to extract numerical values for plotting.
        - Extracts glucose level from 'glucose_reading' (e.g., "Stable (8.2 mmol/L)" -> 8.2)
        - Extracts HbA1c from 'hba1c_reading' (e.g., "8.0%" -> 8.0)
        """
        # Use regex to safely extract numbers. Return NaN if no number is found.
        df['glucose_level'] = df['glucose_reading'].str.extract(r'\((\d+\.?\d*)\s*mmol/L\)').astype(float)
        df['hba1c_numeric'] = df['hba1c_reading'].str.replace('%', '').astype(float)
        return df

    def create_plots(self, df, axes, is_changing=False):
        """Helper function to create and update all plots for a given dataset."""
        # Clear all axes
        for ax in axes:
            ax.clear()
        
        # Plot 1: Glucose Distribution
        sns.histplot(df['glucose_level'], bins=20, kde=True, ax=axes[0])
        axes[0].set_title('Distribution of Glucose Readings')
        axes[0].set_xlabel('Glucose Level (mmol/L)')
        axes[0].set_ylabel('Frequency')
        
        # Plot 2: HbA1c Distribution
        sns.histplot(df['hba1c_numeric'], bins=20, kde=True, ax=axes[1])
        axes[1].set_title('Distribution of HbA1c Readings')
        axes[1].set_xlabel('HbA1c Reading (%)')
        axes[1].set_ylabel('Frequency')

        # Plot 3: Glucose vs. HbA1c Correlation
        sns.regplot(x='hba1c_numeric', y='glucose_level', data=df, ax=axes[2], scatter_kws={'alpha':0.3})
        axes[2].set_title('Correlation: Glucose vs. HbA1c')
        axes[2].set_xlabel('HbA1c Reading (%)')
        axes[2].set_ylabel('Glucose Level (mmol/L)')
        
        # Plot 4: Temporal Trends (only for the changing dataset)
        if is_changing:
            # Sort data by timestamp for the line plot
            df['timestamp'] = pd.to_datetime(df['timestamp'])
            df.sort_values('timestamp', inplace=True)
            
            axes[3].plot(df['timestamp'], df['glucose_level'], marker='o', linestyle='-', markersize=2)
            axes[3].set_title('Glucose Level over Time')
            axes[3].set_xlabel('Timestamp')
            axes[3].set_ylabel('Glucose Level (mmol/L)')
            axes[3].tick_params(axis='x', rotation=45)
            
        # Use tight_layout on the specific figure to adjust spacing
        if is_changing:
            self.fig_changing.tight_layout()
        else:
            self.fig_constant.tight_layout()

    def update_constant_data(self):
        """Reads the constant dataset from file and updates the graphs and info label."""
        file_path = "constant_patient_data.csv"
        try:
            if os.path.exists(file_path):
                df_raw = pd.read_csv(file_path)
                df_constant = self.process_data_for_plotting(df_raw)
                
                total_records = len(df_constant)
                unique_patients = df_constant['patient_id'].nunique()
                avg_glucose = round(df_constant['glucose_level'].mean(), 2)
                avg_hba1c = round(df_constant['hba1c_numeric'].mean(), 2)
                
                info_text = (
                    f"--- Constant Dataset Analysis ---\n"
                    f"Last Updated: {pd.Timestamp.now().strftime('%Y-%m-%d %H:%M:%S')}\n"
                    f"Total Records: {total_records}\n"
                    f"Unique Patients: {unique_patients}\n"
                    f"Average Glucose Level: {avg_glucose} mmol/L\n"
                    f"Average HbA1c Reading: {avg_hba1c}%"
                )
                self.constant_info_label.config(text=info_text)
                
                self.create_plots(df_constant, [self.ax_constant_glucose, self.ax_constant_hba1c, self.ax_constant_correlation])
                self.canvas_constant.draw()
            else:
                self.constant_info_label.config(text="Error: 'constant_patient_data.csv' not found. Waiting for data...")
                # Retry after a delay if the file is not found initially
                self.after(2000, self.update_constant_data)
        except Exception as e:
            self.constant_info_label.config(text=f"An error occurred: {e}")
            # Retry after a delay in case of other errors
            self.after(2000, self.update_constant_data)

    def update_changing_data(self):
        """Reads the changing dataset from file and updates the graphs and info label."""
        file_path = "changing_patient_data.csv"
        
        try:
            if os.path.exists(file_path) and os.path.getsize(file_path) > 0:
                df_raw = pd.read_csv(file_path)
                df_changing = self.process_data_for_plotting(df_raw)
                
                required_cols = ['date', 'glucose_level', 'patient_id', 'hba1c_numeric']
                if df_changing.empty or not all(col in df_changing.columns for col in required_cols) or df_changing['glucose_level'].isnull().any():
                    raise ValueError("Data is currently empty or incomplete.")

                total_records = len(df_changing)
                unique_patients = df_changing['patient_id'].nunique()
                avg_glucose = round(df_changing['glucose_level'].mean(), 2)
                avg_hba1c = round(df_changing['hba1c_numeric'].mean(), 2)
                
                info_text = (
                    f"--- Real-Time Analysis ---\n"
                    f"Last Updated: {pd.Timestamp.now().strftime('%Y-%m-%d %H:%M:%S')}\n"
                    f"Total Records: {total_records}\n"
                    f"Unique Patients: {unique_patients}\n"
                    f"Average Glucose Level: {avg_glucose} mmol/L\n"
                    f"Average HbA1c Reading: {avg_hba1c}%"
                )
                self.changing_info_label.config(text=info_text)

                # Rename 'date' to 'timestamp' for plotting consistency
                df_changing.rename(columns={'date': 'timestamp'}, inplace=True)

                self.create_plots(df_changing, [self.ax_changing_glucose, self.ax_changing_hba1c, self.ax_changing_correlation, self.ax_changing_temporal], is_changing=True)
                self.canvas_changing.draw()
            else:
                raise FileNotFoundError("Waiting for records...")

        except (FileNotFoundError, pd.errors.EmptyDataError, ValueError) as e:
            self.changing_info_label.config(text=f"Data is currently empty or incomplete. {e}")
        
        except Exception as e:
            self.changing_info_label.config(text=f"An error occurred: {e}")

        finally:
            # Always schedule the next update to keep the dashboard live
            self.after(self.update_interval, self.update_changing_data)

if __name__ == "__main__":
    print("This script is intended to be run by run_analysis.py.")
    print("To test, run 'python run_analysis.py'.")
