# C++ 17 判题镜像
FROM gcc:11-slim

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

