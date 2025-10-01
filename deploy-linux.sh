#!/bin/bash

# OJ系统Linux部署脚本
# 专门针对Linux服务器优化

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 检查系统环境
check_system() {
    log_step "检查系统环境..."
    
    # 检查操作系统
    if [[ ! -f /etc/os-release ]]; then
        log_error "无法识别操作系统版本"
        exit 1
    fi
    
    . /etc/os-release
    log_info "操作系统: $PRETTY_NAME"
    
    # 检查是否为root用户
    if [[ $EUID -eq 0 ]]; then
        log_warn "检测到root用户，建议使用普通用户运行Docker"
        read -p "是否继续? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# 检查Docker环境
check_docker() {
    log_step "检查Docker环境..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker未安装"
        log_info "安装Docker的步骤:"
        log_info "curl -fsSL https://get.docker.com -o get-docker.sh"
        log_info "sudo sh get-docker.sh"
        log_info "sudo usermod -aG docker \$USER"
        log_info "然后重新登录"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose未安装"
        log_info "安装Docker Compose的步骤:"
        log_info "sudo curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose"
        log_info "sudo chmod +x /usr/local/bin/docker-compose"
        exit 1
    fi
    
    # 检查Docker服务状态
    if ! systemctl is-active --quiet docker; then
        log_warn "Docker服务未运行，尝试启动..."
        sudo systemctl start docker
        sudo systemctl enable docker
    fi
    
    # 检查用户权限
    if ! docker ps &> /dev/null; then
        log_error "当前用户无法访问Docker"
        log_info "请运行: sudo usermod -aG docker \$USER"
        log_info "然后重新登录或运行: newgrp docker"
        exit 1
    fi
    
    log_info "Docker环境检查通过"
}

# 检查端口占用
check_ports() {
    log_step "检查端口占用..."
    
    local ports=(80 8000 5432)
    local conflicts=()
    
    for port in "${ports[@]}"; do
        if netstat -tuln 2>/dev/null | grep -q ":$port "; then
            conflicts+=($port)
            log_warn "端口 $port 已被占用"
        else
            log_info "端口 $port 可用"
        fi
    done
    
    if [ ${#conflicts[@]} -gt 0 ]; then
        log_warn "发现端口冲突: ${conflicts[*]}"
        
        # 尝试停止现有Docker容器
        log_info "尝试停止现有Docker容器..."
        docker-compose down 2>/dev/null || true
        docker-compose -f docker-compose.cn.yml down 2>/dev/null || true
        
        sleep 3
        
        # 重新检查
        for port in "${conflicts[@]}"; do
            if netstat -tuln 2>/dev/null | grep -q ":$port "; then
                log_error "端口 $port 仍然被占用"
                case $port in
                    5432)
                        log_info "解决方案:"
                        log_info "1. 停止系统PostgreSQL: sudo systemctl stop postgresql"
                        log_info "2. 使用不同端口: 修改docker-compose.yml中的端口映射"
                        ;;
                    80)
                        log_info "解决方案:"
                        log_info "1. 停止Apache/Nginx: sudo systemctl stop apache2/nginx"
                        log_info "2. 使用不同端口: 修改为8080:80"
                        ;;
                    8000)
                        log_info "解决方案:"
                        log_info "1. 停止占用8000端口的服务"
                        log_info "2. 等待几秒后重试"
                        ;;
                esac
                exit 1
            else
                log_info "端口 $port 现在可用"
            fi
        done
    fi
}

# 配置环境
setup_environment() {
    log_step "配置环境..."
    
    # 创建环境配置文件
    if [ ! -f .env ]; then
        log_info "创建环境配置文件..."
        cp env.example .env
        
        # 生成安全的SECRET_KEY
        local secret_key=$(openssl rand -base64 32)
        sed -i "s/your-secret-key-here/$secret_key/" .env
        
        # 设置生产环境配置
        sed -i 's/DEBUG=True/DEBUG=False/' .env
        sed -i 's/localhost,127.0.0.1/your-domain.com,your-server-ip/' .env
        
        log_warn "请编辑 .env 文件配置数据库密码和其他设置"
        log_info "重要配置项:"
        log_info "- DB_PASSWORD: 数据库密码"
        log_info "- ALLOWED_HOSTS: 允许访问的域名/IP"
    else
        log_info "环境配置文件已存在"
    fi
    
    # 创建必要的目录
    mkdir -p static media logs
    
    # 设置权限
    chmod 755 static media logs
    log_info "目录权限设置完成"
}

# 选择部署方式
select_deployment() {
    log_step "选择部署方式..."
    
    echo "请选择部署方式:"
    echo "1) 标准版本 (使用官方镜像源)"
    echo "2) 国内优化版本 (使用国内镜像源，推荐)"
    echo "3) 开发版本 (包含调试信息)"
    
    read -p "请输入选择 (1-3): " choice
    
    case $choice in
        1)
            COMPOSE_FILE="docker-compose.yml"
            log_info "选择标准版本"
            ;;
        2)
            COMPOSE_FILE="docker-compose.cn.yml"
            log_info "选择国内优化版本"
            ;;
        3)
            COMPOSE_FILE="docker-compose.yml"
            # 修改为开发模式
            sed -i 's/DEBUG=False/DEBUG=True/' .env
            log_info "选择开发版本"
            ;;
        *)
            log_warn "无效选择，使用国内优化版本"
            COMPOSE_FILE="docker-compose.cn.yml"
            ;;
    esac
}

