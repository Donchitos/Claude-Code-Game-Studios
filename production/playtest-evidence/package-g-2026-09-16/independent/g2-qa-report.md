# G2限定独立QA

Verdict：APPROVED，仅限G2调度目录、G专项和非权威observer增量。无已证实P0/P1/P2/P3缺陷，无必改项，可继续按序G3。不批准后续未审实现或商业发布。新玩家SKIPPED_BY_USER；battle_ready=false。

## 冻结与实现

g2-freeze.json五项独立重算全部匹配，结束前再次验证亦无变化。目录SHA256 aaa6f439ff53eb5f8aba1da3cc77b96fef3e4acd70841a78ac1e9a86d136c196。基线使用g1-catalog.json。03三stage WAYPOINT value0/2/3，计划数量8/12/12共32，所有row interval45；05四stage CLEANSE_HALF value0/0/2/2，每圈两stage对应row offset相差30 tick，interval45，hold_seconds=6.6保持。

03的WAYPOINT0在初始化时已达到，stage_ticks[0]=0，满足Encounter.valid_state的非CLEANSE_HALF零value必须trigger0规则；后两段在waypoint2/3分别触发。05的CLEANSE_HALF0必须真正开始hold才达到，因此允许非零trigger tick，符合已有validator显式例外。05同圈两个stage共享触发tick，差别是各row的offset，不能宣称四个独立的净化进度阶段。

## 独立执行

Godot4.7.1。运行均带--campaign-validation --evidence-root=/tmp/g2-qa-phoEgu，未改项目或历史证据。

- campaign_package_g_test.gd：48 PASS。02/07普通与高进度回归保持；03/05新增自然通关并终态快照valid，03第一tick仅初始stage激活，后两stage时间递增；05同圈配对stage同时激活、下一圈更晚。
- 正式安全进化优先磁盘journey（--qa-production-evolution）：8/8；77次真实磁盘重建恢复，12910次逐tick完整快照/RNG相等断言，268.20 active秒。选择次数[6,4,4,2,3,10,3,3]；06自然S1-V01。没有软锁、恢复校验失败或比对失败。
- 本轮未重复全套或另一条完整磁盘journey。以上结果是本QA执行；作者两路线audit另以读取审阅方式核对。

证据：
- /tmp/g2-qa-phoEgu/g.log
- /tmp/g2-qa-phoEgu/journey.log
- /tmp/g2-qa-phoEgu/aaa6f439ff53/journey-e/1789548637-35508-174732/journey.json

## 作者阶段遥测与observer解释

读取g2-final两路线g-pacing-audit.json。03两路线均20.1833秒，三段触发0/6.15/13.7167秒，8/12/12计划均完成尝试。05安全路线17.7833秒，触发0.9333/0.9333/11.1833/11.1833秒；风险路线17.15秒，触发0.9333/0.9333/10.55/10.55秒；四stage各10名额均完成尝试。attempted包含被跳过的生成尝试，不能等同全部成功生成。

campaign_package_g_audit.gd新增观察在advance前复制旧landings、advance后读取新状态：hunt_phases是存活目标phase变化记录；boss_warnings是首次看见持久landing记录时的phase归类；boss_observed_landings仅统计旧记录到期且Boss步后仍活着。它不写模拟状态，不调用额外RNG，scope明确排除致命tick歧义。可用于比较警告/到期序列，不能当作命中、真实落点执行回执、伤害权威或保证每个阶段玩家完整体验。静态读取未发现该observer修改模拟的路径。

恢复结论仅覆盖上述77个采样点及最多200tick前瞻窗口，不代表所有组合、完整IO/断电矩阵或真人体验；G3改变Boss运行源码后需重新冻结并独立核验，不继承本轮G2结论。
