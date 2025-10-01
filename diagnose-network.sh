#!/bin/bash

# 网络访问诊断脚本

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🔍 网络访问诊断${NC}"
echo -e "${BLUE}========================================${NC}"
echo

# 1. 获取IP地址
echo -e "${YELLOW}[1/7] 获取IP地址信息...${NC}"
PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "未获取到")
PRIVATE_IP=$(hostname -I | awk '{print $1}' || echo "未获取到")

echo -e "  公网IP: ${GREEN}$PUBLIC_IP${NC}"
echo -e "  内网IP: ${GREEN}$PRIVATE_IP${NC}"
echo

# 2. 检查端口监听
echo -e "${YELLOW}[2/7] 检查端口监听状态...${NC}"
echo "  检查8000端口:"
if netstat -tuln | grep -q ":8000 "; then
    netstat -tuln | grep ":8000 " | while read line; do
        listen_addr=$(echo $line | awk '{print $4}')
        if [[ "$listen_addr" == "0.0.0.0:8000" ]] || [[ "$listen_addr" == "*:8000" ]]; then
            echo -e "    ${GREEN}✓ 监听在所有网卡 ($listen_addr)${NC}"
        elif [[ "$listen_addr" == "127.0.0.1:8000" ]]; then
            echo -e "    ${RED}✗ 仅监听本地 ($listen_addr) - 这是问题所在！${NC}"
            echo -e "    ${YELLOW}  需要修改为监听 0.0.0.0:8000${NC}"
        else
            echo -e "    ${YELLOW}⚠ 监听在 $listen_addr${NC}"
        fi
    done
else
    echo -e "    ${RED}✗ 端口8000未监听${NC}"
fi
echo

# 3. 检查Docker端口映射
echo -e "${YELLOW}[3/7] 检查Docker端口映射...${NC}"
if command -v docker &> /dev/null; then
    # 检测使用的compose文件
    if docker-compose -f docker-compose.fast.yml ps -q web &>/dev/null 2>&1; then
        COMPOSE_FILE="docker-compose.fast.yml"
    elif docker-compose -f docker-compose.cn.yml ps -q web &>/dev/null 2>&1; then
        COMPOSE_FILE="docker-compose.cn.yml"
    else
        COMPOSE_FILE="docker-compose.yml"
    fi
    
    echo "  使用的配置文件: $COMPOSE_FILE"
    echo "  Web服务端口映射:"
    docker-compose -f $COMPOSE_FILE ps web | grep -oP '\d+\.\d+\.\d+\.\d+:\d+->\d+' | while read mapping; do
        echo -e "    ${GREEN}$mapping${NC}"
    done
    
    echo
    echo "  完整容器信息:"
    docker-compose -f $COMPOSE_FILE ps web
else
    echo -e "    ${RED}Docker未安装或未运行${NC}"
fi
echo

# 4. 检查防火墙
echo -e "${YELLOW}[4/7] 检查防火墙状态...${NC}"

# 检查UFW
if command -v ufw &> /dev/null; then
    ufw_status=$(sudo ufw status 2>/dev/null | head -1)
    echo "  UFW: $ufw_status"
    if echo "$ufw_status" | grep -q "active"; then
        echo "  8000端口规则:"
        sudo ufw status | grep 8000 || echo -e "    ${RED}✗ 未找到8000端口规则${NC}"
        echo -e "    ${YELLOW}添加规则: sudo ufw allow 8000${NC}"
    fi
fi

# 检查firewalld
if command -v firewall-cmd &> /dev/null; then
    if systemctl is-active --quiet firewalld; then
        echo "  Firewalld: 活动"
        echo "  开放的端口:"
        sudo firewall-cmd --list-ports 2>/dev/null | grep 8000 || echo -e "    ${RED}✗ 8000端口未开放${NC}"
        echo -e "    ${YELLOW}添加规则: sudo firewall-cmd --permanent --add-port=8000/tcp${NC}"
        echo -e "    ${YELLOW}         sudo firewall-cmd --reload${NC}"
    else
        echo "  Firewalld: 未运行"
    fi
fi

# 检查iptables
if command -v iptables &> /dev/null; then
    echo "  iptables规则数: $(sudo iptables -L -n | wc -l)"
    if sudo iptables -L -n | grep -q "8000"; then
        echo -e "    ${GREEN}✓ 发现8000端口规则${NC}"
    fi
fi
echo

# 5. 测试本地访问
echo -e "${YELLOW}[5/7] 测试本地访问...${NC}"
for addr in "localhost:8000" "127.0.0.1:8000" "$PRIVATE_IP:8000"; do
    if [ "$addr" != ":8000" ]; then
        RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "http://$addr/api/info/" 2>/dev/null || echo "000")
        if [ "$RESPONSE" = "200" ]; then
            echo -e "  ${GREEN}✓ http://$addr - OK (HTTP $RESPONSE)${NC}"
        elif [ "$RESPONSE" = "000" ]; then
            echo -e "  ${RED}✗ http://$addr - 连接失败${NC}"
        else
            echo -e "  ${YELLOW}⚠ http://$addr - HTTP $RESPONSE${NC}"
        fi
    fi
done
echo

