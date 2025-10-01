# Docker构建优化指南

## 国内网络加速方案

### 1. Docker镜像源配置

如果你经常遇到Docker镜像拉取慢的问题，可以配置国内镜像源：

#### Windows系统
创建或编辑 `%USERPROFILE%\.docker\daemon.json` 文件：

```json
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com"
  ]
}
```

#### Linux系统
创建或编辑 `/etc/docker/daemon.json` 文件：

```json
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com"
  ]
}
```

配置完成后重启Docker服务：
```bash
sudo systemctl restart docker
```

### 2. 项目优化文件

本项目提供了以下优化文件：

- `Dockerfile.cn` - 使用国内镜像源的Dockerfile
- `docker-compose.cn.yml` - 国内网络优化的docker-compose配置
- `deploy-cn.sh` - 国内网络优化的部署脚本

### 3. 使用方法

#### 使用优化版本部署
```bash
# 使用国内优化版本
./deploy-cn.sh
```

#### 手动构建优化版本
```bash
# 使用国内优化版本构建
docker-compose -f docker-compose.cn.yml up --build -d
```

### 4. 镜像源说明

#### Debian镜像源
- 阿里云: `https://mirrors.aliyun.com/debian/`
- 清华大学: `https://mirrors.tuna.tsinghua.edu.cn/debian/`
- 中科大: `https://mirrors.ustc.edu.cn/debian/`

#### Python包镜像源
- 清华大学: `https://pypi.tuna.tsinghua.edu.cn/simple/`
- 阿里云: `https://mirrors.aliyun.com/pypi/simple/`
- 豆瓣: `https://pypi.douban.com/simple/`

### 5. 性能对比

使用国内镜像源后，构建速度可以提升：
- Debian包下载: 从几KB/s提升到几MB/s
- Python包安装: 从几十KB/s提升到几MB/s
- 整体构建时间: 减少60-80%

### 6. 故障排除

#### 如果仍然很慢
1. 检查网络连接
2. 尝试不同的镜像源
3. 使用代理或VPN
4. 在非高峰时段构建

#### 如果出现404错误
1. 检查镜像源URL是否正确
2. 确认镜像源是否支持当前架构
3. 尝试使用官方源作为备用

### 7. 推荐配置

对于国内用户，推荐使用以下配置：

1. **Docker镜像源**: 阿里云或中科大
2. **Debian源**: 阿里云
3. **Python源**: 清华大学
4. **构建时间**: 选择网络较好的时段（如凌晨）

这样配置后，Docker构建速度会显著提升！
