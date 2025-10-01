# OJ系统开发计划

## 🤔 现阶段是否需要Nginx？

### ⚠️ 建议：**暂时不需要**

#### 原因分析

1. **开发阶段优先级**
   - ✅ 核心功能开发更重要
   - ✅ Django自带开发服务器足够
   - ✅ 避免增加复杂度
   - ✅ 减少调试障碍

2. **Nginx的作用**
   - 静态文件服务（Django开发模式可以处理）
   - 反向代理（开发阶段不需要）
   - 负载均衡（单机开发用不到）
   - HTTPS支持（开发阶段不需要）

3. **何时需要Nginx**
   - ⏰ 生产环境部署时
   - ⏰ 需要配置域名和HTTPS时
   - ⏰ 有大量静态文件需要优化时
   - ⏰ 需要负载均衡时

### 💡 当前建议配置

```yaml
# 使用简化的docker-compose配置
# 不包含Nginx，直接访问8000端口

version: '3.8'

services:
  db:
    image: postgres:15
    ...
    
  web:
    build: .
    ports:
      - "8000:8000"  # 直接访问，无需Nginx
    ...
```

## 📋 OJ系统开发优先级

### 阶段1: 基础框架（当前阶段）✅
- [x] Django项目搭建
- [x] PostgreSQL数据库配置
- [x] Docker容器化
- [x] 管理后台配置
- [x] 用户认证系统（Django自带）

### 阶段2: 核心功能（优先开发）🎯

#### 2.1 题目管理系统
```
优先级: ⭐⭐⭐⭐⭐

功能点:
- 题目CRUD（创建、查看、编辑、删除）
- 题目分类和标签
- 难度等级
- 测试用例管理
- 题目描述（Markdown支持）
```

#### 2.2 代码提交和判题
```
优先级: ⭐⭐⭐⭐⭐

功能点:
- 代码编辑器集成
- 支持多语言（C++/Java/Python）
- 代码提交
- 判题队列
- 结果展示（AC/WA/TLE/MLE/RE等）
```

#### 2.3 用户系统
```
优先级: ⭐⭐⭐⭐

功能点:
- 用户注册/登录
- 用户信息管理
- 提交历史
- 通过题目统计
```

#### 2.4 排行榜
```
优先级: ⭐⭐⭐

功能点:
- 用户排名
- 通过题目数量
- AC率统计
```

### 阶段3: 进阶功能

#### 3.1 竞赛系统
```
优先级: ⭐⭐

功能点:
- 比赛创建
- 比赛题目
- 实时排名
- 封榜功能
```

#### 3.2 讨论区
```
优先级: ⭐⭐

功能点:
- 题解分享
- 问题讨论
- 评论系统
```

### 阶段4: 生产优化（最后阶段）

#### 4.1 性能优化
```
- Redis缓存
- 数据库优化
- 静态资源CDN
```

#### 4.2 部署优化
```
- Nginx配置 ⬅️ 这时候才需要
- HTTPS配置
- 域名配置
- 负载均衡
```

## 🎯 推荐的开发路线

### Week 1-2: 题目管理系统
```python
# apps/problems/models.py
class Problem(models.Model):
    title = models.CharField(max_length=200)
    description = models.TextField()
    difficulty = models.CharField(choices=[...])
    time_limit = models.IntegerField()  # ms
    memory_limit = models.IntegerField()  # MB
    ...

class TestCase(models.Model):
    problem = models.ForeignKey(Problem)
    input_data = models.TextField()
    output_data = models.TextField()
    ...
```

### Week 3-4: 代码提交和判题
```python
# apps/submissions/models.py
class Submission(models.Model):
    user = models.ForeignKey(User)
    problem = models.ForeignKey(Problem)
    code = models.TextField()
    language = models.CharField(choices=[...])
    status = models.CharField(choices=[...])
    ...

# apps/judge/judge.py
class Judge:
    def run(submission):
        # 判题逻辑
        pass
```

### Week 5-6: 用户系统和排行榜
```python
# apps/users/models.py
class UserProfile(models.Model):
    user = models.OneToOneField(User)
    solved_problems = models.ManyToManyField(Problem)
    submission_count = models.IntegerField()
    ...
```

### Week 7-8: 前端优化和测试
```
- Bootstrap页面美化
- API接口测试
- 功能测试
```

## 🔧 当前推荐的Docker配置

### 开发环境（推荐）

