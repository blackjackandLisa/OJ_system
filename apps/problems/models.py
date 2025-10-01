from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone


class ProblemTag(models.Model):
    """题目标签"""
    name = models.CharField(max_length=50, unique=True, verbose_name='标签名')
    color = models.CharField(max_length=20, default='blue', verbose_name='标签颜色')
    description = models.TextField(blank=True, verbose_name='标签描述')
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='创建时间')
    
    class Meta:
        db_table = 'problem_tags'
        verbose_name = '题目标签'
        verbose_name_plural = '题目标签'
        ordering = ['name']
    
    def __str__(self):
        return self.name


class Problem(models.Model):
    """题目主表"""
    
    # 难度选项
    DIFFICULTY_CHOICES = [
        ('easy', '简单'),
        ('medium', '中等'),
        ('hard', '困难'),
    ]
    
    # 状态选项
    STATUS_CHOICES = [
        ('draft', '草稿'),
        ('published', '已发布'),
        ('hidden', '已隐藏'),
    ]
    
    # 基本信息
    title = models.CharField(max_length=200, verbose_name='题目标题', db_index=True)
    description = models.TextField(verbose_name='题目描述')
    input_format = models.TextField(verbose_name='输入格式')
    output_format = models.TextField(verbose_name='输出格式')
    hint = models.TextField(blank=True, verbose_name='提示')
    source = models.CharField(max_length=200, blank=True, verbose_name='题目来源')
    
    # 限制条件
    time_limit = models.IntegerField(default=1000, verbose_name='时间限制(ms)')
    memory_limit = models.IntegerField(default=256, verbose_name='内存限制(MB)')
    
    # 难度和分类
    difficulty = models.CharField(
        max_length=20,
        choices=DIFFICULTY_CHOICES,
        default='medium',
        verbose_name='难度',
        db_index=True
    )
    
    tags = models.ManyToManyField(
        ProblemTag,
        related_name='problems',
        blank=True,
        verbose_name='标签'
    )
    
    # 状态
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='draft',
        verbose_name='状态',
        db_index=True
    )
    
    # 统计信息
    total_submit = models.IntegerField(default=0, verbose_name='总提交数')
    total_accepted = models.IntegerField(default=0, verbose_name='通过数')
    
    # 创建和修改信息
    created_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        related_name='created_problems',
        verbose_name='创建者'
    )
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='创建时间', db_index=True)
    updated_at = models.DateTimeField(auto_now=True, verbose_name='更新时间')
    
    # 其他
    is_special_judge = models.BooleanField(default=False, verbose_name='特殊判题')
    
    class Meta:
        db_table = 'problems'
        verbose_name = '题目'
        verbose_name_plural = '题目'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['difficulty', 'status']),
            models.Index(fields=['status', 'created_at']),
        ]
    
    def __str__(self):
        return f"{self.id}. {self.title}"
    
    @property
    def acceptance_rate(self):
        """通过率"""
        if self.total_submit == 0:
            return 0.0
        return round(self.total_accepted / self.total_submit * 100, 2)
    
    def get_difficulty_display_color(self):
        """获取难度对应的颜色"""
        color_map = {
            'easy': 'success',
            'medium': 'warning',
            'hard': 'danger',
        }
        return color_map.get(self.difficulty, 'secondary')


class ProblemSample(models.Model):
    """题目样例（公开展示）"""
    problem = models.ForeignKey(
        Problem,
        on_delete=models.CASCADE,
        related_name='samples',
        verbose_name='题目'
    )
    input_data = models.TextField(verbose_name='样例输入')
    output_data = models.TextField(verbose_name='样例输出')
    explanation = models.TextField(blank=True, verbose_name='样例说明')
    order = models.IntegerField(default=0, verbose_name='排序')
    
    class Meta:
        db_table = 'problem_samples'
        verbose_name = '题目样例'
        verbose_name_plural = '题目样例'
        ordering = ['order', 'id']
    
    def __str__(self):
        return f"{self.problem.title} - 样例{self.order + 1}"


class TestCase(models.Model):
    """测试用例"""
    problem = models.ForeignKey(
        Problem,
        on_delete=models.CASCADE,
        related_name='test_cases',
        verbose_name='题目'
    )
    input_data = models.TextField(verbose_name='输入数据')
    output_data = models.TextField(verbose_name='输出数据')
    
    # 属性
    is_sample = models.BooleanField(default=False, verbose_name='是否为样例')
    score = models.IntegerField(default=10, verbose_name='测试点分数')
    order = models.IntegerField(default=0, verbose_name='排序')
    
    # 资源限制（可选，覆盖题目默认设置）
    time_limit = models.IntegerField(
        null=True,
        blank=True,
        verbose_name='时间限制(ms)',
        help_text='留空则使用题目默认设置'
    )
    memory_limit = models.IntegerField(
        null=True,
        blank=True,
        verbose_name='内存限制(MB)',
        help_text='留空则使用题目默认设置'
    )
    
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='创建时间')
    
    class Meta:
        db_table = 'test_cases'
        verbose_name = '测试用例'
        verbose_name_plural = '测试用例'
        ordering = ['order', 'id']
        indexes = [
            models.Index(fields=['problem', 'is_sample']),
        ]
    
    def __str__(self):
        return f"{self.problem.title} - 测试用例{self.order + 1}"
    
    def get_time_limit(self):
        """获取实际时间限制"""
        return self.time_limit if self.time_limit is not None else self.problem.time_limit
    
    def get_memory_limit(self):
        """获取实际内存限制"""
        return self.memory_limit if self.memory_limit is not None else self.problem.memory_limit


class UserProblemStatus(models.Model):
    """用户题目状态"""
    
    STATUS_CHOICES = [
        ('not_tried', '未尝试'),
        ('trying', '尝试中'),
        ('accepted', '已通过'),
    ]
    
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='problem_statuses',
        verbose_name='用户'
    )
    problem = models.ForeignKey(
        Problem,
        on_delete=models.CASCADE,
        related_name='user_statuses',
        verbose_name='题目'
    )
    
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='not_tried',
        verbose_name='状态',
        db_index=True
    )
    
    submit_count = models.IntegerField(default=0, verbose_name='提交次数')
    accepted_count = models.IntegerField(default=0, verbose_name='通过次数')
    first_accepted_at = models.DateTimeField(null=True, blank=True, verbose_name='首次通过时间')
    last_submit_at = models.DateTimeField(null=True, blank=True, verbose_name='最后提交时间')
    
    class Meta:
        db_table = 'user_problem_status'
        verbose_name = '用户题目状态'
        verbose_name_plural = '用户题目状态'
        unique_together = [['user', 'problem']]
        indexes = [
            models.Index(fields=['user', 'status']),
            models.Index(fields=['problem', 'status']),
        ]
    
    def __str__(self):
        return f"{self.user.username} - {self.problem.title} - {self.get_status_display()}"

