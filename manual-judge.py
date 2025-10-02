#!/usr/bin/env python3
"""
手动触发指定提交的判题
"""

import os
import sys
import django

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from apps.judge.models import Submission
from apps.judge.judger import judge_submission

def manual_judge(submission_id):
    """手动判题"""
    
    print("="*60)
    print(f"手动判题: Submission #{submission_id}")
    print("="*60)
    print()
    
    # 获取提交
    try:
        submission = Submission.objects.get(id=submission_id)
    except Submission.DoesNotExist:
        print(f"❌ 提交 #{submission_id} 不存在！")
        return
    
    print(f"提交信息:")
    print(f"  ID: {submission.id}")
    print(f"  用户: {submission.user.username}")
    print(f"  题目: {submission.problem.title} (ID: {submission.problem.id})")
    print(f"  语言: {submission.language.display_name}")
    print(f"  状态: {submission.status} ({submission.get_status_display()})")
    print(f"  创建时间: {submission.created_at}")
    print()
    
    # 显示代码
    print(f"代码:")
    print("-"*60)
    print(submission.code)
    print("-"*60)
    print()
    
    # 检查测试用例
    test_cases_count = submission.problem.test_cases.count()
    print(f"测试用例数量: {test_cases_count}")
    if test_cases_count == 0:
        print("❌ 题目没有测试用例，无法判题！")
        return
    print()
    
    # 开始判题
    print("="*60)
    print("开始判题...")
    print("="*60)
    print()
    
    try:
        result = judge_submission(submission_id)
        
        print("="*60)
        print("判题完成！")
        print("="*60)
        print()
        
        # 刷新提交记录
        submission.refresh_from_db()
        
        print(f"判题结果:")
        print(f"  状态: {submission.status}")
        print(f"  结果: {submission.result}")
        print(f"  得分: {submission.score}/{submission.total_score}")
        print(f"  通过率: {submission.pass_rate}%")
        print(f"  测试用例: {submission.test_cases_passed}/{submission.test_cases_total}")
        print(f"  运行时间: {submission.time_used}ms" if submission.time_used else "  运行时间: 未记录")
        print(f"  内存: {submission.memory_used}KB" if submission.memory_used else "  内存: 未记录")
        
        if submission.compile_error:
            print(f"\n编译错误:")
            print(submission.compile_error[:500])
        
        if submission.runtime_error:
            print(f"\n运行时错误:")
            print(submission.runtime_error[:500])
        
        if submission.judge_detail:
            print(f"\n测试用例详情:")
            test_results = submission.judge_detail.get('test_cases', [])
            for idx, tc_result in enumerate(test_results, 1):
                print(f"  用例 {idx}: {tc_result.get('result', 'unknown')} - {tc_result.get('time', 0)}ms")
        
        print()
        
        if submission.result == 'AC':
            print("🎉 恭喜！通过所有测试用例！")
        elif submission.result:
            print(f"⚠️  判题结果: {submission.get_result_display()}")
        
    except Exception as e:
        print("="*60)
        print("❌ 判题失败！")
        print("="*60)
        print()
        print(f"错误信息: {str(e)}")
        print()
        
        import traceback
        print("详细错误:")
        traceback.print_exc()
        print()
        
        print("常见原因:")
        print("1. Docker未启动: sudo systemctl start docker")
        print("2. 判题镜像不存在: cd docker/judge && docker build ...")
        print("3. docker-py未安装: pip3 install docker==7.0.0")
        print("4. 权限问题: sudo usermod -aG docker $USER")

if __name__ == '__main__':
    if len(sys.argv) > 1:
        submission_id = int(sys.argv[1])
    else:
        # 获取最新的提交
        latest = Submission.objects.order_by('-id').first()
        if latest:
            submission_id = latest.id
            print(f"使用最新提交: #{submission_id}")
            print()
        else:
            print("使用方法: python3 manual-judge.py [提交ID]")
            sys.exit(1)
    
    manual_judge(submission_id)

