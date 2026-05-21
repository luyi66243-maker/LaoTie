#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/AndroidPackages"

mkdir -p "$BASE_DIR/Huawei/screenshots"
mkdir -p "$BASE_DIR/Xiaomi/screenshots"
mkdir -p "$BASE_DIR/OPPO/screenshots"
mkdir -p "$BASE_DIR/vivo/screenshots"
mkdir -p "$BASE_DIR/Tencent/screenshots"
mkdir -p "$BASE_DIR/GooglePlay/screenshots"

echo "已创建安卓商店提审目录：$BASE_DIR"
