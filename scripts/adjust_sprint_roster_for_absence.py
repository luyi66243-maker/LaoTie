#!/usr/bin/env python3
"""
根据缺席信息自动补位 14 天冲刺排班。

示例：
  python3 scripts/adjust_sprint_roster_for_absence.py \
    --batch "D05:B,C:E,F;D06:A:G"
"""

from __future__ import annotations

import argparse
import csv
from pathlib import Path
from datetime import datetime
import shutil


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_INPUT = ROOT / "docs/scenic-image-14day-sprint-roster-suggested.csv"
DEFAULT_OUTPUT = ROOT / "docs/scenic-image-14day-sprint-roster-adjusted.csv"
ROLE_COLUMNS = ["collector", "assetOperator", "dataOwner", "qaOwner"]

# 无外援时的默认补位优先顺序（允许双岗）
FALLBACK_ORDER = {
    "collector": ["assetOperator", "dataOwner", "qaOwner"],
    "assetOperator": ["collector", "dataOwner", "qaOwner"],
    "dataOwner": ["qaOwner", "collector", "assetOperator"],
    "qaOwner": ["dataOwner", "collector", "assetOperator"],
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="请假自动补位并输出新排班表")
    parser.add_argument("--day", help="缺席日期，例如 D05（单日模式）")
    parser.add_argument("--absent", help="缺席人（可逗号分隔，例如 B,C）（单日模式）")
    parser.add_argument(
        "--standby",
        default="",
        help="外援替补人（可逗号分隔，按顺序使用）（单日模式）。",
    )
    parser.add_argument(
        "--batch",
        default="",
        help=(
            "批量模式，格式：D05:B,C:E,F;D06:A:G。"
            "每段为 day:absent1,absent2:standby1,standby2，standby 可省略。"
        ),
    )
    parser.add_argument(
        "--input",
        default=str(DEFAULT_INPUT),
        help="输入排班 CSV 路径",
    )
    parser.add_argument(
        "--output",
        default=str(DEFAULT_OUTPUT),
        help="输出排班 CSV 路径",
    )
    parser.add_argument(
        "--timestamp-output",
        action="store_true",
        help="输出文件名附加时间戳，避免覆盖历史版本",
    )
    parser.add_argument(
        "--latest-link",
        action="store_true",
        help="写入一个固定 latest 文件副本，便于团队统一读取",
    )
    parser.add_argument(
        "--latest-path",
        default="",
        help="latest 文件路径（可选）。未提供时自动使用 output 同目录的 *-latest.csv",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="仅预览变更，不写入输出文件",
    )
    parser.add_argument(
        "--validate-only",
        action="store_true",
        help="仅校验规则是否合法与可执行，不写入输出文件",
    )
    parser.add_argument(
        "--summary-md",
        action="store_true",
        help="生成本次调整说明 Markdown（默认路径 docs/roster-adjustment-summary-latest.md）",
    )
    parser.add_argument(
        "--summary-path",
        default="",
        help="调整说明 Markdown 路径（可选）",
    )
    parser.add_argument(
        "--summary-history",
        action="store_true",
        help="说明文档同时生成时间戳归档版本",
    )
    parser.add_argument(
        "--lock-latest-on-write",
        action="store_true",
        help="仅 write 模式更新 latest 说明；validate/dry-run 仅写预览/归档",
    )
    parser.add_argument(
        "--fail-on-double-role",
        action="store_true",
        help="若补位后同一人当天兼任多岗则直接失败",
    )
    return parser.parse_args()


def load_rows(path: Path) -> list[dict]:
    with path.open("r", encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))


def write_rows(path: Path, rows: list[dict], fields: list[str]) -> None:
    with path.open("w", encoding="utf-8-sig", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)


def write_summary_md(
    path: Path,
    mode_label: str,
    input_path: Path,
    output_path: Path | None,
    latest_path: Path | None,
    specs: list[tuple[str, list[str], list[str]]],
    summaries: list[str],
    warnings: list[str],
) -> None:
    lines = [
        "# 排班调整说明（自动生成）",
        "",
        f"- 生成时间：{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        f"- 执行模式：{mode_label}",
        f"- 输入文件：`{input_path.relative_to(ROOT)}`",
    ]
    if output_path is not None:
        lines.append(f"- 输出文件：`{output_path.relative_to(ROOT)}`")
    if latest_path is not None:
        lines.append(f"- latest 文件：`{latest_path.relative_to(ROOT)}`")

    lines += [
        "",
        "## 规则输入",
        "",
    ]
    for day, absents, standbys in specs:
        standby_text = ",".join(standbys) if standbys else "（无）"
        lines.append(f"- `{day}` 缺席：`{','.join(absents)}`；外援：`{standby_text}`")

    lines += [
        "",
        "## 变更明细",
        "",
    ]
    for s in summaries:
        lines.append(f"- {s}")

    if warnings:
        lines += [
            "",
            "## 风险告警",
            "",
        ]
        for w in warnings:
            lines.append(f"- {w}")

    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def role_owner_for_day(rows: list[dict], day: str) -> dict[str, str]:
    for row in rows:
        if row.get("day") == day:
            return {role: row.get(role, "") for role in ROLE_COLUMNS}
    return {}


