# 创建Django管理员账号

## 🔐 创建超级用户

### 方法1: 交互式创建（推荐）

```bash
# 在服务器上运行
docker-compose exec web python manage.py createsuperuser
```

按提示输入信息：
```
Username (leave blank to use 'root'): admin
Email address: admin@example.com
Password: ********
Password (again): ********
Superuser created successfully.
```

### 方法2: 使用快速部署版本

如果使用的是快速部署：
```bash
docker-compose -f docker-compose.fast.yml exec web python manage.py createsuperuser
```

### 方法3: 使用国内优化版本

```bash
docker-compose -f docker-compose.cn.yml exec web python manage.py createsuperuser
```

## 📝 密码要求

Django默认密码必须满足：
- 至少8个字符
- 不能全是数字
- 不能太常见（如"password123"）
- 不能与用户名太相似

### 推荐密码示例
```
Admin@2024
MySecure123!
StrongPass@OJ
```

## 🚀 快速创建脚本

创建一个便捷脚本：

```bash
# 创建create-admin.sh
cat > create-admin.sh << 'EOF'
#!/bin/bash

# 创建Django超级用户

# 颜色定义
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
elif docker-compose -f docker-compose.cn.yml ps -q web &>/dev/null 2>&1; then
    COMPOSE_FILE="docker-compose.cn.yml"
else
    COMPOSE_FILE="docker-compose.yml"
fi

echo -e "${YELLOW}使用配置文件: $COMPOSE_FILE${NC}"
echo

echo -e "${YELLOW}请输入管理员信息：${NC}"
echo

# 创建超级用户
docker-compose -f $COMPOSE_FILE exec web python manage.py createsuperuser

echo
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ 管理员创建完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo

# 获取服务器IP
PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || echo "your-server-ip")

echo -e "${BLUE}管理后台访问地址：${NC}"
echo -e "  http://$PUBLIC_IP:8000/admin"
echo
echo -e "${YELLOW}💡 提示：${NC}"
echo -e "  1. 使用刚才创建的用户名和密码登录"
echo -e "  2. 登录后可以管理用户、组和其他数据"
echo -e "  3. 如需修改密码，运行："
echo -e "     ${GREEN}docker-compose -f $COMPOSE_FILE exec web python manage.py changepassword 用户名${NC}"
EOF

chmod +x create-admin.sh
```

然后运行：
```bash
./create-admin.sh
```

## 🔧 其他用户管理命令

### 修改管理员密码

```bash
# 修改指定用户密码
docker-compose exec web python manage.py changepassword admin

# 按提示输入新密码
Password: ********
Password (again): ********
Password changed successfully for user 'admin'
```

### 列出所有用户

```bash
# 进入Django Shell
docker-compose exec web python manage.py shell

# 在Shell中运行
from django.contrib.auth.models import User
for user in User.objects.all():
    print(f"用户名: {user.username}, 超级用户: {user.is_superuser}, 邮箱: {user.email}")
```

### 创建普通用户

```bash
# 进入Django Shell
docker-compose exec web python manage.py shell

# 创建普通用户
from django.contrib.auth.models import User
user = User.objects.create_user('testuser', 'test@example.com', 'password123')
user.save()
```

### 删除用户

```bash
# 进入Django Shell
docker-compose exec web python manage.py shell

# 删除用户
from django.contrib.auth.models import User
User.objects.get(username='testuser').delete()
```

## 🌐 登录管理后台

### 访问地址

**本地访问：**
```
http://localhost:8000/admin
```

**远程访问：**
```
http://服务器IP:8000/admin
```

**通过Nginx（如果配置了）：**
```
http://服务器IP/admin
```

### 登录步骤

1. 在浏览器中打开管理后台地址
2. 输入用户名（如：admin）
3. 输入密码
4. 点击"登录"

### 管理后台功能

登录后你可以：
- ✅ 管理用户和组
- ✅ 查看和修改数据库数据
- ✅ 配置权限
- ✅ 查看操作日志

## 🚨 常见问题

### 问题1: 忘记管理员密码

**解决方案：**
```bash
# 重置密码
docker-compose exec web python manage.py changepassword admin
```

### 问题2: 无法登录后台（CSRF错误）

**解决方案：**
1. 清除浏览器缓存和Cookie
2. 检查ALLOWED_HOSTS配置
3. 确认访问地址正确

### 问题3: 显示403 Forbidden

**解决方案：**
```bash
# 检查用户是否是超级用户
docker-compose exec web python manage.py shell

from django.contrib.auth.models import User
user = User.objects.get(username='admin')
user.is_superuser = True
user.is_staff = True
user.save()
```

### 问题4: 创建时密码被拒绝

**原因：** 密码太简单或太常见

**解决方案：** 使用更强的密码，例如：
- `Admin@2024`
- `MySecure123!`
- `OJ_System@Pass`

## 📱 通过脚本批量创建用户

创建 `create-users.py`：

```python
# 在服务器上运行
docker-compose exec web python manage.py shell

# 然后输入：
from django.contrib.auth.models import User

# 批量创建用户
users_data = [
    {'username': 'user1', 'email': 'user1@example.com', 'password': 'Pass@123'},
    {'username': 'user2', 'email': 'user2@example.com', 'password': 'Pass@123'},
    {'username': 'user3', 'email': 'user3@example.com', 'password': 'Pass@123'},
]

for data in users_data:
    user = User.objects.create_user(
        username=data['username'],
        email=data['email'],
        password=data['password']
    )
    print(f"创建用户: {user.username}")
```

## 🔐 安全建议

### 生产环境

1. **使用强密码**
   - 至少12个字符
   - 包含大小写字母、数字和符号
   - 不使用常见词汇

2. **限制管理后台访问**
   - 只允许特定IP访问
   - 使用VPN
   - 配置防火墙规则

3. **启用两步验证**
   - 安装django-two-factor-auth
   - 配置验证方式

4. **定期更换密码**
   - 每3个月更换一次
   - 不重复使用旧密码

### 开发环境

```bash
# 快速创建测试管理员
# 用户名: admin
# 密码: admin123
docker-compose exec web python manage.py shell -c "
from django.contrib.auth.models import User;
User.objects.filter(username='admin').exists() or User.objects.create_superuser('admin', 'admin@test.com', 'admin123')
"
```

## 📊 验证管理员权限

```bash
# 检查用户权限
docker-compose exec web python manage.py shell

from django.contrib.auth.models import User
user = User.objects.get(username='admin')
print(f"用户名: {user.username}")
print(f"超级用户: {user.is_superuser}")
print(f"职员状态: {user.is_staff}")
print(f"激活状态: {user.is_active}")
```

## 🎯 快速参考

```bash
# 创建超级用户
docker-compose exec web python manage.py createsuperuser

# 修改密码
docker-compose exec web python manage.py changepassword admin

# 列出所有用户
docker-compose exec web python manage.py shell -c "from django.contrib.auth.models import User; [print(u.username) for u in User.objects.all()]"

# 删除用户
docker-compose exec web python manage.py shell -c "from django.contrib.auth.models import User; User.objects.get(username='testuser').delete()"
```

## 🌐 访问管理后台

创建管理员后，访问：

**本地：**
- http://localhost:8000/admin

**远程：**
- http://你的服务器IP:8000/admin

使用创建的用户名和密码登录！

---

**快速创建**: 运行 `docker-compose exec web python manage.py createsuperuser`
