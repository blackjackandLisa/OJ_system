#!/bin/bash

# 修复端口5432冲突的脚本

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🔧 修复端口5432冲突${NC}"
echo -e "${BLUE}========================================${NC}"
echo

# 检查当前端口占用情况
echo -e "${YELLOW}检查端口5432占用情况...${NC}"
if netstat -tuln 2>/dev/null | grep -q ":5432 "; then
    echo -e "${RED}端口5432确实被占用${NC}"
    
    # 显示占用端口的进程信息
    echo -e "${YELLOW}占用进程信息:${NC}"
    netstat -tulnp 2>/dev/null | grep ":5432 " | while read line; do
        echo "  $line"
    done
    
    echo
    echo -e "${YELLOW}解决方案选项:${NC}"
    echo "1) 停止系统PostgreSQL服务"
    echo "2) 修改Docker配置使用不同端口"
    echo "3) 查看详细进程信息"
    
    read -p "请选择解决方案 (1/2/3): " choice
    
    case $choice in
        1)
            echo -e "${YELLOW}停止系统PostgreSQL服务...${NC}"
            
            # 检查PostgreSQL服务状态
            if systemctl is-active --quiet postgresql; then
                echo "PostgreSQL服务正在运行，正在停止..."
                sudo systemctl stop postgresql
                sudo systemctl disable postgresql
                echo -e "${GREEN}PostgreSQL服务已停止${NC}"
            elif systemctl is-active --quiet postgresql@*; then
                echo "PostgreSQL集群服务正在运行，正在停止..."
                sudo systemctl stop postgresql@*
                sudo systemctl disable postgresql@*
                echo -e "${GREEN}PostgreSQL集群服务已停止${NC}"
            else
                echo -e "${YELLOW}未找到运行中的PostgreSQL服务${NC}"
                
                # 尝试查找PostgreSQL进程
                pg_pids=$(pgrep -f postgres)
                if [ -n "$pg_pids" ]; then
                    echo "发现PostgreSQL进程: $pg_pids"
                    echo "正在终止进程..."
                    sudo kill $pg_pids
                    echo -e "${GREEN}PostgreSQL进程已终止${NC}"
                fi
            fi
            
            # 等待端口释放
            echo "等待端口释放..."
            sleep 3
            
            # 重新检查端口
            if netstat -tuln 2>/dev/null | grep -q ":5432 "; then
                echo -e "${RED}端口5432仍然被占用${NC}"
                echo "可能需要手动处理或选择其他方案"
            else
                echo -e "${GREEN}端口5432现在可用！${NC}"
            fi
            ;;
            
        2)
            echo -e "${YELLOW}修改Docker配置使用端口5433...${NC}"
            
            # 备份原始文件
            cp docker-compose.yml docker-compose.yml.backup
            cp docker-compose.cn.yml docker-compose.cn.yml.backup 2>/dev/null || true
            
            # 修改端口映射
            sed -i 's/5432:5432/5433:5432/g' docker-compose.yml
            if [ -f docker-compose.cn.yml ]; then
                sed -i 's/5432:5432/5433:5432/g' docker-compose.cn.yml
            fi
            
            # 修改环境配置
            if [ -f .env ]; then
                sed -i 's/DB_PORT=5432/DB_PORT=5433/g' .env
            else
                echo "DB_PORT=5433" >> .env
            fi
            
            echo -e "${GREEN}Docker配置已修改为使用端口5433${NC}"
            echo "现在可以重新运行部署脚本"
            ;;
            
        3)
            echo -e "${YELLOW}详细进程信息:${NC}"
            
            # 显示详细的进程信息
            echo "占用端口5432的进程:"
            netstat -tulnp 2>/dev/null | grep ":5432 " | while read line; do
                pid=$(echo $line | awk '{print $7}' | cut -d'/' -f1)
                if [ "$pid" != "-" ] && [ -n "$pid" ]; then
                    echo "PID: $pid"
                    ps -p $pid -o pid,ppid,cmd 2>/dev/null || echo "无法获取进程信息"
                    echo "---"
                fi
            done
            
            # 显示PostgreSQL相关服务
            echo "PostgreSQL相关服务状态:"
            systemctl list-units --type=service | grep postgres || echo "无PostgreSQL服务"
            ;;
            
        *)
            echo -e "${RED}无效选择${NC}"
            exit 1
            ;;
    esac
    
else
    echo -e "${GREEN}端口5432现在可用${NC}"
fi

echo
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✅ 端口冲突处理完成${NC}"
echo -e "${BLUE}========================================${NC}"
echo

echo "现在可以重新运行部署脚本:"
echo -e "${GREEN}./deploy-linux.sh${NC}"
