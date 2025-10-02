#!/usr/bin/env python3
"""
修复测试数据脚本
1. 为题目添加公开样例
2. 确保测试用例存在
"""

import os
import sys
import django

# 设置Django环境
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from apps.problems.models import Problem, ProblemSample, TestCase

def fix_problem_data():
    """修复题目数据"""
    
    # 获取A+B Problem
    try:
        problem = Problem.objects.get(id=1)
        print(f"找到题目: {problem.title}")
    except Problem.DoesNotExist:
        print("题目不存在，创建新题目...")
        problem = Problem.objects.create(
            title='A+B Problem',
            description='输入两个整数a和b，输出它们的和',
            input_format='一行两个整数，用空格分隔',
            output_format='一个整数，表示a+b的值',
            time_limit=1000,
            memory_limit=256,
            difficulty='easy',
            status='published'
        )
        print(f"✓ 创建题目: {problem.title} (ID: {problem.id})")
    
    # 检查并创建样例（公开展示）
    sample_count = problem.samples.count()
    print(f"\n当前样例数量: {sample_count}")
    
    if sample_count == 0:
        print("创建公开样例...")
        
        samples_data = [
            {
                'input': '1 2',
                'output': '3',
                'explanation': '1 + 2 = 3'
            },
            {
                'input': '10 20',
                'output': '30',
                'explanation': '10 + 20 = 30'
            }
        ]
        
        for idx, sample in enumerate(samples_data):
            ProblemSample.objects.create(
                problem=problem,
                input_data=sample['input'],
                output_data=sample['output'],
                explanation=sample['explanation'],
                order=idx
            )
            print(f"  ✓ 创建样例 {idx + 1}: {sample['input']} -> {sample['output']}")
        
        print(f"✓ 创建了 {len(samples_data)} 个公开样例")
    else:
        print("样例已存在，跳过")
    
    # 检查并创建测试用例（判题使用）
    testcase_count = problem.test_cases.count()
    print(f"\n当前测试用例数量: {testcase_count}")
    
    if testcase_count == 0:
        print("创建测试用例...")
        
        test_cases_data = [
            {'input': '1 2\n', 'output': '3\n'},
            {'input': '10 20\n', 'output': '30\n'},
            {'input': '-5 5\n', 'output': '0\n'},
            {'input': '100 200\n', 'output': '300\n'},
            {'input': '0 0\n', 'output': '0\n'},
        ]
        
        for idx, tc in enumerate(test_cases_data):
            TestCase.objects.create(
                problem=problem,
                input_data=tc['input'],
                output_data=tc['output'],
                order=idx,
                score=10
            )
            print(f"  ✓ 创建测试用例 {idx + 1}")
        
        print(f"✓ 创建了 {len(test_cases_data)} 个测试用例")
    else:
        print("测试用例已存在")
        # 显示现有测试用例
        for idx, tc in enumerate(problem.test_cases.all(), 1):
            print(f"  测试用例 {idx}:")
            print(f"    输入: {repr(tc.input_data[:50])}")
            print(f"    输出: {repr(tc.output_data[:50])}")
            print(f"    分数: {tc.score}")
    
    # 总结
    print("\n" + "="*50)
    print("题目数据总结:")
    print("="*50)
    print(f"题目ID: {problem.id}")
    print(f"题目标题: {problem.title}")
    print(f"公开样例: {problem.samples.count()} 个")
    print(f"测试用例: {problem.test_cases.count()} 个")
    print(f"时间限制: {problem.time_limit} ms")
    print(f"内存限制: {problem.memory_limit} MB")
    print(f"状态: {problem.get_status_display()}")
    print("="*50)
    
    return problem

def fix_other_problems():
    """修复其他题目"""
    
    # 检查"两数之和"题目
    problems = Problem.objects.exclude(id=1)
    
    for problem in problems:
        print(f"\n检查题目: {problem.title} (ID: {problem.id})")
        
        # 检查样例
        if problem.samples.count() == 0:
            print("  ⚠ 缺少公开样例")
            # 可以根据题目添加样例
        
        # 检查测试用例
        if problem.test_cases.count() == 0:
            print("  ⚠ 缺少测试用例")
        else:
            print(f"  ✓ 测试用例: {problem.test_cases.count()} 个")

if __name__ == '__main__':
    print("="*50)
    print("修复测试数据脚本")
    print("="*50)
    print()
    
    # 修复A+B Problem
    problem = fix_problem_data()
    
    # 检查其他题目
    print("\n" + "="*50)
    print("检查其他题目...")
    print("="*50)
    fix_other_problems()
    
    print("\n✓ 脚本执行完成！")
    print("\n下一步:")
    print("1. 访问 Django Admin 查看题目详情")
    print("2. 在前端查看题目样例是否显示")
    print("3. 尝试提交代码测试判题功能")

