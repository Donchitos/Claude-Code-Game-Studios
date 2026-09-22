# F后续新增测试综合

2026-09-16，主线程收齐两个独立专家报告后综合：APPROVED WITH SUGGESTIONS，仅campaign_terminal_disk_test.gd与campaign_pacing_audit.gd。无必改项。

QA APPROVED，明确关闭F遗留的合法前态到终态持久化专项覆盖建议。GDScript APPROVED WITH SUGGESTIONS，类型注解、长测试拆分和未来精确奖励公式oracle为可维护性/覆盖建议；当前断言已验证单次退休、胜负计数和重复请求不改profile/槽，不宣称精确奖励公式已全覆盖。

作者自然两路线安全/进化256.55秒、风险263.77秒。独立专家默认策略复测255.25秒，是未传--qa-production-evolution的第三策略；不与作者进化路线混同。独立风险路线与作者一致。所有数值是自动active秒，不是真人时长或内容体量认证。

绑定test-freeze.json的2项；F原source-freeze 63项和实际PCK哈希均保持一致，见final-check.json。专家各自独立运行的证据归属见gdscript-report.md和qa-report.md。原F报告保持历史，新增报告只追加覆盖。

测试子类在结算提交前同步返回IO_ERROR，无物理故障、部分写入、进程强杀或全切点认证。新玩家SKIPPED_BY_USER，battle_ready=false。

新作者方案design/chapter-one-content-expansion.md未作为代码评审目标，未实施、未获full design verdict；不能继承本测试批准。
