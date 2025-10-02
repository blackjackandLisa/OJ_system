# Django Admin 后台界面优化

## ✅ 已修复的问题

### 问题描述

在题目管理页面的"测试用例"区域：
- ❌ 只显示排序、分数、时间限制、内存限制等字段
- ❌ **缺少最关键的"输入数据"和"输出数据"字段**
- ❌ 无法直接编辑测试用例的实际内容

### 修复内容

✅ **添加输入输出字段** - 测试用例现在可以直接编辑输入输出数据  
✅ **改进布局** - 从TabularInline改为StackedInline，更适合大量文本  
✅ **优化显示** - 使用等宽字体，合适的行高和宽度  
✅ **添加预览** - 列表页显示输入输出预览（显示换行符）  
✅ **字段分组** - 使用fieldsets分组：基本信息、测试数据、资源限制  
✅ **重要提示** - 添加"输入输出必须包含换行符\\n"的提醒

---

## 🎨 界面改进详情

### 1. 测试用例内联编辑（题目页面内）

#### 改进前：
```
❌ 只有：排序、是否为样例、分数、时间限制、内存限制
❌ 看不到实际的测试数据
```

#### 改进后：
```
✅ 字段顺序：
   1. 排序
   2. 输入数据 (多行文本框，等宽字体)
   3. 输出数据 (多行文本框，等宽字体)
   4. 是否为样例
   5. 分数
   6. 时间限制（可选，留空使用题目默认）
   7. 内存限制（可选，留空使用题目默认）

✅ 使用 StackedInline 布局，每个测试用例占据完整宽度
✅ 输入输出框：6行高，等宽字体，100%宽度
```

### 2. 测试用例独立管理页面

访问: `/admin/problems/testcase/`

#### 列表页改进：

| 字段 | 说明 | 样式 |
|------|------|------|
| 题目 | 所属题目 | 链接 |
| 排序 | 测试用例顺序 | 数字 |
| **输入预览** | 前30字符，换行显示为↵ | 等宽代码样式 |
| **输出预览** | 前30字符，换行显示为↵ | 等宽代码样式 |
| 是否样例 | 布尔值 | 图标 |
| 分数 | 测试用例分数 | 数字 |
| 时间限制 | 加粗显示自定义，灰色显示默认 | 格式化 |
| 内存限制 | 加粗显示自定义，灰色显示默认 | 格式化 |

#### 详情页改进：

使用 **fieldsets** 分组显示：

```
📋 基本信息
   - 题目
   - 排序
   - 是否为样例
   - 分数

📝 测试数据
   ⚠️ 提示：输入输出数据末尾必须包含换行符 \n
   - 输入数据 (多行文本框)
   - 输出数据 (多行文本框)

⚙️ 资源限制
   提示：留空则使用题目默认限制
   - 时间限制
   - 内存限制
```

---

## 📝 使用指南

### 在题目页面添加测试用例

1. **访问题目编辑页面**:
   ```
   /admin/problems/problem/1/change/
   ```

2. **滚动到"测试用例"区域**

3. **点击"添加另一个测试用例"**

4. **填写测试数据**:
   ```
   排序: 0
   
   输入数据:
   1 2
   (注意末尾有换行，实际输入: "1 2\n")
   
   输出数据:
   3
   (注意末尾有换行，实际输入: "3\n")
   
   是否为样例: ☐ (不勾选)
   分数: 10
   时间限制: (留空使用题目默认)
   内存限制: (留空使用题目默认)
   ```

5. **保存题目**

### 独立管理测试用例

1. **访问测试用例列表**:
   ```
   /admin/problems/testcase/
   ```

2. **查看所有测试用例**:
   - 可以按题目筛选
   - 可以看到输入输出预览
   - 换行符显示为 `↵` 符号

3. **编辑测试用例**:
   - 点击任意测试用例
   - 使用分组的fieldsets编辑
   - 注意输入输出末尾的换行符

---

## ⚠️ 重要注意事项

### 1. 换行符问题

**测试用例的输入输出必须包含换行符！**

#### ✅ 正确示例：

```python
input_data = "1 2\n"      # ✓ 有换行符
output_data = "3\n"       # ✓ 有换行符
```

#### ❌ 错误示例：

```python
input_data = "1 2"        # ✗ 缺少换行符
output_data = "3"         # ✗ 缺少换行符
```

