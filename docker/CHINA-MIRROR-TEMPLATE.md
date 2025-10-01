# Docker镜像国产源替换模板

## 适用场景

在中国大陆构建Docker镜像时，使用国内镜像源可以大幅提升构建速度。

---

## 📦 Debian/Ubuntu系统镜像

### Debian 11 (Bullseye) - 适用于 python:3.10-slim, gcc:11-slim

```dockerfile
# 完全替换为阿里云镜像源
RUN echo "deb https://mirrors.aliyun.com/debian/ bullseye main contrib non-free" > /etc/apt/sources.list && \
    echo "deb https://mirrors.aliyun.com/debian/ bullseye-updates main contrib non-free" >> /etc/apt/sources.list && \
    echo "deb https://mirrors.aliyun.com/debian-security bullseye-security main contrib non-free" >> /etc/apt/sources.list && \
    rm -rf /etc/apt/sources.list.d/* && \
    mkdir -p /etc/apt/sources.list.d/
```

### Debian 12 (Bookworm)

```dockerfile
RUN echo "deb https://mirrors.aliyun.com/debian/ bookworm main contrib non-free non-free-firmware" > /etc/apt/sources.list && \
    echo "deb https://mirrors.aliyun.com/debian/ bookworm-updates main contrib non-free non-free-firmware" >> /etc/apt/sources.list && \
    echo "deb https://mirrors.aliyun.com/debian-security bookworm-security main contrib non-free non-free-firmware" >> /etc/apt/sources.list && \
    rm -rf /etc/apt/sources.list.d/* && \
    mkdir -p /etc/apt/sources.list.d/
```

### Ubuntu 22.04 (Jammy)

```dockerfile
RUN sed -i 's|http://archive.ubuntu.com|https://mirrors.aliyun.com|g' /etc/apt/sources.list && \
    sed -i 's|http://security.ubuntu.com|https://mirrors.aliyun.com|g' /etc/apt/sources.list && \
    rm -rf /etc/apt/sources.list.d/*
```

### Ubuntu 20.04 (Focal)

```dockerfile
RUN sed -i 's|http://archive.ubuntu.com|https://mirrors.aliyun.com|g' /etc/apt/sources.list && \
    sed -i 's|http://security.ubuntu.com|https://mirrors.aliyun.com|g' /etc/apt/sources.list && \
    rm -rf /etc/apt/sources.list.d/*
```

---

## 🐍 Python pip镜像源

### pip安装时使用清华源

```dockerfile
# 临时使用
RUN pip install --no-cache-dir -i https://pypi.tuna.tsinghua.edu.cn/simple package_name

# 永久配置
RUN pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
```

### 或使用阿里云

```dockerfile
RUN pip install --no-cache-dir -i https://mirrors.aliyun.com/pypi/simple/ package_name
```

---

## 📦 Node.js npm/yarn镜像源

### npm使用淘宝源

```dockerfile
RUN npm config set registry https://registry.npmmirror.com
```

### yarn使用淘宝源

```dockerfile
RUN yarn config set registry https://registry.npmmirror.com
```

---

## ☕ Java Maven镜像源

### 配置阿里云Maven

```dockerfile
RUN mkdir -p /root/.m2 && \
    echo '<settings>' > /root/.m2/settings.xml && \
    echo '  <mirrors>' >> /root/.m2/settings.xml && \
    echo '    <mirror>' >> /root/.m2/settings.xml && \
    echo '      <id>aliyun</id>' >> /root/.m2/settings.xml && \
    echo '      <mirrorOf>central</mirrorOf>' >> /root/.m2/settings.xml && \
    echo '      <url>https://maven.aliyun.com/repository/public</url>' >> /root/.m2/settings.xml && \
    echo '    </mirror>' >> /root/.m2/settings.xml && \
    echo '  </mirrors>' >> /root/.m2/settings.xml && \
    echo '</settings>' >> /root/.m2/settings.xml
```

---

## 🦀 Rust Cargo镜像源

### 使用中科大源

```dockerfile
RUN mkdir -p $HOME/.cargo && \
    echo '[source.crates-io]' > $HOME/.cargo/config.toml && \
    echo 'replace-with = "ustc"' >> $HOME/.cargo/config.toml && \
    echo '[source.ustc]' >> $HOME/.cargo/config.toml && \
    echo 'registry = "https://mirrors.ustc.edu.cn/crates.io-index"' >> $HOME/.cargo/config.toml
```

---

## 🐳 Docker Hub镜像加速

### 配置Docker daemon

