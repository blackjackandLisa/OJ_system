#!/bin/bash

# Linux系统环境检查脚本

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "🔍 OJ系统Linux环境检查"
echo "=========================================="
echo

# 检查操作系统
echo -e "${BLUE}📋 系统信息${NC}"
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    echo -e "操作系统: ${GREEN}$PRETTY_NAME${NC}"
    echo -e "内核版本: ${GREEN}$(uname -r)${NC}"
    echo -e "架构: ${GREEN}$(uname -m)${NC}"
else
    echo -e "操作系统: ${RED}无法识别${NC}"
fi

echo -e "主机名: ${GREEN}$(hostname)${NC}"
echo -e "当前用户: ${GREEN}$(whoami)${NC}"
echo -e "用户ID: ${GREEN}$(id -u)${NC}"

# 检查内存和磁盘
echo
echo -e "${BLUE}💾 系统资源${NC}"
echo -e "内存使用: ${GREEN}$(free -h | awk 'NR==2{printf "%.1f%% (%s/%s)\n", $3*100/$2, $3, $2}')${NC}"
echo -e "磁盘使用: ${GREEN}$(df -h / | awk 'NR==2{print $5 " (" $3 "/" $2 ")"}')${NC}"
echo -e "CPU信息: ${GREEN}$(nproc) 核心${NC}"

# 检查网络
echo
echo -e "${BLUE}🌐 网络信息${NC}"
echo -e "公网IP: ${GREEN}$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "无法获取")${NC}"
echo -e "内网IP: ${GREEN}$(hostname -I | awk '{print $1}')${NC}"

# 检查端口占用
echo
echo -e "${BLUE}🔌 端口检查${NC}"
ports=(80 8000 5432 8080 5433)
for port in "${ports[@]}"; do
    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
        process=$(netstat -tulnp 2>/dev/null | grep ":$port " | awk '{print $7}' | cut -d'/' -f2)
        echo -e "端口 $port: ${RED}被占用${NC} (进程: $process)"
    else
        echo -e "端口 $port: ${GREEN}可用${NC}"
    fi
done

# 检查Docker
echo
echo -e "${BLUE}🐳 Docker环境${NC}"
if command -v docker &> /dev/null; then
    echo -e "Docker版本: ${GREEN}$(docker --version | cut -d' ' -f3 | cut -d',' -f1)${NC}"
    if systemctl is-active --quiet docker; then
        echo -e "Docker服务: ${GREEN}运行中${NC}"
    else
        echo -e "Docker服务: ${RED}未运行${NC}"
    fi
    
    # 检查Docker权限
    if docker ps &> /dev/null; then
        echo -e "Docker权限: ${GREEN}正常${NC}"
    else
        echo -e "Docker权限: ${RED}需要sudo或加入docker组${NC}"
    fi
    
    # 检查Docker Compose
    if command -v docker-compose &> /dev/null; then
        echo -e "Docker Compose: ${GREEN}$(docker-compose --version | cut -d' ' -f3 | cut -d',' -f1)${NC}"
    else
        echo -e "Docker Compose: ${RED}未安装${NC}"
    fi
    
    # 显示Docker容器状态
    echo
    echo -e "现有容器:"
    if docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -q "NAMES"; then
        docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    else
        echo -e "  ${GREEN}无容器${NC}"
    fi
else
    echo -e "Docker: ${RED}未安装${NC}"
fi

# 检查防火墙
echo
echo -e "${BLUE}🔥 防火墙状态${NC}"
if command -v ufw &> /dev/null; then
    if ufw status | grep -q "Status: active"; then
        echo -e "UFW防火墙: ${YELLOW}启用${NC}"
        echo "开放的端口:"
        ufw status | grep "ALLOW" | while read line; do
            echo -e "  ${GREEN}$line${NC}"
        done
    else
        echo -e "UFW防火墙: ${GREEN}禁用${NC}"
    fi
elif command -v firewall-cmd &> /dev/null; then
    if systemctl is-active --quiet firewalld; then
        echo -e "FirewallD: ${YELLOW}启用${NC}"
    else
        echo -e "FirewallD: ${GREEN}禁用${NC}"
    fi
else
    echo -e "防火墙: ${GREEN}未检测到${NC}"
fi

# 检查系统服务
echo
echo -e "${BLUE}⚙️ 相关服务${NC}"
services=("postgresql" "apache2" "nginx" "mysql")
for service in "${services[@]}"; do
    if systemctl list-unit-files | grep -q "^$service"; then
        if systemctl is-active --quiet $service; then
            echo -e "$service: ${YELLOW}运行中${NC}"
        else
            echo -e "$service: ${GREEN}已安装但未运行${NC}"
        fi
    else
        echo -e "$service: ${GREEN}未安装${NC}"
    fi
done

# 检查Python环境
echo
echo -e "${BLUE}🐍 Python环境${NC}"
if command -v python3 &> /dev/null; then
    echo -e "Python版本: ${GREEN}$(python3 --version)${NC}"
    echo -e "Pip版本: ${GREEN}$(python3 -m pip --version | cut -d' ' -f2)${NC}"
else
    echo -e "Python3: ${RED}未安装${NC}"
fi

# 生成建议
echo
echo -e "${BLUE}💡 部署建议${NC}"

# Docker安装建议
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}1. 安装Docker:${NC}"
    echo "   curl -fsSL https://get.docker.com -o get-docker.sh"
    echo "   sudo sh get-docker.sh"
    echo "   sudo usermod -aG docker \$USER"
fi

# 权限建议
if ! docker ps &> /dev/null 2>&1; then
    echo -e "${YELLOW}2. 配置Docker权限:${NC}"
    echo "   sudo usermod -aG docker \$USER"
    echo "   newgrp docker"
fi

# 端口建议
conflicts=()
for port in 80 8000 5432; do
    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
        conflicts+=($port)
    fi
done

if [ ${#conflicts[@]} -gt 0 ]; then
    echo -e "${YELLOW}3. 解决端口冲突:${NC}"
    for port in "${conflicts[@]}"; do
        case $port in
            5432)
                echo "   - 停止PostgreSQL: sudo systemctl stop postgresql"
                ;;
            80)
                echo "   - 停止Web服务: sudo systemctl stop apache2/nginx"
                ;;
            8000)
                echo "   - 停止占用8000端口的服务"
                ;;
        esac
    done
fi

# 防火墙建议
if command -v ufw &> /dev/null && ufw status | grep -q "Status: active"; then
    echo -e "${YELLOW}4. 配置防火墙:${NC}"
    echo "   sudo ufw allow 80"
    echo "   sudo ufw allow 8000"
fi

echo
echo -e "${GREEN}✅ 系统检查完成${NC}"
echo
echo "如果所有检查都通过，可以运行:"
echo -e "${GREEN}./deploy-linux.sh${NC}"
