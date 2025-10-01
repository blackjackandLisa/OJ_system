"""
创建示例数据脚本
在Django Shell中运行此脚本
"""

from django.contrib.auth.models import User
from apps.problems.models import Problem, ProblemTag, ProblemSample, TestCase

# ============================================
# 1. 创建题目标签
# ============================================

print("创建题目标签...")

tags_data = [
    {'name': '数组', 'color': 'primary', 'description': '数组相关题目'},
    {'name': '哈希表', 'color': 'info', 'description': '哈希表相关题目'},
    {'name': '字符串', 'color': 'success', 'description': '字符串相关题目'},
    {'name': '动态规划', 'color': 'warning', 'description': '动态规划相关题目'},
    {'name': '贪心', 'color': 'danger', 'description': '贪心算法相关题目'},
    {'name': '双指针', 'color': 'secondary', 'description': '双指针技巧相关题目'},
    {'name': '排序', 'color': 'dark', 'description': '排序算法相关题目'},
    {'name': '搜索', 'color': 'primary', 'description': '搜索算法相关题目'},
    {'name': '图论', 'color': 'info', 'description': '图论相关题目'},
    {'name': '树', 'color': 'success', 'description': '树结构相关题目'},
]

tags = {}
for tag_data in tags_data:
    tag, created = ProblemTag.objects.get_or_create(
        name=tag_data['name'],
        defaults={
            'color': tag_data['color'],
            'description': tag_data['description']
        }
    )
    tags[tag_data['name']] = tag
    if created:
        print(f"  ✓ 创建标签: {tag.name}")
    else:
        print(f"  - 标签已存在: {tag.name}")

# ============================================
# 2. 获取或创建管理员用户
# ============================================

print("\n获取管理员用户...")
admin_user = User.objects.filter(is_superuser=True).first()
if not admin_user:
    print("  ! 未找到管理员用户，使用默认用户")
    admin_user = User.objects.first()

# ============================================
# 3. 创建示例题目
# ============================================

print("\n创建示例题目...")

# 题目1: 两数之和
print("\n创建题目: 两数之和")
problem1, created = Problem.objects.get_or_create(
    title='两数之和',
    defaults={
        'description': '''给定一个整数数组 `nums` 和一个整数目标值 `target`，请你在该数组中找出和为目标值 `target` 的那两个整数，并返回它们的数组下标。

你可以假设每种输入只会对应一个答案。但是，数组中同一个元素在答案里不能重复出现。

你可以按任意顺序返回答案。

**示例 1：**
```
输入：nums = [2,7,11,15], target = 9
输出：[0,1]
解释：因为 nums[0] + nums[1] == 9 ，返回 [0, 1]
```

**示例 2：**
```
输入：nums = [3,2,4], target = 6
输出：[1,2]
```''',
        'input_format': '''第一行包含两个整数 n 和 target，分别表示数组长度和目标值。
第二行包含 n 个整数，表示数组 nums。''',
        'output_format': '输出两个整数，表示两个数的下标（下标从0开始）。',
        'hint': '可以使用哈希表来优化时间复杂度。',
        'source': 'LeetCode',
        'time_limit': 1000,
        'memory_limit': 256,
        'difficulty': 'easy',
        'status': 'published',
        'created_by': admin_user,
    }
)

if created:
    # 添加标签
    problem1.tags.add(tags['数组'], tags['哈希表'])
    
    # 添加样例
    ProblemSample.objects.create(
        problem=problem1,
        input_data='4 9\n2 7 11 15',
        output_data='0 1',
        explanation='nums[0] + nums[1] = 2 + 7 = 9',
        order=0
    )
    
    ProblemSample.objects.create(
        problem=problem1,
        input_data='3 6\n3 2 4',
        output_data='1 2',
        explanation='nums[1] + nums[2] = 2 + 4 = 6',
        order=1
    )
    
    # 添加测试用例
    TestCase.objects.create(
        problem=problem1,
        input_data='4 9\n2 7 11 15',
        output_data='0 1',
        is_sample=True,
        score=20,
        order=0
    )
    
    TestCase.objects.create(
        problem=problem1,
        input_data='3 6\n3 2 4',
        output_data='1 2',
        is_sample=True,
        score=20,
        order=1
    )
    
    TestCase.objects.create(
        problem=problem1,
        input_data='2 10\n5 5',
        output_data='0 1',
        is_sample=False,
        score=30,
        order=2
    )
    
    TestCase.objects.create(
        problem=problem1,
        input_data='5 15\n1 2 3 4 11',
        output_data='3 4',
        is_sample=False,
        score=30,
        order=3
    )
    
    print("  ✓ 创建题目: 两数之和")
