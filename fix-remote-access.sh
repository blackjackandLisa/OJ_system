#!/bin/bash

# 修复远程访问问题

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🔧 修复远程访问问题${NC}"
echo -e "${BLUE}========================================${NC}"
echo

# 获取IP地址
PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "")
PRIVATE_IP=$(hostname -I | awk '{print $1}' || echo "")

echo -e "${GREEN}服务器IP信息:${NC}"
echo -e "  公网IP: ${BLUE}${PUBLIC_IP:-未获取到}${NC}"
echo -e "  内网IP: ${BLUE}${PRIVATE_IP:-未获取到}${NC}"
echo

# 步骤1: 修复ALLOWED_HOSTS
echo -e "${YELLOW}[步骤 1/4] 修复ALLOWED_HOSTS配置...${NC}"

if [ ! -f .env ]; then
    echo -e "${YELLOW}创建.env文件...${NC}"
    cp env.example .env
fi

# 构建ALLOWED_HOSTS
ALLOWED_HOSTS="localhost,127.0.0.1,0.0.0.0"
if [ -n "$PRIVATE_IP" ]; then
    ALLOWED_HOSTS="$ALLOWED_HOSTS,$PRIVATE_IP"
fi
if [ -n "$PUBLIC_IP" ]; then
    ALLOWED_HOSTS="$ALLOWED_HOSTS,$PUBLIC_IP"
fi

# 更新.env
if grep -q "^ALLOWED_HOSTS=" .env; then
    sed -i "s/^ALLOWED_HOSTS=.*/ALLOWED_HOSTS=$ALLOWED_HOSTS/" .env
else
    echo "ALLOWED_HOSTS=$ALLOWED_HOSTS" >> .env
fi

# 确保DEBUG=True（开发环境）
if grep -q "^DEBUG=" .env; then
    sed -i "s/^DEBUG=.*/DEBUG=True/" .env
else
    echo "DEBUG=True" >> .env
fi

echo -e "${GREEN}✓ ALLOWED_HOSTS已更新: $ALLOWED_HOSTS${NC}"
echo

# 步骤2: 开放防火墙端口
echo -e "${YELLOW}[步骤 2/4] 配置防火墙...${NC}"

# UFW
if command -v ufw &> /dev/null; then
    if sudo ufw status 2>/dev/null | grep -q "Status: active"; then
        echo "  检测到UFW防火墙，正在开放8000端口..."
        sudo ufw allow 8000/tcp 2>/dev/null
        echo -e "${GREEN}✓ UFW规则已添加${NC}"
    fi
fi

# firewalld
if command -v firewall-cmd &> /dev/null; then
    if systemctl is-active --quiet firewalld; then
        echo "  检测到firewalld，正在开放8000端口..."
        sudo firewall-cmd --permanent --add-port=8000/tcp 2>/dev/null
        sudo firewall-cmd --reload 2>/dev/null
        echo -e "${GREEN}✓ firewalld规则已添加${NC}"
    fi
fi

echo -e "${GREEN}✓ 防火墙配置完成${NC}"
echo

# 步骤3: 确保Docker配置正确
echo -e "${YELLOW}[步骤 3/4] 检查Docker配置...${NC}"

# 检测使用的compose文件
if docker-compose -f docker-compose.fast.yml ps -q web &>/dev/null 2>&1; then
    COMPOSE_FILE="docker-compose.fast.yml"
elif docker-compose -f docker-compose.cn.yml ps -q web &>/dev/null 2>&1; then
    COMPOSE_FILE="docker-compose.cn.yml"
else
    COMPOSE_FILE="docker-compose.yml"
fi

echo "  使用的配置文件: $COMPOSE_FILE"

# 检查端口配置
if grep -q "127.0.0.1:8000:8000" $COMPOSE_FILE; then
    echo -e "${YELLOW}  发现端口仅绑定到127.0.0.1，正在修复...${NC}"
    sed -i 's/127.0.0.1:8000:8000/0.0.0.0:8000:8000/g' $COMPOSE_FILE
    echo -e "${GREEN}✓ 端口配置已修复${NC}"
