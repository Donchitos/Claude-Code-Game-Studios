# Steam WP04：结构 schema

这些 Draft 2020-12 文件对应 ADR-0006 / `campaign-flow.md` 中已选定的结构：CampaignDefinitionV1、CampaignDomainV1、UnlockDomainV1。domain 文件包括 Save v2 的 `{schema,payload}` wrapper，payload 保留其自身 schema。所有字段必需，未知字段拒绝。

运行校验分三层，不能互相替代：

1. `SteamCanonicalCodec` 验证规范字节、数值字符串/位模式及调用方字节/深度边界。非规范字节不得先变成可消费数据。Godot String 不能表示 U+0000；该输入明确返回 UNSUPPORTED_STRING，此适配限制尚未关闭。
2. 这些 JSON Schema 只验证结构、类型、唯一集合、固定行数和精确 u63/hex 字符域。标准校验器无需自定义 format 即能拒绝 u63 溢出。ASCII 的结构域包括 U+0000，因此结构通过不代表 Godot codec 可承接。
3. `SteamCampaignSchema` 检查任务 ID/章节/顺序、线性前置、Config 提供的已验证内容 revision/hash/mission hash、grant 引用、M01-03 备战开放、完成前缀、解锁及终局语义。Config 仍须真正生成并验证 MissionDefinition，不能把测试 hash 当正式定义。

schema 检查成功不能启用生产；records/progression/preparation/current_run/user_settings 的 v2 codec、owner snapshots、预算、事务/平台适配尚缺。原运行入口仍是 JSON v1。

生成：`python3 tools/steam/build_schemas.py`。
检查：`python3 tools/steam/check_schema_artifacts.py`（依赖见 `tools/steam/requirements.txt`）。
测试样本：`python3 tools/steam/build_schema_fixtures.py`。仅向 `tests/fixtures/steam/` 写入合成样本，使用 TEST-* grant 和显式合成 Mission hash；不读规划 CSV、不产生正式游戏内容。64 行体现商业版结构测试，不是可玩任务。

测试的 64KiB/128KiB 与深度 32 仅是测试输入上限；codec 的深度 64 是递归适配器保护限制，均非全内容存档的测量预算。生产上限需完整 required-owner 样本与 RESULT_PENDING 双份域峰值测量后单独冻结。
