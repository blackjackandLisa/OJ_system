#!/bin/bash

# 数据库迁移诊断脚本

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🔍 数据库迁移诊断${NC}"
echo -e "${BLUE}========================================${NC}"
echo

# 检测compose文件
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

# 1. 检查容器状态
echo -e "${YELLOW}[1/8] 检查容器状态${NC}"
docker-compose -f $COMPOSE_FILE ps
echo

# 2. 检查Python环境
echo -e "${YELLOW}[2/8] 检查Python环境${NC}"
docker-compose -f $COMPOSE_FILE exec web python --version
echo

# 3. 检查Django版本
echo -e "${YELLOW}[3/8] 检查Django版本${NC}"
docker-compose -f $COMPOSE_FILE exec web python -c "import django; print(f'Django {django.get_version()}')"
echo

# 4. 检查已安装的应用
echo -e "${YELLOW}[4/8] 检查INSTALLED_APPS${NC}"
docker-compose -f $COMPOSE_FILE exec web python manage.py shell << 'CHECK_APPS'
from django.conf import settings
apps = [app for app in settings.INSTALLED_APPS if 'apps.' in app]
print("已注册的本地应用:")
for app in apps:
    print(f"  • {app}")
CHECK_APPS
echo

# 5. 检查模型定义
echo -e "${YELLOW}[5/8] 检查模型定义${NC}"
docker-compose -f $COMPOSE_FILE exec web python manage.py shell << 'CHECK_MODELS'
try:
    from apps.problems.models import Problem, ProblemTag, TestCase, ProblemSample, UserProblemStatus
    print("✓ 所有模型导入成功:")
    print(f"  • Problem: {Problem._meta.db_table}")
    print(f"  • ProblemTag: {ProblemTag._meta.db_table}")
    print(f"  • TestCase: {TestCase._meta.db_table}")
    print(f"  • ProblemSample: {ProblemSample._meta.db_table}")
    print(f"  • UserProblemStatus: {UserProblemStatus._meta.db_table}")
except Exception as e:
    print(f"✗ 模型导入失败: {e}")
CHECK_MODELS
echo

# 6. 检查迁移文件
echo -e "${YELLOW}[6/8] 检查迁移文件${NC}"
if docker-compose -f $COMPOSE_FILE exec web test -d apps/problems/migrations; then
    echo "迁移目录存在:"
    docker-compose -f $COMPOSE_FILE exec web ls -la apps/problems/migrations/
else
    echo -e "${RED}✗ 迁移目录不存在${NC}"
fi
echo

# 7. 检查数据库表
echo -e "${YELLOW}[7/8] 检查数据库表${NC}"
docker-compose -f $COMPOSE_FILE exec web python manage.py shell << 'CHECK_TABLES'
from django.db import connection

try:
    cursor = connection.cursor()
    cursor.execute("""
        SELECT tablename 
        FROM pg_tables 
        WHERE schemaname='public'
        ORDER BY tablename
    """)
    tables = cursor.fetchall()
    
    if tables:
        print(f"数据库中的表 (共{len(tables)}个):")
        problem_tables = [t[0] for t in tables if 'problem' in t[0]]
        other_tables = [t[0] for t in tables if 'problem' not in t[0]]
        
        if problem_tables:
            print("\n题目相关表:")
            for table in problem_tables:
                print(f"  ✓ {table}")
        else:
            print("\n✗ 未找到题目相关表")
        
        if other_tables:
            print(f"\n其他表 ({len(other_tables)}个):")
            for table in other_tables[:5]:  # 只显示前5个
                print(f"  • {table}")
            if len(other_tables) > 5:
                print(f"  ... 还有 {len(other_tables) - 5} 个表")
    else:
        print("✗ 数据库中没有任何表")
    
    cursor.close()
except Exception as e:
    print(f"✗ 检查数据库表失败: {e}")
CHECK_TABLES
echo

# 8. 检查待应用的迁移
echo -e "${YELLOW}[8/8] 检查待应用的迁移${NC}"
docker-compose -f $COMPOSE_FILE exec web python manage.py showmigrations problems
echo

# 总结
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}📋 诊断总结${NC}"
echo -e "${BLUE}========================================${NC}"
echo

# 检查是否需要迁移
PENDING=$(docker-compose -f $COMPOSE_FILE exec web python manage.py showmigrations problems | grep "\[ \]" | wc -l)

if [ "$PENDING" -gt 0 ]; then
    echo -e "${RED}发现问题:${NC}"
    echo -e "  • 有 $PENDING 个待应用的迁移"
    echo
    echo -e "${YELLOW}解决方案:${NC}"
    echo -e "  ${GREEN}./fix-migrations.sh${NC}"
else
    # 检查表是否存在
    TABLE_CHECK=$(docker-compose -f $COMPOSE_FILE exec web python manage.py shell -c "from django.db import connection; cursor = connection.cursor(); cursor.execute(\"SELECT COUNT(*) FROM pg_tables WHERE schemaname='public' AND tablename LIKE 'problem%'\"); print(cursor.fetchone()[0])" 2>/dev/null | tail -1)
    
    if [ "$TABLE_CHECK" -ge 5 ]; then
        echo -e "${GREEN}✅ 迁移状态正常${NC}"
        echo -e "  • 所有迁移已应用"
        echo -e "  • 数据库表已创建"
        echo
        echo -e "${BLUE}可以开始使用:${NC}"
        echo -e "  ${GREEN}docker-compose exec web python manage.py shell < create_sample_data.py${NC}"
    else
        echo -e "${YELLOW}⚠️  迁移已应用但表未创建${NC}"
        echo
        echo -e "${YELLOW}解决方案:${NC}"
        echo -e "  ${GREEN}./fix-migrations.sh${NC}"
    fi
fi

echo
