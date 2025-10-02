#!/bin/bash

# 修复判题系统测试数据
# 解决问题：
# 1. 题目缺少公开样例（前端无法显示）
# 2. 确保测试用例正确创建

echo "======================================"
echo "  修复判题系统测试数据"
echo "======================================"
echo ""

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 执行修复脚本
echo -e "${YELLOW}正在修复测试数据...${NC}"
python3 fix_test_data.py

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ 测试数据修复完成！${NC}"
    echo ""
    echo "验证步骤："
    echo "1. 访问 Django Admin:"
    echo "   http://your-server-ip:8000/admin/problems/problem/1/change/"
    echo ""
    echo "2. 检查题目详情："
    echo "   - 公开样例应该有2个"
    echo "   - 测试用例应该有5个"
    echo ""
    echo "3. 前端查看题目："
    echo "   http://your-server-ip:8000/problems/1/"
    echo "   应该能看到样例输入输出"
    echo ""
    echo "4. 提交测试："
    echo "   http://your-server-ip:8000/problems/1/submit/"
    echo "   提交代码: a, b = map(int, input().split()); print(a + b)"
    echo ""
else
    echo ""
    echo -e "${YELLOW}修复失败，请检查错误信息${NC}"
    exit 1
fi

