"""
Health data aggregation service for fetching and processing patient health metrics via Data Service.
"""
from datetime import datetime, timedelta, timezone
from typing import Optional, List
import httpx
from config import settings
from models.health import (
    MonitorData,
    ActivityLog,
    DailyLog,
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
        Fetch monitor data for a patient.
        """
        raw_data = await self._fetch_data("/patients/me/monitor-data", token)
        
        filtered_data = []
        for item in raw_data:
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
        Fetch activity logs for a patient.
        """
        raw_data = await self._fetch_data("/patients/me/activity-logs", token)
        
        filtered_data = []
        for item in raw_data:
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
        Fetch daily meal logs for a patient.
        """
        raw_data = await self._fetch_data("/patients/me/daily-logs", token)
        
        filtered_data = []
        for item in raw_data:
            filtered_data.append(DailyLog(**item))
        
        filtered_data.sort(key=lambda x: x.log_date, reverse=True)
        return filtered_data

    async def get_patient_thresholds(self, token: str) -> dict:
        """
        Fetch patient-specific health thresholds.
        """
        raw_data = await self._fetch_data("/patients/me/thresholds", token)
        
        # Convert list of thresholds to a dict for easier lookup
        thresholds = {}
        for t in raw_data:
            thresholds[t["data_type"]] = {
                "min": t["min_value"],
                "max": t["max_value"]
            }
        return thresholds

    async def get_patient_profile(self, token: str) -> dict:
        """
        Fetch patient profile.
        """
        return await self._fetch_data("/patients/me", token)

    async def get_health_context(self, token: str) -> HealthContext:
        """
        Get formatted health context for LLM prompt.
        """
        dummy_date = datetime.now()
        
        profile = await self.get_patient_profile(token)
        monitor_data = await self.get_monitor_data(token, dummy_date, dummy_date)
        activity_logs = await self.get_activity_logs(token, dummy_date, dummy_date)
        daily_logs = await self.get_daily_logs(token, dummy_date, dummy_date)
        thresholds = await self.get_patient_thresholds(token)

        # Format Profile
        profile_lines = []
        if not profile:
            profile_lines.append("No profile data available.")
        else:
            if profile.get("name"):
                profile_lines.append(f"Name: {profile.get('name')}")
            if profile.get("gender"):
                profile_lines.append(f"Gender: {profile.get('gender')}")
            if profile.get("date_of_birth"):
                profile_lines.append(f"Date of Birth: {profile.get('date_of_birth')}")
            if profile.get("risk_level"):
                profile_lines.append(f"Risk Level: {profile.get('risk_level')}")

        # Format Monitor Data
        monitor_lines = []
        if not monitor_data:
            monitor_lines.append("No monitor data available.")
        else:
            for m in monitor_data:
                if m.data_type == "ECG":
                    continue
                monitor_lines.append(f"- {m.measured_at.strftime('%Y-%m-%d %H:%M')}: {m.data_type} = {m.value}")
        
        # Format Activity Logs
        activity_lines = []
        if not activity_logs:
            activity_lines.append("No activity logs available.")
        else:
            for a in activity_logs:
                activity_lines.append(f"- {a.performed_at.strftime('%Y-%m-%d %H:%M')}: {a.activity_description} ({a.duration_minutes} mins)")

        # Format Daily Logs
        daily_lines = []
        if not daily_logs:
            daily_lines.append("No meal logs available.")
        else:
            for d in daily_logs:
                entry = f"- {d.log_date.strftime('%Y-%m-%d')} {d.meal_time}:"
                if d.meal_desc:
                    entry += f" {d.meal_desc}"
                if d.calories:
                    entry += f" [{d.calories} kcal]"
                if d.glucose_before_meal:
                    entry += f" (Before: {d.glucose_before_meal})"
                if d.glucose_after_meal:
                    entry += f" (After: {d.glucose_after_meal})"
                daily_lines.append(entry)

        # Format Thresholds
        threshold_lines = []
        if not thresholds:
            threshold_lines.append("No specific thresholds set.")
        else:
            for dtype, limits in thresholds.items():
                threshold_lines.append(f"- {dtype}: Min {limits['min']}, Max {limits['max']}")

        return HealthContext(
            patient_profile="\n".join(profile_lines),
            raw_monitor_data="\n".join(monitor_lines),
            raw_activity_logs="\n".join(activity_lines),
            raw_daily_logs="\n".join(daily_lines),
            patient_thresholds="\n".join(threshold_lines),
            data_timestamp=datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC"),
        )


# Singleton instance
_health_data_service: Optional[HealthDataService] = None


def get_health_data_service() -> HealthDataService:
    """Get or create the singleton HealthDataService instance."""
    global _health_data_service
    if _health_data_service is None:
        _health_data_service = HealthDataService()
    return _health_data_service
