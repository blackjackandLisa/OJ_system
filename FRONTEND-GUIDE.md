# 前端页面使用指南

## 🎨 已创建的页面

### 1. 题目列表页面
**路径**: `/problems/`  
**文件**: `templates/problems/problem_list.html`

**功能特性：**
- ✅ 题目列表展示（表格形式）
- ✅ 搜索功能（按标题搜索）
- ✅ 多维度筛选（难度、标签、状态）
- ✅ 状态图标（已通过/尝试中/未尝试）
- ✅ 通过率可视化（进度条）
- ✅ 分页功能
- ✅ 统计信息展示
- ✅ 响应式设计

**访问地址：**
```
http://your-server-ip:8000/problems/
```

### 2. 题目详情页面
**路径**: `/problems/<id>/`  
**文件**: `templates/problems/problem_detail.html`

**功能特性：**
- ✅ 题目完整描述（支持Markdown）
- ✅ 输入输出格式说明
- ✅ 样例展示（输入/输出/说明）
- ✅ 题目提示
- ✅ 题目信息侧边栏（时间/内存限制）
- ✅ 统计信息（提交数、通过率）
- ✅ 个人统计（提交次数、通过状态）
- ✅ 标签页导航（描述/提交记录/讨论）

**访问地址：**
```
http://your-server-ip:8000/problems/1/
```

### 3. 代码提交页面
**路径**: `/problems/<id>/submit/`  
**文件**: `templates/problems/problem_submit.html`

**功能特性：**
- ✅ CodeMirror代码编辑器
- ✅ 多语言支持（C++/C/Java/Python/JavaScript）
- ✅ 语法高亮
- ✅ 代码自动完成
- ✅ 代码模板
- ✅ 本地保存（LocalStorage）
- ✅ 快捷键支持（Ctrl+S保存、Ctrl+Enter提交）
- ✅ 题目信息侧边栏
- ✅ 提交和测试按钮

**访问地址：**
```
http://your-server-ip:8000/problems/1/submit/
```

## 🎯 页面功能详解

### 题目列表页面功能

#### 1. 搜索和筛选
```javascript
// 支持的筛选选项：
- 搜索框：按题目标题搜索
- 难度：简单/中等/困难
- 标签：数组、哈希表、动态规划等
- 状态：已通过/尝试中/未尝试
```

#### 2. 状态图标
```
✓ 绿色对勾 = 已通过
! 黄色感叹号 = 尝试中但未通过
○ 灰色圆圈 = 未尝试
```

#### 3. 通过率展示
```
绿色进度条 = 通过率 >= 50%
黄色进度条 = 通过率 30%-49%
红色进度条 = 通过率 < 30%
```

### 题目详情页面功能

#### 1. 标签页导航
- **题目描述**：完整的题目内容
- **提交记录**：个人提交历史（待实现）
- **讨论**：题目讨论区（待实现）

#### 2. 样例展示
- 清晰的输入输出展示
- 样例说明
- 代码块样式

#### 3. 侧边栏信息
- 题目限制（时间/内存）
- 统计信息（提交数、通过率）
- 个人统计（如果已登录）

### 代码提交页面功能

#### 1. 代码编辑器
- **CodeMirror编辑器**：专业的代码编辑体验
- **主题**：Monokai暗色主题
- **功能**：语法高亮、括号匹配、自动缩进

#### 2. 多语言支持
```
C++：text/x-c++src
C：text/x-csrc
Java：text/x-java
Python：text/x-python
JavaScript：text/javascript
```

#### 3. 代码模板
每种语言都有预设的代码模板，包含：
- 基本的输入输出框架
- 注释说明

#### 4. 本地存储
- 代码自动保存到浏览器LocalStorage
- 切换语言时询问是否加载模板
- 刷新页面时询问是否加载上次的代码

#### 5. 快捷键
```
Ctrl+S：保存代码到本地
Ctrl+Enter：提交代码
Tab：缩进
Ctrl+/：注释（CodeMirror自带）
```

## 🔌 API集成

### 题目列表API
```javascript
// 获取题目列表
GET /problems/api/problems/

// 参数：
?page=1                    // 页码
&search=关键词              // 搜索
&difficulty=easy           // 难度筛选
&tags=1,2                  // 标签筛选
&user_status=accepted      // 状态筛选
```

### 题目详情API
```javascript
// 获取题目详情
GET /problems/api/problems/1/
```

### 标签API
```javascript
// 获取所有标签
GET /problems/api/tags/
```

## 🎨 样式特性

### Bootstrap组件使用
- ✅ Card卡片
- ✅ Table表格
- ✅ Badge徽章
- ✅ Progress进度条
- ✅ Button按钮
- ✅ Form表单
- ✅ Navbar导航栏
- ✅ Tab标签页

### 自定义样式
- 悬停动画效果
- 渐变色背景
- 圆角卡片
- 阴影效果
- 响应式布局

## 📱 响应式设计

所有页面都支持多种设备：
- **桌面**：完整功能展示
- **平板**：自适应布局
- **手机**：移动端优化

## 🚀 访问和测试

### 1. 首页
```
http://your-server-ip:8000/
```

### 2. 题目列表
```
http://your-server-ip:8000/problems/
```

### 3. 题目详情
```
http://your-server-ip:8000/problems/1/
```

### 4. 代码提交
```
http://your-server-ip:8000/problems/1/submit/
```

### 5. 管理后台
```
http://your-server-ip:8000/admin/problems/problem/
```

## 🔧 开发调试

### 查看API数据
```bash
# 题目列表API
curl http://localhost:8000/problems/api/problems/

# 题目详情API
curl http://localhost:8000/problems/api/problems/1/

# 标签API
curl http://localhost:8000/problems/api/tags/
```

### 浏览器调试
1. 打开浏览器开发者工具（F12）
2. 查看Network标签，监控API请求
3. 查看Console标签，查看JavaScript错误

## 🎯 待实现的功能

当前前端已实现基础功能，以下功能需要后续开发：

### 1. 提交记录
- 显示用户的提交历史
- 提交状态（AC/WA/TLE等）
- 提交时间
- 查看提交代码

### 2. 实际判题
- 代码提交到后端
- 运行测试用例
- 显示判题结果
- 错误信息展示

### 3. 讨论功能
- 题解分享
- 评论系统
- 点赞功能

### 4. 用户系统
- 用户登录/注册
- 个人主页
- 做题统计

## 💡 使用技巧

### 1. 快速导航
- 首页 → 点击"开始刷题"按钮
- 题目列表 → 点击题目标题查看详情
- 题目详情 → 点击"提交代码"进入编辑器

### 2. 代码编辑
- 选择编程语言会自动加载模板
- Ctrl+S随时保存代码
- 切换语言前会提示是否保存

### 3. 筛选题目
- 使用难度筛选找到适合的题目
- 使用标签筛选特定类型的题目
- 使用状态筛选查看进度

## 📄 文件清单

```
templates/
├── base.html                      # 基础模板（已更新导航）
├── core/
│   └── home.html                  # 首页（已更新）
└── problems/
    ├── problem_list.html          # 题目列表 ✨
    ├── problem_detail.html        # 题目详情 ✨
    └── problem_submit.html        # 代码提交 ✨
```

## 🔗 依赖的CDN资源

- Bootstrap 5.3.0
- Font Awesome（图标）
- CodeMirror 5.65.2（代码编辑器）
- Marked.js（Markdown渲染）

所有CDN资源都使用了国内加速节点，加载速度快。

---

**前端页面已全部创建完成！现在可以访问 http://your-server-ip:8000/problems/ 查看效果！** 🎉
