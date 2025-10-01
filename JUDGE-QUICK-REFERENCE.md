# 判题系统快速参考

## 🎯 核心概念

### 判题流程（10步）
```
提交 → 验证 → 入库 → 队列 → Worker接收 → 准备环境 
→ 编译 → 运行测试 → 汇总结果 → 更新数据库
```

### 判题状态
| 代码 | 名称 | 说明 |
|------|------|------|
| `AC` | Accepted | ✅ 完全正确 |
| `WA` | Wrong Answer | ❌ 答案错误 |
| `TLE` | Time Limit Exceeded | ⏰ 运行超时 |
| `MLE` | Memory Limit Exceeded | 💾 内存超限 |
| `RE` | Runtime Error | 💥 运行时错误 |
| `CE` | Compile Error | 🔧 编译错误 |
| `SE` | System Error | ⚠️ 系统错误 |
| `PE` | Presentation Error | 📝 格式错误 |

---

## 📊 数据库模型

### Submission (核心表)
```python
class Submission(models.Model):
    # 关联
    user = FK(User)
    problem = FK(Problem)
    
    # 代码
    language = CharField  # python/cpp/java/c
    code = TextField
    
    # 状态
    status = CharField    # pending/judging/finished/error
    result = CharField    # AC/WA/TLE/MLE/RE/CE/SE/PE
    
    # 资源
    time_used = IntegerField    # 毫秒
    memory_used = IntegerField  # KB
    
    # 测试
    test_cases_passed = IntegerField
    test_cases_total = IntegerField
    
    # 详情
    judge_detail = JSONField  # 每个测试用例的详细结果
```

---

## 🐳 Docker沙箱配置

### 基本配置
```python
container_config = {
    'image': 'oj-judge-python:latest',
    'detach': True,
    'remove': True,
    
    # 资源限制
    'mem_limit': '256m',
    'memswap_limit': '256m',
    'cpu_quota': 100000,  # 1核
    'pids_limit': 50,
    
    # 安全
    'network_mode': 'none',
    'read_only': True,
    'cap_drop': ['ALL'],
    'security_opt': ['no-new-privileges'],
    
    # 文件系统
    'tmpfs': {'/workspace': 'size=10m'},
    'user': '10001:10001',
}
```

### 编译命令
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

### 运行命令
```bash
# C/C++
./main < input.txt > output.txt

# Java
java Main < input.txt > output.txt

# Python
python3 code.py < input.txt > output.txt
```

---

## 🔒 安全清单

### 必须配置项
- [x] 非root用户 (uid: 10001)
- [x] 网络隔离 (network_mode: none)
- [x] 只读文件系统 (read_only: true)
- [x] 内存限制 (mem_limit)
- [x] CPU限制 (cpu_quota)
- [x] 进程数限制 (pids_limit: 50)
- [x] 超时保护 (timeout)
- [x] 输出限制 (64KB)
- [x] Seccomp过滤
- [x] 删除所有capabilities

### Seccomp白名单（最小化）
```json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "syscalls": [{
    "names": [
      "read", "write", "open", "close",
      "brk", "mmap", "munmap",
      "exit", "exit_group"
    ],
    "action": "SCMP_ACT_ALLOW"
  }]
}
```

---

## 🚀 API接口

### 1. 提交代码
```http
POST /api/submissions/
Content-Type: application/json
Authorization: Bearer <token>

{
  "problem_id": 1,
  "language": "python",
  "code": "print('Hello')"
}

Response: 201 Created
{
  "id": 12345,
  "status": "pending"
}
```

### 2. 查询结果
```http
GET /api/submissions/12345/

Response: 200 OK
{
  "id": 12345,
  "status": "finished",
  "result": "AC",
  "time_used": 15,
  "memory_used": 2048,
  "test_cases_passed": 10,
  "test_cases_total": 10
}
```

### 3. 查看代码
```http
GET /api/submissions/12345/code/

Response: 200 OK
{
  "code": "print('Hello')",
  "language": "python"
}
```

### 4. 获取历史
```http
GET /api/submissions/?user=me&problem=1&result=AC

Response: 200 OK
{
  "count": 15,
  "results": [...]
}
```

