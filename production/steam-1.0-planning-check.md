# Steam 1.0 作者规划静态核查

日期：2026-09-11。状态：STATIC CHECK PASS / Design Review Pending。

- 内容矩阵：364行，唯一内容ID与本地化键；计划资产键无重复。
- 数量：{"objective": 6, "region": 8, "scene": 16, "chapter": 8, "character": 8, "active": 24, "passive": 24, "normal_enemy": 24, "elite": 8, "boss": 9, "mission": 64, "evolution": 16, "risk_event": 24, "prep_effect": 12, "challenge": 24, "achievement": 60, "screen": 11, "difficulty": 3, "progression_node": 15}
- 全部依赖及解锁ID存在；包含解锁边的内容图无环。
- 64任务从START顺序可达，每章8任务、2场景；章节文档任务ID顺序与CSV一致。
- 9个Boss各被一个主线任务指定；第8章第7/8任务分别为章节/终局Boss。
- 32既有系统编号保持；新增9域单独统计。
- 新文档本地链接15处全部可解析，工作包owner ID合法。
- 所有364行状态仍为PLANNED / NOT_IMPLEMENTED / NOT_RUN，证据列为空，未把规划当运行证据。
- 矩阵SHA256：`4147588d345132d41ae1e3a6c4e5e1a81fa25a2b72d0306fc8a03931cb1e23ba`。

本核查只校验作者规划的结构、引用与计数。没有独立full review、Godot回归、玩家试玩、Windows或Steam客户端验证。SCOPE-TIME-01有效时长风险OPEN；新增owner合同/Save ABI未冻结，battle_ready=false。

交付文件：design/steam-1.0-product-scope.md、design/steam-1.0-campaign.md、production/steam-1.0-content-matrix.csv、production/steam-1.0-system-migration.md。后续改变CSV需重新核对本记录的hash和计数。