else:
    print("  - 题目已存在: 两数之和")

# 题目2: 回文数
print("\n创建题目: 回文数")
problem2, created = Problem.objects.get_or_create(
    title='回文数',
    defaults={
        'description': '''给你一个整数 x ，如果 x 是一个回文整数，返回 true ；否则，返回 false 。

回文数是指正序（从左向右）和倒序（从右向左）读都是一样的整数。

例如，121 是回文，而 123 不是。

**示例 1：**
```
输入：x = 121
输出：true
```

**示例 2：**
```
输入：x = -121
输出：false
解释：从左向右读为 -121 。从右向左读为 121- 。因此它不是一个回文数。
```

**示例 3：**
```
输入：x = 10
输出：false
解释：从右向左读为 01 。因此它不是一个回文数。
```''',
        'input_format': '一个整数 x。',
        'output_format': '如果是回文数输出 true，否则输出 false。',
        'hint': '你能不将整数转为字符串来解决这个问题吗？',
        'source': 'LeetCode',
        'time_limit': 1000,
        'memory_limit': 256,
        'difficulty': 'easy',
        'status': 'published',
        'created_by': admin_user,
    }
)

if created:
    # 添加标签
    problem2.tags.add(tags['字符串'])
    
    # 添加样例
    ProblemSample.objects.create(
        problem=problem2,
        input_data='121',
        output_data='true',
        explanation='121 从左往右读和从右往左读是一样的',
        order=0
    )
    
    ProblemSample.objects.create(
        problem=problem2,
        input_data='-121',
        output_data='false',
        explanation='负数不是回文数',
        order=1
    )
    
    # 添加测试用例
    TestCase.objects.create(
        problem=problem2,
        input_data='121',
        output_data='true',
        is_sample=True,
        score=25,
        order=0
    )
    
    TestCase.objects.create(
        problem=problem2,
        input_data='-121',
        output_data='false',
        is_sample=True,
        score=25,
        order=1
    )
    
    TestCase.objects.create(
        problem=problem2,
        input_data='10',
        output_data='false',
        is_sample=False,
        score=25,
        order=2
    )
    
    TestCase.objects.create(
        problem=problem2,
        input_data='12321',
        output_data='true',
        is_sample=False,
        score=25,
        order=3
    )
    
    print("  ✓ 创建题目: 回文数")
else:
    print("  - 题目已存在: 回文数")

# 题目3: 最长公共前缀
print("\n创建题目: 最长公共前缀")
problem3, created = Problem.objects.get_or_create(
    title='最长公共前缀',
    defaults={
        'description': '''编写一个函数来查找字符串数组中的最长公共前缀。

如果不存在公共前缀，返回空字符串 ""。

**示例 1：**
```
输入：strs = ["flower","flow","flight"]
输出："fl"
```

**示例 2：**
```
输入：strs = ["dog","racecar","car"]
输出：""
解释：输入不存在公共前缀。
```''',
        'input_format': '''第一行一个整数 n，表示字符串数组的长度。
接下来 n 行，每行一个字符串。''',
        'output_format': '输出最长公共前缀，如果不存在则输出空行。',
        'hint': '可以使用水平扫描或垂直扫描的方法。',
        'source': 'LeetCode',
        'time_limit': 1000,
        'memory_limit': 256,
        'difficulty': 'easy',
        'status': 'published',
        'created_by': admin_user,
    }
)