---

## ⚡ 判题Worker伪代码

### 主流程
```python
def judge_submission(submission_id):
    # 1. 加载提交
    submission = Submission.objects.get(id=submission_id)
    submission.status = 'judging'
    submission.save()
    
    # 2. 准备环境
    workspace = create_workspace()
    save_code(workspace, submission.code)
    
    # 3. 编译（如需要）
    if needs_compile(submission.language):
        result = compile_code(workspace, submission.language)
        if not result.success:
            return finish_with_CE(submission, result.error)
    
    # 4. 运行测试
    test_results = []
    for testcase in submission.problem.test_cases.all():
        result = run_testcase(
            workspace,
            testcase,
            submission.language,
            submission.problem.time_limit,
            submission.problem.memory_limit
        )
        test_results.append(result)
        
        # 遇到错误立即停止
        if result.status != 'AC':
            break
    
    # 5. 汇总结果
    final_result = summarize_results(test_results)
    
    # 6. 更新数据库
    submission.status = 'finished'
    submission.result = final_result.status
    submission.time_used = final_result.max_time
    submission.memory_used = final_result.max_memory
    submission.test_cases_passed = final_result.passed_count
    submission.judge_detail = final_result.details
    submission.judged_at = timezone.now()
    submission.save()
    
    # 7. 更新统计
    update_user_stats(submission.user, submission.problem)
    update_problem_stats(submission.problem)
    
    # 8. 清理
    cleanup_workspace(workspace)
    
    return final_result
```

### 编译函数
```python
def compile_code(workspace, language):
    config = get_language_config(language)
    
    container = docker_client.containers.run(
        image=config.docker_image,
        command=config.compile_command,
        volumes={workspace: {'bind': '/workspace', 'mode': 'rw'}},
        **security_config,
        detach=True
    )
    
    try:
        result = container.wait(timeout=30)
        logs = container.logs().decode('utf-8')
        
        if result['StatusCode'] == 0:
            return {'success': True}
        else:
            return {'success': False, 'error': logs}
    finally:
        container.remove(force=True)
```

### 运行函数
```python
def run_testcase(workspace, testcase, language, time_limit, memory_limit):
    config = get_language_config(language)
    
    container = docker_client.containers.run(
        image=config.docker_image,
        command=config.run_command,
        stdin_open=True,
        mem_limit=f'{memory_limit}m',
        cpu_quota=time_limit * 1000,
        **security_config,
        detach=True
    )
    
    try:
        # 输入测试数据
        socket = container.attach_socket(params={'stdin': 1, 'stream': 1})
        socket._sock.sendall(testcase.input_data.encode())
        socket.close()
        
        # 等待运行
        start = time.time()
        result = container.wait(timeout=time_limit / 1000 + 1)
        elapsed = int((time.time() - start) * 1000)
        
        # 获取输出
        output = container.logs(stdout=True, stderr=False).decode()
        
        # 比对答案
        if result['StatusCode'] != 0:
            return {'status': 'RE', 'time': elapsed}
        
        if compare_output(output, testcase.output_data):
            return {'status': 'AC', 'time': elapsed}
        else:
            return {'status': 'WA', 'time': elapsed, 'output': output}
    
    except TimeoutError:
        return {'status': 'TLE'}
    
    finally:
        container.remove(force=True)
```

### 输出比对
```python
def compare_output(user_output, expected_output):
    """比对输出（忽略行尾空格）"""
    
    def normalize(text):
        lines = text.strip().split('\n')
        lines = [line.rstrip() for line in lines]
        lines = [line for line in lines if line]
        return '\n'.join(lines)
    
    return normalize(user_output) == normalize(expected_output)
```

---

## 📦 依赖安装

### requirements-judge.txt
```txt
django==4.2.5
djangorestframework==3.14.0
celery==5.3.4
redis==5.0.0
docker==6.1.3
psycopg2-binary==2.9.9
```

### 安装命令
```bash
pip install -r requirements-judge.txt
```

---

## 🐳 Docker镜像构建

### Python判题镜像
```dockerfile
FROM python:3.10-slim

RUN useradd -u 10001 -m judger && \
    mkdir /workspace && \
    chown judger:judger /workspace

WORKDIR /workspace
USER judger
```

