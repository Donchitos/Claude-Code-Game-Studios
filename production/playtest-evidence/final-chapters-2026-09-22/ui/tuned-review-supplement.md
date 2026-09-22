# 后五章 UI 调参补充复核

结论：维持 APPROVED WITH SUGGESTIONS，未发现调参新增 UI 阻断。catalog SHA256: abc5f36fd15ea1f7623b4fdf46edd035056ff18f413b97e2bac4410708f86b96

仅重跑 M05-08、M07-08、M08-07 三个实际 Mac Godot 4.7.1 GUI 夹具，1280×720、130%字体；逐张打开 tuned-39-en-1280.png、tuned-55-en-1280.png、tuned-62-zh-CN-1280.png 核查。M05-08 俯冲预警带随半宽55→28相应缩窄，三条平行线及中间通行间隔明确；其渲染仍读取 zone.radius，伤害判定亦读取同半径。M07-08 环形44px危险带与空心区域保持一致，M08-07 向内交叉线及交点明确，教学内容仍匹配。

本次截图为预警瞬间，只证明调参后的几何与可读性；120 tick预警和240 tick冷却的持续时间来自配置/逻辑核对，不以静止截图代替时间运行验证。dive cooldown210同理。其余UI矩阵没有重复运行，渲染逻辑、布局、提示未改。夹具仍强制 --campaign-validation、合法初始任务后 Arena.configure，明确摆放状态，只使用内存存档，不计自然通关。源码哈希见 tuned-reviewed-sha256.json。
