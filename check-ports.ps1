# 端口占用检查脚本
Write-Host "=== OJ系统端口占用检查 ===" -ForegroundColor Green

# 检查常用端口
$ports = @(80, 8000, 5432, 8080, 5433)

foreach ($port in $ports) {
    try {
        $connection = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
        if ($connection) {
            Write-Host "端口 $port: 被占用" -ForegroundColor Red
            Write-Host "  进程ID: $($connection.OwningProcess)" -ForegroundColor Yellow
            Write-Host "  状态: $($connection.State)" -ForegroundColor Yellow
            
            # 尝试获取进程信息
            try {
                $process = Get-Process -Id $connection.OwningProcess -ErrorAction SilentlyContinue
                if ($process) {
                    Write-Host "  进程名: $($process.ProcessName)" -ForegroundColor Yellow
                }
            } catch {
                Write-Host "  无法获取进程信息" -ForegroundColor Yellow
            }
        } else {
            Write-Host "端口 $port: 可用" -ForegroundColor Green
        }
    } catch {
        Write-Host "端口 $port: 检查失败" -ForegroundColor Yellow
    }
}

Write-Host "`n=== Docker容器状态 ===" -ForegroundColor Green
try {
    $containers = docker ps -a 2>$null
    if ($containers) {
        Write-Host $containers -ForegroundColor Cyan
    } else {
        Write-Host "没有Docker容器" -ForegroundColor Green
    }
} catch {
    Write-Host "Docker未安装或未运行" -ForegroundColor Red
}

Write-Host "`n=== 建议的解决方案 ===" -ForegroundColor Green
Write-Host "1. 如果5432端口被占用，可以:" -ForegroundColor Yellow
Write-Host "   - 停止系统PostgreSQL服务" -ForegroundColor White
Write-Host "   - 使用不同端口 (如5433)" -ForegroundColor White
Write-Host "   - 运行: .\deploy-fixed.ps1" -ForegroundColor White

Write-Host "`n2. 如果80端口被占用，可以:" -ForegroundColor Yellow
Write-Host "   - 停止IIS或其他Web服务" -ForegroundColor White
Write-Host "   - 使用不同端口 (如8080)" -ForegroundColor White
Write-Host "   - 跳过Nginx服务" -ForegroundColor White

Write-Host "`n3. 清理现有容器:" -ForegroundColor Yellow
Write-Host "   docker-compose down" -ForegroundColor White
Write-Host "   docker system prune -f" -ForegroundColor White
