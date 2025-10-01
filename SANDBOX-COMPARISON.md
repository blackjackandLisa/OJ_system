# 安全沙箱技术选型对比

## 📊 常见沙箱技术对比

### 1. Docker容器（推荐✅）

**优点**：
- ✅ 完整的命名空间隔离（PID、Network、Mount、UTS、IPC、User）
- ✅ cgroups资源限制（CPU、内存、IO、进程数）
- ✅ 成熟的生态系统和工具链
- ✅ 易于部署和管理
- ✅ 支持自定义镜像
- ✅ 良好的文档和社区支持
- ✅ 可配合Seccomp、AppArmor增强安全

**缺点**：
- ❌ 容器启动有开销（约100-500ms）
- ❌ 需要Docker守护进程
- ❌ 不如虚拟机隔离彻底

**性能**：
- 启动时间：200-500ms
- 内存开销：10-50MB
- CPU开销：<5%

**使用场景**：
- 中小型OJ系统
- 对性能要求不极端
- 需要支持多语言

**安全等级**: ⭐⭐⭐⭐☆ (4/5)

---

### 2. LXC（Linux Containers）

**优点**：
- ✅ 轻量级容器
- ✅ 接近原生性能
- ✅ 资源隔离完善

**缺点**：
- ❌ 配置复杂
- ❌ 生态不如Docker
- ❌ 管理工具较少

**性能**：
- 启动时间：100-300ms
- 内存开销：5-20MB

**使用场景**：
- 对性能要求极高
- 团队有LXC经验

**安全等级**: ⭐⭐⭐⭐☆ (4/5)

---

### 3. Cgroups + Namespace（原生Linux）

**优点**：
- ✅ 最轻量
- ✅ 最快速
- ✅ 完全可控

**缺点**：
- ❌ 需要手动配置所有隔离
- ❌ 代码复杂度高
- ❌ 维护困难

**性能**：
- 启动时间：<50ms
- 内存开销：<5MB

**使用场景**：
- 超大规模OJ（如Codeforces）
- 有专业团队维护
- 对性能要求极致

**安全等级**: ⭐⭐⭐⭐⭐ (5/5，如果配置正确)

---

### 4. ptrace（如Python的sandbox库）

**优点**：
- ✅ 轻量级
- ✅ 易于实现

**缺点**：
- ❌ 性能开销大（追踪每个系统调用）
- ❌ 容易被绕过
- ❌ 不适合生产环境

**性能**：
- 启动时间：<10ms
- CPU开销：20-50%（追踪开销）

**使用场景**：
- 教学演示
- 原型开发

**安全等级**: ⭐⭐☆☆☆ (2/5)

---

### 5. QEMU/KVM虚拟机

**优点**：
- ✅ 最强隔离
- ✅ 完全独立的内核

**缺点**：
- ❌ 启动慢（秒级）
- ❌ 资源开销大
- ❌ 不适合高并发

**性能**：
- 启动时间：2-10秒
- 内存开销：100-500MB

**使用场景**：
- 极高安全要求
- 低并发场景

**安全等级**: ⭐⭐⭐⭐⭐ (5/5)

---

### 6. WebAssembly (WASM)

**优点**：
- ✅ 浏览器内运行
- ✅ 天然安全隔离
- ✅ 跨平台

**缺点**：
- ❌ 语言支持有限
- ❌ 不支持传统系统调用
- ❌ 生态不成熟

**性能**：
- 启动时间：<50ms
- 接近原生性能

**使用场景**：
- 在线IDE
- 前端评测

**安全等级**: ⭐⭐⭐⭐⭐ (5/5)

---

## 🎯 推荐方案

### 方案A: Docker + Seccomp + cgroups（推荐）

**适用场景**：
- 中小型OJ（<10万用户）
- 多语言支持
- 快速开发部署

**技术栈**：
```
Docker 20.10+
Seccomp-BPF
cgroups v2
Python Docker SDK
```

**实现难度**: ⭐⭐☆☆☆ (2/5)  
**维护成本**: ⭐⭐☆☆☆ (2/5)  
**安全性**: ⭐⭐⭐⭐☆ (4/5)  
**性能**: ⭐⭐⭐⭐☆ (4/5)

**容器配置示例**：
```python
import docker

client = docker.from_env()

container = client.containers.run(
    image='oj-judge-python:latest',
    command='python3 /workspace/main.py',
    detach=True,
    remove=True,
    
    # 资源限制
    mem_limit='256m',
    memswap_limit='256m',
    cpu_period=100000,
    cpu_quota=100000,
    pids_limit=50,
    
    # 网络隔离
    network_mode='none',
    
    # 文件系统
    read_only=True,
    tmpfs={'/workspace': 'size=10m,uid=10001'},
    
    # 安全配置
    security_opt=[
        'no-new-privileges',
        'seccomp=/etc/docker/seccomp-oj.json'
    ],
    cap_drop=['ALL'],
    
    # 用户
    user='10001:10001',
    
    # 超时
    ulimits=[
        docker.types.Ulimit(name='cpu', soft=2, hard=2)
    ]
)
```

