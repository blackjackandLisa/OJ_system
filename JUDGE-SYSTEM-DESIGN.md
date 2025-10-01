# 提交与判题系统设计文档

## 📋 目录
- [1. 系统概述](#1-系统概述)
- [2. 需求分析](#2-需求分析)
- [3. 系统架构](#3-系统架构)
- [4. 数据库设计](#4-数据库设计)
- [5. 安全沙箱设计](#5-安全沙箱设计)
- [6. 判题流程](#6-判题流程)
- [7. API设计](#7-api设计)
- [8. 技术选型](#8-技术选型)

---

## 1. 系统概述

### 1.1 目标
构建一个安全、高效、可扩展的代码提交与判题系统，支持多语言、多测试用例、实时反馈。

### 1.2 核心功能
- ✅ 代码提交与存储
- ✅ 多语言编译运行
- ✅ 安全沙箱隔离
- ✅ 测试用例批量测试
- ✅ 资源限制（CPU、内存、时间）
- ✅ 实时判题状态推送
- ✅ 提交历史记录
- ✅ 统计分析

### 1.3 支持的语言（第一期）
| 语言 | 版本 | 编译器/解释器 |
|------|------|--------------|
| C | C11 | GCC 11+ |
| C++ | C++17 | G++ 11+ |
| Python | 3.10+ | CPython |
| Java | 17 | OpenJDK 17 |

---

## 2. 需求分析

### 2.1 功能需求

#### F1: 代码提交
**需求ID**: FR-001  
**描述**: 用户可以提交代码到指定题目  
**优先级**: P0（必须）

**详细要求**：
- 支持选择编程语言
- 支持代码编辑器（语法高亮、自动补全）
- 提交前验证（代码长度、格式）
- 支持多次提交
- 记录提交时间、状态

**前置条件**：
- 用户已登录
- 题目状态为"已发布"

**验收标准**：
- [ ] 提交成功后返回submission_id
- [ ] 未登录用户提交跳转登录
- [ ] 代码超过100KB提示错误
- [ ] 提交立即进入判题队列

---

#### F2: 代码编译
**需求ID**: FR-002  
**描述**: 系统自动编译用户提交的代码  
**优先级**: P0（必须）

**详细要求**：
- 支持C/C++/Java编译
- 编译错误信息捕获
- 编译超时限制（30秒）
- 编译产物安全存储

**编译配置**：
```bash
# C
gcc -std=c11 -O2 -Wall -lm code.c -o main

# C++
g++ -std=c++17 -O2 -Wall code.cpp -o main

# Java
javac Main.java

# Python (无需编译)
python3 -m py_compile code.py
```

**验收标准**：
- [ ] 编译成功生成可执行文件
- [ ] 编译错误返回错误信息
- [ ] 编译超时返回"Compile Time Limit Exceeded"
- [ ] 编译产物隔离存储

---

#### F3: 代码运行与测试
**需求ID**: FR-003  
**描述**: 在安全沙箱中运行代码并测试  
**优先级**: P0（必须）

**详细要求**：
- 每个测试用例独立运行
- 严格的时间和内存限制
- 标准输入输出重定向
- 运行时错误捕获
- 输出结果比对

**测试流程**：
```
1. 加载测试用例
2. 创建沙箱容器
3. 重定向stdin从测试输入
4. 启动程序，设置资源限制
5. 捕获stdout和stderr
6. 比对输出与预期答案
7. 返回判题结果
8. 销毁容器
```

**验收标准**：
- [ ] 时间限制精确到毫秒
- [ ] 内存限制精确到KB
- [ ] 输出比对支持忽略行尾空格
- [ ] 支持Special Judge

---

#### F4: 判题结果判定
**需求ID**: FR-004  
**描述**: 根据测试结果给出最终判定  
**优先级**: P0（必须）

**判题状态**：
| 状态代码 | 状态名 | 说明 |
|---------|--------|------|
| `AC` | Accepted | 完全正确 |
| `WA` | Wrong Answer | 答案错误 |
| `TLE` | Time Limit Exceeded | 运行超时 |
| `MLE` | Memory Limit Exceeded | 内存超限 |
| `RE` | Runtime Error | 运行时错误 |
| `CE` | Compile Error | 编译错误 |
| `SE` | System Error | 系统错误 |
| `PE` | Presentation Error | 格式错误 |
| `OLE` | Output Limit Exceeded | 输出超限 |

**判定规则**：
```python
if 编译失败:
    return CE
    
for 每个测试用例:
    if 运行超时:
        return TLE
    if 内存超限:
        return MLE
    if 运行时错误:
        return RE
    if 输出超限:
        return OLE
    if 答案错误:
        return WA / PE  # 根据格式判断

if 所有测试用例通过:
    return AC
```

**验收标准**：
- [ ] 状态判定准确
- [ ] 返回错误的测试用例编号
- [ ] 返回详细的错误信息
- [ ] 记录运行时间和内存

---

#### F5: 提交历史记录
**需求ID**: FR-005  
**描述**: 记录和展示用户的所有提交  
**优先级**: P1（重要）

**详细要求**：
- 记录完整的提交信息
- 支持按题目、状态、时间筛选
- 支持查看历史代码
- 支持重新提交
- 统计分析（AC率、平均时间）

**展示信息**：
- 提交ID、题目、语言
- 判题状态、得分
- 运行时间、内存消耗
- 提交时间
- 代码长度

**验收标准**：
- [ ] 所有提交持久化存储
- [ ] 查询性能<100ms
- [ ] 支持代码高亮显示
- [ ] 老师可以查看学生提交

---

### 2.2 非功能需求

#### NF1: 安全性
**需求ID**: NFR-001  
**优先级**: P0（必须）

**要求**：
- ✅ 代码沙箱完全隔离
- ✅ 禁止网络访问
- ✅ 禁止文件系统访问（除必要目录）
- ✅ 限制系统调用
- ✅ 防止fork炸弹
- ✅ 防止恶意代码

**安全措施**：
1. **容器隔离**: 使用Docker容器
2. **资源限制**: cgroups限制CPU/内存
3. **系统调用过滤**: Seccomp-BPF白名单
4. **网络隔离**: 禁用网络命名空间
5. **文件系统**: 只读挂载，tmpfs临时目录
6. **用户权限**: 非root用户运行
7. **超时保护**: 强制kill超时进程

---

#### NF2: 性能
**需求ID**: NFR-002  
**优先级**: P0（必须）

**指标**：
| 指标 | 目标值 | 备注 |
|------|--------|------|
| 判题响应时间 | < 2s | 不含程序运行时间 |
| 并发处理能力 | 100+ | 同时判题数 |
| 队列处理延迟 | < 1s | 提交到开始判题 |
| 容器启动时间 | < 500ms | 沙箱创建时间 |
| 数据库查询 | < 100ms | 单次查询 |

**优化策略**：
- 容器池预热
- Redis任务队列
- 测试用例缓存
- 异步判题
- 结果推送（WebSocket）

---

#### NF3: 可扩展性
**需求ID**: NFR-003  
**优先级**: P1（重要）

**要求**：
- ✅ 支持水平扩展（多判题节点）
- ✅ 支持动态添加语言
- ✅ 支持插件化特判（Special Judge）
- ✅ 支持分布式部署
- ✅ 支持负载均衡

---

#### NF4: 可维护性
**需求ID**: NFR-004  
**优先级**: P1（重要）

**要求**：
- ✅ 完整的日志系统
- ✅ 监控告警（Prometheus）
- ✅ 错误追踪
- ✅ 健康检查
- ✅ 自动重启

---

## 3. 系统架构

### 3.1 整体架构

```
┌─────────────┐
│   浏览器    │
│  (前端UI)   │
└──────┬──────┘
       │ HTTPS
       │
┌──────▼──────────────────────────────────┐
│          Nginx (反向代理)                │
└──────┬──────────────────────────────────┘
       │
┌──────▼──────────────────────────────────┐
│       Django (Web服务器)                 │
│  - 用户管理  - 题目管理                  │
│  - API接口   - 权限控制                  │
└──────┬──────────────────────────────────┘
       │
       ├─────────────┬─────────────┐
       │             │             │
┌──────▼──────┐ ┌───▼───────┐ ┌──▼────────┐
│ PostgreSQL  │ │  Redis    │ │  判题队列  │
│  (主数据库) │ │ (缓存/队列)│ │  (Celery) │
└─────────────┘ └───────────┘ └──┬────────┘
                                  │
                    ┌─────────────┴─────────────┐
                    │                           │
             ┌──────▼──────┐           ┌───────▼──────┐
             │ 判题Worker-1 │           │ 判题Worker-N │
             │  (Python)    │           │  (Python)    │
             └──────┬───────┘           └───────┬──────┘
                    │                           │
             ┌──────▼──────────┐         ┌──────▼──────────┐
             │  Docker沙箱-1   │         │  Docker沙箱-N   │
             │   (代码执行)    │         │   (代码执行)    │
             └─────────────────┘         └─────────────────┘
```

### 3.2 模块划分

#### 3.2.1 Web服务模块 (Django)
**职责**：
- 接收用户提交
- 用户认证与权限
- 题目管理
- 提交历史查询
- 统计分析

**技术栈**：
- Django 4.2
- Django REST Framework
- PostgreSQL

---

#### 3.2.2 判题调度模块 (Celery)
**职责**：
- 接收判题任务
- 任务队列管理
- 负载均衡
- 任务优先级
- 失败重试

**技术栈**：
- Celery 5.3
- Redis (消息队列)
- RabbitMQ (可选)

---

#### 3.2.3 判题执行模块 (Judge Worker)
**职责**：
- 代码编译
- 测试用例执行
- 结果判定
- 资源监控
- 沙箱管理

**技术栈**：
- Python 3.10+
- Docker SDK
- Linux cgroups

---

#### 3.2.4 安全沙箱模块 (Docker Sandbox)
**职责**：
- 代码隔离执行
- 资源限制
- 系统调用过滤
- 安全防护

**技术栈**：
- Docker
- Seccomp
- AppArmor/SELinux
- cgroups v2

---

## 4. 数据库设计

### 4.1 Submission (提交记录)

```python
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
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    problem = models.ForeignKey(Problem, on_delete=models.CASCADE)
    
    # 代码信息
    language = models.CharField(max_length=20)      # c/cpp/python/java
    code = models.TextField()                        # 源代码
    code_length = models.IntegerField()              # 代码长度
    
    # 判题信息
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    result = models.CharField(max_length=10, choices=RESULT_CHOICES, null=True)
    
    # 运行结果
    score = models.IntegerField(default=0)           # 得分
    total_score = models.IntegerField()              # 总分
    pass_rate = models.FloatField(default=0.0)       # 通过率
    
    time_used = models.IntegerField(null=True)       # 运行时间(ms)
    memory_used = models.IntegerField(null=True)     # 内存占用(KB)
    
    # 测试用例信息
    test_cases_passed = models.IntegerField(default=0)    # 通过的测试用例数
    test_cases_total = models.IntegerField()              # 总测试用例数
    
    # 错误信息
    compile_error = models.TextField(blank=True)     # 编译错误信息
    runtime_error = models.TextField(blank=True)     # 运行时错误信息
    error_testcase = models.IntegerField(null=True)  # 出错的测试用例编号
    
    # 判题详情（JSON）
    judge_detail = models.JSONField(null=True, blank=True)  # 每个测试用例的详细结果
    
    # IP和标识
    ip_address = models.GenericIPAddressField()
    user_agent = models.TextField(blank=True)
    
    # 时间信息
    created_at = models.DateTimeField(auto_now_add=True)  # 提交时间
    judged_at = models.DateTimeField(null=True)           # 判题完成时间
    
    # 其他
    is_public = models.BooleanField(default=True)    # 是否公开（用于比赛）
    shared = models.BooleanField(default=False)      # 是否分享
    
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
```

**judge_detail 字段示例**：
```json
{
  "test_cases": [
    {
      "id": 1,
      "result": "AC",
      "time": 15,
      "memory": 2048,
      "output": "..."
    },
    {
      "id": 2,
      "result": "WA",
      "time": 10,
      "memory": 2048,
      "output": "...",
      "expected": "..."
    }
  ],
  "compile_output": "",
  "system_info": {
    "judge_server": "worker-1",
    "sandbox_id": "abc123"
  }
}
```

---

### 4.2 JudgeServer (判题服务器)

```python
class JudgeServer(models.Model):
    """判题服务器"""
    
    hostname = models.CharField(max_length=100, unique=True)
    ip_address = models.GenericIPAddressField()
    port = models.IntegerField(default=8080)
    
    # 状态
    is_active = models.BooleanField(default=True)
    is_available = models.BooleanField(default=True)
    
    # 负载信息
    cpu_usage = models.FloatField(default=0.0)      # CPU使用率
    memory_usage = models.FloatField(default=0.0)   # 内存使用率
    task_count = models.IntegerField(default=0)     # 当前任务数
    max_tasks = models.IntegerField(default=10)     # 最大任务数
    
    # 统计
    total_judged = models.IntegerField(default=0)   # 总判题数
    
    # 时间
    created_at = models.DateTimeField(auto_now_add=True)
    last_heartbeat = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'judge_servers'
```

---

### 4.3 Language (编程语言配置)

```python
class Language(models.Model):
    """编程语言配置"""
    
    name = models.CharField(max_length=50, unique=True)  # python/cpp/java
    display_name = models.CharField(max_length=100)       # Python 3.10
    
    # 编译配置
    compile_command = models.TextField(blank=True)        # 编译命令
    compile_timeout = models.IntegerField(default=30)     # 编译超时(s)
    
    # 运行配置
    run_command = models.TextField()                      # 运行命令
    
    # 代码模板
    template = models.TextField(blank=True)
    
    # 沙箱配置
    docker_image = models.CharField(max_length=200)       # Docker镜像
    
    # 状态
    is_active = models.BooleanField(default=True)
    order = models.IntegerField(default=0)
    
    class Meta:
        db_table = 'languages'
        ordering = ['order', 'name']
```

**示例配置**：
```python
# Python
Language.objects.create(
    name='python',
    display_name='Python 3.10',
    compile_command='python3 -m py_compile {src}',
    run_command='python3 {src}',
    docker_image='python:3.10-slim',
    template='# Write your code here\n\n'
)

# C++
Language.objects.create(
    name='cpp',
    display_name='C++ 17',
    compile_command='g++ -std=c++17 -O2 -Wall {src} -o {exe}',
    run_command='{exe}',
    docker_image='gcc:11',
    template='#include <iostream>\nusing namespace std;\n\nint main() {\n    // Your code here\n    return 0;\n}\n'
)
```

---

## 5. 安全沙箱设计

### 5.1 Docker沙箱架构

```
┌─────────────────────────────────────────────┐
│           Host System (Linux)               │
│                                             │
│  ┌───────────────────────────────────────┐ │
│  │   Docker Container (Sandbox)          │ │
│  │                                       │ │
│  │  ┌─────────────────────────────────┐ │ │
│  │  │  User Code Process              │ │ │
│  │  │  - Non-root user (uid: 10001)   │ │ │
│  │  │  - Limited syscalls (seccomp)   │ │ │
│  │  │  - CPU limit (cgroups)          │ │ │
│  │  │  - Memory limit (cgroups)       │ │ │
│  │  │  - No network                   │ │ │
│  │  │  - Read-only filesystem         │ │ │
│  │  └─────────────────────────────────┘ │ │
│  │                                       │ │
│  │  Mounts:                              │ │
│  │  - /workspace (tmpfs, rw, 10MB)      │ │
│  │  - /usr/bin (ro)                     │ │
│  │  - /lib (ro)                         │ │
│  └───────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

### 5.2 Dockerfile 示例

```dockerfile
# C/C++ 判题镜像
FROM gcc:11-slim

# 创建判题用户
RUN useradd -u 10001 -m -s /bin/bash judger && \
    mkdir -p /workspace && \
    chown judger:judger /workspace

# 安装必要工具
RUN apt-get update && apt-get install -y --no-install-recommends \
    time \
    && rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /workspace

# 切换到非特权用户
USER judger

# 默认命令
CMD ["/bin/bash"]
```

### 5.3 Seccomp 配置

```json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "architectures": ["SCMP_ARCH_X86_64"],
  "syscalls": [
    {
      "names": [
        "read", "write", "open", "close", "stat", "fstat",
        "lseek", "mmap", "mprotect", "munmap", "brk",
        "rt_sigaction", "rt_sigprocmask", "rt_sigreturn",
        "access", "pipe", "select", "sched_yield",
        "dup", "dup2", "getpid", "clone", "fork", "execve",
        "exit", "exit_group", "wait4", "fcntl", "getcwd",
        "getdents", "readlink", "arch_prctl", "set_tid_address",
        "set_robust_list", "futex", "getrlimit", "getrusage"
      ],
      "action": "SCMP_ACT_ALLOW"
    }
  ]
}
```

### 5.4 资源限制配置

```python
# Docker容器资源限制
container_config = {
    'image': 'oj-judge-cpp:latest',
    'name': f'judge_{submission_id}',
    'detach': True,
    'auto_remove': True,
    'network_mode': 'none',  # 禁用网络
    'mem_limit': f'{memory_limit}m',  # 内存限制
    'memswap_limit': f'{memory_limit}m',  # 禁用swap
    'cpu_period': 100000,  # CPU周期
    'cpu_quota': 100000,   # CPU配额 (100% = 1核)
    'pids_limit': 50,      # 进程数限制
    'read_only': True,     # 只读文件系统
    'tmpfs': {
        '/workspace': f'size={workspace_size}m,uid=10001'
    },
    'volumes': {
        '/etc/localtime': {'bind': '/etc/localtime', 'mode': 'ro'}
    },
    'security_opt': ['no-new-privileges'],
    'cap_drop': ['ALL'],   # 删除所有capabilities
}
```

### 5.5 安全检查清单

- [x] **容器隔离**: 独立的命名空间
- [x] **非root用户**: uid 10001
- [x] **资源限制**: CPU/内存/进程数/文件大小
- [x] **网络隔离**: network_mode=none
- [x] **文件系统**: 只读 + tmpfs工作目录
- [x] **系统调用**: Seccomp白名单
- [x] **Capabilities**: 删除所有特权
- [x] **超时保护**: 强制kill
- [x] **输出限制**: 防止输出炸弹
- [x] **进程限制**: 防止fork炸弹

---

## 6. 判题流程

### 6.1 完整流程图

```
┌─────────┐
│用户提交代码│
└────┬────┘
     │
     ▼
┌─────────────────┐
│1. 提交验证       │
│ - 登录检查      │
│ - 代码长度      │
│ - 语言检查      │
└────┬────────────┘
     │
     ▼
┌─────────────────┐
│2. 创建Submission │
│ - 保存到数据库   │
│ - 状态: pending  │
└────┬────────────┘
     │
     ▼
┌─────────────────┐
│3. 加入判题队列   │
│ - Celery任务    │
│ - 优先级排序    │
└────┬────────────┘
     │
     ▼
┌─────────────────┐
│4. 判题Worker接收 │
│ - 更新状态:judging│
└────┬────────────┘
     │
     ▼
┌─────────────────┐
│5. 准备环境       │
│ - 创建工作目录   │
│ - 写入源代码    │
│ - 加载测试用例   │
└────┬────────────┘
     │
     ▼
┌─────────────────┐
│6. 编译代码       │
│ - 启动沙箱      │
│ - 执行编译      │
│ - 捕获错误      │
└────┬────────────┘
     │
     ├─ 编译失败 ─► CE ─┐
     │                  │
     ▼                  │
┌─────────────────┐     │
│7. 遍历测试用例   │     │
│ For each test:  │     │
│                 │     │
│ 7.1 准备输入    │     │
│ 7.2 运行程序    │     │
│ 7.3 捕获输出    │     │
│ 7.4 比对答案    │     │
│ 7.5 记录结果    │     │
└────┬────────────┘     │
     │                  │
     ▼                  │
┌─────────────────┐     │
│8. 汇总判题结果   │     │
│ - 计算得分      │ ◄───┘
│ - 确定状态      │
│ - 统计资源      │
└────┬────────────┘
     │
     ▼
┌─────────────────┐
│9. 更新数据库     │
│ - 提交结果      │
│ - 用户统计      │
│ - 题目统计      │
└────┬────────────┘
     │
     ▼
┌─────────────────┐
│10. 推送结果      │
│ - WebSocket通知 │
│ - 邮件提醒(可选)│
└─────────────────┘
```

### 6.2 编译阶段

```python
def compile_code(submission, source_file, output_file):
    """编译代码"""
    
    # 获取语言配置
    language = Language.objects.get(name=submission.language)
    
    # 构建编译命令
    compile_cmd = language.compile_command.format(
        src=source_file,
        exe=output_file
    )
    
    # 创建沙箱容器
    container = docker_client.containers.run(
        image=language.docker_image,
        command=compile_cmd,
        detach=True,
        **container_config
    )
    
    try:
        # 等待编译完成（超时30秒）
        result = container.wait(timeout=language.compile_timeout)
        
        # 获取编译输出
        logs = container.logs().decode('utf-8')
        
        if result['StatusCode'] == 0:
            return {'success': True}
        else:
            return {
                'success': False,
                'error': logs,
                'result': 'CE'
            }
    
    except docker.errors.ContainerError as e:
        return {
            'success': False,
            'error': str(e),
            'result': 'CE'
        }
    
    except Exception as e:
        return {
            'success': False,
            'error': str(e),
            'result': 'SE'
        }
    
    finally:
        # 清理容器
        try:
            container.remove(force=True)
        except:
            pass
```

### 6.3 运行阶段

```python
def run_testcase(submission, executable, testcase):
    """运行单个测试用例"""
    
    # 获取时间和内存限制
    time_limit = testcase.get_time_limit()  # ms
    memory_limit = testcase.get_memory_limit()  # MB
    
    # 创建沙箱容器
    container = docker_client.containers.run(
        image='oj-judge-runtime:latest',
        command=f'/usr/bin/time -v {executable}',
        stdin_open=True,
        detach=True,
        mem_limit=f'{memory_limit}m',
        cpu_quota=int(time_limit * 1000),  # 转换为微秒
        **security_config
    )
    
    try:
        # 输入测试数据
        socket = container.attach_socket(
            params={'stdin': 1, 'stream': 1}
        )
        socket._sock.sendall(testcase.input_data.encode('utf-8'))
        socket.close()
        
        # 等待运行完成
        start_time = time.time()
        result = container.wait(timeout=time_limit / 1000 + 1)
        end_time = time.time()
        
        actual_time = int((end_time - start_time) * 1000)  # ms
        
        # 获取输出
        stdout = container.logs(stdout=True, stderr=False).decode('utf-8')
        stderr = container.logs(stdout=False, stderr=True).decode('utf-8')
        
        # 获取资源使用（从/usr/bin/time输出）
        memory_used = parse_memory_usage(stderr)
        
        # 检查结果
        if result['StatusCode'] != 0:
            return {
                'result': 'RE',
                'error': stderr,
                'time': actual_time,
                'memory': memory_used
            }
        
        # 比对输出
        if compare_output(stdout, testcase.output_data):
            return {
                'result': 'AC',
                'time': actual_time,
                'memory': memory_used,
                'output': stdout
            }
        else:
            return {
                'result': 'WA',
                'time': actual_time,
                'memory': memory_used,
                'output': stdout,
                'expected': testcase.output_data
            }
    
    except docker.errors.ContainerError:
        return {'result': 'RE', 'error': 'Container error'}
    
    except TimeoutError:
        return {'result': 'TLE'}
    
    finally:
        container.remove(force=True)
```

### 6.4 输出比对

```python
def compare_output(user_output, expected_output):
    """比对输出"""
    
    # 规范化输出
    def normalize(text):
        lines = text.strip().split('\n')
        # 去除每行末尾空格
        lines = [line.rstrip() for line in lines]
        # 去除空行
        lines = [line for line in lines if line]
        return '\n'.join(lines)
    
    user_norm = normalize(user_output)
    expected_norm = normalize(expected_output)
    
    return user_norm == expected_norm
```

---

## 7. API设计

### 7.1 提交代码

```http
POST /api/submissions/
Authorization: Bearer <token>
Content-Type: application/json

{
  "problem_id": 1,
  "language": "python",
  "code": "# Python code here\nprint('Hello')"
}
```

**响应**：
```json
{
  "id": 12345,
  "status": "pending",
  "created_at": "2024-10-01T12:00:00Z",
  "message": "提交成功，正在判题..."
}
```

### 7.2 查询提交状态

```http
GET /api/submissions/12345/
Authorization: Bearer <token>
```

**响应**：
```json
{
  "id": 12345,
  "user": "student01",
  "problem": {
    "id": 1,
    "title": "A+B Problem"
  },
  "language": "python",
  "status": "finished",
  "result": "AC",
  "score": 100,
  "time_used": 15,
  "memory_used": 2048,
  "test_cases_passed": 10,
  "test_cases_total": 10,
  "created_at": "2024-10-01T12:00:00Z",
  "judged_at": "2024-10-01T12:00:02Z"
}
```

### 7.3 获取提交列表

```http
GET /api/submissions/?problem=1&user=me&result=AC
Authorization: Bearer <token>
```

### 7.4 查看代码

```http
GET /api/submissions/12345/code/
Authorization: Bearer <token>
```

**响应**：
```json
{
  "code": "# Python code\nprint('Hello')",
  "language": "python",
  "created_at": "2024-10-01T12:00:00Z"
}
```

### 7.5 获取判题详情

```http
GET /api/submissions/12345/detail/
Authorization: Bearer <token>
```

**响应**：
```json
{
  "test_cases": [
    {
      "id": 1,
      "result": "AC",
      "time": 15,
      "memory": 2048
    },
    {
      "id": 2,
      "result": "AC",
      "time": 12,
      "memory": 2048
    }
  ],
  "compile_output": "",
  "total_time": 27,
  "max_memory": 2048
}
```

---

## 8. 技术选型

### 8.1 技术栈总览

| 组件 | 技术 | 版本 | 说明 |
|------|------|------|------|
| Web框架 | Django | 4.2+ | 主应用框架 |
| API框架 | DRF | 3.14+ | RESTful API |
| 数据库 | PostgreSQL | 14+ | 主数据库 |
| 缓存/队列 | Redis | 7+ | 缓存和消息队列 |
| 任务队列 | Celery | 5.3+ | 异步任务 |
| 容器 | Docker | 20+ | 代码沙箱 |
| 反向代理 | Nginx | 1.24+ | 负载均衡 |
| 监控 | Prometheus | 2.45+ | 系统监控 |
| 日志 | ELK Stack | 8+ | 日志分析 |

### 8.2 Python依赖

```txt
# requirements-judge.txt

# Core
django==4.2.5
djangorestframework==3.14.0
celery==5.3.4
redis==5.0.0

# Docker
docker==6.1.3

# 监控
prometheus-client==0.18.0

# 工具
python-decouple==3.8
psycopg2-binary==2.9.9
```

### 8.3 Docker镜像

```bash
# 判题镜像
oj-judge-cpp:latest      # C/C++
oj-judge-python:latest   # Python
oj-judge-java:latest     # Java
```

---

## 9. 实施计划

### Phase 1: 基础判题（第1-2周）
- [x] 数据库模型设计
- [ ] Submission模型实现
- [ ] 基本API接口
- [ ] 简单沙箱（Docker基础版）
- [ ] Python单语言支持
- [ ] 同步判题（不用队列）

### Phase 2: 安全加固（第3周）
- [ ] Seccomp配置
- [ ] 资源限制完善
- [ ] 安全测试
- [ ] C/C++语言支持

### Phase 3: 异步队列（第4周）
- [ ] Celery集成
- [ ] Redis队列
- [ ] 任务调度
- [ ] 状态推送

### Phase 4: 完善功能（第5-6周）
- [ ] Java语言支持
- [ ] Special Judge
- [ ] 提交历史UI
- [ ] 统计分析
- [ ] 性能优化

### Phase 5: 生产部署（第7周）
- [ ] 监控告警
- [ ] 日志系统
- [ ] 负载测试
- [ ] 文档完善

---

## 10. 安全考虑

### 10.1 防止恶意代码

**场景1: Fork炸弹**
```c
// 恶意代码
while(1) fork();
```

**防护**：
- `pids_limit`: 50（限制进程数）
- 检测fork频率

**场景2: 无限循环**
```python
# 恶意代码
while True: pass
```

**防护**：
- CPU时间限制
- 墙钟时间限制
- 强制kill

**场景3: 内存炸弹**
```python
# 恶意代码
a = [0] * (10**9)
```

**防护**：
- cgroups内存限制
- OOM Killer

**场景4: 输出炸弹**
```python
# 恶意代码
while True: print('x' * 10000)
```

**防护**：
- 输出大小限制（64KB）
- 管道缓冲区限制

**场景5: 文件访问**
```python
# 恶意代码
open('/etc/passwd', 'r')
```

**防护**：
- 只读文件系统
- tmpfs工作目录
- Seccomp过滤open系统调用

---

## 11. 监控指标

### 11.1 系统指标

```python
# Prometheus指标

# 判题队列长度
judge_queue_length

# 判题速率（个/秒）
judge_rate

# 判题延迟（秒）
judge_latency_seconds

# 各状态提交数
submissions_by_result{result="AC"}
submissions_by_result{result="WA"}

# 判题服务器负载
judge_server_cpu_usage{server="worker-1"}
judge_server_memory_usage{server="worker-1"}

# 容器数量
active_containers_count
```

### 11.2 告警规则

```yaml
# alerts.yml

- alert: JudgeQueueTooLong
  expr: judge_queue_length > 100
  for: 5m
  annotations:
    summary: "判题队列过长"
    
- alert: JudgeServerDown
  expr: up{job="judge-server"} == 0
  for: 1m
  annotations:
    summary: "判题服务器下线"
```

---

## 12. 总结

这个设计文档涵盖了：

✅ **完整的需求分析**（功能+非功能）  
✅ **清晰的系统架构**（分层+模块）  
✅ **详细的数据库设计**（3个核心表）  
✅ **安全的沙箱方案**（Docker + Seccomp + cgroups）  
✅ **完整的判题流程**（10个步骤）  
✅ **RESTful API设计**（5个核心接口）  
✅ **技术选型和实施计划**  

**下一步**：根据这个设计开始实现代码！

---

**文档版本**: v1.0  
**创建日期**: 2024-10-01  
**作者**: OJ系统开发团队
