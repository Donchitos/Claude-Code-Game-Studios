# Unity Engine — Version Reference
# Unity 引擎 — 版本参考

| Field | Value |
|-------|-------|
| **Engine Version** | Unity 6.3 LTS |
| **Installed at pin time** | NOT DETERMINED — `/setup-engine` §3 probes the installed editor and records the result here. |
| **Release Date** | December 2025 |
| **Latest editor on the pinned line** | 6000.3.26f1 (Oct 8, 2026) |
| **Project Pinned** | 2026-02-13 |
| **Last Docs Verified** | 2026-10-17 (release timeline, newer releases, latest 6.3 LTS editor); 2026-02-13 (rest of directory) |
| **LLM Knowledge Cutoff** | May 2025 |

| 字段 | 值 |
|-------|-------|
| **引擎版本** | Unity 6.3 LTS |
| **锁定版本时的已安装版本** | 尚未确定 — `/setup-engine` §3 会探测已安装的编辑器并将结果记录在此。 |
| **发布日期** | 2025 年 12 月 |
| **在锁定版本线上的最新编辑器** | 6000.3.26f1（2026 年 10 月 8 日） |
| **项目锁定版本** | 2026-02-13 |
| **文档最后验证时间** | 2026-10-17（发布时间线、更新的版本、最新的 6.3 LTS 编辑器）；2026-02-13（目录其余部分） |
| **LLM 知识截止时间** | 2025 年 5 月 |

## Knowledge Gap Warning
## 知识盲区警告

The LLM's training data likely covers Unity up to ~2022 LTS (2022.3). The entire
Unity 6 release series (formerly Unity 2023 Tech Stream) introduced significant
changes that the model does NOT know about. Always cross-reference this directory
before suggesting Unity API calls.

LLM 的训练数据可能仅覆盖 Unity 至约 2022 LTS（2022.3）。整个 Unity 6 发布系列（前身为 Unity 2023 Tech Stream）引入了模型并不知晓的重大变更。在建议 Unity API 调用之前，请务必交叉参考此目录。

## Installed-Version Gap Warning
## 已安装版本差距警告

The warning above is one-directional — it covers the **model** knowing less than
this pin. The reverse gap is real and `/setup-engine` §3 creates it deliberately
("pin the newer one and upgrade later"): this reference can sit **ahead of the
installed editor**, and an agent citing it correctly then emits APIs that do not
compile locally. **Check `Installed at pin time` above before trusting a
version-qualified claim** — `NOT DETERMINED` means the gap is unknown, not absent.

上方的警告是单向的 — 它针对的是**模型**所知少于本次锁定版本的情况。反向差距同样真实存在，且由 `/setup-engine` §3 刻意制造（"锁定较新的版本，之后再升级"）：本参考可能**领先于已安装的编辑器**，此时智能体即使正确引用它，也会产出无法在本地编译的 API。**在相信任何带版本限定条件的说法之前，请先检查上方的 `锁定版本时的已安装版本`** — `尚未确定` 意味着差距未知，而非不存在。

## Post-Cutoff Version Timeline
## 知识截止后的版本时间线

| Version | Release | Risk Level | Key Theme |
|---------|---------|------------|-----------|
| 6.2 | Aug 2025 | MEDIUM | Supported Update release: Unity AI (beta) in the Editor, Mesh LOD, World Space UI for UI Toolkit, Graph Toolkit, Android XR hand mesh |
| 6.3 LTS | Dec 2025 | HIGH | First LTS since 6.0 (two years of support): Platform Toolkit, Nintendo Switch 2 support, Android XR, desktop screen reader support, Shader Build Settings |

| 版本 | 发布时间 | 风险等级 | 核心主题 |
|---------|---------|------------|-----------|
| 6.2 | 2025 年 8 月 | 中 | 受支持的更新版本（Supported Update）：编辑器内的 Unity AI（测试版）、Mesh LOD、UI Toolkit 的世界空间 UI、Graph Toolkit、Android XR 手部网格 |
| 6.3 LTS | 2025 年 12 月 | 高 | 自 6.0 以来首个 LTS（两年支持期）：Platform Toolkit、Nintendo Switch 2 支持、Android XR、桌面屏幕阅读器支持、着色器构建设置（Shader Build Settings） |

