#!/bin/bash

# OJ判题系统一键设置脚本
# 适用于 Linux/Mac 环境

set -e

echo "======================================"
echo "  OJ判题系统一键设置脚本"
echo "======================================"
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查函数
check_command() {
    if command -v $1 &> /dev/null; then
        echo -e "${GREEN}✓${NC} $1 已安装"
        return 0
    else
        echo -e "${RED}✗${NC} $1 未安装"
        return 1
    fi
}

# Step 1: 检查依赖
echo "Step 1: 检查系统依赖..."
echo "-----------------------------------"

MISSING_DEPS=false

if ! check_command python3; then
    MISSING_DEPS=true
fi

if ! check_command docker; then
    MISSING_DEPS=true
    echo -e "${YELLOW}提示: 请先安装Docker${NC}"
    echo "  Ubuntu: curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh"
    echo "  Mac: brew install --cask docker"
fi

if [ "$MISSING_DEPS" = true ]; then
    echo -e "${RED}缺少必要依赖，请先安装后再运行此脚本${NC}"
    exit 1
fi

echo ""

# Step 2: 检查Docker服务
echo "Step 2: 检查Docker服务..."
echo "-----------------------------------"

if ! docker ps &> /dev/null; then
    echo -e "${RED}✗${NC} Docker服务未启动"
    echo "尝试启动Docker..."
    sudo systemctl start docker || {
        echo -e "${RED}无法启动Docker服务，请手动启动${NC}"
        exit 1
    }
fi

echo -e "${GREEN}✓${NC} Docker服务正常运行"
echo ""

# Step 3: 安装Python依赖
echo "Step 3: 安装Python依赖..."
echo "-----------------------------------"

pip install docker==7.0.0

if python3 -c "import docker" &> /dev/null; then
    echo -e "${GREEN}✓${NC} docker-py 安装成功"
else
    echo -e "${RED}✗${NC} docker-py 安装失败"
    exit 1
fi

echo ""

# Step 4: 数据库迁移
echo "Step 4: 执行数据库迁移..."
echo "-----------------------------------"

python manage.py makemigrations
python manage.py migrate

echo -e "${GREEN}✓${NC} 数据库迁移完成"
echo ""

# Step 5: 构建Docker镜像
echo "Step 5: 构建判题Docker镜像..."
echo "-----------------------------------"

cd docker/judge

echo "构建 Python 判题镜像..."
docker build -t oj-judge-python:latest -f Dockerfile.python .

echo ""
echo "构建 C++ 判题镜像..."
docker build -t oj-judge-cpp:latest -f Dockerfile.cpp .

cd ../..

# 验证镜像
if docker images | grep -q "oj-judge-python"; then
    echo -e "${GREEN}✓${NC} Python 判题镜像构建成功"
else
    echo -e "${RED}✗${NC} Python 判题镜像构建失败"
    exit 1
fi

if docker images | grep -q "oj-judge-cpp"; then
    echo -e "${GREEN}✓${NC} C++ 判题镜像构建成功"
else
    echo -e "${RED}✗${NC} C++ 判题镜像构建失败"
    exit 1
fi

echo ""

# Step 6: 初始化语言配置
echo "Step 6: 初始化编程语言配置..."
echo "-----------------------------------"

python manage.py init_languages

echo -e "${GREEN}✓${NC} 语言配置初始化完成"
echo ""

# Step 7: 创建测试题目
echo "Step 7: 创建测试题目和用例..."
echo "-----------------------------------"

python manage.py shell << EOF
from apps.problems.models import Problem, TestCase

# 检查是否已存在
if Problem.objects.filter(title='A+B Problem').exists():
    print('测试题目已存在，跳过创建')
else:
    # 创建测试题目
    problem = Problem.objects.create(
        title='A+B Problem',
        description='输入两个整数a和b，输出它们的和',
        input_format='一行两个整数，用空格分隔',
        output_format='一个整数，表示a+b的值',
        time_limit=1000,
        memory_limit=256,
        difficulty='easy',
        status='published'
    )

    # 创建测试用例
    test_cases = [
        {'input': '1 2\n', 'output': '3\n'},
        {'input': '10 20\n', 'output': '30\n'},
        {'input': '-5 5\n', 'output': '0\n'},
    ]

    for idx, tc in enumerate(test_cases, 1):
        TestCase.objects.create(
            problem=problem,
            input_data=tc['input'],
            output_data=tc['output'],
            order=idx
        )

    print(f'✅ 题目创建成功: {problem.title} (ID: {problem.id})')
    print(f'✅ 测试用例: {problem.test_cases.count()} 个')
EOF

echo ""

# 完成
echo "======================================"
echo -e "${GREEN}✓ 判题系统设置完成！${NC}"
echo "======================================"
echo ""
echo "下一步:"
echo "1. 启动开发服务器: python manage.py runserver"
echo "2. 访问: http://localhost:8000/problems/1/submit/"
echo "3. 提交测试代码验证判题功能"
echo ""
echo "测试代码 (Python):"
echo "-----------------------------------"
echo "a, b = map(int, input().split())"
echo "print(a + b)"
echo "-----------------------------------"
echo ""
echo "预期结果: AC (Accepted)"
echo ""