---

### 方案B: 自研沙箱（高级）

**适用场景**：
- 大型OJ（>100万用户）
- 对性能要求极致
- 有专业安全团队

**技术栈**：
```
cgroups v2
Linux namespaces (手动创建)
Seccomp-BPF (自定义规则)
C/C++实现核心判题器
```

**实现难度**: ⭐⭐⭐⭐⭐ (5/5)  
**维护成本**: ⭐⭐⭐⭐⭐ (5/5)  
**安全性**: ⭐⭐⭐⭐⭐ (5/5)  
**性能**: ⭐⭐⭐⭐⭐ (5/5)

**参考项目**：
- HUSTOJ judger
- QDUOJ Judger
- Themis Judge Core

---

## 🔒 安全加固最佳实践

### 1. Docker沙箱安全检查清单

```bash
# 1. 使用非特权用户
USER 10001:10001

# 2. 只读根文件系统
--read-only

# 3. 禁用网络
--network none

# 4. 限制资源
--memory 256m
--memory-swap 256m
--cpus 1.0
--pids-limit 50

# 5. 删除所有capabilities
--cap-drop ALL

# 6. Seccomp配置
--security-opt seccomp=/path/to/seccomp.json

# 7. 禁用新权限
--security-opt no-new-privileges

# 8. AppArmor/SELinux
--security-opt apparmor=docker-default

# 9. 临时文件系统
--tmpfs /tmp:size=10m,noexec,nodev,nosuid

# 10. 超时保护
--stop-timeout 1
```

### 2. Seccomp白名单（最小化）

```json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "architectures": ["SCMP_ARCH_X86_64"],
  "syscalls": [
    {
      "names": [
        "read", "write", "open", "openat", "close",
        "stat", "fstat", "lstat", "poll", "lseek",
        "mmap", "mprotect", "munmap", "brk",
        "rt_sigaction", "rt_sigprocmask", "rt_sigreturn",
        "access", "pipe", "select", "dup", "dup2",
        "getpid", "getuid", "getgid", "geteuid", "getegid",
        "exit", "exit_group", "wait4", "waitid",
        "fcntl", "getcwd", "readlink",
        "arch_prctl", "futex", "set_tid_address",
        "getdents", "getdents64",
        "clock_gettime", "gettimeofday"
      ],
      "action": "SCMP_ACT_ALLOW"
    },
    {
      "names": ["clone"],
      "action": "SCMP_ACT_ALLOW",
      "args": [
        {
          "index": 0,
          "value": 2114060288,
          "op": "SCMP_CMP_MASKED_EQ"
        }
      ]
    }
  ]
}
```

**禁止的危险系统调用**：
- `execve`: 防止执行其他程序
- `fork`: 控制在clone参数中
- `socket`, `connect`: 禁止网络
- `mount`, `umount`: 禁止挂载
- `reboot`, `shutdown`: 禁止关机
- `ptrace`: 禁止调试
- `chroot`: 禁止改变根目录

### 3. cgroups限制配置

```bash
# CPU限制（1秒 = 1核）
cpu.cfs_period_us=100000
cpu.cfs_quota_us=100000  # 100% = 1核

# 内存限制
memory.limit_in_bytes=268435456  # 256MB
memory.memsw.limit_in_bytes=268435456  # 禁用swap

# 进程数限制
pids.max=50

# IO限制
blkio.weight=500
```

### 4. 文件系统隔离

```python
# 只读挂载
volumes = {
    '/etc/passwd': {'bind': '/etc/passwd', 'mode': 'ro'},
    '/etc/group': {'bind': '/etc/group', 'mode': 'ro'},
}

# 临时目录（限制大小）
tmpfs = {
    '/workspace': 'size=10m,uid=10001,gid=10001,mode=0755',
    '/tmp': 'size=5m,noexec,nodev,nosuid'
}
```

---

## 🧪 安全测试用例

### 测试1: Fork炸弹

```c
// fork_bomb.c
#include <unistd.h>
int main() {
    while(1) fork();
}
```

**预期结果**: `RE` (达到pids_limit)

### 测试2: 内存炸弹

```python
# memory_bomb.py
a = [0] * (10 ** 9)
```

**预期结果**: `MLE` (超过memory_limit)

### 测试3: 无限循环

```python
# infinite_loop.py
while True:
    pass
```

**预期结果**: `TLE` (超过time_limit)

### 测试4: 网络访问

