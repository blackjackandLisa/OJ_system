# OJ题目管理系统需求设计

## 📋 需求梳理

### 1. 核心功能需求

#### 1.1 题目信息管理
- 题目标题
- 题目描述（支持Markdown/富文本）
- 输入输出格式说明
- 样例输入输出
- 数据范围说明
- 题目提示/思路（可选）

#### 1.2 题目属性
- 难度等级（简单/中等/困难）
- 题目标签/分类（动态规划、贪心、图论等）
- 时间限制（毫秒）
- 内存限制（MB）
- 题目来源（原创/OJ平台/比赛等）
- 题目状态（草稿/发布/隐藏）

#### 1.3 测试用例管理
- 输入数据
- 期望输出
- 样例标记（是否为公开样例）
- 测试点分数（可选，用于部分分）
- 特殊判题（SPJ）支持（可选）

#### 1.4 统计信息
- 提交次数
- 通过次数
- 通过率（AC率）
- 题目难度（根据通过率动态计算）

### 2. 用户角色和权限

#### 2.1 管理员
- ✅ 创建题目
- ✅ 编辑题目
- ✅ 删除题目
- ✅ 管理测试用例
- ✅ 查看所有题目（包括草稿）

#### 2.2 普通用户
- ✅ 查看已发布的题目列表
- ✅ 查看题目详情
- ✅ 查看公开样例
- ✅ 提交代码
- ❌ 查看测试用例答案
- ❌ 编辑题目

### 3. 功能界面需求

#### 3.1 题目列表页
```
功能：
- 题目列表展示（分页）
- 筛选功能（难度、标签、状态）
- 搜索功能（题目标题）
- 排序功能（ID、难度、通过率）
- 状态标记（用户已通过/已尝试/未尝试）
```

#### 3.2 题目详情页
```
功能：
- 题目基本信息展示
- 题目描述（Markdown渲染）
- 输入输出格式
- 样例展示
- 代码编辑器
- 提交按钮
- 提交历史（当前用户）
- 题目统计信息
```

#### 3.3 题目管理页（管理员）
```
功能：
- 创建题目表单
- 编辑题目表单
- 测试用例管理
- 题目预览
- 批量导入题目
```

## 🗄️ 数据库设计

### 核心模型

#### Problem（题目表）
```python
class Problem(models.Model):
    """题目主表"""
    # 基本信息
    problem_id = AutoField(primary_key=True)
    title = CharField(max_length=200, verbose_name='题目标题')
    description = TextField(verbose_name='题目描述')
    input_format = TextField(verbose_name='输入格式')
    output_format = TextField(verbose_name='输出格式')
    hint = TextField(blank=True, verbose_name='提示')
    source = CharField(max_length=200, blank=True, verbose_name='题目来源')
    
    # 限制条件
    time_limit = IntegerField(default=1000, verbose_name='时间限制(ms)')
    memory_limit = IntegerField(default=256, verbose_name='内存限制(MB)')
    
    # 难度和分类
    difficulty = CharField(
        max_length=20,
        choices=[
            ('easy', '简单'),
            ('medium', '中等'),
            ('hard', '困难'),
        ],
        default='medium',
        verbose_name='难度'
    )
    
    # 状态
    status = CharField(
        max_length=20,
        choices=[
            ('draft', '草稿'),
            ('published', '已发布'),
            ('hidden', '已隐藏'),
        ],
        default='draft',
        verbose_name='状态'
    )
    
    # 统计信息
    total_submit = IntegerField(default=0, verbose_name='总提交数')
    total_accepted = IntegerField(default=0, verbose_name='通过数')
    
    # 创建和修改信息
    created_by = ForeignKey(User, on_delete=SET_NULL, null=True, 
                           related_name='created_problems')
    created_at = DateTimeField(auto_now_add=True)
    updated_at = DateTimeField(auto_now=True)
    
    # 其他
    is_special_judge = BooleanField(default=False, verbose_name='特殊判题')
    
    class Meta:
        db_table = 'problems'
        ordering = ['problem_id']
        indexes = [
            models.Index(fields=['difficulty']),
            models.Index(fields=['status']),
            models.Index(fields=['created_at']),
        ]
    
    @property
    def acceptance_rate(self):
        """通过率"""
        if self.total_submit == 0:
            return 0
        return round(self.total_accepted / self.total_submit * 100, 2)
```

#### ProblemTag（题目标签表）
```python
class ProblemTag(models.Model):
    """题目标签"""
    name = CharField(max_length=50, unique=True, verbose_name='标签名')
    color = CharField(max_length=20, default='blue', verbose_name='标签颜色')
    description = TextField(blank=True, verbose_name='标签描述')
    problems = ManyToManyField(Problem, related_name='tags')
    
    class Meta:
        db_table = 'problem_tags'
    
    def __str__(self):
        return self.name
```