elif grep -q "\"8000:8000\"" $COMPOSE_FILE || grep -q "'8000:8000'" $COMPOSE_FILE; then
    echo -e "${GREEN}✓ 端口配置正确${NC}"
fi

echo

# 步骤4: 重启服务
echo -e "${YELLOW}[步骤 4/4] 重启服务以应用更改...${NC}"
docker-compose -f $COMPOSE_FILE restart web

echo -e "${YELLOW}等待服务启动...${NC}"
sleep 5

echo -e "${GREEN}✓ 服务已重启${NC}"
echo

# 测试访问
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🧪 测试访问${NC}"
echo -e "${BLUE}========================================${NC}"
echo

echo -e "${YELLOW}本地测试:${NC}"
for addr in "localhost:8000" "127.0.0.1:8000"; do
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "http://$addr/api/info/" 2>/dev/null || echo "000")
    if [ "$RESPONSE" = "200" ]; then
        echo -e "  ${GREEN}✓ http://$addr - OK${NC}"
    else
        echo -e "  ${RED}✗ http://$addr - 失败 (HTTP $RESPONSE)${NC}"
    fi
done

if [ -n "$PRIVATE_IP" ]; then
    echo
    echo -e "${YELLOW}内网IP测试:${NC}"
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "http://$PRIVATE_IP:8000/api/info/" 2>/dev/null || echo "000")
    if [ "$RESPONSE" = "200" ]; then
        echo -e "  ${GREEN}✓ http://$PRIVATE_IP:8000 - OK${NC}"
    else
        echo -e "  ${RED}✗ http://$PRIVATE_IP:8000 - 失败 (HTTP $RESPONSE)${NC}"
        echo -e "  ${YELLOW}  如果失败，可能是云服务器安全组问题${NC}"
    fi
fi

echo

# 显示访问地址
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🌐 访问地址${NC}"
echo -e "${BLUE}========================================${NC}"
echo

echo -e "${GREEN}现在可以通过以下地址访问:${NC}"
echo
echo -e "  ${BLUE}本地访问:${NC}"
echo -e "    http://localhost:8000"
echo -e "    http://127.0.0.1:8000"
echo

if [ -n "$PRIVATE_IP" ]; then
    echo -e "  ${BLUE}内网访问:${NC}"
    echo -e "    http://$PRIVATE_IP:8000"
    echo
fi

if [ -n "$PUBLIC_IP" ]; then
    echo -e "  ${BLUE}公网访问:${NC}"
    echo -e "    http://$PUBLIC_IP:8000"
    echo
fi

echo -e "  ${BLUE}主要页面:${NC}"
echo -e "    主页: /"
echo -e "    管理后台: /admin"
echo -e "    API接口: /api/info/"
echo

# 检查云服务器安全组
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}☁️  云服务器提示${NC}"
echo -e "${BLUE}========================================${NC}"
echo

echo -e "${YELLOW}如果通过公网IP仍无法访问，请检查:${NC}"
echo
echo -e "  ${BLUE}阿里云:${NC} 在ECS安全组中添加入站规则"
echo -e "    端口: 8000"
echo -e "    协议: TCP"
echo -e "    授权对象: 0.0.0.0/0"
echo
echo -e "  ${BLUE}腾讯云:${NC} 在安全组中添加入站规则"
echo -e "    端口: 8000"
echo -e "    协议: TCP"
echo -e "    来源: 0.0.0.0/0"
echo
echo -e "  ${BLUE}AWS:${NC} 在Security Groups中添加Inbound Rules"
echo -e "    Type: Custom TCP"
echo -e "    Port: 8000"
echo -e "    Source: 0.0.0.0/0"
echo

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ 修复完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo

echo -e "${YELLOW}💡 提示:${NC}"
echo -e "  1. 查看日志: docker-compose logs -f web"
echo -e "  2. 查看状态: docker-compose ps"
echo -e "  3. 重启服务: docker-compose restart"
echo
