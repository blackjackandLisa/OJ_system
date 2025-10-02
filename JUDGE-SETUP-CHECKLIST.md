# 判题系统完整设置清单

## 📋 当前状态诊断

### 已完成 ✅
- [x] 判题核心代码 (`apps/judge/judger.py`)
- [x] 提交API (`apps/judge/views.py`)
- [x] 前端提交界面 (`templates/problems/problem_submit.html`)
- [x] 数据模型定义

### 待完成 ❌
- [ ] 数据库迁移
- [ ] Docker环境配置
- [ ] 判题镜像构建
- [ ] 语言配置初始化
- [ ] 测试题目和用例
- [ ] 依赖库安装

---

## 🚀 完整实施步骤

### Step 1: 数据库迁移

```bash
# 1. 创建迁移文件
python manage.py makemigrations

# 2. 执行迁移
python manage.py migrate

# 3. 验证表已创建
python manage.py dbshell
> .tables
> .quit
```

**预期结果**:
- `problems` 表
- `test_cases` 表
- `submissions` 表
- `languages` 表
- `judge_servers` 表

---

### Step 2: 安装Python依赖

```bash
# 安装 docker-py 库（判题核心依赖）
pip install docker==7.0.0

# 验证安装
python -c "import docker; print('Docker SDK:', docker.__version__)"
```

---

### Step 3: Docker环境配置

#### Windows环境

**3.1 安装 Docker Desktop**

1. 下载: https://www.docker.com/products/docker-desktop
2. 运行安装程序
3. 重启计算机
4. 启动 Docker Desktop
5. 等待右下角图标显示"Docker Desktop is running"

**3.2 验证安装**

```powershell
# 检查Docker版本
docker --version
# 输出: Docker version 24.x.x

# 检查Docker服务
docker ps
# 输出: CONTAINER ID   IMAGE   COMMAND   ...（空列表也正常）
```

**3.3 配置Docker（可选）**

Docker Desktop → Settings → Resources:
- CPU: 4核以上
- Memory: 4GB以上
- Disk: 20GB以上

#### Linux环境（Ubuntu/Debian）

```bash
# 安装Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# 启动Docker服务
sudo systemctl start docker
sudo systemctl enable docker

# 添加当前用户到docker组（避免sudo）
sudo usermod -aG docker $USER
# 注销重新登录生效

# 验证
docker --version
docker ps
```

---

### Step 4: 构建判题Docker镜像

#### Windows (PowerShell)

```powershell
# 进入镜像目录
cd docker/judge

# 构建Python镜像
docker build -t oj-judge-python:latest -f Dockerfile.python .

# 构建C++镜像
docker build -t oj-judge-cpp:latest -f Dockerfile.cpp .

# 验证镜像
docker images | Select-String "oj-judge"
```

#### Linux (Bash)

```bash
# 进入镜像目录
cd docker/judge

# 构建镜像
docker build -t oj-judge-python:latest -f Dockerfile.python .
docker build -t oj-judge-cpp:latest -f Dockerfile.cpp .

# 验证镜像
docker images | grep oj-judge
```

**预期输出**:
```
oj-judge-python   latest   xxx   xxx   xxx MB
oj-judge-cpp      latest   xxx   xxx   xxx MB
```

---

### Step 5: 初始化语言配置

```bash
# 运行语言初始化命令
python manage.py init_languages

# 验证
python manage.py shell -c "from apps.judge.models import Language; print('Languages:', Language.objects.count())"
# 输出: Languages: 2
```

**预期结果**:
- Python 3.10 配置已创建
- C++ 17 配置已创建

---

### Step 6: 创建测试题目和用例

#### 方法1: 使用Django Admin（推荐）

1. **创建管理员账号**（如果没有）:
```bash
python manage.py createsuperuser
```

2. **访问管理后台**:
```
http://localhost:8000/admin/
```

3. **创建测试题目**:
   - 导航到 "题目管理" → "题目"
   - 点击 "添加题目"
   - 填写信息:
     ```
     标题: A+B Problem
     描述: 输入两个整数a和b，输出它们的和
     输入格式: 一行两个整数，用空格分隔
     输出格式: 一个整数，表示a+b的值
     时间限制: 1000
     内存限制: 256
     难度: easy
     状态: published
     ```
   - 保存

4. **添加测试用例**:
   - 在题目页面点击 "测试用例"
   - 添加用例1:
     ```
     输入: 1 2
     输出: 3
     ```
   - 添加用例2:
     ```
     输入: 10 20
     输出: 30
     ```
   - 添加用例3:
     ```
     输入: -5 5
     输出: 0
     ```

#### 方法2: 使用脚本（快速）

创建测试脚本 `setup_test_problem.py`:

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

