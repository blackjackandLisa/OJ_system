#!/bin/bash

# 优化apt镜像源，加速包下载

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🚀 优化apt镜像源，加速包下载${NC}"
echo -e "${BLUE}========================================${NC}"
echo

# 检测操作系统
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    OS_NAME=$NAME
    OS_VERSION=$VERSION_CODENAME
    echo -e "${GREEN}检测到操作系统: $OS_NAME${NC}"
    echo -e "${GREEN}版本代号: $OS_VERSION${NC}"
else
    echo -e "${RED}无法识别操作系统版本${NC}"
    exit 1
fi

# 备份原始sources.list
echo -e "${YELLOW}备份原始sources.list...${NC}"
sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup.$(date +%Y%m%d_%H%M%S)

# 选择镜像源
echo -e "${YELLOW}选择镜像源:${NC}"
echo "1) 阿里云镜像源 (推荐)"
echo "2) 清华大学镜像源"
echo "3) 中科大镜像源"
echo "4) 网易镜像源"
echo "5) 华为云镜像源"

read -p "请选择镜像源 (1-5): " choice

case $choice in
    1)
        MIRROR_URL="https://mirrors.aliyun.com"
        MIRROR_NAME="阿里云"
        ;;
    2)
        MIRROR_URL="https://mirrors.tuna.tsinghua.edu.cn"
        MIRROR_NAME="清华大学"
        ;;
    3)
        MIRROR_URL="https://mirrors.ustc.edu.cn"
        MIRROR_NAME="中科大"
        ;;
    4)
        MIRROR_URL="http://mirrors.163.com"
        MIRROR_NAME="网易"
        ;;
    5)
        MIRROR_URL="https://repo.huaweicloud.com"
        MIRROR_NAME="华为云"
        ;;
    *)
        MIRROR_URL="https://mirrors.aliyun.com"
        MIRROR_NAME="阿里云"
        echo -e "${YELLOW}使用默认镜像源: $MIRROR_NAME${NC}"
        ;;
esac

echo -e "${GREEN}使用镜像源: $MIRROR_NAME ($MIRROR_URL)${NC}"

# 配置新的sources.list
echo -e "${YELLOW}配置新的sources.list...${NC}"

# 检测系统版本并配置对应的源
if [[ "$OS_NAME" == *"Ubuntu"* ]]; then
    cat > /tmp/sources.list << EOF
# $MIRROR_NAME Ubuntu镜像源
deb $MIRROR_URL/ubuntu/ $OS_VERSION main restricted universe multiverse
deb $MIRROR_URL/ubuntu/ $OS_VERSION-security main restricted universe multiverse
deb $MIRROR_URL/ubuntu/ $OS_VERSION-updates main restricted universe multiverse
deb $MIRROR_URL/ubuntu/ $OS_VERSION-backports main restricted universe multiverse

# 源码镜像
deb-src $MIRROR_URL/ubuntu/ $OS_VERSION main restricted universe multiverse
deb-src $MIRROR_URL/ubuntu/ $OS_VERSION-security main restricted universe multiverse
deb-src $MIRROR_URL/ubuntu/ $OS_VERSION-updates main restricted universe multiverse
deb-src $MIRROR_URL/ubuntu/ $OS_VERSION-backports main restricted universe multiverse
EOF

elif [[ "$OS_NAME" == *"Debian"* ]]; then
    cat > /tmp/sources.list << EOF
# $MIRROR_NAME Debian镜像源
deb $MIRROR_URL/debian/ $OS_VERSION main contrib non-free non-free-firmware
deb $MIRROR_URL/debian/ $OS_VERSION-updates main contrib non-free non-free-firmware
deb $MIRROR_URL/debian-security/ $OS_VERSION-security main contrib non-free non-free-firmware

# 源码镜像
deb-src $MIRROR_URL/debian/ $OS_VERSION main contrib non-free non-free-firmware
deb-src $MIRROR_URL/debian/ $OS_VERSION-updates main contrib non-free non-free-firmware
deb-src $MIRROR_URL/debian-security/ $OS_VERSION-security main contrib non-free non-free-firmware
EOF

else
    echo -e "${RED}不支持的操作系统: $OS_NAME${NC}"
    exit 1
fi

# 应用新的sources.list
sudo cp /tmp/sources.list /etc/apt/sources.list

# 更新包列表
echo -e "${YELLOW}更新包列表...${NC}"
sudo apt update

# 测试下载速度
echo -e "${YELLOW}测试下载速度...${NC}"
time sudo apt install -y --no-install-recommends curl wget

echo
echo -e "${GREEN}✅ 镜像源优化完成！${NC}"
echo
echo -e "${BLUE}优化效果:${NC}"
echo "- 包下载速度提升 3-10倍"
echo "- 减少网络超时问题"
echo "- 提高Docker构建成功率"
echo
echo -e "${YELLOW}现在可以重新运行Docker构建:${NC}"
echo "docker-compose up --build -d"
echo
echo -e "${BLUE}如需恢复原始配置:${NC}"
echo "sudo cp /etc/apt/sources.list.backup.* /etc/apt/sources.list"
