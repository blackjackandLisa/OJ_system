# 判题系统 Phase 1 完成报告

## ✅ 已完成功能

### 1. Judge应用创建 ✓

**位置**: `apps/judge/`

**包含文件**:
- `models.py` - 数据模型
- `serializers.py` - API序列化器
- `views.py` - 视图和API
- `admin.py` - 管理后台
- `urls.py` - URL配置

---

### 2. 数据库模型 ✓

#### 2.1 Language (编程语言配置)

```python
class Language(models.Model):
    name = CharField              # python, cpp
    display_name = CharField      # Python 3.10, C++ 17
    compile_command = TextField   # 编译命令
    run_command = TextField       # 运行命令
    template = TextField          # 代码模板
    docker_image = CharField      # Docker镜像
    file_extension = CharField    # .py, .cpp
    is_active = BooleanField
    order = IntegerField
```

**已配置语言**:
- ✅ Python 3.10
- ✅ C++ 17

#### 2.2 Submission (提交记录)

```python
class Submission(models.Model):
    # 基本信息
    user = FK(User)
    problem = FK(Problem)
    language = FK(Language)
    code = TextField
    code_length = IntegerField
    
    # 判题状态
    status = CharField  # pending/judging/finished/error
    result = CharField  # AC/WA/TLE/MLE/RE/CE/SE/PE/OLE
    
    # 运行结果
    score = IntegerField
    time_used = IntegerField     # ms
    memory_used = IntegerField   # KB
    test_cases_passed = IntegerField
    test_cases_total = IntegerField
    
    # 错误信息
    compile_error = TextField
    runtime_error = TextField
    error_testcase = IntegerField
    
    # 详情
    judge_detail = JSONField
    
    # 时间
    created_at = DateTimeField
    judged_at = DateTimeField
```

#### 2.3 JudgeServer (判题服务器)

```python
class JudgeServer(models.Model):
    hostname = CharField
    ip_address = GenericIPAddressField
    is_active = BooleanField
    cpu_usage = FloatField
    memory_usage = FloatField
    task_count = IntegerField
    max_tasks = IntegerField
```

---

### 3. API接口 ✓

#### 3.1 语言相关

```http
GET /judge/api/languages/
获取支持的编程语言列表

Response:
[
  {
    "id": 1,
    "name": "python",
    "display_name": "Python 3.10",
    "template": "# Python 3.10\n...",
    "file_extension": ".py",
    "is_active": true,
    "order": 1
  },
  {
    "id": 2,
    "name": "cpp",
    "display_name": "C++ 17",
    "template": "// C++ 17\n...",
    "file_extension": ".cpp",
    "is_active": true,
    "order": 2
  }
]
```

#### 3.2 提交相关

**1. 创建提交**
```http
POST /judge/api/submissions/
Authorization: Bearer <token>
Content-Type: application/json

{
  "problem_id": 1,
  "language_name": "python",
  "code": "print('Hello')"
}

Response: 201 Created
{
  "id": 12345,
  "status": "pending",
  "message": "提交成功，正在判题..."
}
```

**2. 查询提交列表**
```http
GET /judge/api/submissions/
GET /judge/api/submissions/?problem=1
GET /judge/api/submissions/?result=AC
GET /judge/api/submissions/?user__username=student01
```

**3. 查询提交详情**
```http
GET /judge/api/submissions/12345/

Response:
{
  "id": 12345,
  "username": "student01",
  "problem_id": 1,
  "problem_title": "A+B Problem",
  "language_name": "Python 3.10",
  "status": "finished",
  "result": "AC",
  "result_color": "success",
  "result_icon": "fa-check-circle",
  "score": 100,
  "total_score": 100,
  "pass_rate": 100.0,
  "time_used": 15,
  "memory_used": 2048,
  "test_cases_passed": 10,
  "test_cases_total": 10,
  "created_at": "2024-10-01T12:00:00Z",
  "judged_at": "2024-10-01T12:00:02Z",
  "judge_time": 2.0
}
```

**4. 查看代码（需要权限）**
```http
GET /judge/api/submissions/12345/code/
Authorization: Bearer <token>

Response:
{
  "id": 12345,
  "code": "print('Hello')",
  "language_name": "Python 3.10",
  "code_length": 14,
  "created_at": "2024-10-01T12:00:00Z"
}
```

**权限规则**:
- 提交者本人可查看
- 老师可查看所有
- 管理员可查看所有

