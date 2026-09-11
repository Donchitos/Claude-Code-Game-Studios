# 存档进程结束、错误提示与Windows打包准备

## 1. 真实进程结束恢复

`save_crash_test.gd`创建唯一临时双槽档案并提交旧结果，然后启动`save_crash_worker.gd`子进程。子进程沿生产Save写入路径，在无操作的可覆写checkpoint处调用OS.kill结束自身。没有复制一套测试专用写入算法，没有结束编辑器或用户游戏进程。

macOS / Godot 4.7.1结果（5个子进程exit137）：

| 切点 | 恢复代数 |
| --- | --- |
| before_open | 1 |
| after_open | 1 |
| after_store | 1 |
| after_flush | 2 |
| after_readback | 2 |

所有case验证旧有效槽字节不变、旧或新完整结果、不出现重复运行数、domain marker与汇总字段同代。生成的测试文件和空临时目录已清理。after_store允许旧/新两种完整结果，本次观察为旧。不是断电、磁盘缓存丢失、Windows证据或完整kill-point矩阵。

## 2. 错误提示

`save_fault_surface_test.gd`使用内存档案，注入SAVE_COMMIT_FAILED，验证拒绝开局/购买并渲染1280×720截图。首次截图揭示提示层未正确展示；修正Control在add_child之后设置全屏布局并提高z_index。第二次`save-fault-preview.png`已查看，文字/存档目录可见。日志中的CONTROLLED_FAULT是此夹具预期注入，不是正常回归错误。

## 3. Windows内部资源包

本地export_presets.cfg保留已有iOS配置，追加Windows Internal；版本副本在production/windows-internal-preset.cfg。仅内部测试，不签名，不改已有工作名，不代表原创IP清理或Steam上架完成。

首次只选择GameRoot资源的PCK独立启动漏依赖，已改为all_resources并排除tests/production/design/docs/prototypes/.claude及Markdown。PCK成功生成于build/windows-internal/TrialInternal.pck。导出Windows exe实际失败：本机4.7.1.stable模板目录仅有ios.zip，缺windows_debug_x86_64.exe/windows_release_x86_64.exe；必须安装匹配模板后重试。Windows实机还需单独安排。

资源包是数据文件，不能直接作为Windows游戏运行。源码目录之外的PCK启动/高HP自动烟测已PASS：generation=2、level=25、kills=1505、seconds=733.60。此项属于本机Godot验证，不是Windows平台验收。PCK SHA256：1fbc2e37aa1ff2e6152d4268844916e3e4dcda2f0d3b13c70f4639ad8655febb。

save_system_test与production_lifecycle_test回归通过；git diff --check通过。

保留In Review / Re-review Pending，battle_ready=false。跨进程写锁、断电恢复、正式Save ABI、Windows性能和真实输入体验仍OPEN。
