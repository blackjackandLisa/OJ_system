from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone
from apps.problems.models import Problem


class Language(models.Model):
    """编程语言配置"""
    
    name = models.CharField(max_length=50, unique=True, verbose_name='语言名称')
    display_name = models.CharField(max_length=100, verbose_name='显示名称')
    
    # 编译配置
    compile_command = models.TextField(blank=True, verbose_name='编译命令')
    compile_timeout = models.IntegerField(default=30, verbose_name='编译超时(秒)')
    
    # 运行配置
    run_command = models.TextField(verbose_name='运行命令')
    
    # 代码模板
    template = models.TextField(blank=True, verbose_name='代码模板')
    
    # 沙箱配置
    docker_image = models.CharField(max_length=200, verbose_name='Docker镜像')
    
    # 文件扩展名
    file_extension = models.CharField(max_length=10, verbose_name='文件扩展名')
    
    # 状态
    is_active = models.BooleanField(default=True, verbose_name='是否启用')
    order = models.IntegerField(default=0, verbose_name='排序')
    
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='创建时间')
    
    class Meta:
        db_table = 'languages'
        verbose_name = '编程语言'
        verbose_name_plural = '编程语言'
        ordering = ['order', 'name']
    
    def __str__(self):
        return self.display_name


class Submission(models.Model):
    """代码提交记录"""
    
    # 判题状态
    STATUS_CHOICES = [
        ('pending', '等待中'),      # 在队列中
        ('judging', '判题中'),      # 正在判题
        ('finished', '已完成'),     # 判题完成
        ('error', '系统错误'),      # 判题失败
    ]
    
    # 判题结果
    RESULT_CHOICES = [
        ('AC', 'Accepted'),                  # 通过
        ('WA', 'Wrong Answer'),              # 答案错误
        ('TLE', 'Time Limit Exceeded'),      # 超时
        ('MLE', 'Memory Limit Exceeded'),    # 超内存
        ('RE', 'Runtime Error'),             # 运行错误
        ('CE', 'Compile Error'),             # 编译错误
        ('SE', 'System Error'),              # 系统错误
        ('PE', 'Presentation Error'),        # 格式错误
        ('OLE', 'Output Limit Exceeded'),    # 输出超限
    ]
    
    # 基本信息
    id = models.BigAutoField(primary_key=True)
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='submissions',
        verbose_name='用户'
    )
    problem = models.ForeignKey(
        Problem,
        on_delete=models.CASCADE,
        related_name='submissions',
        verbose_name='题目'
    )
    
    # 代码信息
    language = models.ForeignKey(
        Language,
        on_delete=models.PROTECT,
        related_name='submissions',
        verbose_name='编程语言'
    )
    code = models.TextField(verbose_name='源代码')
    code_length = models.IntegerField(verbose_name='代码长度')
    
    # 判题信息
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='pending',
        verbose_name='判题状态',
        db_index=True
    )
    result = models.CharField(
        max_length=10,
        choices=RESULT_CHOICES,
        null=True,
        blank=True,
        verbose_name='判题结果',
        db_index=True
    )
    
    # 运行结果
    score = models.IntegerField(default=0, verbose_name='得分')
    total_score = models.IntegerField(verbose_name='总分')
    pass_rate = models.FloatField(default=0.0, verbose_name='通过率')
    
    time_used = models.IntegerField(null=True, blank=True, verbose_name='运行时间(ms)')
    memory_used = models.IntegerField(null=True, blank=True, verbose_name='内存占用(KB)')
    
    # 测试用例信息
    test_cases_passed = models.IntegerField(default=0, verbose_name='通过的测试用例数')
    test_cases_total = models.IntegerField(verbose_name='总测试用例数')
    
    # 错误信息
    compile_error = models.TextField(blank=True, verbose_name='编译错误信息')
    runtime_error = models.TextField(blank=True, verbose_name='运行时错误信息')
    error_testcase = models.IntegerField(null=True, blank=True, verbose_name='出错的测试用例编号')
    
    # 判题详情（JSON）
    judge_detail = models.JSONField(
        null=True,
        blank=True,
        default=dict,
        verbose_name='判题详情'
    )
    
    # IP和标识
    ip_address = models.GenericIPAddressField(verbose_name='IP地址')
    user_agent = models.TextField(blank=True, verbose_name='User Agent')
    
    # 时间信息
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='提交时间', db_index=True)
    judged_at = models.DateTimeField(null=True, blank=True, verbose_name='判题完成时间')
    
    # 其他
    is_public = models.BooleanField(default=True, verbose_name='是否公开')
    shared = models.BooleanField(default=False, verbose_name='是否分享')
    
    class Meta:
        db_table = 'submissions'
        verbose_name = '代码提交'
        verbose_name_plural = '代码提交'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', 'problem']),
            models.Index(fields=['problem', 'result']),
            models.Index(fields=['status', 'created_at']),
            models.Index(fields=['user', 'result', 'created_at']),
        ]
    
    def __str__(self):
        return f"#{self.id} - {self.user.username} - {self.problem.title}"
    
    @property
    def is_accepted(self):
        """是否通过"""
        return self.result == 'AC'
    
    @property
    def judge_time(self):
        """判题耗时（秒）"""
        if self.judged_at and self.created_at:
            return (self.judged_at - self.created_at).total_seconds()
        return None
    
    def get_result_color(self):
        """获取结果对应的颜色"""
        color_map = {
            'AC': 'success',
            'WA': 'danger',
            'TLE': 'warning',
            'MLE': 'warning',
            'RE': 'danger',
            'CE': 'info',
            'SE': 'secondary',
            'PE': 'warning',
            'OLE': 'warning',
        }
        return color_map.get(self.result, 'secondary')
    
    def get_result_icon(self):
        """获取结果对应的图标"""
        icon_map = {
            'AC': 'fa-check-circle',
            'WA': 'fa-times-circle',
            'TLE': 'fa-clock',
            'MLE': 'fa-memory',
            'RE': 'fa-bug',
            'CE': 'fa-wrench',
            'SE': 'fa-exclamation-triangle',
            'PE': 'fa-file-alt',
            'OLE': 'fa-file-export',
        }
        return icon_map.get(self.result, 'fa-question-circle')


