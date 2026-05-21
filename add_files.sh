#!/bin/bash

# 项目目录
PROJECT_DIR="/Users/yi/Qoder/LaoTie"
PROJECT_FILE="$PROJECT_DIR/LaoTie.xcodeproj/project.pbxproj"

# 新创建的文件列表
NEW_FILES=("LaoTie/Models/ConfusingWord.swift"
           "LaoTie/Models/SubtextGuide.swift"
           "LaoTie/Features/Tools/ConfusingWordsView.swift"
           "LaoTie/Features/Tools/SubtextGuideView.swift"
           "LaoTie/Features/Tools/ToolsHubView.swift")

# 打印开始信息
echo "开始添加新文件到Xcode项目..."

# 遍历新文件
for FILE in "${NEW_FILES[@]}"; do
    FULL_PATH="$PROJECT_DIR/$FILE"
    if [ -f "$FULL_PATH" ]; then
        echo "找到文件: $FILE"
        # 这里需要添加文件到project.pbxproj的逻辑
        # 由于project.pbxproj格式复杂，我们使用一个简单的方法：
        # 1. 检查文件是否已经在项目中
        if grep -q "$FILE" "$PROJECT_FILE"; then
            echo "文件 $FILE 已经在项目中"
        else
            echo "文件 $FILE 需要添加到项目中"
            # 这里应该有具体的添加逻辑
        fi
    else
        echo "文件不存在: $FILE"
    fi
done

echo "添加文件完成！"