# 清理旧容器和镜像
cleanup_old() {
    log_step "清理旧的容器和镜像..."
    
    # 停止所有相关容器
    docker-compose down 2>/dev/null || true
    docker-compose -f docker-compose.cn.yml down 2>/dev/null || true
    
    # 清理悬空容器和镜像
    log_info "清理悬空容器和镜像..."
    docker container prune -f
    docker image prune -f
    
    # 清理未使用的网络和卷
    docker network prune -f
    docker volume prune -f
    
    log_info "清理完成"
}

# 构建和启动服务
build_and_start() {
    log_step "构建和启动服务..."
    
    log_info "使用 $COMPOSE_FILE 构建镜像..."
    docker-compose -f $COMPOSE_FILE build --no-cache
    
    log_info "启动服务..."
    docker-compose -f $COMPOSE_FILE up -d
    
    log_info "等待服务启动..."
    sleep 10
}

# 验证服务状态
verify_services() {
    log_step "验证服务状态..."
    
    # 检查容器状态
    log_info "容器状态:"
    docker-compose -f $COMPOSE_FILE ps
    
    # 检查数据库连接
    log_info "检查数据库连接..."
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if docker-compose -f $COMPOSE_FILE exec -T web python -c "import django; django.setup(); from django.db import connection; connection.ensure_connection()" 2>/dev/null; then
            log_info "数据库连接成功"
            break
        else
            log_info "等待数据库启动... ($attempt/$max_attempts)"
            sleep 2
            ((attempt++))
        fi
    done
    
    if [ $attempt -gt $max_attempts ]; then
        log_error "数据库连接超时"
        docker-compose -f $COMPOSE_FILE logs db
        exit 1
    fi
}

# 运行数据库迁移
run_migrations() {
    log_step "运行数据库迁移..."
    
    docker-compose -f $COMPOSE_FILE exec -T web python manage.py migrate
    
    if [ $? -eq 0 ]; then
        log_info "数据库迁移成功"
    else
        log_error "数据库迁移失败"
        docker-compose -f $COMPOSE_FILE logs web
        exit 1
    fi
}

# 创建超级用户
create_superuser() {
    log_step "创建超级用户..."
    
    echo "是否创建超级用户?"
    read -p "请输入 (y/n): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker-compose -f $COMPOSE_FILE exec web python manage.py createsuperuser
        log_info "超级用户创建完成"
    else
        log_info "跳过超级用户创建"
    fi
}

# 收集静态文件
collect_static() {
    log_step "收集静态文件..."
    
    docker-compose -f $COMPOSE_FILE exec -T web python manage.py collectstatic --noinput
    
    if [ $? -eq 0 ]; then
        log_info "静态文件收集成功"
    else
        log_warn "静态文件收集失败，但不影响基本功能"
    fi
}

# 显示部署结果
show_results() {
    log_step "部署完成！"
    
    echo
    echo "=========================================="
    echo "🎉 OJ系统部署成功！"
    echo "=========================================="
    echo
    
    # 获取服务器IP
    local server_ip=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "your-server-ip")
    
    echo "📱 访问地址:"
    echo "   主页: http://$server_ip"
    echo "   管理后台: http://$server_ip/admin"
    echo "   API接口: http://$server_ip/api/info/"
    echo
    
    echo "🔧 管理命令:"
    echo "   查看日志: docker-compose -f $COMPOSE_FILE logs -f"
    echo "   重启服务: docker-compose -f $COMPOSE_FILE restart"
    echo "   停止服务: docker-compose -f $COMPOSE_FILE down"
    echo "   查看状态: docker-compose -f $COMPOSE_FILE ps"
    echo
    
    echo "📊 容器状态:"
    docker-compose -f $COMPOSE_FILE ps
    echo
    
    echo "🔐 安全建议:"
    echo "   1. 修改默认数据库密码"
    echo "   2. 配置防火墙规则"
    echo "   3. 启用HTTPS证书"
    echo "   4. 定期备份数据"
    echo
    
    log_info "部署日志已保存到 logs/deploy.log"
}

# 主函数
main() {
    echo "=========================================="
    echo "🚀 OJ系统Linux部署脚本"
    echo "=========================================="
    echo
    
    # 创建日志目录
    mkdir -p logs
    
    # 记录部署日志
    exec > >(tee -a logs/deploy.log)
    exec 2>&1
    
    check_system
    check_docker
    check_ports
    setup_environment
    select_deployment
    cleanup_old
    build_and_start
    verify_services
    run_migrations
    create_superuser
    collect_static
    show_results
}

# 错误处理
trap 'log_error "部署过程中发生错误，请检查日志"; exit 1' ERR

# 运行主函数
main "$@"
