# Linux服务器部署命令清单

## 📋 完整部署流程

### 第1步：更新代码

```bash
# 进入项目目录
cd /path/to/OJ_system

# 拉取最新代码
git pull origin main

# 查看当前提交
git log -1
```

---

### 第2步：安装Python依赖

```bash
# 激活虚拟环境（如果使用）
source venv/bin/activate

# 安装docker库
pip install docker==7.0.0

# 或安装所有依赖
pip install -r requirements.txt

# 验证安装
python -c "import docker; print(docker.__version__)"
```

---

### 第3步：检查Docker是否安装

```bash
# 检查Docker版本
docker --version

# 检查Docker服务状态
sudo systemctl status docker

# 如果未安装，执行以下命令安装Docker
```

#### 安装Docker (Ubuntu/Debian)

```bash
# 更新包索引
sudo apt-get update

# 安装依赖
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# 添加Docker GPG密钥
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# 设置仓库
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 安装Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# 启动Docker
sudo systemctl start docker
sudo systemctl enable docker

# 添加当前用户到docker组（避免每次sudo）
sudo usermod -aG docker $USER

# 注销并重新登录，或执行：
newgrp docker

# 验证安装
docker run hello-world
```

---

### 第4步：构建判题Docker镜像

```bash
# 进入镜像目录
cd docker/judge

# 添加执行权限
chmod +x build-images.sh

# 构建镜像
./build-images.sh

# 或手动构建
docker build -t oj-judge-python:latest -f Dockerfile.python .
docker build -t oj-judge-cpp:latest -f Dockerfile.cpp .
```

#### 验证镜像

```bash
# 查看已构建镜像
docker images | grep oj-judge

# 应该看到：
# oj-judge-python   latest   xxx   xxx   xxx MB
# oj-judge-cpp      latest   xxx   xxx   xxx MB

# 测试Python镜像
docker run --rm oj-judge-python:latest python3 --version
# 输出: Python 3.10.x

# 测试C++镜像
docker run --rm oj-judge-cpp:latest g++ --version
# 输出: g++ (GCC) 11.x.x

# 测试运行简单代码
echo 'print("Hello from Docker!")' > test.py
docker run --rm -v $(pwd):/workspace oj-judge-python:latest python3 /workspace/test.py
rm test.py
```

---

### 第5步：运行数据库迁移

```bash
# 返回项目根目录
cd /path/to/OJ_system

# 运行迁移
python manage.py migrate

# 查看迁移状态
python manage.py showmigrations judge
```

---

### 第6步：初始化编程语言配置

```bash
# 运行语言初始化命令
python manage.py init_languages

# 应该看到输出：
# 正在初始化编程语言配置...
# [!] Python 3.10 配置已存在
# [!] C++ 17 配置已存在
# 
# 语言配置初始化完成！
# 已配置语言数量: 2
# 
# 支持的语言：
#   - Python 3.10 (python)
#   - C++ 17 (cpp)
```

---

### 第7步：重启Django服务

#### 如果使用Gunicorn

```bash
# 重启Gunicorn
sudo systemctl restart gunicorn

# 查看状态
sudo systemctl status gunicorn

# 查看日志
sudo journalctl -u gunicorn -f
```

#### 如果使用Docker Compose

```bash
# 重启web服务
docker-compose restart web

# 查看日志
docker-compose logs -f web
```

#### 如果使用screen/nohup运行

```bash
# 找到并杀死旧进程
ps aux | grep "manage.py runserver"
kill <PID>

# 或使用pkill
pkill -f "manage.py runserver"

# 重新启动（后台运行）
nohup python manage.py runserver 0.0.0.0:8000 > django.log 2>&1 &

# 查看日志
tail -f django.log
```

---

### 第8步：测试判题功能

#### 创建测试题目

```bash
# 进入Django shell
python manage.py shell
```

```python
from apps.problems.models import Problem, TestCase
from django.contrib.auth.models import User

# 获取或创建用户
admin = User.objects.filter(is_superuser=True).first()

# 创建测试题目
problem = Problem.objects.create(
    title='A+B Problem',
    description='输入两个整数a和b，输出它们的和',
    input_format='一行两个整数，用空格分隔',
    output_format='一个整数，表示a+b的值',
    hint='',
    time_limit=1000,
    memory_limit=256,
    difficulty='easy',
    status='published',
    created_by=admin
)

# 添加测试用例
TestCase.objects.create(
    problem=problem,
    input_data='1 2',
    output_data='3',
    is_sample=True,
    score=10,
    order=1
)

TestCase.objects.create(
    problem=problem,
    input_data='10 20',
    output_data='30',
    is_sample=True,
    score=10,
    order=2
)

TestCase.objects.create(
    problem=problem,
    input_data='-5 5',
    output_data='0',
    is_sample=False,
    score=10,
    order=3
)

print(f"题目创建成功！ID: {problem.id}")
print(f"测试用例数量: {problem.test_cases.count()}")

# 退出shell
exit()
```