# 6. 检查docker-compose配置
echo -e "${YELLOW}[6/7] 检查docker-compose配置...${NC}"
if [ -f "$COMPOSE_FILE" ]; then
    echo "  Web服务端口配置:"
    grep -A 2 "ports:" $COMPOSE_FILE | grep "8000" | while read line; do
        if echo "$line" | grep -q "0.0.0.0:8000"; then
            echo -e "    ${GREEN}✓ $line (正确)${NC}"
        elif echo "$line" | grep -q "127.0.0.1:8000"; then
            echo -e "    ${RED}✗ $line (仅监听本地)${NC}"
            echo -e "    ${YELLOW}  需要改为: \"0.0.0.0:8000:8000\"${NC}"
        else
            echo "    $line"
        fi
    done
fi
echo

# 7. 检查.env配置
echo -e "${YELLOW}[7/7] 检查环境配置...${NC}"
if [ -f .env ]; then
    echo "  ALLOWED_HOSTS配置:"
    if grep -q "^ALLOWED_HOSTS=" .env; then
        allowed=$(grep "^ALLOWED_HOSTS=" .env | cut -d= -f2)
        echo -e "    ${GREEN}$allowed${NC}"
        
        # 检查是否包含必要的主机
        if echo "$allowed" | grep -q "\*"; then
            echo -e "    ${GREEN}✓ 允许所有主机${NC}"
        else
            if echo "$allowed" | grep -q "$PRIVATE_IP"; then
                echo -e "    ${GREEN}✓ 包含内网IP${NC}"
            else
                echo -e "    ${YELLOW}⚠ 未包含内网IP: $PRIVATE_IP${NC}"
            fi
        fi
    else
        echo -e "    ${RED}✗ 未配置ALLOWED_HOSTS${NC}"
    fi
    
    echo
    echo "  DEBUG模式:"
    if grep -q "^DEBUG=True" .env; then
        echo -e "    ${GREEN}✓ DEBUG=True (开发模式)${NC}"
    elif grep -q "^DEBUG=False" .env; then
        echo -e "    ${YELLOW}⚠ DEBUG=False (生产模式，需要明确配置ALLOWED_HOSTS)${NC}"
    else
        echo -e "    ${YELLOW}⚠ 未配置DEBUG${NC}"
    fi
else
    echo -e "    ${RED}✗ .env文件不存在${NC}"
fi
echo

# 总结和建议
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}📋 诊断总结${NC}"
echo -e "${BLUE}========================================${NC}"
echo

echo -e "${YELLOW}可能的问题和解决方案:${NC}"
echo

# 检查是否是端口绑定问题
if netstat -tuln | grep ":8000 " | grep -q "127.0.0.1:8000"; then
    echo -e "${RED}问题1: Docker端口仅绑定到127.0.0.1${NC}"
    echo -e "${GREEN}解决方案:${NC}"
    echo -e "  1. 编辑 $COMPOSE_FILE"
    echo -e "  2. 找到 web 服务的 ports 配置"
    echo -e "  3. 将 \"127.0.0.1:8000:8000\" 改为 \"0.0.0.0:8000:8000\""
    echo -e "  4. 运行: docker-compose -f $COMPOSE_FILE up -d"
    echo
fi

# 检查防火墙
if command -v ufw &> /dev/null && sudo ufw status 2>/dev/null | grep -q "Status: active"; then
    if ! sudo ufw status | grep -q "8000"; then
        echo -e "${RED}问题2: 防火墙未开放8000端口${NC}"
        echo -e "${GREEN}解决方案:${NC}"
        echo -e "  sudo ufw allow 8000"
        echo -e "  sudo ufw reload"
        echo
    fi
fi

# 检查ALLOWED_HOSTS
if [ -f .env ]; then
    if ! grep -q "^ALLOWED_HOSTS=.*\*" .env && ! grep "^ALLOWED_HOSTS=" .env | grep -q "$PRIVATE_IP"; then
        echo -e "${RED}问题3: ALLOWED_HOSTS未包含服务器IP${NC}"
        echo -e "${GREEN}解决方案:${NC}"
        echo -e "  ./fix-allowed-hosts.sh"
        echo
    fi
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}💡 快速修复命令${NC}"
echo -e "${BLUE}========================================${NC}"
echo
echo -e "${YELLOW}如果是端口绑定问题，运行以下命令:${NC}"
echo -e "${GREEN}  # 修改docker-compose配置${NC}"
echo -e "  sed -i 's/127.0.0.1:8000:8000/0.0.0.0:8000:8000/g' $COMPOSE_FILE"
echo -e "  docker-compose -f $COMPOSE_FILE up -d"
echo
echo -e "${YELLOW}如果是防火墙问题，运行以下命令:${NC}"
echo -e "${GREEN}  sudo ufw allow 8000"
echo -e "  # 或"
echo -e "  sudo firewall-cmd --permanent --add-port=8000/tcp"
echo -e "  sudo firewall-cmd --reload"
echo
echo -e "${YELLOW}如果是ALLOWED_HOSTS问题，运行以下命令:${NC}"
echo -e "${GREEN}  ./fix-allowed-hosts.sh"
echo