class JudgeServer(models.Model):
    """判题服务器"""
    
    hostname = models.CharField(max_length=100, unique=True, verbose_name='主机名')
    ip_address = models.GenericIPAddressField(verbose_name='IP地址')
    port = models.IntegerField(default=8080, verbose_name='端口')
    
    # 状态
    is_active = models.BooleanField(default=True, verbose_name='是否激活')
    is_available = models.BooleanField(default=True, verbose_name='是否可用')
    
    # 负载信息
    cpu_usage = models.FloatField(default=0.0, verbose_name='CPU使用率')
    memory_usage = models.FloatField(default=0.0, verbose_name='内存使用率')
    task_count = models.IntegerField(default=0, verbose_name='当前任务数')
    max_tasks = models.IntegerField(default=10, verbose_name='最大任务数')
    
    # 统计
    total_judged = models.IntegerField(default=0, verbose_name='总判题数')
    
    # 时间
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='创建时间')
    last_heartbeat = models.DateTimeField(auto_now=True, verbose_name='最后心跳')
    
    class Meta:
        db_table = 'judge_servers'
        verbose_name = '判题服务器'
        verbose_name_plural = '判题服务器'
        ordering = ['hostname']
    
    def __str__(self):
        return f"{self.hostname} ({self.ip_address})"
    
    @property
    def is_online(self):
        """是否在线（最近5分钟有心跳）"""
        if not self.last_heartbeat:
            return False
        return (timezone.now() - self.last_heartbeat).total_seconds() < 300
    
    @property
    def load_percentage(self):
        """负载百分比"""
        if self.max_tasks == 0:
            return 100
        return int((self.task_count / self.max_tasks) * 100)