def parse_people(value: str) -> list[str]:
    return [x.strip() for x in value.split(",") if x.strip()]


def parse_batch_specs(batch: str) -> list[tuple[str, list[str], list[str]]]:
    specs: list[tuple[str, list[str], list[str]]] = []
    for segment in [x.strip() for x in batch.split(";") if x.strip()]:
        parts = [p.strip() for p in segment.split(":")]
        if len(parts) < 2 or len(parts) > 3:
            raise ValueError(f"批量格式错误：{segment}")
        day = parts[0]
        absents = parse_people(parts[1])
        standbys = parse_people(parts[2]) if len(parts) == 3 else []
        if not day or not absents:
            raise ValueError(f"批量条目缺少 day 或 absent：{segment}")
        specs.append((day, absents, standbys))
    return specs


def choose_replacement(
    day_roles: dict[str, str],
    target_role: str,
    absent_set: set[str],
    standby_queue: list[str],
    replacement_counts: dict[str, int],
) -> tuple[str, str]:
    while standby_queue:
        standby = standby_queue.pop(0)
        if standby not in absent_set:
            replacement_counts[standby] = replacement_counts.get(standby, 0) + 1
            return standby, "外援替补"

    candidate_with_reason: tuple[str, str] | None = None
    for source_role in FALLBACK_ORDER[target_role]:
        candidate = day_roles.get(source_role, "")
        if candidate and candidate not in absent_set:
            reason = f"内部补位（{source_role} 兼岗）"
            if candidate_with_reason is None:
                candidate_with_reason = (candidate, reason)
                continue
            # 尽量减少同一人多次兼岗
            prev = candidate_with_reason[0]
            if replacement_counts.get(candidate, 0) < replacement_counts.get(prev, 0):
                candidate_with_reason = (candidate, reason)

    if candidate_with_reason:
        candidate = candidate_with_reason[0]
        replacement_counts[candidate] = replacement_counts.get(candidate, 0) + 1
        return candidate_with_reason
    return "", "未找到可用替补"


def apply_absence(
    rows: list[dict],
    day: str,
    absents: list[str],
    standbys: list[str],
    fail_on_double_role: bool,
) -> tuple[list[dict], list[str], list[str]]:
    day_roles = role_owner_for_day(rows, day)
    if not day_roles:
        raise ValueError(f"未找到日期：{day}")

    absent_set = set(absents)
    role_by_absent: dict[str, str] = {}
    for absent in absents:
        for role, owner in day_roles.items():
            if owner == absent:
                role_by_absent[absent] = role
                break
        if absent not in role_by_absent:
            raise ValueError(f"{day} 未找到缺席人：{absent}")

    # 同一天最多 4 个岗位，超过则不可补位
    if len(absent_set) >= len(ROLE_COLUMNS):
        raise ValueError("同日缺席人数过多，无法自动补位")

    state_roles = dict(day_roles)
    replacement_counts: dict[str, int] = {}
    summaries: list[str] = []
    warnings: list[str] = []
    note_suffixes: list[str] = []
    standby_queue = list(standbys)

    for absent in absents:
        absent_role = role_by_absent[absent]
        replacement, reason = choose_replacement(
            day_roles=state_roles,
            target_role=absent_role,
            absent_set=absent_set,
            standby_queue=standby_queue,
            replacement_counts=replacement_counts,
        )
        if not replacement:
            raise ValueError("未找到可用替补人，请补充 --standby")
        state_roles[absent_role] = replacement
        summaries.append(f"{day}: {absent} 缺席，岗位 {absent_role} -> {replacement}（{reason}）")
        note_suffixes.append(f"{day} {absent} 缺席，{replacement} 补位（{reason}）")

    warnings: list[str] = []
    owner_roles: dict[str, list[str]] = {}
    for role, owner in state_roles.items():
        owner_roles.setdefault(owner, []).append(role)
    double_role_owners = {owner: roles for owner, roles in owner_roles.items() if len(roles) > 1}
    if double_role_owners:
        fragments = [f"{owner}({','.join(roles)})" for owner, roles in double_role_owners.items()]
        message = f"{day} 出现兼岗：{'；'.join(fragments)}"
        if fail_on_double_role:
            raise ValueError(f"{message}。请补充 --standby 或减少缺席人数")
        warnings.append(message)

    updated = []
    for row in rows:
        new_row = dict(row)
        if row.get("day") == day:
            for role in ROLE_COLUMNS:
                new_row[role] = state_roles[role]
            note = row.get("notes", "").strip()
            suffix = "；".join(note_suffixes)
            new_row["notes"] = f"{note} | {suffix}" if note else suffix
        updated.append(new_row)
    return updated, summaries, warnings


