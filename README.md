# LaoTie（唠嗑小馆）

东北方言学习与文旅打卡应用，包含词汇学习、情景对话、闯关测验、错题复习和风景打卡等核心功能。项目同时包含 iOS 与 Android 代码（Android 端为独立目录）。

## 项目亮点

- **学习闭环**：每日任务卡 + 错题自动入库 + 1/3/7 天间隔复习
- **实用场景**：情景对话、方言翻译、常用表达工具模块
- **文旅融合**：东北三省景点地图与打卡体系
- **可信打卡**：定位与图片元信息参与真实性评估
- **可观测音频链路**：TTS 预检、失败原因诊断、缓存命中指标

## 技术栈

- iOS: Swift, SwiftUI, AVFoundation, CoreLocation, ImageIO
- Android: Kotlin, Gradle（位于 `LaoTieAndroid`）
- 数据与资源: JSON Seed Data, 本地持久化（UserDefaults / 本地文件）
- 工程工具: Xcode, xcodebuild, Python scripts

## 目录结构

- `LaoTie/`：iOS 主工程代码
- `LaoTie.xcodeproj/`：iOS 工程文件
- `LaoTieAndroid/`：Android 工程
- `docs/`：产品、验收、素材校验与发布流程文档
- `scripts/`：校验与自动化脚本
- `AppStoreSubmission/`：上架相关材料（已忽略 `.ipa` 产物）

## 本地运行（iOS）

1. 使用 Xcode 打开 `LaoTie.xcodeproj`
2. 选择 Scheme: `LaoTie`
3. 选择模拟器后直接运行

命令行构建示例：

```bash
xcodebuild -project LaoTie.xcodeproj -scheme LaoTie -destination 'generic/platform=iOS Simulator' -derivedDataPath ./build/LocalBuild build
```

## 本地运行（Android）

Android 项目位于 `LaoTieAndroid/`，可使用 Android Studio 打开并运行。

## 当前仓库地址

- GitHub: [https://github.com/luyi66243-maker/LaoTie](https://github.com/luyi66243-maker/LaoTie)

## 说明

- 本仓库用于项目展示与迭代维护。
- 若你是招聘方，欢迎直接查看 `docs/` 下的功能迭代与验收文档了解完整实现过程。
