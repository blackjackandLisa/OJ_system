from rest_framework import permissions


class IsTeacherOrAdmin(permissions.BasePermission):
    """老师或管理员权限"""
    
    def has_permission(self, request, view):
        # 允许所有人读取
        if request.method in permissions.SAFE_METHODS:
            return True
        
        # 写操作需要认证
        if not request.user.is_authenticated:
            return False
        
        # 管理员或超级用户
        if request.user.is_staff or request.user.is_superuser:
            return True
        
        # 老师
        if hasattr(request.user, 'profile'):
            return request.user.profile.is_teacher or request.user.profile.is_admin
        
        return False


class IsOwnerOrTeacherOrAdmin(permissions.BasePermission):
    """拥有者、老师或管理员权限"""
    
    def has_object_permission(self, request, view, obj):
        # 允许所有人读取
        if request.method in permissions.SAFE_METHODS:
            return True
        
        # 管理员可以修改所有
        if request.user.is_staff or request.user.is_superuser:
            return True
        
        # 创建者可以修改自己的
        if hasattr(obj, 'created_by') and obj.created_by == request.user:
            return True
        
        # 管理员profile
        if hasattr(request.user, 'profile') and request.user.profile.is_admin:
            return True
        
        return False

