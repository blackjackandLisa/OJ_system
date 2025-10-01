#!/bin/bash

# 启动OJ系统服务

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🚀 启动OJ系统服务${NC}"
echo -e "${BLUE}========================================${NC}"
echo

# 检测使用的docker-compose文件
if [ -f "docker-compose.fast.yml" ] && docker-compose -f docker-compose.fast.yml ps -q web &>/dev/null; then
    COMPOSE_FILE="docker-compose.fast.yml"
    echo -e "${GREEN}检测到快速部署版本${NC}"
elif [ -f "docker-compose.cn.yml" ] && docker-compose -f docker-compose.cn.yml ps -q web &>/dev/null; then
    COMPOSE_FILE="docker-compose.cn.yml"
    echo -e "${GREEN}检测到国内优化版本${NC}"
else
    COMPOSE_FILE="docker-compose.yml"
    echo -e "${GREEN}使用标准版本${NC}"
fi

echo

# 检查容器状态
echo -e "${YELLOW}检查容器状态...${NC}"
docker-compose -f $COMPOSE_FILE ps

echo

# 检查是否有容器在运行
if docker-compose -f $COMPOSE_FILE ps -q web | grep -q .; then
    echo -e "${GREEN}✅ 服务已经在运行中${NC}"
    
    # 检查容器健康状态
    WEB_STATUS=$(docker-compose -f $COMPOSE_FILE ps web | grep "Up" || echo "")
    DB_STATUS=$(docker-compose -f $COMPOSE_FILE ps db | grep "Up" || echo "")
    NGINX_STATUS=$(docker-compose -f $COMPOSE_FILE ps nginx | grep "Up" || echo "")
    
    if [ -n "$WEB_STATUS" ]; then
        echo -e "  ${GREEN}✓${NC} Web服务运行正常"
    else
        echo -e "  ${RED}✗${NC} Web服务未运行"
    fi
    
    if [ -n "$DB_STATUS" ]; then
        echo -e "  ${GREEN}✓${NC} 数据库服务运行正常"
    else
        echo -e "  ${RED}✗${NC} 数据库服务未运行"
    fi
    
    if [ -n "$NGINX_STATUS" ]; then
        echo -e "  ${GREEN}✓${NC} Nginx服务运行正常"
    else
        echo -e "  ${YELLOW}!${NC} Nginx服务未运行（可能未配置）"
    fi
    
else
    echo -e "${YELLOW}服务未运行，正在启动...${NC}"
    docker-compose -f $COMPOSE_FILE up -d
    
    echo -e "${YELLOW}等待服务启动...${NC}"
    sleep 10
    
    # 再次检查状态
    docker-compose -f $COMPOSE_FILE ps
fi

echo
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}📊 服务信息${NC}"
echo -e "${BLUE}========================================${NC}"
echo

# 获取服务器IP
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || hostname -I | awk '{print $1}')

# 检查端口映射
WEB_PORT=$(docker-compose -f $COMPOSE_FILE ps web | grep -oP '0.0.0.0:\K[0-9]+' | head -1 || echo "8000")
NGINX_PORT=$(docker-compose -f $COMPOSE_FILE ps nginx | grep -oP '0.0.0.0:\K[0-9]+' | head -1 || echo "")

echo -e "${GREEN}🌐 访问地址:${NC}"
echo

if [ -n "$NGINX_PORT" ]; then
    echo -e "  ${BLUE}主页:${NC}       http://$SERVER_IP:$NGINX_PORT"
    echo -e "  ${BLUE}管理后台:${NC}   http://$SERVER_IP:$NGINX_PORT/admin"
    echo -e "  ${BLUE}API接口:${NC}    http://$SERVER_IP:$NGINX_PORT/api/info/"
else
    echo -e "  ${BLUE}主页:${NC}       http://$SERVER_IP:$WEB_PORT"
    echo -e "  ${BLUE}管理后台:${NC}   http://$SERVER_IP:$WEB_PORT/admin"
    echo -e "  ${BLUE}API接口:${NC}    http://$SERVER_IP:$WEB_PORT/api/info/"
fi

echo
echo -e "${GREEN}📱 本地访问:${NC}"
if [ -n "$NGINX_PORT" ]; then
    echo -e "  http://localhost:$NGINX_PORT"
else
    echo -e "  http://localhost:$WEB_PORT"
fi

echo
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🔧 常用管理命令${NC}"
echo -e "${BLUE}========================================${NC}"
echo

echo -e "${YELLOW}查看日志:${NC}"
echo -e "  docker-compose -f $COMPOSE_FILE logs -f"
echo

echo -e "${YELLOW}查看Web日志:${NC}"
echo -e "  docker-compose -f $COMPOSE_FILE logs -f web"
echo

echo -e "${YELLOW}重启服务:${NC}"
echo -e "  docker-compose -f $COMPOSE_FILE restart"
echo

echo -e "${YELLOW}停止服务:${NC}"
echo -e "  docker-compose -f $COMPOSE_FILE down"
echo

echo -e "${YELLOW}查看容器状态:${NC}"
echo -e "  docker-compose -f $COMPOSE_FILE ps"
echo

echo -e "${YELLOW}进入Web容器:${NC}"
echo -e "  docker-compose -f $COMPOSE_FILE exec web bash"
echo

echo -e "${YELLOW}进入数据库:${NC}"
echo -e "  docker-compose -f $COMPOSE_FILE exec db psql -U postgres -d oj_system"
echo

# 测试API接口
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🧪 测试服务连接${NC}"
echo -e "${BLUE}========================================${NC}"
echo

echo -e "${YELLOW}测试API接口...${NC}"

if [ -n "$NGINX_PORT" ]; then
    API_URL="http://localhost:$NGINX_PORT/api/info/"
else
    API_URL="http://localhost:$WEB_PORT/api/info/"
fi

# 等待服务完全启动
sleep 3

RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" $API_URL 2>/dev/null || echo "000")

if [ "$RESPONSE" = "200" ]; then
    echo -e "${GREEN}✅ API接口响应正常 (HTTP $RESPONSE)${NC}"
    echo -e "${GREEN}服务已经可以访问了！${NC}"
elif [ "$RESPONSE" = "000" ]; then
    echo -e "${YELLOW}⏳ 服务正在启动中，请稍等片刻...${NC}"
else
    echo -e "${YELLOW}⚠️  API接口返回 HTTP $RESPONSE${NC}"
    echo -e "${YELLOW}服务可能还在启动中，请稍后访问${NC}"
fi

echo
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✅ 启动完成！${NC}"
echo -e "${BLUE}========================================${NC}"
echo

echo -e "${YELLOW}💡 提示:${NC}"
echo -e "  1. 首次访问管理后台需要创建超级用户"
echo -e "  2. 如需创建超级用户，运行:"
echo -e "     ${GREEN}docker-compose -f $COMPOSE_FILE exec web python manage.py createsuperuser${NC}"
echo -e "  3. 查看实时日志:"
echo -e "     ${GREEN}docker-compose -f $COMPOSE_FILE logs -f${NC}"
echo
