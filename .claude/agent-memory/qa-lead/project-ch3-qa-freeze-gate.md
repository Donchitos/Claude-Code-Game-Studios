---
name: project-ch3-qa-freeze-gate
description: 第三章（涨潮）2026-09-17 QA 复核 verdict 与冻结门未闭合项（journey 两路线）
metadata:
  type: project
---

第三章（S1-M03-01..08）独立 QA 复核（2026-09-17，production/playtest-evidence/chapter-three-2026-09-17/qa-review.md）verdict 为 APPROVED WITH SUGGESTIONS，但源码冻结有两个未闭合门：journey 安全路线（seed 711）与 alternate 路线（seed 977）。主线程 12:24 启动的安全路线实例被外部终止且未产出任何结果；qa-lead 已用 --evidence-root=/tmp/ch3-qa-journey 重启独立执行。terminal-disk（--campaign-validation，victory tick4490 / timeout tick22801）与 precision-roundtrip 已由 qa-lead 补跑 PASS。

**Why:** ADR-0011 Acceptance Criteria 明确要求"真实1→24两路线"作为验收项；journey 是 AC 必需项而非可选回归。alternate 路线启动时必须同时传 `--alternate-build` 与 `--risk-route`（两开关独立，漏传则 M03-03 机缘风险分支零覆盖）。

**How to apply:** 后续会话涉及第三章冻结/交付时，先确认 /tmp/ch3-qa-journey 与主 evidence 目录下 journey-chapter-three 的 journey.json 已落盘且 CHAPTER_THREE_JOURNEY_PASS，再执行冻结 hash 记录。相关纪律见 [[feedback-headless-test-verification]]。
