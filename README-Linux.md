# OJ系统 - Linux部署指南

基于Django + DRF + Bootstrap + PostgreSQL构建的在线判题系统，专为Linux服务器部署优化。

## 🎯 系统要求

### 最低配置
- **CPU**: 1核心
- **内存**: 2GB RAM
- **存储**: 10GB 可用空间
- **网络**: 公网IP或域名

### 推荐配置
- **CPU**: 2核心
- **内存**: 4GB RAM
- **存储**: 20GB SSD
- **网络**: 100Mbps带宽

### 支持的操作系统
- Ubuntu 18.04+ (推荐 20.04+)
- Debian 10+
- CentOS 7+ / RHEL 7+
- Amazon Linux 2

## 🚀 快速部署

### 1. 系统检查
```bash
# 下载项目
git clone https://github.com/blackjackandLisa/OJ_system.git
cd OJ_system

# 检查系统环境
chmod +x check-system.sh
./check-system.sh
```

### 2. 一键部署
```bash
# 给脚本执行权限
chmod +x deploy-linux.sh

# 运行部署脚本
./deploy-linux.sh
```

### 3. 访问系统
部署完成后，访问以下地址：
- **主页**: http://your-server-ip
- **管理后台**: http://your-server-ip/admin
- **API接口**: http://your-server-ip/api/info/

## 📋 详细部署步骤

### 步骤1: 准备服务器

#### 更新系统包
```bash
# Ubuntu/Debian
sudo apt update && sudo apt upgrade -y

# CentOS/RHEL
sudo yum update -y
```

#### 安装必要工具
```bash
# Ubuntu/Debian
sudo apt install -y curl wget git vim net-tools

# CentOS/RHEL
sudo yum install -y curl wget git vim net-tools
```

### 步骤2: 安装Docker

#### 自动安装（推荐）
```bash
# 使用官方脚本安装
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# 启动Docker服务
sudo systemctl start docker
sudo systemctl enable docker

# 将当前用户添加到docker组
sudo usermod -aG docker $USER
newgrp docker
```

#### 手动安装
```bash
# Ubuntu/Debian
sudo apt install -y docker.io docker-compose

# CentOS/RHEL
sudo yum install -y docker docker-compose
```

### 步骤3: 配置防火墙

#### UFW (Ubuntu)
```bash
# 安装UFW
sudo apt install -y ufw

# 配置防火墙规则
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw enable
```

#### FirewallD (CentOS/RHEL)
```bash
# 配置防火墙规则
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

### 步骤4: 部署应用

```bash
# 克隆项目
git clone https://github.com/blackjackandLisa/OJ_system.git
cd OJ_system

# 配置环境
cp env.example .env
vim .env  # 编辑配置文件

# 运行部署脚本
chmod +x deploy-linux.sh
./deploy-linux.sh
```

## ⚙️ 环境配置

### .env 文件配置
```env
# Django设置
SECRET_KEY=your-very-secret-key-here
DEBUG=False
ALLOWED_HOSTS=your-domain.com,your-server-ip

# 数据库设置
DB_NAME=oj_system
DB_USER=postgres
DB_PASSWORD=your-secure-password
DB_HOST=db
DB_PORT=5432
```

### 重要配置说明
- **SECRET_KEY**: 使用强密码，建议32位随机字符串
- **DEBUG**: 生产环境必须设为False
- **ALLOWED_HOSTS**: 添加你的域名和IP地址
- **DB_PASSWORD**: 使用强密码保护数据库

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
# 进入数据库容器
docker-compose exec db psql -U postgres -d oj_system

# 备份数据库
docker-compose exec db pg_dump -U postgres oj_system > backup.sql

# 恢复数据库
docker-compose exec -T db psql -U postgres oj_system < backup.sql
```

### 日志管理
```bash
# 查看应用日志
docker-compose logs web

# 查看数据库日志
docker-compose logs db

# 查看Nginx日志
docker-compose logs nginx

# 清理日志
docker-compose logs --tail=0 -f
```

## 🛡️ 安全配置

### 1. 修改默认密码
```bash
# 修改数据库密码
docker-compose exec web python manage.py changepassword admin

# 或创建新的超级用户
docker-compose exec web python manage.py createsuperuser
```

### 2. 配置HTTPS
```bash
# 使用Let's Encrypt获取免费SSL证书
sudo apt install -y certbot
sudo certbot certonly --standalone -d your-domain.com

# 修改nginx.conf配置HTTPS
# 然后重启服务
docker-compose restart nginx
```

### 3. 设置定期备份
```bash
# 创建备份脚本
cat > backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/opt/oj_backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# 备份数据库
docker-compose exec -T db pg_dump -U postgres oj_system > $BACKUP_DIR/db_$DATE.sql

# 备份媒体文件
tar -czf $BACKUP_DIR/media_$DATE.tar.gz media/

# 清理30天前的备份
find $BACKUP_DIR -name "*.sql" -mtime +30 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +30 -delete
EOF

chmod +x backup.sh

# 设置定时任务
crontab -e
# 添加以下行，每天凌晨2点备份
# 0 2 * * * /path/to/backup.sh
```

## 📊 性能优化

### 1. 数据库优化
```bash
# 进入数据库容器
docker-compose exec db psql -U postgres oj_system

# 创建索引
CREATE INDEX CONCURRENTLY idx_submission_user_id ON submissions(user_id);
CREATE INDEX CONCURRENTLY idx_submission_problem_id ON submissions(problem_id);
```

### 2. 静态文件优化
```bash
# 收集静态文件
docker-compose exec web python manage.py collectstatic --noinput

# 配置Nginx缓存
# 在nginx.conf中添加缓存配置
```

### 3. 监控设置
```bash
# 安装监控工具
sudo apt install -y htop iotop nethogs

# 查看系统资源使用
htop
iotop
nethogs
```

## 🔍 故障排除

### 常见问题

#### 1. 端口被占用
```bash
# 检查端口占用
netstat -tuln | grep :5432

# 停止占用端口的服务
sudo systemctl stop postgresql
```

#### 2. 权限问题
```bash
# 检查Docker权限
docker ps

# 添加用户到docker组
sudo usermod -aG docker $USER
newgrp docker
```

#### 3. 内存不足
```bash
# 检查内存使用
free -h

# 清理Docker资源
docker system prune -f
```

#### 4. 磁盘空间不足
```bash
# 检查磁盘使用
df -h

# 清理Docker镜像
docker image prune -a -f
```

### 日志分析
```bash
# 查看详细错误日志
docker-compose logs web | grep ERROR
docker-compose logs db | grep ERROR
docker-compose logs nginx | grep ERROR
```

## 📞 技术支持

如果遇到问题，请：
1. 检查系统日志：`./check-system.sh`
2. 查看容器日志：`docker-compose logs`
3. 提交Issue到GitHub仓库

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件
