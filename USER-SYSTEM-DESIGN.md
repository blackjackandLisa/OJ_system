# 用户认证系统需求设计

## 📋 需求梳理

### 1. 用户角色定义

#### 1.1 学生（Student）
**权限范围：**
- ✅ 查看已发布的题目
- ✅ 提交代码
- ✅ 查看自己的提交记录
- ✅ 查看自己的统计信息
- ✅ 参与讨论
- ❌ 创建/编辑题目
- ❌ 查看测试用例答案
- ❌ 管理其他用户

**使用场景：**
- 练习算法题目
- 参加比赛
- 查看排行榜
- 查看个人进度

#### 1.2 老师（Teacher）
**权限范围：**
- ✅ 学生的所有权限
- ✅ 创建和编辑题目
- ✅ 管理测试用例
- ✅ 查看所有学生的提交记录
- ✅ 创建和管理班级
- ✅ 创建和管理作业
- ✅ 查看班级统计
- ❌ 管理其他老师
- ❌ 系统配置

**使用场景：**
- 出题和管理题库
- 布置作业
- 查看学生完成情况
- 评分和反馈

#### 1.3 管理员（Admin）
**权限范围：**
- ✅ 所有权限
- ✅ 管理用户（创建、编辑、删除）
- ✅ 管理所有题目
- ✅ 系统配置
- ✅ 查看系统日志
- ✅ 数据统计和分析

**使用场景：**
- 系统维护
- 用户管理
- 数据管理
- 系统配置

### 2. 用户信息需求

#### 2.1 基本信息
- 用户名（唯一，用于登录）
- 邮箱（唯一，用于找回密码）
- 密码（加密存储）
- 真实姓名
- 学号/工号（可选）
- 头像
- 个人简介

#### 2.2 角色信息
- 用户类型（学生/老师/管理员）
- 所属班级/组织（学生）
- 所管理的班级（老师）

#### 2.3 统计信息
- 总提交数
- 通过题目数
- 尝试题目数
- AC率
- 注册时间
- 最后登录时间

#### 2.4 扩展信息
- 学校/机构
- 年级/届
- 专业
- 个性签名

### 3. 认证功能需求

#### 3.1 注册功能
```
学生注册：
- 用户名（必填）
- 邮箱（必填）
- 密码（必填，需确认）
- 真实姓名（必填）
- 学号（可选）
- 验证码（防止机器注册）

老师注册：
- 需要管理员审核或邀请码
- 额外信息：职位、所属部门

管理员：
- 只能通过命令行创建
```

#### 3.2 登录功能
```
支持方式：
- 用户名 + 密码
- 邮箱 + 密码

附加功能：
- 记住我（7天免登录）
- 忘记密码（邮件重置）
- 登录限制（防暴力破解）
```

#### 3.3 个人中心
```
功能：
- 查看个人信息
- 修改个人资料
- 修改密码
- 上传头像
- 查看做题统计
- 查看提交历史
- 查看通过的题目
```

#### 3.4 权限控制
```
装饰器：
- @student_required  # 学生权限
- @teacher_required  # 老师权限
- @admin_required    # 管理员权限

中间件：
- 自动记录用户行为
- 检查用户状态（是否被禁用）
```

## 🗄️ 数据库设计

### 扩展User模型

#### UserProfile（用户资料表）
```python
class UserProfile(models.Model):
    """用户资料扩展"""
    
    # 用户类型
    USER_TYPE_CHOICES = [
        ('student', '学生'),
        ('teacher', '老师'),
        ('admin', '管理员'),
    ]
    
    user = OneToOneField(User, on_delete=CASCADE, related_name='profile')
    
    # 角色信息
    user_type = CharField(
        max_length=20,
        choices=USER_TYPE_CHOICES,
        default='student',
        verbose_name='用户类型'
    )
    
    # 基本信息
    real_name = CharField(max_length=50, verbose_name='真实姓名')
    student_id = CharField(max_length=50, blank=True, verbose_name='学号/工号')
    avatar = ImageField(upload_to='avatars/', blank=True, verbose_name='头像')
    bio = TextField(blank=True, verbose_name='个人简介')
    
    # 组织信息
    school = CharField(max_length=100, blank=True, verbose_name='学校/机构')
    grade = CharField(max_length=50, blank=True, verbose_name='年级/届')
    major = CharField(max_length=100, blank=True, verbose_name='专业')
    
    # 统计信息
    total_submit = IntegerField(default=0, verbose_name='总提交数')
    total_accepted = IntegerField(default=0, verbose_name='通过题目数')
    
    # 其他
    created_at = DateTimeField(auto_now_add=True)
    last_login_at = DateTimeField(null=True, blank=True)
    is_active = BooleanField(default=True, verbose_name='是否激活')
    
    @property
    def acceptance_rate(self):
        """AC率"""
        if self.total_submit == 0:
            return 0
        return round(self.total_accepted / self.total_submit * 100, 2)
    
    @property
    def is_student(self):
        return self.user_type == 'student'
    
    @property
    def is_teacher(self):
        return self.user_type == 'teacher'
    
    @property
    def is_admin(self):
        return self.user_type == 'admin' or self.user.is_superuser
```

