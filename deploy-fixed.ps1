# OJ系统部署脚本 - Windows PowerShell版本
# 修复端口冲突问题

Write-Host "开始部署OJ系统..." -ForegroundColor Green

# 检查Docker是否安装
try {
    $dockerVersion = docker --version
    Write-Host "Docker已安装: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "错误: Docker未安装，请先安装Docker Desktop" -ForegroundColor Red
    exit 1
}

try {
    $composeVersion = docker-compose --version
    Write-Host "Docker Compose已安装: $composeVersion" -ForegroundColor Green
} catch {
    Write-Host "错误: Docker Compose未安装，请先安装Docker Compose" -ForegroundColor Red
    exit 1
}

# 创建环境配置文件
if (!(Test-Path ".env")) {
    Write-Host "创建环境配置文件..." -ForegroundColor Yellow
    Copy-Item "env.example" ".env"
    Write-Host "请编辑.env文件配置数据库和其他设置" -ForegroundColor Yellow
}

# 检查端口占用并处理
Write-Host "检查端口占用情况..." -ForegroundColor Yellow

# 检查5432端口（PostgreSQL）
$port5432 = Get-NetTCPConnection -LocalPort 5432 -ErrorAction SilentlyContinue
if ($port5432) {
    Write-Host "警告: 5432端口已被占用" -ForegroundColor Red
    Write-Host "尝试停止现有Docker容器..." -ForegroundColor Yellow
    
    try {
        docker-compose down 2>$null
        docker-compose -f docker-compose.cn.yml down 2>$null
        Start-Sleep -Seconds 3
    } catch {
        Write-Host "无法停止容器，可能没有运行中的容器" -ForegroundColor Yellow
    }
    
    # 重新检查端口
    $port5432 = Get-NetTCPConnection -LocalPort 5432 -ErrorAction SilentlyContinue
    if ($port5432) {
        Write-Host "5432端口仍然被占用，可能系统已安装PostgreSQL" -ForegroundColor Red
        Write-Host "选项:" -ForegroundColor Yellow
        Write-Host "1) 停止系统PostgreSQL服务"
        Write-Host "2) 使用不同的端口"
        Write-Host "3) 退出"
        
        $choice = Read-Host "请选择 (1/2/3)"
        
        switch ($choice) {
            "1" {
                Write-Host "尝试停止PostgreSQL服务..." -ForegroundColor Yellow
                try {
                    Stop-Service -Name "postgresql*" -Force -ErrorAction SilentlyContinue
                    Write-Host "PostgreSQL服务已停止" -ForegroundColor Green
                } catch {
                    Write-Host "无法停止PostgreSQL服务，请手动停止" -ForegroundColor Red
                    exit 1
                }
            }
            "2" {
                Write-Host "使用端口5433替代5432..." -ForegroundColor Yellow
                # 修改docker-compose文件中的端口映射
                (Get-Content "docker-compose.yml") -replace "5432:5432", "5433:5432" | Set-Content "docker-compose.yml"
                (Get-Content "docker-compose.cn.yml") -replace "5432:5432", "5433:5432" | Set-Content "docker-compose.cn.yml"
                if (Test-Path ".env") {
                    (Get-Content ".env") -replace "DB_PORT=5432", "DB_PORT=5433" | Set-Content ".env"
                }
            }
            "3" {
                Write-Host "退出部署" -ForegroundColor Red
                exit 1
            }
            default {
                Write-Host "无效选择，退出部署" -ForegroundColor Red
                exit 1
            }
        }
    }
}

# 检查8000端口（Web服务）
$port8000 = Get-NetTCPConnection -LocalPort 8000 -ErrorAction SilentlyContinue
if ($port8000) {
    Write-Host "警告: 8000端口已被占用，尝试停止现有容器..." -ForegroundColor Yellow
    try {
        docker-compose down 2>$null
        docker-compose -f docker-compose.cn.yml down 2>$null
        Start-Sleep -Seconds 3
    } catch {
        Write-Host "无法停止容器" -ForegroundColor Yellow
    }
}

# 检查80端口（Nginx）
$port80 = Get-NetTCPConnection -LocalPort 80 -ErrorAction SilentlyContinue
if ($port80) {
    Write-Host "警告: 80端口已被占用" -ForegroundColor Red
    Write-Host "选项:" -ForegroundColor Yellow
    Write-Host "1) 停止占用80端口的服务"
    Write-Host "2) 使用不同端口"
    Write-Host "3) 跳过Nginx"
    
    $choice = Read-Host "请选择 (1/2/3)"
    
    switch ($choice) {
        "1" {
            Write-Host "请手动停止占用80端口的服务" -ForegroundColor Yellow
        }
        "2" {
            Write-Host "使用端口8080替代80..." -ForegroundColor Yellow
            (Get-Content "docker-compose.yml") -replace "80:80", "8080:80" | Set-Content "docker-compose.yml"
            (Get-Content "docker-compose.cn.yml") -replace "80:80", "8080:80" | Set-Content "docker-compose.cn.yml"
        }
        "3" {
            Write-Host "跳过Nginx服务..." -ForegroundColor Yellow
            # 创建不包含Nginx的docker-compose文件
            $content = Get-Content "docker-compose.yml"
            $newContent = @()
            $skipNginx = $false
            foreach ($line in $content) {
                if ($line -match "^  nginx:") {
                    $skipNginx = $true
                    continue
                }
                if ($skipNginx -and $line -match "^[a-zA-Z]") {
                    $skipNginx = $false
                }
                if (-not $skipNginx) {
                    $newContent += $line
                }
            }
            $newContent | Set-Content "docker-compose-no-nginx.yml"
        }
    }
}

