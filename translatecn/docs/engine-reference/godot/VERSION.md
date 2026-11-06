# Godot Engine — Version Reference
# Godot 引擎 — 版本参考

| Field | Value |
|-------|-------|
| **Engine Version** | Godot 4.7 |
| **Installed at pin time** | NOT DETERMINED — `/setup-engine` §3 probes the installed editor and records the result here. |
| **Release Date** | June 2026 (latest patch: 4.7.2, August 2026) |
| **Project Pinned** | 2026-10-17 |
| **Last Docs Verified** | 2026-10-17 (release timeline and 4.7 changes); 2026-02-12 (4.4-4.6 content) |
| **LLM Knowledge Cutoff** | May 2025 |

| 字段 | 值 |
|-------|-------|
| **引擎版本** | Godot 4.7 |
| **固定版本时已安装的版本** | 未确定 — `/setup-engine` 第 3 节会探测已安装的编辑器，并将结果记录在此。 |
| **发布日期** | 2026 年 6 月（最新补丁：4.7.2，2026 年 8 月） |
| **项目固定版本** | 2026-10-17 |
| **最后文档验证** | 2026-10-17（发布时间线与 4.7 变更）；2026-02-12（4.4-4.6 内容） |
| **LLM 知识截止** | 2025 年 5 月 |

## Knowledge Gap Warning
## 知识缺口警告

The LLM's training data likely covers Godot up to ~4.3. Versions 4.5, 4.6
and 4.7 were released after the cutoff and introduced significant changes that
the model does NOT know about; 4.4 came out shortly before it and may be thinly
covered. Always cross-reference this directory before suggesting Godot API calls.
LLM 的训练数据可能仅涵盖到约 4.3 的 Godot 版本。4.5、4.6 和 4.7 版本在截止时间之后发布，引入了模型并不知晓的重大变更；4.4 在截止前不久发布，可能只有少量覆盖。在建议任何 Godot API 调用之前，务必交叉参考本目录。

## Installed-Version Gap Warning
## 已安装版本缺口警告

The warning above is one-directional — it covers the **model** knowing less than
this pin. The reverse gap is real and `/setup-engine` §3 creates it deliberately
("pin the newer one and upgrade later"): this reference can sit **ahead of the
installed editor**, and an agent citing it correctly then emits APIs that do not
compile locally. **Check `Installed at pin time` above before trusting a
version-qualified claim** — `NOT DETERMINED` means the gap is unknown, not absent.
上述警告是单向的 — 它针对的是**模型**所知少于本固定版本的情况。反向缺口真实存在，且 `/setup-engine` 第 3 节刻意制造了它（"固定更新的版本，之后再升级"）：本参考可能**领先于已安装的编辑器**，智能体即便正确引用它，也可能产出无法在本地编译的 API。**在信任任何带版本限定的说法之前，请检查上方的 `Installed at pin time`（固定版本时已安装的版本）** — `NOT DETERMINED`（未确定）意味着缺口未知，而非不存在。

## Post-Cutoff Version Timeline
## 截止后的版本时间线

| Version | Release | Risk Level | Key Theme |
|---------|---------|------------|-----------|
| 4.5 | Sep 2025 | HIGH | Accessibility (AccessKit), variadic args, @abstract, shader baker, SMAA |
| 4.6 | Jan 2026 | HIGH | Jolt default, glow rework, D3D12 default on Windows, IK restored |
| 4.7 | Jun 2026 | HIGH | AreaLight3D, HDR output, Asset Store replaces the Asset Library, VirtualJoystick, Jolt soft-body and world-boundary changes, typed-return overrides |

| 版本 | 发布 | 风险等级 | 关键主题 |
|---------|---------|------------|-----------|
| 4.5 | 2025 年 9 月 | HIGH | 无障碍（AccessKit）、可变参数、@abstract、着色器烘焙器、SMAA |
| 4.6 | 2026 年 1 月 | HIGH | Jolt 设为默认、glow 重做、Windows 上 D3D12 设为默认、IK 恢复 |
| 4.7 | 2026 年 6 月 | HIGH | AreaLight3D、HDR 输出、Asset Store 取代 Asset Library、VirtualJoystick、Jolt 软体和世界边界变更、类型化返回值覆写 |

## Before the Cutoff
## 截止之前

4.4 (Mar 2025, Jolt option, FileAccess return types) predates the May 2025
cutoff; the Knowledge Gap Warning still applies to it.
4.4（2025 年 3 月，Jolt 选项、FileAccess 返回类型）早于 2025 年 5 月的截止时间；知识缺口警告对它仍然适用。

Dates from https://github.com/godotengine/godot/releases, checked 2026-10-17:
4.4 Mar 3 2025, 4.5 Sep 15 2025, 4.6 Jan 26 2026, 4.7 Jun 18 2026, 4.7.2 Aug 18
2026. Migration guides and release notes: `breaking-changes.md` § Sources.
日期来自 https://github.com/godotengine/godot/releases，核查于 2026-10-17：4.4 2025 年 3 月 3 日、4.5 2025 年 9 月 15 日、4.6 2026 年 1 月 26 日、4.7 2026 年 6 月 18 日、4.7.2 2026 年 8 月 18 日。迁移指南与发行说明见 `breaking-changes.md` 的"Sources（来源）"一节。