#### Class（班级表）
```python
class Class(models.Model):
    """班级/课程"""
    name = CharField(max_length=100, verbose_name='班级名称')
    code = CharField(max_length=50, unique=True, verbose_name='班级代码')
    description = TextField(blank=True, verbose_name='班级描述')
    
    # 老师
    teacher = ForeignKey(
        User,
        on_delete=CASCADE,
        limit_choices_to={'profile__user_type': 'teacher'},
        related_name='teaching_classes',
        verbose_name='授课老师'
    )
    
    # 学生
    students = ManyToManyField(
        User,
        limit_choices_to={'profile__user_type': 'student'},
        related_name='enrolled_classes',
        blank=True,
        verbose_name='学生'
    )
    
    # 状态
    is_active = BooleanField(default=True, verbose_name='是否激活')
    created_at = DateTimeField(auto_now_add=True)
```

#### UserLoginLog（登录日志表）
```python
class UserLoginLog(models.Model):
    """用户登录日志"""
    user = ForeignKey(User, on_delete=CASCADE, related_name='login_logs')
    ip_address = GenericIPAddressField(verbose_name='IP地址')
    user_agent = CharField(max_length=255, verbose_name='浏览器信息')
    login_time = DateTimeField(auto_now_add=True, verbose_name='登录时间')
    is_success = BooleanField(default=True, verbose_name='是否成功')
```

## 🎨 页面设计

### 1. 注册页面
```html
┌─────────────────────────────────────┐
│  OJ系统 - 用户注册                   │
├─────────────────────────────────────┤
│                                      │
│  [选择角色]                          │
│  ○ 学生注册  ○ 老师注册              │
│                                      │
│  用户名: [____________]               │
│  邮箱:   [____________]               │
│  密码:   [____________]               │
│  确认:   [____________]               │
│                                      │
│  真实姓名: [____________]             │
│  学号:     [____________] (学生)      │
│  邀请码:   [____________] (老师)      │
│                                      │
│  学校:   [____________]               │
│  年级:   [____________]               │
│  专业:   [____________]               │
│                                      │
│  [注册] [已有账号？登录]              │
└─────────────────────────────────────┘
```

### 2. 登录页面
```html
┌─────────────────────────────────────┐
│  OJ系统 - 用户登录                   │
├─────────────────────────────────────┤
│                                      │
│  用户名/邮箱: [____________]          │
│  密码:        [____________]          │
│                                      │
│  [√] 记住我  [忘记密码?]              │
│                                      │
│  [登录]                               │
│                                      │
│  还没有账号？[立即注册]               │
└─────────────────────────────────────┘
```

### 3. 个人中心
```html
┌─────────────────────────────────────┐
│  个人中心                             │
├─────────────────────────────────────┤
│  [头像]  用户名                       │
│          真实姓名                     │
│          学生 | 学号: 20210001        │
├─────────────────────────────────────┤
│  [个人信息] [做题统计] [提交记录]     │
│                                      │
│  通过题目: 15 题                      │
│  总提交数: 50 次                      │
│  AC率: 30%                           │
│                                      │
│  最近通过:                            │
│  ✓ 两数之和 (2天前)                   │
│  ✓ 回文数 (5天前)                     │
│  ...                                 │
└─────────────────────────────────────┘
```

## 🔐 权限控制设计

### 权限矩阵

