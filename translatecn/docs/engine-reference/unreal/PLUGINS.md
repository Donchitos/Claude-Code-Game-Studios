# Unreal Engine 5.8 — Optional Plugins & Systems
# Unreal Engine 5.8 — 可选插件与系统

**Last verified:** 2026-10-17 (5.8 status flags, Mover, Iris, AI Assistant, MCP Server, Raw Input); 2026-02-13 (rest of file, written against 5.7)

**最后验证：** 2026-10-17（5.8 状态标记、Mover、Iris、AI Assistant、MCP Server、Raw Input）；2026-02-13（文件其余部分，基于 5.7 编写）

This document indexes **optional plugins and systems** available in Unreal Engine 5.8.
These are NOT part of the core engine but are commonly used for specific game types.

本文档索引 Unreal Engine 5.8 中可用的**可选插件与系统**。它们并不属于核心引擎，但常用于特定类型的游戏。

---

## How to Use This Guide
## 如何使用本指南

**✅ Detailed Documentation Available** - See `plugins/` directory for comprehensive guides
**🟡 Brief Overview Only** - Links to official docs, use WebSearch for details
**⚠️ Experimental** - May have breaking changes in future versions
**📦 Plugin Required** - Must be enabled in `Edit > Plugins`

**✅ 提供详细文档** - 参见 `plugins/` 目录获取完整指南
**🟡 仅简要概述** - 链接到官方文档，详细信息请使用 WebSearch
**⚠️ 实验性** - 未来版本可能会有破坏性变更
**📦 需要插件** - 必须在 `Edit > Plugins` 中启用

### Status flags in the UE 5.8 install
### UE 5.8 安装中的状态标记

Epic's own `.uplugin` flags decide whether the Plugins window shows a plugin as
Beta or Experimental. Read from a UE 5.8.1 install (`Engine/Plugins/...`) on
2026-10-17; where a status line below and this table disagree, the table is the
engine's word.

Epic 自己的 `.uplugin` 标记决定了 Plugins 窗口将插件显示为 Beta 还是 Experimental。以下内容于 2026-10-17 从 UE 5.8.1 安装（`Engine/Plugins/...`）中读取；若下文某行状态与此表不一致，以本表为准，因为它代表了引擎的说法。

| Plugin | `.uplugin` | 5.8 flag |
|--------|-----------|----------|
| Gameplay Abilities | `Runtime/GameplayAbilities/GameplayAbilities.uplugin` | none (not Beta/Experimental) |
| CommonUI | `Runtime/CommonUI/CommonUI.uplugin` | none |
| PCG | `PCG/PCG.uplugin` | none; enabled by default |
| Gameplay Cameras | `Cameras/GameplayCameras/GameplayCameras.uplugin` | Experimental; enabled by default |
| Mass Gameplay / Mass Crowd | `Runtime/MassGameplay/MassGameplay.uplugin`, `AI/MassCrowd/MassCrowd.uplugin` | Experimental (MassEntity itself is engine code, `Engine/Source/Runtime/MassEntity`) |
| Niagara Fluids | `FX/NiagaraFluids/NiagaraFluids.uplugin` | Beta |
| Water | `Experimental/Water/Water.uplugin` | Experimental |
| Landmass | `Experimental/Landmass/Landmass.uplugin` | Beta |
| Chaos Destruction (Geometry Collection) | `Experimental/GeometryCollectionPlugin/GeometryCollectionPlugin.uplugin` | Beta |
| Chaos Vehicles | `Experimental/ChaosVehiclesPlugin/ChaosVehiclesPlugin.uplugin` | Experimental |
| Geometry Scripting | `Runtime/GeometryScripting/GeometryScripting.uplugin` | none |
| Mover / ChaosMover | `Experimental/Mover/Mover.uplugin`, `Experimental/ChaosMover/ChaosMover.uplugin` | Experimental |
| Iris | `Experimental/Iris/Iris.uplugin` | Beta (the 5.8 release notes call Iris "production-ready for licensees") |
| Replication Graph | `Runtime/ReplicationGraph/ReplicationGraph.uplugin` | Beta (no deprecation flag) |
| AI Assistant | `Experimental/AIAssistant/AIAssistant.uplugin` | Experimental |
| Raw Input | `Experimental/RawInput/RawInput.uplugin` | `"DeprecatedEngineVersion": "5.8"` |
| Game Input (Windows) | `GameInputWindows/GameInputWindows.uplugin` | Beta |
| OpenXR | `Runtime/OpenXR/OpenXR.uplugin` | none |
| Enhanced Input, MetaSound | `EnhancedInput/EnhancedInput.uplugin`, `Runtime/Metasound/Metasound.uplugin` | none; enabled by default |

