# 快速更新模拟器中的应用

## 方法一：使用 Xcode（最简单）

既然 Xcode 已经打开了，你只需要：

1. 在 Xcode 顶部工具栏确认选择了正确的模拟器（如 iPhone 16）
2. 按 `Cmd + Shift + K` 清理构建
3. 按 `Cmd + R` 重新构建并运行

这样就会将最新版本的应用安装到模拟器中了！

## 方法二：使用 Xcode 菜单

1. **清理旧构建**
   - Product > Clean Build Folder (Cmd + Shift + K)

2. **重新构建并运行**
   - Product > Run (Cmd + R)

## 方法三：命令行快速更新

打开终端，运行：

```bash
cd /Users/yi/Qoder/LaoTie

# 停止应用
xcrun simctl terminate booted com.laotie.LaoTie 2>/dev/null || true

# 清理并重新构建
xcodebuild \
    -project LaoTie.xcodeproj \
    -scheme LaoTie \
    -destination 'platform=iOS Simulator,name=iPhone 16' \
    -sdk iphonesimulator \
    clean build

# 安装并运行
# (你需要手动在 Xcode 中点击 Run，或者找到构建好的 .app 文件安装)
```

## 提示

- 如果不确定当前运行的模拟器是什么，可以在 Xcode 顶部工具栏查看
- 清理构建是一个好习惯，可以确保使用最新的代码
