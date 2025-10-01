# 判题系统 Phase 2 设置指南

## ✅ Phase 2 已完成功能

### 1. 判题核心模块 ✓

**文件**: `apps/judge/judger.py` (~400行)

**核心类**:
- `JudgeResult`: 判题结果类
- `Judger`: 判题器主类
- `judge_submission()`: 判题入口函数

**判题流程**:
```
1. 准备工作目录 (_prepare_workspace)
2. 编译代码 (_compile_code) - 如需要
3. 获取测试用例
4. 遍历运行测试 (_run_testcase)
5. 汇总结果
6. 更新数据库 (_update_submission)
7. 清理工作目录 (_cleanup_workspace)
```

**核心功能**:
- ✅ Docker沙箱隔离
- ✅ 代码编译（C++）
- ✅ 代码运行（Python/C++）
- ✅ 输出比对（忽略空格和空行）
- ✅ 超时控制
- ✅ 内存限制
- ✅ 错误捕获
- ✅ 统计更新

---

### 2. Docker判题镜像 ✓

**镜像文件**:
- `docker/judge/Dockerfile.python` - Python 3.10镜像
- `docker/judge/Dockerfile.cpp` - C++ 17镜像

**安全配置**:
```dockerfile
# 非root用户
RUN useradd -u 10001 -m judger

# 工作目录
WORKDIR /workspace

# 必要工具
apt-get install time
```

**构建脚本**:
- `docker/judge/build-images.sh` (Linux/Mac)
- `docker/judge/build-images.ps1` (Windows)

---

### 3. API集成 ✓

**提交API更新**:
```python
POST /judge/api/submissions/

# 创建提交后自动在后台线程判题
thread = threading.Thread(target=judge_in_background)
thread.start()
```

**返回**:
```json
{
  "id": 12345,
  "status": "pending",
  "message": "提交成功，正在判题..."
}
```

---

## 🐳 Docker环境设置

### Windows环境

#### 1. 安装Docker Desktop

**下载地址**:
- https://www.docker.com/products/docker-desktop

**安装步骤**:
1. 下载 Docker Desktop for Windows
2. 运行安装程序
3. 重启计算机
4. 启动 Docker Desktop
5. 等待Docker服务启动（右下角图标）

**验证安装**:
```powershell
docker --version
docker ps
```

#### 2. 配置Docker

**设置WSL2后端** (推荐):
- Docker Desktop → Settings → General
- ✅ Use the WSL 2 based engine

**资源分配**:
- Docker Desktop → Settings → Resources
- CPU: 至少4核
- Memory: 至少4GB
- Disk: 至少20GB

---

### Linux环境

#### Ubuntu/Debian

```bash
# 1. 更新包索引
sudo apt-get update

# 2. 安装依赖
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# 3. 添加Docker官方GPG密钥
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# 4. 设置仓库
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 5. 安装Docker Engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# 6. 启动Docker
sudo systemctl start docker
sudo systemctl enable docker

# 7. 添加用户到docker组（可选）
sudo usermod -aG docker $USER
# 注销后重新登录生效

# 8. 验证安装
docker --version
docker ps
```

---

## 🏗️ 构建判题镜像

### Windows (PowerShell)

```powershell
# 进入镜像目录
cd docker/judge

# 构建镜像
.\build-images.ps1

# 或手动构建
docker build -t oj-judge-python:latest -f Dockerfile.python .
docker build -t oj-judge-cpp:latest -f Dockerfile.cpp .
```

### Linux (Bash)

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

### 验证镜像

```bash
# 查看已构建镜像
docker images | grep oj-judge

# 测试Python镜像
docker run --rm oj-judge-python:latest python3 --version
# 输出: Python 3.10.x

# 测试C++镜像
docker run --rm oj-judge-cpp:latest g++ --version
# 输出: g++ (GCC) 11.x.x

# 测试运行Python代码
docker run --rm -v ${PWD}:/workspace oj-judge-python:latest \
    python3 -c "print('Hello from Docker!')"
```

---

## 📦 Python依赖安装

```bash
# 安装docker-py库
pip install docker==7.0.0

# 验证安装
python -c "import docker; print(docker.__version__)"
```

---

## 🧪 测试判题系统

### 1. 准备测试题目

**创建测试题目** (在Django Admin):

```
标题: A+B Problem
描述: 输入两个整数a和b，输出它们的和
输入格式: 一行两个整数，用空格分隔
输出格式: 一个整数，表示a+b的值
时间限制: 1000ms
内存限制: 256MB
状态: 已发布
```

**添加测试用例**:

```
测试用例1:
输入: 1 2
输出: 3

测试用例2:
输入: 10 20
输出: 30

测试用例3:
输入: -5 5
输出: 0
```

### 2. 测试Python提交

**正确代码**:
```python
a, b = map(int, input().split())
print(a + b)
```

**提交**:
```bash
curl -X POST http://localhost:8000/judge/api/submissions/ \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "problem_id": 1,
    "language_name": "python",
    "code": "a, b = map(int, input().split())\nprint(a + b)"
  }'
```

**预期结果**: `AC` (Accepted)

### 3. 测试C++提交

**正确代码**:
```cpp
#include <iostream>
using namespace std;

int main() {
    int a, b;
    cin >> a >> b;
    cout << a + b << endl;
    return 0;
}
```

**提交**:
```bash
curl -X POST http://localhost:8000/judge/api/submissions/ \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "problem_id": 1,
    "language_name": "cpp",
    "code": "#include <iostream>\nusing namespace std;\n\nint main() {\n    int a, b;\n    cin >> a >> b;\n    cout << a + b << endl;\n    return 0;\n}"
  }'
```

