from django.contrib import admin
from django.utils.html import format_html
from .models import Problem, ProblemTag, ProblemSample, TestCase, UserProblemStatus


@admin.register(ProblemTag)
class ProblemTagAdmin(admin.ModelAdmin):
    """题目标签管理"""
    list_display = ['name', 'color', 'problem_count', 'created_at']
    search_fields = ['name', 'description']
    list_filter = ['created_at']
    ordering = ['name']
    
    def problem_count(self, obj):
        """题目数量"""
        return obj.problems.count()
    problem_count.short_description = '题目数量'


class ProblemSampleInline(admin.TabularInline):
    """题目样例内联编辑"""
    model = ProblemSample
    extra = 1
    fields = ['order', 'input_data', 'output_data', 'explanation']
    ordering = ['order']


class TestCaseInline(admin.TabularInline):
    """测试用例内联编辑"""
    model = TestCase
    extra = 0
    fields = ['order', 'is_sample', 'score', 'time_limit', 'memory_limit']
    ordering = ['order']


@admin.register(Problem)
class ProblemAdmin(admin.ModelAdmin):
    """题目管理"""
    list_display = [
        'id',
        'title',
        'difficulty_badge',
        'status_badge',
        'acceptance_rate_display',
        'total_submit',
        'total_accepted',
        'created_at'
    ]
    list_filter = ['difficulty', 'status', 'is_special_judge', 'created_at', 'tags']
    search_fields = ['title', 'description', 'source']
    filter_horizontal = ['tags']
    readonly_fields = ['total_submit', 'total_accepted', 'created_at', 'updated_at']
    date_hierarchy = 'created_at'
    ordering = ['-created_at']
    
    fieldsets = (
        ('基本信息', {
            'fields': ('title', 'difficulty', 'status', 'tags')
        }),
        ('题目内容', {
            'fields': ('description', 'input_format', 'output_format', 'hint', 'source')
        }),
        ('限制条件', {
            'fields': ('time_limit', 'memory_limit', 'is_special_judge')
        }),
        ('统计信息', {
            'fields': ('total_submit', 'total_accepted')
        }),
        ('元数据', {
            'fields': ('created_by', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    inlines = [ProblemSampleInline, TestCaseInline]
    
    def difficulty_badge(self, obj):
        """难度徽章"""
        color_map = {
            'easy': '#28a745',
            'medium': '#ffc107',
            'hard': '#dc3545',
        }
        color = color_map.get(obj.difficulty, '#6c757d')
        return format_html(
            '<span style="background-color: {}; color: white; padding: 3px 8px; border-radius: 3px;">{}</span>',
            color,
            obj.get_difficulty_display()
        )
    difficulty_badge.short_description = '难度'
    
    def status_badge(self, obj):
        """状态徽章"""
        color_map = {
            'draft': '#6c757d',
            'published': '#28a745',
            'hidden': '#ffc107',
        }
        color = color_map.get(obj.status, '#6c757d')
        return format_html(
            '<span style="background-color: {}; color: white; padding: 3px 8px; border-radius: 3px;">{}</span>',
            color,
            obj.get_status_display()
        )
    status_badge.short_description = '状态'
    
    def acceptance_rate_display(self, obj):
        """通过率显示"""
        rate = obj.acceptance_rate
        if rate >= 50:
            color = '#28a745'
        elif rate >= 30:
            color = '#ffc107'
        else:
            color = '#dc3545'
        return format_html(
            '<span style="color: {}; font-weight: bold;">{}%</span>',
            color,
            rate
        )
    acceptance_rate_display.short_description = '通过率'
    
    def save_model(self, request, obj, form, change):
        """保存时自动设置创建者"""
        if not change:  # 新创建
            obj.created_by = request.user
        super().save_model(request, obj, form, change)
    
    actions = ['publish_problems', 'hide_problems', 'draft_problems']
    
    def publish_problems(self, request, queryset):
        """批量发布题目"""
        count = queryset.update(status='published')
        self.message_user(request, f'成功发布 {count} 个题目')
    publish_problems.short_description = '发布选中的题目'
    
    def hide_problems(self, request, queryset):
        """批量隐藏题目"""
        count = queryset.update(status='hidden')
        self.message_user(request, f'成功隐藏 {count} 个题目')
    hide_problems.short_description = '隐藏选中的题目'
    
    def draft_problems(self, request, queryset):
        """批量转为草稿"""
        count = queryset.update(status='draft')
        self.message_user(request, f'成功将 {count} 个题目转为草稿')
    draft_problems.short_description = '转为草稿'


@admin.register(ProblemSample)
class ProblemSampleAdmin(admin.ModelAdmin):
    """题目样例管理"""
    list_display = ['problem', 'order', 'input_preview', 'output_preview']
    list_filter = ['problem__difficulty']
    search_fields = ['problem__title']
    ordering = ['problem', 'order']
    
    def input_preview(self, obj):
        """输入预览"""
        return obj.input_data[:50] + '...' if len(obj.input_data) > 50 else obj.input_data
    input_preview.short_description = '输入预览'
    
    def output_preview(self, obj):
        """输出预览"""
        return obj.output_data[:50] + '...' if len(obj.output_data) > 50 else obj.output_data
    output_preview.short_description = '输出预览'


@admin.register(TestCase)
class TestCaseAdmin(admin.ModelAdmin):
    """测试用例管理"""
    list_display = ['problem', 'order', 'is_sample', 'score', 'time_limit_display', 'memory_limit_display']
    list_filter = ['is_sample', 'problem__difficulty']
    search_fields = ['problem__title']
    ordering = ['problem', 'order']
    
    def time_limit_display(self, obj):
        """时间限制显示"""
        return f"{obj.get_time_limit()}ms"
    time_limit_display.short_description = '时间限制'
    
    def memory_limit_display(self, obj):
        """内存限制显示"""
        return f"{obj.get_memory_limit()}MB"
    memory_limit_display.short_description = '内存限制'


@admin.register(UserProblemStatus)
class UserProblemStatusAdmin(admin.ModelAdmin):
    """用户题目状态管理"""
    list_display = [
        'user',
        'problem',
        'status_badge',
        'submit_count',
        'accepted_count',
        'first_accepted_at',
        'last_submit_at'
    ]
    list_filter = ['status', 'first_accepted_at', 'last_submit_at']
    search_fields = ['user__username', 'problem__title']
    readonly_fields = ['first_accepted_at', 'last_submit_at']
    ordering = ['-last_submit_at']
    
    def status_badge(self, obj):
        """状态徽章"""
        color_map = {
            'not_tried': '#6c757d',
            'trying': '#ffc107',
            'accepted': '#28a745',
        }
        color = color_map.get(obj.status, '#6c757d')
        return format_html(
            '<span style="background-color: {}; color: white; padding: 3px 8px; border-radius: 3px;">{}</span>',
            color,
            obj.get_status_display()
        )
    status_badge.short_description = '状态'

