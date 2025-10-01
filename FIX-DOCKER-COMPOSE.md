# 修复Docker Compose部署以支持判题功能

## 🎯 目标

让Docker Compose部署的web容器能够运行判题功能。

---

## 🔧 方案：修改配置文件

### 步骤1: 更新docker-compose.yml

添加Docker socket挂载和权限：

```yaml
web:
  build: .
  command: gunicorn --bind 0.0.0.0:8000 config.wsgi:application
  volumes:
    - .:/app
    - static_volume:/app/staticfiles
    - media_volume:/app/media
    - /var/run/docker.sock:/var/run/docker.sock  # ← 添加这行（允许访问宿主机Docker）
  ports:
    - "8000:8000"
  depends_on:
    - db
  environment:
    - DEBUG=False
    - DB_HOST=db
    - DB_NAME=oj_system
    - DB_USER=postgres
    - DB_PASSWORD=postgres
    - DB_PORT=5432
  privileged: true  # ← 添加这行（提供特权访问）
```

### 步骤2: 更新Dockerfile

添加Docker客户端：

```dockerfile
# 在安装系统依赖部分添加
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        postgresql-client \
        build-essential \
        libpq-dev \
        curl \
        ca-certificates \
        gnupg \
    && install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && chmod a+r /etc/apt/keyrings/docker.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y docker-ce-cli \
    && rm -rf /var/lib/apt/lists/*
```

---

## 🚀 完整操作流程

### 1. 停止现有服务（如果有）

```bash
docker-compose down
```

### 2. 备份当前配置

```bash
cp docker-compose.yml docker-compose.yml.backup
cp Dockerfile Dockerfile.backup
```

### 3. 应用修改

手动编辑文件，或使用我提供的修改后的完整文件。

### 4. 重新构建并启动

```bash
# 重新构建镜像
docker-compose build --no-cache

# 启动服务
docker-compose up -d

# 查看状态
docker-compose ps
```

### 5. 验证Docker访问

```bash
# 测试web容器能否访问Docker
docker-compose exec web docker ps

# 应该看到宿主机的容器列表
```

### 6. 运行迁移和初始化

```bash
# 数据库迁移
docker-compose exec web python manage.py migrate

# 初始化语言
docker-compose exec web python manage.py init_languages

# 创建超级用户
docker-compose exec web python manage.py createsuperuser
```

---

## ⚡ 快速修复脚本

自动应用修改：

```bash
#!/bin/bash

# 备份文件
cp docker-compose.yml docker-compose.yml.backup.$(date +%Y%m%d_%H%M%S)

# 使用sed添加配置
# 在web volumes部分添加Docker socket
sed -i '/volumes:/a\      - /var/run/docker.sock:/var/run/docker.sock' docker-compose.yml

# 在web environment之前添加privileged
sed -i '/environment:/i\    privileged: true' docker-compose.yml

echo "配置已更新！"
echo "请运行: docker-compose up -d --build"
```

---

## 📋 完整配置文件模板

见下方创建的文件。