| 插件 | `.uplugin` | 5.8 标记 |
|--------|-----------|----------|
| Gameplay Abilities | `Runtime/GameplayAbilities/GameplayAbilities.uplugin` | 无（非 Beta/Experimental） |
| CommonUI | `Runtime/CommonUI/CommonUI.uplugin` | 无 |
| PCG | `PCG/PCG.uplugin` | 无；默认启用 |
| Gameplay Cameras | `Cameras/GameplayCameras/GameplayCameras.uplugin` | Experimental；默认启用 |
| Mass Gameplay / Mass Crowd | `Runtime/MassGameplay/MassGameplay.uplugin`、`AI/MassCrowd/MassCrowd.uplugin` | Experimental（MassEntity 本身是引擎代码，`Engine/Source/Runtime/MassEntity`） |
| Niagara Fluids | `FX/NiagaraFluids/NiagaraFluids.uplugin` | Beta |
| Water | `Experimental/Water/Water.uplugin` | Experimental |
| Landmass | `Experimental/Landmass/Landmass.uplugin` | Beta |
| Chaos Destruction（Geometry Collection） | `Experimental/GeometryCollectionPlugin/GeometryCollectionPlugin.uplugin` | Beta |
| Chaos Vehicles | `Experimental/ChaosVehiclesPlugin/ChaosVehiclesPlugin.uplugin` | Experimental |
| Geometry Scripting | `Runtime/GeometryScripting/GeometryScripting.uplugin` | 无 |
| Mover / ChaosMover | `Experimental/Mover/Mover.uplugin`、`Experimental/ChaosMover/ChaosMover.uplugin` | Experimental |
| Iris | `Experimental/Iris/Iris.uplugin` | Beta（5.8 发行说明称 Iris 已"对授权方生产就绪"） |
| Replication Graph | `Runtime/ReplicationGraph/ReplicationGraph.uplugin` | Beta（无弃用标记） |
| AI Assistant | `Experimental/AIAssistant/AIAssistant.uplugin` | Experimental |
| Raw Input | `Experimental/RawInput/RawInput.uplugin` | `"DeprecatedEngineVersion": "5.8"` |
| Game Input (Windows) | `GameInputWindows/GameInputWindows.uplugin` | Beta |
| OpenXR | `Runtime/OpenXR/OpenXR.uplugin` | 无 |
| Enhanced Input、MetaSound | `EnhancedInput/EnhancedInput.uplugin`、`Runtime/Metasound/Metasound.uplugin` | 无；默认启用 |

---

## Production-Ready Systems (Detailed Docs Available)
## 生产就绪系统（提供详细文档）

### ✅ Gameplay Ability System (GAS)
### ✅ Gameplay Ability System（GAS）

- **Purpose:** Modular ability system (abilities, attributes, effects, cooldowns, costs)
- **When to use:** RPGs, MOBAs, shooters with abilities, any ability-based gameplay
- **Knowledge Gap:** GAS stable since UE4, UE5 improvements post-cutoff
- **Status:** Production-Ready
- **Plugin:** `GameplayAbilities` (built-in, enable in Plugins)
- **Detailed Docs:** [plugins/gameplay-ability-system.md](plugins/gameplay-ability-system.md)
- **Official:** https://docs.unrealengine.com/5.7/en-US/gameplay-ability-system-for-unreal-engine/

