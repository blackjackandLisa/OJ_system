# Docker Compose 部署判题系统完整指南

## 📋 前置条件

✅ 判题镜像已构建完成：
- `oj-judge-python:latest`
- `oj-judge-cpp:latest`

---

## 🚀 完整部署流程

### 第1步：验证判题镜像

```bash
# 查看已构建的镜像
docker images | grep oj-judge

# 应该看到：
# oj-judge-python   latest   xxxxx   xxx   xxxMB
# oj-judge-cpp      latest   xxxxx   xxx   xxxMB

# 测试镜像是否正常
docker run --rm oj-judge-python:latest python3 --version
docker run --rm oj-judge-cpp:latest g++ --version
```

---

### 第2步：返回项目根目录

```bash
cd ~/OJ_system
# 或
cd /path/to/OJ_system
```

---

### 第3步：拉取最新代码

```bash
git pull origin main
```

---

### 第4步：运行数据库迁移

```bash
# 如果项目已经在运行，先进入web容器
docker-compose exec web python manage.py migrate

# 如果项目还没启动，先启动后再迁移
docker-compose up -d
docker-compose exec web python manage.py migrate
```

---

### 第5步：初始化编程语言配置

```bash
# 在web容器中执行
docker-compose exec web python manage.py init_languages

# 应该看到输出：
# 正在初始化编程语言配置...
# [OK] 创建 Python 3.10 语言配置
# [OK] 创建 C++ 17 语言配置
# 
# 语言配置初始化完成！
# 已配置语言数量: 2
```

---

### 第6步：重启web服务（应用判题功能）

```bash
# 重启web容器
docker-compose restart web

# 查看日志确认启动成功
docker-compose logs -f web

# 按 Ctrl+C 退出日志查看
```

---

### 第7步：验证服务状态

```bash
# 查看所有容器状态
docker-compose ps

# 应该看到：
# Name              Command               State           Ports
# -------------------------------------------------------------------------
# web               gunicorn ...                 Up      0.0.0.0:8000->8000/tcp
# db                docker-entrypoint.sh ...     Up      5432/tcp
# nginx             nginx -g daemon off;         Up      0.0.0.0:80->80/tcp

# 检查web容器健康状态
docker-compose exec web python manage.py check
```

---

### 第8步：创建测试题目

#### 方法1: 通过Django Shell

```bash
# 进入Django shell
docker-compose exec web python manage.py shell
```

然后在shell中执行：

```python
from apps.problems.models import Problem, TestCase
from django.contrib.auth.models import User

# 获取管理员用户
admin = User.objects.filter(is_superuser=True).first()
if not admin:
    print("请先创建超级用户: docker-compose exec web python manage.py createsuperuser")
else:
    # 创建测试题目
    problem = Problem.objects.create(
        title='A+B Problem',
        description='输入两个整数a和b，输出它们的和',
        input_format='一行两个整数，用空格分隔',
        output_format='一个整数，表示a+b的值',
        hint='这是一道简单的入门题',
        time_limit=1000,
        memory_limit=256,
        difficulty='easy',
        status='published',
        created_by=admin
    )
    
    # 添加测试用例
    TestCase.objects.create(
        problem=problem,
        input_data='1 2',
        output_data='3',
        is_sample=True,
        score=10,
        order=1
    )
    
    TestCase.objects.create(
        problem=problem,
        input_data='10 20',
        output_data='30',
        is_sample=True,
        score=10,
        order=2
    )
    
    TestCase.objects.create(
        problem=problem,
        input_data='-5 5',
        output_data='0',
        is_sample=False,
        score=10,
        order=3
    )
    
    print(f"✓ 题目创建成功！")
    print(f"  题目ID: {problem.id}")
    print(f"  标题: {problem.title}")
    print(f"  测试用例数量: {problem.test_cases.count()}")

# 退出shell
exit()
```

#### 方法2: 通过管理后台

```bash
# 1. 确保有超级用户
docker-compose exec web python manage.py createsuperuser

# 2. 访问管理后台
浏览器打开: http://your-server-ip/admin/

# 3. 导航到：题目 -> 添加题目
# 4. 填写题目信息并添加测试用例
```

---

### 第9步：测试判题功能

#### 获取认证Token

```bash
# 方法1: 通过API登录
curl -X POST http://your-server-ip/users/api/login/ \
  -H "Content-Type: application/json" \
  -d '{"username":"your_username","password":"your_password"}'

# 复制返回的token
```

