# 第二章最终冻结 Godot架构/UI独立评审

最终限定verdict：APPROVED。范围仅ADR-0010第二章增量的Godot架构/UI；无剩余P0/P1/P2/P3问题。不继承旧G/F批准。

## 最终身份

冻结：production/playtest-evidence/chapter-two-2026-09-16/source-freeze.json，75项。GUI运行前后逐文件SHA256均匹配，mismatches=[]。
目录SHA256：7a6edddb768b4bb813bc52bd0fd334269ebeee7a6228ac55ac0806704801420f。
Render SHA256：9b55b6bedb9e16ec5c1e0a619735ea80371f0b0bbacfac1ffb780a264de5ab95，与炉门修复后已审版本一致。

## 独立问题闭环

首轮P2“炉门先于Boss主体绘制而被完全遮盖”已修复：Render:206–209将门态标记画在主体之后。之前关闭/打开外观相同的截图在/tmp/ch2-ui-before-door-fix/；修复后真实Mac图形显示灰门中缝与亮黄炉心两态，且HUD一致。已复核关闭。

首轮非阻塞公开helper文档建议也已关闭：ChapterTwo全文复读，vent_closed/door_open/hunt_damage/valid_definition/valid_state/teaching均有对应doc comment。

## 最终真实图形证据

独立探针/tmp/ch2-ui-final-probe.gd，日志/tmp/ch2-ui-final-probe.log；Godot4.7.1、Apple M4 Compatibility，--campaign-validation，退出0，CH2_UI_PROBE_PASS。

960×540物理窗口、130%字号：12狩猎8XP和16Boss18XP最新中英文briefing完整自动换行，无目标卡片文字截断或横向溢出；四张最终截图已逐张目视：
- /tmp/ch2-ui-final-zh-CN-12.png
- /tmp/ch2-ui-final-en-12.png
- /tmp/ch2-ui-final-zh-CN-16.png
- /tmp/ch2-ui-final-en-16.png

最终探针同时重新生成冷却匣/炉工及炉门开闭中英HUD：/tmp/ch2-ui-final-{zh-CN,en}-hud-{11,14}-0.png及...-hud-16-{0,180}.png。护送身份仍分别为蓝色矩形/人形，中文HP目标名称与英文教学名称正确。此前/tmp/ch2-ui-review.md记录全章09–16共16张briefing检查，此次只重跑改变的文案及关键HUD。

探针为定向呈现夹具：临时取消锁定卡片disabled以聚焦滚动，不激活，不修改profile解锁；HUD通过直接configure及指定位置/tick、刷新镜头建立截图状态，不声称自然解锁、相机通知链、磁盘恢复或真人体验。正式Root/UI与G staging未改；该夹具不替代主线程即将执行的实际PCK保存/重建继续验证。

## 架构与限定

ChapterTwo为RefCounted helper，无新增Node/process计时owner。炉门由权威tick推导、喷口关闭由目标identity推导，Renderer/HUD只读；Boss发射检查容量并沿用带delay的zone呈现，阶段经验仍经原可见pickup链，未建立UI奖励账本。新schema/content hash区分章域行为。数值/全恢复/全路线另由GDScript与QA专家裁决。

本评审不写项目，只在/tmp生成证据。新玩家SKIPPED_BY_USER；Windows/Steam、SaveV2、20小时、完整性能及发行验收均不在批准范围，battle_ready=false。