**5. 我的提交**
```http
GET /judge/api/submissions/my_submissions/
Authorization: Bearer <token>
```

**6. 提交统计**
```http
GET /judge/api/submissions/statistics/

Response:
{
  "total": 1500,
  "accepted": 800,
  "ac_rate": 53.33,
  "result_stats": [
    {"result": "AC", "count": 800},
    {"result": "WA", "count": 400},
    {"result": "TLE", "count": 200},
    {"result": "RE", "count": 100}
  ],
  "language_stats": [
    {"language__display_name": "Python 3.10", "count": 900},
    {"language__display_name": "C++ 17", "count": 600}
  ]
}
```

---

### 4. 管理后台 ✓

#### 4.1 Language管理

**功能**:
- ✅ 列表展示（名称、显示名、扩展名、镜像、状态）
- ✅ 筛选（是否启用）
- ✅ 搜索（名称、显示名）
- ✅ 排序
- ✅ 创建/编辑/删除

**访问**: `/admin/judge/language/`

#### 4.2 Submission管理

**功能**:
- ✅ 列表展示（ID、用户、题目、语言、状态、结果、得分、时间/内存）
- ✅ 状态徽章（彩色标签）
- ✅ 结果徽章（AC绿色、WA红色、TLE黄色等）
- ✅ 筛选（状态、结果、语言、时间）
- ✅ 搜索（用户名、题目、IP）
- ✅ 只读字段（防止手动修改）
- ✅ 代码折叠显示
- ✅ 判题详情JSON

**访问**: `/admin/judge/submission/`

#### 4.3 JudgeServer管理

**功能**:
- ✅ 服务器列表
- ✅ 在线状态显示
- ✅ 负载百分比（进度条）
- ✅ 心跳监控

**访问**: `/admin/judge/judgeserver/`

---

### 5. 数据验证 ✓

#### 提交验证规则

```python
# 1. 题目验证
- 题目必须存在
- 题目必须已发布（status='published'）

# 2. 语言验证
- 语言必须存在
- 语言必须启用（is_active=True）
- 只支持：python, cpp

# 3. 代码验证
- 代码不能为空
- 代码长度 <= 100KB

# 4. 权限验证
- 提交：需要登录
- 查看代码：提交者本人/老师/管理员
- 查看列表：公开提交所有人可见，非公开只有本人可见
```

---

## 📊 数据库迁移

已创建的迁移文件：
```
apps/judge/migrations/0001_initial.py
  - Create model JudgeServer
  - Create model Language
  - Create model Submission
```

**数据库表**:
- `languages` - 编程语言配置
- `submissions` - 提交记录
- `judge_servers` - 判题服务器

**索引**:
```sql
-- submissions表
CREATE INDEX idx_user_problem ON submissions(user_id, problem_id);
CREATE INDEX idx_problem_result ON submissions(problem_id, result);
CREATE INDEX idx_status_created ON submissions(status, created_at);
CREATE INDEX idx_user_result_created ON submissions(user_id, result, created_at);
```

---

## 🎯 语言配置详情

### Python 3.10

```python
{
  "name": "python",
  "display_name": "Python 3.10",
  "compile_command": "python3 -m py_compile {src}",
  "compile_timeout": 10,
  "run_command": "python3 {src}",
  "docker_image": "python:3.10-slim",
  "file_extension": ".py",
  "template": """# Python 3.10
# 请在下方编写代码

def main():
    # 从标准输入读取数据
    # 示例：读取两个整数
    # a, b = map(int, input().split())
    # print(a + b)
    pass

if __name__ == '__main__':
    main()
"""
}
```

### C++ 17

```python
{
  "name": "cpp",
  "display_name": "C++ 17",
  "compile_command": "g++ -std=c++17 -O2 -Wall -o {exe} {src}",
  "compile_timeout": 30,
  "run_command": "{exe}",
  "docker_image": "gcc:11-slim",
  "file_extension": ".cpp",
  "template": """// C++ 17
// 请在下方编写代码

#include <iostream>
using namespace std;

int main() {
    // 从标准输入读取数据
    // 示例：读取两个整数
    // int a, b;
    // cin >> a >> b;
    // cout << a + b << endl;
    
    return 0;
}
"""
}
```

---

## 🧪 测试API

### 1. 获取语言列表

```bash
curl -X GET http://localhost:8000/judge/api/languages/
```

### 2. 提交代码

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

