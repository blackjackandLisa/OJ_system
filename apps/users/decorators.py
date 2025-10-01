from functools import wraps
from django.shortcuts import redirect
from django.contrib import messages
from django.http import HttpResponseForbidden


def student_required(function=None, redirect_url='users:login'):
    """要求学生权限（学生、老师、管理员都可以访问）"""
    def decorator(view_func):
        @wraps(view_func)
        def _wrapped_view(request, *args, **kwargs):
            if not request.user.is_authenticated:
                messages.warning(request, '请先登录')
                return redirect(redirect_url)
            
            # 所有已登录用户都可以访问
            return view_func(request, *args, **kwargs)
        
        return _wrapped_view
    
    if function:
        return decorator(function)
    return decorator


def teacher_required(function=None, redirect_url='users:login'):
    """要求老师权限（老师和管理员可以访问）"""
    def decorator(view_func):
        @wraps(view_func)
        def _wrapped_view(request, *args, **kwargs):
            if not request.user.is_authenticated:
                messages.warning(request, '请先登录')
                return redirect(redirect_url)
            
            # 检查是否是老师或管理员
            if hasattr(request.user, 'profile'):
                if request.user.profile.is_teacher or request.user.profile.is_admin:
                    return view_func(request, *args, **kwargs)
            
            # 超级用户也可以访问
            if request.user.is_superuser or request.user.is_staff:
                return view_func(request, *args, **kwargs)
            
            messages.error(request, '您没有权限访问此页面，需要老师或管理员权限')
            return HttpResponseForbidden('需要老师权限')
        
        return _wrapped_view
    
    if function:
        return decorator(function)
    return decorator


def admin_required(function=None, redirect_url='users:login'):
    """要求管理员权限"""
    def decorator(view_func):
        @wraps(view_func)
        def _wrapped_view(request, *args, **kwargs):
            if not request.user.is_authenticated:
                messages.warning(request, '请先登录')
                return redirect(redirect_url)
            
            # 检查是否是管理员或超级用户
            if request.user.is_superuser or request.user.is_staff:
                return view_func(request, *args, **kwargs)
            
            if hasattr(request.user, 'profile') and request.user.profile.is_admin:
                return view_func(request, *args, **kwargs)
            
            messages.error(request, '您没有权限访问此页面，需要管理员权限')
            return HttpResponseForbidden('需要管理员权限')
        
        return _wrapped_view
    
    if function:
        return decorator(function)
    return decorator


def anonymous_required(function=None, redirect_url='/'):
    """要求匿名用户（未登录）"""
    def decorator(view_func):
        @wraps(view_func)
        def _wrapped_view(request, *args, **kwargs):
            if request.user.is_authenticated:
                messages.info(request, '您已经登录')
                return redirect(redirect_url)
            
            return view_func(request, *args, **kwargs)
        
        return _wrapped_view
    
    if function:
        return decorator(function)
    return decorator

