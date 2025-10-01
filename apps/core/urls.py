from django.urls import path
from . import views

app_name = 'core'

urlpatterns = [
    path('', views.home, name='home'),
    path('api/info/', views.api_info, name='api_info'),
]
