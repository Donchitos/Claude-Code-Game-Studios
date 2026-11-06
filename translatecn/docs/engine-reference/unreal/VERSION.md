# Unreal Engine — Version Reference
# Unreal Engine — 版本参考

| Field | Value |
|-------|-------|
| **Engine Version** | Unreal Engine 5.8 |
| **Installed at pin time** | NOT DETERMINED — `/setup-engine` §3 probes the installed editor and records the result here. |
| **Release Date** | June 2026 (5.8.0); latest hotfix 5.8.3, September 2026 |
| **Project Pinned** | 2026-10-17 |
| **Last Docs Verified** | 2026-10-17 (release timeline, 5.8 release notes, and the 5.8 changes recorded in this directory); 2026-02-13 (rest of directory, written against 5.7) |
| **LLM Knowledge Cutoff** | May 2025 |

| 字段 | 值 |
|-------|-------|
| **引擎版本** | Unreal Engine 5.8 |
| **固定版本时已安装的版本** | 未确定 — `/setup-engine` §3 会探测已安装的编辑器，并将结果记录在此处。 |
| **发布日期** | 2026 年 6 月（5.8.0）；最新热修复 5.8.3，2026 年 9 月 |
| **项目固定版本** | 2026-10-17 |
| **最后文档验证** | 2026-10-17（发布时间线、5.8 发行说明，以及本目录中记录的 5.8 变更）；2026-02-13（本目录其余部分，基于 5.7 编写） |
| **LLM 知识截止** | 2025 年 5 月 |

## Knowledge Gap Warning
## 知识缺口警告

The LLM's training data likely covers Unreal Engine up to ~5.3. Versions 5.4
through 5.8 introduced significant changes that the model does NOT know about
(5.4 and 5.5 predate the cutoff but are not reliably covered). Always
cross-reference this directory before suggesting Unreal API calls.

LLM 的训练数据可能仅覆盖到约 Unreal Engine 5.3。5.4 到 5.8 各版本引入了模型并不了解的重大变更（5.4 和 5.5 早于知识截止时间，但覆盖并不可靠）。在建议调用 Unreal API 之前，务必交叉参考本目录。

## Installed-Version Gap Warning
## 已安装版本缺口警告

The warning above is one-directional — it covers the **model** knowing less than
this pin. The reverse gap is real and `/setup-engine` §3 creates it deliberately
("pin the newer one and upgrade later"): this reference can sit **ahead of the
installed editor**, and an agent citing it correctly then emits APIs that do not
compile locally. **Check `Installed at pin time` above before trusting a
version-qualified claim** — `NOT DETERMINED` means the gap is unknown, not absent.

上述警告是单向的 — 它针对的是**模型**所知少于本次固定版本的情况。反向缺口同样真实存在，而且是由 `/setup-engine` §3 有意造成的（"固定较新的版本，之后再升级"）：本参考文档可能**领先于已安装的编辑器**，此时智能体正确地引用它，却会给出无法在本地编译的 API。**在采信任何带版本限定的说法之前，请先检查上方的 `Installed at pin time`（固定版本时已安装的版本）** — `NOT DETERMINED` 表示缺口未知，而非不存在。

## Post-Cutoff Version Timeline
## 知识截止之后的版本时间线

| Version | Release | Risk Level | Key Theme |
|---------|---------|------------|-----------|
| 5.6 | Jun 2025 | MEDIUM | Large open worlds at 60 Hz (Hardware Ray Tracing Lumen performance, Fast Geometry Streaming plugin, Experimental), MetaHuman Creator in the engine, in-editor animation and rigging tools |
| 5.7 | Nov 2025 | HIGH | PCG production-ready, Substrate production-ready (on by default for new projects), MegaLights Beta, in-editor AI Assistant (Experimental) |
| 5.8 | Jun 2026 | HIGH | MegaLights production-ready, Iris replication production-ready, Mesh Terrain (Experimental), Lumen Lite (Beta), Enhanced Input and Common UI unified, MCP Server plugin (Experimental), C++20 minimum, WASAPI default audio backend on Windows, multi-pass deferred default on mobile |

| 版本 | 发布 | 风险等级 | 核心主题 |
|---------|---------|------------|-----------|
| 5.6 | 2025 年 6 月 | 中 | 60 Hz 下的大型开放世界（硬件光线追踪 Lumen 性能、Fast Geometry Streaming 插件，实验性）、引擎内置 MetaHuman Creator、编辑器内动画与绑定工具 |
| 5.7 | 2025 年 11 月 | 高 | PCG 生产就绪、Substrate 生产就绪（新项目默认启用）、MegaLights Beta、编辑器内 AI Assistant（实验性） |
| 5.8 | 2026 年 6 月 | 高 | MegaLights 生产就绪、Iris 复制生产就绪、Mesh Terrain（实验性）、Lumen Lite（Beta）、Enhanced Input 与 Common UI 统一、MCP Server 插件（实验性）、最低 C++20、Windows 默认音频后端为 WASAPI、移动端默认多通道延迟渲染 |

