# D包整改与本人试玩反馈

2026-09-15。实现、回归与独立定向复审已完成，verdict为APPROVED WITH SUGGESTIONS，D总体验收仍OPEN，battle_ready=false。

## 真人反馈

[P00原始记录](package-d-2026-09-15/playtest/P00反馈.md)：本人自报玩完，明确喜欢关卡逐渐丰富；曾在撤离阶段求助。真人1、新玩家0。没有终局截图和逐关统计，不能写作人类8/8通关证据。

## 修改

- D-S01：Profile写入口绑定当前run的seed/loadout并调用Arena恢复语义验证；错误检查点不触碰双槽。错误页可重新加载上次可靠进度。
- D-S02：HUD限制两行加生命/悟性条；完整构筑和提示在暂停页可查看。中间240×240区域的18组窗口/语言/字号fixture均无HUD覆盖。
- D-S03：死亡tick两套elapsed同步，仍保持死亡优先于超时；死亡检查点保存、结算写失败、磁盘重建及一次性结算验证通过。
- D-S04：当前线索和已出现猎物共享导航目标；三条线索完成后显示追猎提示。
- 用户卡点：撤离开放后显示金圈、金箭头和方向/距离；已在圈内时提示走出再进入。

目录hash保持C包不变；无新增持久字段，未改成长曲线、关卡节奏或三阶段数值。

## 主线程证据

[证据目录](package-d-fix-2026-09-15)：D专项40/0；Root错误保存/退出/重新加载/继续通过；A135、B132、C237、Profile581、Content1170、Combat287、Root44、Snapshot299均通过。

Profile581是使用最小目录的存储事务测试，测试子类隔离Arena语义；真实Profile/Arena语义由D专项和连续旅程覆盖，不能用581条单独证明。

八关连续自动旅程8/8，46次真实磁盘重载，active278.37秒。Root专项原始脚本使用内存Storage，不能把它称为Root真实磁盘全旅程。

Mac图形18格：960×540、1280×720、1216×1108；中英文；100/115/130%；满构筑fixture。主线程已查看最小英文130%、撤离中文130%。该矩阵初始仅01静态布局；Boss/根区危险预警交由独立UI补测，不冒称覆盖。

## 未关闭范围

至少3名新玩家、Windows/Steam、正式Save v2、20小时主线体量仍未完成。XP/3秒升级间隔及任意窗口视野外生成是既有延期需求，本轮未动。旧D CHANGES REQUIRED报告保留，最终状态以后续独立结论为准。

## 最终独立裁决与交付

[资深综合](package-d-fix-2026-09-15/senior-report.md)：四项缺陷限定关闭，新玩家隔离持久档探索测试放行，D总仍OPEN。引擎补充真实Root容量错误双槽不变、玩家及护送物真实伤害/同tick自动保存/结算IO_ERROR/新Root磁盘恢复一次结算；UI补充18格生产双落点/跨HUD根区及实际错误恢复按钮操作。证据与原探针均已保留。非完整图形磁盘故障旅程或自然躲避证据。

新入口：[开始D修订版试玩.command](../../build/package-d-fix-2026-09-15/开始D修订版试玩.command)。支持持久保存，独立Spirit Nexus D Fix 20260915目录，不沿用旧P00临时档。旧包未改。

PCK SHA256：30c92b14fe0ba9df66fdbbda036e21fb869a1efe9841184ebdc989cc7cbab166。stage src/assets与工作树逐文件一致，仅project应用名隔离；PCK图形非validation真实双槽120tick保存、Root销毁重建后继续通过，测试创建的两个slot已删除，待试玩档为空。该测试不是跨进程强杀。来源和manifest不冒称PCK全文件独立反解审计。

复审后只更正350tick的注释，明确是validator而非roundtrip；归档engine探针并加入便携temp目录/清理/headless守卫的长期回归版本，两项再次执行通过。生产源代码未再修改。review-addendum.json记录差异；ADR/GDD/registry/session只补最终状态。路线检查26通过，git diff --check通过。
