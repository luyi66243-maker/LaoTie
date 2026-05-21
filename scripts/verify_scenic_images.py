#!/usr/bin/env python3
"""
校验东北三省风光图片资源与景点数据匹配情况，并输出可填报台账。

用法：
  python3 scripts/verify_scenic_images.py
"""

from __future__ import annotations

import argparse
import csv
import json
import sys
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCENICS_JSON = ROOT / "LaoTie/Resources/SeedData/scenics.json"
SCENIC_ASSETS_DIR = ROOT / "LaoTie/Resources/Assets.xcassets/Scenics"
OUTPUT_CSV = ROOT / "docs/scenic-image-mapping-template.csv"
OUTPUT_MD = ROOT / "docs/scenic-image-verification-latest.md"


def load_scenics() -> list[dict]:
    with SCENICS_JSON.open("r", encoding="utf-8") as f:
        return json.load(f)


def existing_asset_names() -> set[str]:
    names: set[str] = set()
    for imageset in SCENIC_ASSETS_DIR.glob("*.imageset"):
        names.add(imageset.stem)
    return names


def compute_rows(scenics: list[dict], assets: set[str]) -> list[dict]:
    rows = []
    for s in scenics:
        scenic_id = s["id"]
        target_asset = f"scenic_{scenic_id}"
        fallback_asset = s.get("imageName") or ""
        status = s.get("imageMatchType", "pending")

        has_unique_asset = target_asset in assets
        has_fallback_asset = fallback_asset in assets if fallback_asset else False
        resolved_asset = target_asset if has_unique_asset else (fallback_asset if has_fallback_asset else "")

        if has_unique_asset and status != "exact":
            action = "建议改为 exact"
        elif status == "exact" and not has_unique_asset and has_fallback_asset:
            action = "已核验（共用图），建议补唯一图"
        elif status == "exact" and not resolved_asset:
            action = "状态异常：exact 但无可用图"
        elif status == "pending":
            action = "待补唯一实拍图"
        elif status == "representative":
            action = "示意图可用，待替换实拍"
        else:
            action = "已通过"

        rows.append(
            {
                "id": scenic_id,
                "name": s["name"],
                "province": s["province"],
                "city": s["city"],
                "status": status,
                "targetAsset": target_asset,
                "fallbackAsset": fallback_asset,
                "resolvedAsset": resolved_asset,
                "hasUniqueAsset": "yes" if has_unique_asset else "no",
                "action": action,
                "imageSource": "",
                "copyrightOwner": "",
                "licenseProof": "",
                "notes": "",
            }
        )
    return rows


def write_csv(rows: list[dict]) -> None:
    OUTPUT_CSV.parent.mkdir(parents=True, exist_ok=True)
    fields = [
        "id",
        "name",
        "province",
        "city",
        "status",
        "targetAsset",
        "fallbackAsset",
        "resolvedAsset",
        "hasUniqueAsset",
        "action",
        "imageSource",
        "copyrightOwner",
        "licenseProof",
        "notes",
    ]
    with OUTPUT_CSV.open("w", encoding="utf-8-sig", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)


def collect_gate_issues(rows: list[dict]) -> list[str]:
    pending_rows = [r for r in rows if r["status"] == "pending"]
    exact_missing_rows = [
        r for r in rows if r["status"] == "exact" and r["hasUniqueAsset"] == "no"
    ]
    status_conflict_rows = [r for r in rows if "异常" in r["action"]]

    issues: list[str] = []
    if pending_rows:
        issues.append(f"pending 状态未清零：{len(pending_rows)}")
    if exact_missing_rows:
        issues.append(f"exact 缺唯一图：{len(exact_missing_rows)}")
    if status_conflict_rows:
        issues.append(f"状态异常项：{len(status_conflict_rows)}")
    return issues


def write_markdown(
    rows: list[dict],
    strict_gate_issues: list[str],
    effective_gate_issues: list[str],
    allow_pending: bool,
) -> None:
    status_counter = Counter(r["status"] for r in rows)
    unique_count = sum(1 for r in rows if r["hasUniqueAsset"] == "yes")
    risk_rows = [r for r in rows if "异常" in r["action"]]
    pending_rows = [r for r in rows if r["status"] == "pending"]

    lines = [
        "# 东北三省风光图片校验（自动生成）",
        "",
        "## 总览",
        "",
        f"- 景点总数：{len(rows)}",
        f"- `exact`：{status_counter.get('exact', 0)}",
        f"- `representative`：{status_counter.get('representative', 0)}",
        f"- `pending`：{status_counter.get('pending', 0)}",
        f"- 已存在唯一资源 `scenic_<id>`：{unique_count}",
        "",
        "## 风险项",
        "",
    ]

    lines += [
        "## 发布门禁",
        "",
    ]
    if strict_gate_issues:
        lines.append("- 严格门禁：`阻断发布`")
        for issue in strict_gate_issues:
            lines.append(f"- {issue}")
    else:
        lines.append("- 严格门禁：`可发布`")

    if allow_pending:
        lines.append("- 本次执行：`临时放行（已忽略 pending 阻断）`")
        if effective_gate_issues:
            for issue in effective_gate_issues:
                lines.append(f"- 放行后仍需阻断：{issue}")
    else:
        lines.append("- 本次执行：`按严格门禁执行`")

    if risk_rows:
        for item in risk_rows[:20]:
            lines.append(f"- {item['id']} {item['name']}：{item['action']}")
    else:
        lines.append("- 未发现状态与资源明显冲突项")

    lines += [
        "",
        "## 待补图优先队列（前20）",
        "",
    ]

    for item in pending_rows[:20]:
        lines.append(
            f"- {item['id']} {item['name']}（{item['province']}-{item['city']}） -> 目标资源：`{item['targetAsset']}`"
        )

    lines += [
        "",
        "## 产物",
        "",
        f"- 台账：`{OUTPUT_CSV.relative_to(ROOT)}`",
        f"- 本报告：`{OUTPUT_MD.relative_to(ROOT)}`",
    ]

    OUTPUT_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="校验东北三省风光图片资源并生成台账/报告"
    )
    parser.add_argument(
        "--gate-release",
        action="store_true",
        help="启用发布门禁：若存在 pending/异常项则返回非 0",
    )
    parser.add_argument(
        "--allow-pending",
        action="store_true",
        help="仅用于紧急场景：忽略 pending 阻断并继续返回 0",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    scenics = load_scenics()
    assets = existing_asset_names()
    rows = compute_rows(scenics, assets)
    strict_gate_issues = collect_gate_issues(rows)
    gate_issues = strict_gate_issues[:]
    if args.allow_pending:
        gate_issues = [x for x in gate_issues if not x.startswith("pending 状态未清零")]

    write_csv(rows)
    write_markdown(rows, strict_gate_issues, gate_issues, args.allow_pending)
    print(f"[ok] wrote: {OUTPUT_CSV.relative_to(ROOT)}")
    print(f"[ok] wrote: {OUTPUT_MD.relative_to(ROOT)}")

    if args.gate_release:
        if gate_issues:
            print("[gate] BLOCKED: 风景图校验未通过。")
            for issue in gate_issues:
                print(f"[gate] - {issue}")
            sys.exit(2)
        print("[gate] PASSED: 风景图校验通过，可发布。")


if __name__ == "__main__":
    main()
