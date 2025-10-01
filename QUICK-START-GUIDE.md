# 🚀 OJ系统快速启动指南

## 📋 当前状态检查

你已经完成：
- ✅ Django项目搭建
- ✅ Docker配置
- ✅ 题目管理系统代码

现在需要：
- ⏳ 运行数据库迁移
- ⏳ 创建示例数据
- ⏳ 测试系统

## 🎯 立即开始（3步完成）

### 步骤1: 安装依赖并运行迁移

在Linux服务器上运行：

```bash
# 方式1: 使用自动化脚本（推荐）
chmod +x setup-database.sh
./setup-database.sh
```

或手动执行：

```bash
# 方式2: 手动执行命令
# 1. 安装新依赖
docker-compose exec web pip install django-filter==23.3 markdown==3.5.1

# 2. 创建迁移文件
docker-compose exec web python manage.py makemigrations

# 3. 应用迁移
docker-compose exec web python manage.py migrate
```

### 步骤2: 创建示例数据

```bash
# 运行示例数据脚本
docker-compose exec web python manage.py shell < create_sample_data.py
```

**这会创建：**
- 10个题目标签
- 4个示例题目（两数之和、回文数等）
- 每个题目包含样例和测试用例

### 步骤3: 访问系统

**管理后台：**
```
http://your-server-ip:8000/admin/problems/problem/
```

**API接口：**
```
http://your-server-ip:8000/problems/api/problems/
```

## 🔍 详细步骤说明

### 一、数据库迁移详解

#### 什么是迁移？
迁移是Django将模型定义转换为数据库表结构的过程。

#### 为什么需要迁移？
因为我们创建了新的models.py，需要在数据库中创建对应的表。

#### 迁移命令：

```bash
# 1. 创建迁移文件（根据models.py生成）
docker-compose exec web python manage.py makemigrations

# 输出示例：
# Migrations for 'problems':
#   apps/problems/migrations/0001_initial.py
#     - Create model ProblemTag
#     - Create model Problem
#     - Create model ProblemSample
#     - Create model TestCase
#     - Create model UserProblemStatus

# 2. 应用迁移（在数据库中创建表）
docker-compose exec web python manage.py migrate

# 输出示例：
# Running migrations:
#   Applying problems.0001_initial... OK
```

#### 验证迁移成功：

```bash
# 查看数据库表
docker-compose exec web python manage.py dbshell
\dt

# 应该看到这些表：
# problem_tags
# problems
# problem_samples
# test_cases
# user_problem_status
```

### 二、创建数据详解

#### 方式1: 使用脚本（推荐）

```bash
# 运行create_sample_data.py
docker-compose exec web python manage.py shell < create_sample_data.py
```

**脚本会创建：**

1. **题目标签（10个）：**
   - 数组、哈希表、字符串
   - 动态规划、贪心、双指针
   - 排序、搜索、图论、树

2. **示例题目（4个）：**
   - 两数之和（简单）
   - 回文数（简单）
   - 最长公共前缀（简单）
   - 合并两个有序数组（中等）

3. **每个题目包含：**
   - 完整的题目描述
   - 输入输出格式
   - 2-3个样例
   - 3-4个测试用例

#### 方式2: 手动在Shell创建

```bash
# 进入Django Shell
docker-compose exec web python manage.py shell
```

然后参考 `SHELL-COMMANDS.md` 中的示例。

### 三、验证系统

#### 1. 检查数据

```bash
# 进入Shell
docker-compose exec web python manage.py shell

# 查看数据
>>> from apps.problems.models import Problem, ProblemTag
>>> Problem.objects.count()  # 应该返回4
>>> ProblemTag.objects.count()  # 应该返回10
>>> Problem.objects.all()
>>> exit()
```

#### 2. 测试API

```bash
# 获取题目列表
curl http://localhost:8000/problems/api/problems/

# 获取题目详情
curl http://localhost:8000/problems/api/problems/1/

# 获取标签列表
curl http://localhost:8000/problems/api/tags/
```

#### 3. 访问管理后台

