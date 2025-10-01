from django.shortcuts import render
from django.http import JsonResponse
from rest_framework.decorators import api_view
from rest_framework.response import Response

def home(request):
    """主页视图"""
    context = {
        'title': 'OJ系统',
        'description': '在线判题系统主页'
    }
    return render(request, 'core/home.html', context)

@api_view(['GET'])
def api_info(request):
    """API信息接口"""
    return Response({
        'message': 'OJ系统API',
        'version': '1.0.0',
        'status': 'running'
    })
