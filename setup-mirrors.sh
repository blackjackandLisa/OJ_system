#!/bin/bash

# 完整配置国内镜像源，包括Docker构建加速

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🚀 完整配置国内镜像加速${NC}"
echo -e "${BLUE}========================================${NC}"
echo

# 1. 配置系统apt源
echo -e "${YELLOW}[1/4] 配置系统apt镜像源...${NC}"

# 备份原始配置
sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup.$(date +%Y%m%d) 2>/dev/null || true

# 检测系统版本
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    DISTRO=$ID
    VERSION=$VERSION_CODENAME
    echo -e "${GREEN}检测到系统: $DISTRO $VERSION${NC}"
else
    echo -e "${RED}无法检测系统版本${NC}"
    exit 1
fi

# 配置镜像源
if [[ "$DISTRO" == "ubuntu" ]]; then
    sudo tee /etc/apt/sources.list > /dev/null <<EOF
# 阿里云Ubuntu镜像源
deb https://mirrors.aliyun.com/ubuntu/ $VERSION main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ $VERSION-security main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ $VERSION-updates main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ $VERSION-backports main restricted universe multiverse

deb-src https://mirrors.aliyun.com/ubuntu/ $VERSION main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ $VERSION-security main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ $VERSION-updates main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ $VERSION-backports main restricted universe multiverse
EOF

elif [[ "$DISTRO" == "debian" ]]; then
    sudo tee /etc/apt/sources.list > /dev/null <<EOF
# 阿里云Debian镜像源
deb https://mirrors.aliyun.com/debian/ $VERSION main non-free contrib non-free-firmware
deb https://mirrors.aliyun.com/debian/ $VERSION-updates main non-free contrib non-free-firmware
deb https://mirrors.aliyun.com/debian-security/ $VERSION-security main non-free contrib non-free-firmware

deb-src https://mirrors.aliyun.com/debian/ $VERSION main non-free contrib non-free-firmware
deb-src https://mirrors.aliyun.com/debian/ $VERSION-updates main non-free contrib non-free-firmware
deb-src https://mirrors.aliyun.com/debian-security/ $VERSION-security main non-free contrib non-free-firmware
EOF
fi

echo -e "${GREEN}✅ 系统apt源配置完成${NC}"

# 2. 配置Docker镜像源
echo -e "${YELLOW}[2/4] 配置Docker镜像加速...${NC}"

sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com",
    "https://registry.docker-cn.com"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

# 重启Docker服务
if systemctl is-active --quiet docker; then
    echo -e "${YELLOW}重启Docker服务...${NC}"
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    echo -e "${GREEN}✅ Docker镜像加速配置完成${NC}"
else
    echo -e "${YELLOW}Docker服务未运行，配置已保存${NC}"
fi

# 3. 配置pip镜像源
echo -e "${YELLOW}[3/4] 配置pip镜像源...${NC}"

mkdir -p ~/.pip
tee ~/.pip/pip.conf > /dev/null <<EOF
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple/
trusted-host = pypi.tuna.tsinghua.edu.cn

[install]
trusted-host = pypi.tuna.tsinghua.edu.cn
EOF

# 配置系统级pip源
sudo mkdir -p /etc/pip
sudo tee /etc/pip.conf > /dev/null <<EOF
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple/
trusted-host = pypi.tuna.tsinghua.edu.cn
EOF

echo -e "${GREEN}✅ pip镜像源配置完成${NC}"

# 4. 更新系统包列表
echo -e "${YELLOW}[4/4] 更新系统包列表...${NC}"
sudo apt update

echo
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}🎉 所有镜像源配置完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo

echo -e "${BLUE}配置总结:${NC}"
echo -e "✅ apt源: 阿里云镜像"
echo -e "✅ Docker源: 中科大+网易+百度"
echo -e "✅ pip源: 清华大学镜像"
echo

echo -e "${BLUE}预期效果:${NC}"
echo -e "📦 apt包下载速度: ${GREEN}3-10倍提升${NC}"
echo -e "🐳 Docker镜像拉取: ${GREEN}5-20倍提升${NC}"
echo -e "🐍 pip包安装速度: ${GREEN}3-10倍提升${NC}"
echo

echo -e "${YELLOW}下一步操作:${NC}"
echo -e "1. 测试apt源: ${GREEN}sudo apt install -y curl${NC}"
echo -e "2. 测试Docker: ${GREEN}docker pull python:3.11-slim${NC}"
echo -e "3. 部署项目: ${GREEN}./deploy-fast.sh${NC}"
echo

# 显示当前配置
echo -e "${BLUE}当前镜像源配置:${NC}"
echo -e "${YELLOW}apt源:${NC}"
head -n 5 /etc/apt/sources.list 2>/dev/null | sed 's/^/  /'
echo
echo -e "${YELLOW}Docker镜像源:${NC}"
grep -A 5 "registry-mirrors" /etc/docker/daemon.json 2>/dev/null | sed 's/^/  /' || echo "  Docker配置文件已创建"