print(f"✅ 题目创建成功: {problem.title} (ID: {problem.id})")
print(f"✅ 测试用例: {problem.test_cases.count()} 个")
```

运行:
```bash
python manage.py shell < setup_test_problem.py
```

---

### Step 7: 测试判题功能

#### 7.1 测试Python提交（正确答案）

**访问**: `http://localhost:8000/problems/1/submit/`

**选择语言**: Python 3

**提交代码**:
```python
a, b = map(int, input().split())
print(a + b)
```

**点击**: "提交代码"

**预期结果**: `AC` (Accepted) ✅

#### 7.2 测试错误情况

**答案错误 (WA)**:
```python
a, b = map(int, input().split())
print(a - b)  # 错误：应该是加法
```
预期: `WA` (Wrong Answer)

**运行错误 (RE)**:
```python
a, b = map(int, input().split())
print(a / 0)  # 错误：除以零
```
预期: `RE` (Runtime Error)

#### 7.3 测试C++提交

**选择语言**: C++ 17

**提交代码**:
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

**预期结果**: `AC` (Accepted) ✅

---

## 🔍 问题排查

### 问题1: 提交后一直显示"正在判题"

**可能原因**:
1. Docker未启动或不可用
2. 判题镜像不存在
3. 测试用例未创建
4. Python docker库未安装

**排查步骤**:

```bash
# 1. 检查Docker
docker ps
# 如果报错，说明Docker未启动

# 2. 检查镜像
docker images | grep oj-judge
# 应该看到 oj-judge-python 和 oj-judge-cpp

# 3. 检查提交状态
python manage.py shell
>>> from apps.judge.models import Submission
>>> s = Submission.objects.latest('id')
>>> print(f"Status: {s.status}")
>>> print(f"Error: {s.runtime_error}")
>>> exit()

# 4. 查看Django日志
# 查找 [Judger] 或 [Judge Error] 开头的日志
```

### 问题2: Docker连接失败

**错误**: `docker.errors.DockerException: Error while fetching server API version`

**解决**:
```bash
# Windows: 启动 Docker Desktop
# Linux: 启动 Docker 服务
sudo systemctl start docker
```

### 问题3: 权限拒绝

**错误**: `permission denied while trying to connect to Docker`

**解决**:
```bash
# Linux
sudo usermod -aG docker $USER
# 注销重新登录

# Windows
# 以管理员身份运行PowerShell或命令提示符
```

### 问题4: 镜像构建失败

**错误**: `Error response from daemon: Get https://registry-1.docker.io/v2/: net/http: request canceled`

**解决**: 配置Docker镜像加速

Docker Desktop → Settings → Docker Engine，添加:
```json
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://mirror.ccs.tencentyun.com"
  ]
}
```

---

## ✅ 完成检查清单

执行完所有步骤后，检查:

- [ ] `docker ps` 命令正常运行
- [ ] `docker images` 显示 oj-judge-python 和 oj-judge-cpp
- [ ] 数据库中有 Language 记录（Python 和 C++）
- [ ] 数据库中有测试题目和用例
- [ ] Python提交测试通过（AC）
- [ ] C++提交测试通过（AC）
- [ ] 错误提交能正确判定（WA/RE等）

---

## 📊 系统架构

```
用户提交代码
    ↓
Django API (/judge/api/submissions/)
    ↓
SubmissionCreateSerializer (验证)
    ↓
创建 Submission 记录
    ↓
后台线程启动判题
    ↓
Judger 类初始化
    ↓
准备工作目录 (/tmp/judge_xxx)
    ↓
编译代码（如需要）
    ↓
运行测试用例（Docker容器）
    ├─ 创建容器
    ├─ 挂载代码
    ├─ 执行运行命令
    ├─ 比对输出
    └─ 记录时间/内存
    ↓
汇总结果
    ↓
更新数据库（status='finished', result='AC'等）
    ↓
前端轮询获取结果
    ↓
展示判题结果
```

---

## 📚 相关文档

- `JUDGE-SYSTEM-DESIGN.md` - 系统设计文档
- `JUDGE-PHASE2-SETUP.md` - Phase 2 设置指南
- `JUDGE-QUICK-REFERENCE.md` - 快速参考
- `docker/judge/README.md` - Docker镜像说明

---

## 🎯 下一步优化

完成基础判题后，可以考虑:

1. **异步判题** - 使用Celery + Redis队列
2. **负载均衡** - 多个判题服务器
3. **容器池** - 预热容器提高性能
4. **WebSocket** - 实时推送判题结果
5. **代码高亮** - 提交历史代码查看
6. **统计报表** - 用户/题目统计图表

---

**文档版本**: v2.0  
**更新日期**: 2024-10-02  
**状态**: 完整实施指南

