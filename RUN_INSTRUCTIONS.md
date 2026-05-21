# 唠嗑小馆 (LaoTie) 项目运行指南

## 方法一：使用 Xcode 图形界面（推荐）

1. 打开项目
   ```
   open /Users/yi/Qoder/LaoTie/LaoTie.xcodeproj
   ```

2. 在 Xcode 顶部工具栏选择模拟器（如 iPhone 16）

3. 点击左上角的 ▶ 按钮（或按 Cmd + R）构建并运行

## 方法二：使用命令行

### 快速构建命令

在终端中执行：

```bash
cd /Users/yi/Qoder/LaoTie

# 查看可用模拟器
xcrun simctl list devices available

# 使用特定模拟器构建并运行（替换 SIMULATOR_UDID）
xcodebuild \
    -project LaoTie.xcodeproj \
    -scheme LaoTie \
    -destination 'platform=iOS Simulator,name=iPhone 16' \
    -sdk iphonesimulator \
    clean build
```

### 使用提供的脚本

```bash
cd /Users/yi/Qoder/LaoTie
chmod +x build_and_run.sh

# 列出可用模拟器
./build_and_run.sh --list

# 构建并运行
./build_and_run.sh
```

## 项目信息

- **项目名称**: 唠嗑小馆 (LaoTie)
- **开发语言**: Swift
- **UI 框架**: SwiftUI
- **最低 iOS 版本**: iOS 16.0
- **Swift 版本**: Swift 6.0

## 主要功能

1. 东北话学习
2. 词汇练习
3. 对话练习
4. 打卡签到
5. 测验系统

## 常见问题

### 找不到模拟器
如果命令行找不到模拟器，请：
1. 打开 Xcode
2. 进入 Xcode > Settings > Platforms
3. 确认已安装 iOS 模拟器

### 构建失败
- 确保使用正确的 Xcode 版本（建议 16.0 或更高）
- 检查项目配置是否正确

## 项目结构

```
LaoTie/
├── App/                    # 应用入口和主视图
├── Configuration/          # 配置文件（Info.plist 等）
├── Core/                   # 核心功能模块
├── Features/               # 功能模块
├── Models/                 # 数据模型
├── Repositories/           # 数据访问层
└── Resources/              # 资源文件
```

更多详细信息请查看项目中的 `.qoder/repowiki/` 文档。
