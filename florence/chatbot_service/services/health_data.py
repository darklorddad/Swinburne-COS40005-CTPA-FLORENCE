"""
Health data aggregation service for fetching and processing patient health metrics.
"""
from datetime import datetime, timedelta
from typing import Optional, List
import statistics
from supabase import create_client, Client
from config import settings
from models.health import (
    MonitorData,
    ActivityLog,
    DailyLog,
    HealthSummary,
    HealthContext,
)


class HealthDataService:
    """Service for fetching and aggregating patient health data."""

    def __init__(self):
        """Initialize the health data service with Supabase client."""
        self.supabase: Client = create_client(
            settings.supabase_url,
            settings.supabase_service_key
        )

    async def get_monitor_data(
        self,
        patient_id: int,
        start_date: datetime,
        end_date: datetime,
        data_type: Optional[str] = None
    ) -> List[MonitorData]:
        """
        Fetch monitor data for a patient within a date range.

        Args:
            patient_id: Patient ID
            start_date: Start of date range
            end_date: End of date range
            data_type: Optional filter by data type (e.g., 'GLUCOSE')

        Returns:
            List of MonitorData objects
        """
        query = (
            self.supabase.table("patient_monitor_data")
            .select("*")
            .eq("patient_id", patient_id)
            .gte("measured_at", start_date.isoformat())
            .lte("measured_at", end_date.isoformat())
            .order("measured_at", desc=True)
        )

        if data_type:
            query = query.eq("data_type", data_type)

        response = query.execute()
        return [MonitorData(**item) for item in response.data]

    async def get_activity_logs(
        self,
        patient_id: int,
        start_date: datetime,
        end_date: datetime
    ) -> List[ActivityLog]:
        """
        Fetch activity logs for a patient within a date range.

        Args:
            patient_id: Patient ID
            start_date: Start of date range
            end_date: End of date range

        Returns:
            List of ActivityLog objects
        """
        response = (
            self.supabase.table("patient_activity_log")
            .select("*")
            .eq("patient_id", patient_id)
            .gte("performed_at", start_date.isoformat())
            .lte("performed_at", end_date.isoformat())
            .order("performed_at", desc=True)
            .execute()
        )

        return [ActivityLog(**item) for item in response.data]

    async def get_daily_logs(
        self,
        patient_id: int,
        start_date: datetime,
        end_date: datetime
    ) -> List[DailyLog]:
        """
        Fetch daily meal logs for a patient within a date range.

        Args:
            patient_id: Patient ID
            start_date: Start of date range
            end_date: End of date range

        Returns:
            List of DailyLog objects
        """
        response = (
            self.supabase.table("daily_patient_log")
            .select("*")
            .eq("patient_id", patient_id)
            .gte("log_date", start_date.date().isoformat())
            .lte("log_date", end_date.date().isoformat())
            .order("log_date", desc=True)
            .execute()
        )

        return [DailyLog(**item) for item in response.data]

    async def get_health_summary(
        self,
        patient_id: int,
        start_date: datetime,
        end_date: datetime
    ) -> HealthSummary:
        """
        Generate comprehensive health summary for a patient.

        Args:
            patient_id: Patient ID
            start_date: Start of date range
            end_date: End of date range

        Returns:
            HealthSummary object with aggregated metrics
        """
        # Fetch all monitor data
        monitor_data = await self.get_monitor_data(patient_id, start_date, end_date)

        # Separate by type
        glucose_readings = [m for m in monitor_data if m.data_type == "GLUCOSE"]
        systolic_readings = [m for m in monitor_data if m.data_type == "BLOOD_PRESSURE_SYSTOLIC"]
        diastolic_readings = [m for m in monitor_data if m.data_type == "BLOOD_PRESSURE_DIASTOLIC"]
        bmi_readings = [m for m in monitor_data if m.data_type == "BMI"]
        hba1c_readings = [m for m in monitor_data if m.data_type == "HBA1C"]

        # Calculate glucose metrics
        glucose_values = [g.value for g in glucose_readings]
        average_glucose = statistics.mean(glucose_values) if glucose_values else None
        glucose_std_dev = statistics.stdev(glucose_values) if len(glucose_values) > 1 else None

        # Count hyper/hypo events
        hyper_events = sum(1 for v in glucose_values if v > settings.glucose_high_threshold)
        hypo_events = sum(1 for v in glucose_values if v < settings.glucose_low_threshold)

        # Calculate time in range
        in_range_count = sum(
            1 for v in glucose_values
            if settings.glucose_low_threshold <= v <= settings.glucose_high_threshold
        )
        time_in_range = (in_range_count / len(glucose_values) * 100) if glucose_values else 0.0

        # Estimated A1C calculation: (avg_glucose + 46.7) / 28.7
        estimated_a1c = ((average_glucose + 46.7) / 28.7) if average_glucose else None

        # Latest glucose reading
        latest_glucose = glucose_readings[0] if glucose_readings else None

        # Blood pressure metrics
        avg_systolic = statistics.mean([s.value for s in systolic_readings]) if systolic_readings else None
        avg_diastolic = statistics.mean([d.value for d in diastolic_readings]) if diastolic_readings else None

        # Latest BMI and HbA1c
        latest_bmi = bmi_readings[0].value if bmi_readings else None
        latest_hba1c = hba1c_readings[0].value if hba1c_readings else None

        # Fetch activity data
        activity_logs = await self.get_activity_logs(patient_id, start_date, end_date)
        total_activity_minutes = sum(a.duration_minutes for a in activity_logs)

        # Fetch meal data
        daily_logs = await self.get_daily_logs(patient_id, start_date, end_date)
        total_meals = len(daily_logs)

        return HealthSummary(
            start_date=start_date,
            end_date=end_date,
            latest_glucose=latest_glucose.value if latest_glucose else None,
            latest_glucose_time=latest_glucose.measured_at if latest_glucose else None,
            latest_glucose_context=None,  # Not stored in monitor_data
            average_glucose=average_glucose,
            glucose_std_dev=glucose_std_dev,
            total_glucose_readings=len(glucose_readings),
            hyper_events=hyper_events,
            hypo_events=hypo_events,
            time_in_range=time_in_range,
            estimated_a1c=estimated_a1c,
            average_systolic=avg_systolic,
            average_diastolic=avg_diastolic,
            total_activity_minutes=total_activity_minutes,
            average_daily_activity=(
                total_activity_minutes / ((end_date - start_date).days + 1)
                if (end_date - start_date).days > 0 else 0
            ),
            total_meals=total_meals,
            latest_bmi=latest_bmi,
            latest_hba1c=latest_hba1c,
        )

    async def get_health_context(self, patient_id: int) -> HealthContext:
        """
        Get formatted health context for LLM prompt.

        Args:
            patient_id: Patient ID

        Returns:
            HealthContext object ready for LLM prompt formatting
        """
        end_date = datetime.now()
        start_date = end_date - timedelta(days=settings.health_context_days)

        summary = await self.get_health_summary(patient_id, start_date, end_date)

        return HealthContext(
            latest_glucose=summary.latest_glucose,
            latest_glucose_time=(
                summary.latest_glucose_time.strftime("%Y-%m-%d %H:%M")
                if summary.latest_glucose_time else None
            ),
            latest_glucose_context=summary.latest_glucose_context,
            average_glucose_7d=summary.average_glucose,
            time_in_range_7d=summary.time_in_range,
            hyper_events_7d=summary.hyper_events,
            hypo_events_7d=summary.hypo_events,
            total_activity_minutes_7d=summary.total_activity_minutes,
            average_systolic_7d=summary.average_systolic,
            average_diastolic_7d=summary.average_diastolic,
            data_timestamp=datetime.now().strftime("%Y-%m-%d %H:%M"),
        )


# Singleton instance
_health_data_service: Optional[HealthDataService] = None


def get_health_data_service() -> HealthDataService:
    """Get or create the singleton HealthDataService instance."""
    global _health_data_service
    if _health_data_service is None:
        _health_data_service = HealthDataService()
    return _health_data_service
