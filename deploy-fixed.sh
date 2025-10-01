#!/bin/bash

# OJ系统部署脚本 - 修复端口冲突版本
echo "开始部署OJ系统..."

# 检查Docker是否安装
if ! command -v docker &> /dev/null; then
    echo "错误: Docker未安装，请先安装Docker"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "错误: Docker Compose未安装，请先安装Docker Compose"
    exit 1
fi

# 创建环境配置文件
if [ ! -f .env ]; then
    echo "创建环境配置文件..."
    cp env.example .env
    echo "请编辑.env文件配置数据库和其他设置"
fi

# 检查端口占用并处理
echo "检查端口占用情况..."

# 检查5432端口（PostgreSQL）
if netstat -tuln 2>/dev/null | grep -q ":5432 "; then
    echo "警告: 5432端口已被占用，尝试停止现有容器..."
    docker-compose down 2>/dev/null || true
    docker-compose -f docker-compose.cn.yml down 2>/dev/null || true
    
    # 等待端口释放
    sleep 3
    
    # 如果端口仍然被占用，询问用户
    if netstat -tuln 2>/dev/null | grep -q ":5432 "; then
        echo "5432端口仍然被占用，可能系统已安装PostgreSQL"
        echo "选项:"
        echo "1) 停止系统PostgreSQL服务"
        echo "2) 使用不同的端口"
        echo "3) 退出"
        read -p "请选择 (1/2/3): " choice
        
        case $choice in
            1)
                echo "尝试停止PostgreSQL服务..."
                if command -v systemctl &> /dev/null; then
                    sudo systemctl stop postgresql
                elif command -v service &> /dev/null; then
                    sudo service postgresql stop
                else
                    echo "无法停止PostgreSQL服务，请手动停止"
                    exit 1
                fi
                ;;
            2)
                echo "使用端口5433替代5432..."
                # 修改docker-compose文件中的端口映射
                sed -i 's/5432:5432/5433:5432/g' docker-compose.yml
                sed -i 's/5432:5432/5433:5432/g' docker-compose.cn.yml
                sed -i 's/DB_PORT=5432/DB_PORT=5433/g' .env 2>/dev/null || true
                ;;
            3)
                echo "退出部署"
                exit 1
                ;;
            *)
                echo "无效选择，退出部署"
                exit 1
                ;;
        esac
    fi
fi

# 检查8000端口（Web服务）
if netstat -tuln 2>/dev/null | grep -q ":8000 "; then
    echo "警告: 8000端口已被占用，尝试停止现有容器..."
    docker-compose down 2>/dev/null || true
    docker-compose -f docker-compose.cn.yml down 2>/dev/null || true
    sleep 3
fi

# 检查80端口（Nginx）
if netstat -tuln 2>/dev/null | grep -q ":80 "; then
    echo "警告: 80端口已被占用"
    echo "选项:"
    echo "1) 停止占用80端口的服务"
    echo "2) 使用不同端口"
    echo "3) 跳过Nginx"
    read -p "请选择 (1/2/3): " choice
    
    case $choice in
        1)
            echo "请手动停止占用80端口的服务"
            ;;
        2)
            echo "使用端口8080替代80..."
            sed -i 's/80:80/8080:80/g' docker-compose.yml
            sed -i 's/80:80/8080:80/g' docker-compose.cn.yml
            ;;
        3)
            echo "跳过Nginx服务..."
            # 创建不包含Nginx的docker-compose文件
            cp docker-compose.yml docker-compose-no-nginx.yml
            sed -i '/nginx:/,$d' docker-compose-no-nginx.yml
            ;;
    esac
fi

# 停止所有现有容器
echo "停止现有容器..."
docker-compose down 2>/dev/null || true
docker-compose -f docker-compose.cn.yml down 2>/dev/null || true
docker-compose -f docker-compose-no-nginx.yml down 2>/dev/null || true

# 清理悬空容器和镜像
echo "清理悬空容器和镜像..."
docker container prune -f 2>/dev/null || true
docker image prune -f 2>/dev/null || true

# 选择部署方式
echo "选择部署方式:"
echo "1) 标准版本"
echo "2) 国内优化版本"
echo "3) 无Nginx版本"
read -p "请选择 (1/2/3): " deploy_choice

case $deploy_choice in
    1)
        COMPOSE_FILE="docker-compose.yml"
        ;;
    2)
        COMPOSE_FILE="docker-compose.cn.yml"
        ;;
    3)
        COMPOSE_FILE="docker-compose-no-nginx.yml"
        ;;
    *)
        echo "无效选择，使用标准版本"
        COMPOSE_FILE="docker-compose.yml"
        ;;
esac

# 构建并启动服务
echo "使用 $COMPOSE_FILE 构建并启动服务..."
docker-compose -f $COMPOSE_FILE up --build -d

# 检查容器状态
echo "检查容器状态..."
docker-compose -f $COMPOSE_FILE ps

# 等待数据库启动
echo "等待数据库启动..."
sleep 15

# 检查数据库容器是否正常运行
DB_STATUS=$(docker-compose -f $COMPOSE_FILE ps -q db)
if [ -z "$DB_STATUS" ] || [ "$(docker inspect -f '{{.State.Status}}' $DB_STATUS 2>/dev/null)" != "running" ]; then
    echo "错误: 数据库容器启动失败"
    echo "容器日志:"
    docker-compose -f $COMPOSE_FILE logs db
    exit 1
fi

# 运行数据库迁移
echo "运行数据库迁移..."
docker-compose -f $COMPOSE_FILE exec -T web python manage.py migrate

# 检查迁移是否成功
if [ $? -ne 0 ]; then
    echo "错误: 数据库迁移失败"
    docker-compose -f $COMPOSE_FILE logs web
    exit 1
fi

# 创建超级用户（可选）
echo "是否创建超级用户? (y/n)"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    docker-compose -f $COMPOSE_FILE exec web python manage.py createsuperuser
fi

# 收集静态文件
echo "收集静态文件..."
docker-compose -f $COMPOSE_FILE exec -T web python manage.py collectstatic --noinput

# 最终状态检查
echo "最终容器状态:"
docker-compose -f $COMPOSE_FILE ps

echo "部署完成！"
if [ "$COMPOSE_FILE" = "docker-compose-no-nginx.yml" ]; then
    echo "访问地址: http://localhost:8000"
else
    if grep -q "8080:80" $COMPOSE_FILE; then
        echo "访问地址: http://localhost:8080"
    else
        echo "访问地址: http://localhost"
    fi
fi

# 显示端口信息
if grep -q "5433:5432" $COMPOSE_FILE; then
    echo "数据库端口: 5433 (替代5432)"
else
    echo "数据库端口: 5432"
fi

echo "管理后台: http://localhost/admin"
echo "API接口: http://localhost/api/info/"
