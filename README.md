# OJ系统

基于Django + DRF + Bootstrap + PostgreSQL构建的在线判题系统，专为Linux服务器部署优化。

## 🎯 技术栈

- **后端**: Django 4.2.7 + Django REST Framework
- **前端**: Bootstrap 5.3.0
- **数据库**: PostgreSQL 15
- **部署**: Docker + Docker Compose + Nginx
- **平台**: Linux服务器 (Ubuntu/CentOS/Debian)

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

## 🚀 快速开始

### 1. 系统要求

- **操作系统**: Ubuntu 18.04+ / CentOS 7+ / Debian 10+
- **内存**: 最低2GB，推荐4GB
- **存储**: 最低10GB可用空间
- **网络**: 公网IP或域名

### 2. 一键部署到Linux服务器

```bash
# 克隆项目到服务器
git clone https://github.com/blackjackandLisa/OJ_system.git
cd OJ_system

# 检查系统环境
chmod +x check-system.sh
./check-system.sh

# 运行Linux优化部署脚本
chmod +x deploy-linux.sh
./deploy-linux.sh
```

### 3. 部署选项

脚本提供三种部署方式：
- **标准版本**: 使用官方镜像源
- **国内优化版本**: 使用国内镜像源（推荐中国用户）
- **开发版本**: 包含调试信息

### 4. 访问系统

部署完成后访问：
- **主页**: http://your-server-ip
- **管理后台**: http://your-server-ip/admin
- **API接口**: http://your-server-ip/api/info/

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

## 🔧 服务管理

### 基本命令

```bash
# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 重启服务
docker-compose restart

# 停止服务
docker-compose down

# 启动服务
docker-compose up -d
```

### 数据库管理

```bash
# 进入数据库
docker-compose exec db psql -U postgres -d oj_system

# 备份数据库
docker-compose exec db pg_dump -U postgres oj_system > backup.sql

# 恢复数据库
docker-compose exec -T db psql -U postgres oj_system < backup.sql
```

### 系统监控

```bash
# 检查系统状态
./check-system.sh

# 查看资源使用
docker stats

# 清理Docker资源
docker system prune -f
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

## 🛠️ 故障排除

### 常见问题

1. **端口被占用**
   ```bash
   # 检查端口占用
   netstat -tuln | grep :5432
   
   # 停止冲突服务
   sudo systemctl stop postgresql
   ```

2. **Docker权限问题**
   ```bash
   # 添加用户到docker组
   sudo usermod -aG docker $USER
   newgrp docker
   ```

3. **内存不足**
   ```bash
   # 检查内存使用
   free -h
   
   # 清理Docker资源
   docker system prune -f
   ```

4. **数据库连接失败**
   ```bash
   # 检查容器状态
   docker-compose ps
   
   # 查看数据库日志
   docker-compose logs db
   ```

### 详细故障排除

请参考 [README-Linux.md](README-Linux.md) 获取完整的故障排除指南。

### 日志分析

```bash
# 查看所有服务日志
docker-compose logs

# 查看错误日志
docker-compose logs web | grep ERROR
docker-compose logs db | grep ERROR
docker-compose logs nginx | grep ERROR
```

## 贡献

欢迎提交Issue和Pull Request来改进项目。

## 许可证

MIT License
