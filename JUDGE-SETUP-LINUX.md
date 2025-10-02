# 判题系统设置指南 (Linux服务器)

## 📋 系统要求

- **操作系统**: Ubuntu 20.04+ / Debian 10+ / CentOS 8+
- **内存**: 最低 4GB，推荐 8GB+
- **CPU**: 最低 2核，推荐 4核+
- **磁盘**: 最低 20GB 可用空间
- **Python**: 3.8+
- **Docker**: 20.10+

---

## 🚀 快速开始

### 方法1: 一键自动化脚本（推荐）

```bash
# 1. 确保有执行权限
chmod +x setup-judge-system.sh

# 2. 执行自动化脚本
./setup-judge-system.sh

# 脚本会自动完成所有设置步骤
```

### 方法2: 手动逐步设置

按照下面的详细步骤操作。

---

## 📝 详细设置步骤

### Step 1: 安装Docker

#### Ubuntu/Debian

```bash
# 更新包索引
sudo apt-get update

# 安装依赖
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# 添加Docker官方GPG密钥
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# 设置Docker仓库
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 安装Docker Engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# 启动Docker
sudo systemctl start docker
sudo systemctl enable docker

# 添加当前用户到docker组（避免每次sudo）
sudo usermod -aG docker $USER

# ⚠️ 注销后重新登录使组权限生效
# 或者运行: newgrp docker
```

#### CentOS/RHEL

```bash
# 安装依赖
sudo yum install -y yum-utils

# 添加Docker仓库
sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

# 安装Docker
sudo yum install -y docker-ce docker-ce-cli containerd.io

# 启动Docker
sudo systemctl start docker
sudo systemctl enable docker

# 添加用户到docker组
sudo usermod -aG docker $USER
```

#### 验证Docker安装

```bash
# 检查版本
docker --version
# 输出: Docker version 24.x.x, build xxxxx

# 检查服务状态
docker ps
# 输出: CONTAINER ID   IMAGE   COMMAND   ...（空列表也正常）

# 测试运行容器
docker run hello-world
# 如果看到 "Hello from Docker!" 说明安装成功
```

---

### Step 2: 安装Python依赖

```bash
# 确保在项目目录
cd /path/to/OJ_system

# 安装docker-py库（判题核心依赖）
pip3 install docker==7.0.0

# 或者使用requirements.txt
pip3 install -r requirements.txt

# 验证安装
python3 -c "import docker; print('Docker SDK version:', docker.__version__)"
```

---

### Step 3: 数据库迁移

```bash
# 创建迁移文件
python3 manage.py makemigrations

# 执行迁移
python3 manage.py migrate

# 验证表已创建
python3 manage.py dbshell
> .tables
# 应该看到: problems, test_cases, submissions, languages 等表
> .quit
```

---

### Step 4: 构建判题Docker镜像

```bash
# 进入镜像目录
cd docker/judge

# 构建Python镜像
docker build -t oj-judge-python:latest -f Dockerfile.python .

# 构建C++镜像
docker build -t oj-judge-cpp:latest -f Dockerfile.cpp .

# 返回项目根目录
cd ../..

# 验证镜像已创建
docker images | grep oj-judge
```

**预期输出**:
```
oj-judge-python   latest   abc123def456   2 minutes ago   150MB
oj-judge-cpp      latest   def456abc789   1 minute ago    500MB
```

**测试镜像**:
```bash
# 测试Python镜像
docker run --rm oj-judge-python:latest python3 --version
# 输出: Python 3.10.x

# 测试C++镜像
docker run --rm oj-judge-cpp:latest g++ --version
# 输出: g++ (GCC) 11.x.x

# 测试运行代码
docker run --rm oj-judge-python:latest python3 -c "print('Hello from Docker!')"
# 输出: Hello from Docker!
```

---

### Step 5: 初始化语言配置

```bash
# 运行初始化命令
python3 manage.py init_languages

# 验证
python3 manage.py shell -c "from apps.judge.models import Language; print('Languages:', Language.objects.count())"
# 输出: Languages: 2
```

---

### Step 6: 创建测试题目和用例

#### 方法1: 使用Django Shell

```bash
python3 manage.py shell
```

在Shell中执行:
```python
from apps.problems.models import Problem, TestCase

# 创建测试题目
problem = Problem.objects.create(
    title='A+B Problem',
    description='输入两个整数a和b，输出它们的和',
    input_format='一行两个整数，用空格分隔',
    output_format='一个整数，表示a+b的值',
    time_limit=1000,
    memory_limit=256,
    difficulty='easy',
    status='published'
)

# 创建测试用例
test_cases = [
    {'input': '1 2\n', 'output': '3\n'},
    {'input': '10 20\n', 'output': '30\n'},
    {'input': '-5 5\n', 'output': '0\n'},
]

for idx, tc in enumerate(test_cases, 1):
    TestCase.objects.create(
        problem=problem,
        input_data=tc['input'],
        output_data=tc['output'],
        order=idx
    )

print(f'✅ 题目创建成功: {problem.title} (ID: {problem.id})')
print(f'✅ 测试用例: {problem.test_cases.count()} 个')

# 退出
exit()
```

