from django.core.management.base import BaseCommand
from apps.judge.models import Language


class Command(BaseCommand):
    help = '初始化编程语言配置（Python和C++）'
    
    def handle(self, *args, **options):
        self.stdout.write('正在初始化编程语言配置...\n')
        
        # Python 配置
        python, created = Language.objects.get_or_create(
            name='python',
            defaults={
                'display_name': 'Python 3.10',
                'compile_command': 'python3 -m py_compile {src}',
                'compile_timeout': 10,
                'run_command': 'python3 {src}',
                'template': '''# Python 3.10
# 请在下方编写代码

def main():
    # 从标准输入读取数据
    # 示例：读取两个整数
    # a, b = map(int, input().split())
    # print(a + b)
    pass

if __name__ == '__main__':
    main()
''',
                'docker_image': 'python:3.10-slim',
                'file_extension': '.py',
                'is_active': True,
                'order': 1
            }
        )
        
        if created:
            self.stdout.write(self.style.SUCCESS('[OK] 创建 Python 3.10 语言配置'))
        else:
            self.stdout.write(self.style.WARNING('[!] Python 3.10 配置已存在'))
        
        # C++ 配置
        cpp, created = Language.objects.get_or_create(
            name='cpp',
            defaults={
                'display_name': 'C++ 17',
                'compile_command': 'g++ -std=c++17 -O2 -Wall -o {exe} {src}',
                'compile_timeout': 30,
                'run_command': '{exe}',
                'template': '''// C++ 17
// 请在下方编写代码

#include <iostream>
using namespace std;

int main() {
    // 从标准输入读取数据
    // 示例：读取两个整数
    // int a, b;
    // cin >> a >> b;
    // cout << a + b << endl;
    
    return 0;
}
''',
                'docker_image': 'gcc:11-slim',
                'file_extension': '.cpp',
                'is_active': True,
                'order': 2
            }
        )
        
        if created:
            self.stdout.write(self.style.SUCCESS('[OK] 创建 C++ 17 语言配置'))
        else:
            self.stdout.write(self.style.WARNING('[!] C++ 17 配置已存在'))
        
        self.stdout.write('\n' + self.style.SUCCESS('语言配置初始化完成！'))
        self.stdout.write(f'\n已配置语言数量: {Language.objects.filter(is_active=True).count()}')
        self.stdout.write('\n支持的语言：')
        for lang in Language.objects.filter(is_active=True).order_by('order'):
            self.stdout.write(f'  - {lang.display_name} ({lang.name})')