| 功能 | 学生 | 老师 | 管理员 |
|------|------|------|--------|
| 查看题目 | ✅ | ✅ | ✅ |
| 提交代码 | ✅ | ✅ | ✅ |
| 查看自己的提交 | ✅ | ✅ | ✅ |
| 创建题目 | ❌ | ✅ | ✅ |
| 编辑题目 | ❌ | ✅自己创建的 | ✅所有 |
| 删除题目 | ❌ | ✅自己创建的 | ✅所有 |
| 查看测试用例 | ❌ | ✅ | ✅ |
| 查看他人提交 | ❌ | ✅班级学生 | ✅所有 |
| 管理用户 | ❌ | ❌ | ✅ |
| 创建班级 | ❌ | ✅ | ✅ |
| 管理班级 | ❌ | ✅自己的班级 | ✅所有 |
| 系统配置 | ❌ | ❌ | ✅ |

### 装饰器实现

```python
# users/decorators.py

def student_required(function):
    """要求学生权限"""
    def wrap(request, *args, **kwargs):
        if request.user.is_authenticated:
            if request.user.profile.is_student or request.user.is_staff:
                return function(request, *args, **kwargs)
        return redirect('users:login')
    return wrap

def teacher_required(function):
    """要求老师权限"""
    def wrap(request, *args, **kwargs):
        if request.user.is_authenticated:
            if request.user.profile.is_teacher or request.user.is_staff:
                return function(request, *args, **kwargs)
        return redirect('users:login')
    return wrap

def admin_required(function):
    """要求管理员权限"""
    def wrap(request, *args, **kwargs):
        if request.user.is_authenticated and request.user.is_staff:
            return function(request, *args, **kwargs)
        return redirect('users:login')
    return wrap
```

## 🔑 认证流程设计

### 注册流程

```
用户访问注册页
    ↓
选择角色（学生/老师）
    ↓
填写注册信息
    ↓
验证信息（用户名、邮箱唯一性）
    ↓
[学生] → 直接注册成功
[老师] → 需要邀请码或审核
    ↓
发送欢迎邮件（可选）
    ↓
自动登录 → 跳转到个人中心
```

### 登录流程

```
用户访问登录页
    ↓
输入用户名/邮箱 + 密码
    ↓
验证凭据
    ↓
记录登录日志
    ↓
更新最后登录时间
    ↓
创建Session
    ↓
跳转到首页或来源页面
```

### 密码重置流程

```
用户点击"忘记密码"
    ↓
输入邮箱
    ↓
发送重置链接（含token）
    ↓
用户点击邮件链接
    ↓
验证token有效性
    ↓
输入新密码
    ↓
更新密码 → 自动登录
```

## 🎨 API设计

### 认证相关API

#### 注册
```
POST /api/users/register/

请求体:
{
  "username": "student001",
  "email": "student@example.com",
  "password": "SecurePass123!",
  "password2": "SecurePass123!",
  "user_type": "student",
  "real_name": "张三",
  "student_id": "20210001",
  "school": "XX大学",
  "grade": "2021",
  "major": "计算机科学"
}

响应: 201 Created
{
  "id": 1,
  "username": "student001",
  "email": "student@example.com",
  "token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "user_type": "student"
}
```

#### 登录
```
POST /api/users/login/

请求体:
{
  "username": "student001",
  "password": "SecurePass123!"
}

响应: 200 OK
{
  "token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "user": {
    "id": 1,
    "username": "student001",
    "email": "student@example.com",
    "user_type": "student",
    "real_name": "张三"
  }
}
```

#### 登出
```
POST /api/users/logout/

响应: 200 OK
```

#### 获取当前用户信息
```
GET /api/users/me/

响应: 200 OK
{
  "id": 1,
  "username": "student001",
  "email": "student@example.com",
  "user_type": "student",
  "real_name": "张三",
  "student_id": "20210001",
  "avatar": "/media/avatars/user1.jpg",
  "stats": {
    "total_submit": 50,
    "total_accepted": 15,
    "acceptance_rate": 30.0
  }
}
```

#### 更新个人信息
```
PUT /api/users/me/
PATCH /api/users/me/

请求体:
{
  "real_name": "张三",
  "bio": "热爱算法的学生",
  "school": "XX大学"
}

响应: 200 OK
```

#### 修改密码
```
POST /api/users/change-password/

请求体:
{
  "old_password": "OldPass123!",
  "new_password": "NewPass123!",
  "new_password2": "NewPass123!"
}

响应: 200 OK
```

### 用户管理API（管理员）