#### 通过API测试提交

```bash
# 获取认证Token（先登录）
TOKEN=$(curl -X POST http://your-server-ip:8000/users/api/login/ \
  -H "Content-Type: application/json" \
  -d '{"username":"your_username","password":"your_password"}' \
  | jq -r '.token')

echo "Token: $TOKEN"

# 提交Python代码
curl -X POST http://your-server-ip:8000/judge/api/submissions/ \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "problem_id": 1,
    "language_name": "python",
    "code": "a, b = map(int, input().split())\nprint(a + b)"
  }'

# 记录返回的submission_id

# 查询提交结果（等待几秒后查询）
sleep 3
curl -X GET http://your-server-ip:8000/judge/api/submissions/1/

# 查看我的提交
curl -X GET http://your-server-ip:8000/judge/api/submissions/my_submissions/ \
  -H "Authorization: Bearer $TOKEN"
```

#### 测试C++提交

```bash
# 提交C++代码
curl -X POST http://your-server-ip:8000/judge/api/submissions/ \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "problem_id": 1,
    "language_name": "cpp",
    "code": "#include <iostream>\nusing namespace std;\n\nint main() {\n    int a, b;\n    cin >> a >> b;\n    cout << a + b << endl;\n    return 0;\n}"
  }'
```

---

### 第9步：查看判题日志

```bash
# 查看Django日志（如果使用journalctl）
sudo journalctl -u gunicorn -f | grep "\[Judger\]"

# 或查看Django日志文件
tail -f /var/log/django/debug.log | grep "\[Judger\]"

# 或查看容器日志
docker-compose logs -f web | grep "\[Judger\]"

# 应该看到类似输出：
# [Judger] 开始判题: Submission #1
# [Judger] 工作目录: /tmp/judge_xxx
# [Judger] 开始编译...
# [Judger] 编译成功
# [Judger] 运行测试用例 1/3
# [Judger] 运行测试用例 2/3
# [Judger] 运行测试用例 3/3
# [Judger] 判题完成: AC
# [Judger] 清理工作目录: /tmp/judge_xxx
```

---

### 第10步：在管理后台查看

```bash
# 访问管理后台
# 浏览器打开: http://your-server-ip:8000/admin/

# 导航到:
# 判题系统 -> 代码提交

# 可以看到:
# - 提交列表
# - 判题状态（pending/judging/finished）
# - 判题结果（AC/WA/TLE等）
# - 运行时间和内存
# - 测试用例通过情况
# - 完整的判题详情JSON
```

---

## 🔧 常用维护命令

### 查看Docker容器

```bash
# 查看运行中的容器
docker ps

# 查看所有容器（包括已停止）
docker ps -a

# 清理停止的容器
docker container prune -f

# 查看Docker磁盘占用
docker system df
```

### 清理Docker资源

```bash
# 清理未使用的镜像
docker image prune -f

# 清理所有未使用资源
docker system prune -a -f

# 保留判题镜像
docker images | grep oj-judge
```

### 查看系统资源

```bash
# CPU和内存使用
htop

# 或
top

# 磁盘使用
df -h

# 查看临时目录
du -sh /tmp/judge_*
```

### 数据库操作

```bash
# 备份数据库
python manage.py dumpdata judge > judge_backup.json

# 恢复数据库
python manage.py loaddata judge_backup.json

# 查看提交记录
python manage.py shell
```

```python
from apps.judge.models import Submission

# 查看最近10条提交
for s in Submission.objects.all()[:10]:
    print(f"#{s.id} {s.user.username} {s.problem.title} {s.result} {s.status}")
```

---

## 🐛 故障排查

### 问题1：Docker权限错误

```bash
# 错误: permission denied while trying to connect to the Docker daemon socket
# 解决:
sudo usermod -aG docker $USER
newgrp docker

# 或临时使用sudo
sudo docker ps
```

### 问题2：判题一直pending

