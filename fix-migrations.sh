#!/bin/bash

# 修复数据库迁移问题

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🔧 修复数据库迁移问题${NC}"
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

# 步骤1: 检查Web容器状态
echo -e "${YELLOW}[步骤 1/7] 检查Web容器状态...${NC}"
if docker-compose -f $COMPOSE_FILE ps | grep web | grep -q "Up"; then
    echo -e "${GREEN}✓ Web容器运行中${NC}"
else
    echo -e "${RED}✗ Web容器未运行${NC}"
    echo -e "${YELLOW}正在启动容器...${NC}"
    docker-compose -f $COMPOSE_FILE up -d
    sleep 5
fi
echo

# 步骤2: 安装依赖
echo -e "${YELLOW}[步骤 2/7] 安装Python依赖...${NC}"
docker-compose -f $COMPOSE_FILE exec web pip install -q django-filter==23.3 markdown==3.5.1
echo -e "${GREEN}✓ 依赖安装完成${NC}"
echo

# 步骤3: 检查apps目录
echo -e "${YELLOW}[步骤 3/7] 检查应用目录...${NC}"
docker-compose -f $COMPOSE_FILE exec web ls -la apps/problems/
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ problems应用目录存在${NC}"
else
    echo -e "${RED}✗ problems应用目录不存在${NC}"
    exit 1
fi
echo

# 步骤4: 清理旧的迁移缓存
echo -e "${YELLOW}[步骤 4/7] 清理Python缓存...${NC}"
docker-compose -f $COMPOSE_FILE exec web find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
docker-compose -f $COMPOSE_FILE exec web find . -name "*.pyc" -delete 2>/dev/null || true
echo -e "${GREEN}✓ 缓存清理完成${NC}"
echo

# 步骤5: 创建迁移目录
echo -e "${YELLOW}[步骤 5/8] 确保迁移目录存在...${NC}"
docker-compose -f $COMPOSE_FILE exec web mkdir -p apps/problems/migrations
docker-compose -f $COMPOSE_FILE exec web touch apps/problems/migrations/__init__.py
echo -e "${GREEN}✓ 迁移目录准备完成${NC}"
echo

# 步骤6: 检查Django配置
echo -e "${YELLOW}[步骤 6/8] 检查Django配置...${NC}"
docker-compose -f $COMPOSE_FILE exec web python manage.py check

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Django配置检查通过${NC}"
else
    echo -e "${RED}✗ Django配置有误${NC}"
    exit 1
fi
echo

# 步骤7: 创建迁移文件
echo -e "${YELLOW}[步骤 7/8] 创建数据库迁移文件...${NC}"
docker-compose -f $COMPOSE_FILE exec web python manage.py makemigrations problems

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 迁移文件创建成功${NC}"
else
    echo -e "${RED}✗ 迁移文件创建失败${NC}"
    echo -e "${YELLOW}尝试创建所有应用的迁移...${NC}"
    docker-compose -f $COMPOSE_FILE exec web python manage.py makemigrations
fi
echo

# 步骤8: 应用迁移
echo -e "${YELLOW}[步骤 8/8] 应用数据库迁移...${NC}"
docker-compose -f $COMPOSE_FILE exec web python manage.py migrate

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 数据库迁移成功${NC}"
else
    echo -e "${RED}✗ 数据库迁移失败${NC}"
    echo -e "${YELLOW}查看数据库连接...${NC}"
    docker-compose -f $COMPOSE_FILE exec web python manage.py dbshell -c "\dt"
    exit 1
fi
echo

# 验证表是否创建
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🔍 验证数据库表${NC}"
echo -e "${BLUE}========================================${NC}"
echo

docker-compose -f $COMPOSE_FILE exec web python manage.py shell << 'PYTHON_SCRIPT'
from django.db import connection

cursor = connection.cursor()
cursor.execute("""
    SELECT tablename 
    FROM pg_tables 
    WHERE schemaname='public' AND tablename LIKE 'problem%'
    ORDER BY tablename
""")

tables = cursor.fetchall()

if tables:
    print("\n✓ 成功创建以下表:")
    for table in tables:
        print(f"  • {table[0]}")
else:
    print("\n✗ 未找到problem相关的表")

cursor.close()
PYTHON_SCRIPT

echo
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✅ 迁移修复完成！${NC}"
echo -e "${BLUE}========================================${NC}"
echo

# 询问是否创建示例数据
echo -e "${YELLOW}是否现在创建示例数据? (y/n)${NC}"
read -r response

if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo -e "${YELLOW}正在创建示例数据...${NC}"
    docker-compose -f $COMPOSE_FILE exec -T web python manage.py shell < create_sample_data.py
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ 示例数据创建成功${NC}"
        
        # 显示统计
        echo
        echo -e "${BLUE}数据统计:${NC}"
        docker-compose -f $COMPOSE_FILE exec web python manage.py shell << 'STATS_SCRIPT'
from apps.problems.models import Problem, ProblemTag, TestCase, ProblemSample

print(f"  题目标签: {ProblemTag.objects.count()} 个")
print(f"  题目总数: {Problem.objects.count()} 个")
print(f"  样例总数: {ProblemSample.objects.count()} 个")
print(f"  测试用例: {TestCase.objects.count()} 个")
STATS_SCRIPT
    else
        echo -e "${RED}✗ 示例数据创建失败${NC}"
        echo -e "${YELLOW}请检查错误信息${NC}"
    fi
else
    echo -e "${YELLOW}跳过示例数据创建${NC}"
    echo -e "${BLUE}稍后可以手动运行:${NC}"
    echo -e "  ${GREEN}docker-compose exec web python manage.py shell < create_sample_data.py${NC}"
fi

echo
echo -e "${BLUE}下一步:${NC}"
echo -e "  1. 访问管理后台: ${GREEN}http://your-server-ip:8000/admin${NC}"
echo -e "  2. 访问API: ${GREEN}http://your-server-ip:8000/problems/api/problems/${NC}"
echo -e "  3. 创建管理员: ${GREEN}./create-admin.sh${NC}"
echo
