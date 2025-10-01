# Django Shell 命令指南

## 🚀 进入Django Shell

```bash
# 方式1: 标准Shell
docker-compose exec web python manage.py shell

# 方式2: Shell Plus（如果安装了django-extensions）
docker-compose exec web python manage.py shell_plus
```

## 📝 创建标签和题目

### 方法1: 运行示例数据脚本（推荐）

```bash
# 在服务器上运行
docker-compose exec web python manage.py shell < create_sample_data.py

# 或者进入shell后
docker-compose exec web python manage.py shell
>>> exec(open('create_sample_data.py').read())
```

### 方法2: 手动在Shell中创建

#### 1. 创建题目标签

```python
from apps.problems.models import ProblemTag

# 创建单个标签
tag1 = ProblemTag.objects.create(
    name='数组',
    color='primary',
    description='数组相关题目'
)

tag2 = ProblemTag.objects.create(
    name='哈希表',
    color='info',
    description='哈希表相关题目'
)

tag3 = ProblemTag.objects.create(
    name='动态规划',
    color='warning',
    description='动态规划相关题目'
)

# 查看所有标签
ProblemTag.objects.all()

# 查看标签数量
ProblemTag.objects.count()
```

#### 2. 创建题目

```python
from django.contrib.auth.models import User
from apps.problems.models import Problem, ProblemTag, ProblemSample, TestCase

# 获取管理员用户
admin = User.objects.filter(is_superuser=True).first()

# 创建题目
problem = Problem.objects.create(
    title='两数之和',
    description='''给定一个整数数组 nums 和一个整数目标值 target，请你在该数组中找出和为目标值 target 的那两个整数，并返回它们的数组下标。

你可以假设每种输入只会对应一个答案。但是，数组中同一个元素在答案里不能重复出现。''',
    input_format='第一行包含两个整数 n 和 target。\n第二行包含 n 个整数，表示数组 nums。',
    output_format='输出两个整数，表示两个数的下标。',
    hint='可以使用哈希表来优化时间复杂度。',
    source='LeetCode',
    time_limit=1000,
    memory_limit=256,
    difficulty='easy',
    status='published',
    created_by=admin
)

# 添加标签
array_tag = ProblemTag.objects.get(name='数组')
hash_tag = ProblemTag.objects.get(name='哈希表')
problem.tags.add(array_tag, hash_tag)

# 查看题目
print(problem)
print(f"难度: {problem.get_difficulty_display()}")
print(f"标签: {[tag.name for tag in problem.tags.all()]}")
```

#### 3. 创建样例

```python
# 为题目添加样例
sample1 = ProblemSample.objects.create(
    problem=problem,
    input_data='4 9\n2 7 11 15',
    output_data='0 1',
    explanation='nums[0] + nums[1] = 2 + 7 = 9',
    order=0
)

sample2 = ProblemSample.objects.create(
    problem=problem,
    input_data='3 6\n3 2 4',
    output_data='1 2',
    explanation='nums[1] + nums[2] = 2 + 4 = 6',
    order=1
)

# 查看题目的所有样例
problem.samples.all()
```

#### 4. 创建测试用例

```python
# 为题目添加测试用例
testcase1 = TestCase.objects.create(
    problem=problem,
    input_data='4 9\n2 7 11 15',
    output_data='0 1',
    is_sample=True,
    score=20,
    order=0
)

testcase2 = TestCase.objects.create(
    problem=problem,
    input_data='3 6\n3 2 4',
    output_data='1 2',
    is_sample=True,
    score=20,
    order=1
)

testcase3 = TestCase.objects.create(
    problem=problem,
    input_data='2 10\n5 5',
    output_data='0 1',
    is_sample=False,
    score=30,
    order=2
)

# 查看题目的所有测试用例
problem.test_cases.all()
problem.test_cases.count()
```

## 📊 查询数据

### 查询题目

```python
from apps.problems.models import Problem

# 查看所有题目
Problem.objects.all()

# 查看已发布的题目
Problem.objects.filter(status='published')

# 查看简单题目
Problem.objects.filter(difficulty='easy')

# 查看特定标签的题目
array_problems = Problem.objects.filter(tags__name='数组')

# 查看题目详情
problem = Problem.objects.get(id=1)
print(f"标题: {problem.title}")
print(f"难度: {problem.get_difficulty_display()}")
print(f"通过率: {problem.acceptance_rate}%")
print(f"标签: {[tag.name for tag in problem.tags.all()]}")
print(f"样例数: {problem.samples.count()}")
print(f"测试用例数: {problem.test_cases.count()}")
```

### 查询标签

```python
from apps.problems.models import ProblemTag

# 查看所有标签
ProblemTag.objects.all()

# 查看标签的题目数量
for tag in ProblemTag.objects.all():
    count = tag.problems.count()
    print(f"{tag.name}: {count} 个题目")
```

### 查询测试用例