```bash
# 检查Django日志
tail -f django.log | grep -E "\[Judger\]|Error"

# 检查是否有死锁的容器
docker ps -a | grep judge

# 强制清理
docker rm -f $(docker ps -aq --filter "name=judge")
```

### 问题3：镜像拉取失败

```bash
# 配置国内镜像源
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://mirror.ccs.tencentyun.com"
  ]
}
EOF

# 重启Docker
sudo systemctl restart docker
```

### 问题4：测试用例读取失败

```bash
# 检查文件权限
ls -la /tmp/judge_*

# 检查Django能否访问临时目录
python -c "import tempfile; print(tempfile.gettempdir())"

# 设置临时目录权限
sudo chmod 777 /tmp
```

---

## 📊 性能监控

### 创建监控脚本

```bash
# 创建监控脚本
cat > monitor_judge.sh <<'EOF'
#!/bin/bash

echo "========== OJ判题系统监控 =========="
echo "时间: $(date)"
echo ""

echo "--- Django进程 ---"
ps aux | grep "manage.py" | grep -v grep

echo ""
echo "--- Docker容器 ---"
docker ps --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}"

echo ""
echo "--- 判题镜像 ---"
docker images | grep oj-judge

echo ""
echo "--- 最近提交 ---"
echo "SELECT id, user_id, problem_id, result, status, created_at FROM submissions ORDER BY created_at DESC LIMIT 5;" | python manage.py dbshell

echo ""
echo "--- 磁盘使用 ---"
df -h | grep -E "Filesystem|/$"

echo ""
echo "--- 内存使用 ---"
free -h

echo ""
echo "==================================="
EOF

chmod +x monitor_judge.sh
```

### 运行监控

```bash
# 执行监控
./monitor_judge.sh

# 或定时监控
watch -n 10 ./monitor_judge.sh
```

---

## 🔄 更新部署脚本

### 创建快速部署脚本

```bash
cat > deploy_judge.sh <<'EOF'
#!/bin/bash

set -e

echo "========== OJ判题系统部署 =========="

# 1. 拉取代码
echo "[1/7] 拉取最新代码..."
git pull origin main

# 2. 安装依赖
echo "[2/7] 安装Python依赖..."
pip install -r requirements.txt -q

# 3. 运行迁移
echo "[3/7] 运行数据库迁移..."
python manage.py migrate

# 4. 初始化语言
echo "[4/7] 初始化编程语言..."
python manage.py init_languages

# 5. 构建Docker镜像
echo "[5/7] 构建判题Docker镜像..."
cd docker/judge
./build-images.sh
cd ../..

# 6. 收集静态文件
echo "[6/7] 收集静态文件..."
python manage.py collectstatic --noinput

# 7. 重启服务
echo "[7/7] 重启服务..."
sudo systemctl restart gunicorn
# 或: docker-compose restart web

echo ""
echo "========== 部署完成 =========="
echo "请访问管理后台查看: http://your-server-ip:8000/admin/"
EOF

chmod +x deploy_judge.sh
```

### 使用部署脚本

```bash
# 一键部署
./deploy_judge.sh
```

---

## 📝 快速命令参考

```bash
# 项目目录
cd /path/to/OJ_system

# 拉取代码
git pull

# 安装依赖
pip install docker==7.0.0

# 构建镜像
cd docker/judge && ./build-images.sh && cd ../..

# 验证镜像
docker images | grep oj-judge

# 运行迁移
python manage.py migrate

# 初始化语言
python manage.py init_languages

# 重启服务
sudo systemctl restart gunicorn

# 查看日志
sudo journalctl -u gunicorn -f

# 测试判题
curl -X POST http://localhost:8000/judge/api/submissions/ \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"problem_id":1,"language_name":"python","code":"print(1+1)"}'

# 查看结果
curl http://localhost:8000/judge/api/submissions/1/
```

---

## ✅ 部署检查清单

- [ ] Git代码已更新
- [ ] Python依赖已安装（docker==7.0.0）
- [ ] Docker已安装并运行
- [ ] 判题镜像已构建（python/cpp）
- [ ] 数据库迁移已执行
- [ ] 语言配置已初始化
- [ ] Django服务已重启
- [ ] 测试题目已创建
- [ ] 测试提交已成功
- [ ] 判题结果正确（AC）
- [ ] 管理后台可访问
- [ ] 日志输出正常

---

**完成以上步骤后，判题系统即可正常运行！** 🎉

有问题随时查看日志或使用监控脚本排查。

