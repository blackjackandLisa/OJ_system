# 轻量应用服务器访问配置指南

## 🎯 问题说明

轻量应用服务器有独立的防火墙配置，即使配置了系统防火墙和Docker，也需要在**服务器控制台**开放端口才能访问。

## ☁️ 各云服务商配置指南

### 阿里云轻量应用服务器

#### 方法1: 通过控制台配置（推荐）

1. **登录阿里云控制台**
   - 访问: https://swas.console.aliyun.com/

2. **进入服务器管理**
   - 找到你的轻量应用服务器
   - 点击服务器名称进入详情页

3. **配置防火墙**
   - 左侧菜单选择 **"防火墙"**
   - 点击 **"添加规则"**
   
4. **添加8000端口规则**
   ```
   应用类型: 自定义
   协议: TCP
   端口范围: 8000
   策略: 允许
   备注: Django Web服务
   ```

5. **点击确定**
   - 规则立即生效，无需重启

#### 方法2: 使用快捷配置

阿里云轻量服务器支持快捷应用配置：
- 在防火墙页面，点击 **"添加预设规则"**
- 选择 **"自定义TCP"**
- 输入端口: `8000`

### 腾讯云轻量应用服务器

1. **登录腾讯云控制台**
   - 访问: https://console.cloud.tencent.com/lighthouse/

2. **进入服务器详情**
   - 找到你的轻量应用服务器
   - 点击实例ID进入详情

3. **配置防火墙**
   - 选择 **"防火墙"** 标签
   - 点击 **"添加规则"**

4. **添加规则**
   ```
   类型: 自定义
   协议端口: TCP:8000
   来源: 所有IP (0.0.0.0/0)
   策略: 允许
   描述: Django应用端口
   ```

5. **保存规则**

### 华为云轻量应用服务器

1. **登录华为云控制台**
   - 访问: https://console.huaweicloud.com/

2. **进入云耀云服务器**
   - 找到你的服务器实例

3. **配置安全组**
   - 点击 **"安全组"**
   - 选择 **"配置规则"**
   - 添加入方向规则

4. **添加规则**
   ```
   协议端口: TCP 8000
   源地址: 0.0.0.0/0
   ```

## 🔧 服务器端配置

在配置控制台防火墙后，还需要确保服务器端配置正确：

### 运行综合修复脚本

```bash
# 在服务器上运行
chmod +x fix-remote-access.sh
./fix-remote-access.sh
```

### 手动配置步骤

#### 1. 配置ALLOWED_HOSTS

```bash
# 编辑.env文件
nano .env

# 添加服务器公网IP
ALLOWED_HOSTS=localhost,127.0.0.1,你的公网IP

# 或者开发环境使用
ALLOWED_HOSTS=*
```

#### 2. 配置系统防火墙

```bash
# Ubuntu/Debian
sudo ufw allow 8000/tcp
sudo ufw status

# CentOS/RHEL
sudo firewall-cmd --permanent --add-port=8000/tcp
sudo firewall-cmd --reload
```

#### 3. 重启服务

```bash
docker-compose restart web
```

## ✅ 验证配置

### 1. 检查端口监听

```bash
# 确认8000端口在监听
netstat -tuln | grep 8000

# 应该看到类似输出:
# tcp6  0  0 :::8000  :::*  LISTEN
```

### 2. 测试本地访问

```bash
# 在服务器上测试
curl http://localhost:8000/api/info/

# 应该返回JSON数据
```

### 3. 测试远程访问

```bash
# 在服务器上测试公网IP
curl http://你的公网IP:8000/api/info/

# 如果返回JSON数据，说明配置成功
```

### 4. 浏览器测试

在本地电脑浏览器中访问：
```
http://你的服务器公网IP:8000
```

## 🚨 常见问题排查

### 问题1: 控制台防火墙已开放，仍无法访问

**可能原因:**
- 系统防火墙仍然阻止
- ALLOWED_HOSTS未配置
- Docker服务未启动

**解决方案:**
```bash
# 运行诊断脚本
./diagnose-network.sh

# 查看详细错误
docker-compose logs web

# 确认容器运行
docker-compose ps
```