## Newer Releases After the Pin (6.4 to 6.7)
## 锁定版本之后的新版本（6.4 至 6.7）

**The pin does not change: it stays Unity 6.3 LTS, the newest LTS.** These are
Supported Update releases that shipped after it. Nothing else in this directory
covers their APIs, so treat any 6.4+ API as unconfirmed until checked against
Unity's docs for that release. 6.0 LTS support ends in October 2026.

**锁定版本不变：仍为 Unity 6.3 LTS，即最新的 LTS。** 以下是在其之后发布的受支持更新版本（Supported Update）。本目录中没有其他内容涵盖它们的 API，因此任何 6.4+ 的 API 在对照 Unity 对应版本的文档核实之前，都应视为未经确认。6.0 LTS 的支持将于 2026 年 10 月结束。

| Version | Release | Status (2026-10-17) | Key Theme |
|---------|---------|---------------------|-----------|
| 6.4 | Mar 2026 | Reached end of life | ECS (Entities, Collections, Mathematics, Entities Graphics) ships as Core packages, Project Auditor built into the Editor, DirectStorage on Windows, `EntityId` replaces `InstanceID`, URP Compatibility Mode removed in favor of Render Graph |
| 6.5 | Jun 2026 | Reached end of life | Entity unification (`InstanceID` to `EntityId`), Editor Lifecycle API toward a CoreCLR Editor, 2D (custom lights and shadows, `RenderSprite` API, Physics Core 2D), on-tile post-processing for mobile, Built-In Render Pipeline deprecated |
| 6.6 | Sep 2026 | Supported until 6.7 ships | Final supported release of the Unity 6 family: Play Mode skips domain reloads by default for new projects, Content Directories, Build Analysis window, WebGPU as a production Web option |
| 6.7 | Beta | Not released | 6000.7.0b1 on Sep 17, 2026, latest 6000.7.0b5 on Oct 15, 2026; Unity's 6.6 post calls it the 6.7 LTS |

| 版本 | 发布时间 | 状态（2026-10-17） | 核心主题 |
|---------|---------|---------------------|-----------|
| 6.4 | 2026 年 3 月 | 已停止支持（生命周期结束） | ECS（Entities、Collections、Mathematics、Entities Graphics）作为核心包（Core packages）发布、Project Auditor 内置于编辑器、Windows 上的 DirectStorage、`EntityId` 取代 `InstanceID`、URP 兼容模式（Compatibility Mode）被移除，改由 Render Graph 承担 |
| 6.5 | 2026 年 6 月 | 已停止支持（生命周期结束） | 实体统一（`InstanceID` 改为 `EntityId`）、面向 CoreCLR 编辑器的编辑器生命周期 API（Editor Lifecycle API）、2D（自定义灯光与阴影、`RenderSprite` API、Physics Core 2D）、移动端的片上后处理（on-tile post-processing）、内置渲染管线（Built-In Render Pipeline）弃用 |
| 6.6 | 2026 年 9 月 | 支持至 6.7 发布 | Unity 6 系列的最后一个受支持版本：新项目默认在播放模式（Play Mode）下跳过域重载（domain reload）、内容目录（Content Directories）、构建分析窗口（Build Analysis window）、WebGPU 作为生产级 Web 选项 |
| 6.7 | 测试版 | 尚未发布 | 2026 年 9 月 17 日的 6000.7.0b1，2026 年 10 月 15 日最新的 6000.7.0b5；Unity 的 6.6 公告称其为 6.7 LTS |

Dates and status, verified 2026-10-17: 6.4 (announced Mar 17, 2026; editor
6000.4.0f1 Mar 18) https://discussions.unity.com/t/unity-6-4-is-now-available/1713245
and https://docs.unity.com/en-us/engine/6000.6/manual/whats-new/unity64; 6.5
(Jun 15, 2026) https://discussions.unity.com/t/unity-6-5-is-now-available/1723176
and https://docs.unity.com/en-us/engine/6000.5/manual/whats-new/unity65; 6.6
(editor 6000.6.0f1 Aug 31, announced Sep 1, 2026, latest 6000.6.6f1 Oct 15)
https://discussions.unity.com/t/unity-6-6-is-now-available/1735357. The 6.4 and
6.5 threads carry the banner "This supported release has reached end of life"
(6.4 points to 6.5 or above, 6.5 to 6.6 or above); the 6.6 post says it is
supported "until the next release - in this case 6.7 - arrives" and that it
"brings you one step closer to the 6.7 LTS". Editor versions and release dates
come from Unity's release API
https://services.api.unity.com/unity/editor/release/v1/releases (6.3 LTS first
editor 6000.3.0f1 on Dec 3, 2025; latest 6000.3.26f1 on Oct 8, 2026). Upgrading
the pin is a decision for when 6.7 LTS ships and `/setup-engine` re-pins; until
then new projects stay on 6.3 LTS.