在宿主机上配置 `/etc/docker/daemon.json`:

```json
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://mirror.ccs.tencentyun.com",
    "https://hub-mirror.c.163.com",
    "https://registry.docker-cn.com"
  ]
}
```

然后重启Docker:
```bash
sudo systemctl daemon-reload
sudo systemctl restart docker
```

---

## 🌐 Alpine Linux镜像源

### 替换为阿里云源

```dockerfile
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories
```

### 或使用清华源

```dockerfile
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories
```

---

## 📝 完整示例

### Python项目Dockerfile（完全国产化）

```dockerfile
FROM python:3.10-slim

# 替换apt源为阿里云
RUN echo "deb https://mirrors.aliyun.com/debian/ bullseye main contrib non-free" > /etc/apt/sources.list && \
    echo "deb https://mirrors.aliyun.com/debian/ bullseye-updates main contrib non-free" >> /etc/apt/sources.list && \
    echo "deb https://mirrors.aliyun.com/debian-security bullseye-security main contrib non-free" >> /etc/apt/sources.list && \
    rm -rf /etc/apt/sources.list.d/*

# 安装系统依赖
RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 配置pip使用清华源
RUN pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple

# 安装Python依赖
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

WORKDIR /app
COPY . .

CMD ["python", "app.py"]
```

### Node.js项目Dockerfile（完全国产化）

```dockerfile
FROM node:18-slim

# 替换apt源
RUN sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list && \
    rm -rf /etc/apt/sources.list.d/*

# 配置npm使用淘宝源
RUN npm config set registry https://registry.npmmirror.com

WORKDIR /app
COPY package*.json ./
RUN npm install

COPY . .
CMD ["node", "app.js"]
```

---

## 🎯 最佳实践

### 1. 在Dockerfile最开始就替换源

```dockerfile
FROM base_image

# 第一步：立即替换为国内源
RUN echo "deb https://mirrors.aliyun.com/..." > /etc/apt/sources.list
# ... 其他配置
```

### 2. 清理apt缓存减小镜像

```dockerfile
RUN apt-get update && \
    apt-get install -y package && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
```

### 3. 合并RUN命令减少层数

```dockerfile
# 不推荐
RUN apt-get update
RUN apt-get install -y package
RUN apt-get clean

# 推荐
RUN apt-get update && \
    apt-get install -y package && \
    apt-get clean
```

### 4. 删除sources.list.d目录避免冲突

```dockerfile
RUN rm -rf /etc/apt/sources.list.d/* && \
    mkdir -p /etc/apt/sources.list.d/
```

---

## 🔧 常用国内镜像站

| 类型 | 阿里云 | 清华 | 中科大 | 华为云 |
|------|--------|------|--------|--------|
| Debian/Ubuntu | ✅ | ✅ | ✅ | ✅ |
| PyPI | ✅ | ✅ | ✅ | ✅ |
| npm | ✅(淘宝) | ❌ | ❌ | ✅ |
| Docker Hub | ✅ | ✅ | ✅ | ✅ |
| Maven | ✅ | ✅ | ❌ | ✅ |

### 镜像站地址

**阿里云**:
- Debian/Ubuntu: `https://mirrors.aliyun.com`
- PyPI: `https://mirrors.aliyun.com/pypi/simple/`
- Docker Hub: `https://mirror.ccs.tencentyun.com`
- Maven: `https://maven.aliyun.com/repository/public`

**清华大学**:
- Debian/Ubuntu: `https://mirrors.tuna.tsinghua.edu.cn`
- PyPI: `https://pypi.tuna.tsinghua.edu.cn/simple`
- Docker Hub: `https://docker.mirrors.ustc.edu.cn`
- Maven: `https://mirrors.tuna.tsinghua.edu.cn/maven/maven-central`

**中科大**:
- Debian/Ubuntu: `https://mirrors.ustc.edu.cn`
- PyPI: `https://pypi.mirrors.ustc.edu.cn/simple/`
- Docker Hub: `https://docker.mirrors.ustc.edu.cn`

---

## 📊 速度对比

| 操作 | 官方源 | 国内源 | 提升 |
|------|--------|--------|------|
| apt-get update | 30-60s | 2-5s | **10倍** |
| 下载100MB包 | 5-10min | 30-60s | **10倍** |
| pip安装大包 | 3-5min | 20-40s | **5倍** |
| Docker拉取镜像 | 10-20min | 1-3min | **8倍** |

---

**使用国内镜像源，构建速度提升5-10倍！** 🚀

保存此文档，以后所有Docker项目都可以参考使用。

