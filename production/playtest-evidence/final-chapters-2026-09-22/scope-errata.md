# 临时探针 scope 文本勘误

原始JSON/脚本保留未覆写，以下优先解释实际执行配置。

- sweep.json/sweep-initial.json：正式 campaign_late_sweep，C01、三脉0/0/0、处方解锁数、固定711/977/1345899233，稳妥事件，40×3，独立任务夹具。
- alt-sweep-before-tuning.json / alt-sweep.json：临时脚本从上项复制，scope/comment错误沿用了zero-growth C01字样。实际为C03，三脉按任务解锁数取3/4/5、固定2228242853/197682660/977、稳妥事件，--alternate-build选择。传入--risk-route但这个临时脚本choose_event(false)，故不是风险路线。分别94/120与99/120，不能算新档真实成长。
- regional-tail.json：同一临时夹具继承上述scope文本，实际为第48至64关的本章解锁角色C06/C07/C08，三脉4/5、使用既有安全旅程逐关实际seed、风险事件；结果14/17。
- regional-prepared.json：第57至64关C08/三脉5/风险事件，CLEANSE/BREAK/SURVIVE loadout指定PREP08，结果8/8；这项仅验证战斗，未证明药材来源。真正消费药材/库存的证据只认full_journey --regional-build --risk-route --prepared-route。

最终完整旅程每行记录character、branches、pill_id、herbs_remaining、run_seed，使用Profile正式接口，不受上列临时scope文字影响。任何自动玩家数据均非真人试玩。
