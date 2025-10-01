#!/bin/bash

# 快速检查远程访问配置

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🔍 快速访问检查${NC}"
echo -e "${BLUE}========================================${NC}"
echo

# 获取IP
PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "未获取")
echo -e "${YELLOW}服务器公网IP: ${GREEN}$PUBLIC_IP${NC}"
echo

# 检查1: Docker服务
echo -e "${YELLOW}[1/5] 检查Docker服务...${NC}"
if docker-compose ps | grep -q "Up"; then
    echo -e "  ${GREEN}✓ Docker服务运行中${NC}"
else
    echo -e "  ${RED}✗ Docker服务未运行${NC}"
    echo -e "  ${YELLOW}  运行: docker-compose up -d${NC}"
fi

# 检查2: 端口监听
echo -e "${YELLOW}[2/5] 检查端口监听...${NC}"
if netstat -tuln | grep -q ":8000 "; then
    listen_addr=$(netstat -tuln | grep ":8000 " | awk '{print $4}')
    if echo "$listen_addr" | grep -q "0.0.0.0:8000\|:::8000"; then
        echo -e "  ${GREEN}✓ 8000端口监听所有网卡${NC}"
    else
        echo -e "  ${RED}✗ 8000端口仅监听: $listen_addr${NC}"
    fi
else
    echo -e "  ${RED}✗ 8000端口未监听${NC}"
fi

# 检查3: ALLOWED_HOSTS
echo -e "${YELLOW}[3/5] 检查ALLOWED_HOSTS配置...${NC}"
if [ -f .env ] && grep -q "^ALLOWED_HOSTS=" .env; then
    allowed=$(grep "^ALLOWED_HOSTS=" .env | cut -d= -f2)
    echo -e "  ${GREEN}✓ ALLOWED_HOSTS: $allowed${NC}"
    if echo "$allowed" | grep -q "\*\|$PUBLIC_IP"; then
        echo -e "  ${GREEN}✓ 包含公网IP或允许所有${NC}"
    else
        echo -e "  ${RED}✗ 未包含公网IP: $PUBLIC_IP${NC}"
        echo -e "  ${YELLOW}  运行: ./fix-allowed-hosts.sh${NC}"
    fi
else
    echo -e "  ${RED}✗ ALLOWED_HOSTS未配置${NC}"
fi

# 检查4: 系统防火墙
echo -e "${YELLOW}[4/5] 检查系统防火墙...${NC}"
if command -v ufw &> /dev/null && sudo ufw status 2>/dev/null | grep -q "Status: active"; then
    if sudo ufw status | grep -q "8000"; then
        echo -e "  ${GREEN}✓ UFW已开放8000端口${NC}"
    else
        echo -e "  ${RED}✗ UFW未开放8000端口${NC}"
        echo -e "  ${YELLOW}  运行: sudo ufw allow 8000${NC}"
    fi
elif command -v firewall-cmd &> /dev/null && systemctl is-active --quiet firewalld; then
    if sudo firewall-cmd --list-ports 2>/dev/null | grep -q "8000"; then
        echo -e "  ${GREEN}✓ firewalld已开放8000端口${NC}"
    else
        echo -e "  ${RED}✗ firewalld未开放8000端口${NC}"
        echo -e "  ${YELLOW}  运行: sudo firewall-cmd --permanent --add-port=8000/tcp${NC}"
        echo -e "  ${YELLOW}       sudo firewall-cmd --reload${NC}"
    fi
else
    echo -e "  ${GREEN}✓ 系统防火墙未启用或未检测到${NC}"
fi

# 检查5: 访问测试
echo -e "${YELLOW}[5/5] 测试访问...${NC}"

# 本地测试
LOCALHOST_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/api/info/ 2>/dev/null || echo "000")
if [ "$LOCALHOST_RESPONSE" = "200" ]; then
    echo -e "  ${GREEN}✓ 本地访问正常 (localhost:8000)${NC}"
else
    echo -e "  ${RED}✗ 本地访问失败 (HTTP $LOCALHOST_RESPONSE)${NC}"
fi