#### 方法2: 使用脚本

```bash
# 创建脚本文件
cat > setup_test_data.py << 'EOF'
from apps.problems.models import Problem, TestCase

if Problem.objects.filter(title='A+B Problem').exists():
    print('测试题目已存在')
else:
    problem = Problem.objects.create(
        title='A+B Problem',
        description='输入两个整数a和b，输出它们的和',
        input_format='一行两个整数，用空格分隔',
        output_format='一个整数，表示a+b的值',
        time_limit=1000,
        memory_limit=256,
        difficulty='easy',
        status='published'
    )
    
    test_cases = [
        {'input': '1 2\n', 'output': '3\n'},
        {'input': '10 20\n', 'output': '30\n'},
        {'input': '-5 5\n', 'output': '0\n'},
    ]
    
    for idx, tc in enumerate(test_cases, 1):
        TestCase.objects.create(
            problem=problem,
            input_data=tc['input'],
            output_data=tc['output'],
            order=idx
        )
    
    print(f'✅ 题目创建成功: {problem.title} (ID: {problem.id})')
    print(f'✅ 测试用例: {problem.test_cases.count()} 个')
EOF

# 执行脚本
python3 manage.py shell < setup_test_data.py
```

---

### Step 7: 启动服务并测试

#### 开发环境

```bash
# 启动Django开发服务器
python3 manage.py runserver 0.0.0.0:8000
```

#### 生产环境（使用Docker Compose）

```bash
# 启动所有服务
docker-compose up -d

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f web
```

#### 测试判题功能

**1. 访问提交页面**:
```
http://your-server-ip:8000/problems/1/submit/
```

**2. 提交测试代码（Python）**:
```python
a, b = map(int, input().split())
print(a + b)
```

**3. 预期结果**: `AC (Accepted)` ✅

---

## 🔍 问题排查

### 问题1: Docker权限不足

**错误信息**:
```
permission denied while trying to connect to the Docker daemon socket
```

**解决方案**:
```bash
# 添加用户到docker组
sudo usermod -aG docker $USER

# 注销重新登录，或者运行
newgrp docker

# 验证
docker ps
```

### 问题2: 判题一直不完成

**排查步骤**:

```bash
# 1. 检查Docker服务
systemctl status docker

# 2. 检查判题镜像
docker images | grep oj-judge

# 3. 查看最新提交状态
python3 manage.py shell
>>> from apps.judge.models import Submission
>>> s = Submission.objects.latest('id')
>>> print('Status:', s.status)
>>> print('Error:', s.runtime_error)
>>> exit()

# 4. 查看Django日志
# 如果使用runserver，直接看终端输出
# 如果使用Docker Compose:
docker-compose logs -f web | grep -E '\[Judger\]|\[Judge Error\]'

# 5. 检查Docker容器
docker ps -a | head -20
```

### 问题3: 镜像拉取失败

**错误信息**:
```
Error response from daemon: Get https://registry-1.docker.io/v2/: net/http: request canceled
```

**解决方案（配置国内镜像源）**:

```bash
# 创建或编辑 daemon.json
sudo vim /etc/docker/daemon.json

# 添加以下内容
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://mirror.ccs.tencentyun.com",
    "https://registry.docker-cn.com"
  ]
}

# 重启Docker
sudo systemctl daemon-reload
sudo systemctl restart docker

# 验证
docker info | grep -A 5 "Registry Mirrors"
```

### 问题4: 测试用例未找到

**错误**: 判题显示"没有测试用例"

**解决方案**:
```bash
# 检查题目是否有测试用例
python3 manage.py shell -c "
from apps.problems.models import Problem
p = Problem.objects.get(id=1)
print('Test cases:', p.test_cases.count())
"

# 如果为0，重新创建测试用例（参考Step 6）
```

### 问题5: 内存不足

**错误**: Docker运行失败或系统卡顿

**解决方案**:
```bash
# 检查系统内存
free -h

# 清理Docker垃圾
docker system prune -a

# 限制单个容器内存（已在judger.py中配置）
# 如果需要调整，修改 apps/judge/judger.py 中的 mem_limit
```

---

## 🔒 安全加固（生产环境）

### 1. 防火墙配置

