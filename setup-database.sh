#!/bin/bash

# 数据库设置脚本

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🗄️  OJ系统数据库设置${NC}"
echo -e "${BLUE}========================================${NC}"
echo

# 检测使用的compose文件
if docker-compose -f docker-compose.fast.yml ps -q web &>/dev/null 2>&1; then
    COMPOSE_FILE="docker-compose.fast.yml"
elif docker-compose -f docker-compose.cn.yml ps -q web &>/dev/null 2>&1; then
    COMPOSE_FILE="docker-compose.cn.yml"
elif docker-compose -f docker-compose.dev.yml ps -q web &>/dev/null 2>&1; then
    COMPOSE_FILE="docker-compose.dev.yml"
else
    COMPOSE_FILE="docker-compose.yml"
fi

echo -e "${YELLOW}使用配置: $COMPOSE_FILE${NC}"
echo

# 步骤1: 安装依赖
echo -e "${YELLOW}[步骤 1/5] 安装Python依赖...${NC}"
docker-compose -f $COMPOSE_FILE exec web pip install django-filter==23.3 markdown==3.5.1
echo -e "${GREEN}✓ 依赖安装完成${NC}"
echo

# 步骤2: 创建迁移文件
echo -e "${YELLOW}[步骤 2/5] 创建数据库迁移文件...${NC}"
docker-compose -f $COMPOSE_FILE exec web python manage.py makemigrations

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 迁移文件创建成功${NC}"
else
    echo -e "${RED}✗ 迁移文件创建失败${NC}"
    exit 1
fi
echo

# 步骤3: 应用迁移
echo -e "${YELLOW}[步骤 3/5] 应用数据库迁移...${NC}"
docker-compose -f $COMPOSE_FILE exec web python manage.py migrate

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 数据库迁移成功${NC}"
else
    echo -e "${RED}✗ 数据库迁移失败${NC}"
    exit 1
fi
echo

# 步骤4: 检查表是否创建
echo -e "${YELLOW}[步骤 4/5] 检查数据库表...${NC}"
docker-compose -f $COMPOSE_FILE exec web python manage.py shell -c "
from django.db import connection
cursor = connection.cursor()
cursor.execute(\"SELECT tablename FROM pg_tables WHERE schemaname='public' AND tablename LIKE 'problem%'\")
tables = cursor.fetchall()
print('题目相关表:')
for table in tables:
    print(f'  ✓ {table[0]}')
"
echo

# 步骤5: 创建示例数据
echo -e "${YELLOW}[步骤 5/5] 是否创建示例数据? (y/n)${NC}"
read -r response

if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo -e "${YELLOW}正在创建示例数据...${NC}"
    docker-compose -f $COMPOSE_FILE exec -T web python manage.py shell < create_sample_data.py
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ 示例数据创建成功${NC}"
    else
        echo -e "${RED}✗ 示例数据创建失败${NC}"
    fi
else
    echo -e "${YELLOW}跳过示例数据创建${NC}"
fi

echo
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✅ 数据库设置完成！${NC}"
echo -e "${BLUE}========================================${NC}"
echo

# 显示统计信息
echo -e "${YELLOW}数据库统计:${NC}"
docker-compose -f $COMPOSE_FILE exec web python manage.py shell -c "
from apps.problems.models import Problem, ProblemTag, TestCase, ProblemSample
print(f'题目标签: {ProblemTag.objects.count()} 个')
print(f'题目总数: {Problem.objects.count()} 个')
print(f'样例总数: {ProblemSample.objects.count()} 个')
print(f'测试用例: {TestCase.objects.count()} 个')
"

echo
echo -e "${BLUE}下一步操作:${NC}"
echo -e "  1. 访问管理后台: ${GREEN}http://your-server-ip:8000/admin/problems/problem/${NC}"
echo -e "  2. 访问API列表: ${GREEN}http://your-server-ip:8000/problems/api/problems/${NC}"
echo -e "  3. 创建超级用户: ${GREEN}./create-admin.sh${NC}"
echo