# 公网IP测试
if [ "$PUBLIC_IP" != "未获取" ]; then
    PUBLIC_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://$PUBLIC_IP:8000/api/info/ 2>/dev/null || echo "000")
    if [ "$PUBLIC_RESPONSE" = "200" ]; then
        echo -e "  ${GREEN}✓ 公网访问正常 ($PUBLIC_IP:8000)${NC}"
    elif [ "$PUBLIC_RESPONSE" = "000" ]; then
        echo -e "  ${RED}✗ 公网访问连接失败${NC}"
        echo -e "  ${YELLOW}  可能原因: 云服务器控制台防火墙未开放${NC}"
    elif [ "$PUBLIC_RESPONSE" = "400" ]; then
        echo -e "  ${RED}✗ 公网访问返回400 (ALLOWED_HOSTS问题)${NC}"
        echo -e "  ${YELLOW}  运行: ./fix-allowed-hosts.sh${NC}"
    else
        echo -e "  ${RED}✗ 公网访问失败 (HTTP $PUBLIC_RESPONSE)${NC}"
    fi
fi

echo
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}📋 诊断总结${NC}"
echo -e "${BLUE}========================================${NC}"
echo

# 判断主要问题
if [ "$PUBLIC_RESPONSE" = "000" ]; then
    echo -e "${RED}❌ 主要问题: 无法连接到服务器${NC}"
    echo
    echo -e "${YELLOW}最可能的原因（按优先级）:${NC}"
    echo -e "  ${RED}1. 云服务器控制台防火墙未开放8000端口 ⭐⭐⭐⭐⭐${NC}"
    echo -e "     ${BLUE}解决方法:${NC}"
    echo -e "     • 登录云服务商控制台（阿里云/腾讯云/华为云）"
    echo -e "     • 找到轻量应用服务器的防火墙配置"
    echo -e "     • 添加规则: TCP 8000，允许所有IP (0.0.0.0/0)"
    echo
    echo -e "  ${YELLOW}2. 系统防火墙阻止${NC}"
    echo -e "     ${BLUE}解决方法: sudo ufw allow 8000${NC}"
    echo
    echo -e "  ${YELLOW}3. Docker服务未运行${NC}"
    echo -e "     ${BLUE}解决方法: docker-compose up -d${NC}"
    echo
    
elif [ "$PUBLIC_RESPONSE" = "400" ]; then
    echo -e "${RED}❌ 主要问题: ALLOWED_HOSTS配置${NC}"
    echo
    echo -e "${YELLOW}解决方法:${NC}"
    echo -e "  ${GREEN}./fix-allowed-hosts.sh${NC}"
    echo
    
elif [ "$PUBLIC_RESPONSE" = "200" ]; then
    echo -e "${GREEN}✅ 所有检查通过！系统可以正常访问${NC}"
    echo
    echo -e "${BLUE}访问地址:${NC}"
    echo -e "  主页: ${GREEN}http://$PUBLIC_IP:8000${NC}"
    echo -e "  管理后台: ${GREEN}http://$PUBLIC_IP:8000/admin${NC}"
    echo -e "  API接口: ${GREEN}http://$PUBLIC_IP:8000/api/info/${NC}"
    echo
else
    echo -e "${YELLOW}⚠️  部分配置可能有问题${NC}"
    echo
    echo -e "${YELLOW}建议操作:${NC}"
    echo -e "  1. 运行完整诊断: ${GREEN}./diagnose-network.sh${NC}"
    echo -e "  2. 运行自动修复: ${GREEN}./fix-remote-access.sh${NC}"
    echo -e "  3. 查看详细日志: ${GREEN}docker-compose logs web${NC}"
    echo
fi

# 控制台配置提示
if [ "$PUBLIC_RESPONSE" != "200" ]; then
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}☁️  轻量应用服务器控制台配置${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo
    echo -e "${YELLOW}阿里云轻量应用服务器:${NC}"
    echo -e "  1. 访问: ${BLUE}https://swas.console.aliyun.com/${NC}"
    echo -e "  2. 选择你的服务器 → 防火墙"
    echo -e "  3. 添加规则: TCP 8000，策略-允许"
    echo
    echo -e "${YELLOW}腾讯云轻量应用服务器:${NC}"
    echo -e "  1. 访问: ${BLUE}https://console.cloud.tencent.com/lighthouse/${NC}"
    echo -e "  2. 选择实例 → 防火墙"
    echo -e "  3. 添加规则: TCP:8000，来源-0.0.0.0/0"
    echo
    echo -e "${YELLOW}查看详细指南:${NC}"
    echo -e "  ${GREEN}cat LIGHTWEIGHT-SERVER-GUIDE.md${NC}"
    echo
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}检查完成！${NC}"
echo -e "${BLUE}========================================${NC}"
