# 东北三省风光图片匹配校验报告

更新时间：2026-04-16

## 校验口径

- `exact`：图片可与具体景点一一对应（可作为上架展示图）
- `representative`：同类示意图，仅用于功能演示，不代表该景点实拍
- `pending`：待人工核验，当前不应对外宣称为该景点真实图片

## 当前结果（按数据集）

- 景点总数：100
- `exact`：6
- `representative`：0
- `pending`：94

## 已完成精准匹配（exact）

- `s001` 哈尔滨冰雪大世界 -> `scenic_icesnow`
- `s002` 中央大街 -> `scenic_city`
- `s006` 五大连池 -> `scenic_volcano`
- `s008` 雪乡 -> `scenic_snowvillage`
- `s025` 长白山天池 -> `scenic_mountain`
- `s052` 盘锦红海滩 -> `scenic_wetland`

## 上架前必须完成项

- 为其余 94 个景点补充“景点唯一实拍图”资源（建议命名：`scenic_<id>`）
- 将对应条目的 `imageMatchType` 从 `pending` 更新为 `exact`
- 为每张图补录来源、拍摄地点、授权信息（留档到法务/素材台账）
- 抽样二次复核（至少 20%）确认“图地一致、文图一致”

## 代码侧防错

- 模型新增 `imageMatchType` 字段，默认 `pending`
- UI 对图片打标：`实拍已核验 / 示意图 / 待核验`
- 仓库层加载时打印校验统计，便于测试与发布前检查
