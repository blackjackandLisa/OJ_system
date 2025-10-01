# 判题Docker镜像构建说明

## 已优化：使用阿里云镜像源加速

两个Dockerfile已配置使用阿里云镜像源，加速apt包下载。

## 在Linux服务器上构建

### 方法1：停止当前构建，清理后重新开始

```bash
# 1. 按Ctrl+C停止当前构建

# 2. 清理部分构建的镜像
docker system prune -f

# 3. 重新运行构建脚本
./build-images.sh
```

### 方法2：手动单独构建

```bash
# 先构建Python镜像（较快）
docker build -t oj-judge-python:latest -f Dockerfile.python . --no-cache

# 等待完成后再构建C++镜像
docker build -t oj-judge-cpp:latest -f Dockerfile.cpp . --no-cache
```

### 方法3：使用国内Docker Hub镜像（最快）

如果基础镜像（python:3.10-slim, gcc:11-slim）下载太慢，配置Docker镜像加速：

```bash
# 创建或编辑Docker配置
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://mirror.ccs.tencentyun.com",
    "https://hub-mirror.c.163.com"
  ]
}
EOF

# 重启Docker服务
sudo systemctl daemon-reload
sudo systemctl restart docker

# 验证配置
docker info | grep -A 10 "Registry Mirrors"

# 然后重新构建镜像
./build-images.sh
```

## 预计构建时间

- Python镜像：3-5分钟（使用阿里云源）
- C++镜像：5-8分钟（使用阿里云源）

## 验证镜像

```bash
# 查看镜像
docker images | grep oj-judge

# 测试Python镜像
docker run --rm oj-judge-python:latest python3 --version

# 测试C++镜像
docker run --rm oj-judge-cpp:latest g++ --version
```

## 故障排查

### 问题1：构建超时
```bash
# 增加Docker构建超时时间
export DOCKER_BUILDKIT=0
docker build --network=host -t oj-judge-python:latest -f Dockerfile.python .
```

### 问题2：网络连接失败
```bash
# 检查DNS
ping mirrors.aliyun.com

# 如果无法访问，改用清华源
# 编辑Dockerfile，将 mirrors.aliyun.com 改为 mirrors.tuna.tsinghua.edu.cn
```

### 问题3：空间不足
```bash
# 检查磁盘空间
df -h

# 清理Docker缓存
docker system prune -a -f
```