if created:
    # 添加标签
    problem3.tags.add(tags['字符串'])
    
    # 添加样例
    ProblemSample.objects.create(
        problem=problem3,
        input_data='3\nflower\nflow\nflight',
        output_data='fl',
        explanation='所有字符串的公共前缀是 "fl"',
        order=0
    )
    
    ProblemSample.objects.create(
        problem=problem3,
        input_data='3\ndog\nracecar\ncar',
        output_data='',
        explanation='不存在公共前缀',
        order=1
    )
    
    # 添加测试用例
    TestCase.objects.create(
        problem=problem3,
        input_data='3\nflower\nflow\nflight',
        output_data='fl',
        is_sample=True,
        score=30,
        order=0
    )
    
    TestCase.objects.create(
        problem=problem3,
        input_data='3\ndog\nracecar\ncar',
        output_data='',
        is_sample=True,
        score=30,
        order=1
    )
    
    TestCase.objects.create(
        problem=problem3,
        input_data='1\nabc',
        output_data='abc',
        is_sample=False,
        score=40,
        order=2
    )
    
    print("  ✓ 创建题目: 最长公共前缀")
else:
    print("  - 题目已存在: 最长公共前缀")

# 题目4: 合并两个有序数组（中等难度）
print("\n创建题目: 合并两个有序数组")
problem4, created = Problem.objects.get_or_create(
    title='合并两个有序数组',
    defaults={
        'description': '''给你两个按 非递减顺序 排列的整数数组 nums1 和 nums2，另有两个整数 m 和 n ，分别表示 nums1 和 nums2 中的元素数目。

请你 合并 nums2 到 nums1 中，使合并后的数组同样按 非递减顺序 排列。

**示例 1：**
```
输入：nums1 = [1,2,3,0,0,0], m = 3, nums2 = [2,5,6], n = 3
输出：[1,2,2,3,5,6]
解释：需要合并 [1,2,3] 和 [2,5,6] 。
合并结果是 [1,2,2,3,5,6]
```

**示例 2：**
```
输入：nums1 = [1], m = 1, nums2 = [], n = 0
输出：[1]
解释：需要合并 [1] 和 [] 。
合并结果是 [1] 。
```''',
        'input_format': '''第一行包含两个整数 m 和 n。
第二行包含 m 个整数，表示 nums1 的前 m 个元素。
第三行包含 n 个整数，表示 nums2 的所有元素。''',
        'output_format': '输出合并后的数组。',
        'hint': '可以使用双指针从后往前遍历。',
        'source': 'LeetCode',
        'time_limit': 1000,
        'memory_limit': 256,
        'difficulty': 'medium',
        'status': 'published',
        'created_by': admin_user,
    }
)

if created:
    # 添加标签
    problem4.tags.add(tags['数组'], tags['双指针'], tags['排序'])
    
    # 添加样例
    ProblemSample.objects.create(
        problem=problem4,
        input_data='3 3\n1 2 3\n2 5 6',
        output_data='1 2 2 3 5 6',
        explanation='合并两个有序数组',
        order=0
    )
    
    # 添加测试用例
    TestCase.objects.create(
        problem=problem4,
        input_data='3 3\n1 2 3\n2 5 6',
        output_data='1 2 2 3 5 6',
        is_sample=True,
        score=50,
        order=0
    )
    
    TestCase.objects.create(
        problem=problem4,
        input_data='1 0\n1\n',
        output_data='1',
        is_sample=False,
        score=50,
        order=1
    )
    
    print("  ✓ 创建题目: 合并两个有序数组")
else:
    print("  - 题目已存在: 合并两个有序数组")

# ============================================
# 4. 显示统计信息
# ============================================

print("\n" + "="*50)
print("创建完成！统计信息：")
print("="*50)
print(f"标签总数: {ProblemTag.objects.count()}")
print(f"题目总数: {Problem.objects.count()}")
print(f"  - 简单: {Problem.objects.filter(difficulty='easy').count()}")
print(f"  - 中等: {Problem.objects.filter(difficulty='medium').count()}")
print(f"  - 困难: {Problem.objects.filter(difficulty='hard').count()}")
print(f"样例总数: {ProblemSample.objects.count()}")
print(f"测试用例总数: {TestCase.objects.count()}")
print("="*50)

print("\n访问以下地址查看：")
print(f"管理后台: http://your-server-ip:8000/admin/problems/problem/")
print(f"API列表: http://your-server-ip:8000/problems/api/problems/")