def main() -> None:
    args = parse_args()
    input_path = Path(args.input).resolve()
    base_output_path = Path(args.output).resolve()
    output_path = base_output_path
    rows = load_rows(input_path)
    if not rows:
        raise SystemExit("输入排班为空")

    if args.batch.strip():
        specs = parse_batch_specs(args.batch.strip())
    else:
        if not args.day or not args.absent:
            raise SystemExit("单日模式需提供 --day 与 --absent，或改用 --batch")
        specs = [(
            args.day.strip(),
            parse_people(args.absent.strip()),
            parse_people(args.standby.strip()),
        )]

    updated_rows = rows
    summaries: list[str] = []
    warnings: list[str] = []
    for day, absents, standbys in specs:
        if not absents:
            raise SystemExit(f"{day} 缺席人为空")
        try:
            updated_rows, one_day_summaries, one_day_warnings = apply_absence(
                rows=updated_rows,
                day=day,
                absents=absents,
                standbys=standbys,
                fail_on_double_role=args.fail_on_double_role,
            )
        except ValueError as exc:
            raise SystemExit(f"校验失败：{exc}") from exc
        summaries.extend(one_day_summaries)
        warnings.extend(one_day_warnings)

    mode_label = "validate-only" if args.validate_only else ("dry-run" if args.dry_run else "write")
    summary_path = (
        Path(args.summary_path).resolve()
        if args.summary_path.strip()
        else (ROOT / "docs/roster-adjustment-summary-latest.md").resolve()
    )
    summary_archive_path: Path | None = None
    summary_preview_path: Path | None = None
    if args.summary_md and args.summary_history:
        ts = datetime.now().strftime("%Y%m%d-%H%M%S")
        summary_archive_path = summary_path.with_name(
            f"{summary_path.stem}-{ts}{summary_path.suffix}"
        )
    if args.summary_md and args.lock_latest_on_write and mode_label != "write":
        ts = datetime.now().strftime("%Y%m%d-%H%M%S")
        summary_preview_path = summary_path.with_name(
            f"{summary_path.stem}-{mode_label}-{ts}{summary_path.suffix}"
        )

    summary_target_path = summary_preview_path or summary_path

    if args.validate_only:
        print("[validate] 校验通过：规则可执行，不写入输出文件")
        for summary in summaries:
            print(f"[validate] {summary}")
        for warning in warnings:
            print(f"[validate][warn] {warning}")
        if args.summary_md:
            write_summary_md(
                path=summary_target_path,
                mode_label=mode_label,
                input_path=input_path,
                output_path=None,
                latest_path=None,
                specs=specs,
                summaries=summaries,
                warnings=warnings,
            )
            print(f"[validate] summary: {summary_target_path.relative_to(ROOT)}")
            if summary_archive_path is not None:
                shutil.copy2(summary_target_path, summary_archive_path)
                print(f"[validate] summary archive: {summary_archive_path.relative_to(ROOT)}")
        return

    written_output_path: Path | None = None
    written_latest_path: Path | None = None
    if args.dry_run:
        print("[dry-run] 预览模式：不写入输出文件")
    else:
        if args.timestamp_output:
            ts = datetime.now().strftime("%Y%m%d-%H%M%S")
            output_path = output_path.with_name(f"{output_path.stem}-{ts}{output_path.suffix}")
        fields = list(updated_rows[0].keys())
        write_rows(output_path, updated_rows, fields)
        print(f"[ok] wrote: {output_path.relative_to(ROOT)}")
        written_output_path = output_path

        if args.latest_link:
            if args.latest_path.strip():
                latest_path = Path(args.latest_path).resolve()
            else:
                latest_path = base_output_path.with_name(
                    f"{base_output_path.stem}-latest{base_output_path.suffix}"
                )
            latest_path.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(output_path, latest_path)
            print(f"[ok] wrote latest: {latest_path.relative_to(ROOT)}")
            written_latest_path = latest_path

    for summary in summaries:
        prefix = "[dry-run]" if args.dry_run else "[ok]"
        print(f"{prefix} {summary}")
    for warning in warnings:
        prefix = "[dry-run][warn]" if args.dry_run else "[warn]"
        print(f"{prefix} {warning}")

    if args.summary_md:
        write_summary_md(
            path=summary_target_path,
            mode_label=mode_label,
            input_path=input_path,
            output_path=written_output_path,
            latest_path=written_latest_path,
            specs=specs,
            summaries=summaries,
            warnings=warnings,
        )
        prefix = "[dry-run]" if args.dry_run else "[ok]"
        print(f"{prefix} summary: {summary_target_path.relative_to(ROOT)}")
        if summary_archive_path is not None:
            shutil.copy2(summary_target_path, summary_archive_path)
            print(f"{prefix} summary archive: {summary_archive_path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
