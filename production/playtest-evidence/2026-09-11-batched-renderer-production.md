# 几何批量绘制正式接入

## 决策

正式Stage为普通敌人与友方飞剑启用固定容量`MultiMeshInstance2D`几何批次。几何直接复现原`draw_circle`与Godot 4.7.1无羽化`draw_line`的三角形，不使用预渲染纹理，因此没有二次纹理采样、alpha贴图合成或像素对齐漂移。甲虫/召唤物与狼共享一个按原数组顺序提交的敌人批次，类型由`INSTANCE_CUSTOM`选择；飞剑按velocity旋转。Boss存在时敌人退回原逐项绘制，以保留Boss血条和敌人遮挡顺序，友方飞剑仍批量绘制。

`assets/config/production_defaults.json`中的`rendering.geometry_batch_enabled=true`是生产默认值；Stage仍保留运行时false路径用于A/B像素验证。可见范围剔除先于实例上传，碰撞、HP、Grid、Pool、生命周期和存档均未改变。

## 视觉验证

`batched_renderer_visual_test.gd`覆盖甲虫、狼、召唤物、12个飞剑角度，以及0.75/1/1.25缩放；参考Canvas primitive与几何批次逐像素完全一致：changed_pixels=0。

`dense_batch_probe.gd`直接切换正式Stage旧/新路径。三种布局均为319敌人、392飞剑、30帧预热、180帧采样，无模拟和存档：

| 布局 | 旧/新帧均值 ms | 旧/新Stage draw CPU均值 ms | 最大通道差 | 差值>1像素 |
| --- | --- | --- | --- | --- |
| spread | 18.445 / 2.150 | 3.672 / 0.576 | 1 | 0 |
| overlap | 18.479 / 2.381 | 3.645 / 0.644 | 1 | 0 |
| mixed_types | 16.553 / 2.846 | 2.907 / 0.585 | 1 | 0 |

最大1级通道差来自相同半透明几何经不同提交路径的取整；没有任何像素差超过1。参考图、候选图和缩放/旋转图已实际查看，未见结构、颜色、阴影或遮挡差异。

## 生产性能复测

Apple M4、macOS、Godot 4.7.1 Compatibility、1280×720，每场景120帧预热+600帧采样：

| 场景 | 帧间隔P95 ms | 模拟P95 ms | 超16.67ms模拟帧 |
| --- | --- | --- | --- |
| ordinary | 13.862 | 0.166 | 0/600 |
| capacity_stress | 10.398 | 4.572 | 0/600 |
| boss_phase2 | 13.912 | 0.170 | 0/600 |
| capacity_stress_dense | 14.753 | 7.031 | 0/600 |

新增dense场景把约390枚友方飞剑布置在屏内并以16方向运动，和319敌人一起走正式Grid候选与精确扫掠；图形P99为22.910ms，因此这里只判定当前Mac基线P95通过，不宣称无尖峰或所有平台稳定60FPS。

分段容量压力复测：帧间隔P95 10.326ms，Stage draw CPU均值0.429ms/P95 0.443ms；上一轮只做剔除时分别为18.041ms和2.310ms。

## 回归与边界

22个`tests/integration/*_test.gd`在headless全部exit 0；其中图形专属测试在headless明确skip。macOS图形环境另外通过batched renderer视觉、macOS输入/UI、draw culling三场景与Save fault surface四项检查。Save fault的错误日志是预期注入。

这是当前Apple M4/OpenGL Compatibility运行证据。Windows release交叉导出已经完成，但仍没有Windows/D3D12运行、独立显卡、Steam Deck、min-spec、thermal、正式美术或长时P99验收。`battle_ready=false`。