日期与状态，核实于 2026-10-17：6.4（2026 年 3 月 17 日发布公告；编辑器 6000.4.0f1 于 3 月 18 日）https://discussions.unity.com/t/unity-6-4-is-now-available/1713245 以及 https://docs.unity.com/en-us/engine/6000.6/manual/whats-new/unity64；6.5（2026 年 6 月 15 日）https://discussions.unity.com/t/unity-6-5-is-now-available/1723176 以及 https://docs.unity.com/en-us/engine/6000.5/manual/whats-new/unity65；6.6（编辑器 6000.6.0f1 于 8 月 31 日，2026 年 9 月 1 日发布公告，最新 6000.6.6f1 于 10 月 15 日）https://discussions.unity.com/t/unity-6-6-is-now-available/1735357。6.4 与 6.5 的帖子带有横幅"该受支持版本已停止支持（This supported release has reached end of life）"（6.4 指向 6.5 或更高版本，6.5 指向 6.6 或更高版本）；6.6 的公告称其支持期"直到下一个版本 — 此处即 6.7 — 发布"，并且它"让你离 6.7 LTS 更近一步"。编辑器版本与发布日期来自 Unity 的发布 API https://services.api.unity.com/unity/editor/release/v1/releases（6.3 LTS 首个编辑器 6000.3.0f1 于 2025 年 12 月 3 日；最新 6000.3.26f1 于 2026 年 10 月 8 日）。升级锁定版本是一项待 6.7 LTS 发布并由 `/setup-engine` 重新锁定版本时作出的决策；在此之前，新项目继续使用 6.3 LTS。

## Unity 6 Releases Before the Cutoff
## 知识截止前的 Unity 6 版本

These two predate the May 2025 cutoff, so they are not post-cutoff. The Knowledge
Gap Warning above still applies to them: treat their APIs as unconfirmed until
checked against this directory.

这两个版本早于 2025 年 5 月的知识截止时间，因此不属于截止后版本。上方的知识盲区警告对它们仍然适用：在对照本目录核实之前，其 API 应视为未经确认。

| Version | Release | Risk Level | Key Theme |
|---------|---------|------------|-----------|
| 6.0 LTS | Oct 2024 | HIGH | Unity 6 launch: GPU Resident Drawer, Render Graph for URP, multiplayer workflows, mobile web, new Update release type |
| 6.1 | Apr 2025 | MEDIUM | First Supported Update release: URP Deferred+ path, Variable Rate Shading, Project Auditor, WebGPU for Unity Web, foldable/large-screen Android |

| 版本 | 发布时间 | 风险等级 | 核心主题 |
|---------|---------|------------|-----------|
| 6.0 LTS | 2024 年 10 月 | 高 | Unity 6 发布：GPU Resident Drawer、适用于 URP 的 Render Graph、多人游戏工作流、移动端 Web、新的更新版本类型（Update） |
| 6.1 | 2025 年 4 月 | 中 | 首个受支持更新版本（Supported Update）：URP Deferred+ 路径、可变速率着色（Variable Rate Shading）、Project Auditor、Unity Web 的 WebGPU、可折叠/大屏 Android |

Release dates verified 2026-10-17 against Unity's announcements: 6.0
(Oct 17, 2024) https://unity.com/blog/introducing-unity-6-launch, 6.1
(Apr 24, 2025) https://unity.com/blog/unity-6-1-is-now-available, 6.2
(Aug 12, 2025) https://discussions.unity.com/t/6-2-is-now-available/1677060,
6.3 LTS (Dec 4, 2025) https://unity.com/blog/unity-6-3-lts-is-now-available.
Support windows: https://unity.com/releases/unity-6/support (6.0 LTS through
October 2026, 6.3 LTS until December 2027).