- **用途：** 模块化能力系统（能力、属性、效果、冷却、消耗）
- **适用场景：** RPG、MOBA、带技能的射击游戏，以及任何基于能力的玩法
- **知识缺口：** GAS 自 UE4 起稳定，UE5 的改进发生在知识截止之后
- **状态：** 生产就绪
- **插件：** `GameplayAbilities`（内置，在 Plugins 中启用）
- **详细文档：** [plugins/gameplay-ability-system.md](plugins/gameplay-ability-system.md)
- **官方文档：** https://docs.unrealengine.com/5.7/en-US/gameplay-ability-system-for-unreal-engine/

---

### ✅ CommonUI
### ✅ CommonUI

- **Purpose:** Cross-platform UI framework (automatic gamepad/mouse/touch input routing)
- **When to use:** Multi-platform games (console + PC), input-agnostic UI
- **Knowledge Gap:** Production-ready in UE5+, major improvements post-cutoff
- **Status:** Production-Ready
- **Plugin:** `CommonUI` (built-in, enable in Plugins)
- **Detailed Docs:** [plugins/common-ui.md](plugins/common-ui.md)
- **Official:** https://docs.unrealengine.com/5.7/en-US/commonui-plugin-for-advanced-user-interfaces-in-unreal-engine/

- **用途：** 跨平台 UI 框架（自动路由手柄/鼠标/触摸输入）
- **适用场景：** 多平台游戏（主机 + PC）、与输入方式无关的 UI
- **知识缺口：** UE5+ 中生产就绪，重大改进发生在知识截止之后
- **状态：** 生产就绪
- **插件：** `CommonUI`（内置，在 Plugins 中启用）
- **详细文档：** [plugins/common-ui.md](plugins/common-ui.md)
- **官方文档：** https://docs.unrealengine.com/5.7/en-US/commonui-plugin-for-advanced-user-interfaces-in-unreal-engine/

---

### ✅ Gameplay Camera System
### ✅ Gameplay Camera System

- **Purpose:** Modular camera management (camera modes, blending, context-aware cameras)
- **When to use:** Games needing dynamic camera behavior (3rd person, aiming, vehicles)
- **Knowledge Gap:** NEW in UE 5.5, completely post-cutoff
- **Status:** ⚠️ Experimental (UE 5.5-5.8; still flagged Experimental in 5.8)
- **Plugin:** `GameplayCameras` (built-in, enable in Plugins)
- **Detailed Docs:** [plugins/gameplay-camera-system.md](plugins/gameplay-camera-system.md)
- **Official:** https://docs.unrealengine.com/5.7/en-US/gameplay-cameras-in-unreal-engine/

- **用途：** 模块化相机管理（相机模式、混合、上下文感知相机）
- **适用场景：** 需要动态相机行为的游戏（第三人称、瞄准、载具）
- **知识缺口：** UE 5.5 新增，完全处于知识截止之后
- **状态：** ⚠️ 实验性（UE 5.5-5.8；在 5.8 中仍标记为 Experimental）
- **插件：** `GameplayCameras`（内置，在 Plugins 中启用）
- **详细文档：** [plugins/gameplay-camera-system.md](plugins/gameplay-camera-system.md)
- **官方文档：** https://docs.unrealengine.com/5.7/en-US/gameplay-cameras-in-unreal-engine/

---

### ✅ PCG (Procedural Content Generation)
### ✅ PCG（程序化内容生成）

- **Purpose:** Node-based procedural world generation (foliage, props, terrain details)
- **When to use:** Open worlds, procedural levels, large-scale environment population
- **Knowledge Gap:** Experimental in UE 5.0-5.6, production-ready in 5.7; 5.8 adds manual editing, complex attributes and embedded subgraphs
- **Status:** Production-Ready (as of UE 5.7)
- **Plugin:** `PCG` (built-in, enable in Plugins)
- **Detailed Docs:** [plugins/pcg.md](plugins/pcg.md)
- **Official:** https://docs.unrealengine.com/5.7/en-US/procedural-content-generation-in-unreal-engine/

