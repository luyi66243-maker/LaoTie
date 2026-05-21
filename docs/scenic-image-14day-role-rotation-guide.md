# 14天排班角色轮转说明（A/B/C/D）

适用文件：`docs/scenic-image-14day-sprint-roster-suggested.csv`

## 轮转规则

- 每天按 Day 序号轮转 1 位：
- Day01：A 采集 / B 入库 / C 数据 / D 验收
- Day02：B 采集 / C 入库 / D 数据 / A 验收
- Day03：C 采集 / D 入库 / A 数据 / B 验收
- Day04：D 采集 / A 入库 / B 数据 / C 验收
- Day05 起按 Day01 规则循环

## 使用方式

1. 打开 `docs/scenic-image-14day-sprint-roster-suggested.csv`
2. 将 `A/B/C/D` 替换为真实负责人姓名
3. 若当天请假，可只调整当日 4 个角色，不影响次日轮转
4. 每日收尾执行：`python3 scripts/verify_scenic_images.py`

## 字段说明

- `collector`：素材采集负责人
- `assetOperator`：资源入库负责人
- `dataOwner`：`scenics.json` 更新负责人
- `qaOwner`：验收与门禁复检负责人
