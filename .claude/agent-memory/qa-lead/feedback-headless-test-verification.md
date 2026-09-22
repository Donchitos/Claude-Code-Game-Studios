---
name: feedback-headless-test-verification
description: headless Godot 测试核验纪律——assert 不中止必须 grep SCRIPT ERROR；terminal-disk 必须带 --campaign-validation
metadata:
  type: feedback
---

本项目的 headless Godot 测试核验必须独立执行 `grep -c "SCRIPT ERROR"`，不能只看 exit code 与 PASS 字符串：headless 下 assert 失败不中止脚本（campaign_terminal_disk_test.gd L38 的参数 assert 就是例子——不带 `--campaign-validation` 运行会打出 SCRIPT ERROR 后继续跑完，exit 0 且可能打印 PASS，但按项目纪律该输出不可采信）。

**Why:** 2026-09-17 ch3 复核时发现主线程曾以无参数方式后台跑 campaign_terminal_disk_test，且旧实例进程消失无日志留存；ch2 QA 报告也有先例表述"exit0但有ERROR的日志不算最终通过"。

**How to apply:** 任何 suite 复核或引用回归结果时：exit code、SCRIPT ERROR 计数、PASS 标记三者齐备才算通过；引用他人跑的结果时确认其命令行参数完整（terminal-disk 需 `-- --campaign-validation`）。长测试（journey、terminal-disk timeout 模式）放后台跑，避免前台超时被杀丢证据。相关冻结状态见 [[project-ch3-qa-freeze-gate]]。