- **用途：** 基于节点的程序化世界生成（植被、道具、地形细节）
- **适用场景：** 开放世界、程序化关卡、大规模环境填充
- **知识缺口：** UE 5.0-5.6 中为实验性，5.7 中生产就绪；5.8 新增手动编辑、复杂属性与内嵌子图
- **状态：** 生产就绪（自 UE 5.7 起）
- **插件：** `PCG`（内置，在 Plugins 中启用）
- **详细文档：** [plugins/pcg.md](plugins/pcg.md)
- **官方文档：** https://docs.unrealengine.com/5.7/en-US/procedural-content-generation-in-unreal-engine/

---

## Other Plugins (Brief Overview)
## 其他插件（简要概述）

### 🟡 Mass Entity
### 🟡 Mass Entity

- **Purpose:** High-performance ECS for large-scale AI/crowds (10,000+ entities)
- **When to use:** RTS, city simulators, massive crowds, large-scale AI
- **Status:** `MassGameplay` and `MassCrowd` are flagged Experimental in 5.8. 5.8 overhauled Mass: Mass Signals moved into the core engine, entities can be created off the game thread, and a new MassCore module separates the core entity system from MassGameplay
- **Plugin:** `MassGameplay`, `MassCrowd` (MassEntity is engine code in 5.8, not a plugin)
- **Official:** https://docs.unrealengine.com/5.7/en-US/mass-entity-in-unreal-engine/

- **用途：** 面向大规模 AI/人群的高性能 ECS（10,000+ 实体）
- **适用场景：** RTS、城市模拟、大规模人群、大规模 AI
- **状态：** `MassGameplay` 和 `MassCrowd` 在 5.8 中标记为 Experimental。5.8 对 Mass 进行了全面改造：Mass Signals 移入核心引擎，实体可在游戏线程之外创建，新的 MassCore 模块将核心实体系统与 MassGameplay 分离
- **插件：** `MassGameplay`、`MassCrowd`（5.8 中 MassEntity 是引擎代码，不是插件）
- **官方文档：** https://docs.unrealengine.com/5.7/en-US/mass-entity-in-unreal-engine/

---

### 🟡 Niagara Fluids
### 🟡 Niagara Fluids

- **Purpose:** GPU fluid simulation (smoke, fire, liquids)
- **When to use:** Realistic fire/smoke effects, water simulation
- **Status:** Beta (5.8 flag)
- **Plugin:** `NiagaraFluids` (built-in)
- **Official:** https://docs.unrealengine.com/5.7/en-US/niagara-fluids-in-unreal-engine/

- **用途：** GPU 流体模拟（烟雾、火焰、液体）
- **适用场景：** 逼真的火焰/烟雾效果、水体模拟
- **状态：** Beta（5.8 标记）
- **插件：** `NiagaraFluids`（内置）
- **官方文档：** https://docs.unrealengine.com/5.7/en-US/niagara-fluids-in-unreal-engine/

---

### 🟡 Water Plugin
### 🟡 Water 插件

- **Purpose:** Ocean, river, lake rendering with buoyancy
- **When to use:** Games with water bodies, boats, swimming
- **Status:** Experimental (5.8 flag)
- **Plugin:** `Water` (built-in)
- **Official:** https://docs.unrealengine.com/5.7/en-US/water-system-in-unreal-engine/

- **用途：** 海洋、河流、湖泊渲染，支持浮力
- **适用场景：** 包含水体、船只、游泳的游戏
- **状态：** 实验性（5.8 标记）
- **插件：** `Water`（内置）
- **官方文档：** https://docs.unrealengine.com/5.7/en-US/water-system-in-unreal-engine/

---

### 🟡 Landmass Plugin
### 🟡 Landmass 插件

