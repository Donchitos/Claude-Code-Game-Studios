# PC 输入整改前后性能 A/B 与 Windows 收证检查

## 结果

本次同机、同夹具交错对照**没有复现 PC 输入整改导致整帧性能明显退步**。默认 VSync 下旧版也出现 P95=29.767ms，不能仅凭历史 14.753ms 与 29.838ms 两次记录归因于 Input。

关闭 VSync 后两版帧间隔下降，模拟耗时基本相同，说明当前测量对显示同步/帧调度敏感。此结果不能确定历史两次运行差异的唯一原因，也不能把帧等待解释为纯 GPU 耗时。未修改生产 VSync、战斗数值或渲染路径。

## 正式实验

- A：提交 `e45f1350757bb8e217199444fe4adff51217e570`；B：当前未提交 PC 输入整改的冻结副本。
- 两个独立临时项目，共用 Godot `4.7.1.stable.official.a13da4feb`、Apple M4、macOS、`gl_compatibility`、1280×720、seed101、临时内存档案。
- Stage/渲染代码及战斗配置相同；差异为六个既有文件中的 PC 整改与三个新增输入类及UID。完整hash、当前源码快照、公共probe与原始JSON/日志保存在 `pc-input-ab-2026-09-11/`。
- 每轮120 tick预热、600模拟样本、599帧间隔样本；319敌人、390友弹峰值，固定每帧补齐密集夹具，填充在计时段外。两个版本都调用完整 `battle.run_tick(1/60,tick+1)`，确保旧版外层Input与新版内部Input均被测到。
- 默认VSync=1与诊断VSync=0各按 A→B→B→A→A→B 顺序，合计12次正式运行，每条件每版本3次。没有同时运行多个benchmark或导出任务。
- 两个原有Godot进程（原型编辑器与先前headless测试）保留，PID及CPU快照已记录。因此是同机交错对照，不是干净系统、锁频或无后台进程实验。
- 公共probe SHA256：`79037a870e474a6dcf67cfa8b061e6120f32bc3747ffbe65fd81a04ab5c63685`。

下表为**各轮百分位的中位数**，不是将三轮样本合并后的总体百分位。括号为三轮最小–最大值，单位ms。

| 条件 | 版本 | 模拟P95中位数 | 帧间隔P95中位数（范围） | 帧间隔P99中位数（范围） |
| --- | --- | --- | --- | --- |
| 默认VSync | A旧版 | 6.974 | 20.579（19.817–29.767） | 32.638（31.099–33.305） |
| 默认VSync | B当前 | 6.985 | 19.785（19.776–20.610） | 30.719（29.701–32.652） |
| 关闭VSync | A旧版 | 6.982 | 15.708（15.666–16.123） | 16.771（16.720–16.838） |
| 关闭VSync | B当前 | 6.946 | 15.991（14.852–16.096） | 16.633（16.332–16.913） |

12次运行均完成、每轮600个模拟样本中超过16.67ms的数量均为0。默认VSync帧间隔P95/P99仍未过门；关闭VSync也有P99尖峰，不能宣布稳定60FPS、min-spec或长时性能通过。三轮规模不支持统计等价/显著优于旧版结论。

首次探索复用了历史gameplay-only探针，默认/关闭VSync共12次；发现旧输入采样位于该入口外、新输入位于入口内后，改用上述完整tick并重跑全部正式实验。探索数据单独保存在 `exploratory-gameplay-only-*`，**不混入正式表**。公共probe仅增加元数据、原始数组和完整tick入口，未改变战斗夹具。

## 可复现性

证据目录中的 `baseline-source-hashes.json`、`current-source-hashes.json` 绑定资源与源码；`current-snapshot/`保留B的src、config及project.godot，未变二进制资源来自A提交。`performance_probe.gd`为两版相同诊断脚本；`run_pc_input_ab.py`支持第二个参数指定包含baseline/current的目录。

重建方式：把上述提交的 `src/ assets/ project.godot` 分别导出至两个隔离项目，将 `current-snapshot/`覆盖到B；向两边 `tests/integration/performance_probe.gd`复制公共probe，并创建 `production/playtest-evidence/`。然后运行：

```text
python3 run_pc_input_ab.py default /absolute/path/to/isolated-pair
python3 run_pc_input_ab.py no-vsync /absolute/path/to/isolated-pair
```

runner使用本次Mac的Godot可执行路径；其它机器需明确修改并记录引擎/平台差异。原始JSON保留实际命令和当时临时目录路径，归档文件才是持久证据。运行阶段会弹出测试窗口；测试使用内存档案。

## 第三步：Windows 收证检查

当前可访问主机为Darwin/arm64，没有wine、wine64或pwsh，未取得Windows实机或物理控制器会话。本轮W01–W14全部保持 **NOT_RUN**，PowerShell在目标系统的执行也未验证。

已有 `build/windows-pc-input/windows-pc-input-validation.zip` CRC完整性通过，内含EXE/PCK/PowerShell/检查表；四项内容逐字节或SHA256均与当前独立文件一致。

| 产物 | SHA256 |
| --- | --- |
| EXE | `4e5e07b73a38be1452888ba41c0a7a8729abe601cbf47aca726857b524a79404` |
| PCK | `eacc9a9204a87b69215b53f13d014e1a4ae24a8c930c0d475d21eda653233d94` |
| ZIP | `989c87773c18671cf1871a7b2179db878b3e590736c03d1779eefd62815a37e6` |

机读记录：`2026-09-11-windows-input-delivery-check.json`。检查包完整性不表示Windows可运行或物理输入通过。包对应本轮已发现两个P1的既有实现，可用于收证，不能作为已验收发行包。

## 当前下一步

优先处理独立复审R1恢复重入、R2 modal焦点，以及同报告R3–R8的合同/反馈/覆盖问题，再重跑有针对性的回归与独立复审。不要基于旧14.753→29.838ms记录直接修改Input性能实现。Windows设备可用后仍需完成W01–W14、完整局和独立低配/长时性能门。`battle_ready=false`。
