# WP04a：Steam编码与章节数据校验基础

2026-09-11。用户“继续”后，从已批准的ADR-0006/Save/Campaign/Mission设计基线推进。**本轮WP04a代码复核通过，WP04整体仍PARTIAL；运行存档仍JSON v1，battle_ready=false。**

## 实现

- `src/persistence/steam_canonical_codec.gd`：调用方字节/深度预算必填；对象ASCII key排序、语义数组保序、规范UTF8/控制字符转义、完整重编码一致才发布解析值；拒绝重复key、宽松JSON、别名转义与原生JSON数值。u63直接解析十进制，不经过float；checked递增；finite float64固定hex位模式，负零归正零，读取拒绝非finite/负零/非规范hex。
- `src/data/steam_campaign_schema.gd`：Config注入内容revision/hash、Mission hash与合法unlock集合；初始化先全表校验再深拷贝；64任务身份/章节/ordinal/线性前置、grant引用、M01-03备战唯一开放；campaign/unlocks封闭wrapper和payload、合法完成前缀、解锁集合与最终ending校验。多个任务可以共享已有解锁项。模块不发奖励、不持久化、不接生产入口。
- `assets/schemas/steam/`：三份自包含Draft2020-12结构schema及边界说明；生成器、标准校验器、GDScript字段集合对照明确分工。
- `tools/steam/build_schema_fixtures.py`：9份独立Python canonical/SHA256 golden及64行合成任务fixture。TEST-* grants和合成hash不是正式任务配置，不读取规划CSV，不生成可玩内容。

## 验证与review

| 证据 | 结果 | 范围 |
|---|---|---|
| steam_codec_test.gd | 82 checks PASS | u63/IEEE bits、canonical、嵌套重复key、UTF8六种坏序列、精确字节/深度边界 |
| steam_schema_test.gd | 104 checks PASS | Python-vs-Godot golden、64完整前缀/终局、未知字段/图/hash/grant、共享grant、ASCII、生命周期/别名 |
| check_schema_artifacts.py | 70 checks PASS | Draft2020-12结构与u63边界、生成文件漂移、GDScript/schema properties/required一致 |
| 既有5组集成回归 | 全部PASS | Save、fault surface、process crash、Progression、Home progression |
| Godot editor import | exit0 | 新脚本导入，无SCRIPT ERROR；不是Windows验证 |
| git diff --check | PASS | 当前工作树格式 |

独立Godot/GDScript与QA按仓库code-review技能实际并行复核；前者APPROVED限定模块范围，后者APPROVED WITH SUGGESTIONS并增量检查机器schema。两项P2（ASCII域缩窄、全局grant去重）已修复并独立复测；最终测试建议已吸收。报告归档[review-code](steam-schema-2026-09-11/review-code.md)、[review-qa](steam-schema-2026-09-11/review-qa.md)。没有声称额外fresh总监或全部商业合同重新批准。

日志/hash见[证据目录](steam-schema-2026-09-11/)。非法UTF8故意触发Godot转换诊断，测试断言其返回失败且不发布value；这些诊断不是静默接受数据。测试成功行和退出码单独核对。

## 限制与下一工程入口

1. **U+0000仍为适配限制**：Godot String构造/JSON解析会替换它；decoder在解析前明确UNSUPPORTED_STRING，避免伪造字节。ASCII结构schema包含该字符，因此仍需codec前置。没有宣称完整SP01域通过；后续须选择字节级字符串表示或正式限制实际domain字符串域。
2. 目前仅campaign/unlocks具新校验器。records/progression/preparation/current_run/user_settings以及战斗owner快照尚未完整注册，`production_admission()`固定返回UNSUPPORTED_SCHEMA及缺失域，不生成空对象补齐。
3. Config注入的真实MissionDefinition仍待生成与内容审核。这里校验hash绑定，不证明该hash背后已经有合法目标配置；64行fixture仅合成协议测试。
4. 64KiB/128KiB测试上限、深度32及递归适配器硬保护64不是实测生产容量。完整required-owner + RESULT_PENDING双份域样本齐备后，才测字节、内存、编码/读回/恢复耗时。
5. 未实现或启用v2的磁盘事务、Windows OS锁/强杀/云档，也未改变现有JSON v1文件、生产配置或游戏流程。

下一工程入口：逐一完成其余五domain的schema/validator/migration与required-owner快照清单，先锁定字段/identity/队列/恢复行为；再生成最大合法fixture并冻结预算。随后接Save v2两阶段提交与Mission/Campaign运行闭环。完整八章、20小时以上目标继续按原范围验收。

## 引擎参考

先读取本地Godot版本/实践文档，再核对[JSON官方说明](https://docs.godotengine.org/en/stable/classes/class_json.html)、[PackedByteArray](https://docs.godotengine.org/en/stable/classes/class_packedbytearray.html)与[String](https://docs.godotengine.org/en/stable/classes/class_string.html)。特别没有把Godot宽松parse成功当成规范JSON通过；浮点布局经当前runtime探测和Python参考golden验证，未据macOS结果推定Windows通过。
