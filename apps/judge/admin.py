from django.contrib import admin
from django.utils.html import format_html
from .models import Language, Submission, JudgeServer


@admin.register(Language)
class LanguageAdmin(admin.ModelAdmin):
    """编程语言管理"""
    
    list_display = [
        'name', 'display_name', 'file_extension',
        'docker_image', 'is_active', 'order', 'created_at'
    ]
    list_filter = ['is_active']
    search_fields = ['name', 'display_name']
    ordering = ['order', 'name']
    
    fieldsets = (
        ('基本信息', {
            'fields': ('name', 'display_name', 'file_extension', 'is_active', 'order')
        }),
        ('编译配置', {
            'fields': ('compile_command', 'compile_timeout')
        }),
        ('运行配置', {
            'fields': ('run_command', 'docker_image')
        }),
        ('代码模板', {
            'fields': ('template',),
            'classes': ('collapse',)
        }),
    )


@admin.register(Submission)
class SubmissionAdmin(admin.ModelAdmin):
    """提交记录管理"""
    
    list_display = [
        'id', 'user', 'problem_link', 'language',
        'status_badge', 'result_badge',
        'score_display', 'time_memory_display',
        'created_at'
    ]
    list_filter = [
        'status', 'result', 'language',
        'created_at', 'is_public'
    ]
    search_fields = ['user__username', 'problem__title', 'ip_address']
    readonly_fields = [
        'id', 'user', 'problem', 'language',
        'code_length', 'ip_address', 'user_agent',
        'created_at', 'judged_at'
    ]
    ordering = ['-created_at']
    date_hierarchy = 'created_at'
    
    fieldsets = (
        ('基本信息', {
            'fields': (
                'id', 'user', 'problem', 'language',
                'code_length', 'created_at'
            )
        }),
        ('判题信息', {
            'fields': (
                'status', 'result', 'score', 'total_score', 'pass_rate',
                'time_used', 'memory_used',
                'test_cases_passed', 'test_cases_total'
            )
        }),
        ('错误信息', {
            'fields': (
                'compile_error', 'runtime_error', 'error_testcase'
            ),
            'classes': ('collapse',)
        }),
        ('判题详情', {
            'fields': ('judge_detail', 'judged_at'),
            'classes': ('collapse',)
        }),
        ('代码', {
            'fields': ('code',),
            'classes': ('collapse',)
        }),
        ('其他信息', {
            'fields': (
                'ip_address', 'user_agent',
                'is_public', 'shared'
            ),
            'classes': ('collapse',)
        }),
    )
    
    def problem_link(self, obj):
        """题目链接"""
        return format_html(
            '<a href="/admin/problems/problem/{}/change/">{}</a>',
            obj.problem.id,
            obj.problem.title
        )
    problem_link.short_description = '题目'
    
    def status_badge(self, obj):
        """状态徽章"""
        color_map = {
            'pending': '#6c757d',
            'judging': '#0d6efd',
            'finished': '#28a745',
            'error': '#dc3545',
        }
        color = color_map.get(obj.status, '#6c757d')
        
        return format_html(
            '<span style="background-color: {}; color: white; padding: 3px 10px; '
            'border-radius: 3px; font-size: 12px;">{}</span>',
            color,
            obj.get_status_display()
        )
    status_badge.short_description = '状态'
    
    def result_badge(self, obj):
        """结果徽章"""
        if not obj.result:
            return '-'
        
        color_map = {
            'AC': '#28a745',
            'WA': '#dc3545',
            'TLE': '#ffc107',
            'MLE': '#fd7e14',
            'RE': '#dc3545',
            'CE': '#17a2b8',
            'SE': '#6c757d',
            'PE': '#ffc107',
            'OLE': '#fd7e14',
        }
        color = color_map.get(obj.result, '#6c757d')
        
        return format_html(
            '<span style="background-color: {}; color: white; padding: 3px 10px; '
            'border-radius: 3px; font-weight: bold; font-size: 12px;">{}</span>',
            color,
            obj.result
        )
    result_badge.short_description = '结果'
    
    def score_display(self, obj):
        """得分显示"""
        if obj.total_score == 0:
            return '-'
        percentage = int((obj.score / obj.total_score) * 100)
        return f"{obj.score}/{obj.total_score} ({percentage}%)"
    score_display.short_description = '得分'
    
    def time_memory_display(self, obj):
        """时间内存显示"""
        if obj.time_used is None:
            return '-'
        return format_html(
            '<span style="color: #0d6efd;">{} ms</span> / '
            '<span style="color: #28a745;">{} KB</span>',
            obj.time_used,
            obj.memory_used or 0
        )
    time_memory_display.short_description = '时间/内存'
    
    def has_add_permission(self, request):
        """禁止手动添加"""
        return False


@admin.register(JudgeServer)
class JudgeServerAdmin(admin.ModelAdmin):
    """判题服务器管理"""
    
    list_display = [
        'hostname', 'ip_address', 'port',
        'status_badge', 'load_badge',
        'task_display', 'total_judged',
        'last_heartbeat'
    ]
    list_filter = ['is_active', 'is_available']
    search_fields = ['hostname', 'ip_address']
    readonly_fields = [
        'cpu_usage', 'memory_usage', 'task_count',
        'total_judged', 'created_at', 'last_heartbeat'
    ]
    
    fieldsets = (
        ('基本信息', {
            'fields': ('hostname', 'ip_address', 'port')
        }),
        ('状态', {
            'fields': ('is_active', 'is_available')
        }),
        ('负载信息', {
            'fields': (
                'cpu_usage', 'memory_usage',
                'task_count', 'max_tasks'
            )
        }),
        ('统计', {
            'fields': ('total_judged',)
        }),
        ('时间', {
            'fields': ('created_at', 'last_heartbeat')
        }),
    )
    
    def status_badge(self, obj):
        """状态徽章"""
        if obj.is_online:
            color = '#28a745'
            text = '在线'
        else:
            color = '#dc3545'
            text = '离线'
        
        return format_html(
            '<span style="background-color: {}; color: white; padding: 3px 10px; '
            'border-radius: 3px;">{}</span>',
            color,
            text
        )
    status_badge.short_description = '状态'
    
    def load_badge(self, obj):
        """负载徽章"""
        percentage = obj.load_percentage
        
        if percentage < 50:
            color = '#28a745'
        elif percentage < 80:
            color = '#ffc107'
        else:
            color = '#dc3545'
        
        return format_html(
            '<div style="width: 100px; background-color: #e9ecef; border-radius: 3px; overflow: hidden;">'
            '<div style="width: {}%; background-color: {}; color: white; '
            'text-align: center; padding: 2px; font-size: 11px;">{:.0f}%</div>'
            '</div>',
            percentage,
            color,
            percentage
        )
    load_badge.short_description = '负载'
    
    def task_display(self, obj):
        """任务显示"""
        return f"{obj.task_count}/{obj.max_tasks}"
    task_display.short_description = '当前任务'
