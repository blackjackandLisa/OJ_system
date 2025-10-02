# 判题系统故障排查指南

## 问题：提交后一直显示"正在判题"

如果前端显示"系统判题中，请稍候...(N)"并一直轮询不完成，说明判题逻辑出现问题。

---

## 🔍 诊断步骤（在Linux服务器上执行）

### Step 1: 检查提交记录

```bash
# 进入项目目录
cd /path/to/OJ_system

# 查看最新提交状态
python3 manage.py shell << 'EOF'
from apps.judge.models import Submission

# 检查提交总数
count = Submission.objects.count()
print(f"提交总数: {count}")

if count > 0:
    # 获取最新提交
    s = Submission.objects.latest('id')
    print(f"\n最新提交:")
    print(f"  ID: {s.id}")
    print(f"  状态: {s.status}")
    print(f"  结果: {s.result}")
    print(f"  用户: {s.user.username}")
    print(f"  题目: {s.problem.title}")
    print(f"  语言: {s.language.name}")
    print(f"  创建时间: {s.created_at}")
    
    if s.runtime_error:
        print(f"\n运行时错误:")
        print(s.runtime_error[:500])
    
    if s.compile_error:
        print(f"\n编译错误:")
        print(s.compile_error[:500])
else:
    print("没有提交记录！")
EOF
```

### Step 2: 检查Docker环境

```bash
# 1. 检查Docker服务
systemctl status docker | grep Active
# 应该显示: Active: active (running)

# 2. 检查Docker是否可用
docker ps
# 如果报错，说明Docker有问题

# 3. 检查判题镜像
docker images | grep oj-judge
# 应该看到:
# oj-judge-python   latest   ...
# oj-judge-cpp      latest   ...
```

### Step 3: 检查Python依赖

```bash
# 检查docker-py库
python3 -c "import docker; print('docker-py version:', docker.__version__)"

# 如果报错，安装
pip3 install docker==7.0.0
```

### Step 4: 查看Django日志

```bash
# 如果使用runserver
# 直接查看终端输出，找 [Judger] 或 [Judge Error] 开头的日志

# 如果使用Docker Compose
docker-compose logs -f web | grep -E '\[Judger\]|\[Judge Error\]'

# 或者保存到文件分析
docker-compose logs web > judge_logs.txt
grep -E '\[Judger\]|\[Judge Error\]' judge_logs.txt
```

### Step 5: 手动测试判题

```bash
# 进入Django Shell
python3 manage.py shell

# 手动创建一个提交并判题
from apps.judge.models import Submission, Language
from apps.problems.models import Problem
from django.contrib.auth.models import User

# 获取测试数据
user = User.objects.first()
problem = Problem.objects.get(id=1)  # A+B Problem
language = Language.objects.get(name='python')

# 创建提交
submission = Submission.objects.create(
    user=user,
    problem=problem,
    language=language,
    code='a, b = map(int, input().split())\nprint(a + b)',
    code_length=50,
    total_score=problem.test_cases.count() * 10,
    test_cases_total=problem.test_cases.count(),
    ip_address='127.0.0.1',
    user_agent='test',
    status='pending'
)

print(f"创建提交 ID: {submission.id}")

# 手动触发判题
from apps.judge.judger import judge_submission
try:
    result = judge_submission(submission.id)
    print(f"判题结果: {result.status}")
except Exception as e:
    print(f"判题异常: {str(e)}")
    import traceback
    traceback.print_exc()

exit()
```

---

## 🐛 常见问题和解决方案

### 问题1: Docker不可用

**错误信息**:
```
docker.errors.DockerException: Error while fetching server API version
```

**解决方案**:
```bash
# 启动Docker服务
sudo systemctl start docker
sudo systemctl enable docker

# 检查状态
systemctl status docker

# 添加用户到docker组
sudo usermod -aG docker $USER

# 重新登录或运行
newgrp docker
```

### 问题2: 判题镜像不存在

**错误信息**:
```
docker.errors.ImageNotFound: 404 Client Error: Not Found
```

**解决方案**:
```bash
# 重新构建镜像
cd docker/judge

docker build -t oj-judge-python:latest -f Dockerfile.python .
docker build -t oj-judge-cpp:latest -f Dockerfile.cpp .

# 验证
docker images | grep oj-judge
```

### 问题3: 测试用例不存在

**错误信息**: 数据库中显示 `runtime_error: 没有测试用例`

**解决方案**:
```bash
# 检查测试用例
python3 manage.py shell -c "
from apps.problems.models import Problem
p = Problem.objects.get(id=1)
print('测试用例数量:', p.test_cases.count())
"

# 如果为0，重新创建
python3 manage.py shell << 'EOF'
from apps.problems.models import Problem, TestCase

problem = Problem.objects.get(id=1)

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

print(f'创建了 {len(test_cases)} 个测试用例')
EOF
```

### 问题4: 权限不足

**错误信息**:
```
PermissionError: [Errno 13] Permission denied: '/tmp/judge_xxx'
```

**解决方案**:
```bash
# 检查/tmp目录权限
ls -ld /tmp
# 应该是: drwxrwxrwt

# 如果不对，修复
sudo chmod 1777 /tmp

# 或者修改判题工作目录（在judger.py中）
```

### 问题5: docker-py版本问题

**错误信息**:
```
AttributeError: module 'docker' has no attribute 'from_env'
```

**解决方案**:
```bash
# 卸载旧版本
pip3 uninstall docker docker-py

# 安装正确版本
pip3 install docker==7.0.0

# 验证
python3 -c "import docker; print(docker.__version__)"
```

### 问题6: 判题超时导致一直等待

**现象**: 提交状态一直是 `judging`，永远不变为 `finished`

