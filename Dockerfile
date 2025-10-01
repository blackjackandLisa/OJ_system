# 使用官方Python运行时作为父镜像
FROM python:3.11-slim

# 设置工作目录
WORKDIR /app

# 设置环境变量
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# 配置国内镜像源加速下载（适用于中国用户）
RUN if [ "$(curl -s ifconfig.me 2>/dev/null | grep -E '^(1\.|14\.|27\.|36\.|39\.|42\.|49\.|58\.|59\.|60\.|61\.|101\.|103\.|106\.|110\.|111\.|112\.|113\.|114\.|115\.|116\.|117\.|118\.|119\.|120\.|121\.|122\.|123\.|124\.|125\.|126\.|127\.|180\.|183\.|202\.|203\.|210\.|211\.|218\.|219\.|220\.|221\.|222\.)' || curl -s ipinfo.io/country 2>/dev/null | grep -q CN)" ]; then \
        echo "检测到中国IP，使用国内镜像源"; \
        sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list.d/debian.sources; \
        sed -i 's/security.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list.d/debian.sources; \
    fi

# 安装系统依赖
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        postgresql-client \
        build-essential \
        libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# 复制requirements文件
COPY requirements.txt /app/

# 使用国内镜像源安装Python依赖
RUN pip install --no-cache-dir -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple/

# 复制项目文件
COPY . /app/

# 创建静态文件目录
RUN mkdir -p /app/staticfiles /app/media

# 收集静态文件
RUN python manage.py collectstatic --noinput

# 暴露端口
EXPOSE 8000

# 启动命令
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "config.wsgi:application"]
