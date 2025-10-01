# 快速启动指南

## 🎉 部署完成后如何访问

### 1️⃣ 启动服务

```bash
# 方式1: 使用启动脚本（推荐）
chmod +x start-service.sh
./start-service.sh
```

或者手动启动：

```bash
# 方式2: 使用docker-compose命令
docker-compose up -d

# 或使用快速部署版本
docker-compose -f docker-compose.fast.yml up -d
```

### 2️⃣ 检查服务状态

```bash
# 查看所有容器状态
docker-compose ps

# 应该看到类似输出：
# NAME                COMMAND                  SERVICE   STATUS    PORTS
# oj_system-web-1     "gunicorn --bind 0.0…"   web       Up        0.0.0.0:8000->8000/tcp
# oj_system-db-1      "docker-entrypoint.s…"   db        Up        0.0.0.0:5432->5432/tcp
# oj_system-nginx-1   "nginx -g 'daemon of…"   nginx     Up        0.0.0.0:80->80/tcp
```

### 3️⃣ 访问系统

#### 🌐 通过浏览器访问

**如果配置了Nginx（80端口）：**
- 主页: `http://your-server-ip`
- 管理后台: `http://your-server-ip/admin`
- API接口: `http://your-server-ip/api/info/`

**如果只有Web服务（8000端口）：**
- 主页: `http://your-server-ip:8000`
- 管理后台: `http://your-server-ip:8000/admin`
- API接口: `http://your-server-ip:8000/api/info/`

#### 📍 获取服务器IP地址

```bash
# 获取公网IP
curl ifconfig.me

# 或
curl ipinfo.io/ip

# 获取内网IP
hostname -I
```

#### 💻 本地测试

```bash
# 使用curl测试API
curl http://localhost:8000/api/info/

# 应该返回类似：
# {
#   "message": "OJ系统API",
#   "version": "1.0.0",
#   "status": "running"
# }
```

### 4️⃣ 创建管理员账号

首次使用需要创建超级用户：

```bash
# 创建超级用户
docker-compose exec web python manage.py createsuperuser

# 按提示输入：
# Username: admin
# Email: admin@example.com
# Password: ********
# Password (again): ********
```

### 5️⃣ 登录管理后台

1. 访问 `http://your-server-ip/admin`
2. 使用刚才创建的用户名和密码登录
3. 进入Django管理后台

## 🔧 常用管理命令

### 服务管理

```bash
# 启动服务
docker-compose up -d

# 停止服务
docker-compose down

# 重启服务
docker-compose restart

# 查看服务状态
docker-compose ps

# 查看资源使用
docker stats
```

### 日志查看

```bash
# 查看所有日志
docker-compose logs

# 实时查看日志
docker-compose logs -f

# 查看特定服务日志
docker-compose logs -f web
docker-compose logs -f db
docker-compose logs -f nginx

# 查看最近100行日志
docker-compose logs --tail=100
```

### 进入容器

```bash
# 进入Web容器
docker-compose exec web bash

# 进入数据库容器
docker-compose exec db bash

# 直接进入PostgreSQL
docker-compose exec db psql -U postgres -d oj_system
```

### Django管理命令

```bash
# 创建超级用户
docker-compose exec web python manage.py createsuperuser

# 数据库迁移
docker-compose exec web python manage.py migrate

# 收集静态文件
docker-compose exec web python manage.py collectstatic

# 进入Django Shell
docker-compose exec web python manage.py shell

# 查看所有命令
docker-compose exec web python manage.py help
```

## 🔍 故障排查

### 1. 服务无法访问

```bash
# 检查容器是否运行
docker-compose ps

# 检查端口是否监听
netstat -tuln | grep 8000
netstat -tuln | grep 80

# 查看错误日志
docker-compose logs web
```

### 2. 页面报错500

```bash
# 查看详细错误
docker-compose logs web

# 检查数据库连接
docker-compose exec web python manage.py check

# 运行迁移
docker-compose exec web python manage.py migrate
```

### 3. 静态文件无法加载

```bash
# 收集静态文件
docker-compose exec web python manage.py collectstatic --noinput

# 重启Nginx
docker-compose restart nginx
```

### 4. 数据库连接失败

```bash
# 检查数据库容器
docker-compose ps db

# 查看数据库日志
docker-compose logs db

# 测试数据库连接
docker-compose exec web python -c "from django.db import connection; connection.ensure_connection(); print('Database OK')"
```

## 📱 防火墙配置

如果使用云服务器，需要开放端口：

### AWS/阿里云/腾讯云

在安全组中开放：
- 80端口（HTTP）
- 443端口（HTTPS，如果配置了）
- 8000端口（如果直接访问Web服务）

### Linux防火墙

```bash
# Ubuntu/Debian (UFW)
sudo ufw allow 80
sudo ufw allow 443
sudo ufw allow 8000

# CentOS/RHEL (firewalld)
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --add-port=8000/tcp
sudo firewall-cmd --reload
```

## 🚀 性能优化建议

### 1. 启用生产模式

确保 `.env` 文件中：
```env
DEBUG=False
ALLOWED_HOSTS=your-domain.com,your-server-ip
```

### 2. 配置域名

```bash
# 修改 .env 文件
ALLOWED_HOSTS=example.com,www.example.com,your-server-ip
```

### 3. 配置HTTPS（可选）

```bash
# 安装certbot
sudo apt install certbot

# 获取SSL证书
sudo certbot certonly --standalone -d your-domain.com

# 修改nginx.conf配置HTTPS
# 然后重启
docker-compose restart nginx
```

## 📊 监控和维护

### 定期备份

```bash
# 备份数据库
docker-compose exec db pg_dump -U postgres oj_system > backup_$(date +%Y%m%d).sql

# 备份媒体文件
tar -czf media_backup_$(date +%Y%m%d).tar.gz media/
```

### 查看资源使用

```bash
# 实时查看容器资源使用
docker stats

# 查看磁盘使用
df -h

# 清理Docker资源
docker system prune -f
```

## 🎯 下一步

1. ✅ 访问主页查看效果
2. ✅ 登录管理后台
3. ✅ 开始开发OJ系统功能
4. ✅ 配置域名和HTTPS
5. ✅ 设置定期备份

## 📞 获取帮助

如果遇到问题：
1. 查看 `README.md` 和 `README-Linux.md`
2. 运行 `./check-system.sh` 检查系统状态
3. 查看容器日志 `docker-compose logs`
4. 提交Issue到GitHub仓库

---

**现在就开始使用你的OJ系统吧！** 🚀