- **Purpose:** Terrain sculpting and landscape editing
- **When to use:** Large-scale terrain modification, procedural landscapes
- **Status:** Beta (5.8 flag)
- **Plugin:** `Landmass` (built-in)
- **Official:** https://docs.unrealengine.com/5.7/en-US/landmass-plugin-in-unreal-engine/

- **用途：** 地形雕刻与场景观编辑
- **适用场景：** 大规模地形修改、程序化场景观
- **状态：** Beta（5.8 标记）
- **插件：** `Landmass`（内置）
- **官方文档：** https://docs.unrealengine.com/5.7/en-US/landmass-plugin-in-unreal-engine/

---

### 🟡 Chaos Destruction
### 🟡 Chaos Destruction

- **Purpose:** Real-time fracture and destruction
- **When to use:** Destructible environments (walls, buildings, objects)
- **Status:** Beta (5.8 flag on `GeometryCollectionPlugin`)
- **Plugin:** `GeometryCollectionPlugin` (built-in)
- **Official:** https://docs.unrealengine.com/5.7/en-US/destruction-in-unreal-engine/

- **用途：** 实时破碎与破坏
- **适用场景：** 可破坏环境（墙壁、建筑、物体）
- **状态：** Beta（`GeometryCollectionPlugin` 上的 5.8 标记）
- **插件：** `GeometryCollectionPlugin`（内置）
- **官方文档：** https://docs.unrealengine.com/5.7/en-US/destruction-in-unreal-engine/

---

### 🟡 Chaos Vehicle
### 🟡 Chaos Vehicle

- **Purpose:** Advanced vehicle physics (wheeled vehicles, suspension)
- **When to use:** Racing games, vehicle-heavy gameplay
- **Status:** Experimental (5.8 flag; replaces PhysX Vehicles)
- **Plugin:** `ChaosVehiclesPlugin` (built-in)
- **Official:** https://docs.unrealengine.com/5.7/en-US/chaos-vehicles-overview-in-unreal-engine/

- **用途：** 高级载具物理（轮式载具、悬挂）
- **适用场景：** 竞速游戏、载具密集型玩法
- **状态：** 实验性（5.8 标记；取代 PhysX Vehicles）
- **插件：** `ChaosVehiclesPlugin`（内置）
- **官方文档：** https://docs.unrealengine.com/5.7/en-US/chaos-vehicles-overview-in-unreal-engine/

---

### 🟡 Geometry Scripting
### 🟡 Geometry Scripting

- **Purpose:** Runtime procedural mesh generation and editing
- **When to use:** Dynamic mesh creation, procedural modeling
- **Status:** Production-Ready (UE 5.1+)
- **Plugin:** `GeometryScripting` (built-in)
- **Official:** https://docs.unrealengine.com/5.7/en-US/geometry-scripting-in-unreal-engine/

- **用途：** 运行时程序化网格生成与编辑
- **适用场景：** 动态网格创建、程序化建模
- **状态：** 生产就绪（UE 5.1+）
- **插件：** `GeometryScripting`（内置）
- **官方文档：** https://docs.unrealengine.com/5.7/en-US/geometry-scripting-in-unreal-engine/

---

### 🟡 Motion Design Tools
### 🟡 Motion Design 工具

- **Purpose:** Motion graphics, procedural animation, keyframe animation
- **When to use:** UI animations, procedural motion, keyframed sequences
- **Status:** Experimental → Production-Ready (UE 5.4+)
- **Plugin:** `MotionDesign` (built-in)
- **Official:** https://docs.unrealengine.com/5.7/en-US/motion-design-mode-in-unreal-engine/

- **用途：** 动态图形、程序化动画、关键帧动画
- **适用场景：** UI 动画、程序化运动、关键帧序列
- **状态：** 实验性 → 生产就绪（UE 5.4+）
- **插件：** `MotionDesign`（内置）
- **官方文档：** https://docs.unrealengine.com/5.7/en-US/motion-design-mode-in-unreal-engine/