```bash
# 仅允许特定端口（如80, 443, 8000）
sudo ufw allow 22/tcp      # SSH
sudo ufw allow 80/tcp      # HTTP
sudo ufw allow 443/tcp     # HTTPS
sudo ufw allow 8000/tcp    # Django（如果直接暴露）
sudo ufw enable

# 验证
sudo ufw status
```

### 2. Docker安全配置

```bash
# 限制Docker容器资源
# 已在代码中配置:
# - mem_limit: 内存限制
# - memswap_limit: 交换内存限制
# - pids_limit: 进程数限制
# - network_mode='none': 禁用网络
```

### 3. 定期清理

```bash
# 创建清理脚本
cat > /usr/local/bin/cleanup-judge.sh << 'EOF'
#!/bin/bash
# 清理判题临时文件
find /tmp -name "judge_*" -type d -mtime +1 -exec rm -rf {} + 2>/dev/null

# 清理Docker垃圾
docker system prune -f --volumes

echo "清理完成: $(date)"
EOF

chmod +x /usr/local/bin/cleanup-judge.sh

# 添加到crontab（每天凌晨3点执行）
(crontab -l 2>/dev/null; echo "0 3 * * * /usr/local/bin/cleanup-judge.sh >> /var/log/cleanup-judge.log 2>&1") | crontab -
```

---

## 📊 监控和日志

### 查看判题日志

```bash
# 实时查看日志（如果使用runserver）
python3 manage.py runserver 0.0.0.0:8000 2>&1 | grep -E '\[Judger\]|\[Judge Error\]'

# 如果使用Docker Compose
docker-compose logs -f web | grep -E '\[Judger\]|\[Judge Error\]'

# 保存日志到文件
docker-compose logs web > judge.log
```

### 系统监控

```bash
# 实时监控Docker容器资源
docker stats

# 查看判题容器
docker ps -a | grep judge

# 查看系统资源
htop  # 需要先安装: sudo apt-get install htop
```

---

## 🚀 性能优化

### 1. 镜像预热

```bash
# 预先拉取镜像避免首次判题慢
docker pull python:3.10-slim
docker pull gcc:11-slim

# 或重新构建本地镜像
cd docker/judge
docker build -t oj-judge-python:latest -f Dockerfile.python .
docker build -t oj-judge-cpp:latest -f Dockerfile.cpp .
```

### 2. 并发控制

在 `apps/judge/views.py` 中，当前使用后台线程判题。
生产环境建议使用 **Celery** 实现异步队列。

### 3. 数据库优化

```bash
# 如果使用PostgreSQL（推荐生产环境）
# 创建索引（已在models.py中定义）
python3 manage.py migrate

# 如果使用SQLite（开发环境）
# 定期清理旧提交
python3 manage.py shell -c "
from apps.judge.models import Submission
from datetime import timedelta
from django.utils import timezone

# 删除30天前的提交
old_date = timezone.now() - timedelta(days=30)
count = Submission.objects.filter(created_at__lt=old_date).delete()[0]
print(f'清理了 {count} 条旧提交')
"
```

---

## ✅ 验证清单

完成所有设置后，请验证：

```bash
# 1. Docker正常运行
docker ps

# 2. 判题镜像存在
docker images | grep oj-judge

# 3. 数据库表已创建
python3 manage.py dbshell -c ".tables" .quit

# 4. 语言配置已初始化
python3 manage.py shell -c "from apps.judge.models import Language; print(Language.objects.count())"

# 5. 测试题目已创建
python3 manage.py shell -c "from apps.problems.models import Problem; print(Problem.objects.count())"

# 6. 测试提交功能
# 访问: http://your-ip:8000/problems/1/submit/
# 提交代码并验证结果为 AC
```

---

## 📚 相关文件

- `setup-judge-system.sh` - 自动化设置脚本
- `docker/judge/Dockerfile.python` - Python判题镜像
- `docker/judge/Dockerfile.cpp` - C++判题镜像
- `apps/judge/judger.py` - 判题核心逻辑
- `apps/judge/views.py` - 提交API
- `apps/judge/models.py` - 数据模型

---

## 🎯 下一步

完成基础判题后，可以考虑：

1. **使用Celery异步队列** - 提高并发性能
2. **添加更多语言支持** - Java, Go, Rust等
3. **实现分布式判题** - 多台判题服务器负载均衡
4. **WebSocket实时推送** - 无需轮询，即时获取结果
5. **代码相似度检测** - 防止抄袭
6. **竞赛模式** - ACM/OI赛制支持

---

**文档版本**: v1.0  
**适用环境**: Linux (Ubuntu/Debian/CentOS)  
**更新日期**: 2024-10-02

