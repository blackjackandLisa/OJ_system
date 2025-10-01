#!/bin/bash

# 创建Django管理员账号脚本

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🔐 创建Django管理员账号${NC}"
echo -e "${BLUE}========================================${NC}"
echo

# 检测使用的compose文件
if docker-compose -f docker-compose.fast.yml ps -q web &>/dev/null 2>&1; then
    COMPOSE_FILE="docker-compose.fast.yml"
    echo -e "${GREEN}检测到快速部署版本${NC}"
elif docker-compose -f docker-compose.cn.yml ps -q web &>/dev/null 2>&1; then
    COMPOSE_FILE="docker-compose.cn.yml"
    echo -e "${GREEN}检测到国内优化版本${NC}"
else
    COMPOSE_FILE="docker-compose.yml"
    echo -e "${GREEN}使用标准版本${NC}"
fi

echo

# 检查Web容器是否运行
if ! docker-compose -f $COMPOSE_FILE ps | grep web | grep -q "Up"; then
    echo -e "${RED}错误: Web容器未运行${NC}"
    echo -e "${YELLOW}请先启动服务: docker-compose up -d${NC}"
    exit 1
fi

echo -e "${YELLOW}准备创建Django超级用户...${NC}"
echo
echo -e "${BLUE}提示:${NC}"
echo -e "  - 用户名建议: admin 或 administrator"
echo -e "  - 邮箱格式: user@example.com"
echo -e "  - 密码要求: 至少8位，不能全是数字，不能太简单"
echo -e "  - 推荐密码: Admin@2024, MySecure123!, OJ_Admin@2024"
echo
echo -e "${YELLOW}请按提示输入信息：${NC}"
echo

# 创建超级用户
docker-compose -f $COMPOSE_FILE exec web python manage.py createsuperuser

# 检查是否创建成功
if [ $? -eq 0 ]; then
    echo
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}✅ 管理员创建成功！${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo
    
    # 获取服务器IP
    PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "your-server-ip")
    
    echo -e "${BLUE}管理后台访问地址：${NC}"
    echo
    echo -e "  ${GREEN}本地访问:${NC}"
    echo -e "    http://localhost:8000/admin"
    echo -e "    http://127.0.0.1:8000/admin"
    echo
    
    if [ "$PUBLIC_IP" != "your-server-ip" ]; then
        echo -e "  ${GREEN}远程访问:${NC}"
        echo -e "    http://$PUBLIC_IP:8000/admin"
        echo
    fi
    
    echo -e "${YELLOW}💡 使用提示：${NC}"
    echo -e "  1. 在浏览器中打开管理后台地址"
    echo -e "  2. 使用刚才创建的用户名和密码登录"
    echo -e "  3. 登录后可以管理用户、数据和系统设置"
    echo
    
    echo -e "${YELLOW}🔧 常用管理命令：${NC}"
    echo -e "  修改密码:"
    echo -e "    ${GREEN}docker-compose -f $COMPOSE_FILE exec web python manage.py changepassword 用户名${NC}"
    echo
    echo -e "  查看所有用户:"
    echo -e "    ${GREEN}docker-compose -f $COMPOSE_FILE exec web python manage.py shell -c \"from django.contrib.auth.models import User; [print(u.username) for u in User.objects.all()]\"${NC}"
    echo
    echo -e "  创建更多管理员:"
    echo -e "    ${GREEN}./create-admin.sh${NC}"
    echo
else
    echo
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}❌ 管理员创建失败${NC}"
    echo -e "${RED}========================================${NC}"
    echo
    echo -e "${YELLOW}可能的原因：${NC}"
    echo -e "  1. 用户名已存在"
    echo -e "  2. 密码不符合要求（太简单）"
    echo -e "  3. Web容器未正常运行"
    echo
    echo -e "${YELLOW}解决方法：${NC}"
    echo -e "  1. 使用不同的用户名重试"
    echo -e "  2. 使用更强的密码（如：Admin@2024）"
    echo -e "  3. 检查容器状态: ${GREEN}docker-compose ps${NC}"
    echo -e "  4. 查看错误日志: ${GREEN}docker-compose logs web${NC}"
    echo
fi
