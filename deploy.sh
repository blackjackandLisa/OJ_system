#!/bin/bash

# OJ系统部署脚本
echo "开始部署OJ系统..."

# 检查Docker是否安装
if ! command -v docker &> /dev/null; then
    echo "错误: Docker未安装，请先安装Docker"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "错误: Docker Compose未安装，请先安装Docker Compose"
    exit 1
fi

# 创建环境配置文件
if [ ! -f .env ]; then
    echo "创建环境配置文件..."
    cp env.example .env
    echo "请编辑.env文件配置数据库和其他设置"
fi

# 停止现有容器
echo "停止现有容器..."
docker-compose down

# 构建并启动服务
echo "构建并启动服务..."
docker-compose up --build -d

# 等待数据库启动
echo "等待数据库启动..."
sleep 10

# 运行数据库迁移
echo "运行数据库迁移..."
docker-compose exec web python manage.py migrate

# 创建超级用户（可选）
echo "是否创建超级用户? (y/n)"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    docker-compose exec web python manage.py createsuperuser
fi

# 收集静态文件
echo "收集静态文件..."
docker-compose exec web python manage.py collectstatic --noinput

echo "部署完成！"
echo "访问地址: http://localhost"
echo "管理后台: http://localhost/admin"
echo "API接口: http://localhost/api/info/"

# 显示容器状态
echo "容器状态:"
docker-compose ps
