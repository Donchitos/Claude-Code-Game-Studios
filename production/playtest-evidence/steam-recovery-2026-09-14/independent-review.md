# WP04c 独立代码复核汇总 — 2026-09-14

本文件由实施主线程归档真实独立审查结果，不冒充 fresh creative-director full design verdict。两位审查者以独立上下文并行启动，之后分别增量复验已报问题；无审查者直接修改仓库。

## Godot/GDScript 与主引擎专项

Agent `01a09f05-cc46-78e2-9fdf-15a4a6d881f6`，最终限定 verdict **APPROVED**。

三项 P2 全部关闭：错误 metadata 类型（如 binding=[]）曾导致脚本异常/空结果；Node provider 释放后 Callable 失效；注册 owner schema 2 被 Save 结构层固定 schema1 拒绝。独立修复复验确认明确拒绝、生命周期守卫及版本2完整接线。

引擎专项最终执行 integration154/0、unit34/0、旧domains95/0、独立Complete/旧版本21/0与原类型/释放/绑定/版本probes；7进程exit0，SCRIPT ERROR及ERROR日志均0。五份生成schema逐字节一致。原始日志、probe文本和审查哈希见 `independent-engine/`。之后唯一代码相关变更为QA要求的两个字符串key测试修正与path断言，最终156checks，由QA复验；实现文件未再修改。

## QA 专项

Agent `01a09f05-ccd5-7e52-8805-dee57327c4d0`，最终限定 verdict **APPROVED**。

关闭：Preparation 在快照预检之前调用且能修改输入（P1）；畸形Preparation返回导致脚本异常（P2）；负例被预算拒绝遮蔽（P2）；legacy负例未真正消费snapshot语义（P2）。后续还识别 `.extra` 新增StringName键会被codec提前拒绝，改为 `["extra"]` String键并断言具体path，关闭最后P2。

QA确认旧Preparation修复/返回协议/副本隔离、完整RESULT_PENDING的Complete协议、legacy constant-OK mutant、preflight删除、副本隔离删除、返回类型与生命周期守卫回退均能被测试检出。最终仅重复最后两个mutant：baseline156/0；删除checkpoint字段闭合=3 failures/exit1；删除payload字段闭合=3 failures/exit1，均无脚本异常。原始结果见 `independent-qa/`。

## 共同批准边界

仅 **TEST_ONLY / LEGACY_ADAPTER_ONLY 可信配置相对的恢复合同及Save校验接线**。不批准完整商业owner、Mission runtime、Save v2磁盘事务、商业容量/性能或Windows验证。整个WP04保持PARTIAL，battle_ready=false。
