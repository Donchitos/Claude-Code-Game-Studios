# 最终G包/G3增量独立QA

Verdict：APPROVED，限定最终G冻结下的G1/G2调度边界、G3 Boss阶段入口与相关恢复/奖励测试。未发现P0/P1/P2/P3确定性缺陷，无必改项。本结论不作为全量设计、全部存档故障组合或商业发布批准；新玩家SKIPPED_BY_USER，battle_ready=false。

## 冻结

最终source-freeze.json共68项逐文件重算匹配。catalog hash b4b4a50190f3bf99b182956bc79d0d98c31a3777077de800bd7f483c0a6c5cbc。G3仅通过boss_phase_entry_warning可选bool启用，Encounter valid_definition在83行限制bool及boss_chapter存在。读取最终Chapter、G专项、boss_entry专项、奖励夹具和C谓词夹具；项目文件未改。

## 实现与风险核对

campaign_chapter_one.gd:75–91：phase采用max保持单调，跨越每个阶段只发一次奖励；上升且flag开启才清timer，保存后的boss_phase使恢复不重复发奖。旧landings先按原due tick执行/移除，再决定是否发新预警。flag开启且仍有pending时直接等待，不新增重叠pending；既有最多2条的界限保持。最后一条旧landing排空当tick可以发布新阶段完整预警，并不意味着新攻击同tick落地。

新预警前保留zone容量preflight：phase2需4个槽（1 impact+3 root），phase1需2，phase0需1；不足时不增加attack/landing，timer已到期状态允许下次重试。跨0→2奖励发两份，但不会强制补打一套中间phase1攻击；此行为不承诺玩家必定体验全部阶段。Combat.advance_enemies跳过hp<=0敌人，已有Chapter.advance终态清landings，因此Boss死亡不等待延迟攻击，不因新flag延迟胜利。

## 独立执行

Godot4.7.1，命令均--headless --path . --script tests/integration/<suite>.gd -- --campaign-validation --evidence-root=/tmp/g-final-qa-f0nXCs。

- campaign_boss_entry_test：112 checks，0失败。phase1立即发54/84tick完整warning；进入phase2保持两条旧pending，恢复后100tick逐tick快照相等，第二条旧landing的tick85才发phase2新warning；满128 zone不发不可见attack，容量释放后重试，致死后立即victory且pending清空。
- campaign_pacing_rewards_test：17 checks，0失败。阶段奖励一次/跨两段两份/JSON恢复不重复以及XP容量合并等原断言保持。
- campaign_package_c_test：237 PASS。原半程predicate边界断言仍执行。
- campaign_package_g_test：58 PASS。包含02/07在tick89尚无第二stage第一个到期项，JSON恢复后tick90仅计一次且快照完全一致；普通/高进度通关与03/05分段验证仍通过。

四项独立日志均在/tmp/g-final-qa-f0nXCs/，文件名对应suite名加.log。没有重跑会覆盖历史证据的旧脚本。

## 测试变化是否弱化

奖励夹具make(7)先合法推进一个active tick后再造阶段伤害。这避免新行为立即发布attack时形成tick0但attack计数1的不合法历史；没有删除JSON恢复、奖励守恒、重复发奖等断言，也未修改production实现去兼容非法夹具。

C测试将stage深拷贝并显式设value1，保留half-before/half-exact/后续进度不反转的通用CLEANSE_HALF谓词测试。G2生产配置已采用value0/2，不能再把生产第二row当作value1；生产目录值与同圈stage触发通过G专项独立校验。该修改是分离通用谓词测试和新目录调度测试，并非停用失败断言。

作者boss-before.log为旧版阳性111 checks/5 failures，涉及立即warning、旧pending等待、容量重试；最终新增精确pending到期断言后112/0。此处只审核作者日志，不冒称本QA独立重跑了旧版本。

## 最终整包作者证据核对

读取最终两套正式磁盘journey结果与末尾PASS，均绑定b4b4...catalog：

| 路线 | 完成 | 恢复 | 逐tick对照 | active秒 | 各关选择 |
|---|---:|---:|---:|---:|---|
| 安全进化优先 | 8/8 | 77 | 13061 | 268.25 | [6,4,4,2,3,10,3,3] |
| alternate/risk | 8/8 | 74 | 12789 | 267.5833 | [5,3,3,2,3,11,3,3] |

这些最终旅程是作者执行、本QA读取审核；独立执行范围为上列四专项。合计151恢复和25850逐tick比对不能替代全部状态/故障切点/跨进程断电矩阵。非权威landing到期observer不能证明伤害命中或真人体验。旧F PCK升级拒读链路若由主线程实测，应按它自己的证据归属记录。