# 停止所有现有容器
Write-Host "停止现有容器..." -ForegroundColor Yellow
try {
    docker-compose down 2>$null
    docker-compose -f docker-compose.cn.yml down 2>$null
    docker-compose -f docker-compose-no-nginx.yml down 2>$null
} catch {
    Write-Host "没有运行中的容器需要停止" -ForegroundColor Yellow
}

# 清理悬空容器和镜像
Write-Host "清理悬空容器和镜像..." -ForegroundColor Yellow
try {
    docker container prune -f 2>$null
    docker image prune -f 2>$null
} catch {
    Write-Host "清理完成" -ForegroundColor Yellow
}

# 选择部署方式
Write-Host "选择部署方式:" -ForegroundColor Yellow
Write-Host "1) 标准版本"
Write-Host "2) 国内优化版本"
Write-Host "3) 无Nginx版本"

$deployChoice = Read-Host "请选择 (1/2/3)"

switch ($deployChoice) {
    "1" { $composeFile = "docker-compose.yml" }
    "2" { $composeFile = "docker-compose.cn.yml" }
    "3" { $composeFile = "docker-compose-no-nginx.yml" }
    default { 
        Write-Host "无效选择，使用标准版本" -ForegroundColor Yellow
        $composeFile = "docker-compose.yml"
    }
}

# 构建并启动服务
Write-Host "使用 $composeFile 构建并启动服务..." -ForegroundColor Green
try {
    docker-compose -f $composeFile up --build -d
} catch {
    Write-Host "构建失败，请检查Docker配置" -ForegroundColor Red
    exit 1
}

# 检查容器状态
Write-Host "检查容器状态..." -ForegroundColor Yellow
docker-compose -f $composeFile ps

# 等待数据库启动
Write-Host "等待数据库启动..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

# 检查数据库容器是否正常运行
try {
    $dbContainer = docker-compose -f $composeFile ps -q db
    if ($dbContainer) {
        $dbStatus = docker inspect -f '{{.State.Status}}' $dbContainer
        if ($dbStatus -ne "running") {
            Write-Host "错误: 数据库容器启动失败，状态: $dbStatus" -ForegroundColor Red
            Write-Host "容器日志:" -ForegroundColor Yellow
            docker-compose -f $composeFile logs db
            exit 1
        }
    } else {
        Write-Host "错误: 无法找到数据库容器" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "无法检查数据库容器状态" -ForegroundColor Yellow
}

# 运行数据库迁移
Write-Host "运行数据库迁移..." -ForegroundColor Green
try {
    docker-compose -f $composeFile exec -T web python manage.py migrate
    Write-Host "数据库迁移完成" -ForegroundColor Green
} catch {
    Write-Host "错误: 数据库迁移失败" -ForegroundColor Red
    docker-compose -f $composeFile logs web
    exit 1
}

# 创建超级用户（可选）
$response = Read-Host "是否创建超级用户? (y/n)"
if ($response -match "^[yY]([eE][sS])?$") {
    try {
        docker-compose -f $composeFile exec web python manage.py createsuperuser
    } catch {
        Write-Host "创建超级用户失败" -ForegroundColor Yellow
    }
}

# 收集静态文件
Write-Host "收集静态文件..." -ForegroundColor Green
try {
    docker-compose -f $composeFile exec -T web python manage.py collectstatic --noinput
    Write-Host "静态文件收集完成" -ForegroundColor Green
} catch {
    Write-Host "静态文件收集失败" -ForegroundColor Yellow
}

# 最终状态检查
Write-Host "最终容器状态:" -ForegroundColor Green
docker-compose -f $composeFile ps

Write-Host "部署完成！" -ForegroundColor Green

# 显示访问地址
if ($composeFile -eq "docker-compose-no-nginx.yml") {
    Write-Host "访问地址: http://localhost:8000" -ForegroundColor Cyan
} else {
    $content = Get-Content $composeFile
    if ($content -match "8080:80") {
        Write-Host "访问地址: http://localhost:8080" -ForegroundColor Cyan
    } else {
        Write-Host "访问地址: http://localhost" -ForegroundColor Cyan
    }
}

# 显示端口信息
$content = Get-Content $composeFile
if ($content -match "5433:5432") {
    Write-Host "数据库端口: 5433 (替代5432)" -ForegroundColor Cyan
} else {
    Write-Host "数据库端口: 5432" -ForegroundColor Cyan
}

Write-Host "管理后台: http://localhost/admin" -ForegroundColor Cyan
Write-Host "API接口: http://localhost/api/info/" -ForegroundColor Cyan
