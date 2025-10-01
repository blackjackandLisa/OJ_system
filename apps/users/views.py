from rest_framework import viewsets, status, views
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, IsAdminUser, AllowAny
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.models import User
from django.contrib.auth.decorators import login_required
from django.shortcuts import render, redirect
from django.contrib import messages
from django.utils import timezone

from .models import UserProfile, Class, UserLoginLog
from .serializers import (
    UserSerializer,
    UserRegisterSerializer,
    UserLoginSerializer,
    ChangePasswordSerializer,
    UserUpdateSerializer,
    ClassSerializer,
)
from .decorators import teacher_required, admin_required, anonymous_required


# ============================================
# REST API Views
# ============================================

class RegisterAPIView(views.APIView):
    """用户注册API"""
    permission_classes = [AllowAny]
    
    def post(self, request):
        serializer = UserRegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            
            # 自动登录
            login(request, user)
            
            # 记录登录日志
            self._log_login(request, user, True)
            
            # 返回用户信息
            user_serializer = UserSerializer(user)
            return Response({
                'message': '注册成功',
                'user': user_serializer.data
            }, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    def _log_login(self, request, user, is_success, fail_reason=''):
        """记录登录日志"""
        ip = self._get_client_ip(request)
        user_agent = request.META.get('HTTP_USER_AGENT', '')[:255]
        
        UserLoginLog.objects.create(
            user=user,
            ip_address=ip,
            user_agent=user_agent,
            is_success=is_success,
            fail_reason=fail_reason
        )
    
    def _get_client_ip(self, request):
        """获取客户端IP"""
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = request.META.get('REMOTE_ADDR')
        return ip


class LoginAPIView(views.APIView):
    """用户登录API"""
    permission_classes = [AllowAny]
    
    def post(self, request):
        serializer = UserLoginSerializer(data=request.data)
        if serializer.is_valid():
            username = serializer.validated_data['username']
            password = serializer.validated_data['password']
            remember_me = serializer.validated_data.get('remember_me', False)
            
            # 支持用户名或邮箱登录
            user = authenticate(request, username=username, password=password)
            
            if user is None:
                # 尝试使用邮箱登录
                try:
                    user_obj = User.objects.get(email=username)
                    user = authenticate(request, username=user_obj.username, password=password)
                except User.DoesNotExist:
                    pass
            
            if user is not None:
                if user.is_active:
                    # 检查用户profile是否激活
                    if hasattr(user, 'profile') and not user.profile.is_active:
                        self._log_login(request, user, False, '账号已被禁用')
                        return Response({
                            'error': '账号已被禁用，请联系管理员'
                        }, status=status.HTTP_403_FORBIDDEN)
                    
                    # 登录成功
                    login(request, user)
                    
                    # 设置session过期时间
                    if remember_me:
                        request.session.set_expiry(604800)  # 7天
                    else:
                        request.session.set_expiry(7200)  # 2小时
                    
                    # 更新最后登录时间
                    if hasattr(user, 'profile'):
                        user.profile.last_login_at = timezone.now()
                        user.profile.save()
                    
                    # 记录登录日志
                    self._log_login(request, user, True)
                    
                    # 返回用户信息
                    user_serializer = UserSerializer(user)
                    return Response({
                        'message': '登录成功',
                        'user': user_serializer.data
                    })
                else:
                    self._log_login(request, user, False, '账号未激活')
                    return Response({
                        'error': '账号未激活'
                    }, status=status.HTTP_403_FORBIDDEN)
            else:
                # 记录失败日志（尝试获取用户）
                try:
                    failed_user = User.objects.get(username=username)
                    self._log_login(request, failed_user, False, '密码错误')
                except User.DoesNotExist:
                    pass
                
                return Response({
                    'error': '用户名或密码错误'
                }, status=status.HTTP_401_UNAUTHORIZED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    def _log_login(self, request, user, is_success, fail_reason=''):
        """记录登录日志"""
        ip = self._get_client_ip(request)
        user_agent = request.META.get('HTTP_USER_AGENT', '')[:255]
        
        UserLoginLog.objects.create(
            user=user,
            ip_address=ip,
            user_agent=user_agent,
            is_success=is_success,
            fail_reason=fail_reason
        )
    
    def _get_client_ip(self, request):
        """获取客户端IP"""
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = request.META.get('REMOTE_ADDR', '127.0.0.1')
        return ip


class LogoutAPIView(views.APIView):
    """用户登出API"""
    permission_classes = [IsAuthenticated]
    
    def post(self, request):
        logout(request)
        return Response({'message': '登出成功'})


class UserViewSet(viewsets.ModelViewSet):
    """用户视图集"""
    queryset = User.objects.all()
    serializer_class = UserSerializer
    
    def get_permissions(self):
        """根据action设置权限"""
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            return [IsAdminUser()]
        elif self.action == 'me':
            return [IsAuthenticated()]
        return [IsAdminUser()]
    
    @action(detail=False, methods=['get', 'put', 'patch'], permission_classes=[IsAuthenticated])
    def me(self, request):
        """获取或更新当前用户信息"""
        if request.method == 'GET':
            serializer = UserSerializer(request.user)
            return Response(serializer.data)
        else:
            serializer = UserUpdateSerializer(request.user, data=request.data, partial=True)
            if serializer.is_valid():
                serializer.save()
                return Response(serializer.data)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=False, methods=['post'], permission_classes=[IsAuthenticated])
    def change_password(self, request):
        """修改密码"""
        serializer = ChangePasswordSerializer(data=request.data)
        if serializer.is_valid():
            user = request.user
            
            # 验证旧密码
            if not user.check_password(serializer.validated_data['old_password']):
                return Response({
                    'error': '旧密码不正确'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # 设置新密码
            user.set_password(serializer.validated_data['new_password'])
            user.save()
            
            return Response({'message': '密码修改成功，请重新登录'})
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class ClassViewSet(viewsets.ModelViewSet):
    """班级视图集"""
    queryset = Class.objects.all()
    serializer_class = ClassSerializer
    
    def get_permissions(self):
        """根据action设置权限"""
        if self.action in ['list', 'retrieve']:
            return [IsAuthenticated()]
        return [IsAuthenticated()]  # 老师和管理员可以创建
    
    def get_queryset(self):
        """获取查询集"""
        queryset = super().get_queryset()
        user = self.request.user
        
        # 管理员可以看到所有班级
        if user.is_staff or user.is_superuser:
            return queryset
        
        # 老师只能看到自己的班级
        if hasattr(user, 'profile') and user.profile.is_teacher:
            return queryset.filter(teacher=user)
        
        # 学生只能看到自己加入的班级
        return queryset.filter(students=user)
    
    def perform_create(self, serializer):
        """创建时设置老师"""
        serializer.save(teacher=self.request.user)
    
    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated])
    def join(self, request, pk=None):
        """学生加入班级"""
        class_obj = self.get_object()
        code = request.data.get('code', '')
        
        if class_obj.code != code:
            return Response({
                'error': '班级代码错误'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # 添加学生
        class_obj.students.add(request.user)
        
        return Response({
            'message': f'成功加入班级 {class_obj.name}'
        })


# ============================================
# Template Views (前端页面)
# ============================================

@anonymous_required
def register_view(request):
    """注册页面"""
    return render(request, 'users/register.html')


@anonymous_required
def login_view(request):
    """登录页面"""
    return render(request, 'users/login.html')


@login_required
def profile_view(request):
    """个人中心"""
    return render(request, 'users/profile.html', {
        'user': request.user
    })


@login_required
def logout_view(request):
    """登出"""
    logout(request)
    messages.success(request, '您已成功登出')
    return redirect('core:home')


@teacher_required
def my_classes_view(request):
    """我的班级（老师）"""
    classes = Class.objects.filter(teacher=request.user)
    return render(request, 'users/my_classes.html', {
        'classes': classes
    })


@teacher_required
def class_detail_view(request, pk):
    """班级详情（老师）"""
    class_obj = Class.objects.get(pk=pk, teacher=request.user)
    return render(request, 'users/class_detail.html', {
        'class': class_obj
    })

