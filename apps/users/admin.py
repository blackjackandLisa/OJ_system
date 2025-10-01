from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.contrib.auth.models import User
from django.utils.html import format_html
from .models import UserProfile, Class, UserLoginLog, InvitationCode


class UserProfileInline(admin.StackedInline):
    """用户资料内联编辑"""
    model = UserProfile
    can_delete = False
    verbose_name = '用户资料'
    verbose_name_plural = '用户资料'
    
    fieldsets = (
        ('角色信息', {
            'fields': ('user_type', 'real_name', 'student_id')
        }),
        ('个人信息', {
            'fields': ('avatar', 'bio', 'phone', 'qq', 'wechat')
        }),
        ('组织信息', {
            'fields': ('school', 'grade', 'major')
        }),
        ('统计信息', {
            'fields': ('total_submit', 'total_accepted', 'total_tried'),
            'classes': ('collapse',)
        }),
        ('状态', {
            'fields': ('is_active', 'is_verified', 'last_login_at')
        }),
    )
    
    readonly_fields = ['total_submit', 'total_accepted', 'total_tried', 'last_login_at']


class CustomUserAdmin(BaseUserAdmin):
    """自定义用户管理"""
    inlines = [UserProfileInline]
    list_display = [
        'username',
        'email',
        'real_name_display',
        'user_type_badge',
        'is_active',
        'is_staff',
        'date_joined'
    ]
    list_filter = ['is_staff', 'is_superuser', 'is_active', 'date_joined', 'profile__user_type']
    search_fields = ['username', 'email', 'profile__real_name', 'profile__student_id']
    
    def real_name_display(self, obj):
        """真实姓名"""
        if hasattr(obj, 'profile'):
            return obj.profile.real_name
        return '-'
    real_name_display.short_description = '真实姓名'
    
    def user_type_badge(self, obj):
        """用户类型徽章"""
        if not hasattr(obj, 'profile'):
            return '-'
        
        color_map = {
            'student': '#17a2b8',
            'teacher': '#28a745',
            'admin': '#dc3545',
        }
        color = color_map.get(obj.profile.user_type, '#6c757d')
        
        return format_html(
            '<span style="background-color: {}; color: white; padding: 3px 10px; border-radius: 3px;">{}</span>',
            color,
            obj.profile.get_user_type_display()
        )
    user_type_badge.short_description = '用户类型'


# 注销默认的User管理，使用自定义的
admin.site.unregister(User)
admin.site.register(User, CustomUserAdmin)


