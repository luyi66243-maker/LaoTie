# 添加工具模块到项目的步骤

由于直接修改project.pbxproj文件容易出错，我们采用通过Xcode界面添加文件的方法。

## 步骤1：打开Xcode项目

1. 双击 `LaoTie.xcodeproj` 文件打开项目

## 步骤2：添加模型文件到项目

1. 在左侧项目导航器中，右键点击 `Models` 文件夹
2. 选择 `Add Files to "LaoTie"...`
3. 导航到 `LaoTie/Models` 文件夹
4. 选择以下两个文件：
   - `ConfusingWord.swift`
   - `SubtextGuide.swift`
5. 确保勾选 `Copy items if needed` 和 `Add to targets: LaoTie`
6. 点击 `Add`

## 步骤3：添加工具视图文件到项目

1. 在左侧项目导航器中，右键点击 `Features` 文件夹
2. 选择 `New Group`，命名为 `Tools`
3. 右键点击新创建的 `Tools` 文件夹
4. 选择 `Add Files to "LaoTie"...`
5. 导航到 `LaoTie/Features/Tools` 文件夹
6. 选择以下三个文件：
   - `ToolsHubView.swift`
   - `ConfusingWordsView.swift`
   - `SubtextGuideView.swift`
7. 确保勾选 `Copy items if needed` 和 `Add to targets: LaoTie`
8. 点击 `Add`

## 步骤4：修复颜色定义

1. 在左侧项目导航器中，找到 `Core/Design/DongbeiColors.swift` 文件
2. 双击打开该文件
3. 在颜色定义中添加 `qianlan` 颜色：

```swift
static let binglan = Color(hex: 0xA8DADC)
static let qianlan = Color(hex: 0x83C5BE) // 添加这一行
static let snowWhite = Color(hex: 0xF1FAEE)
```

## 步骤5：运行应用

1. 在Xcode顶部工具栏，选择一个可用的模拟器（如 iPhone 15）
2. 点击左上角的播放按钮（▶️）或按 `Cmd + R`
3. 等待应用编译并在模拟器中启动
4. 在底部标签栏中找到并点击"工具"标签，查看工具功能

## 已完成的功能

1. **工具中心**：分类展示各种实用工具，包括应急工具、文化指南和实用工具
2. **易混淆词**：展示南北用词差异和禁忌词，提供发音对比和使用说明
3. **潜台词指南**：解析东北话中的"话外音"，提供正确回应方式和使用场景

所有代码已经准备就绪，按照上述步骤操作即可完成添加！