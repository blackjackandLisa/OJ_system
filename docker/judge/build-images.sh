#!/bin/bash
# 构建判题Docker镜像

set -e

echo "========================================="
echo "开始构建判题Docker镜像"
echo "========================================="
echo ""

# 构建Python镜像
echo "[1/2] 构建 Python 3.10 判题镜像..."
docker build -t oj-judge-python:latest -f Dockerfile.python .
echo "✓ Python镜像构建完成"
echo ""

# 构建C++镜像
echo "[2/2] 构建 C++ 17 判题镜像..."
docker build -t oj-judge-cpp:latest -f Dockerfile.cpp .
echo "✓ C++镜像构建完成"
echo ""

echo "========================================="
echo "所有镜像构建完成！"
echo "========================================="
echo ""

# 显示镜像信息
echo "已构建的镜像："
docker images | grep "oj-judge"
echo ""

echo "可用的镜像："
echo "  - oj-judge-python:latest  (Python 3.10)"
echo "  - oj-judge-cpp:latest     (C++ 17)"
echo ""

echo "测试镜像："
echo "  docker run --rm oj-judge-python:latest python3 --version"
echo "  docker run --rm oj-judge-cpp:latest g++ --version"