---

## Experimental Plugins (Use with Caution)
## 实验性插件（谨慎使用）

### ⚠️ AI Assistant (UE 5.7+)
### ⚠️ AI Assistant（UE 5.7+）

- **Purpose:** In-editor AI guidance and help
- **Status:** Experimental
- **Plugin:** `AIAssistant` (Experimental, off by default in 5.8)
- **Official:** Announced in UE 5.7 release

- **用途：** 编辑器内 AI 指导与帮助
- **状态：** 实验性
- **插件：** `AIAssistant`（Experimental，5.8 中默认关闭）
- **官方文档：** 在 UE 5.7 发行中公布

---

### ⚠️ MCP Server (UE 5.8+)
### ⚠️ MCP Server（UE 5.8+）

- **Purpose:** Lets agentic AI systems connect to the Unreal Editor to understand the engine and project and help build assets or systems
- **Status:** Experimental
- **Official:** UE 5.8 release notes, *MCP Server (Experimental)*

- **用途：** 让智能体式 AI 系统连接到 Unreal Editor，以理解引擎与项目，并协助构建资产或系统
- **状态：** 实验性
- **官方文档：** UE 5.8 发行说明，*MCP Server (Experimental)*

---

### ⚠️ Mover / ChaosMover
### ⚠️ Mover / ChaosMover

- **Purpose:** Character and object movement framework with rollback and prediction
- **Status:** Experimental (5.8 flag). 5.8 continues "the architectural work toward moving Mover out of Experimental status"
- **5.8 change:** PhysicsMover / NetworkPhysicsLiaison code was removed from the Mover plugin; use `ChaosMover`

- **用途：** 支持回滚与预测的角色和物体移动框架
- **状态：** 实验性（5.8 标记）。5.8 继续推进"旨在让 Mover 脱离实验性状态的架构工作"
- **5.8 变更：** PhysicsMover / NetworkPhysicsLiaison 代码已从 Mover 插件中移除；请使用 `ChaosMover`

---

### ⚠️ OpenXR (VR/AR)
### ⚠️ OpenXR（VR/AR）

- **Purpose:** Cross-platform VR/AR support
- **When to use:** VR/AR games
- **Status:** Production-Ready for VR, Experimental for AR
- **Plugin:** `OpenXR` (built-in)
- **Official:** https://docs.unrealengine.com/5.7/en-US/openxr-in-unreal-engine/

- **用途：** 跨平台 VR/AR 支持
- **适用场景：** VR/AR 游戏
- **状态：** VR 生产就绪，AR 实验性
- **插件：** `OpenXR`（内置）
- **官方文档：** https://docs.unrealengine.com/5.7/en-US/openxr-in-unreal-engine/

---

### ⚠️ Online Subsystem (EOS, Steam, etc.)
### ⚠️ Online Subsystem（EOS、Steam 等）

- **Purpose:** Platform-agnostic online services (matchmaking, friends, achievements)
- **When to use:** Multiplayer games with online features
- **Status:** Production-Ready
- **Plugin:** `OnlineSubsystem`, `OnlineSubsystemEOS`, `OnlineSubsystemSteam`
- **Official:** https://docs.unrealengine.com/5.7/en-US/online-subsystem-in-unreal-engine/

- **用途：** 与平台无关的在线服务（匹配、好友、成就）
- **适用场景：** 具备在线功能的多玩家游戏
- **状态：** 生产就绪
- **插件：** `OnlineSubsystem`、`OnlineSubsystemEOS`、`OnlineSubsystemSteam`
- **官方文档：** https://docs.unrealengine.com/5.7/en-US/online-subsystem-in-unreal-engine/

---

## Deprecated Plugins (Avoid for New Projects)
## 已弃用的插件（新项目请避免使用）

### ❌ PhysX Vehicles
### ❌ PhysX Vehicles

- **Deprecated:** Use Chaos Vehicles instead
- **Status:** Legacy, not recommended

