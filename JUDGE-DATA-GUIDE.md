# 判题系统数据配置指南

## 📋 问题说明

### 问题1: 题目页面看不到样例输入输出

**原因**: 题目缺少**公开样例（ProblemSample）**

**解决**: 为题目添加样例数据

### 问题2: 后台显示"0个判题服务器"

**说明**: 当前架构**不需要判题服务器（JudgeServer）模型**

- 当前判题方式：直接调用Docker容器执行判题
- JudgeServer模型是为未来分布式判题架构预留的
- 不影响当前判题功能

---

## 🔍 数据模型说明

### 1. ProblemSample（题目样例）

**用途**: 在题目详情页**公开展示**给用户看

**字段**:
- `input_data`: 样例输入
- `output_data`: 样例输出
- `explanation`: 样例说明
- `order`: 排序

**示例**:
```
样例1:
输入: 1 2
输出: 3
说明: 1 + 2 = 3
```

### 2. TestCase（测试用例）

**用途**: 判题时使用，**不公开**

**字段**:
- `input_data`: 测试输入
- `output_data`: 期望输出
- `score`: 分数
- `order`: 排序

**示例**:
```
测试用例1:
输入: 1 2\n
输出: 3\n
分数: 10
```

### 3. JudgeServer（判题服务器）

**用途**: 分布式判题架构（当前未使用）

**当前架构**: 直接使用Docker，无需配置

---

## 🚀 快速修复

### 方法1: 使用自动化脚本（推荐）

```bash
# 在Linux服务器上执行
cd /path/to/OJ_system

# 赋予执行权限
chmod +x fix-judge-data.sh

# 运行脚本
./fix-judge-data.sh
```

**脚本会自动**:
- ✅ 检查A+B Problem是否存在
- ✅ 创建2个公开样例（前端显示）
- ✅ 创建5个测试用例（判题使用）
- ✅ 显示数据总结

### 方法2: 手动添加（Django Admin）

#### 添加公开样例

1. 访问 Django Admin:
   ```
   http://your-server-ip:8000/admin/
   ```

2. 进入题目管理:
   ```
   题目管理 → 题目 → 选择题目
   ```

3. 滚动到"题目样例"区域

4. 点击"添加另一个题目样例"

5. 填写样例数据:
   ```
   样例1:
   输入数据: 1 2
   输出数据: 3
   样例说明: 1 + 2 = 3
   排序: 0
   
   样例2:
   输入数据: 10 20
   输出数据: 30
   样例说明: 10 + 20 = 30
   排序: 1
   ```

6. 保存

#### 添加测试用例

1. 在题目详情页滚动到"测试用例"区域

2. 点击"添加另一个测试用例"

3. 填写测试用例:
   ```
   测试用例1:
   输入数据: 1 2
   (换行)
   输出数据: 3
   (换行)
   分数: 10
   排序: 0
   是否为样例: 否
   
   测试用例2:
   输入数据: 10 20
   (换行)
   输出数据: 30
   (换行)
   分数: 10
   排序: 1
   是否为样例: 否
   
   ...以此类推
   ```

4. 保存

### 方法3: 使用Django Shell

```bash
python3 manage.py shell
```

执行以下代码:

```python
from apps.problems.models import Problem, ProblemSample, TestCase

# 获取题目
problem = Problem.objects.get(id=1)

# 创建公开样例
samples = [
    {'input': '1 2', 'output': '3', 'explanation': '1 + 2 = 3'},
    {'input': '10 20', 'output': '30', 'explanation': '10 + 20 = 30'}
]

for idx, sample in enumerate(samples):
    ProblemSample.objects.create(
        problem=problem,
        input_data=sample['input'],
        output_data=sample['output'],
        explanation=sample['explanation'],
        order=idx
    )

print(f"创建了 {len(samples)} 个公开样例")

# 创建测试用例
test_cases = [
    {'input': '1 2\n', 'output': '3\n'},
    {'input': '10 20\n', 'output': '30\n'},
    {'input': '-5 5\n', 'output': '0\n'},
    {'input': '100 200\n', 'output': '300\n'},
    {'input': '0 0\n', 'output': '0\n'},
]

for idx, tc in enumerate(test_cases):
    TestCase.objects.create(
        problem=problem,
        input_data=tc['input'],
        output_data=tc['output'],
        order=idx,
        score=10
    )

print(f"创建了 {len(test_cases)} 个测试用例")

exit()
```

