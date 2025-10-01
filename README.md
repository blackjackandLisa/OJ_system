# OJ系统

基于Django + DRF + Bootstrap + PostgreSQL构建的在线判题系统。

## 技术栈

- **后端**: Django 4.2.7 + Django REST Framework
- **前端**: Bootstrap 5.3.0
- **数据库**: PostgreSQL 15
- **部署**: Docker + Docker Compose + Nginx

## 项目结构

```
OJ_system/
├── apps/
│   └── core/                 # 核心应用
│       ├── __init__.py
│       ├── apps.py
│       ├── models.py
│       ├── views.py
│       ├── urls.py
│       └── admin.py
├── config/                   # 项目配置
│   ├── __init__.py
│   ├── settings.py
│   ├── urls.py
│   ├── wsgi.py
│   └── asgi.py
├── templates/                # 模板文件
│   ├── base.html
│   └── core/
│       └── home.html
├── static/                   # 静态文件
├── media/                    # 媒体文件
├── requirements.txt          # Python依赖
├── Dockerfile               # Docker镜像配置
├── docker-compose.yml       # Docker Compose配置
├── nginx.conf               # Nginx配置
├── deploy.sh                # 部署脚本
└── README.md                # 项目说明
```

## 快速开始

### 1. 环境准备

确保你的系统已安装：
- Docker
- Docker Compose

### 2. 部署到Linux服务器

```bash
# 克隆项目到服务器
git clone <your-repo-url> oj_system
cd oj_system

# 给部署脚本执行权限
chmod +x deploy.sh

# 运行部署脚本
./deploy.sh
```

### 3. 手动部署（可选）

```bash
# 复制环境配置文件
cp env.example .env

# 编辑环境配置
vim .env

# 启动服务
docker-compose up -d

# 运行数据库迁移
docker-compose exec web python manage.py migrate

# 创建超级用户
docker-compose exec web python manage.py createsuperuser

# 收集静态文件
docker-compose exec web python manage.py collectstatic --noinput
```

## 环境配置

编辑 `.env` 文件配置以下参数：

```env
# Django设置
SECRET_KEY=your-secret-key-here
DEBUG=False
ALLOWED_HOSTS=your-domain.com,your-server-ip

# 数据库设置
DB_NAME=oj_system
DB_USER=postgres
DB_PASSWORD=your-db-password
DB_HOST=db
DB_PORT=5432
```

## 访问地址

- **主页**: http://your-server-ip
- **管理后台**: http://your-server-ip/admin
- **API接口**: http://your-server-ip/api/info/

## 服务管理

```bash
# 启动服务
docker-compose up -d

# 停止服务
docker-compose down

# 查看日志
docker-compose logs -f

# 重启服务
docker-compose restart

# 查看容器状态
docker-compose ps
```

## 开发环境

### 本地开发

```bash
# 安装依赖
pip install -r requirements.txt

# 配置环境变量
cp env.example .env
# 编辑.env文件，设置DEBUG=True

# 运行迁移
python manage.py migrate

# 创建超级用户
python manage.py createsuperuser

# 启动开发服务器
python manage.py runserver
```

## 功能特性

- ✅ 响应式Bootstrap UI设计
- ✅ RESTful API接口
- ✅ PostgreSQL数据库
- ✅ Docker容器化部署
- ✅ Nginx反向代理
- ✅ 静态文件管理
- ✅ 媒体文件处理
- ✅ 环境配置管理

## 扩展功能

项目已为以下功能预留了扩展空间：

- 用户认证系统
- 题目管理
- 代码提交和判题
- 排行榜系统
- 竞赛管理
- 实时通知

## 故障排除

### 常见问题

1. **数据库连接失败**
   - 检查PostgreSQL容器是否正常运行
   - 确认数据库配置信息是否正确

2. **静态文件无法访问**
   - 运行 `python manage.py collectstatic`
   - 检查Nginx配置

3. **权限问题**
   - 确保Docker有足够权限
   - 检查文件权限设置

### 日志查看

```bash
# 查看所有服务日志
docker-compose logs

# 查看特定服务日志
docker-compose logs web
docker-compose logs db
docker-compose logs nginx
```

## 贡献

欢迎提交Issue和Pull Request来改进项目。

## 许可证

MIT License
