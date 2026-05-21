#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IOS_RES_DIR="$ROOT_DIR/../LaoTie/Resources"
ASSETS_DIR="$ROOT_DIR/app/src/main/assets"

mkdir -p "$ASSETS_DIR/seed"
mkdir -p "$ASSETS_DIR/audio"

if [[ -d "$IOS_RES_DIR/SeedData" ]]; then
  cp -R "$IOS_RES_DIR/SeedData"/. "$ASSETS_DIR/seed/"
  echo "SeedData 同步完成 -> app/src/main/assets/seed"
else
  echo "未找到 SeedData: $IOS_RES_DIR/SeedData"
fi

if [[ -d "$IOS_RES_DIR/Audio" ]]; then
  cp -R "$IOS_RES_DIR/Audio"/. "$ASSETS_DIR/audio/"
  echo "Audio 同步完成 -> app/src/main/assets/audio"
else
  echo "未找到 Audio: $IOS_RES_DIR/Audio"
fi

echo "资源同步完成。"
