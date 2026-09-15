# 独立 QA 与增量结果归档

来源：本轮实际启动的 schema_qa_review 及后续增量任务；由协调者据真实报告归档。

结论：TESTABLE / APPROVED WITH SUGGESTIONS，无新增阻断项。最终覆盖两GDScript模块、单元/集成测试、三个Python工具、三份机器schema和两份合成fixture。

最终独立执行Godot 4.7.1单元82/82、集成104/104、Python结构检查70通过。独立整数oracle的52,001个u63样本与生成regex一致；两个domain的properties/required与GDScript常量一致。完整前缀、最终ending、初始化生命周期、非法UTF8探针已纳入正式测试。

Python canonical与hashlib独立生成golden，没有用Godot输出回填。QA初步怀疑排序正向golden不足；在隔离副本删除keys.sort()后，现有unit成功抓到非规范顺序被放行，因此未把它列为阻断。作者仍新增逆序嵌套golden增强正向oracle。

最终非阻断建议：Python checker比较GDScript fields与手写payload，而不是直接对照schema properties/required。作者已将断言改为四者同时相等，并复跑70检查通过；此最终测试断言强化由作者执行，不声称又独立重审。

结构schema通过不等于语义图/hash/grant/终局通过，更不等于生产可用。U+0000、其他五域、真实Mission定义、v2事务、Windows与预算仍在既定边界之外。QA未修改主文件。
