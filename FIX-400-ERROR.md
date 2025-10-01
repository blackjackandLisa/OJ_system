# 修复 Bad Request (400) 错误

## 🔍 问题说明

如果你看到 "Bad Request (400)" 错误，这是因为Django的`ALLOWED_HOSTS`配置问题。

### 症状
- ✅ `http://localhost:8000` 可以访问
- ❌ `http://服务器IP:8000` 显示 Bad Request (400)
- ❌ 通过域名访问显示 Bad Request (400)

### 原因
Django的安全机制要求必须在`ALLOWED_HOSTS`中明确列出允许访问的主机名/IP地址。

## ✅ 解决方案

### 方案1: 使用自动修复脚本（推荐）

```bash
# 在Linux服务器上运行
chmod +x fix-allowed-hosts.sh
./fix-allowed-hosts.sh
```

这个脚本会：
- 自动获取服务器的公网IP和内网IP
- 更新`.env`文件中的`ALLOWED_HOSTS`配置
- 提示是否添加域名
- 自动重启服务

### 方案2: 手动修改配置

#### 步骤1: 编辑.env文件

```bash
# 编辑环境配置文件
nano .env
```

#### 步骤2: 修改ALLOWED_HOSTS

找到或添加`ALLOWED_HOSTS`配置行，包含你的服务器IP：

```env
# 示例：添加多个主机
ALLOWED_HOSTS=localhost,127.0.0.1,192.168.1.100,123.45.67.89,yourdomain.com

# 开发环境（允许所有主机，仅用于测试）
ALLOWED_HOSTS=*

# 生产环境（推荐明确指定）
ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com,123.45.67.89
```

#### 步骤3: 重启服务

```bash
# 重启Web服务
docker-compose restart web

# 或重启所有服务
docker-compose restart
```

## 🎯 配置示例

### 开发环境配置

```env
DEBUG=True
ALLOWED_HOSTS=*
```

**说明**: `*` 表示允许所有主机访问（仅用于开发环境）

### 生产环境配置

```env
DEBUG=False
ALLOWED_HOSTS=example.com,www.example.com,123.45.67.89
```

**说明**: 明确列出所有允许访问的域名和IP

### 常见配置组合

#### 云服务器配置
```env
# 包含公网IP、内网IP和localhost
ALLOWED_HOSTS=localhost,127.0.0.1,172.16.0.100,123.45.67.89
```

#### 域名+IP配置
```env
# 同时支持域名和IP访问
ALLOWED_HOSTS=example.com,www.example.com,123.45.67.89,localhost,127.0.0.1
```

#### 多域名配置
```env
# 支持多个域名
ALLOWED_HOSTS=example.com,www.example.com,api.example.com,admin.example.com
```

## 🔧 验证配置

### 检查当前配置

```bash
# 查看.env文件中的ALLOWED_HOSTS
cat .env | grep ALLOWED_HOSTS
```

### 测试访问

```bash
# 测试localhost
curl http://localhost:8000/api/info/

# 测试IP地址
curl http://你的服务器IP:8000/api/info/

# 应该返回JSON数据而不是400错误
```

### 查看Django日志

```bash
# 查看Web服务日志
docker-compose logs web

# 实时查看日志
docker-compose logs -f web
```

## 📝 注意事项

### 安全建议

1. **生产环境不要使用 `*`**
   ```env
   # ❌ 不安全
   ALLOWED_HOSTS=*
   
   # ✅ 安全
   ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com
   ```

2. **只添加必要的主机**
   ```env
   # ❌ 包含不必要的IP
   ALLOWED_HOSTS=*,localhost,127.0.0.1,0.0.0.0
   
   # ✅ 仅包含实际使用的
   ALLOWED_HOSTS=yourdomain.com,123.45.67.89
   ```

3. **使用域名而不是IP**
   ```env
   # ✅ 推荐：使用域名
   ALLOWED_HOSTS=example.com,www.example.com
   
   # ⚠️  不推荐：仅使用IP（IP可能会变）
   ALLOWED_HOSTS=123.45.67.89
   ```

### 常见错误

#### 错误1: 配置后仍然400
**原因**: 未重启服务
**解决**: `docker-compose restart web`

#### 错误2: 通过Nginx访问仍然400
**原因**: Nginx代理头未正确设置
**解决**: 检查`nginx.conf`中的`proxy_set_header Host $host;`

#### 错误3: 部分地址可以访问，部分不行
**原因**: ALLOWED_HOSTS未包含所有访问方式
**解决**: 添加所有可能的主机名和IP

## 🚀 快速修复流程

```bash
# 1. 运行修复脚本
./fix-allowed-hosts.sh

# 2. 重启服务
docker-compose restart web

# 3. 测试访问
curl http://你的服务器IP:8000/api/info/

# 4. 在浏览器中访问
# http://你的服务器IP:8000
```

## 🔍 深入理解

### ALLOWED_HOSTS的作用

Django使用`ALLOWED_HOSTS`来防止HTTP Host头攻击。只有在这个列表中的主机名才能访问你的应用。

### HTTP Host头

当浏览器访问网站时，会发送一个Host头：
```http
GET / HTTP/1.1
Host: example.com
```

Django会检查这个Host是否在`ALLOWED_HOSTS`中。

### 通配符支持

```env
# 允许所有子域名
ALLOWED_HOSTS=.example.com

# 允许特定子域名
ALLOWED_HOSTS=*.example.com

# 允许所有主机（仅用于开发）
ALLOWED_HOSTS=*
```

## 📞 获取帮助

如果修复后仍然有问题：

1. 检查Docker日志：`docker-compose logs web`
2. 验证.env文件：`cat .env | grep ALLOWED_HOSTS`
3. 确认服务已重启：`docker-compose ps`
4. 查看完整错误信息：`docker-compose logs web | grep -i allowed`

---

**快速修复**: 运行 `./fix-allowed-hosts.sh` 一键解决！