```
GET /api/users/              # 用户列表
GET /api/users/{id}/         # 用户详情
PUT /api/users/{id}/         # 更新用户
DELETE /api/users/{id}/      # 删除用户
POST /api/users/{id}/ban/    # 禁用用户
POST /api/users/{id}/unban/  # 解禁用户
```

### 班级管理API（老师）

```
GET /api/classes/              # 班级列表
POST /api/classes/             # 创建班级
GET /api/classes/{id}/         # 班级详情
PUT /api/classes/{id}/         # 更新班级
DELETE /api/classes/{id}/      # 删除班级
POST /api/classes/{id}/join/   # 学生加入班级
```

## 🛡️ 安全设计

### 1. 密码安全
- ✅ 使用Django内置的密码加密（PBKDF2）
- ✅ 密码强度验证
- ✅ 密码历史记录（防止重复使用）
- ✅ 登录失败限制（5次后锁定10分钟）

### 2. Session安全
- ✅ Session超时设置（2小时）
- ✅ CSRF保护
- ✅ 安全Cookie（HTTPS环境）

### 3. 防暴力破解
- ✅ 登录频率限制
- ✅ 验证码（多次失败后）
- ✅ IP黑名单

### 4. 数据验证
- ✅ 用户名格式验证（3-20位，字母数字下划线）
- ✅ 邮箱格式验证
- ✅ 密码复杂度验证
- ✅ XSS防护

## 🎯 用户注册流程

### 学生注册（开放注册）
```
1. 访问注册页面
2. 选择"学生注册"
3. 填写基本信息
   - 用户名
   - 邮箱
   - 密码
   - 真实姓名
   - 学号（可选）
4. 填写学校信息（可选）
5. 同意服务条款
6. 提交注册
7. 自动登录
8. 跳转到个人中心
```

### 老师注册（需要审核）
```
1. 访问注册页面
2. 选择"老师注册"
3. 填写基本信息
4. 输入邀请码（或等待审核）
5. 提交注册
6. [需审核] 管理员审核通过后激活
7. [有邀请码] 立即激活
8. 发送确认邮件
9. 登录使用
```

### 管理员创建（命令行）
```bash
# 通过Django命令创建
python manage.py createsuperuser

# 或在Shell中创建
from django.contrib.auth.models import User
user = User.objects.create_superuser('admin', 'admin@example.com', 'password')
```

## 📊 个人中心功能

### 统计信息
- 通过题目数
- 总提交数
- AC率
- 做题日历（热力图）
- 题目难度分布
- 标签分布

### 做题记录
- 最近提交
- 通过的题目列表
- 尝试中的题目
- 收藏的题目（可选）

### 个人设置
- 修改个人信息
- 修改密码
- 上传头像
- 邮箱验证
- 隐私设置

## 🚀 开发优先级

### Phase 1: 基础认证（Week 1）
```
优先级: ⭐⭐⭐⭐⭐

- 扩展User模型（UserProfile）
- 注册功能（学生）
- 登录功能
- 登出功能
- 个人中心（基础信息）
```

### Phase 2: 角色权限（Week 1-2）
```
优先级: ⭐⭐⭐⭐

- 用户类型区分
- 权限装饰器
- 老师注册和审核
- 权限控制
```

### Phase 3: 班级系统（Week 2）
```
优先级: ⭐⭐⭐

- 班级模型
- 班级管理（老师）
- 学生加入班级
- 班级统计
```

### Phase 4: 高级功能（Week 3）
```
优先级: ⭐⭐

- 密码重置
- 邮件验证
- 登录日志
- 做题统计可视化
```

## 📝 技术选型

### 认证方式
```
推荐: Django REST Framework Token认证 + Session

优点:
- 简单易用
- 前后端分离友好
- Django原生支持
```

### 依赖包
```python
# requirements.txt 需要添加
djangorestframework-simplejwt==5.3.0  # JWT认证（可选）
django-cors-headers==4.3.1            # 已安装
Pillow==10.1.0                        # 已安装（头像上传）
```

## 🎯 下一步行动

准备开始开发了吗？我可以帮你：

1. ✅ 创建users应用
2. ✅ 创建UserProfile模型
3. ✅ 创建Class模型
4. ✅ 创建注册/登录视图
5. ✅ 创建注册/登录页面
6. ✅ 创建个人中心页面
7. ✅ 实现权限控制

---

**告诉我：现在开始创建用户认证系统吗？** 🚀
