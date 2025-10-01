#!/bin/bash

# 用户系统设置脚本

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}👥 用户认证系统设置${NC}"
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

# 步骤1: 创建迁移
echo -e "${YELLOW}[步骤 1/5] 创建users应用迁移...${NC}"
docker-compose -f $COMPOSE_FILE exec web python manage.py makemigrations users

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 迁移文件创建成功${NC}"
else
    echo -e "${RED}✗ 迁移文件创建失败${NC}"
    exit 1
fi
echo

# 步骤2: 应用迁移
echo -e "${YELLOW}[步骤 2/5] 应用数据库迁移...${NC}"
docker-compose -f $COMPOSE_FILE exec web python manage.py migrate

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 数据库迁移成功${NC}"
else
    echo -e "${RED}✗ 数据库迁移失败${NC}"
    exit 1
fi
echo

# 步骤3: 验证表创建
echo -e "${YELLOW}[步骤 3/5] 验证数据库表...${NC}"
docker-compose -f $COMPOSE_FILE exec web python manage.py shell << 'VERIFY_TABLES'
from django.db import connection

cursor = connection.cursor()
cursor.execute("""
    SELECT tablename 
    FROM pg_tables 
    WHERE schemaname='public' AND (
        tablename LIKE 'user%' OR 
        tablename LIKE 'class%'
    )
    ORDER BY tablename
""")

tables = cursor.fetchall()

if tables:
    print("\n✓ 成功创建以下表:")
    for table in tables:
        print(f"  • {table[0]}")
else:
    print("\n✗ 未找到用户相关的表")

cursor.close()
VERIFY_TABLES
echo

# 步骤4: 为现有用户创建Profile
echo -e "${YELLOW}[步骤 4/5] 为现有用户创建Profile...${NC}"
docker-compose -f $COMPOSE_FILE exec web python manage.py shell << 'CREATE_PROFILES'
from django.contrib.auth.models import User
from apps.users.models import UserProfile

users_without_profile = User.objects.filter(profile__isnull=True)
count = 0

for user in users_without_profile:
    UserProfile.objects.create(
        user=user,
        real_name=user.username,
        user_type='admin' if user.is_superuser else 'student'
    )
    count += 1
    print(f"为用户 {user.username} 创建了Profile")

if count > 0:
    print(f"\n✓ 成功为 {count} 个用户创建Profile")
else:
    print("\n✓ 所有用户都已有Profile")
CREATE_PROFILES
echo

# 步骤5: 创建邀请码（可选）
echo -e "${YELLOW}[步骤 5/5] 是否创建老师邀请码? (y/n)${NC}"
read -r response

if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo -e "${YELLOW}创建邀请码...${NC}"
    docker-compose -f $COMPOSE_FILE exec web python manage.py shell << 'CREATE_INVITATIONS'
import random
import string
from django.contrib.auth.models import User
from apps.users.models import InvitationCode

# 获取管理员用户
admin = User.objects.filter(is_superuser=True).first()

if admin:
    # 创建5个邀请码
    for i in range(5):
        code = ''.join(random.choices(string.ascii_uppercase + string.digits, k=12))
        invitation = InvitationCode.objects.create(
            code=code,
            for_user_type='teacher',
            created_by=admin,
            note=f'初始邀请码{i+1}'
        )
        print(f"✓ 创建邀请码: {code}")
    
    print(f"\n✓ 成功创建5个邀请码")
    print("可以在管理后台查看: /admin/users/invitationcode/")
else:
    print("✗ 未找到管理员用户，请先创建超级用户")
CREATE_INVITATIONS
else
    echo -e "${YELLOW}跳过邀请码创建${NC}"
fi
echo

# 显示统计
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}📊 系统统计${NC}"
echo -e "${BLUE}========================================${NC}"
echo

docker-compose -f $COMPOSE_FILE exec web python manage.py shell << 'SHOW_STATS'
from django.contrib.auth.models import User
from apps.users.models import UserProfile, Class, InvitationCode

print(f"用户总数: {User.objects.count()} 个")
print(f"  - 学生: {UserProfile.objects.filter(user_type='student').count()} 个")
print(f"  - 老师: {UserProfile.objects.filter(user_type='teacher').count()} 个")
print(f"  - 管理员: {User.objects.filter(is_superuser=True).count()} 个")
print(f"班级总数: {Class.objects.count()} 个")
print(f"邀请码总数: {InvitationCode.objects.count()} 个")
print(f"  - 有效: {InvitationCode.objects.filter(is_used=False).count()} 个")
print(f"  - 已使用: {InvitationCode.objects.filter(is_used=True).count()} 个")
SHOW_STATS

echo
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ 用户系统设置完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo

echo -e "${BLUE}访问地址:${NC}"
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "your-server-ip")
echo -e "  注册页面: ${GREEN}http://$SERVER_IP:8000/users/register/${NC}"
echo -e "  登录页面: ${GREEN}http://$SERVER_IP:8000/users/login/${NC}"
echo -e "  个人中心: ${GREEN}http://$SERVER_IP:8000/users/profile/${NC}"
echo -e "  用户管理: ${GREEN}http://$SERVER_IP:8000/admin/users/userprofile/${NC}"
echo

echo -e "${YELLOW}💡 提示:${NC}"
echo -e "  1. 学生可以直接注册"
echo -e "  2. 老师注册需要邀请码（在管理后台创建）"
echo -e "  3. 管理员通过命令行创建: ./create-admin.sh"
echo