**为什么？**
- Python的`input()`函数会去掉换行符
- C++的`cin`也会处理换行
- 但文件重定向时需要换行符作为结束标志

### 2. 多行输入

如果测试用例有多行输入：

```
输入数据:
3
1 2 3
(实际存储: "3\n1 2 3\n")
```

在文本框中输入时：
1. 输入第一行：`3`
2. 按回车
3. 输入第二行：`1 2 3`
4. 按回车（或者手动在末尾加\n）

### 3. 时间和内存限制

- **留空**: 使用题目的默认限制
- **填写**: 针对此测试用例的特殊限制

例如：
- 题目默认时间限制：1000ms
- 某个大数据测试用例：设置2000ms

---

## 🔧 技术细节

### 代码改进

#### 1. TestCaseInline（题目页面内联）

```python
class TestCaseInline(admin.StackedInline):
    model = TestCase
    extra = 1  # 默认显示1个空白表单
    fields = [
        'order',
        'input_data',      # ✨ 新增
        'output_data',     # ✨ 新增
        'is_sample',
        'score',
        'time_limit',
        'memory_limit'
    ]
    
    def get_formset(self, request, obj=None, **kwargs):
        """自定义textarea样式"""
        formset = super().get_formset(request, obj, **kwargs)
        # 设置等宽字体、合适行高
        formset.form.base_fields['input_data'].widget.attrs.update({
            'rows': 6,
            'cols': 80,
            'style': 'font-family: monospace; width: 100%;'
        })
        formset.form.base_fields['output_data'].widget.attrs.update({
            'rows': 6,
            'cols': 80,
            'style': 'font-family: monospace; width: 100%;'
        })
        return formset
```

#### 2. TestCaseAdmin（独立管理页面）

```python
@admin.register(TestCase)
class TestCaseAdmin(admin.ModelAdmin):
    list_display = [
        'problem',
        'order',
        'input_preview',    # ✨ 新增预览
        'output_preview',   # ✨ 新增预览
        'is_sample',
        'score',
        'time_limit_display',
        'memory_limit_display'
    ]
    
    fieldsets = (            # ✨ 新增分组
        ('基本信息', {...}),
        ('测试数据', {...}),
        ('资源限制', {...}),
    )
    
    def input_preview(self, obj):
        """显示输入预览，换行符显示为↵"""
        preview = obj.input_data[:30].replace('\n', '↵')
        return format_html('<code>...</code>', preview)
```

---

## 📊 对比总结

| 功能 | 改进前 | 改进后 |
|------|--------|--------|
| **输入数据字段** | ❌ 不显示 | ✅ 完整显示 |
| **输出数据字段** | ❌ 不显示 | ✅ 完整显示 |
| **布局方式** | TabularInline | StackedInline |
| **文本框样式** | 默认 | 等宽字体，多行 |
| **列表预览** | ❌ 无 | ✅ 显示输入输出预览 |
| **字段分组** | ❌ 无 | ✅ 3个分组 |
| **换行符提示** | ❌ 无 | ✅ 醒目提示 |
| **默认值提示** | ❌ 无 | ✅ 区分默认/自定义 |

---

## 🚀 下一步

### 在Linux服务器上更新

```bash
# 1. 拉取最新代码
cd /path/to/OJ_system
git pull origin main

# 2. 重启Django服务
# 如果使用runserver:
# Ctrl+C 停止，然后重新运行
python3 manage.py runserver 0.0.0.0:8000

# 如果使用Docker Compose:
docker-compose restart web
```

### 验证改进

1. **访问题目管理页面**:
   ```
   http://your-server-ip:8000/admin/problems/problem/1/change/
   ```

2. **检查测试用例区域**:
   - ✅ 应该看到"输入数据"和"输出数据"文本框
   - ✅ 文本框使用等宽字体
   - ✅ 可以直接编辑测试数据

3. **访问测试用例列表**:
   ```
   http://your-server-ip:8000/admin/problems/testcase/
   ```

4. **检查列表显示**:
   - ✅ 应该看到输入输出预览列
   - ✅ 换行符显示为 `↵` 符号

---

## 📚 相关文档

- `JUDGE-DATA-GUIDE.md` - 判题数据配置指南
- `fix_test_data.py` - 自动创建测试数据脚本
- `apps/problems/models.py` - 数据模型定义
- `apps/problems/admin.py` - Admin配置（本次修改）

---

**文档版本**: v1.0  
**更新日期**: 2024-10-02  
**修改提交**: c3482e4