#### TestCase（测试用例表）
```python
class TestCase(models.Model):
    """测试用例"""
    problem = ForeignKey(Problem, on_delete=CASCADE, 
                        related_name='test_cases')
    input_data = TextField(verbose_name='输入数据')
    output_data = TextField(verbose_name='输出数据')
    
    # 属性
    is_sample = BooleanField(default=False, verbose_name='是否为样例')
    score = IntegerField(default=0, verbose_name='测试点分数')
    order = IntegerField(default=0, verbose_name='排序')
    
    # 资源限制（可选，覆盖题目默认设置）
    time_limit = IntegerField(null=True, blank=True, 
                             verbose_name='时间限制(ms)')
    memory_limit = IntegerField(null=True, blank=True, 
                               verbose_name='内存限制(MB)')
    
    created_at = DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'test_cases'
        ordering = ['order', 'id']
        indexes = [
            models.Index(fields=['problem', 'is_sample']),
        ]
```

#### ProblemSample（样例表）
```python
class ProblemSample(models.Model):
    """题目样例（公开展示）"""
    problem = ForeignKey(Problem, on_delete=CASCADE, 
                        related_name='samples')
    input_data = TextField(verbose_name='样例输入')
    output_data = TextField(verbose_name='样例输出')
    explanation = TextField(blank=True, verbose_name='样例说明')
    order = IntegerField(default=0, verbose_name='排序')
    
    class Meta:
        db_table = 'problem_samples'
        ordering = ['order']
```

#### UserProblemStatus（用户题目状态表）
```python
class UserProblemStatus(models.Model):
    """用户题目状态"""
    user = ForeignKey(User, on_delete=CASCADE)
    problem = ForeignKey(Problem, on_delete=CASCADE)
    
    status = CharField(
        max_length=20,
        choices=[
            ('not_tried', '未尝试'),
            ('trying', '尝试中'),
            ('accepted', '已通过'),
        ],
        default='not_tried'
    )
    
    submit_count = IntegerField(default=0, verbose_name='提交次数')
    accepted_count = IntegerField(default=0, verbose_name='通过次数')
    first_accepted_at = DateTimeField(null=True, blank=True)
    last_submit_at = DateTimeField(null=True, blank=True)
    
    class Meta:
        db_table = 'user_problem_status'
        unique_together = [['user', 'problem']]
        indexes = [
            models.Index(fields=['user', 'status']),
        ]
```

## 🎨 API设计

### RESTful API接口

#### 题目列表
```
GET /api/problems/

参数:
  - page: 页码（默认1）
  - page_size: 每页数量（默认20）
  - difficulty: 难度筛选（easy/medium/hard）
  - tags: 标签筛选（逗号分隔）
  - search: 搜索关键词
  - status: 用户状态筛选（accepted/trying/not_tried）

响应:
{
  "count": 100,
  "next": "...",
  "previous": "...",
  "results": [
    {
      "id": 1,
      "title": "两数之和",
      "difficulty": "easy",
      "acceptance_rate": 45.2,
      "total_submit": 1000,
      "total_accepted": 452,
      "tags": ["数组", "哈希表"],
      "user_status": "accepted"  // 当前用户状态
    },
    ...
  ]
}
```

#### 题目详情
```
GET /api/problems/{id}/

响应:
{
  "id": 1,
  "title": "两数之和",
  "description": "给定一个整数数组...",
  "input_format": "第一行...",
  "output_format": "输出...",
  "hint": "可以使用...",
  "difficulty": "easy",
  "time_limit": 1000,
  "memory_limit": 256,
  "samples": [
    {
      "input": "...",
      "output": "...",
      "explanation": "..."
    }
  ],
  "tags": ["数组", "哈希表"],
  "stats": {
    "total_submit": 1000,
    "total_accepted": 452,
    "acceptance_rate": 45.2
  },
  "user_stats": {
    "status": "accepted",
    "submit_count": 3,
    "accepted_count": 1
  }
}
```

#### 创建题目（管理员）
```
POST /api/problems/

请求体:
{
  "title": "两数之和",
  "description": "...",
  "input_format": "...",
  "output_format": "...",
  "difficulty": "easy",
  "time_limit": 1000,
  "memory_limit": 256,
  "tags": [1, 2],  // 标签ID列表
  "samples": [
    {
      "input": "...",
      "output": "...",
      "explanation": "..."
    }
  ]
}

响应: 201 Created
```

#### 更新题目（管理员）
```
PUT /api/problems/{id}/
PATCH /api/problems/{id}/

请求体: 同创建题目

响应: 200 OK
```

#### 删除题目（管理员）
```
DELETE /api/problems/{id}/

响应: 204 No Content
```

#### 测试用例管理（管理员）
```
GET /api/problems/{id}/testcases/
POST /api/problems/{id}/testcases/
PUT /api/problems/{id}/testcases/{testcase_id}/
DELETE /api/problems/{id}/testcases/{testcase_id}/
```

#### 标签管理
```
GET /api/tags/
POST /api/tags/
```

## 🎨 前端页面设计

