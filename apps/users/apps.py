from django.apps import AppConfig


class UsersConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'apps.users'
    verbose_name = '用户管理'
    
    def ready(self):
        """应用就绪时导入信号"""
        import apps.users.signals