## Unreal Engine 5 Releases Before the Cutoff
## 知识截止之前的 Unreal Engine 5 版本

These two predate the May 2025 cutoff, so they are not post-cutoff. The Knowledge
Gap Warning above still applies to them: treat their APIs as unconfirmed until
checked against this directory.

这两个版本早于 2025 年 5 月的截止时间，因此不属于截止之后的版本。上述知识缺口警告对它们同样适用：在对照本目录核实之前，应将其 API 视为未经确认。

| Version | Release | Risk Level | Key Theme |
|---------|---------|------------|-----------|
| 5.4 | Apr 2024 | HIGH | Motion Matching production-ready, Choosers, animation authoring (Modular Control Rig, Sequencer rework), Nanite Tessellation (Experimental), Motion Design mode |
| 5.5 | Nov 2024 | HIGH | MegaLights introduced, Substrate moves to Beta, Sequencer animation authoring, mobile game development, many features reach production-ready |

| 版本 | 发布 | 风险等级 | 核心主题 |
|---------|---------|------------|-----------|
| 5.4 | 2024 年 4 月 | 高 | Motion Matching 生产就绪、Choosers、动画创作（模块化 Control Rig、Sequencer 重做）、Nanite 细分（实验性）、Motion Design 模式 |
| 5.5 | 2024 年 11 月 | 高 | 引入 MegaLights、Substrate 进入 Beta、Sequencer 动画创作、移动游戏开发、多项功能达到生产就绪 |

Release dates verified 2026-10-17 against Epic's release announcement threads:
5.4 (Apr 23, 2024) https://forums.unrealengine.com/t/unreal-engine-5-4-released/1817064,
5.5 (Nov 12, 2024) https://forums.unrealengine.com/t/unreal-engine-5-5-released/2117936,
5.6 (Jun 3, 2025) https://forums.unrealengine.com/t/unreal-engine-5-6-released/2538952,
5.7 (Nov 12, 2025) https://forums.unrealengine.com/t/unreal-engine-5-7-released/2673913,
5.8 (Jun 17, 2026) https://forums.unrealengine.com/t/unreal-engine-5-8-released/2729274.
Hotfixes 5.8.1 (Jul 28, 2026), 5.8.2 (Aug 25, 2026) and 5.8.3 (Sep 22, 2026):
https://forums.unrealengine.com/t/5-8-3-hotfix-released/2833315. Key themes come
from the same threads and from the 5.7 and 5.8 release notes (Verified Sources below).

发布日期已于 2026-10-17 对照 Epic 的发布公告帖核实：
5.4（2024 年 4 月 23 日）https://forums.unrealengine.com/t/unreal-engine-5-4-released/1817064，
5.5（2024 年 11 月 12 日）https://forums.unrealengine.com/t/unreal-engine-5-5-released/2117936，
5.6（2025 年 6 月 3 日）https://forums.unrealengine.com/t/unreal-engine-5-6-released/2538952，
5.7（2025 年 11 月 12 日）https://forums.unrealengine.com/t/unreal-engine-5-7-released/2673913，
5.8（2026 年 6 月 17 日）https://forums.unrealengine.com/t/unreal-engine-5-8-released/2729274。
热修复 5.8.1（2026 年 7 月 28 日）、5.8.2（2026 年 8 月 25 日）和 5.8.3（2026 年 9 月 22 日）：
https://forums.unrealengine.com/t/5-8-3-hotfix-released/2833315。核心主题来自同样的帖子，以及 5.7 和 5.8 的发行说明（见下方"已验证来源"）。

## Major Changes from UE 5.3 to UE 5.8
## 从 UE 5.3 到 UE 5.8 的重大变更

### Breaking Changes
### 破坏性变更

- **Substrate Material System**: New material framework (replaces legacy materials); new projects created in 5.7+ have it enabled automatically
- **PCG (Procedural Content Generation)**: Production-ready, major API changes
- **MegaLights**: New lighting system for many shadow-casting dynamic lights; production-ready in 5.8
- **Animation Authoring**: New rigging and animation tools
- **C++20 minimum (5.8)**: `CppStandardVersion.Cpp14` and `Cpp17` are obsolete and no longer compile
- **5.8 API removals**: deprecated animation, Control Rig and Live Link symbols from 5.0-5.6 removed; PhysicsMover removed from Mover in favour of ChaosMover — see `breaking-changes.md`

- **Substrate 材质系统**：新材质框架（取代旧版材质）；5.7+ 创建的新项目会自动启用
- **PCG（程序化内容生成）**：生产就绪，API 有重大变更
- **MegaLights**：面向大量投射阴影的动态光源的新光照系统；在 5.8 中生产就绪
- **动画创作**：新的绑定与动画工具
- **最低 C++20（5.8）**：`CppStandardVersion.Cpp14` 和 `Cpp17` 已废弃，不再编译
- **5.8 API 移除**：5.0-5.6 中已弃用的动画、Control Rig 和 Live Link 符号被移除；Mover 中的 PhysicsMover 被移除，改用 ChaosMover — 见 `breaking-changes.md`