### 题目列表页面
```html
┌─────────────────────────────────────────────┐
│  OJ系统 - 题目列表                           │
├─────────────────────────────────────────────┤
│  [搜索框]  [难度▼] [标签▼] [状态▼]         │
├─────────────────────────────────────────────┤
│  ID  标题          难度   通过率  标签      │
│  ─────────────────────────────────────────  │
│  ✓ 1  两数之和     简单   45.2%  数组 哈希  │
│  ✗ 2  三数之和     中等   32.1%  数组 双指针│
│  ○ 3  四数之和     中等   28.5%  数组       │
│  ...                                         │
├─────────────────────────────────────────────┤
│  [上一页] 1 2 3 ... 10 [下一页]             │
└─────────────────────────────────────────────┘

图例:
✓ 已通过
✗ 尝试过但未通过
○ 未尝试
```

### 题目详情页面
```html
┌─────────────────────────────────────────────┐
│  ← 返回列表                                  │
├─────────────────────────────────────────────┤
│  1. 两数之和                      [简单]     │
│  标签: 数组  哈希表                          │
│  通过率: 45.2% (452/1000)                    │
├─────────────────────────────────────────────┤
│  [题目] [提交记录] [讨论]                    │
│                                              │
│  题目描述:                                   │
│  给定一个整数数组nums和一个目标值target...   │
│                                              │
│  输入格式:                                   │
│  第一行包含两个整数n和target...              │
│                                              │
│  输出格式:                                   │
│  输出两个整数...                             │
│                                              │
│  样例1:                                      │
│  输入:                                       │
│  ┌────────────┐                              │
│  │ 4 9        │                              │
│  │ 2 7 11 15  │                              │
│  └────────────┘                              │
│  输出:                                       │
│  ┌────────────┐                              │
│  │ 0 1        │                              │
│  └────────────┘                              │
│  说明: nums[0] + nums[1] = 2 + 7 = 9        │
│                                              │
│  时间限制: 1000ms  内存限制: 256MB           │
├─────────────────────────────────────────────┤
│  代码编辑器                                  │
│  语言: [C++▼] [提交] [测试样例]             │
│  ┌───────────────────────────────────────┐  │
│  │ #include <iostream>                    │  │
│  │ using namespace std;                   │  │
│  │                                        │  │
│  │ int main() {                           │  │
│  │     // your code here                  │  │
│  │     return 0;                          │  │
│  │ }                                      │  │
│  └───────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

### 题目管理页面（管理员）
```html
┌─────────────────────────────────────────────┐
│  创建新题目                                  │
├─────────────────────────────────────────────┤
│  题目标题: [__________________________]      │
│  难度: [中等▼]  状态: [草稿▼]              │
│  时间限制: [1000]ms  内存限制: [256]MB      │
│  标签: [数组] [哈希表] [+ 添加]             │
│                                              │
│  题目描述: (支持Markdown)                    │
│  ┌───────────────────────────────────────┐  │
│  │                                        │  │
│  │                                        │  │
│  └───────────────────────────────────────┘  │
│                                              │
│  样例输入输出: [+ 添加样例]                 │
│  样例1:                                      │
│    输入: [___________]                       │
│    输出: [___________]                       │
│    说明: [___________]                       │
│                                              │
│  测试用例: [+ 添加测试用例]                 │
│  ...                                         │
│                                              │
│  [预览] [保存草稿] [发布]                   │
└─────────────────────────────────────────────┘
```

## 🚀 开发步骤

### Phase 1: 基础模型（Week 1）
```bash
# 1. 创建应用
docker-compose exec web python manage.py startapp problems

# 2. 编写models.py
# 3. 注册到admin.py
# 4. 运行迁移
# 5. 创建几个测试题目
```

### Phase 2: API开发（Week 1-2）
```bash
# 1. 安装DRF（已安装）
# 2. 编写serializers.py
# 3. 编写views.py（使用ViewSet）
# 4. 配置urls.py
# 5. 测试API
```

### Phase 3: 前端开发（Week 2）
```bash
# 1. 题目列表页面
# 2. 题目详情页面
# 3. 集成Bootstrap样式
# 4. 添加搜索和筛选功能
```

### Phase 4: 管理功能（Week 2）
```bash
# 1. 题目创建表单
# 2. 题目编辑功能
# 3. 测试用例管理
# 4. 权限控制
```

## 📝 下一步行动

```bash
# 1. 创建problems应用
docker-compose exec web python manage.py startapp problems

# 2. 移动到apps目录
mv problems apps/

# 3. 开始编写模型
# 编辑 apps/problems/models.py

# 4. 注册应用
# 编辑 config/settings.py，添加 'apps.problems'

# 5. 运行迁移
docker-compose exec web python manage.py makemigrations
docker-compose exec web python manage.py migrate
```

---

**准备好开始了吗？我可以帮你：**
1. 创建完整的models.py代码
2. 创建serializers.py
3. 创建views.py和urls.py
4. 创建前端模板

告诉我你想从哪里开始！🚀
