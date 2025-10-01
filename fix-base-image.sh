#!/bin/bash

# 将 Dockerfile.judge 的基础镜像切换为 python:3.11-slim-bookworm
# 并重新拉取最新代码，保证全部使用国内镜像源

set -e

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

cd "$ROOT_DIR"

TARGET_FILE="Dockerfile.judge"

if [ ! -f "$TARGET_FILE" ]; then
  echo "[ERROR] 找不到 $TARGET_FILE，请在项目根目录执行此脚本。"
  exit 1
fi

echo "[INFO] 更新 Dockerfile.judge 基础镜像为 python:3.11-slim-bookworm"

sed -i 's/^FROM python:3.11-slim$/FROM python:3.11-slim-bookworm/' "$TARGET_FILE"

if ! grep -q 'python:3.11-slim-bookworm' "$TARGET_FILE"; then
  echo "[ERROR] 替换失败，请手动检查 $TARGET_FILE 的 FROM 行。"
  exit 1
fi

echo "[INFO] 替换完成。"
echo "下一步建议执行："
echo "  git pull"
echo "  docker system prune -af"
echo "  docker-compose build --no-cache web"