#### 提交Python代码测试

```bash
# 设置token变量（替换为你的token）
export TOKEN="your_token_here"

# 提交Python代码
curl -X POST http://your-server-ip/judge/api/submissions/ \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "problem_id": 1,
    "language_name": "python",
    "code": "a, b = map(int, input().split())\nprint(a + b)"
  }'

# 记录返回的submission_id
```

#### 查看判题结果

```bash
# 等待3-5秒后查询结果
sleep 5

# 查询提交详情（替换ID）
curl http://your-server-ip/judge/api/submissions/1/

# 查看我的所有提交
curl http://your-server-ip/judge/api/submissions/my_submissions/ \
  -H "Authorization: Bearer $TOKEN"
```

#### 提交C++代码测试

```bash
curl -X POST http://your-server-ip/judge/api/submissions/ \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "problem_id": 1,
    "language_name": "cpp",
    "code": "#include <iostream>\nusing namespace std;\n\nint main() {\n    int a, b;\n    cin >> a >> b;\n    cout << a + b << endl;\n    return 0;\n}"
  }'
```

---

### 第10步：查看判题日志

```bash
# 实时查看web容器日志（包含判题日志）
docker-compose logs -f web | grep "\[Judger\]"

# 应该看到类似：
# [Judger] 开始判题: Submission #1
# [Judger] 工作目录: /tmp/judge_xxx
# [Judger] 运行测试用例 1/3
# [Judger] 运行测试用例 2/3
# [Judger] 运行测试用例 3/3
# [Judger] 判题完成: AC
# [Judger] 清理工作目录: /tmp/judge_xxx

# 查看最近100行日志
docker-compose logs --tail=100 web

# 查看所有容器日志
docker-compose logs --tail=50
```

---

### 第11步：访问管理后台查看结果

```bash
浏览器访问: http://your-server-ip/admin/judge/submission/

可以看到：
✓ 提交列表
✓ 判题状态（pending/judging/finished）
✓ 判题结果（AC/WA/TLE等）
✓ 彩色状态徽章
✓ 运行时间和内存
✓ 测试用例通过情况
✓ 完整的判题详情JSON
```

---

## 🔧 常用维护命令

### 查看容器状态

```bash
# 查看所有容器
docker-compose ps

# 查看容器资源使用
docker stats

# 查看特定容器日志
docker-compose logs web
docker-compose logs db
docker-compose logs nginx
```

### 进入容器内部

```bash
# 进入web容器
docker-compose exec web bash

# 进入数据库容器
docker-compose exec db psql -U postgres -d oj_db

# 进入nginx容器
docker-compose exec nginx sh
```

### 重启服务

```bash
# 重启所有服务
docker-compose restart

# 重启特定服务
docker-compose restart web
docker-compose restart db
docker-compose restart nginx

# 停止所有服务
docker-compose stop

# 启动所有服务
docker-compose start

# 停止并删除容器（不删除数据）
docker-compose down

# 停止并删除容器和数据卷（危险！）
docker-compose down -v
```

### 更新代码后重新部署

```bash
# 1. 拉取代码
git pull origin main

# 2. 重新构建（如果代码有变化）
docker-compose build web

# 3. 重启服务
docker-compose up -d

# 4. 运行迁移
docker-compose exec web python manage.py migrate

# 5. 收集静态文件
docker-compose exec web python manage.py collectstatic --noinput
```

---

## 🐛 故障排查

### 问题1: 判题一直pending

```bash
# 检查web容器日志
docker-compose logs -f web | grep -E "\[Judger\]|Error"

# 检查Docker守护进程
docker ps -a | grep judge

# 检查web容器能否访问Docker socket
docker-compose exec web docker ps
```

### 问题2: 容器无法启动

```bash
# 查看详细错误
docker-compose logs web

# 检查端口占用
netstat -tlnp | grep 8000
netstat -tlnp | grep 5432

# 重新创建容器
docker-compose down
docker-compose up -d
```

### 问题3: 数据库连接失败

```bash
# 检查数据库容器
docker-compose ps db

# 测试数据库连接
docker-compose exec web python manage.py dbshell

# 查看数据库日志
docker-compose logs db
```

### 问题4: 判题Docker权限问题

```bash
# 检查web容器能否访问宿主机Docker
docker-compose exec web docker version

# 如果失败，检查docker-compose.yml中的volumes配置
# 应该有：
# volumes:
#   - /var/run/docker.sock:/var/run/docker.sock
```