### New Features (Post-Cutoff)
### 新功能（知识截止之后）

- **MegaLights**: Dynamic lighting at massive scale (production-ready in 5.8)
- **Substrate Materials**: Production-ready modular material system (5.7)
- **PCG Framework**: Procedural world generation (production-ready in 5.7)
- **Iris**: Replication system, production-ready in 5.8
- **Lumen Lite (5.8, Beta)**: Medium-quality GI setting, the default on current-generation handheld consoles
- **Mesh Terrain (5.8, Experimental)**: Mesh-based terrain beyond heightfield landscapes
- **Enhanced Virtual Production**: MetaHuman integration, deeper VP workflows
- **Animation Improvements**: Better rigging, blending, procedural animation
- **AI Assistant (5.7)**: In-editor AI help (Experimental)
- **MCP Server (5.8)**: Editor plugin that lets agentic AI systems connect to the Unreal Editor (Experimental)

- **MegaLights**：大规模动态光照（5.8 中生产就绪）
- **Substrate 材质**：生产就绪的模块化材质系统（5.7）
- **PCG 框架**：程序化世界生成（5.7 中生产就绪）
- **Iris**：复制系统，5.8 中生产就绪
- **Lumen Lite（5.8，Beta）**：中等质量的全局光照（GI）设置，当前世代掌机上的默认选项
- **Mesh Terrain（5.8，实验性）**：超越高度场景观的基于网格的地形
- **增强的虚拟制片**：MetaHuman 集成、更深入的 VP 工作流
- **动画改进**：更好的绑定、混合与程序化动画
- **AI Assistant（5.7）**：编辑器内 AI 辅助（实验性）
- **MCP Server（5.8）**：允许智能体式 AI 系统连接到 Unreal Editor 的编辑器插件（实验性）

### Deprecated Systems
### 已弃用的系统

- **Legacy Material System**: Migrate to Substrate for new projects
- **Old PCG API**: Use new production-ready PCG API (5.7+)
- **Raw Input plugin (5.8)**: Deprecated in favour of the Game Input for Windows plugin
- **`UE_LOG` (5.8)**: Still supported; Epic says it "will eventually be deprecated" and asks for `UE_LOGF`

- **旧版材质系统**：新项目请迁移到 Substrate
- **旧 PCG API**：请使用新的生产就绪 PCG API（5.7+）
- **Raw Input 插件（5.8）**：已弃用，改用 Game Input for Windows 插件
- **`UE_LOG`（5.8）**：仍受支持；Epic 表示它"最终会被弃用"，并建议使用 `UE_LOGF`

## Verified Sources
## 已验证来源

- Official docs: https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-5-8-documentation?application_version=5.8
- UE 5.8 release notes: https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-5-8-release-notes?application_version=5.8
- UE 5.8 release thread: https://forums.unrealengine.com/t/unreal-engine-5-8-released/2729274
- UE 5.8.3 hotfix: https://forums.unrealengine.com/t/5-8-3-hotfix-released/2833315
- UE 5.7 release notes: https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-5-7-release-notes
- What's new in 5.7: https://dev.epicgames.com/documentation/en-us/unreal-engine/whats-new
- UE 5.7 announcement: https://www.unrealengine.com/en-US/news/unreal-engine-5-7-is-now-available
- UE 5.5 blog: https://www.unrealengine.com/en-US/blog/unreal-engine-5-5-is-now-available
- Migration guides: https://dev.epicgames.com/documentation/en-us/unreal-engine/upgrading-projects-to-newer-versions-of-unreal-engine
- Engine source, read from a UE 5.8.1 install on 2026-10-17: `Engine/Source/Programs/UnrealBuildTool/System/CppCompileEnvironment.cs` (C++ standard), `Engine/Source/Runtime/RenderCore/Private/RenderUtils.cpp` (Substrate defaults)

- 官方文档：https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-5-8-documentation?application_version=5.8
- UE 5.8 发行说明：https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-5-8-release-notes?application_version=5.8
- UE 5.8 发布帖：https://forums.unrealengine.com/t/unreal-engine-5-8-released/2729274
- UE 5.8.3 热修复：https://forums.unrealengine.com/t/5-8-3-hotfix-released/2833315
- UE 5.7 发行说明：https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-5-7-release-notes
- 5.7 中的新功能：https://dev.epicgames.com/documentation/en-us/unreal-engine/whats-new
- UE 5.7 公告：https://www.unrealengine.com/en-US/news/unreal-engine-5-7-is-now-available
- UE 5.5 博客：https://www.unrealengine.com/en-US/blog/unreal-engine-5-5-is-now-available
- 迁移指南：https://dev.epicgames.com/documentation/en-us/unreal-engine/upgrading-projects-to-newer-versions-of-unreal-engine
- 引擎源码，于 2026-10-17 从 UE 5.8.1 安装中读取：`Engine/Source/Programs/UnrealBuildTool/System/CppCompileEnvironment.cs`（C++ 标准）、`Engine/Source/Runtime/RenderCore/Private/RenderUtils.cpp`（Substrate 默认值）
