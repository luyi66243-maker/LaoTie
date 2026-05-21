# 请假自动补位规则（14天冲刺）

适用排班：

- 输入：`docs/scenic-image-14day-sprint-roster-suggested.csv`
- 输出：`docs/scenic-image-14day-sprint-roster-adjusted.csv`

---

## 一、使用命令

### 快捷封装（推荐）

```bash
bash scripts/update_roster_from_absence.sh --batch "D05:B,C:E,F;D06:A:G"
```

说明：

- 默认自动开启 `--timestamp-output` + `--latest-link`
- 可用 `--dry-run` 先预览，不写文件
- 可用 `--validate-only` 仅校验规则是否合法与可执行
- 可用 `--no-timestamp` 或 `--no-latest-link` 关闭默认行为

### 快速校验（不改文件）

```bash
bash scripts/update_roster_from_absence.sh \
  --batch "D05:B,C:E,F;D06:A:G" \
  --validate-only
```

### 0) 跨多天批处理（推荐）

```bash
python3 scripts/adjust_sprint_roster_for_absence.py \
  --batch "D05:B,C:E,F;D06:A:G"
```

说明：

- 每段格式：`day:absent列表:standby列表`
- 多段用 `;` 分隔
- `standby` 可省略，例如：`D07:C`

### 0.1) 仅预览，不落盘

```bash
python3 scripts/adjust_sprint_roster_for_absence.py \
  --batch "D05:B,C:E,F;D06:A:G" \
  --dry-run
```

说明：

- 仅打印补位结果，不改动任何 CSV 文件
- 适合先评审再执行正式调整

### 0.2) 输出带时间戳（防覆盖）

```bash
python3 scripts/adjust_sprint_roster_for_absence.py \
  --batch "D05:B,C:E,F;D06:A:G" \
  --timestamp-output
```

说明：

- 输出形如：`docs/scenic-image-14day-sprint-roster-adjusted-20260423-213500.csv`
- 适合保存多轮调整记录，便于追溯

### 0.3) 同时产出 latest 固定文件（推荐团队协作）

```bash
python3 scripts/adjust_sprint_roster_for_absence.py \
  --batch "D05:B,C:E,F;D06:A:G" \
  --timestamp-output \
  --latest-link
```

说明：

- 会生成一份时间戳文件（归档）
- 同时生成固定名副本：`docs/scenic-image-14day-sprint-roster-adjusted-latest.csv`
- 团队系统可固定读取 `latest`，无需关心具体时间戳文件名

可选自定义 latest 路径：

```bash
python3 scripts/adjust_sprint_roster_for_absence.py \
  --batch "D05:B,C:E,F;D06:A:G" \
  --timestamp-output \
  --latest-link \
  --latest-path "docs/my-latest.csv"
```

### 0.4) 自动生成本次调整说明（Markdown）

```bash
bash scripts/update_roster_from_absence.sh \
  --batch "D05:B,C:E,F;D06:A:G" \
  --summary-md
```

说明：

- 默认输出：`docs/roster-adjustment-summary-latest.md`
- 可用 `--summary-path "docs/my-summary.md"` 自定义
- 说明文档包含：规则输入、变更明细、输出文件路径

### 0.5) 说明文档同时归档（防覆盖）

```bash
bash scripts/update_roster_from_absence.sh \
  --batch "D05:B,C:E,F;D06:A:G" \
  --summary-md \
  --summary-history
```

说明：

- 仍会更新 `docs/roster-adjustment-summary-latest.md`
- 同时新增时间戳归档，例如：
  `docs/roster-adjustment-summary-latest-20260423-220800.md`

### 0.6) 锁定 latest（仅正式执行可改 latest）

```bash
bash scripts/update_roster_from_absence.sh \
  --batch "D05:B,C:E,F" \
  --summary-md \
  --lock-latest-on-write
```

说明：

- `write` 模式：仍更新 `roster-adjustment-summary-latest.md`
- `validate-only` / `dry-run`：不会覆盖 latest，会写成带模式与时间戳的预览说明

### 0.7) 严格防兼岗（建议上线前启用）

```bash
bash scripts/update_roster_from_absence.sh \
  --batch "D05:B,C" \
  --fail-on-double-role
```

说明：

- 若补位后同一人当天兼任多个岗位，命令会直接失败并提示补外援
- 适合上线前或关键节点，避免“一个人顶两岗”带来的执行风险

### 1) 有外援（推荐）

```bash
python3 scripts/adjust_sprint_roster_for_absence.py \
  --day D05 \
  --absent B,C \
  --standby E,F
```

说明：

- `B,C` 为缺席人（支持多人）
- `E,F` 为当日外援（按顺序消耗）
- 输出文件会自动写入补位后的新排班

### 2) 无外援（自动内部补位）

```bash
python3 scripts/adjust_sprint_roster_for_absence.py \
  --day D05 \
  --absent B,C
```

说明：

- 脚本会按默认优先顺序选择同日人员补位
- 若内部补位，会在 `notes` 标记“兼岗”

---

## 二、默认内部补位优先顺序

- `collector` 缺席：优先 `assetOperator`，其次 `dataOwner`，最后 `qaOwner`
- `assetOperator` 缺席：优先 `collector`，其次 `dataOwner`，最后 `qaOwner`
- `dataOwner` 缺席：优先 `qaOwner`，其次 `collector`，最后 `assetOperator`
- `qaOwner` 缺席：优先 `dataOwner`，其次 `collector`，最后 `assetOperator`

---

## 三、执行后检查

- [ ] 打开 `docs/scenic-image-14day-sprint-roster-adjusted.csv`，确认当天角色已变更
- [ ] 确认 `notes` 已记录补位信息
- [ ] 当天任务完成后执行：`python3 scripts/verify_scenic_images.py`
- [ ] 关键里程碑日执行：`python3 scripts/verify_scenic_images.py --gate-release`

## 四、注意事项

- 同一天最多支持 3 人缺席自动补位（4 岗全缺席无法自动处理）
- 无外援时可能出现“同一人兼两岗”，以保障当日任务可继续推进
- 建议多人缺席场景优先传入 `--standby`，降低兼岗风险