---

## 📊 性能监控

### 创建监控脚本

```bash
cat > monitor.sh <<'EOF'
#!/bin/bash

echo "========== OJ系统状态监控 =========="
echo "时间: $(date)"
echo ""

echo "--- 容器状态 ---"
docker-compose ps

echo ""
echo "--- 容器资源使用 ---"
docker stats --no-stream

echo ""
echo "--- 判题镜像 ---"
docker images | grep oj-judge

echo ""
echo "--- 最近5条提交 ---"
docker-compose exec -T web python manage.py shell <<PYTHON
from apps.judge.models import Submission
for s in Submission.objects.all()[:5]:
    print(f"#{s.id} {s.user.username} {s.problem.title} {s.result} {s.status}")
PYTHON

echo ""
echo "--- 磁盘使用 ---"
df -h | grep -E "Filesystem|/$"

echo ""
echo "==================================="
EOF

chmod +x monitor.sh
```

### 运行监控

```bash
# 执行监控
./monitor.sh

# 或定时监控
watch -n 10 ./monitor.sh
```

---

## 🔄 备份和恢复

### 备份数据库

```bash
# 备份PostgreSQL数据库
docker-compose exec -T db pg_dump -U postgres oj_db > backup_$(date +%Y%m%d_%H%M%S).sql

# 或使用Django的dumpdata
docker-compose exec -T web python manage.py dumpdata > backup_data.json
```

### 恢复数据库

```bash
# 恢复PostgreSQL
docker-compose exec -T db psql -U postgres oj_db < backup.sql

# 或恢复Django数据
docker-compose exec -T web python manage.py loaddata backup_data.json
```

---

## ✅ 部署完成检查清单

- [ ] 判题镜像已构建（python + cpp）
- [ ] docker-compose服务正常运行
- [ ] 数据库迁移已执行
- [ ] 编程语言已初始化
- [ ] 超级用户已创建
- [ ] 测试题目已创建（含测试用例）
- [ ] Python代码提交测试通过（AC）
- [ ] C++代码提交测试通过（AC）
- [ ] 管理后台可访问
- [ ] 判题日志输出正常
- [ ] web容器能访问Docker socket

---

## 🎯 快速命令参考

```bash
# 项目目录
cd ~/OJ_system

# 查看状态
docker-compose ps

# 查看日志
docker-compose logs -f web

# 重启服务
docker-compose restart web

# 执行命令
docker-compose exec web python manage.py migrate
docker-compose exec web python manage.py init_languages
docker-compose exec web python manage.py shell

# 测试判题
curl -X POST http://localhost/judge/api/submissions/ \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"problem_id":1,"language_name":"python","code":"print(1+1)"}'

# 查看结果
curl http://localhost/judge/api/submissions/1/
docker-compose exec web python manage.py dbshell
```

---

## 🚀 完整部署脚本

创建一键部署脚本：

```bash
cat > deploy_judge_compose.sh <<'EOF'
#!/bin/bash

set -e

echo "========== OJ判题系统部署（Docker Compose）=========="

# 1. 拉取代码
echo "[1/8] 拉取最新代码..."
git pull origin main

# 2. 重新构建web容器
echo "[2/8] 构建web容器..."
docker-compose build web

# 3. 启动所有服务
echo "[3/8] 启动服务..."
docker-compose up -d

# 4. 等待服务启动
echo "[4/8] 等待服务启动..."
sleep 10

# 5. 运行数据库迁移
echo "[5/8] 运行数据库迁移..."
docker-compose exec -T web python manage.py migrate

# 6. 初始化编程语言
echo "[6/8] 初始化编程语言..."
docker-compose exec -T web python manage.py init_languages

# 7. 收集静态文件
echo "[7/8] 收集静态文件..."
docker-compose exec -T web python manage.py collectstatic --noinput

# 8. 重启web服务
echo "[8/8] 重启web服务..."
docker-compose restart web

echo ""
echo "========== 部署完成 =========="
echo "服务地址: http://your-server-ip"
echo "管理后台: http://your-server-ip/admin/"
echo ""
echo "查看日志: docker-compose logs -f web"
echo "查看状态: docker-compose ps"
EOF

chmod +x deploy_judge_compose.sh
```

使用：
```bash
./deploy_judge_compose.sh
```

---

**部署完成！** 🎉

现在可以通过浏览器访问系统，测试完整的判题流程。

