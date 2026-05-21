# Android 提审前自检报告（2026-04-26）

## 一、构建与产物

- 结果：通过
- 命令：
  - `:app:assembleCnRelease`
  - `:app:bundleGpRelease`
- 产物：
  - `AndroidPackages/Huawei/app-release.apk`（同一 APK 已复制到 Xiaomi/OPPO/vivo/Tencent）
  - `AndroidPackages/GooglePlay/app-release.aab`

## 二、产物完整性

- APK 大小：`36400127 bytes`
- AAB 大小：`38683336 bytes`
- SHA256：
  - APK：`181a912d7961ac550cd570cd101d4798300bae98b0e14648787bf5f10d4d0d5b`
  - AAB：`6bfe5b000ad3fd7af4a5beddda764cb1c32b71974d866b57b49c5bb2f431a965`

## 三、签名检查

- APK 签名验证：通过（`apksigner verify --print-certs`）
- 证书 DN：`CN=LaoTie, OU=Dev, O=LaoTie, L=Shenyang, ST=Liaoning, C=CN`
- 证书 SHA-256：`66840af0df4701ba5680141870563c7db7984adf8fdf373dcd308ec2ada6de64`
- AAB 验证：`jarsigner -verify` 可读取签名信息；因使用本地自签名证书，链路校验提示 `Invalid certificate chain` 属预期

## 四、资料分发

- 目录：`AppStoreSubmission/AndroidPackages/`
- 已生成商店目录：
  - `Huawei`
  - `Xiaomi`
  - `OPPO`
  - `vivo`
  - `Tencent`
  - `GooglePlay`
- 每个目录已生成：
  - `metadata.txt`
  - `privacy_policy_url.txt`
  - `terms_url.txt`
  - `checklist.txt`
  - `screenshots/`

## 五、隐私与权限文案核验

- `docs/privacy.html` 已包含：
  - 按需权限申请（录音/定位/相机）
  - Android 端 SDK 披露（高德、讯飞、崩溃分析）
  - 不同功能触发权限的说明

## 六、阻塞项（需你补齐后才能正式提审）

- 各商店 `screenshots/` 当前数量为 0（需至少 5 张）
- `software_copyright.pdf` 尚未放入各商店目录
- `app_filing_record.pdf` 尚未放入各商店目录
- 当前为本地自签名证书，仅用于本地出包验证；正式上架需替换为你最终发行 keystore
