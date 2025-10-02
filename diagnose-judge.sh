#!/bin/bash

# 判题系统完整诊断脚本
# 一次性检查所有可能的问题

echo "======================================"
echo "  判题系统完整诊断"
echo "======================================"
echo ""

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 1. 检查Docker
echo "1. Docker环境检查"
echo "-----------------------------------"
if docker ps &> /dev/null; then
    echo -e "${GREEN}✓${NC} Docker服务正常"
    docker --version
else
    echo -e "${RED}✗${NC} Docker服务异常"
    echo "  启动: sudo systemctl start docker"
fi
echo ""

# 2. 检查判题镜像
echo "2. 判题镜像检查"
echo "-----------------------------------"
if docker images | grep -q "oj-judge-python"; then
    echo -e "${GREEN}✓${NC} Python判题镜像存在"
else
    echo -e "${RED}✗${NC} Python判题镜像不存在"
    echo "  构建: cd docker/judge && docker build -t oj-judge-python:latest -f Dockerfile.python ."
fi

if docker images | grep -q "oj-judge-cpp"; then
    echo -e "${GREEN}✓${NC} C++判题镜像存在"
else
    echo -e "${RED}✗${NC} C++判题镜像不存在"
    echo "  构建: cd docker/judge && docker build -t oj-judge-cpp:latest -f Dockerfile.cpp ."
fi
echo ""

# 3. 检查Python依赖
echo "3. Python依赖检查"
echo "-----------------------------------"
if python3 -c "import docker" &> /dev/null; then
    version=$(python3 -c "import docker; print(docker.__version__)")
    echo -e "${GREEN}✓${NC} docker-py 已安装 (版本: $version)"
else
    echo -e "${RED}✗${NC} docker-py 未安装"
    echo "  安装: pip3 install docker==7.0.0"
fi
echo ""

# 4. 运行Python诊断脚本
echo "4. 详细提交记录分析"
echo "-----------------------------------"
python3 diagnose-submission.py

# 5. 查看Django日志（如果使用Docker Compose）
if [ -f "docker-compose.yml" ]; then
    echo ""
    echo "5. Django服务日志（最后20行）"
    echo "-----------------------------------"
    if docker-compose ps | grep -q "web"; then
        docker-compose logs --tail=20 web | grep -E '\[Judger\]|\[Judge Error\]|ERROR|Exception' || echo "  无判题相关日志"
    else
        echo "  Docker Compose服务未运行"
    fi
fi

echo ""
echo "======================================"
echo "  诊断完成"
echo "======================================"
echo ""
echo "下一步操作建议："
echo "1. 查看上述诊断结果"
echo "2. 如有问题，按照提示修复"
echo "3. 手动测试判题："
echo "   python3 manage.py shell"
echo "   >>> from apps.judge.judger import judge_submission"
echo "   >>> judge_submission(5)  # 替换为实际提交ID"
echo ""

