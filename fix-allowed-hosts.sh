#!/bin/bash

# 修复Django ALLOWED_HOSTS配置

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🔧 修复ALLOWED_HOSTS配置${NC}"
echo -e "${BLUE}========================================${NC}"
echo

# 获取服务器IP
echo -e "${YELLOW}获取服务器IP地址...${NC}"
PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "")
PRIVATE_IP=$(hostname -I | awk '{print $1}' || echo "")

echo -e "${GREEN}公网IP: ${PUBLIC_IP:-未获取到}${NC}"
echo -e "${GREEN}内网IP: ${PRIVATE_IP:-未获取到}${NC}"

# 检查.env文件
if [ ! -f .env ]; then
    echo -e "${RED}.env文件不存在，正在创建...${NC}"
    cp env.example .env
fi

# 备份.env文件
echo -e "${YELLOW}备份.env文件...${NC}"
cp .env .env.backup.$(date +%Y%m%d_%H%M%S)

# 构建ALLOWED_HOSTS
ALLOWED_HOSTS="localhost,127.0.0.1,0.0.0.0"

if [ -n "$PRIVATE_IP" ]; then
    ALLOWED_HOSTS="$ALLOWED_HOSTS,$PRIVATE_IP"
fi

if [ -n "$PUBLIC_IP" ]; then
    ALLOWED_HOSTS="$ALLOWED_HOSTS,$PUBLIC_IP"
fi

# 询问是否添加域名
echo
echo -e "${YELLOW}是否添加域名到ALLOWED_HOSTS? (y/n)${NC}"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo -e "${YELLOW}请输入域名（多个域名用逗号分隔）:${NC}"
    read -r domain
    if [ -n "$domain" ]; then
        ALLOWED_HOSTS="$ALLOWED_HOSTS,$domain"
    fi
fi

# 更新.env文件
echo -e "${YELLOW}更新ALLOWED_HOSTS配置...${NC}"

if grep -q "^ALLOWED_HOSTS=" .env; then
    # 如果存在，则替换
    sed -i "s/^ALLOWED_HOSTS=.*/ALLOWED_HOSTS=$ALLOWED_HOSTS/" .env
else
    # 如果不存在，则添加
    echo "ALLOWED_HOSTS=$ALLOWED_HOSTS" >> .env
fi

echo -e "${GREEN}✅ ALLOWED_HOSTS已更新为:${NC}"
echo -e "   ${BLUE}$ALLOWED_HOSTS${NC}"

# 检测使用的docker-compose文件
if docker-compose -f docker-compose.fast.yml ps -q web &>/dev/null 2>&1; then
    COMPOSE_FILE="docker-compose.fast.yml"
elif docker-compose -f docker-compose.cn.yml ps -q web &>/dev/null 2>&1; then
    COMPOSE_FILE="docker-compose.cn.yml"
else
    COMPOSE_FILE="docker-compose.yml"
fi

# 重启服务
echo
echo -e "${YELLOW}需要重启服务以应用更改${NC}"
echo -e "${YELLOW}是否现在重启? (y/n)${NC}"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo -e "${YELLOW}正在重启服务...${NC}"
    docker-compose -f $COMPOSE_FILE restart web
    
    echo -e "${YELLOW}等待服务启动...${NC}"
    sleep 5
    
    echo -e "${GREEN}✅ 服务已重启${NC}"
else
    echo -e "${YELLOW}请手动重启服务:${NC}"
    echo -e "   ${BLUE}docker-compose -f $COMPOSE_FILE restart web${NC}"
fi

echo
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}🎉 配置完成！${NC}"
echo -e "${BLUE}========================================${NC}"
echo

echo -e "${GREEN}现在可以通过以下地址访问:${NC}"
echo -e "  ${BLUE}http://localhost:8000${NC}"
echo -e "  ${BLUE}http://127.0.0.1:8000${NC}"

if [ -n "$PRIVATE_IP" ]; then
    echo -e "  ${BLUE}http://$PRIVATE_IP:8000${NC}"
fi

if [ -n "$PUBLIC_IP" ]; then
    echo -e "  ${BLUE}http://$PUBLIC_IP:8000${NC}"
fi

echo
echo -e "${YELLOW}💡 提示:${NC}"
echo -e "  - 如果通过Nginx访问，也需要配置Nginx${NC}"
echo -e "  - 生产环境建议配置具体的域名${NC}"
echo -e "  - 不建议在生产环境使用 0.0.0.0${NC}"

# 测试访问
echo
echo -e "${YELLOW}测试API访问...${NC}"
sleep 2

for url in "http://localhost:8000/api/info/" "http://127.0.0.1:8000/api/info/"; do
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" $url 2>/dev/null || echo "000")
    if [ "$RESPONSE" = "200" ]; then
        echo -e "  ${GREEN}✓ $url - OK (HTTP $RESPONSE)${NC}"
    else
        echo -e "  ${RED}✗ $url - Failed (HTTP $RESPONSE)${NC}"
    fi
done

if [ -n "$PRIVATE_IP" ]; then
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "http://$PRIVATE_IP:8000/api/info/" 2>/dev/null || echo "000")
    if [ "$RESPONSE" = "200" ]; then
        echo -e "  ${GREEN}✓ http://$PRIVATE_IP:8000/api/info/ - OK (HTTP $RESPONSE)${NC}"
    else
        echo -e "  ${YELLOW}⚠ http://$PRIVATE_IP:8000/api/info/ - (HTTP $RESPONSE)${NC}"
    fi
fi

echo
