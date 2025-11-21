"""
Health data aggregation service for fetching and processing patient health metrics via Data Service.
"""
from datetime import datetime, timedelta
from typing import Optional, List
import statistics
import httpx
from config import settings
from models.health import (
    MonitorData,
    ActivityLog,
    DailyLog,
    HealthSummary,
    HealthContext,
)


class HealthDataService:
    """Service for fetching and aggregating patient health data via Data Service."""

    async def _fetch_data(self, endpoint: str, token: str) -> List[dict]:
        """Helper to fetch data from Data Service."""
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{settings.data_service_url}{endpoint}",
                headers={"Authorization": f"Bearer {token}"},
                timeout=10.0
            )
            response.raise_for_status()
            return response.json()

    async def get_monitor_data(
        self,
        token: str,
        start_date: datetime,
        end_date: datetime,
        data_type: Optional[str] = None
    ) -> List[MonitorData]:
        """
        Fetch monitor data for a patient within a date range.
        """
        raw_data = await self._fetch_data("/patients/me/monitor-data", token)
        
        # Filter in memory since Data Service returns all data
        filtered_data = []
        for item in raw_data:
            measured_at = datetime.fromisoformat(item["measured_at"].replace('Z', '+00:00'))
            # Naive comparison or timezone aware comparison depending on data
            # Assuming data service returns ISO strings
            if start_date.timestamp() <= measured_at.timestamp() <= end_date.timestamp():
                if data_type and item["data_type"] != data_type:
                    continue
                filtered_data.append(MonitorData(**item))
                
        # Sort descending
        filtered_data.sort(key=lambda x: x.measured_at, reverse=True)
        return filtered_data

    async def get_activity_logs(
        self,
        token: str,
        start_date: datetime,
        end_date: datetime
    ) -> List[ActivityLog]:
        """
        Fetch activity logs for a patient within a date range.
        """
        raw_data = await self._fetch_data("/patients/me/activity-logs", token)
        
        filtered_data = []
        for item in raw_data:
            performed_at = datetime.fromisoformat(item["performed_at"].replace('Z', '+00:00'))
            if start_date.timestamp() <= performed_at.timestamp() <= end_date.timestamp():
                filtered_data.append(ActivityLog(**item))
        
        filtered_data.sort(key=lambda x: x.performed_at, reverse=True)
        return filtered_data

    async def get_daily_logs(
        self,
        token: str,
        start_date: datetime,
        end_date: datetime
    ) -> List[DailyLog]:
        """
        Fetch daily meal logs for a patient within a date range.
        """
        raw_data = await self._fetch_data("/patients/me/daily-logs", token)
        
        filtered_data = []
        for item in raw_data:
            # log_date is usually YYYY-MM-DD, but model expects datetime
            # We'll parse it carefully
            log_date_str = item["log_date"]
            if "T" in log_date_str:
                log_date = datetime.fromisoformat(log_date_str.replace('Z', '+00:00'))
            else:
                log_date = datetime.strptime(log_date_str, "%Y-%m-%d")
                
            if start_date.date() <= log_date.date() <= end_date.date():
                # Ensure item matches model (convert date string to datetime if needed)
                item_copy = item.copy()
                item_copy["log_date"] = log_date
                filtered_data.append(DailyLog(**item_copy))
        
        filtered_data.sort(key=lambda x: x.log_date, reverse=True)
        return filtered_data

    async def get_health_summary(
        self,
        token: str,
        start_date: datetime,
        end_date: datetime
    ) -> HealthSummary:
        """
        Generate comprehensive health summary for a patient.
        """
        # Fetch all monitor data
        monitor_data = await self.get_monitor_data(token, start_date, end_date)

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
        activity_logs = await self.get_activity_logs(token, start_date, end_date)
        total_activity_minutes = sum(a.duration_minutes for a in activity_logs)

        # Fetch meal data
        daily_logs = await self.get_daily_logs(token, start_date, end_date)
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

    async def get_health_context(self, token: str) -> HealthContext:
        """
        Get formatted health context for LLM prompt.
        """
        end_date = datetime.now()
        start_date = end_date - timedelta(days=settings.health_context_days)

        summary = await self.get_health_summary(token, start_date, end_date)

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
