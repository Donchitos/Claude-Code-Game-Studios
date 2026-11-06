# Launch Checklist: [Game Title]
# 发布检查清单：[游戏名称]
Target Launch: [Date or DRY RUN]
目标发布：[Date 或 试运行]
Generated: [Date]
生成日期：[Date]

---

## 1. Code Readiness
## 1. 代码就绪

### Build Health
### 构建健康度
- [ ] Clean build on all target platforms
- [ ] 在所有目标平台上构建通过
- [ ] Zero compiler warnings
- [ ] 零编译器警告
- [ ] All unit tests passing
- [ ] 所有单元测试通过
- [ ] All integration tests passing
- [ ] 所有集成测试通过
- [ ] Performance benchmarks within targets
- [ ] 性能基准在目标范围内
- [ ] No memory leaks (verified via extended soak test)
- [ ] 无内存泄漏（通过延长浸泡测试验证）
- [ ] Build size within platform limits
- [ ] 构建体积在平台限制内
- [ ] Build version correctly set and tagged in source control
- [ ] 构建版本已正确设置并在版本控制中打上标签

### Code Quality
### 代码质量
- [ ] TODO count: [N] (zero required for launch, or documented exceptions)
- [ ] TODO 数量：[N]（发布要求为零，或有记录的例外）
- [ ] FIXME count: [N] (zero required)
- [ ] FIXME 数量：[N]（要求为零）
- [ ] HACK count: [N] (each must have documented justification)
- [ ] HACK 数量：[N]（每一个都必须有书面理由）
- [ ] No debug output in production code
- [ ] 生产代码中无调试输出
- [ ] No hardcoded dev/test values
- [ ] 无硬编码的开发/测试值
- [ ] All feature flags set to production values
- [ ] 所有功能开关已设为生产值
- [ ] Error handling covers all critical paths
- [ ] 错误处理覆盖所有关键路径
- [ ] Crash reporting integrated and verified
- [ ] 崩溃报告已集成并验证

### Security
### 安全
- [ ] No exposed API keys or credentials in source
- [ ] 源代码中无暴露的 API 密钥或凭证
- [ ] Save data encrypted
- [ ] 存档数据已加密
- [ ] Network communication secured (TLS/DTLS)
- [ ] 网络通信已加密（TLS/DTLS）
- [ ] Anti-cheat measures active (if multiplayer)
- [ ] 反作弊措施已启用（若为多人游戏）
- [ ] Input validation on all server endpoints (if multiplayer)
- [ ] 所有服务端端点均有输入校验（若为多人游戏）
- [ ] Privacy policy compliance verified
- [ ] 隐私政策合规性已验证

---

## 2. Content Readiness
## 2. 内容就绪

### Assets
### 资产
- [ ] All placeholder art replaced with final assets
- [ ] 所有占位美术已替换为最终资产
- [ ] All placeholder audio replaced with final audio
- [ ] 所有占位音频已替换为最终音频
- [ ] Audio mix finalized and approved by audio director
- [ ] 音频混音已定稿并经音频总监批准
- [ ] All VFX polished and performance-verified
- [ ] 所有视觉特效已打磨并验证性能
- [ ] No missing or broken asset references
- [ ] 无缺失或损坏的资产引用
- [ ] Asset naming conventions enforced
- [ ] 资产命名规范已强制执行

### Text and Localization
### 文本与本地化
- [ ] All player-facing text proofread
- [ ] 所有玩家可见文本已校对
- [ ] No hardcoded strings (all externalized for localization)
- [ ] 无硬编码字符串（全部外置以便本地化）
- [ ] All supported languages translated and verified
- [ ] 所有支持语言已翻译并验证
- [ ] Text fits UI in all languages (text fitting pass complete)
- [ ] 文本在所有语言的 UI 中均能适配（文本适配检查已完成）
- [ ] Font coverage verified for all supported languages
- [ ] 所有支持语言的字体覆盖已验证
- [ ] Credits complete, accurate, and up to date
- [ ] 制作人员名单完整、准确且为最新

### Game Content
### 游戏内容
- [ ] All levels/maps playable from start to finish
- [ ] 所有关卡/地图均可从头玩到尾
- [ ] Tutorial flow complete and tested with new players
- [ ] 教程流程完整并已用新玩家测试
- [ ] All achievements/trophies implemented and tested
- [ ] 所有成就/奖杯已实现并测试
- [ ] Save/load works correctly for all game states
- [ ] 存档/读档在所有游戏状态下均正常工作
- [ ] Difficulty settings balanced and tested
- [ ] 难度设置已平衡并测试
- [ ] End-game/credits sequence complete
- [ ] 结局/制作人员名单序列完整

---

## 3. Quality Assurance
## 3. 质量保证

