# OJ判题系统一键设置脚本 (Windows PowerShell)
# 使用方法: .\setup-judge-system.ps1

$ErrorActionPreference = "Stop"

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  OJ判题系统一键设置脚本 (Windows)"  -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# 检查函数
function Test-Command {
    param($Command)
    try {
        if (Get-Command $Command -ErrorAction SilentlyContinue) {
            Write-Host "[✓] $Command 已安装" -ForegroundColor Green
            return $true
        }
    } catch {
        Write-Host "[✗] $Command 未安装" -ForegroundColor Red
        return $false
    }
    return $false
}

# Step 1: 检查依赖
Write-Host "Step 1: 检查系统依赖..." -ForegroundColor Yellow
Write-Host "-----------------------------------"

$missingDeps = $false

if (-not (Test-Command python)) {
    $missingDeps = $true
}

if (-not (Test-Command docker)) {
    $missingDeps = $true
    Write-Host "提示: 请先安装 Docker Desktop for Windows" -ForegroundColor Yellow
    Write-Host "  下载地址: https://www.docker.com/products/docker-desktop"
}

if ($missingDeps) {
    Write-Host "缺少必要依赖，请先安装后再运行此脚本" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 2: 检查Docker服务
Write-Host "Step 2: 检查Docker服务..." -ForegroundColor Yellow
Write-Host "-----------------------------------"

try {
    docker ps | Out-Null
    Write-Host "[✓] Docker服务正常运行" -ForegroundColor Green
} catch {
    Write-Host "[✗] Docker服务未启动" -ForegroundColor Red
    Write-Host "请启动 Docker Desktop 后再运行此脚本" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Step 3: 安装Python依赖
Write-Host "Step 3: 安装Python依赖..." -ForegroundColor Yellow
Write-Host "-----------------------------------"

pip install docker==7.0.0

try {
    python -c "import docker" 2>$null
    Write-Host "[✓] docker-py 安装成功" -ForegroundColor Green
} catch {
    Write-Host "[✗] docker-py 安装失败" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 4: 数据库迁移
Write-Host "Step 4: 执行数据库迁移..." -ForegroundColor Yellow
Write-Host "-----------------------------------"

python manage.py makemigrations
python manage.py migrate

Write-Host "[✓] 数据库迁移完成" -ForegroundColor Green
Write-Host ""

# Step 5: 构建Docker镜像
Write-Host "Step 5: 构建判题Docker镜像..." -ForegroundColor Yellow
Write-Host "-----------------------------------"

Push-Location docker\judge

Write-Host "构建 Python 判题镜像..." -ForegroundColor Cyan
docker build -t oj-judge-python:latest -f Dockerfile.python .

Write-Host ""
Write-Host "构建 C++ 判题镜像..." -ForegroundColor Cyan
docker build -t oj-judge-cpp:latest -f Dockerfile.cpp .

Pop-Location

# 验证镜像
if (docker images | Select-String "oj-judge-python") {
    Write-Host "[✓] Python 判题镜像构建成功" -ForegroundColor Green
} else {
    Write-Host "[✗] Python 判题镜像构建失败" -ForegroundColor Red
    exit 1
}

if (docker images | Select-String "oj-judge-cpp") {
    Write-Host "[✓] C++ 判题镜像构建成功" -ForegroundColor Green
} else {
    Write-Host "[✗] C++ 判题镜像构建失败" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 6: 初始化语言配置
Write-Host "Step 6: 初始化编程语言配置..." -ForegroundColor Yellow
Write-Host "-----------------------------------"

python manage.py init_languages

Write-Host "[✓] 语言配置初始化完成" -ForegroundColor Green
Write-Host ""

# Step 7: 创建测试题目
Write-Host "Step 7: 创建测试题目和用例..." -ForegroundColor Yellow
Write-Host "-----------------------------------"

$pythonScript = @'
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
'@

$pythonScript | python manage.py shell

Write-Host ""

# 完成
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "[✓] 判题系统设置完成！" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "下一步:" -ForegroundColor Yellow
Write-Host "1. 启动开发服务器: python manage.py runserver"
Write-Host "2. 访问: http://localhost:8000/problems/1/submit/"
Write-Host "3. 提交测试代码验证判题功能"
Write-Host ""
Write-Host "测试代码 (Python):" -ForegroundColor Cyan
Write-Host "-----------------------------------"
Write-Host "a, b = map(int, input().split())"
Write-Host "print(a + b)"
Write-Host "-----------------------------------"
Write-Host ""
Write-Host "预期结果: AC (Accepted)" -ForegroundColor Green
Write-Host ""

