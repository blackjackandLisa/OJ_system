# C++ 17 判题镜像（使用国内镜像源）
FROM gcc:11-slim

# 使用阿里云镜像源（加速apt）
RUN sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list && \
    sed -i 's/security.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list

# 创建判题用户（非root）
RUN useradd -u 10001 -m -s /bin/bash judger && \
    mkdir -p /workspace && \
    chown judger:judger /workspace

# 安装必要工具
RUN apt-get update && apt-get install -y --no-install-recommends \
    time \
    && rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /workspace

# 默认使用judger用户
USER judger

# 默认命令
CMD ["/bin/bash"]