@admin.register(UserProfile)
class UserProfileAdmin(admin.ModelAdmin):
    """用户资料管理"""
    list_display = [
        'user',
        'real_name',
        'user_type_badge',
        'student_id',
        'school',
        'stats_display',
        'is_active',
        'created_at'
    ]
    list_filter = ['user_type', 'is_active', 'is_verified', 'school', 'grade']
    search_fields = ['real_name', 'student_id', 'user__username', 'user__email']
    readonly_fields = ['total_submit', 'total_accepted', 'total_tried', 'created_at', 'updated_at']
    
    fieldsets = (
        ('关联用户', {
            'fields': ('user',)
        }),
        ('角色信息', {
            'fields': ('user_type', 'real_name', 'student_id')
        }),
        ('个人信息', {
            'fields': ('avatar', 'bio', 'phone', 'qq', 'wechat')
        }),
        ('组织信息', {
            'fields': ('school', 'grade', 'major')
        }),
        ('统计信息', {
            'fields': ('total_submit', 'total_accepted', 'total_tried')
        }),
        ('状态', {
            'fields': ('is_active', 'is_verified', 'last_login_at')
        }),
        ('时间信息', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def user_type_badge(self, obj):
        """用户类型徽章"""
        color_map = {
            'student': '#17a2b8',
            'teacher': '#28a745',
            'admin': '#dc3545',
        }
        color = color_map.get(obj.user_type, '#6c757d')
        
        return format_html(
            '<span style="background-color: {}; color: white; padding: 3px 10px; border-radius: 3px;">{}</span>',
            color,
            obj.get_user_type_display()
        )
    user_type_badge.short_description = '用户类型'
    
    def stats_display(self, obj):
        """统计信息"""
        return format_html(
            '提交: <strong>{}</strong> | 通过: <strong style="color: green;">{}</strong> | AC率: <strong>{}%</strong>',
            obj.total_submit,
            obj.total_accepted,
            obj.acceptance_rate
        )
    stats_display.short_description = '统计信息'
    
    actions = ['activate_users', 'deactivate_users', 'verify_users']
    
    def activate_users(self, request, queryset):
        """批量激活用户"""
        count = queryset.update(is_active=True)
        self.message_user(request, f'成功激活 {count} 个用户')
    activate_users.short_description = '激活选中的用户'
    
    def deactivate_users(self, request, queryset):
        """批量禁用用户"""
        count = queryset.update(is_active=False)
        self.message_user(request, f'成功禁用 {count} 个用户')
    deactivate_users.short_description = '禁用选中的用户'
    
    def verify_users(self, request, queryset):
        """批量验证用户"""
        count = queryset.update(is_verified=True)
        self.message_user(request, f'成功验证 {count} 个用户')
    verify_users.short_description = '验证选中的用户'


@admin.register(Class)
class ClassAdmin(admin.ModelAdmin):
    """班级管理"""
    list_display = [
        'name',
        'code',
        'teacher',
        'student_count_display',
        'semester',
        'is_active',
        'created_at'
    ]
    list_filter = ['is_active', 'semester', 'created_at']
    search_fields = ['name', 'code', 'teacher__username', 'description']
    filter_horizontal = ['students']
    
    fieldsets = (
        ('基本信息', {
            'fields': ('name', 'code', 'description')
        }),
        ('老师', {
            'fields': ('teacher',)
        }),
        ('学期', {
            'fields': ('semester', 'start_date', 'end_date')
        }),
        ('学生', {
            'fields': ('students',)
        }),
        ('状态', {
            'fields': ('is_active',)
        }),
    )
    
    readonly_fields = ['created_at', 'updated_at']
    
    def student_count_display(self, obj):
        """学生数量"""
        count = obj.student_count
        return format_html(
            '<span style="color: #007bff; font-weight: bold;">{}</span> 人',
            count
        )
    student_count_display.short_description = '学生人数'


@admin.register(UserLoginLog)
class UserLoginLogAdmin(admin.ModelAdmin):
    """登录日志管理"""
    list_display = [
        'user',
        'ip_address',
        'location',
        'status_badge',
        'login_time'
    ]
    list_filter = ['is_success', 'login_time']
    search_fields = ['user__username', 'ip_address', 'location']
    readonly_fields = ['user', 'ip_address', 'user_agent', 'login_time', 'location']
    
    def status_badge(self, obj):
        """状态徽章"""
        if obj.is_success:
            return format_html(
                '<span style="background-color: #28a745; color: white; padding: 3px 10px; border-radius: 3px;">成功</span>'
            )
        else:
            return format_html(
                '<span style="background-color: #dc3545; color: white; padding: 3px 10px; border-radius: 3px;">失败: {}</span>',
                obj.fail_reason
            )
    status_badge.short_description = '登录状态'
    
    def has_add_permission(self, request):
        """禁止手动添加日志"""
        return False
    
    def has_change_permission(self, request, obj=None):
        """禁止修改日志"""
        return False


@admin.register(InvitationCode)
class InvitationCodeAdmin(admin.ModelAdmin):
    """邀请码管理"""
    list_display = [
        'code',
        'for_user_type_badge',
        'status_badge',
        'used_by',
        'created_by',
        'expires_at'
    ]
    list_filter = ['for_user_type', 'is_used', 'created_at']
    search_fields = ['code', 'note', 'used_by__username']
    readonly_fields = ['is_used', 'used_by', 'used_at', 'created_at']
    
    fieldsets = (
        ('邀请码信息', {
            'fields': ('code', 'for_user_type', 'note')
        }),
        ('有效期', {
            'fields': ('expires_at',)
        }),
        ('使用信息', {
            'fields': ('is_used', 'used_by', 'used_at'),
            'classes': ('collapse',)
        }),
        ('创建信息', {
            'fields': ('created_by', 'created_at'),
            'classes': ('collapse',)
        }),
    )
    
    def for_user_type_badge(self, obj):
        """用户类型徽章"""
        color_map = {
            'student': '#17a2b8',
            'teacher': '#28a745',
            'admin': '#dc3545',
        }
        color = color_map.get(obj.for_user_type, '#6c757d')
        
        return format_html(
            '<span style="background-color: {}; color: white; padding: 3px 10px; border-radius: 3px;">{}</span>',
            color,
            obj.get_for_user_type_display()
        )
    for_user_type_badge.short_description = '用户类型'
    
    def status_badge(self, obj):
        """状态徽章"""
        if obj.is_used:
            return format_html(
                '<span style="background-color: #6c757d; color: white; padding: 3px 10px; border-radius: 3px;">已使用</span>'
            )
        elif obj.expires_at and obj.expires_at < timezone.now():
            return format_html(
                '<span style="background-color: #ffc107; color: white; padding: 3px 10px; border-radius: 3px;">已过期</span>'
            )
        else:
            return format_html(
                '<span style="background-color: #28a745; color: white; padding: 3px 10px; border-radius: 3px;">有效</span>'
            )
    status_badge.short_description = '状态'
    
    def save_model(self, request, obj, form, change):
        """保存时自动设置创建者"""
        if not change:
            obj.created_by = request.user
        super().save_model(request, obj, form, change)
    
    actions = ['generate_codes']
    
    def generate_codes(self, request, queryset):
        """批量生成邀请码"""
        import random
        import string
        
        count = 0
        for _ in range(10):  # 生成10个邀请码
            code = ''.join(random.choices(string.ascii_uppercase + string.digits, k=12))
            InvitationCode.objects.create(
                code=code,
                for_user_type='teacher',
                created_by=request.user,
                note='批量生成'
            )
            count += 1
        
        self.message_user(request, f'成功生成 {count} 个邀请码')
    generate_codes.short_description = '批量生成邀请码'