### Testing
### 测试
- [ ] Full regression test suite passed
- [ ] 完整回归测试套件通过
- [ ] Zero S1 (Critical) bugs open
- [ ] 零个未关闭的 S1（严重）缺陷
- [ ] Zero S2 (High) bugs open (or documented exceptions) — at `workflow: full` instead: zero S2 (High) and S3 (Medium) bugs open, no exceptions
- [ ] 零个未关闭的 S2（高）缺陷（或有记录的例外）—— 在 `workflow: full` 下则要求：零个未关闭的 S2（高）和 S3（中）缺陷，无例外
- [ ] Soak test passed (the longest soak `/soak-test` runs, or longer by hand if a play session lasts longer)
- [ ] 浸泡测试通过（`/soak-test` 运行的最长浸泡时长，若单次游玩时间更长则手动延长）
- [ ] Multiplayer stress test passed (if applicable)
- [ ] 多人压力测试通过（如适用）
- [ ] All critical user paths tested on every platform
- [ ] 所有关键用户路径已在每个平台测试
- [ ] Edge cases tested (full storage, no network, suspend/resume)
- [ ] 边缘情况已测试（存储已满、无网络、挂起/恢复）

[Certification: the one block for this project's `platform.cert_tier`, copied from `certification-none.md`, `certification-itch.md`, `certification-steam.md` or `certification-console.md`; `certification-unknown.md` when the tier cannot be determined]
[认证：本项目 `platform.cert_tier` 对应的那一块内容，从 `certification-none.md`、`certification-itch.md`、`certification-steam.md` 或 `certification-console.md` 复制；无法确定层级时使用 `certification-unknown.md`]

**Every tier**, because these are not certification-gated:
**所有层级**均适用，因为这些不受认证门控：
- [ ] Accessibility: minimum standards met (remapping, text scaling, colorblind)
- [ ] 无障碍：已满足最低标准（按键重映射、文本缩放、色盲）

### Performance
### 性能
- [ ] Target FPS met on minimum spec hardware
- [ ] 在最低配置硬件上达到目标帧率
- [ ] Load times within budget on all platforms
- [ ] 所有平台的加载时间在预算内
- [ ] Memory usage within budget on all platforms
- [ ] 所有平台的内存占用在预算内
- [ ] Network bandwidth within targets (if multiplayer)
- [ ] 网络带宽在目标范围内（若为多人游戏）
- [ ] No frame hitches in critical gameplay moments
- [ ] 关键玩法时刻无掉帧卡顿

---

## 4. Store and Distribution
## 4. 商店与分发

### Store Pages
### 商店页面
- [ ] Store page copy finalized and proofread
- [ ] 商店页面文案已定稿并校对
- [ ] Screenshots current and per-platform resolution
- [ ] 截图为最新且符合各平台分辨率
- [ ] Trailers current and approved
- [ ] 预告片为最新且已获批准
- [ ] Key art and capsule images finalized
- [ ] 主视觉与胶囊图已定稿
- [ ] System requirements accurate (PC)
- [ ] 系统配置要求准确（PC）
- [ ] Pricing configured for all regions
- [ ] 所有区域的价格已配置
- [ ] Pre-purchase/wishlist campaigns active (if applicable)
- [ ] 预购/愿望单活动已启动（如适用）

### Legal
### 法务
- [ ] EULA finalized and approved by legal
- [ ] 最终用户许可协议已定稿并经法务批准
- [ ] Privacy policy published and linked
- [ ] 隐私政策已发布并链接
- [ ] Third-party license attributions complete
- [ ] 第三方许可署名完整
- [ ] Music/audio licensing verified
- [ ] 音乐/音频授权已验证
- [ ] Trademark/IP clearance confirmed
- [ ] 商标/知识产权清查已确认
- [ ] GDPR/CCPA compliance verified (data collection, consent, deletion)
- [ ] GDPR/CCPA 合规性已验证（数据收集、同意、删除）

---

## 5. Infrastructure
## 5. 基础设施

### Servers (if multiplayer/online)
### 服务器（若为多人/在线游戏）
- [ ] Production servers provisioned and load-tested
- [ ] 生产服务器已配置并完成负载测试
- [ ] Auto-scaling configured and tested
- [ ] 自动扩缩容已配置并测试
- [ ] Database backups configured
- [ ] 数据库备份已配置
- [ ] CDN configured for content delivery
- [ ] CDN 已配置用于内容分发
- [ ] DDoS protection active
- [ ] DDoS 防护已启用
- [ ] Monitoring and alerting configured
- [ ] 监控与告警已配置

### Analytics and Monitoring
### 分析与监控
- [ ] Analytics pipeline verified and receiving data
- [ ] 分析管线已验证并正在接收数据
- [ ] Crash reporting active and dashboard accessible
- [ ] 崩溃报告已启用且仪表盘可访问
- [ ] Server monitoring dashboards live
- [ ] 服务器监控仪表盘已上线
- [ ] Key metrics tracked: DAU, session length, retention, crashes
- [ ] 关键指标已跟踪：DAU、会话时长、留存率、崩溃
- [ ] Alerts configured for critical thresholds
- [ ] 关键阈值已配置告警

---

## 6. Community and Marketing
## 6. 社区与市场营销

### Community Readiness
### 社区就绪
- [ ] Community guidelines published
- [ ] 社区准则已发布
- [ ] Moderation team briefed and tools ready
- [ ] 版主团队已通报且工具就绪
- [ ] Discord/forum/social channels set up
- [ ] Discord/论坛/社交渠道已建立
- [ ] FAQ and known issues page prepared
- [ ] FAQ 与已知问题页面已准备
- [ ] Support email/ticketing system active
- [ ] 支持邮箱/工单系统已启用

### Marketing
### 市场营销
- [ ] Launch trailer published
- [ ] 发布预告片已发布
- [ ] Press/influencer review keys distributed
- [ ] 媒体/意见领袖评测密钥已分发
- [ ] Social media launch posts scheduled
- [ ] 社交媒体发布贴文已排期
- [ ] Launch day blog post/dev update drafted
- [ ] 发布日博客/开发更新已起草
- [ ] Patch notes for launch version published
- [ ] 发布版本的补丁说明已发布

---

## 7. Operations
## 7. 运营

### Team Readiness
### 团队就绪
- [ ] On-call schedule set for first 72 hours post-launch
- [ ] 发布后前 72 小时的值班表已设定
- [ ] Incident response playbook reviewed by team
- [ ] 团队已评审事故响应手册
- [ ] Rollback plan documented and tested
- [ ] 回滚方案已记录并测试
- [ ] Hotfix pipeline tested (can ship emergency fix within 4 hours)
- [ ] 热修复管线已测试（可在 4 小时内发布紧急修复）
- [ ] Communication plan for launch issues (who posts, where, how fast)
- [ ] 发布问题沟通方案（谁发布、在哪里、多快）

### Day-One Plan
### 首日计划
- [ ] Day-one patch prepared (if needed)
- [ ] 首日补丁已准备（如需要）
- [ ] Server unlock/go-live procedure documented
- [ ] 服务器解锁/上线流程已记录
- [ ] Launch monitoring dashboard bookmarked by all leads
- [ ] 所有负责人均已收藏发布监控仪表盘
- [ ] War room/channel established for launch day
- [ ] 发布日作战室/频道已建立

---

## Go / No-Go Decision
## 上线/不上线决策

**Overall Status**: [READY / CONDITIONAL / NOT ASSESSED / NOT READY]
**总体状态**：[就绪 / 有条件就绪 / 未评估 / 未就绪]

First match wins: **NOT READY** if Blocking Items is not empty; else **NOT
ASSESSED** if any item is `- [?]`, any section came out `NOT ASSESSED`, or any
item is still unconfirmed — neither ticked on evidence or on a Phase 4b answer,
nor marked N/A, nor listed below (name each; group by section when there are
many); else **CONDITIONAL** if Conditional
Items is not empty; else **READY**. NOT ASSESSED outranks CONDITIONAL and READY —
an item nobody could check is not a passed one — and ranks below NOT READY, so a
known blocker is never buried behind it.
首先匹配者胜出：若“阻塞项”非空，则为 **NOT READY**；否则，若任一条目为 `- [?]`、任一章节结果为 `NOT ASSESSED`，或任一条目仍未确认 —— 既未依据证据勾选，也未依据 Phase 4b 的答复勾选，也未标记为 N/A，也未列在下方（逐一命名；数量多时按章节分组）—— 则为 **NOT
ASSESSED**；否则，若“有条件项”非空，则为 **CONDITIONAL**；否则为 **READY**。NOT ASSESSED 优先于 CONDITIONAL 和 READY ——
无人能检查的条目并非通过的条目 —— 且低于 NOT READY，因此已知的阻塞项永远不会被它掩盖。

### Blocking Items
### 阻塞项
[Every FAIL or unresolved finding: a check that found a problem — FIXMEs, debug
output, placeholder assets, hardcoded dev values, an open S1 bug, a failing
build or test — with no documented workaround and no explicitly accepted risk]
[每一项 FAIL 或未解决的发现：检查中发现问题 —— FIXME、调试输出、占位资产、硬编码开发值、未关闭的 S1 缺陷、失败的构建或测试 —— 且无记录的变通方案、无明确接受的风险]

### Conditional Items
### 有条件项
[Every shortfall with a documented workaround or an explicitly accepted risk —
e.g. a HACK with its documented justification, an S2 with a documented
exception (below `workflow: full`, which allows none). Name the workaround, or
who accepted the risk]
[每一项带有记录的变通方案或明确接受风险的不足 —— 例如带书面理由的 HACK、有记录例外的 S2（在 `workflow: full` 以下，该层级不允许任何例外）。注明变通方案，或由谁接受了风险]

### Sign-Offs Required
### 需要的签署确认
- [ ] Creative Director — Content and experience quality
- [ ] 创意总监 — 内容与体验质量
- [ ] Technical Director — Technical health and stability
- [ ] 技术总监 — 技术健康度与稳定性
- [ ] QA Lead — Quality and test coverage
- [ ] QA 负责人 — 质量与测试覆盖
- [ ] Producer — Schedule and overall readiness
- [ ] 制作人 — 排期与总体就绪度
- [ ] Release Manager — Build and deployment readiness
- [ ] 发布经理 — 构建与部署就绪度
