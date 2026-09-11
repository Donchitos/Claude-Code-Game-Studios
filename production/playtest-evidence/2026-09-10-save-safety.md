# 存档失败与恢复增量

## 变化

- 仅两条路径都不存在时视为新档；存在文件但无有效槽时拒绝初始化，禁止提交覆盖。空路径仍为显式内存存档模式。
- 两槽同代而内容不同，返回CONFLICTING_SLOTS，不自行决定丢哪份。
- 按实际加载的active槽选择另一物理槽写入，不再用generation奇偶推断目标，保护单槽恢复来源。
- 写后验证完整payload SHA256；检查flush错误。IO/读回失败后锁住本实例写入，不更新内存profile，不自动重复提交。重启时重新读取实际磁盘状态。
- 增加整数计数的类型/有限性/整数性/JSON安全范围检查。
- GameRoot加载、购买和结算存档失败进入停止操作状态，显示备份存档目录和关闭重启提示；不自动删除、重置或宣称本次已保存。

## 验证与限制

Godot 4.7.1 save_system_test通过：正常双槽、最新损坏回退、恢复后写入、偶数代移到A仍保留该槽、双槽损坏保留原字节、写失败不发布/禁止重试、同代错误hash读回拒绝、文件已写但校验失败后重启加载一次结果、同代冲突拒绝。所有磁盘故障夹具仅使用唯一临时路径并清理测试文件，未改真实用户档案。

home_progression_test与long_run_test通过，覆盖正常购买、下局投影、长局收入与Boss结算。git diff --check通过。FaultNotice已实现但未做图形布局/真人验收。

本轮仍是同步JSON基础层：不具备完整binary codec、跨进程互斥/CAS、事务reservation/reconcile ABI、目录fsync/断电保证、kill-point矩阵或完整domain语义校验。文件不可访问与路径权限错误仍需更细分类；不能宣称绝不丢档。In Review / Re-review Pending，battle_ready=false。
