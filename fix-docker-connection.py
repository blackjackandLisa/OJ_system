#!/usr/bin/env python3
"""
修复Docker连接问题
"""

import os
import sys

def test_docker_connection():
    """测试Docker连接"""
    
    print("="*60)
    print("测试Docker连接")
    print("="*60)
    print()
    
    try:
        import docker
        print(f"✓ docker-py 版本: {docker.__version__}")
        print()
        
        # 方法1: 使用默认连接
        print("方法1: 使用默认连接 (docker.from_env())")
        try:
            client = docker.from_env()
            client.ping()
            print("✓ 连接成功！")
            
            # 测试列出镜像
            images = client.images.list()
            print(f"✓ 找到 {len(images)} 个镜像")
            
            # 查找判题镜像
            judge_images = [img for img in images if any('oj-judge' in tag for tag in img.tags)]
            if judge_images:
                print(f"✓ 找到 {len(judge_images)} 个判题镜像")
            else:
                print("⚠️  未找到判题镜像")
            
            return True
        except Exception as e:
            print(f"✗ 连接失败: {e}")
            print()
        
        # 方法2: 使用Unix socket
        print("方法2: 使用Unix socket")
        try:
            client = docker.DockerClient(base_url='unix://var/run/docker.sock')
            client.ping()
            print("✓ 连接成功！")
            return True
        except Exception as e:
            print(f"✗ 连接失败: {e}")
            print()
        
        # 方法3: 使用TCP
        print("方法3: 使用TCP (localhost)")
        try:
            client = docker.DockerClient(base_url='tcp://127.0.0.1:2375')
            client.ping()
            print("✓ 连接成功！")
            return True
        except Exception as e:
            print(f"✗ 连接失败: {e}")
            print()
        
        print("❌ 所有连接方法都失败了！")
        print()
        print("可能的解决方案:")
        print("1. 确保Docker服务运行:")
        print("   sudo systemctl status docker")
        print()
        print("2. 确保当前用户在docker组:")
        print("   sudo usermod -aG docker $USER")
        print("   注销后重新登录")
        print()
        print("3. 检查Docker socket权限:")
        print("   ls -l /var/run/docker.sock")
        print("   sudo chmod 666 /var/run/docker.sock  # 临时方案")
        print()
        
        return False
        
    except ImportError:
        print("❌ docker-py 未安装")
        print("   安装: pip3 install docker==7.0.0")
        return False

if __name__ == '__main__':
    success = test_docker_connection()
    sys.exit(0 if success else 1)

