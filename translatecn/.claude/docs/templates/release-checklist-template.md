## Release Checklist: [Version] -- [Platform]
## 发布检查清单：[Version] -- [Platform]
Generated: [Date]
生成日期：[Date]

### Codebase Health
### 代码库健康度
- Scanned: [N] source files (or `NOT ASSESSED — [reason]`, per Phase 3)
- TODO count: [N] ([list top 5 if many])
- FIXME count: [N] ([list all -- these are potential blockers])
- HACK count: [N] ([list all -- these need review])
- 已扫描：[N] 个源文件（或 `NOT ASSESSED — [reason]`，依 Phase 3）
- TODO 数量：[N]（[数量多时列出前 5]）
- FIXME 数量：[N]（[全部列出 —— 这些是潜在阻塞项]）
- HACK 数量：[N]（[全部列出 —— 这些需要评审]）

### Build Verification
### 构建验证
- [ ] Clean build succeeds on all target platforms
- [ ] 在所有目标平台上干净构建成功
- [ ] No compiler warnings (zero-warning policy)
- [ ] 无编译器警告（零警告策略）
- [ ] All assets included and loading correctly
- [ ] 所有资产已包含且加载正确
- [ ] Build size within budget ([target size])
- [ ] 构建体积在预算内（[target size]）
- [ ] Build version number correctly set ([version])
- [ ] 构建版本号设置正确（[version]）
- [ ] Build is reproducible from tagged commit
- [ ] 构建可从打标签的提交复现

### Quality Gates
### 质量门控
- Open bugs (`production/qa/bugs/`): [N] S1, [N] S2, [N] S3 -- or `NOT ASSESSED — no bug records`
- [ ] Zero open S1 (Critical) bugs
- [ ] Zero open S2 (High) bugs, no exceptions -- this row at `workflow: full` only; at `standard`/`minimal` open S2 bugs go in the Rationale as risks
- [ ] Zero S3 (Medium) bugs open, no exceptions -- this row at `workflow: full` only; at `standard`/`minimal` open S3 bugs go in the Rationale as risks
- [ ] All critical path features tested and signed off by QA
- [ ] Performance within budgets:
  - [ ] Target FPS met on minimum spec hardware
  - [ ] Memory usage within budget
  - [ ] Load times within budget
  - [ ] No memory leaks over extended play sessions
- [ ] No regression from previous build
- [ ] Soak test passed (4+ hours continuous play)
- 未关闭缺陷（`production/qa/bugs/`）：[N] 个 S1，[N] 个 S2，[N] 个 S3 —— 或 `NOT ASSESSED — 无缺陷记录`
- [ ] 零个未关闭的 S1（严重）缺陷
- [ ] 零个未关闭的 S2（高）缺陷，无例外 —— 此行仅在 `workflow: full` 下适用；在 `standard`/`minimal` 下，未关闭的 S2 缺陷作为风险写入“理由”
- [ ] 零个未关闭的 S3（中）缺陷，无例外 —— 此行仅在 `workflow: full` 下适用；在 `standard`/`minimal` 下，未关闭的 S3 缺陷作为风险写入“理由”
- [ ] 所有关键路径功能已测试并经 QA 签署确认
- [ ] 性能在预算内：
  - [ ] 在最低配置硬件上达到目标帧率
  - [ ] 内存占用在预算内
  - [ ] 加载时间在预算内
  - [ ] 长时间游玩会话中无内存泄漏
- [ ] 相对上一构建无回归
- [ ] 浸泡测试通过（连续游玩 4 小时以上）

> The release gate (`/gate-check release`) blocks any open S1–S3 bug at `workflow: full`,
> with no exceptions; at `standard` and `minimal` it blocks open S1 only, and an open
> S2 or S3 is a risk to record in the Rationale.
> 发布门控（`/gate-check release`）在 `workflow: full` 下会阻塞任何未关闭的 S1–S3 缺陷，
> 无例外；在 `standard` 和 `minimal` 下只阻塞未关闭的 S1，而未关闭的
> S2 或 S3 是需要在“理由”中记录的风险。

### Content Complete
### 内容完成
- [ ] All placeholder assets replaced with final versions
- [ ] 所有占位资产已替换为最终版本
- [ ] All TODO/FIXME in content files resolved or documented
- [ ] 内容文件中的所有 TODO/FIXME 已解决或记录在案
- [ ] All player-facing text proofread
- [ ] 所有玩家可见文本已校对
- [ ] All text localization-ready (no hardcoded strings)
- [ ] 所有文本已可本地化（无硬编码字符串）
- [ ] Audio mix finalized and approved
- [ ] 音频混音已定稿并获批
- [ ] Credits complete and accurate
- [ ] 制作人员名单完整且准确