1. 打开浏览器：`http://your-server-ip:8000/admin`
2. 登录（如果还没有管理员，运行 `./create-admin.sh`）
3. 点击"题目管理" → "题目"
4. 可以看到创建的题目列表

## 🎨 管理后台功能

登录管理后台后，你可以：

### 题目管理
- ✅ 查看所有题目
- ✅ 创建新题目
- ✅ 编辑题目
- ✅ 删除题目
- ✅ 批量发布/隐藏题目

### 标签管理
- ✅ 查看所有标签
- ✅ 创建新标签
- ✅ 编辑标签颜色和描述

### 样例管理
- ✅ 为题目添加公开样例
- ✅ 编辑样例说明

### 测试用例管理
- ✅ 为题目添加测试用例
- ✅ 设置测试点分数
- ✅ 标记是否为公开样例

## 🔧 常见问题

### Q1: 迁移失败怎么办？

**错误：`No changes detected`**
```bash
# 解决：确保应用已注册
# 检查 config/settings.py 中的 INSTALLED_APPS 是否包含 'apps.problems'
```

**错误：`UndefinedTable`**
```bash
# 解决：先运行迁移
docker-compose exec web python manage.py migrate
```

### Q2: 无法导入模块？

```bash
# 安装缺失的依赖
docker-compose exec web pip install -r requirements.txt
```

### Q3: 数据库连接失败？

```bash
# 检查数据库容器
docker-compose ps

# 如果数据库未运行，启动它
docker-compose up -d db
```

### Q4: Shell脚本运行失败？

```bash
# 方式1: 使用管道
docker-compose exec -T web python manage.py shell < create_sample_data.py

# 方式2: 在Shell中运行
docker-compose exec web python manage.py shell
>>> exec(open('create_sample_data.py').read())
```

## 📊 数据库表结构

迁移后会创建以下表：

```
problems               # 题目主表
├── id                # 主键
├── title             # 标题
├── description       # 描述
├── difficulty        # 难度
├── time_limit        # 时间限制
├── memory_limit      # 内存限制
└── ...

problem_tags          # 标签表
├── id
├── name              # 标签名
├── color             # 颜色
└── description       # 描述

problem_samples       # 样例表
├── id
├── problem_id        # 外键
├── input_data        # 输入
├── output_data       # 输出
└── explanation       # 说明

test_cases            # 测试用例表
├── id
├── problem_id        # 外键
├── input_data        # 输入
├── output_data       # 输出
├── is_sample         # 是否公开
└── score             # 分数

user_problem_status   # 用户状态表
├── id
├── user_id           # 外键
├── problem_id        # 外键
├── status            # 状态
└── submit_count      # 提交次数
```

## 🎯 下一步

完成数据库设置后，你可以：

1. **继续开发功能**
   - 代码提交系统
   - 判题系统
   - 排行榜

2. **美化前端页面**
   - 创建题目列表页面
   - 创建题目详情页面
   - 集成代码编辑器

3. **测试API**
   - 使用Postman测试
   - 编写前端调用API

4. **部署优化**
   - 配置Nginx（生产环境）
   - 配置HTTPS
   - 性能优化

## 📝 命令速查表

```bash
# 数据库相关
docker-compose exec web python manage.py makemigrations
docker-compose exec web python manage.py migrate
docker-compose exec web python manage.py dbshell

# 创建数据
docker-compose exec web python manage.py shell < create_sample_data.py
docker-compose exec web python manage.py shell

# 用户管理
./create-admin.sh
docker-compose exec web python manage.py createsuperuser

# 服务管理
docker-compose up -d
docker-compose down
docker-compose restart
docker-compose logs -f web

# 查看状态
docker-compose ps
./check-access.sh
```

## 🔗 相关文档

- `SHELL-COMMANDS.md` - Django Shell命令详解
- `PROBLEM-SYSTEM-DESIGN.md` - 题目系统设计文档
- `DEVELOPMENT-PLAN.md` - 开发计划
- `CREATE-ADMIN.md` - 管理员创建指南

---

**现在运行 `./setup-database.sh` 开始设置数据库！** 🚀