### 3. 查询提交

```bash
# 查询所有提交
curl -X GET http://localhost:8000/judge/api/submissions/

# 查询指定题目的提交
curl -X GET "http://localhost:8000/judge/api/submissions/?problem=1"

# 查询AC的提交
curl -X GET "http://localhost:8000/judge/api/submissions/?result=AC"

# 查询我的提交
curl -X GET http://localhost:8000/judge/api/submissions/my_submissions/ \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 4. 查看代码

```bash
curl -X GET http://localhost:8000/judge/api/submissions/1/code/ \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## 📂 文件结构

```
apps/judge/
├── __init__.py
├── apps.py
├── models.py                    # 3个模型
├── serializers.py               # 5个序列化器
├── views.py                     # 2个ViewSet
├── admin.py                     # 3个Admin类
├── urls.py                      # URL配置
├── migrations/
│   ├── __init__.py
│   └── 0001_initial.py         # 初始迁移
└── management/
    └── commands/
        └── init_languages.py   # 语言初始化命令
```

---

## ⚙️ 配置变更

### config/settings.py
```python
LOCAL_APPS = [
    'apps.core',
    'apps.problems',
    'apps.users',
    'apps.judge',  # ✅ 新增
]
```

### config/urls.py
```python
urlpatterns = [
    path('admin/', admin.site.urls),
    path('users/', include('apps.users.urls')),
    path('problems/', include('apps.problems.urls')),
    path('judge/', include('apps.judge.urls')),  # ✅ 新增
    path('', include('apps.core.urls')),
]
```

---

## 🚀 已实现功能清单

- [x] Judge应用创建
- [x] Language模型（编程语言配置）
- [x] Submission模型（提交记录）
- [x] JudgeServer模型（判题服务器）
- [x] Language序列化器
- [x] Submission序列化器（列表/详情/代码/创建）
- [x] LanguageViewSet（只读API）
- [x] SubmissionViewSet（完整CRUD）
- [x] 提交验证（题目/语言/代码/权限）
- [x] 代码查看权限控制
- [x] 我的提交API
- [x] 提交统计API
- [x] 管理后台配置
- [x] 状态和结果徽章
- [x] URL配置
- [x] 数据库迁移
- [x] Python 3.10语言配置
- [x] C++ 17语言配置
- [x] 语言初始化命令

---

## ⏭️ 下一步：Phase 2

### 待实现功能

1. **基础判题逻辑** 🔧
   - [ ] 创建判题核心模块
   - [ ] 实现代码编译
   - [ ] 实现代码运行
   - [ ] 实现输出比对
   - [ ] 同步判题（不用队列）

2. **Docker沙箱** 🐳
   - [ ] 创建Python判题镜像
   - [ ] 创建C++判题镜像
   - [ ] 配置资源限制
   - [ ] 测试沙箱安全性

3. **前端集成** 🎨
   - [ ] 代码提交页面
   - [ ] 提交历史页面
   - [ ] 代码查看页面
   - [ ] 实时状态更新

4. **测试** 🧪
   - [ ] 简单Python程序测试
   - [ ] 简单C++程序测试
   - [ ] 错误处理测试

---

## 📝 使用说明

### 初始化语言配置

```bash
python manage.py init_languages
```

### 访问管理后台

1. 访问: `http://localhost:8000/admin/`
2. 导航到: 判题系统
3. 可管理：
   - 编程语言
   - 提交记录
   - 判题服务器

### 查看已配置语言

进入Django shell:
```bash
python manage.py shell
```

```python
from apps.judge.models import Language

# 查看所有语言
for lang in Language.objects.filter(is_active=True):
    print(f"{lang.display_name} ({lang.name})")

# 输出:
# Python 3.10 (python)
# C++ 17 (cpp)
```

---

## 🎉 Phase 1 总结

✅ **已完成**: 基础架构搭建  
✅ **数据模型**: 3个核心模型  
✅ **API接口**: 8个主要接口  
✅ **管理后台**: 完整的Admin配置  
✅ **语言支持**: Python 3.10 + C++ 17  

**代码统计**:
- 模型代码: ~350行
- 序列化器: ~180行
- 视图: ~150行
- 管理后台: ~250行
- **总计**: ~930行核心代码

**下一步**: 实现判题核心逻辑和Docker沙箱！

---

**Phase 1 完成时间**: 2024-10-01  
**版本**: v0.1.0
