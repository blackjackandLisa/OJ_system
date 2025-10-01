from rest_framework import serializers
from django.contrib.auth.models import User
from .models import Submission, Language
from apps.problems.models import Problem


class LanguageSerializer(serializers.ModelSerializer):
    """编程语言序列化器"""
    
    class Meta:
        model = Language
        fields = [
            'id', 'name', 'display_name', 'template',
            'file_extension', 'is_active', 'order'
        ]


class SubmissionListSerializer(serializers.ModelSerializer):
    """提交列表序列化器"""
    
    username = serializers.CharField(source='user.username', read_only=True)
    problem_title = serializers.CharField(source='problem.title', read_only=True)
    language_name = serializers.CharField(source='language.display_name', read_only=True)
    result_color = serializers.CharField(source='get_result_color', read_only=True)
    result_icon = serializers.CharField(source='get_result_icon', read_only=True)
    
    class Meta:
        model = Submission
        fields = [
            'id', 'username', 'problem_title', 'language_name',
            'status', 'result', 'result_color', 'result_icon',
            'score', 'total_score', 'pass_rate',
            'time_used', 'memory_used',
            'test_cases_passed', 'test_cases_total',
            'code_length', 'created_at', 'is_public'
        ]


class SubmissionDetailSerializer(serializers.ModelSerializer):
    """提交详情序列化器"""
    
    username = serializers.CharField(source='user.username', read_only=True)
    problem_title = serializers.CharField(source='problem.title', read_only=True)
    problem_id = serializers.IntegerField(source='problem.id', read_only=True)
    language_name = serializers.CharField(source='language.display_name', read_only=True)
    result_color = serializers.CharField(source='get_result_color', read_only=True)
    result_icon = serializers.CharField(source='get_result_icon', read_only=True)
    judge_time = serializers.FloatField(read_only=True)
    
    class Meta:
        model = Submission
        fields = [
            'id', 'username', 'problem_id', 'problem_title',
            'language_name', 'status', 'result',
            'result_color', 'result_icon',
            'score', 'total_score', 'pass_rate',
            'time_used', 'memory_used',
            'test_cases_passed', 'test_cases_total',
            'compile_error', 'runtime_error', 'error_testcase',
            'judge_detail', 'code_length',
            'created_at', 'judged_at', 'judge_time',
            'is_public', 'shared'
        ]


class SubmissionCodeSerializer(serializers.ModelSerializer):
    """提交代码序列化器（敏感信息）"""
    
    language_name = serializers.CharField(source='language.display_name', read_only=True)
    
    class Meta:
        model = Submission
        fields = [
            'id', 'code', 'language_name',
            'code_length', 'created_at'
        ]


class SubmissionCreateSerializer(serializers.ModelSerializer):
    """创建提交序列化器"""
    
    problem_id = serializers.IntegerField(write_only=True)
    language_name = serializers.CharField(write_only=True)
    
    class Meta:
        model = Submission
        fields = ['problem_id', 'language_name', 'code']
    
    def validate_problem_id(self, value):
        """验证题目ID"""
        try:
            problem = Problem.objects.get(id=value, status='published')
        except Problem.DoesNotExist:
            raise serializers.ValidationError('题目不存在或未发布')
        return value
    
    def validate_language_name(self, value):
        """验证语言名称"""
        try:
            language = Language.objects.get(name=value, is_active=True)
        except Language.DoesNotExist:
            raise serializers.ValidationError('不支持的编程语言')
        return value
    
    def validate_code(self, value):
        """验证代码"""
        if not value or not value.strip():
            raise serializers.ValidationError('代码不能为空')
        
        # 代码长度限制（100KB）
        if len(value.encode('utf-8')) > 100 * 1024:
            raise serializers.ValidationError('代码长度不能超过100KB')
        
        return value
    
    def create(self, validated_data):
        """创建提交"""
        request = self.context.get('request')
        
        # 获取题目和语言
        problem = Problem.objects.get(id=validated_data['problem_id'])
        language = Language.objects.get(name=validated_data['language_name'])
        
        # 获取IP地址
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip_address = x_forwarded_for.split(',')[0]
        else:
            ip_address = request.META.get('REMOTE_ADDR', '127.0.0.1')
        
        # 获取User-Agent
        user_agent = request.META.get('HTTP_USER_AGENT', '')
        
        # 计算代码长度
        code = validated_data['code']
        code_length = len(code)
        
        # 获取测试用例总数
        test_cases_total = problem.test_cases.count()
        
        # 创建提交
        submission = Submission.objects.create(
            user=request.user,
            problem=problem,
            language=language,
            code=code,
            code_length=code_length,
            total_score=test_cases_total * 10,  # 每个测试用例10分
            test_cases_total=test_cases_total,
            ip_address=ip_address,
            user_agent=user_agent[:200],  # 限制长度
            status='pending'
        )
        
        return submission