创建 `docker-compose.dev.yml`:

```yaml
version: '3.8'

services:
  db:
    image: postgres:15
    volumes:
      - postgres_data:/var/lib/postgresql/data/
    environment:
      - POSTGRES_DB=oj_system
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
    ports:
      - "5432:5432"

  web:
    build:
      context: .
      dockerfile: Dockerfile.fast
    command: python manage.py runserver 0.0.0.0:8000
    volumes:
      - .:/app  # 代码热重载
    ports:
      - "8000:8000"
    depends_on:
      - db
    environment:
      - DEBUG=True
      - ALLOWED_HOSTS=*
      - DB_HOST=db

volumes:
  postgres_data:
```

使用方式：
```bash
docker-compose -f docker-compose.dev.yml up
```

## 📝 技术选型建议

### 判题系统
```
推荐方案1: 使用Docker沙箱
- 安全性好
- 隔离性强
- 资源限制

推荐方案2: 使用judger库
- python-judger
- 轻量级
- 易于集成
```

### 代码编辑器
```
推荐: CodeMirror 或 Monaco Editor
- 语法高亮
- 代码补全
- 多语言支持
```

### API设计
```
使用Django REST Framework
- 前后端分离
- API文档自动生成
- 权限控制
```

## 🚀 快速开始开发

### 1. 创建题目应用
```bash
docker-compose exec web python manage.py startapp problems
```

### 2. 创建提交应用
```bash
docker-compose exec web python manage.py startapp submissions
```

### 3. 创建判题应用
```bash
docker-compose exec web python manage.py startapp judge
```

### 4. 目录结构
```
OJ_system/
├── apps/
│   ├── core/          # 已有：基础功能
│   ├── problems/      # 新建：题目管理
│   ├── submissions/   # 新建：提交管理
│   ├── judge/         # 新建：判题系统
│   └── users/         # 新建：用户扩展
├── templates/
├── static/
└── ...
```

## 📊 数据模型设计示例

### 核心模型关系
```
User (用户)
  ├── UserProfile (用户资料)
  ├── Submissions (提交记录)
  └── SolvedProblems (通过的题目)

Problem (题目)
  ├── TestCases (测试用例)
  ├── Tags (标签)
  └── Submissions (提交记录)

Submission (提交)
  ├── User (提交用户)
  ├── Problem (题目)
  └── JudgeResult (判题结果)
```

## ⚡ 开发效率提升

### 使用Django扩展
```bash
# 安装有用的开发工具
pip install django-extensions
pip install django-debug-toolbar
pip install ipython

# 更新requirements.txt
echo "django-extensions==3.2.3" >> requirements.txt
echo "django-debug-toolbar==4.2.0" >> requirements.txt
echo "ipython==8.18.1" >> requirements.txt
```

### 使用Shell Plus
```bash
# 更强大的Django Shell
docker-compose exec web python manage.py shell_plus
```

## 🎯 总结建议

### ✅ 现在应该做的
1. **不配置Nginx**（开发阶段不需要）
2. **专注核心功能**（题目、提交、判题）
3. **使用Django开发服务器**（直接访问8000端口）
4. **保持简单配置**（减少复杂度）

### ⏰ 以后再做的
1. **Nginx配置**（生产部署时）
2. **HTTPS配置**（有域名时）
3. **性能优化**（功能完成后）
4. **负载均衡**（用户量大时）

### 📅 时间规划
```
Phase 1 (2-3周): 核心功能开发
Phase 2 (1-2周): 用户系统和测试
Phase 3 (1周):   前端优化
Phase 4 (1周):   生产部署（包含Nginx）
```

## 🔗 下一步行动

```bash
# 1. 简化docker-compose配置（移除Nginx）
cp docker-compose.yml docker-compose.prod.yml  # 备份生产配置
# 编辑docker-compose.yml，注释掉nginx部分

# 2. 创建开发应用
docker-compose exec web python manage.py startapp problems
docker-compose exec web python manage.py startapp submissions

# 3. 开始编写模型
# 编辑 apps/problems/models.py
# 编辑 apps/submissions/models.py

# 4. 运行迁移
docker-compose exec web python manage.py makemigrations
docker-compose exec web python manage.py migrate
```

---

**结论**: 现在不需要配置Nginx，专注开发OJ核心功能。等功能开发完成、准备生产部署时，再配置Nginx和HTTPS！
