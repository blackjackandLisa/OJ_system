#!/bin/bash

# 快速部署脚本 - 使用国内镜像源加速构建

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}⚡ OJ系统快速部署脚本${NC}"
echo -e "${BLUE}========================================${NC}"
echo

# 检查Docker环境
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker未安装，请先安装Docker${NC}"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}Docker Compose未安装，请先安装Docker Compose${NC}"
    exit 1
fi

# 创建环境配置文件
if [ ! -f .env ]; then
    echo -e "${YELLOW}创建环境配置文件...${NC}"
    cp env.example .env
    
    # 生成安全的SECRET_KEY
    SECRET_KEY=$(openssl rand -base64 32)
    sed -i "s/your-secret-key-here/$SECRET_KEY/" .env
    sed -i 's/DEBUG=True/DEBUG=False/' .env
    
    echo -e "${GREEN}环境配置文件已创建${NC}"
fi

# 停止现有容器
echo -e "${YELLOW}停止现有容器...${NC}"
docker-compose down 2>/dev/null || true
docker-compose -f docker-compose.cn.yml down 2>/dev/null || true
docker-compose -f docker-compose.fast.yml down 2>/dev/null || true

# 清理Docker缓存
echo -e "${YELLOW}清理Docker缓存...${NC}"
docker system prune -f

# 选择部署方式
echo -e "${BLUE}选择部署方式:${NC}"
echo "1) 快速构建 (使用国内镜像源，推荐)"
echo "2) 标准构建"
echo "3) 国内优化构建"

read -p "请选择 (1-3): " choice

case $choice in
    1)
        COMPOSE_FILE="docker-compose.fast.yml"
        echo -e "${GREEN}使用快速构建模式${NC}"
        ;;
    2)
        COMPOSE_FILE="docker-compose.yml"
        echo -e "${GREEN}使用标准构建模式${NC}"
        ;;
    3)
        COMPOSE_FILE="docker-compose.cn.yml"
        echo -e "${GREEN}使用国内优化构建模式${NC}"
        ;;
    *)
        COMPOSE_FILE="docker-compose.fast.yml"
        echo -e "${YELLOW}使用默认快速构建模式${NC}"
        ;;
esac

# 构建和启动服务
echo -e "${YELLOW}开始构建和启动服务...${NC}"
echo -e "${BLUE}这可能需要几分钟时间，请耐心等待...${NC}"

# 显示构建进度
docker-compose -f $COMPOSE_FILE up --build -d

# 等待服务启动
echo -e "${YELLOW}等待服务启动...${NC}"
sleep 15

# 检查容器状态
echo -e "${YELLOW}检查容器状态...${NC}"
docker-compose -f $COMPOSE_FILE ps

# 运行数据库迁移
echo -e "${YELLOW}运行数据库迁移...${NC}"
docker-compose -f $COMPOSE_FILE exec -T web python manage.py migrate

# 创建超级用户
echo -e "${YELLOW}是否创建超级用户? (y/n): ${NC}"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    docker-compose -f $COMPOSE_FILE exec web python manage.py createsuperuser
fi

# 收集静态文件
echo -e "${YELLOW}收集静态文件...${NC}"
docker-compose -f $COMPOSE_FILE exec -T web python manage.py collectstatic --noinput

# 显示部署结果
echo
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}🎉 部署完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo

# 获取服务器IP
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "your-server-ip")

echo -e "${BLUE}访问地址:${NC}"
echo -e "主页: ${GREEN}http://$SERVER_IP${NC}"
echo -e "管理后台: ${GREEN}http://$SERVER_IP/admin${NC}"
echo -e "API接口: ${GREEN}http://$SERVER_IP/api/info/${NC}"
echo

echo -e "${BLUE}管理命令:${NC}"
echo -e "查看日志: ${YELLOW}docker-compose -f $COMPOSE_FILE logs -f${NC}"
echo -e "重启服务: ${YELLOW}docker-compose -f $COMPOSE_FILE restart${NC}"
echo -e "停止服务: ${YELLOW}docker-compose -f $COMPOSE_FILE down${NC}"
echo

echo -e "${BLUE}容器状态:${NC}"
docker-compose -f $COMPOSE_FILE ps
