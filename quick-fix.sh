#!/bin/bash

# 快速解决端口5432冲突

echo "🔧 快速解决端口5432冲突"

# 方案1: 停止系统PostgreSQL
echo "方案1: 停止系统PostgreSQL服务"
echo "执行命令: sudo systemctl stop postgresql"
read -p "是否执行? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo systemctl stop postgresql
    sudo systemctl disable postgresql
    echo "✅ PostgreSQL服务已停止"
fi

# 等待端口释放
sleep 2

# 检查端口状态
if netstat -tuln 2>/dev/null | grep -q ":5432 "; then
    echo "⚠️  端口5432仍然被占用"
    
    echo
    echo "方案2: 修改Docker配置使用端口5433"
    read -p "是否修改Docker配置? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # 修改docker-compose文件
        sed -i 's/5432:5432/5433:5432/g' docker-compose.yml
        sed -i 's/5432:5432/5433:5432/g' docker-compose.cn.yml 2>/dev/null || true
        
        # 修改环境配置
        if [ -f .env ]; then
            sed -i 's/DB_PORT=5432/DB_PORT=5433/g' .env
        else
            echo "DB_PORT=5433" >> .env
        fi
        
        echo "✅ Docker配置已修改为使用端口5433"
    fi
else
    echo "✅ 端口5432现在可用！"
fi

echo
echo "🚀 现在可以重新运行部署脚本:"
echo "./deploy-linux.sh"
