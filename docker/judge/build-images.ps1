# PowerShell script for building judge Docker images on Windows

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "开始构建判题Docker镜像" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# 构建Python镜像
Write-Host "[1/2] 构建 Python 3.10 判题镜像..." -ForegroundColor Yellow
docker build -t oj-judge-python:latest -f Dockerfile.python .
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Python镜像构建完成" -ForegroundColor Green
} else {
    Write-Host "✗ Python镜像构建失败" -ForegroundColor Red
    exit 1
}
Write-Host ""

# 构建C++镜像
Write-Host "[2/2] 构建 C++ 17 判题镜像..." -ForegroundColor Yellow
docker build -t oj-judge-cpp:latest -f Dockerfile.cpp .
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ C++镜像构建完成" -ForegroundColor Green
} else {
    Write-Host "✗ C++镜像构建失败" -ForegroundColor Red
    exit 1
}
Write-Host ""

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "所有镜像构建完成！" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# 显示镜像信息
Write-Host "已构建的镜像：" -ForegroundColor Yellow
docker images | Select-String "oj-judge"
Write-Host ""

Write-Host "可用的镜像：" -ForegroundColor Green
Write-Host "  - oj-judge-python:latest  (Python 3.10)" -ForegroundColor White
Write-Host "  - oj-judge-cpp:latest     (C++ 17)" -ForegroundColor White
Write-Host ""

Write-Host "测试镜像：" -ForegroundColor Yellow
Write-Host "  docker run --rm oj-judge-python:latest python3 --version" -ForegroundColor Gray
Write-Host "  docker run --rm oj-judge-cpp:latest g++ --version" -ForegroundColor Gray

