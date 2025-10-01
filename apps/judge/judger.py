"""
判题核心模块
实现代码编译、运行、测试和结果判定
"""

import os
import time
import tempfile
import subprocess
import docker
from django.utils import timezone
from django.conf import settings

from .models import Submission, Language
from apps.problems.models import TestCase


class JudgeResult:
    """判题结果类"""
    
    def __init__(self):
        self.status = 'SE'  # 默认系统错误
        self.time_used = 0  # ms
        self.memory_used = 0  # KB
        self.score = 0
        self.test_results = []
        self.compile_error = ''
        self.runtime_error = ''
        self.error_testcase = None


class Judger:
    """判题器"""
    
    def __init__(self, submission_id):
        self.submission = Submission.objects.get(id=submission_id)
        self.language = self.submission.language
        self.problem = self.submission.problem
        self.result = JudgeResult()
        self.docker_client = docker.from_env()
        
    def judge(self):
        """执行判题"""
        print(f"[Judger] 开始判题: Submission #{self.submission.id}")
        
        # 更新状态为判题中
        self.submission.status = 'judging'
        self.submission.save()
        
        try:
            # 1. 准备工作目录
            workspace = self._prepare_workspace()
            
            # 2. 编译代码（如果需要）
            if self.language.compile_command:
                compile_result = self._compile_code(workspace)
                if not compile_result['success']:
                    self._finish_with_ce(compile_result['error'])
                    return self.result
            
            # 3. 获取测试用例
            test_cases = self.problem.test_cases.all().order_by('order')
            if not test_cases.exists():
                self._finish_with_error('没有测试用例')
                return self.result
            
            # 4. 运行所有测试用例
            all_passed = True
            total_time = 0
            max_memory = 0
            
            for idx, testcase in enumerate(test_cases, 1):
                print(f"[Judger] 运行测试用例 {idx}/{len(test_cases)}")
                
                test_result = self._run_testcase(workspace, testcase)
                self.result.test_results.append(test_result)
                
                # 累计时间和内存
                total_time += test_result.get('time', 0)
                max_memory = max(max_memory, test_result.get('memory', 0))
                
                # 如果不是AC，记录并停止
                if test_result['result'] != 'AC':
                    all_passed = False
                    self.result.error_testcase = idx
                    self.result.status = test_result['result']
                    if 'error' in test_result:
                        self.result.runtime_error = test_result['error']
                    break
            
            # 5. 汇总结果
            if all_passed:
                self.result.status = 'AC'
            
            self.result.time_used = total_time
            self.result.memory_used = max_memory
            
            # 计算得分
            passed_count = len([r for r in self.result.test_results if r['result'] == 'AC'])
            total_count = len(test_cases)
            self.result.score = int((passed_count / total_count) * self.submission.total_score)
            
            # 6. 更新提交记录
            self._update_submission()
            
            # 7. 清理工作目录
            self._cleanup_workspace(workspace)
            
            print(f"[Judger] 判题完成: {self.result.status}")
            
        except Exception as e:
            print(f"[Judger] 判题异常: {str(e)}")
            self._finish_with_error(str(e))
        
        return self.result
    
    def _prepare_workspace(self):
        """准备工作目录"""
        workspace = tempfile.mkdtemp(prefix='judge_')
        
        # 写入源代码
        src_file = os.path.join(workspace, f'main{self.language.file_extension}')
        with open(src_file, 'w', encoding='utf-8') as f:
            f.write(self.submission.code)
        
        print(f"[Judger] 工作目录: {workspace}")
        return workspace
    
    def _compile_code(self, workspace):
        """编译代码"""
        print(f"[Judger] 开始编译...")
        
        src_file = os.path.join(workspace, f'main{self.language.file_extension}')
        exe_file = os.path.join(workspace, 'main')
        
        # 构建编译命令
        compile_cmd = self.language.compile_command.format(
            src=src_file,
            exe=exe_file
        )
        
        try:
            # 使用Docker编译
            container = self.docker_client.containers.run(
                image=self.language.docker_image,
                command=f'bash -c "{compile_cmd}"',
                volumes={workspace: {'bind': '/workspace', 'mode': 'rw'}},
                working_dir='/workspace',
                detach=True,
                remove=False,
                mem_limit='512m',
                network_mode='none',
                user='root'  # 编译需要写文件
            )
            
            # 等待编译完成
            result = container.wait(timeout=self.language.compile_timeout)
            logs = container.logs().decode('utf-8', errors='ignore')
            
            container.remove(force=True)
            
            if result['StatusCode'] == 0:
                print(f"[Judger] 编译成功")
                return {'success': True}
            else:
                print(f"[Judger] 编译失败: {logs}")
                return {'success': False, 'error': logs}
        
        except docker.errors.ContainerError as e:
            return {'success': False, 'error': str(e)}
        except Exception as e:
            return {'success': False, 'error': f'编译异常: {str(e)}'}
    
    def _run_testcase(self, workspace, testcase):
        """运行单个测试用例"""
        
        # 获取时间和内存限制
        time_limit = testcase.get_time_limit()  # ms
        memory_limit = testcase.get_memory_limit()  # MB
        
        # 准备输入输出文件
        input_file = os.path.join(workspace, 'input.txt')
        output_file = os.path.join(workspace, 'output.txt')
        
        with open(input_file, 'w', encoding='utf-8') as f:
            f.write(testcase.input_data)
        
        # 构建运行命令
        if self.language.name == 'python':
            src_file = os.path.join(workspace, f'main{self.language.file_extension}')
            run_cmd = f'python3 {src_file} < input.txt > output.txt 2>&1'
        elif self.language.name == 'cpp':
            exe_file = os.path.join(workspace, 'main')
            run_cmd = f'{exe_file} < input.txt > output.txt 2>&1'
        else:
            return {'result': 'SE', 'error': '不支持的语言'}
        
        try:
            # 使用Docker运行
            start_time = time.time()
            
            container = self.docker_client.containers.run(
                image=self.language.docker_image,
                command=f'bash -c "timeout {time_limit/1000}s {run_cmd}"',
                volumes={workspace: {'bind': '/workspace', 'mode': 'rw'}},
                working_dir='/workspace',
                detach=True,
                remove=False,
                mem_limit=f'{memory_limit}m',
                memswap_limit=f'{memory_limit}m',
                network_mode='none',
                pids_limit=50,
                user='root'
            )
            
            # 等待运行完成（超时时间+1秒缓冲）
            try:
                result = container.wait(timeout=(time_limit / 1000) + 1)
                actual_time = int((time.time() - start_time) * 1000)
            except:
                # 超时
                container.kill()
                container.remove(force=True)
                return {'result': 'TLE', 'time': time_limit}
            
            # 获取退出码
            exit_code = result['StatusCode']
            
            container.remove(force=True)
            
            # 检查运行时错误
            if exit_code == 124:  # timeout命令的超时退出码
                return {'result': 'TLE', 'time': time_limit}
            elif exit_code != 0:
                # 读取错误输出
                if os.path.exists(output_file):
                    with open(output_file, 'r', encoding='utf-8', errors='ignore') as f:
                        error_output = f.read()[:1000]  # 限制长度
                else:
                    error_output = f'Exit code: {exit_code}'
                return {'result': 'RE', 'time': actual_time, 'error': error_output}
            
            # 读取输出
            if not os.path.exists(output_file):
                return {'result': 'RE', 'time': actual_time, 'error': '没有输出文件'}
            
            with open(output_file, 'r', encoding='utf-8', errors='ignore') as f:
                user_output = f.read()
            
            # 检查输出大小限制（64KB）
            if len(user_output.encode('utf-8')) > 64 * 1024:
                return {'result': 'OLE', 'time': actual_time}
            
            # 比对输出
            if self._compare_output(user_output, testcase.output_data):
                return {
                    'result': 'AC',
                    'time': actual_time,
                    'memory': 0  # TODO: 获取实际内存使用
                }
            else:
                return {
                    'result': 'WA',
                    'time': actual_time,
                    'memory': 0,
                    'user_output': user_output[:500],  # 限制长度
                    'expected_output': testcase.output_data[:500]
                }
        
        except docker.errors.APIError as e:
            return {'result': 'SE', 'error': f'Docker API错误: {str(e)}'}
        except Exception as e:
            return {'result': 'SE', 'error': f'运行异常: {str(e)}'}
    
    def _compare_output(self, user_output, expected_output):
        """比对输出（忽略行尾空格和空行）"""
        
        def normalize(text):
            lines = text.strip().split('\n')
            # 去除每行末尾空格
            lines = [line.rstrip() for line in lines]
            # 去除空行
            lines = [line for line in lines if line]
            return '\n'.join(lines)
        
        user_norm = normalize(user_output)
        expected_norm = normalize(expected_output)
        
        return user_norm == expected_norm
    
    def _update_submission(self):
        """更新提交记录"""
        self.submission.status = 'finished'
        self.submission.result = self.result.status
        self.submission.score = self.result.score
        self.submission.time_used = self.result.time_used
        self.submission.memory_used = self.result.memory_used
        self.submission.test_cases_passed = len([r for r in self.result.test_results if r['result'] == 'AC'])
        self.submission.runtime_error = self.result.runtime_error
        self.submission.error_testcase = self.result.error_testcase
        self.submission.judge_detail = {
            'test_cases': self.result.test_results,
            'judged_at': timezone.now().isoformat()
        }
        self.submission.judged_at = timezone.now()
        
        # 计算通过率
        if self.submission.test_cases_total > 0:
            self.submission.pass_rate = (self.submission.test_cases_passed / self.submission.test_cases_total) * 100
        
        self.submission.save()
        
        # 更新题目统计
        self._update_problem_stats()
        
        # 更新用户统计
        self._update_user_stats()
    
    def _update_problem_stats(self):
        """更新题目统计"""
        self.problem.total_submit += 1
        if self.result.status == 'AC':
            self.problem.total_accepted += 1
        self.problem.save()
    
    def _update_user_stats(self):
        """更新用户统计"""
        if hasattr(self.submission.user, 'profile'):
            profile = self.submission.user.profile
            profile.update_stats()
    
    def _finish_with_ce(self, error_message):
        """编译错误结束"""
        self.submission.status = 'finished'
        self.submission.result = 'CE'
        self.submission.compile_error = error_message[:5000]  # 限制长度
        self.submission.score = 0
        self.submission.test_cases_passed = 0
        self.submission.judged_at = timezone.now()
        self.submission.save()
        
        self.result.status = 'CE'
        self.result.compile_error = error_message
    
    def _finish_with_error(self, error_message):
        """系统错误结束"""
        self.submission.status = 'error'
        self.submission.runtime_error = error_message[:5000]
        self.submission.save()
        
        self.result.status = 'SE'
        self.result.runtime_error = error_message
    
    def _cleanup_workspace(self, workspace):
        """清理工作目录"""
        import shutil
        try:
            shutil.rmtree(workspace)
            print(f"[Judger] 清理工作目录: {workspace}")
        except Exception as e:
            print(f"[Judger] 清理失败: {str(e)}")


def judge_submission(submission_id):
    """判题入口函数"""
    judger = Judger(submission_id)
    return judger.judge()

