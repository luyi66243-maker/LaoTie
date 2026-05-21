#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

PY_SCRIPT="scripts/adjust_sprint_roster_for_absence.py"

ENABLE_TIMESTAMP=1
ENABLE_LATEST=1
DRY_RUN=0
VALIDATE_ONLY=0

ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --batch|--day|--absent|--standby|--input|--output|--latest-path|--summary-path)
      if [[ $# -lt 2 ]]; then
        echo "参数缺失：$1 需要一个值" >&2
        exit 1
      fi
      ARGS+=("$1" "$2")
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      ARGS+=("$1")
      shift
      ;;
    --validate-only)
      VALIDATE_ONLY=1
      ARGS+=("$1")
      shift
      ;;
    --summary-md)
      ARGS+=("$1")
      shift
      ;;
    --summary-history)
      ARGS+=("$1")
      shift
      ;;
    --lock-latest-on-write)
      ARGS+=("$1")
      shift
      ;;
    --fail-on-double-role)
      ARGS+=("$1")
      shift
      ;;
    --no-timestamp)
      ENABLE_TIMESTAMP=0
      shift
      ;;
    --no-latest-link)
      ENABLE_LATEST=0
      shift
      ;;
    -h|--help)
      cat <<'EOF'
用法：
  bash scripts/update_roster_from_absence.sh --batch "D05:B,C:E,F;D06:A:G"
  bash scripts/update_roster_from_absence.sh --day D05 --absent B,C --standby E,F

说明：
  - 默认开启：--timestamp-output + --latest-link
  - 预览模式：--dry-run（不写文件）
  - 说明文档：--summary-md（生成调整说明 markdown）
  - 说明归档：--summary-history（说明文档追加时间戳归档）
  - 锁定 latest：--lock-latest-on-write（仅 write 更新 latest 说明）
  - 严格防兼岗：--fail-on-double-role（出现兼岗直接失败）
  - 关闭时间戳：--no-timestamp
  - 关闭 latest 副本：--no-latest-link
EOF
      exit 0
      ;;
    *)
      echo "未知参数：$1" >&2
      exit 1
      ;;
  esac
done

CMD=(python3 "$PY_SCRIPT")
CMD+=("${ARGS[@]}")

if [[ $DRY_RUN -eq 0 ]]; then
  if [[ $VALIDATE_ONLY -eq 0 ]]; then
    if [[ $ENABLE_TIMESTAMP -eq 1 ]]; then
      CMD+=("--timestamp-output")
    fi
    if [[ $ENABLE_LATEST -eq 1 ]]; then
      CMD+=("--latest-link")
    fi
  fi
fi

echo "[run] ${CMD[*]}"
"${CMD[@]}"
