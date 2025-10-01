from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

app_name = 'judge'

# API路由
router = DefaultRouter()
router.register(r'submissions', views.SubmissionViewSet, basename='submission')
router.register(r'languages', views.LanguageViewSet, basename='language')

urlpatterns = [
    # API endpoints
    path('api/', include(router.urls)),
]