**预期结果**: `AC` (Accepted)

### 4. 测试错误情况

#### 编译错误 (CE)
```cpp
// 缺少分号
#include <iostream>
using namespace std;

int main() {
    int a, b
    cin >> a >> b;
    cout << a + b << endl;
    return 0;
}
```

**预期**: `CE` (Compile Error)

#### 答案错误 (WA)
```python
a, b = map(int, input().split())
print(a - b)  # 应该是加法，写成了减法
```

**预期**: `WA` (Wrong Answer)

#### 超时 (TLE)
```python
a, b = map(int, input().split())
while True:
    pass  # 无限循环
print(a + b)
```

**预期**: `TLE` (Time Limit Exceeded)

#### 运行错误 (RE)
```python
a, b = map(int, input().split())
print(a / 0)  # 除以零
```

**预期**: `RE` (Runtime Error)

---

## 📊 查看判题结果

### 1. 查询提交状态

```bash
# 查询指定提交
curl http://localhost:8000/judge/api/submissions/12345/

# 查询我的提交
curl http://localhost:8000/judge/api/submissions/my_submissions/ \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 2. 在管理后台查看

访问: `http://localhost:8000/admin/judge/submission/`

可以看到:
- ✅ 彩色状态徽章
- ✅ 判题结果
- ✅ 运行时间和内存
- ✅ 测试用例通过情况
- ✅ 错误信息
- ✅ 完整判题详情（JSON）

---

## 🔧 调试和日志

### 查看判题日志

判题器会输出详细日志：

```
[Judger] 开始判题: Submission #12345
[Judger] 工作目录: /tmp/judge_abc123
[Judger] 开始编译...
[Judger] 编译成功
[Judger] 运行测试用例 1/3
[Judger] 运行测试用例 2/3
[Judger] 运行测试用例 3/3
[Judger] 判题完成: AC
[Judger] 清理工作目录: /tmp/judge_abc123
```

### Django Shell测试

```bash
python manage.py shell
```

```python
from apps.judge.judger import judge_submission
from apps.judge.models import Submission

# 获取一个提交
submission = Submission.objects.first()

# 手动触发判题
result = judge_submission(submission.id)

# 查看结果
print(f"结果: {result.status}")
print(f"得分: {result.score}")
print(f"时间: {result.time_used}ms")
print(f"内存: {result.memory_used}KB")
```

---

## ⚠️ 常见问题

### Q1: Docker未安装或未启动

**错误**:
```
docker: 无法将"docker"识别为 cmdlet
```

**解决**:
1. 安装 Docker Desktop
2. 启动 Docker Desktop
3. 等待服务完全启动
4. 验证: `docker ps`

### Q2: 权限不足

**错误**:
```
permission denied while trying to connect to the Docker daemon socket
```

**解决**:
```bash
# Linux
sudo usermod -aG docker $USER
# 注销重新登录

# Windows
# 以管理员身份运行 PowerShell
```

### Q3: 镜像拉取失败

**错误**:
```
Error response from daemon: Get https://registry-1.docker.io/v2/: net/http: request canceled
```

**解决**:
```bash
# 配置Docker镜像加速
# Docker Desktop → Settings → Docker Engine
# 添加:
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://mirror.ccs.tencentyun.com"
  ]
}
```

### Q4: 判题超时

**问题**: 判题一直处于`judging`状态

**检查**:
1. 查看Django日志
2. 检查Docker容器: `docker ps -a`
3. 检查工作目录是否被清理
4. 查看数据库中的错误信息

### Q5: 输出比对失败

**问题**: 明明正确却显示WA

**原因**: 输出格式问题（多余空格/换行）

**解决**: 检查输出是否严格匹配，_compare_output已处理行尾空格

---

## 🎯 Phase 2 完成检查清单

- [x] 创建判题核心模块 `judger.py`
- [x] 实现编译功能
- [x] 实现运行功能
- [x] 实现输出比对
- [x] Docker沙箱集成
- [x] 创建Python判题镜像
- [x] 创建C++判题镜像
- [x] 镜像构建脚本
- [x] API集成判题
- [x] 后台线程判题
- [x] 错误处理
- [x] 统计更新
- [ ] 构建Docker镜像（需要Docker环境）
- [ ] 测试Python提交
- [ ] 测试C++提交
- [ ] 测试各种错误情况

---

## ⏭️ Phase 3 计划

### 异步判题队列

- [ ] 安装Celery
- [ ] 配置Redis
- [ ] 创建Celery任务
- [ ] 异步判题
- [ ] 任务队列监控
- [ ] WebSocket实时推送

### 前端页面

- [ ] 代码编辑器（CodeMirror）
- [ ] 语言选择
- [ ] 提交按钮
- [ ] 实时状态显示
- [ ] 提交历史列表
- [ ] 代码查看页面

### 性能优化

- [ ] 容器池预热
- [ ] 测试用例缓存
- [ ] 并发控制
- [ ] 负载均衡

---

## 📚 相关文档

- `JUDGE-SYSTEM-DESIGN.md` - 完整设计文档
- `JUDGE-PHASE1-COMPLETE.md` - Phase 1完成报告
- `SANDBOX-COMPARISON.md` - 沙箱技术对比
- `JUDGE-QUICK-REFERENCE.md` - 快速参考

---

**Phase 2 状态**: 代码完成，待Docker环境测试  
**下一步**: 安装Docker并构建镜像，然后测试判题功能

---

**文档版本**: v1.0  
**创建日期**: 2024-10-01
