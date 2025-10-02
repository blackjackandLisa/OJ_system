#!/usr/bin/env python3
"""
测试提交API是否正常工作
"""

import os
import sys
import django

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from django.test import Client
from django.contrib.auth.models import User
from apps.problems.models import Problem
from apps.judge.models import Language
import json

def test_submission_api():
    """测试提交API"""
    
    print("="*60)
    print("测试提交API")
    print("="*60)
    print()
    
    # 1. 检查用户
    print("1. 检查用户...")
    users = User.objects.all()
    if not users.exists():
        print("❌ 没有用户！请先创建用户：")
        print("   python3 manage.py createsuperuser")
        return
    
    user = users.first()
    print(f"✓ 找到用户: {user.username}")
    print()
    
    # 2. 检查题目
    print("2. 检查题目...")
    try:
        problem = Problem.objects.get(id=1, status='published')
        print(f"✓ 找到题目: {problem.title}")
    except Problem.DoesNotExist:
        print("❌ 题目不存在或未发布！")
        return
    print()
    
    # 3. 检查语言
    print("3. 检查语言...")
    try:
        language = Language.objects.get(name='python', is_active=True)
        print(f"✓ 找到语言: {language.display_name}")
    except Language.objects.DoesNotExist:
        print("❌ Python语言配置不存在！")
        print("   运行: python3 manage.py init_languages")
        return
    print()
    
    # 4. 模拟API请求
    print("4. 模拟提交API请求...")
    client = Client()
    
    # 登录
    client.force_login(user)
    
    # 提交数据
    payload = {
        'problem_id': 1,
        'language_name': 'python',
        'code': 'a, b = map(int, input().split())\nprint(a + b)'
    }
    
    # 发送POST请求
    response = client.post(
        '/judge/api/submissions/',
        data=json.dumps(payload),
        content_type='application/json'
    )
    
    print(f"状态码: {response.status_code}")
    
    if response.status_code == 201:
        result = response.json()
        print(f"✓ 提交成功！")
        print(f"  提交ID: {result.get('id')}")
        print(f"  状态: {result.get('status')}")
        print(f"  消息: {result.get('message')}")
        print()
        print("="*60)
        print("API测试通过！前端应该可以正常提交")
        print("="*60)
    else:
        print(f"❌ 提交失败！")
        print(f"响应内容:")
        try:
            print(json.dumps(response.json(), indent=2, ensure_ascii=False))
        except:
            print(response.content.decode())
        print()
        print("="*60)
        print("API有问题，需要修复")
        print("="*60)

if __name__ == '__main__':
    test_submission_api()

