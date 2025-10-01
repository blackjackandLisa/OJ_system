# C++ 17 判题镜像（使用国内镜像源）
# 使用Debian作为基础镜像，然后安装GCC（避免Docker Hub拉取失败）
FROM debian:bullseye-slim

# 先使用HTTP源安装ca-certificates，然后再切换到HTTPS
RUN echo "deb http://mirrors.aliyun.com/debian/ bullseye main contrib non-free" > /etc/apt/sources.list && \
    echo "deb http://mirrors.aliyun.com/debian/ bullseye-updates main contrib non-free" >> /etc/apt/sources.list && \
    echo "deb http://mirrors.aliyun.com/debian-security bullseye-security main contrib non-free" >> /etc/apt/sources.list && \
    rm -rf /etc/apt/sources.list.d/* && \
    mkdir -p /etc/apt/sources.list.d/

# 先安装ca-certificates（使用HTTP源）
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 切换到HTTPS源（现在有了CA证书）
RUN echo "deb https://mirrors.aliyun.com/debian/ bullseye main contrib non-free" > /etc/apt/sources.list && \
    echo "deb https://mirrors.aliyun.com/debian/ bullseye-updates main contrib non-free" >> /etc/apt/sources.list && \
    echo "deb https://mirrors.aliyun.com/debian-security bullseye-security main contrib non-free" >> /etc/apt/sources.list

# 安装GCC和必要工具
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        g++ \
        gcc \
        libc6-dev \
        make \
        time && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 验证GCC版本
RUN g++ --version

# 创建判题用户（非root）
RUN useradd -u 10001 -m -s /bin/bash judger && \
    mkdir -p /workspace && \
    chown judger:judger /workspace

# 设置工作目录
WORKDIR /workspace

# 默认使用judger用户
USER judger

# 默认命令
CMD ["/bin/bash"]

