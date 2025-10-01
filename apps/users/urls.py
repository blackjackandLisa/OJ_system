from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

# API路由
router = DefaultRouter()
router.register(r'users', views.UserViewSet, basename='user')
router.register(r'classes', views.ClassViewSet, basename='class')

app_name = 'users'

urlpatterns = [
    # API路由
    path('api/', include(router.urls)),
    path('api/register/', views.RegisterAPIView.as_view(), name='api_register'),
    path('api/login/', views.LoginAPIView.as_view(), name='api_login'),
    path('api/logout/', views.LogoutAPIView.as_view(), name='api_logout'),
    
    # 前端页面路由
    path('register/', views.register_view, name='register'),
    path('login/', views.login_view, name='login'),
    path('logout/', views.logout_view, name='logout'),
    path('profile/', views.profile_view, name='profile'),
    path('my-classes/', views.my_classes_view, name='my_classes'),
    path('classes/<int:pk>/', views.class_detail_view, name='class_detail'),
]

