from rest_framework import serializers
from django.contrib.auth.models import User
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError
from .models import UserProfile, Class, InvitationCode


class UserProfileSerializer(serializers.ModelSerializer):
    """用户资料序列化器"""
    user_type_display = serializers.CharField(source='get_user_type_display', read_only=True)
    acceptance_rate = serializers.FloatField(read_only=True)
    
    class Meta:
        model = UserProfile
        fields = [
            'user_type',
            'user_type_display',
            'real_name',
            'student_id',
            'avatar',
            'bio',
            'school',
            'grade',
            'major',
            'phone',
            'qq',
            'wechat',
            'total_submit',
            'total_accepted',
            'total_tried',
            'acceptance_rate',
            'is_verified',
            'created_at',
        ]
        read_only_fields = ['total_submit', 'total_accepted', 'total_tried', 'created_at']


class UserSerializer(serializers.ModelSerializer):
    """用户序列化器"""
    profile = UserProfileSerializer(read_only=True)
    
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name', 'profile', 'date_joined']
        read_only_fields = ['id', 'date_joined']


class UserRegisterSerializer(serializers.ModelSerializer):
    """用户注册序列化器"""
    password = serializers.CharField(write_only=True, required=True, min_length=6)
    password2 = serializers.CharField(write_only=True, required=True, label='确认密码')
    
    # UserProfile字段
    user_type = serializers.ChoiceField(choices=UserProfile.USER_TYPE_CHOICES, default='student')
    real_name = serializers.CharField(required=False, allow_blank=True, max_length=50)
    phone = serializers.CharField(required=False, allow_blank=True, max_length=20)
    
    # 老师注册需要邀请码
    invitation_code = serializers.CharField(
        write_only=True,
        required=False,
        allow_blank=True,
        help_text='老师注册需要提供邀请码'
    )
    
    class Meta:
        model = User
        fields = [
            'username',
            'email',
            'password',
            'password2',
            'user_type',
            'real_name',
            'phone',
            'invitation_code',
        ]
        extra_kwargs = {
            'email': {'required': False, 'allow_blank': True}
        }
    
    def validate(self, attrs):
        """验证数据"""
        # 验证密码一致性
        if attrs['password'] != attrs['password2']:
            raise serializers.ValidationError({"password": "两次输入的密码不一致"})
        
        # 验证邮箱唯一性（如果提供了邮箱）
        email = attrs.get('email', '')
        if email and User.objects.filter(email=email).exists():
            raise serializers.ValidationError({"email": "该邮箱已被注册"})
        
        # 老师注册需要手机号和邀请码
        if attrs.get('user_type') == 'teacher':
            # 验证手机号
            phone = attrs.get('phone', '')
            if not phone:
                raise serializers.ValidationError({"phone": "老师注册需要提供手机号"})
            
            # 验证邀请码
            code = attrs.get('invitation_code', '')
            if not code:
                raise serializers.ValidationError({"invitation_code": "老师注册需要邀请码"})
            
            try:
                invitation = InvitationCode.objects.get(code=code)
                if not invitation.is_valid():
                    raise serializers.ValidationError({"invitation_code": "邀请码无效或已使用"})
                if invitation.for_user_type != 'teacher':
                    raise serializers.ValidationError({"invitation_code": "此邀请码不适用于老师注册"})
                attrs['invitation'] = invitation
            except InvitationCode.DoesNotExist:
                raise serializers.ValidationError({"invitation_code": "邀请码不存在"})
        
        return attrs
    
    def create(self, validated_data):
        """创建用户"""
        from django.utils import timezone
        
        # 提取UserProfile字段
        user_type = validated_data.pop('user_type', 'student')
        real_name = validated_data.pop('real_name', '')
        phone = validated_data.pop('phone', '')
        invitation = validated_data.pop('invitation', None)
        
        # 移除password2和invitation_code
        validated_data.pop('password2')
        validated_data.pop('invitation_code', None)
        
        # 如果没有邮箱，生成默认邮箱
        if not validated_data.get('email'):
            validated_data['email'] = f"{validated_data['username']}@oj.local"
        
        # 创建User
        user = User.objects.create_user(**validated_data)
        
        # 更新或创建UserProfile
        profile, created = UserProfile.objects.get_or_create(user=user)
        profile.user_type = user_type
        profile.real_name = real_name if real_name else user.username
        profile.phone = phone
        profile.save()
        
        # 如果是老师注册，标记邀请码为已使用
        if invitation:
            invitation.is_used = True
            invitation.used_by = user
            invitation.used_at = timezone.now()
            invitation.save()
        
        return user


class UserLoginSerializer(serializers.Serializer):
    """用户登录序列化器"""
    username = serializers.CharField(required=True)
    password = serializers.CharField(required=True, write_only=True)
    remember_me = serializers.BooleanField(default=False, required=False)


class ChangePasswordSerializer(serializers.Serializer):
    """修改密码序列化器"""
    old_password = serializers.CharField(required=True, write_only=True)
    new_password = serializers.CharField(required=True, write_only=True, validators=[validate_password])
    new_password2 = serializers.CharField(required=True, write_only=True, label='确认新密码')
    
    def validate(self, attrs):
        """验证密码"""
        if attrs['new_password'] != attrs['new_password2']:
            raise serializers.ValidationError({"new_password": "两次输入的新密码不一致"})
        return attrs


class UserUpdateSerializer(serializers.ModelSerializer):
    """用户更新序列化器"""
    profile = UserProfileSerializer(required=False)
    
    class Meta:
        model = User
        fields = ['email', 'first_name', 'last_name', 'profile']
    
    def update(self, instance, validated_data):
        """更新用户信息"""
        profile_data = validated_data.pop('profile', None)
        
        # 更新User字段
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        
        # 更新Profile字段
        if profile_data and hasattr(instance, 'profile'):
            profile = instance.profile
            for attr, value in profile_data.items():
                setattr(profile, attr, value)
            profile.save()
        
        return instance


class ClassSerializer(serializers.ModelSerializer):
    """班级序列化器"""
    teacher_name = serializers.CharField(source='teacher.username', read_only=True)
    student_count = serializers.IntegerField(read_only=True)
    students_info = serializers.SerializerMethodField()
    
    class Meta:
        model = Class
        fields = [
            'id',
            'name',
            'code',
            'description',
            'teacher',
            'teacher_name',
            'student_count',
            'students_info',
            'semester',
            'is_active',
            'start_date',
            'end_date',
            'created_at',
        ]
        read_only_fields = ['created_at', 'student_count']
    
    def get_students_info(self, obj):
        """获取学生信息"""
        students = obj.students.all()[:10]  # 只返回前10个
        return [{
            'id': s.id,
            'username': s.username,
            'real_name': s.profile.real_name if hasattr(s, 'profile') else s.username
        } for s in students]

