# 第三章 Codex Godot/UI 最终独立复验

限定verdict：APPROVED。仅当前冻结第三章增量的Godot架构/渲染/UI，既有UI阻塞已关闭，无新增需修复项。不是完整游戏或发布批准。

## 最终身份

production/playtest-evidence/chapter-three-2026-09-17/source-freeze.json，共162项，运行前后逐文件SHA256全匹配。最终隔离核对发现一项差异：src/campaign/campaign_profile.gd仍为缺CHAPTER_TWO_CONTENT_HASH常量及旧档路由列表条目的副本；其余清单src/assets/tests全部匹配。已读取该两行功能差异，仅影响旧第二章活动档的错误路由，当前新空validation profile图形路径未触及，故不影响本UI范围批准；本次GUI不得称完整冻结包运行或旧包兼容证据。应用名独立且--campaign-validation，未触碰玩家存档。

catalog：6cea8186b024592bf3edb298df02400964c246eeab4cb6e475afdbfd3a8fe35a。
渲染仍为已审2075d1589dda69856aff6e9d6c4574c5141d263283e6ca2fbff11c0b497cef95。
最终输入完整清单/tmp/ch3-codex-ui-final-input-hashes.json。

## 最终复跑

- /tmp/ch3-codex-ui-final-probe.gd、/tmp/ch3-codex-ui-final.log，真实Mac Godot4.7.1 Apple M4 Compatibility，960×540，briefing130%字号，退出0，CH3_UI_PROBE_PASS。
- /tmp/ch3-codex-ui-final-mechanics.log，当前冻结campaign_chapter_three_test.gd独立执行，退出0，1713 PASS；替代首轮1710，不沿用草稿1711。
- 最终GUI进程已结束，可由主线程执行独立实际PCK GUI验证。

## 修复复核与架构

潮墙锚点y=-625、长度1250、方向PI/2，墙段贯通正负半场；最终两侧墙/phase2环池截图仍可见齿间通道。颜色取zone创作色，潮池蓝、第二章热区橙；warning刻线/浅填充与active粗环/深填充有可见差异。渡船木船体及撑篙与中文渡船/英文ferry语义一致。旧harbor越界结论是把half_size再次除2产生的误报，实际中心(-380,340)半径80处于±640内。

Encounter无同flat存活zone才重发，最终ChapterThree.valid_state:77–83还拒绝重复flat；500tick守卫包含在最终1713通过项。永久淹没取消休潮但保留预警，不能把zone连续存在说成每tick都伤害。

新增ChapterThree.boss_damage:20在伤害边界提交阶段/XP而不发射攻击；boss:38先校验12颗projectile容量后才发布此轮，未绕过原完整警告。已阅读差异并在最终Arena/ChapterThree/Encounter/Render上复跑；Profile例外如上明确记录。M03-07目录调参仅改变有限后排名额/时序，不新增渲染/生命周期owner，其平衡结论由路线/QA证据单独裁决。

中英月牙可驻留、拆印后警告期离开、护送涨水时离队、默认提前离开说明与当前实现一致。M03-06默认教学虽只强调潮池，场景确有潮池、briefing补充喷流/潜鳍，可接受。

## 最终截图

/tmp/ch3-codex-ui-final-m24-wall-warn-p1.png
/tmp/ch3-codex-ui-final-m24-wall-active-p1.png
/tmp/ch3-codex-ui-final-m24-wall-active-p2.png
/tmp/ch3-codex-ui-final-m17-pool-warn.png
/tmp/ch3-codex-ui-final-m17-pool-active.png
/tmp/ch3-codex-ui-final-ferry.png
/tmp/ch3-codex-ui-final-ch2-orange.png
/tmp/ch3-codex-ui-final-brief-en-24.png
/tmp/ch3-codex-ui-final-brief-zh-CN-21.png

最终已再目视phase2全高墙、船形与英文长briefing；同hash Render先前完整目视记录见/tmp/ch3-codex-ui-review.md。所有截图是直接configure、指定位置/tick/zone与相机的呈现夹具，不冒称自然战斗、合法解锁、真实恢复或PCK图形证据。旧脚本净化任务索引错误已在小窗及最终脚本改为missions[19]（全局20），文件名m19不作为ID证据。

## 边界

项目文件零编辑。新玩家SKIPPED_BY_USER，battle_ready=false。不推导Windows/Steam、SaveV2、20小时、完整性能或最终发行验收；待主线程合并其他独立专家、最终路线及实际PCK证据。
