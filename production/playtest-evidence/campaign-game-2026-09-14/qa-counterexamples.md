# QA test-first contract

独立写集仅两个integration脚本及qa-*。遵循team-combat Phase 5；用户已授权实现，QA不重新请求阶段批准。

1. 六类目标必须经configure/advance/movement/choose真实改变状态至胜利；专用低HP/短时配置不得作为生产平衡、64任务通关、20小时时长证据。禁止直接写finished/victory/objective造结果。
2. 远离撤离/净化区域不得仅因时钟完成目标；护送须实际同行。
3. pending upgrade/event时重复advance不得改变snapshot任意字段（含RNG/pending）；非法选择同样零效果。
4. JSON snapshot恢复必须从完整状态继续，随后200tick同输入/选择逐tick相等，且tick实际增长。
5. content hash/mission/RNG错误、必要状态缺失、非有限/非法数值、槽位/等级溢出应原子拒绝，不能静默新开run。
6. 实际任务胜利交给profile/root结算，next解锁；重复finish不增加奖励；真实双槽磁盘关闭再读保持pendingchoice和RNG。
7. 构筑通过真实level/draft，检查4+4与5级上限；进化须实际消费条件并改变战斗；24mode名字及24stat名字不是效果完成证明。

初始读取发现Arena _step/_choose_upgrade/_choose_event/_valid_saved暂为stub，属于并行落盘中；探针先落盘，继续执行与适配，不把暂缺模块当最终BLOCKED。