```python
from apps.problems.models import TestCase

# 查看所有测试用例
TestCase.objects.all()

# 查看特定题目的测试用例
problem_id = 1
TestCase.objects.filter(problem_id=problem_id)

# 查看公开样例
TestCase.objects.filter(is_sample=True)
```

## 🔧 修改数据

### 修改题目

```python
# 获取题目
problem = Problem.objects.get(id=1)

# 修改题目属性
problem.title = '新标题'
problem.difficulty = 'medium'
problem.status = 'published'
problem.save()

# 修改标签
new_tag = ProblemTag.objects.get(name='动态规划')
problem.tags.add(new_tag)

# 移除标签
old_tag = ProblemTag.objects.get(name='数组')
problem.tags.remove(old_tag)

# 清空所有标签
problem.tags.clear()
```

### 修改测试用例

```python
# 获取测试用例
testcase = TestCase.objects.get(id=1)

# 修改测试用例
testcase.input_data = '新的输入数据'
testcase.output_data = '新的输出数据'
testcase.score = 50
testcase.save()
```

## 🗑️ 删除数据

```python
# 删除标签
tag = ProblemTag.objects.get(name='测试标签')
tag.delete()

# 删除题目（会级联删除相关的样例和测试用例）
problem = Problem.objects.get(id=1)
problem.delete()

# 删除所有草稿题目
Problem.objects.filter(status='draft').delete()
```

## 📈 统计信息

```python
from apps.problems.models import Problem, ProblemTag, TestCase

# 题目统计
print(f"总题目数: {Problem.objects.count()}")
print(f"已发布: {Problem.objects.filter(status='published').count()}")
print(f"草稿: {Problem.objects.filter(status='draft').count()}")
print(f"简单题: {Problem.objects.filter(difficulty='easy').count()}")
print(f"中等题: {Problem.objects.filter(difficulty='medium').count()}")
print(f"困难题: {Problem.objects.filter(difficulty='hard').count()}")

# 标签统计
print(f"标签总数: {ProblemTag.objects.count()}")

# 测试用例统计
print(f"测试用例总数: {TestCase.objects.count()}")
print(f"公开样例: {TestCase.objects.filter(is_sample=True).count()}")
print(f"隐藏用例: {TestCase.objects.filter(is_sample=False).count()}")
```

## 🎯 快速创建多个题目

```python
from django.contrib.auth.models import User
from apps.problems.models import Problem, ProblemTag

admin = User.objects.filter(is_superuser=True).first()
array_tag = ProblemTag.objects.get(name='数组')

# 批量创建题目
problems_data = [
    {
        'title': '三数之和',
        'description': '给你一个包含 n 个整数的数组...',
        'input_format': '...',
        'output_format': '...',
        'difficulty': 'medium',
    },
    {
        'title': '四数之和',
        'description': '给你一个包含 n 个整数的数组...',
        'input_format': '...',
        'output_format': '...',
        'difficulty': 'medium',
    },
]

for data in problems_data:
    problem = Problem.objects.create(
        title=data['title'],
        description=data['description'],
        input_format=data['input_format'],
        output_format=data['output_format'],
        difficulty=data['difficulty'],
        status='published',
        time_limit=1000,
        memory_limit=256,
        created_by=admin
    )
    problem.tags.add(array_tag)
    print(f"创建题目: {problem.title}")
```

## 💡 有用的技巧

### 1. 查看SQL查询

```python
from django.db import connection

# 执行查询后查看SQL
problems = Problem.objects.filter(difficulty='easy')
print(problems.query)  # 查看生成的SQL

# 查看所有SQL查询
for query in connection.queries:
    print(query['sql'])
```

### 2. 使用Q对象进行复杂查询

```python
from django.db.models import Q

# OR查询
Problem.objects.filter(Q(difficulty='easy') | Q(difficulty='medium'))

# AND查询
Problem.objects.filter(Q(difficulty='easy') & Q(status='published'))

# NOT查询
Problem.objects.exclude(Q(difficulty='hard'))
```

### 3. 使用聚合函数

```python
from django.db.models import Count, Avg

# 按难度统计题目数量
Problem.objects.values('difficulty').annotate(count=Count('id'))

# 计算平均通过率
Problem.objects.aggregate(avg_rate=Avg('total_accepted'))
```

## 🚪 退出Shell

```python
exit()
# 或按 Ctrl+D (Linux/Mac) / Ctrl+Z然后Enter (Windows)
```

## 📌 注意事项

1. **保存更改**: 修改对象后必须调用 `save()` 方法
2. **事务**: Shell中的操作会立即生效，请小心删除操作
3. **性能**: 使用 `select_related()` 和 `prefetch_related()` 优化查询
4. **调试**: 使用 `print()` 查看对象信息

## 🔗 相关命令

```bash
# 创建迁移
python manage.py makemigrations

# 应用迁移
python manage.py migrate

# 创建超级用户
python manage.py createsuperuser

# 运行开发服务器
python manage.py runserver

# 清空数据库（危险！）
python manage.py flush
```
