from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone


class UserProfile(models.Model):
    """用户资料扩展"""
    
    # 用户类型选项
    USER_TYPE_CHOICES = [
        ('student', '学生'),
        ('teacher', '老师'),
        ('admin', '管理员'),
    ]
    
    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name='profile',
        verbose_name='关联用户'
    )
    
    # 角色信息
    user_type = models.CharField(
        max_length=20,
        choices=USER_TYPE_CHOICES,
        default='student',
        verbose_name='用户类型',
        db_index=True
    )
    
    # 基本信息
    real_name = models.CharField(max_length=50, verbose_name='真实姓名')
    student_id = models.CharField(
        max_length=50,
        blank=True,
        verbose_name='学号/工号',
        help_text='学生填写学号，老师填写工号'
    )
    avatar = models.ImageField(
        upload_to='avatars/%Y/%m/',
        blank=True,
        null=True,
        verbose_name='头像'
    )
    bio = models.TextField(blank=True, verbose_name='个人简介')
    
    # 组织信息
    school = models.CharField(max_length=100, blank=True, verbose_name='学校/机构')
    grade = models.CharField(max_length=50, blank=True, verbose_name='年级/届')
    major = models.CharField(max_length=100, blank=True, verbose_name='专业')
    
    # 联系方式
    phone = models.CharField(max_length=20, blank=True, verbose_name='手机号')
    qq = models.CharField(max_length=20, blank=True, verbose_name='QQ号')
    wechat = models.CharField(max_length=50, blank=True, verbose_name='微信号')
    
    # 统计信息
    total_submit = models.IntegerField(default=0, verbose_name='总提交数')
    total_accepted = models.IntegerField(default=0, verbose_name='通过题目数')
    total_tried = models.IntegerField(default=0, verbose_name='尝试题目数')
    
    # 状态信息
    is_active = models.BooleanField(default=True, verbose_name='是否激活')
    is_verified = models.BooleanField(default=False, verbose_name='是否验证邮箱')
    
    # 时间信息
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='注册时间')
    updated_at = models.DateTimeField(auto_now=True, verbose_name='更新时间')
    last_login_at = models.DateTimeField(null=True, blank=True, verbose_name='最后登录时间')
    
    class Meta:
        db_table = 'user_profiles'
        verbose_name = '用户资料'
        verbose_name_plural = '用户资料'
        indexes = [
            models.Index(fields=['user_type', 'is_active']),
            models.Index(fields=['student_id']),
        ]
    
    def __str__(self):
        return f"{self.real_name} ({self.user.username}) - {self.get_user_type_display()}"
    
    @property
    def acceptance_rate(self):
        """AC率"""
        if self.total_submit == 0:
            return 0.0
        return round(self.total_accepted / self.total_submit * 100, 2)
    
    @property
    def is_student(self):
        """是否是学生"""
        return self.user_type == 'student'
    
    @property
    def is_teacher(self):
        """是否是老师"""
        return self.user_type == 'teacher'
    
    @property
    def is_admin(self):
        """是否是管理员"""
        return self.user_type == 'admin' or self.user.is_superuser
    
    def update_stats(self):
        """更新统计信息"""
        from apps.problems.models import UserProblemStatus
        
        # 更新通过题目数
        self.total_accepted = UserProblemStatus.objects.filter(
            user=self.user,
            status='accepted'
        ).count()
        
        # 更新尝试题目数
        self.total_tried = UserProblemStatus.objects.filter(
            user=self.user
        ).exclude(status='not_tried').count()
        
        self.save()


class Class(models.Model):
    """班级/课程"""
    
    name = models.CharField(max_length=100, verbose_name='班级名称')
    code = models.CharField(
        max_length=50,
        unique=True,
        verbose_name='班级代码',
        help_text='学生加入班级时使用的邀请码'
    )
    description = models.TextField(blank=True, verbose_name='班级描述')
    
    # 老师
    teacher = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='teaching_classes',
        verbose_name='授课老师'
    )
    
    # 学生（多对多关系）
    students = models.ManyToManyField(
        User,
        related_name='enrolled_classes',
        blank=True,
        verbose_name='学生'
    )
    
    # 学期信息
    semester = models.CharField(
        max_length=50,
        blank=True,
        verbose_name='学期',
        help_text='如：2024春季'
    )
    
    # 状态
    is_active = models.BooleanField(default=True, verbose_name='是否激活')
    
    # 时间
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='创建时间')
    updated_at = models.DateTimeField(auto_now=True, verbose_name='更新时间')
    start_date = models.DateField(null=True, blank=True, verbose_name='开始日期')
    end_date = models.DateField(null=True, blank=True, verbose_name='结束日期')
    
    class Meta:
        db_table = 'classes'
        verbose_name = '班级'
        verbose_name_plural = '班级'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['teacher', 'is_active']),
            models.Index(fields=['code']),
        ]
    
    def __str__(self):
        return f"{self.name} ({self.code})"
    
    @property
    def student_count(self):
        """学生数量"""
        return self.students.count()


class UserLoginLog(models.Model):
    """用户登录日志"""
    
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='login_logs',
        verbose_name='用户'
    )
    
    # 登录信息
    ip_address = models.GenericIPAddressField(verbose_name='IP地址')
    user_agent = models.CharField(max_length=255, verbose_name='浏览器信息')
    login_time = models.DateTimeField(auto_now_add=True, verbose_name='登录时间')
    
    # 登录状态
    is_success = models.BooleanField(default=True, verbose_name='是否成功')
    fail_reason = models.CharField(
        max_length=100,
        blank=True,
        verbose_name='失败原因'
    )
    
    # 地理位置（可选）
    location = models.CharField(max_length=100, blank=True, verbose_name='登录位置')
    
    class Meta:
        db_table = 'user_login_logs'
        verbose_name = '登录日志'
        verbose_name_plural = '登录日志'
        ordering = ['-login_time']
        indexes = [
            models.Index(fields=['user', 'login_time']),
            models.Index(fields=['ip_address']),
        ]
    
    def __str__(self):
        status = '成功' if self.is_success else '失败'
        return f"{self.user.username} - {self.ip_address} - {status} - {self.login_time}"


class InvitationCode(models.Model):
    """邀请码（用于老师注册）"""
    
    code = models.CharField(
        max_length=50,
        unique=True,
        verbose_name='邀请码'
    )
    
    # 类型和用途
    for_user_type = models.CharField(
        max_length=20,
        choices=UserProfile.USER_TYPE_CHOICES,
        default='teacher',
        verbose_name='适用用户类型'
    )
    
    # 使用信息
    is_used = models.BooleanField(default=False, verbose_name='是否已使用')
    used_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='used_invitations',
        verbose_name='使用者'
    )
    used_at = models.DateTimeField(null=True, blank=True, verbose_name='使用时间')
    
    # 创建信息
    created_by = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='created_invitations',
        verbose_name='创建者'
    )
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='创建时间')
    
    # 有效期
    expires_at = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name='过期时间',
        help_text='留空表示永久有效'
    )
    
    # 备注
    note = models.CharField(max_length=200, blank=True, verbose_name='备注')
    
    class Meta:
        db_table = 'invitation_codes'
        verbose_name = '邀请码'
        verbose_name_plural = '邀请码'
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.code} ({self.get_for_user_type_display()})"
    
    def is_valid(self):
        """检查邀请码是否有效"""
        if self.is_used:
            return False
        if self.expires_at and self.expires_at < timezone.now():
            return False
        return True