---

## ✅ 验证修复结果

### 1. 检查数据库

```bash
python3 manage.py shell -c "
from apps.problems.models import Problem
p = Problem.objects.get(id=1)
print(f'题目: {p.title}')
print(f'公开样例: {p.samples.count()} 个')
print(f'测试用例: {p.test_cases.count()} 个')
"
```

**预期输出**:
```
题目: A+B Problem
公开样例: 2 个
测试用例: 5 个
```

### 2. 检查前端显示

访问题目详情页:
```
http://your-server-ip:8000/problems/1/
```

**应该看到**:
- ✅ 题目描述
- ✅ 输入格式
- ✅ 输出格式
- ✅ **样例输入输出**（之前是空的）

### 3. 测试判题功能

访问提交页面:
```
http://your-server-ip:8000/problems/1/submit/
```

提交测试代码:
```python
a, b = map(int, input().split())
print(a + b)
```

**预期结果**: `AC (Accepted)` ✅

---

## 🔧 关于判题服务器

### 当前架构（Phase 2）

```
用户提交代码
    ↓
Django API
    ↓
后台线程
    ↓
直接调用 Docker 容器判题
    ↓
返回结果
```

**不需要**配置 JudgeServer 模型。

### 未来架构（Phase 3）

如果需要分布式判题（多台判题服务器），才需要配置 JudgeServer：

```
用户提交代码
    ↓
Django API
    ↓
Celery 异步任务队列
    ↓
负载均衡选择判题服务器
    ↓
远程判题服务器执行
    ↓
返回结果
```

**届时配置方法**:

```python
# 在Django Shell中
from apps.judge.models import JudgeServer

JudgeServer.objects.create(
    hostname='judge-server-1',
    ip_address='192.168.1.100',
    port=8080,
    is_active=True,
    max_tasks=10
)
```

但**目前不需要**。

---

## 📚 常见问题

### Q1: 公开样例和测试用例有什么区别？

| 项目 | 公开样例 | 测试用例 |
|------|---------|---------|
| **用途** | 展示给用户 | 判题使用 |
| **是否公开** | 是 | 否 |
| **数量** | 1-3个 | 多个 |
| **显示位置** | 题目详情页 | 不显示 |

### Q2: 为什么提交一直"等待中"？

可能原因：
1. ❌ 测试用例未创建 → 运行修复脚本
2. ❌ Docker未启动 → `sudo systemctl start docker`
3. ❌ 判题镜像未构建 → 重新构建镜像
4. ❌ docker-py未安装 → `pip3 install docker==7.0.0`

详见: `JUDGE-TROUBLESHOOTING.md`

### Q3: 如何创建新题目？

1. **在Django Admin创建题目**:
   - 填写基本信息（标题、描述等）
   - 保存

2. **添加公开样例**:
   - 在题目详情页添加2-3个样例

3. **添加测试用例**:
   - 添加5-10个测试用例
   - 设置分数（通常每个10分）

4. **发布题目**:
   - 状态改为"已发布"

### Q4: 测试用例需要注意什么？

⚠️ **重要**:
- 输入输出**必须包含换行符** `\n`
- 例如: `'1 2\n'` 而不是 `'1 2'`
- 输出也要有换行: `'3\n'` 而不是 `'3'`

**正确示例**:
```python
TestCase.objects.create(
    problem=problem,
    input_data='1 2\n',    # ✓ 正确：有换行
    output_data='3\n',     # ✓ 正确：有换行
    score=10
)
```

**错误示例**:
```python
TestCase.objects.create(
    problem=problem,
    input_data='1 2',      # ✗ 错误：缺少换行
    output_data='3',       # ✗ 错误：缺少换行
    score=10
)
```

---

## 🎯 总结

**修复步骤**:

1. ✅ 运行修复脚本: `./fix-judge-data.sh`
2. ✅ 验证数据: 检查样例和测试用例
3. ✅ 测试判题: 提交代码验证功能
4. ✅ 忽略"0个判题服务器"提示（不影响功能）

**关键点**:
- 公开样例 ≠ 测试用例
- 当前不需要配置判题服务器
- 测试用例输入输出要有换行符

---

**文档版本**: v1.0  
**更新日期**: 2024-10-02

