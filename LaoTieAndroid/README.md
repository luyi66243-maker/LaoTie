# LaoTieAndroid

原生 Kotlin + Jetpack Compose Android 工程。

## 已完成内容

- Compose + Hilt + Navigation + DataStore + Room 工程骨架
- `cn/gp` 双 flavor 配置
- 词汇/对话/闯关/口语/打卡/AI 聊天页面骨架
- 打卡、成就、连续天数基础逻辑
- 上架与隐私合规模板文档

## 资源同步

iOS 的资源位于：

- `../LaoTie/Resources/SeedData`
- `../LaoTie/Resources/Audio`

建议执行脚本将资源同步到 Android：

```bash
./scripts/sync_ios_resources.sh
```

脚本会同步到：

- `app/src/main/assets/seed`
- `app/src/main/assets/audio`

## 构建

```bash
./gradlew :app:assembleCnDebug
```
