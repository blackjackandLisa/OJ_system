from rest_framework import viewsets, status, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from django_filters.rest_framework import DjangoFilterBackend
from django.shortcuts import render, get_object_or_404
from django.db import models

from .models import Submission, Language
from .serializers import (
    SubmissionListSerializer,
    SubmissionDetailSerializer,
    SubmissionCodeSerializer,
    SubmissionCreateSerializer,
    LanguageSerializer,
)


class LanguageViewSet(viewsets.ReadOnlyModelViewSet):
    """编程语言视图集（只读）"""
    
    queryset = Language.objects.filter(is_active=True)
    serializer_class = LanguageSerializer
    permission_classes = [AllowAny]
    ordering = ['order', 'name']


class SubmissionViewSet(viewsets.ModelViewSet):
    """提交记录视图集"""
    
    queryset = Submission.objects.all()
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['status', 'result', 'language', 'problem']
    search_fields = ['user__username', 'problem__title']
    ordering_fields = ['id', 'created_at', 'score', 'time_used', 'memory_used']
    ordering = ['-created_at']
    
    def get_serializer_class(self):
        """根据action选择序列化器"""
        if self.action == 'create':
            return SubmissionCreateSerializer
        elif self.action == 'retrieve':
            return SubmissionDetailSerializer
        elif self.action == 'code':
            return SubmissionCodeSerializer
        return SubmissionListSerializer
    
    def get_permissions(self):
        """根据action设置权限"""
        if self.action in ['create']:
            return [IsAuthenticated()]
        return [AllowAny()]
    
    def get_queryset(self):
        """获取查询集"""
        queryset = super().get_queryset()
        
        # 非管理员只能看到自己的提交和公开的提交
        user = self.request.user
        if not user.is_staff:
            if user.is_authenticated:
                # 自己的提交 或 公开的提交
                queryset = queryset.filter(
                    models.Q(user=user) | models.Q(is_public=True)
                )
            else:
                # 只看公开的
                queryset = queryset.filter(is_public=True)
        
        return queryset
    
    def create(self, request, *args, **kwargs):
        """创建提交"""
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        submission = serializer.save()
        
        # 同步判题（Phase 2）
        # TODO: Phase 3将改为异步Celery任务
        from .judger import judge_submission
        import threading
        
        # 在后台线程中判题，避免阻塞API响应
        def judge_in_background():
            try:
                judge_submission(submission.id)
            except Exception as e:
                print(f"[Judge Error] {str(e)}")
        
        thread = threading.Thread(target=judge_in_background)
        thread.start()
        
        return Response({
            'id': submission.id,
            'status': submission.status,
            'message': '提交成功，正在判题...'
        }, status=status.HTTP_201_CREATED)
    
    @action(detail=True, methods=['get'], permission_classes=[IsAuthenticated])
    def code(self, request, pk=None):
        """查看代码（需要权限）"""
        submission = self.get_object()
        
        # 只有提交者本人、老师和管理员可以查看代码
        user = request.user
        if submission.user != user:
            if not (user.is_staff or 
                    (hasattr(user, 'profile') and 
                     (user.profile.is_teacher or user.profile.is_admin))):
                return Response(
                    {'error': '您没有权限查看此代码'},
                    status=status.HTTP_403_FORBIDDEN
                )
        
        serializer = SubmissionCodeSerializer(submission)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'], permission_classes=[IsAuthenticated])
    def my_submissions(self, request):
        """我的提交"""
        queryset = self.get_queryset().filter(user=request.user)
        
        # 应用过滤和搜索
        queryset = self.filter_queryset(queryset)
        
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def statistics(self, request):
        """提交统计"""
        from django.db.models import Count, Q
        
        queryset = self.get_queryset()
        
        # 按结果统计
        result_stats = queryset.values('result').annotate(
            count=Count('id')
        ).order_by('-count')
        
        # 按语言统计
        language_stats = queryset.values(
            'language__display_name'
        ).annotate(
            count=Count('id')
        ).order_by('-count')
        
        # 总体统计
        total = queryset.count()
        accepted = queryset.filter(result='AC').count()
        ac_rate = (accepted / total * 100) if total > 0 else 0
        
        return Response({
            'total': total,
            'accepted': accepted,
            'ac_rate': round(ac_rate, 2),
            'result_stats': list(result_stats),
            'language_stats': list(language_stats),
        })
