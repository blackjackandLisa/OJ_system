#!/usr/bin/env python3
"""
诊断提交记录脚本
检查判题是否执行、是否有错误
"""

import os
import sys
import django

# 设置Django环境
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from apps.judge.models import Submission, Language
from apps.problems.models import Problem
from django.contrib.auth.models import User

def diagnose_submissions():
    """诊断提交记录"""
    
    print("="*60)
    print("提交记录诊断")
    print("="*60)
    print()
    
    # 获取最近的提交
    submissions = Submission.objects.all().order_by('-id')[:10]
    
    if not submissions.exists():
        print("❌ 没有提交记录！")
        print("\n可能原因：")
        print("1. 前端提交未成功发送到后端")
        print("2. API路由配置错误")
        print("3. 权限问题")
        return
    
    print(f"📊 共有 {Submission.objects.count()} 条提交记录")
    print(f"显示最近 {min(10, submissions.count())} 条：")
    print()
    
    for submission in submissions:
        print("-"*60)
        print(f"提交ID: {submission.id}")
        print(f"用户: {submission.user.username}")
        print(f"题目: {submission.problem.title} (ID: {submission.problem.id})")
        print(f"语言: {submission.language.display_name}")
        print(f"状态: {submission.status} ({submission.get_status_display()})")
        print(f"结果: {submission.result if submission.result else '无'}")
        print(f"得分: {submission.score}/{submission.total_score}")
        print(f"通过率: {submission.pass_rate}%")
        print(f"测试用例: {submission.test_cases_passed}/{submission.test_cases_total}")
        print(f"创建时间: {submission.created_at}")
        print(f"判题完成时间: {submission.judged_at if submission.judged_at else '未完成'}")
        
        # 显示代码（前100字符）
        print(f"\n代码预览:")
        code_preview = submission.code[:100].replace('\n', '\\n')
        print(f"  {code_preview}...")
        
        # 显示错误信息
        if submission.compile_error:
            print(f"\n❌ 编译错误:")
            print(f"  {submission.compile_error[:200]}")
        
        if submission.runtime_error:
            print(f"\n❌ 运行时错误:")
            print(f"  {submission.runtime_error[:200]}")
        
        # 显示判题详情
        if submission.judge_detail:
            print(f"\n📋 判题详情:")
            test_results = submission.judge_detail.get('test_cases', [])
            if test_results:
                print(f"  测试用例数: {len(test_results)}")
                for idx, result in enumerate(test_results[:3], 1):
                    print(f"  - 用例{idx}: {result.get('result', 'unknown')}")
        
        print()

def check_docker_and_images():
    """检查Docker环境"""
    print("="*60)
    print("Docker环境检查")
    print("="*60)
    print()
    
    try:
        import docker
        client = docker.from_env()
        
        # 检查Docker可用性
        client.ping()
        print("✓ Docker服务正常")
        
        # 检查判题镜像
        images = client.images.list()
        judge_images = [img for img in images if any('oj-judge' in tag for tag in img.tags)]
        
        if judge_images:
            print(f"✓ 找到 {len(judge_images)} 个判题镜像:")
            for img in judge_images:
                for tag in img.tags:
                    if 'oj-judge' in tag:
                        print(f"  - {tag}")
        else:
            print("❌ 未找到判题镜像！")
            print("  需要构建镜像: cd docker/judge && docker build ...")
        
    except ImportError:
        print("❌ docker-py 未安装")
        print("  安装: pip3 install docker==7.0.0")
    except Exception as e:
        print(f"❌ Docker错误: {str(e)}")
    
    print()

def check_test_cases():
    """检查测试用例"""
    print("="*60)
    print("测试用例检查")
    print("="*60)
    print()
    
    from apps.problems.models import TestCase, ProblemSample
    
    problems = Problem.objects.all()[:5]
    
    for problem in problems:
        print(f"题目: {problem.title} (ID: {problem.id})")
        
        # 检查公开样例
        samples = problem.samples.count()
        print(f"  公开样例: {samples} 个")
        if samples == 0:
            print("    ⚠️ 缺少公开样例（前端无法显示）")
        
        # 检查测试用例
        testcases = problem.test_cases.count()
        print(f"  测试用例: {testcases} 个")
        if testcases == 0:
            print("    ❌ 缺少测试用例（无法判题）")
        else:
            # 检查测试用例数据
            for idx, tc in enumerate(problem.test_cases.all()[:2], 1):
                has_input = bool(tc.input_data and tc.input_data.strip())
                has_output = bool(tc.output_data and tc.output_data.strip())
                
                print(f"  - 测试用例{idx}:")
                print(f"      输入: {'✓' if has_input else '❌ 空'} ({len(tc.input_data) if tc.input_data else 0} 字符)")
                print(f"      输出: {'✓' if has_output else '❌ 空'} ({len(tc.output_data) if tc.output_data else 0} 字符)")
                
                if has_input and not tc.input_data.endswith('\n'):
                    print("      ⚠️ 输入数据缺少换行符")
                if has_output and not tc.output_data.endswith('\n'):
                    print("      ⚠️ 输出数据缺少换行符")
        
        print()

def suggest_fixes():
    """建议修复方案"""
    print("="*60)
    print("修复建议")
    print("="*60)
    print()
    
    submissions = Submission.objects.filter(status__in=['pending', 'judging'])
    if submissions.exists():
        print(f"发现 {submissions.count()} 个卡住的提交（pending/judging状态）")
        print()
        print("修复方案:")
        print("1. 清理卡住的提交:")
        print("   python3 manage.py shell")
        print("   >>> from apps.judge.models import Submission")
        print("   >>> Submission.objects.filter(status__in=['pending','judging']).update(")
        print("   ...     status='error', runtime_error='系统重启，需要重新提交')")
        print()
        print("2. 重新构建Docker镜像:")
        print("   cd docker/judge")
        print("   docker build -t oj-judge-python:latest -f Dockerfile.python .")
        print("   docker build -t oj-judge-cpp:latest -f Dockerfile.cpp .")
        print()
        print("3. 重启Django服务")
        print()
    else:
        print("✓ 没有卡住的提交")
        print()
    
    # 检查最新提交的具体问题
    latest = Submission.objects.order_by('-id').first()
    if latest and latest.status in ['pending', 'judging']:
        print(f"最新提交 #{latest.id} 卡在 {latest.status} 状态")
        print()
        print("可能原因:")
        print("1. Docker未启动或不可用")
        print("2. 判题镜像不存在")
        print("3. 判题线程异常但未更新状态")
        print("4. 测试用例数据有问题")
        print()
        print("诊断命令:")
        print("  docker ps")
        print("  docker images | grep oj-judge")
        print("  systemctl status docker")
        print()

if __name__ == '__main__':
    print()
    diagnose_submissions()
    check_docker_and_images()
    check_test_cases()
    suggest_fixes()
    
    print("="*60)
    print("诊断完成")
    print("="*60)
    print()
    print("如需手动测试判题，执行:")
    print("  python3 manage.py shell")
    print("  >>> from apps.judge.judger import judge_submission")
    print("  >>> judge_submission(提交ID)")
    print()