构建：
```bash
docker build -t oj-judge-python:latest -f Dockerfile.python .
```

### C++判题镜像
```dockerfile
FROM gcc:11-slim

RUN useradd -u 10001 -m judger && \
    mkdir /workspace && \
    chown judger:judger /workspace

WORKDIR /workspace
USER judger
```

构建：
```bash
docker build -t oj-judge-cpp:latest -f Dockerfile.cpp .
```

---

## 🧪 测试用例

### 测试Fork炸弹
```c
// fork_bomb.c
#include <unistd.h>
int main() {
    while(1) fork();
}
```
**预期**: `RE` (pids_limit)

### 测试内存炸弹
```python
# memory_bomb.py
a = [0] * (10 ** 9)
```
**预期**: `MLE`

### 测试无限循环
```python
# infinite_loop.py
while True: pass
```
**预期**: `TLE`

### 测试网络访问
```python
# network_test.py
import socket
socket.socket().connect(('8.8.8.8', 80))
```
**预期**: `RE` (网络禁用)

---

## 📊 性能指标

### 目标
- 容器启动: <500ms
- 编译耗时: <5s
- 单测试运行: 10-100ms
- 判题总耗时: <2s（不含程序运行时间）
- 并发能力: 50-100

### 监控
```python
# Prometheus指标
judge_queue_length              # 队列长度
judge_duration_seconds          # 判题耗时
judge_rate                      # 判题速率
submissions_by_result{result}   # 各状态计数
```

---

## 🔧 Celery配置

### settings.py
```python
# Celery配置
CELERY_BROKER_URL = 'redis://localhost:6379/0'
CELERY_RESULT_BACKEND = 'redis://localhost:6379/0'
CELERY_ACCEPT_CONTENT = ['json']
CELERY_TASK_SERIALIZER = 'json'
CELERY_RESULT_SERIALIZER = 'json'
CELERY_TIMEZONE = 'Asia/Shanghai'
```

### celery.py
```python
from celery import Celery

app = Celery('oj')
app.config_from_object('django.conf:settings', namespace='CELERY')
app.autodiscover_tasks()
```

### tasks.py
```python
from celery import shared_task

@shared_task
def judge_submission(submission_id):
    # 判题逻辑
    pass
```

### 启动Worker
```bash
celery -A config worker -l info -c 4
```

---

## 🚀 部署清单

### 1. 安装依赖
```bash
pip install -r requirements-judge.txt
```

### 2. 构建镜像
```bash
docker build -t oj-judge-python:latest -f Dockerfile.python .
docker build -t oj-judge-cpp:latest -f Dockerfile.cpp .
docker build -t oj-judge-java:latest -f Dockerfile.java .
```

### 3. 启动Redis
```bash
docker run -d -p 6379:6379 redis:7-alpine
```

### 4. 运行迁移
```bash
python manage.py makemigrations
python manage.py migrate
```

### 5. 启动Celery
```bash
celery -A config worker -l info
```

### 6. 启动Web
```bash
python manage.py runserver
```

---

## 📝 常见问题

### Q1: 容器启动慢？
**A**: 使用容器池预热，提前创建10个容器待命。

### Q2: 内存不够？
**A**: 限制并发数，或增加服务器内存。

### Q3: 判题结果不准确？
**A**: 检查输出比对逻辑，考虑忽略行尾空格和空行。

### Q4: 如何支持Special Judge?
**A**: 实现自定义比对器，传入用户输出、标准输出、输入数据。

### Q5: 如何防止作弊？
**A**: 
- 代码相似度检测
- 限制提交频率
- 随机化测试用例顺序
- 隐藏测试用例

---

## 📚 下一步

1. 阅读完整设计: `JUDGE-SYSTEM-DESIGN.md`
2. 沙箱技术对比: `SANDBOX-COMPARISON.md`
3. 开始实现:
   - [ ] 创建Submission模型
   - [ ] 实现基本判题逻辑
   - [ ] 配置Docker沙箱
   - [ ] 集成Celery队列
   - [ ] 测试安全性

---

**快速参考 v1.0** | 2024-10-01
