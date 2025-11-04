from enum import Enum

class MonitorDataType(str, Enum):
    BLOOD_PRESSURE_SYSTOLIC = 'BLOOD_PRESSURE_SYSTOLIC'
    BLOOD_PRESSURE_DIASTOLIC = 'BLOOD_PRESSURE_DIASTOLIC'
    GLUCOSE = 'GLUCOSE'
    BMI = 'BMI'
    HBA1C = 'HBA1C'
    ECG = 'ECG'
    CHOLESTEROL = 'CHOLESTEROL'

    @property
    def unit(self) -> str:
        """Returns the measurement unit for the data type."""
        return {
            MonitorDataType.BLOOD_PRESSURE_SYSTOLIC: 'mmHg',
            MonitorDataType.BLOOD_PRESSURE_DIASTOLIC: 'mmHg',
            MonitorDataType.GLUCOSE: 'mg/dL',
            MonitorDataType.BMI: 'kg/m²',
            MonitorDataType.HBA1C: '%',
            MonitorDataType.ECG: 'bpm',
            MonitorDataType.CHOLESTEROL: 'mg/dL'
        }.get(self, 'N/A')
