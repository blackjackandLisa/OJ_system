#!/bin/bash

set -e

echo "========================================="
echo "OJ判题系统 Docker Compose 部署脚本"
echo "========================================="
echo ""

# 检查Docker是否运行
if ! docker info > /dev/null 2>&1; then
    echo "错误: Docker未运行或未安装"
    echo "请先启动Docker服务: sudo systemctl start docker"
    exit 1
fi

echo "[1/10] 停止现有服务..."
docker-compose down || true

echo "[2/10] 备份现有配置..."
if [ -f docker-compose.yml ]; then
    cp docker-compose.yml docker-compose.yml.backup.$(date +%Y%m%d_%H%M%S)
fi
if [ -f Dockerfile ]; then
    cp Dockerfile Dockerfile.backup.$(date +%Y%m%d_%H%M%S)
fi

echo "[3/10] 使用支持判题的配置文件..."
cp docker-compose.judge.yml docker-compose.yml
cp Dockerfile.judge Dockerfile

echo "[4/10] 构建判题镜像（可能需要5-10分钟）..."
cd docker/judge
./build-images.sh
cd ../..

echo "[5/10] 构建web镜像..."
docker-compose build --no-cache

echo "[6/10] 启动所有服务..."
docker-compose up -d

echo "[7/10] 等待服务启动..."
sleep 15

echo "[8/10] 运行数据库迁移..."
docker-compose exec -T web python manage.py migrate

echo "[9/10] 初始化编程语言..."
docker-compose exec -T web python manage.py init_languages

echo "[10/10] 验证Docker访问..."
if docker-compose exec -T web docker ps > /dev/null 2>&1; then
    echo "✓ web容器可以访问Docker"
else
    echo "✗ web容器无法访问Docker，判题功能可能不可用"
fi

echo ""
echo "========================================="
echo "部署完成！"
echo "========================================="
echo ""
echo "服务状态:"
docker-compose ps
echo ""
echo "查看判题镜像:"
docker images | grep oj-judge
echo ""
echo "下一步操作:"
echo "1. 创建超级用户: docker-compose exec web python manage.py createsuperuser"
echo "2. 访问管理后台: http://your-server-ip/admin/"
echo "3. 查看日志: docker-compose logs -f web"
echo "4. 测试判题: 参考 DOCKER-COMPOSE-DEPLOY.md"
echo ""