[Platform Requirements: one block per device the platform argument names (`pc`, `console`, `mobile`; `all` is all three), copied from `release-platform-requirements.md`]
[平台要求：平台参数点名的每个设备（`pc`、`console`、`mobile`；`all` 表示三者全部）对应一块内容，从 `release-platform-requirements.md` 复制]

[Certification: the one block for this project's `platform.cert_tier`, copied from `certification-none.md`, `certification-itch.md`, `certification-steam.md` or `certification-console.md`; `certification-unknown.md` when the tier cannot be determined]
[认证：本项目 `platform.cert_tier` 对应的那一块内容，从 `certification-none.md`、`certification-itch.md`、`certification-steam.md` 或 `certification-console.md` 复制；无法确定层级时使用 `certification-unknown.md`]

### Store / Distribution
### 商店 / 分发
- [ ] Store page metadata complete and proofread
  - [ ] Short description
  - [ ] Long description
  - [ ] Feature list
  - [ ] System requirements (PC)
- [ ] Screenshots up to date and per-platform resolution requirements met
- [ ] Trailers up to date
- [ ] Key art and capsule images current
- [ ] Age rating obtained and configured:
  - [ ] ESRB
  - [ ] PEGI
  - [ ] Other regional ratings as required
- [ ] Legal notices, EULA, and privacy policy in place
- [ ] Third-party license attributions complete
- [ ] Pricing configured for all regions
- [ ] 商店页面元数据完整且已校对
  - [ ] 简短描述
  - [ ] 详细描述
  - [ ] 功能列表
  - [ ] 系统配置要求（PC）
- [ ] 截图为最新且满足各平台分辨率要求
- [ ] 预告片为最新
- [ ] 主视觉与胶囊图为最新
- [ ] 年龄分级已获取并配置：
  - [ ] ESRB
  - [ ] PEGI
  - [ ] 按需的其他地区分级
- [ ] 法律声明、EULA 与隐私政策已就位
- [ ] 第三方许可署名完整
- [ ] 所有区域的价格已配置

### Launch Readiness
### 发布就绪
- [ ] Analytics / telemetry verified and receiving data
- [ ] 分析/遥测已验证并正在接收数据
- [ ] Crash reporting configured and dashboard accessible
- [ ] 崩溃报告已配置且仪表盘可访问
- [ ] Day-one patch prepared and tested (if needed)
- [ ] 首日补丁已准备并测试（如需要）
- [ ] On-call team schedule set for first 72 hours
- [ ] 前 72 小时的值班团队表已设定
- [ ] Community launch announcements drafted
- [ ] 社区发布公告已起草
- [ ] Press/influencer keys prepared for distribution
- [ ] 媒体/意见领袖评测密钥已准备分发
- [ ] Support team briefed on known issues and FAQ
- [ ] 支持团队已了解已知问题与 FAQ
- [ ] Rollback plan documented (if critical issues found post-launch)
- [ ] 回滚方案已记录（若发布后发现严重问题）

### Go / No-Go: [READY / NOT ASSESSED / NOT READY]
### 上线/不上线：[READY / NOT ASSESSED / NOT READY]

First match wins: **NOT READY** if any blocking item fails; else **NOT ASSESSED**
if any section or item came out `NOT ASSESSED` (name each one); else **READY**. NOT
ASSESSED outranks READY — an unassessed section is not a passed one — and ranks
below NOT READY, so a known blocker is never buried behind it.
首先匹配者胜出：若任何阻塞项失败，则为 **NOT READY**；否则，若任一章节或条目结果为 `NOT ASSESSED`
（逐一命名），则为 **NOT ASSESSED**；否则为 **READY**。NOT
ASSESSED 优先于 READY —— 未评估的章节并非通过的章节 —— 且低于 NOT READY，
因此已知的阻塞项永远不会被它掩盖。

**Rationale:**
**理由：**
[Summary of readiness assessment. List any blocking items that must be
resolved before launch. If NOT READY, list the specific items that need
resolution and estimated time to address them.]
[就绪评估摘要。列出发布前必须解决的任何阻塞项。
若为 NOT READY，列出需要解决的具体条目及预计处理时间。]

**Sign-offs Required:**
**需要的签署确认：**
- [ ] QA Lead
- [ ] QA 负责人
- [ ] Technical Director
- [ ] 技术总监
- [ ] Producer
- [ ] 制作人
- [ ] Creative Director
- [ ] 创意总监