- **已弃用：** 请改用 Chaos Vehicles
- **状态：** 遗留，不推荐

---

### ❌ Old Replication Graph
### ❌ 旧版 Replication Graph

- **Deprecated:** Replaced by Iris (UE 5.1+)
- **Status:** Use Iris for modern networking. Note: in 5.8 the `ReplicationGraph` plugin carries a Beta flag and no deprecation flag, so this is guidance, not an engine deprecation

- **已弃用：** 由 Iris 取代（UE 5.1+）
- **状态：** 现代网络请使用 Iris。注意：在 5.8 中 `ReplicationGraph` 插件带有 Beta 标记，且没有弃用标记，因此这是建议而非引擎层面的弃用

---

### ❌ Raw Input
### ❌ Raw Input

- **Deprecated:** In UE 5.8 (`"DeprecatedEngineVersion": "5.8"`)
- **Status:** Use the Game Input for Windows plugin (`GameInputWindows`, Beta)

- **已弃用：** 于 UE 5.8（`"DeprecatedEngineVersion": "5.8"`）
- **状态：** 请使用 Game Input for Windows 插件（`GameInputWindows`，Beta）

---

## On-Demand WebSearch Strategy
## 按需 WebSearch 策略

For plugins NOT listed above, use the following approach when users ask:

对于上文未列出的插件，当用户询问时请采用以下方法：

1. **WebSearch** for latest documentation: `"Unreal Engine 5.8 [plugin name]"`
2. Verify if plugin is:
   - Post-cutoff (beyond May 2025 training data)
   - Experimental vs Production-Ready
   - Still supported in UE 5.8
3. Optionally cache findings in `plugins/[plugin-name].md` for future reference

1. 使用 **WebSearch** 查找最新文档：`"Unreal Engine 5.8 [plugin name]"`
2. 核实插件是否：
   - 处于知识截止之后（超出 2025 年 5 月的训练数据）
   - 实验性还是生产就绪
   - 在 UE 5.8 中仍受支持
3. 可选地将结果缓存到 `plugins/[plugin-name].md` 以便后续参考

---

## Quick Decision Guide
## 快速决策指南

**I need abilities/skills/buffs** → **Gameplay Ability System (GAS)**
**I need cross-platform UI (console + PC)** → **CommonUI**
**I need dynamic cameras** → **Gameplay Camera System**
**I need procedural worlds** → **PCG**
**I need large crowds (1000s of AI)** → **Mass Entity**
**I need destructible environments** → **Chaos Destruction**
**I need vehicles** → **Chaos Vehicles**
**I need water/oceans** → **Water Plugin**
**I need VR/AR** → **OpenXR**

**我需要能力/技能/增益** → **Gameplay Ability System（GAS）**
**我需要跨平台 UI（主机 + PC）** → **CommonUI**
**我需要动态相机** → **Gameplay Camera System**
**我需要程序化世界** → **PCG**
**我需要大规模人群（数千 AI）** → **Mass Entity**
**我需要可破坏环境** → **Chaos Destruction**
**我需要载具** → **Chaos Vehicles**
**我需要水体/海洋** → **Water 插件**
**我需要 VR/AR** → **OpenXR**

---

**Last Updated:** 2026-10-17
**Engine Version:** Unreal Engine 5.8
**Sources (5.8):** UE 5.8 release notes https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-5-8-release-notes?application_version=5.8 (Mass, Iris, Mover, MCP Server, Raw Input upgrade note); `.uplugin` files in a UE 5.8.1 install, paths in the status table above
**LLM Knowledge Cutoff:** May 2025

**最后更新：** 2026-10-17
**引擎版本：** Unreal Engine 5.8
**来源（5.8）：** UE 5.8 发行说明 https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-5-8-release-notes?application_version=5.8（Mass、Iris、Mover、MCP Server、Raw Input 升级说明）；UE 5.8.1 安装中的 `.uplugin` 文件，路径见上方状态表
**LLM 知识截止：** 2025 年 5 月