### 问题2: 显示 "Bad Request (400)"

**原因:** ALLOWED_HOSTS未包含服务器IP

**解决方案:**
```bash
# 运行修复脚本
./fix-allowed-hosts.sh

# 重启服务
docker-compose restart web
```

### 问题3: 显示 "连接超时"

**原因:** 控制台防火墙未开放

**解决方案:**
1. 登录云服务商控制台
2. 找到轻量应用服务器防火墙配置
3. 确认8000端口规则已添加且生效
4. 检查规则策略是 "允许" 而不是 "拒绝"

### 问题4: 显示 "连接被拒绝"

**原因:** Docker服务未启动或端口未监听

**解决方案:**
```bash
# 检查Docker服务
docker-compose ps

# 如果未运行，启动服务
docker-compose up -d

# 检查端口
netstat -tuln | grep 8000
```

## 📝 完整配置检查清单

### 云服务商控制台
- [ ] 已登录轻量应用服务器控制台
- [ ] 找到防火墙/安全组配置
- [ ] 添加TCP 8000端口入站规则
- [ ] 规则策略设置为"允许"
- [ ] 源地址设置为 0.0.0.0/0
- [ ] 规则已保存并生效

### 服务器配置
- [ ] 已更新.env文件的ALLOWED_HOSTS
- [ ] 已配置系统防火墙规则
- [ ] Docker容器正常运行
- [ ] 端口8000正在监听
- [ ] 可以通过localhost访问

### 网络测试
- [ ] 服务器本地curl测试成功
- [ ] 服务器curl公网IP测试成功
- [ ] 本地浏览器访问成功

## 🎯 快速配置流程

### 第一步: 云控制台配置（最重要！）

**阿里云轻量:**
```
控制台 → 服务器管理 → 防火墙 → 添加规则
协议: TCP
端口: 8000
策略: 允许
```

**腾讯云轻量:**
```
控制台 → 实例详情 → 防火墙 → 添加规则
协议端口: TCP:8000
来源: 0.0.0.0/0
策略: 允许
```

### 第二步: 服务器配置

```bash
# 在服务器上运行
./fix-remote-access.sh
```

### 第三步: 验证访问

```bash
# 测试
curl http://你的公网IP:8000/api/info/
```

## 🔍 获取服务器公网IP

```bash
# 方法1: 使用curl
curl ifconfig.me

# 方法2: 使用ip命令
ip addr show

# 方法3: 查看云控制台
在服务器详情页查看公网IP地址
```

## 💡 安全建议

### 生产环境配置

1. **限制访问源**
   ```
   # 只允许特定IP访问
   来源: 你的办公网IP/32
   ```

2. **使用域名**
   ```bash
   # .env配置
   ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com
   DEBUG=False
   ```

3. **配置HTTPS**
   ```bash
   # 开放443端口
   # 使用Let's Encrypt获取SSL证书
   ```

### 开发环境配置

```bash
# .env配置
ALLOWED_HOSTS=*
DEBUG=True
```

## 📞 还是不行？

如果按照以上步骤操作后仍然无法访问：

1. **截图云控制台防火墙配置**
   - 确认8000端口规则存在
   - 确认策略是"允许"

2. **运行诊断脚本**
   ```bash
   ./diagnose-network.sh > diagnostic.log
   cat diagnostic.log
   ```

3. **检查Docker日志**
   ```bash
   docker-compose logs web | tail -50
   ```

4. **提供错误信息**
   - 浏览器显示的错误信息
   - 服务器日志内容
   - 防火墙配置截图

## 🎉 成功标志

配置成功后，你应该能看到：

1. **浏览器访问** `http://公网IP:8000`
   - 显示OJ系统主页
   - 没有400、500等错误

2. **API测试成功**
   ```bash
   curl http://公网IP:8000/api/info/
   # 返回: {"message":"OJ系统API","version":"1.0.0","status":"running"}
   ```

3. **管理后台可访问**
   - `http://公网IP:8000/admin`
   - 显示Django管理登录页面

---

**重点提醒**: 轻量应用服务器必须在云控制台开放端口，这是最关键的一步！
