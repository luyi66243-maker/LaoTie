# Android 发布指南

## 1. 签名文件

在 `LaoTieAndroid/keystore.properties` 中配置：

```properties
storeFile=/absolute/path/to/laotie-release.jks
storePassword=******
keyAlias=laotie
keyPassword=******
```

`keystore.properties` 已被 `.gitignore` 忽略，不会进入仓库。

## 2. 同步 iOS 资源

```bash
cd LaoTieAndroid
./scripts/sync_ios_resources.sh
```

## 3. 构建渠道包

```bash
./gradlew :app:assembleCnRelease
./gradlew :app:bundleGpRelease
```

## 4. 提审前自测

- 首次启动隐私弹窗流程可通过
- 拒绝权限后页面不崩溃
- 词汇/对话/闯关数据正常读取
- 口语评测可返回评分
- 打卡可写入本地记录并刷新成就
