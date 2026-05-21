from django.apps import AppConfig


class AppApiConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'app_api'

    def ready(self):
        # Patch LogEntry to be unmanaged to avoid errors on databases without admin tables
        try:
            from django.contrib.admin.models import LogEntry
            LogEntry._meta.managed = False
        except Exception:
            pass
