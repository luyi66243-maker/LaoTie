#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/AndroidPackages"
PRIVACY_URL="https://laotie.app/privacy.html"
TERMS_URL="https://laotie.app/terms.html"

read -r -d '' META_CN <<'EOF' || true
应用名称：唠嗑小馆
一句话简介：东北方言学习助手
主分类：教育
副分类：参考
版权：© 2026 卢易

应用简介：
唠嗑小馆是一款聚焦东北方言的学习应用，覆盖词汇、场景对话、口语练习和风景打卡。
你可以从日常高频东北话入门，结合双语音频与互动练习，快速掌握地道表达方式。

核心功能：
1) 场景对话学习（真实生活场景）
2) 词汇速查（东北话与普通话对照）
3) 口语练习（录音评测）
4) 风景打卡（定位激励）
5) 闯关测试（巩固记忆）

关键词：东北话, 方言学习, 口语练习, 东北方言, 普通话对照, 方言词典

更新说明（1.0.0）：
- 上线词汇、对话、闯关、风景打卡等核心能力
- 新增发音评测与学习进度记录
- 优化音频播放和稳定性
EOF

read -r -d '' META_GP <<'EOF' || true
App Name: LaoTie
Subtitle: Northeastern Chinese Dialect Learning
Primary Category: Education
Secondary Category: Reference
Copyright: © 2026 Lu Yi

Description:
LaoTie is a learning app for Northeastern Chinese dialects.
It includes vocabulary, dialogues, speaking practice, and location check-ins.

Key Features:
1) Scenario-based dialogues
2) Vocabulary lookup with examples
3) Speaking practice with scoring
4) Scenic check-in learning tasks
5) Quiz levels for retention

Keywords: chinese dialect, northeastern chinese, speaking practice, vocabulary, learning app

What's New (1.0.0):
- Initial release with core learning features
- Added speech scoring and progress tracking
- Improved audio playback reliability
EOF

for store in Huawei Xiaomi OPPO vivo Tencent; do
  dir="$BASE_DIR/$store"
  mkdir -p "$dir"
  printf "%s\n" "$META_CN" > "$dir/metadata.txt"
  printf "%s\n" "$PRIVACY_URL" > "$dir/privacy_policy_url.txt"
  printf "%s\n" "$TERMS_URL" > "$dir/terms_url.txt"
  cat > "$dir/checklist.txt" <<EOF
[$store 提审前检查]
- app-release.apk 已放置
- metadata.txt 已填写
- privacy_policy_url.txt 已填写
- terms_url.txt 已填写
- screenshots/ 需补充 5 张 1080x1920
- software_copyright.pdf 需补充
- app_filing_record.pdf 需补充
EOF
done

GP_DIR="$BASE_DIR/GooglePlay"
mkdir -p "$GP_DIR"
printf "%s\n" "$META_GP" > "$GP_DIR/metadata.txt"
printf "%s\n" "$PRIVACY_URL" > "$GP_DIR/privacy_policy_url.txt"
printf "%s\n" "$TERMS_URL" > "$GP_DIR/terms_url.txt"
cat > "$GP_DIR/checklist.txt" <<'EOF'
[Google Play 提审前检查]
- app-release.aab 已放置
- metadata.txt 已填写
- privacy_policy_url.txt 已填写
- terms_url.txt 已填写
- screenshots/ 需补充（手机尺寸）
- Data Safety 表单需填写
- 内容分级与政策问卷需填写
EOF

echo "各商店元数据与链接文件已生成。"
