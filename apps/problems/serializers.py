from rest_framework import serializers
from django.contrib.auth.models import User
from .models import Problem, ProblemTag, ProblemSample, TestCase, UserProblemStatus


class ProblemTagSerializer(serializers.ModelSerializer):
    """题目标签序列化器"""
    problem_count = serializers.SerializerMethodField()
    
    class Meta:
        model = ProblemTag
        fields = ['id', 'name', 'color', 'description', 'problem_count']
    
    def get_problem_count(self, obj):
        return obj.problems.filter(status='published').count()


class ProblemSampleSerializer(serializers.ModelSerializer):
    """题目样例序列化器"""
    class Meta:
        model = ProblemSample
        fields = ['id', 'input_data', 'output_data', 'explanation', 'order']


class ProblemListSerializer(serializers.ModelSerializer):
    """题目列表序列化器（简化版）"""
    tags = ProblemTagSerializer(many=True, read_only=True)
    difficulty_display = serializers.CharField(source='get_difficulty_display', read_only=True)
    acceptance_rate = serializers.FloatField(read_only=True)
    user_status = serializers.SerializerMethodField()
    
    class Meta:
        model = Problem
        fields = [
            'id',
            'title',
            'difficulty',
            'difficulty_display',
            'acceptance_rate',
            'total_submit',
            'total_accepted',
            'tags',
            'user_status',
            'created_at',
        ]
    
    def get_user_status(self, obj):
        """获取当前用户的题目状态"""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            try:
                status = UserProblemStatus.objects.get(user=request.user, problem=obj)
                return {
                    'status': status.status,
                    'submit_count': status.submit_count,
                    'accepted_count': status.accepted_count,
                }
            except UserProblemStatus.DoesNotExist:
                return {'status': 'not_tried', 'submit_count': 0, 'accepted_count': 0}
        return None


class ProblemDetailSerializer(serializers.ModelSerializer):
    """题目详情序列化器（完整版）"""
    tags = ProblemTagSerializer(many=True, read_only=True)
    samples = ProblemSampleSerializer(many=True, read_only=True)
    difficulty_display = serializers.CharField(source='get_difficulty_display', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    acceptance_rate = serializers.FloatField(read_only=True)
    created_by_username = serializers.CharField(source='created_by.username', read_only=True)
    user_status = serializers.SerializerMethodField()
    
    class Meta:
        model = Problem
        fields = [
            'id',
            'title',
            'description',
            'input_format',
            'output_format',
            'hint',
            'source',
            'time_limit',
            'memory_limit',
            'difficulty',
            'difficulty_display',
            'status',
            'status_display',
            'tags',
            'samples',
            'total_submit',
            'total_accepted',
            'acceptance_rate',
            'is_special_judge',
            'created_by_username',
            'created_at',
            'updated_at',
            'user_status',
        ]
    
    def get_user_status(self, obj):
        """获取当前用户的题目状态"""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            try:
                status = UserProblemStatus.objects.get(user=request.user, problem=obj)
                return {
                    'status': status.status,
                    'submit_count': status.submit_count,
                    'accepted_count': status.accepted_count,
                    'first_accepted_at': status.first_accepted_at,
                    'last_submit_at': status.last_submit_at,
                }
            except UserProblemStatus.DoesNotExist:
                return {
                    'status': 'not_tried',
                    'submit_count': 0,
                    'accepted_count': 0,
                    'first_accepted_at': None,
                    'last_submit_at': None,
                }
        return None


class ProblemCreateUpdateSerializer(serializers.ModelSerializer):
    """题目创建/更新序列化器（管理员使用）"""
    tag_ids = serializers.ListField(
        child=serializers.IntegerField(),
        write_only=True,
        required=False
    )
    samples = ProblemSampleSerializer(many=True, required=False)
    
    class Meta:
        model = Problem
        fields = [
            'title',
            'description',
            'input_format',
            'output_format',
            'hint',
            'source',
            'time_limit',
            'memory_limit',
            'difficulty',
            'status',
            'tag_ids',
            'samples',
            'is_special_judge',
        ]
    
    def create(self, validated_data):
        """创建题目"""
        tag_ids = validated_data.pop('tag_ids', [])
        samples_data = validated_data.pop('samples', [])
        
        # 设置创建者
        request = self.context.get('request')
        if request and request.user:
            validated_data['created_by'] = request.user
        
        # 创建题目
        problem = Problem.objects.create(**validated_data)
        
        # 添加标签
        if tag_ids:
            problem.tags.set(tag_ids)
        
        # 创建样例
        for sample_data in samples_data:
            ProblemSample.objects.create(problem=problem, **sample_data)
        
        return problem
    
    def update(self, instance, validated_data):
        """更新题目"""
        tag_ids = validated_data.pop('tag_ids', None)
        samples_data = validated_data.pop('samples', None)
        
        # 更新基本字段
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        
        # 更新标签
        if tag_ids is not None:
            instance.tags.set(tag_ids)
        
        # 更新样例
        if samples_data is not None:
            # 删除旧样例
            instance.samples.all().delete()
            # 创建新样例
            for sample_data in samples_data:
                ProblemSample.objects.create(problem=instance, **sample_data)
        
        return instance


class TestCaseSerializer(serializers.ModelSerializer):
    """测试用例序列化器（管理员使用）"""
    time_limit_display = serializers.SerializerMethodField()
    memory_limit_display = serializers.SerializerMethodField()
    
    class Meta:
        model = TestCase
        fields = [
            'id',
            'input_data',
            'output_data',
            'is_sample',
            'score',
            'order',
            'time_limit',
            'memory_limit',
            'time_limit_display',
            'memory_limit_display',
        ]
    
    def get_time_limit_display(self, obj):
        return obj.get_time_limit()
    
    def get_memory_limit_display(self, obj):
        return obj.get_memory_limit()


class UserProblemStatusSerializer(serializers.ModelSerializer):
    """用户题目状态序列化器"""
    user_username = serializers.CharField(source='user.username', read_only=True)
    problem_title = serializers.CharField(source='problem.title', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    
    class Meta:
        model = UserProblemStatus
        fields = [
            'id',
            'user',
            'user_username',
            'problem',
            'problem_title',
            'status',
            'status_display',
            'submit_count',
            'accepted_count',
            'first_accepted_at',
            'last_submit_at',
        ]
        read_only_fields = [
            'submit_count',
            'accepted_count',
            'first_accepted_at',
            'last_submit_at',
        ]

