from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

# API路由
router = DefaultRouter()
router.register(r'problems', views.ProblemViewSet, basename='problem')
router.register(r'tags', views.ProblemTagViewSet, basename='tag')
router.register(r'testcases', views.TestCaseViewSet, basename='testcase')
router.register(r'user-status', views.UserProblemStatusViewSet, basename='user-status')

app_name = 'problems'

urlpatterns = [
    # API路由
    path('api/', include(router.urls)),
    
    # 前端页面路由
    path('', views.problem_list_view, name='problem_list'),
    path('<int:pk>/', views.problem_detail_view, name='problem_detail'),
    path('<int:pk>/submit/', views.problem_submit_view, name='problem_submit'),
]

