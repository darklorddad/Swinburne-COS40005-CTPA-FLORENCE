from enum import Enum

class UserRole(str, Enum):
    ADMIN = 'ADMIN'
    CLINICIAN = 'CLINICIAN'
    PATIENT = 'PATIENT'

class PublicUserRole(str, Enum):
    PATIENT = 'PATIENT'
    CLINICIAN = 'CLINICIAN'

class RiskLevel(str, Enum):
    LOW = 'LOW'
    MEDIUM = 'MEDIUM'
    HIGH = 'HIGH'

class MealTime(str, Enum):
    BREAKFAST = 'BREAKFAST'
    LUNCH = 'LUNCH'
    DINNER = 'DINNER'

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