发布日期核实于 2026-10-17，对照 Unity 的公告：6.0（2024 年 10 月 17 日）https://unity.com/blog/introducing-unity-6-launch，6.1（2025 年 4 月 24 日）https://unity.com/blog/unity-6-1-is-now-available，6.2（2025 年 8 月 12 日）https://discussions.unity.com/t/6-2-is-now-available/1677060，6.3 LTS（2025 年 12 月 4 日）https://unity.com/blog/unity-6-3-lts-is-now-available。支持窗口：https://unity.com/releases/unity-6/support（6.0 LTS 支持至 2026 年 10 月，6.3 LTS 支持至 2027 年 12 月）。

## Major Changes from 2022 LTS to Unity 6.3 LTS
## 从 2022 LTS 到 Unity 6.3 LTS 的主要变更

### Breaking Changes
### 破坏性变更

- **Entities/DOTS**: Major API overhaul in Entities 1.0+, complete redesign of ECS patterns
- **Input System**: Legacy Input Manager deprecated, new Input System is default
- **Rendering**: URP/HDRP significant upgrades, SRP Batcher improvements
- **Addressables**: Asset management workflow changes
- **Scripting**: C# 9 support, new API patterns

- **Entities/DOTS**：Entities 1.0+ 中的重大 API 重构，ECS 模式的完整重新设计
- **Input System**：旧版 Input Manager 已弃用，新 Input System 成为默认
- **渲染**：URP/HDRP 的重大升级，SRP Batcher 改进
- **Addressables**：资源管理工作流变更
- **脚本**：支持 C# 9，新的 API 模式

### New Features (Post-Cutoff)
### 新特性（知识截止后）

- **DOTS**: Production-ready Entity Component System (Entities 1.3+)
- **Graphics**: Enhanced URP/HDRP pipelines, GPU Resident Drawer
- **Multiplayer**: Netcode for GameObjects improvements
- **UI Toolkit**: Production-ready for runtime UI (replaces UGUI for new projects)
- **Async Asset Loading**: Improved Addressables performance
- **Web**: WebGPU support

- **DOTS**：生产就绪的实体组件系统（Entities 1.3+）
- **图形**：增强的 URP/HDRP 管线，GPU Resident Drawer
- **多人游戏**：Netcode for GameObjects 改进
- **UI Toolkit**：可用于生产环境的运行时 UI（新项目以之取代 UGUI）
- **异步资源加载**：改进的 Addressables 性能
- **Web**：支持 WebGPU

### Deprecated Systems
### 弃用系统

- **Legacy Input Manager**: Use new Input System package
- **Legacy Particle System**: Use Visual Effect Graph
- **UGUI**: Still supported, but UI Toolkit recommended for new projects
- **Old ECS (GameObjectEntity)**: Replaced by modern DOTS/Entities

- **旧版 Input Manager**：改用新 Input System 包
- **旧版粒子系统**：改用 Visual Effect Graph
- **UGUI**：仍然支持，但新项目推荐使用 UI Toolkit
- **旧 ECS（GameObjectEntity）**：由现代 DOTS/Entities 取代

## Verified Sources
## 已验证来源

- Official docs: https://docs.unity3d.com/6000.0/Documentation/Manual/index.html
- Unity 6 release: https://unity.com/releases/unity-6
- Unity 6.0 launch: https://unity.com/blog/introducing-unity-6-launch
- Unity 6.1 announcement: https://unity.com/blog/unity-6-1-is-now-available
- Unity 6.2 announcement: https://discussions.unity.com/t/6-2-is-now-available/1677060
- Unity 6.3 LTS announcement: https://unity.com/blog/unity-6-3-lts-is-now-available
- Migration guide: https://docs.unity3d.com/6000.0/Documentation/Manual/upgrade-guides.html
- Unity 6 support: https://unity.com/releases/unity-6/support
- Unity 6.4 announcement: https://discussions.unity.com/t/unity-6-4-is-now-available/1713245
- Unity 6.5 announcement: https://discussions.unity.com/t/unity-6-5-is-now-available/1723176
- Unity 6.6 announcement: https://discussions.unity.com/t/unity-6-6-is-now-available/1735357
- Editor release API: https://services.api.unity.com/unity/editor/release/v1/releases
- C# API reference: https://docs.unity3d.com/6000.0/Documentation/ScriptReference/index.html