```python
# network_test.py
import socket
s = socket.socket()
s.connect(('google.com', 80))
```

**预期结果**: `RE` (网络被禁用)

### 测试5: 文件访问

```python
# file_access.py
with open('/etc/passwd', 'r') as f:
    print(f.read())
```

**预期结果**: `RE` (只读文件系统或被seccomp阻止)

### 测试6: 输出炸弹

```python
# output_bomb.py
while True:
    print('A' * 100000)
```

**预期结果**: `OLE` (输出超限)

---

## 📈 性能基准测试

### 测试环境
- CPU: Intel Xeon 8核
- RAM: 16GB
- OS: Ubuntu 22.04
- Docker: 24.0

### 测试结果

| 操作 | 耗时 | 备注 |
|------|------|------|
| 容器创建 | 200ms | 首次启动 |
| 容器创建（热） | 50ms | 镜像已缓存 |
| Python程序启动 | 80ms | 解释器加载 |
| C++程序启动 | 5ms | 编译后二进制 |
| 编译C++程序 | 500ms | 单文件 |
| 编译Java程序 | 800ms | 单类 |
| 测试用例运行 | 10-100ms | 取决于程序 |

### 并发测试

| 并发数 | 平均响应时间 | CPU使用率 | 内存使用 |
|--------|-------------|----------|----------|
| 10 | 1.2s | 40% | 2GB |
| 50 | 2.5s | 80% | 8GB |
| 100 | 5.0s | 95% | 14GB |
| 200 | 队列等待 | 100% | 16GB |

**结论**: 
- 单机可支持50-100并发判题
- 需要队列系统避免过载
- 建议使用容器池预热

---

## 🚀 优化建议

### 1. 容器池预热

```python
class ContainerPool:
    """容器池，预先创建容器"""
    
    def __init__(self, size=10):
        self.pool = []
        self.size = size
        self.warm_up()
    
    def warm_up(self):
        """预热容器池"""
        for i in range(self.size):
            container = create_sandbox_container()
            self.pool.append(container)
    
    def get_container(self):
        """获取可用容器"""
        if self.pool:
            return self.pool.pop()
        else:
            return create_sandbox_container()
    
    def return_container(self, container):
        """归还容器"""
        # 清理容器
        container.exec_run('rm -rf /workspace/*')
        self.pool.append(container)
```

### 2. 镜像优化

```dockerfile
# 使用Alpine减小镜像大小
FROM python:3.10-alpine

# 多阶段构建
FROM gcc:11 AS builder
COPY code.cpp .
RUN g++ -O2 code.cpp -o main

FROM alpine:3.18
COPY --from=builder /main /
CMD ["/main"]
```

### 3. 测试用例缓存

```python
from functools import lru_cache

@lru_cache(maxsize=1000)
def get_testcase(problem_id, testcase_id):
    """缓存测试用例"""
    return TestCase.objects.get(
        problem_id=problem_id,
        id=testcase_id
    )
```

### 4. 结果推送

```python
# 使用WebSocket实时推送结果
from channels.layers import get_channel_layer

async def push_judge_result(user_id, submission_id, result):
    channel_layer = get_channel_layer()
    await channel_layer.group_send(
        f'user_{user_id}',
        {
            'type': 'judge_result',
            'submission_id': submission_id,
            'result': result
        }
    )
```

---

## 📚 参考资料

### 开源OJ判题器

1. **QDUOJ Judger** (推荐)
   - 语言: C/Python
   - 特点: 高性能，安全
   - GitHub: https://github.com/QingdaoU/Judger

2. **HUSTOJ Judge_client**
   - 语言: C++
   - 特点: 成熟稳定
   - 适合: 学习参考

3. **Vnoj Judge**
   - 语言: Python
   - 特点: 易于理解
   - 适合: 快速开发

### 技术文档

- Docker安全最佳实践: https://docs.docker.com/engine/security/
- Seccomp Profile: https://docs.docker.com/engine/security/seccomp/
- cgroups v2: https://www.kernel.org/doc/html/latest/admin-guide/cgroup-v2.html
- Linux Namespaces: https://man7.org/linux/man-pages/man7/namespaces.7.html

---

## 🎯 总结

### 最终推荐

**对于本项目（教学型OJ）**：

✅ **推荐使用**: Docker + Seccomp + cgroups

**理由**：
1. 平衡安全性和实现难度
2. 良好的生态和工具支持
3. 易于部署和维护
4. 性能足够（<100ms启动）
5. 团队容易上手

**实施步骤**：
1. 创建判题Docker镜像（C/C++/Python/Java）
2. 配置Seccomp白名单
3. 实现判题Worker
4. 集成Celery任务队列
5. 安全测试
6. 性能调优

---

**文档版本**: v1.0  
**最后更新**: 2024-10-01
