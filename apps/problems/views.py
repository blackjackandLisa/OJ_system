from rest_framework import viewsets, filters, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, IsAdminUser, AllowAny
from django_filters.rest_framework import DjangoFilterBackend
from django.shortcuts import render, get_object_or_404
from django.contrib.auth.decorators import login_required
from django.db.models import Q

from .models import Problem, ProblemTag, TestCase, UserProblemStatus
from .serializers import (
    ProblemListSerializer,
    ProblemDetailSerializer,
    ProblemCreateUpdateSerializer,
    ProblemTagSerializer,
    TestCaseSerializer,
    UserProblemStatusSerializer,
)


class ProblemViewSet(viewsets.ModelViewSet):
    """题目视图集"""
    queryset = Problem.objects.all()
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['difficulty', 'status']
    search_fields = ['title', 'description', 'source']
    ordering_fields = ['id', 'difficulty', 'total_submit', 'total_accepted', 'created_at']
    ordering = ['-created_at']
    
    def get_serializer_class(self):
        """根据action选择序列化器"""
        if self.action == 'list':
            return ProblemListSerializer
        elif self.action in ['create', 'update', 'partial_update']:
            return ProblemCreateUpdateSerializer
        return ProblemDetailSerializer
    
    def get_permissions(self):
        """根据action设置权限"""
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            return [IsAdminUser()]
        return [AllowAny()]
    
    def get_queryset(self):
        """获取查询集"""
        queryset = super().get_queryset()
        
        # 非管理员只能看到已发布的题目
        if not self.request.user.is_staff:
            queryset = queryset.filter(status='published')
        
        # 标签筛选
        tags = self.request.query_params.get('tags', None)
        if tags:
            tag_ids = [int(t) for t in tags.split(',') if t.isdigit()]
            queryset = queryset.filter(tags__id__in=tag_ids).distinct()
        
        # 用户状态筛选
        user_status = self.request.query_params.get('user_status', None)
        if user_status and self.request.user.is_authenticated:
            if user_status == 'accepted':
                accepted_problem_ids = UserProblemStatus.objects.filter(
                    user=self.request.user,
                    status='accepted'
                ).values_list('problem_id', flat=True)
                queryset = queryset.filter(id__in=accepted_problem_ids)
            elif user_status == 'trying':
                trying_problem_ids = UserProblemStatus.objects.filter(
                    user=self.request.user,
                    status='trying'
                ).values_list('problem_id', flat=True)
                queryset = queryset.filter(id__in=trying_problem_ids)
            elif user_status == 'not_tried':
                tried_problem_ids = UserProblemStatus.objects.filter(
                    user=self.request.user
                ).values_list('problem_id', flat=True)
                queryset = queryset.exclude(id__in=tried_problem_ids)
        
        return queryset.prefetch_related('tags', 'samples')
    
    @action(detail=True, methods=['get'], permission_classes=[IsAdminUser])
    def testcases(self, request, pk=None):
        """获取题目的测试用例（管理员）"""
        problem = self.get_object()
        testcases = problem.test_cases.all()
        serializer = TestCaseSerializer(testcases, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'], permission_classes=[IsAdminUser])
    def add_testcase(self, request, pk=None):
        """添加测试用例（管理员）"""
        problem = self.get_object()
        serializer = TestCaseSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(problem=problem)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class ProblemTagViewSet(viewsets.ModelViewSet):
    """题目标签视图集"""
    queryset = ProblemTag.objects.all()
    serializer_class = ProblemTagSerializer
    filter_backends = [filters.SearchFilter]
    search_fields = ['name', 'description']
    
    def get_permissions(self):
        """根据action设置权限"""
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            return [IsAdminUser()]
        return [AllowAny()]


class TestCaseViewSet(viewsets.ModelViewSet):
    """测试用例视图集（管理员）"""
    queryset = TestCase.objects.all()
    serializer_class = TestCaseSerializer
    permission_classes = [IsAdminUser]
    
    def get_queryset(self):
        """获取查询集"""
        queryset = super().get_queryset()
        problem_id = self.request.query_params.get('problem_id', None)
        if problem_id:
            queryset = queryset.filter(problem_id=problem_id)
        return queryset


class UserProblemStatusViewSet(viewsets.ReadOnlyModelViewSet):
    """用户题目状态视图集"""
    queryset = UserProblemStatus.objects.all()
    serializer_class = UserProblemStatusSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        """只返回当前用户的状态"""
        return super().get_queryset().filter(user=self.request.user)


# 前端视图（Template Views）

def problem_list_view(request):
    """题目列表页面"""
    return render(request, 'problems/problem_list.html')


def problem_detail_view(request, pk):
    """题目详情页面"""
    problem = get_object_or_404(Problem, pk=pk)
    
    # 非管理员只能查看已发布的题目
    if not request.user.is_staff and problem.status != 'published':
        from django.http import Http404
        raise Http404("题目不存在")
    
    # 获取用户状态
    user_status = None
    if request.user.is_authenticated:
        try:
            user_status = UserProblemStatus.objects.get(
                user=request.user,
                problem=problem
            )
        except UserProblemStatus.DoesNotExist:
            pass
    
    context = {
        'problem': problem,
        'user_status': user_status,
    }
    return render(request, 'problems/problem_detail.html', context)


@login_required
def problem_submit_view(request, pk):
    """题目提交页面"""
    problem = get_object_or_404(Problem, pk=pk, status='published')
    
    context = {
        'problem': problem,
    }
    return render(request, 'problems/problem_submit.html', context)

