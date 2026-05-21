#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

VERIFY_ARGS=(--gate-release)
if [[ "${1:-}" == "--allow-pending" ]]; then
  VERIFY_ARGS+=(--allow-pending)
fi

echo "== Day14 Release Check =="
echo "[1/3] 风景图严格门禁检查"
python3 scripts/verify_scenic_images.py "${VERIFY_ARGS[@]}"

echo "[2/3] iOS 通用设备构建检查"
xcodebuild \
  -project "LaoTie.xcodeproj" \
  -scheme "LaoTie" \
  -destination "generic/platform=iOS" \
  -derivedDataPath "./build/Day14ReleaseCheck" \
  build >/tmp/laotie_day14_build.log

echo "[3/3] 输出关键产物路径"
echo "- 报告: docs/scenic-image-verification-latest.md"
echo "- 台账: docs/scenic-image-mapping-template.csv"
echo "- 构建日志: /tmp/laotie_day14_build.log"
echo ""
echo "PASS: Day14 自动检查通过，可继续执行手工验收清单。"