**原因**: 判题线程可能挂了但没有更新数据库状态

**解决方案**:
```bash
# 查找卡住的提交
python3 manage.py shell -c "
from apps.judge.models import Submission
from datetime import timedelta
from django.utils import timezone

# 找出判题中超过5分钟的提交
stuck = Submission.objects.filter(
    status='judging',
    created_at__lt=timezone.now() - timedelta(minutes=5)
)

print(f'卡住的提交: {stuck.count()}')

for s in stuck:
    print(f'  ID: {s.id}, 创建时间: {s.created_at}')
    # 手动标记为系统错误
    s.status = 'error'
    s.runtime_error = '判题超时，系统异常'
    s.save()
    print(f'  已标记为错误状态')
"

# 或者重新判题
python3 manage.py shell
>>> from apps.judge.judger import judge_submission
>>> judge_submission(提交ID)  # 替换为实际ID
```

---

## 🔧 调试技巧

### 1. 启用详细日志

在 `apps/judge/judger.py` 中已经有详细的日志输出：

```python
print(f"[Judger] 开始判题: Submission #{self.submission.id}")
print(f"[Judger] 工作目录: {workspace}")
print(f"[Judger] 开始编译...")
...
```

运行Django时直接查看这些日志。

### 2. 测试Docker容器

```bash
# 手动测试Python容器
echo 'print("Hello from Docker!")' > /tmp/test.py
docker run --rm -v /tmp:/workspace oj-judge-python:latest python3 /workspace/test.py
# 应该输出: Hello from Docker!

# 手动测试C++容器
echo '#include <iostream>
int main() { std::cout << "Hello from Docker!" << std::endl; }' > /tmp/test.cpp

docker run --rm -v /tmp:/workspace oj-judge-cpp:latest bash -c "g++ /workspace/test.cpp -o /workspace/test && /workspace/test"
# 应该输出: Hello from Docker!
```

### 3. 检查容器残留

```bash
# 查看所有容器（包括已停止的）
docker ps -a | grep -E 'oj-judge|python|gcc'

# 清理残留容器
docker container prune -f

# 清理所有Docker垃圾
docker system prune -a --volumes
```

---

## 📝 完整诊断脚本

创建诊断脚本 `diagnose-judge.sh`:

```bash
#!/bin/bash

echo "======================================"
echo "  判题系统诊断脚本"
echo "======================================"
echo ""

# 1. Docker检查
echo "1. Docker环境检查..."
echo "-----------------------------------"
if docker ps &> /dev/null; then
    echo "✓ Docker服务正常"
    docker --version
else
    echo "✗ Docker服务异常"
fi
echo ""

# 2. 镜像检查
echo "2. 判题镜像检查..."
echo "-----------------------------------"
docker images | grep oj-judge || echo "✗ 未找到判题镜像"
echo ""

# 3. Python依赖检查
echo "3. Python依赖检查..."
echo "-----------------------------------"
python3 -c "import docker; print('✓ docker-py version:', docker.__version__)" || echo "✗ docker-py未安装"
echo ""

# 4. 数据库检查
echo "4. 数据库检查..."
echo "-----------------------------------"
python3 manage.py shell -c "
from apps.judge.models import Language, Submission
from apps.problems.models import Problem, TestCase

print(f'语言配置: {Language.objects.count()}')
print(f'题目数量: {Problem.objects.count()}')
print(f'测试用例: {TestCase.objects.count()}')
print(f'提交记录: {Submission.objects.count()}')
"
echo ""

# 5. 提交状态检查
echo "5. 提交状态检查..."
echo "-----------------------------------"
python3 manage.py shell -c "
from apps.judge.models import Submission
from django.db.models import Count

status_counts = Submission.objects.values('status').annotate(count=Count('id'))
for item in status_counts:
    print(f\"  {item['status']}: {item['count']}\")
" || echo "没有提交记录"
echo ""

echo "======================================"
echo "  诊断完成"
echo "======================================"
```

运行:
```bash
chmod +x diagnose-judge.sh
./diagnose-judge.sh
```

---

## 🎯 快速修复流程

如果判题一直卡住，按以下步骤快速修复：

```bash
# 1. 停止服务
# 如果使用runserver: Ctrl+C
# 如果使用Docker Compose:
docker-compose down

# 2. 重新构建镜像
cd docker/judge
docker build -t oj-judge-python:latest -f Dockerfile.python .
docker build -t oj-judge-cpp:latest -f Dockerfile.cpp .
cd ../..

# 3. 清理数据库中卡住的提交
python3 manage.py shell -c "
from apps.judge.models import Submission
Submission.objects.filter(status__in=['pending', 'judging']).update(
    status='error',
    runtime_error='系统重启，需要重新提交'
)
print('已清理卡住的提交')
"

# 4. 重新启动服务
python3 manage.py runserver 0.0.0.0:8000
# 或
docker-compose up -d

# 5. 重新提交测试
# 访问: http://your-ip:8000/problems/1/submit/
# 提交测试代码
```

---

## 📞 获取帮助

如果以上方法都无法解决问题，请提供以下信息：

1. **系统信息**:
```bash
cat /etc/os-release
docker --version
python3 --version
```

2. **完整日志**:
```bash
# Django日志
python3 manage.py runserver > django.log 2>&1
# 提交代码后
cat django.log | grep -E '\[Judger\]|\[Judge Error\]'
```

3. **提交状态**:
```bash
python3 manage.py shell -c "
from apps.judge.models import Submission
s = Submission.objects.latest('id')
print('Status:', s.status)
print('Error:', s.runtime_error)
"
```

---

**文档版本**: v1.0  
**更新日期**: 2024-10-02

