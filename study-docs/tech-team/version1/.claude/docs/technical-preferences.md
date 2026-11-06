# Technical Preferences — 技术配置契约

> 本文件由 `/setup-engine` 写入,被 `/dev-story` / `/code-review` / `/architecture-decision` 等读取。
> 引擎与知识源已预填,`/setup-engine` 只问剩余 5 项。

---

## Engine
- **Engine**: Unreal Engine 5.8
- **Knowledge Source**: Context7 MCP(运行时查 UE 5.8 API,见 [knowledge-authority.md](file:///workspace/study-docs/tech-team/version1/.claude/docs/knowledge-authority.md))
- **Primary Language**: C++
- **Secondary Language**: Blueprint(内容/原型)
- **Source Root**: `Source/`(对应逻辑层 `Source/core` `Source/gameplay` `Source/ai` `Source/ui` `Source/network`)
- **Asset Root**: `Content/`

---

## Target Platform
<!-- /setup-engine 填,如 Windows / macOS / Console / Mobile / VR -->
- [TO BE CONFIGURED]

---

## Input
<!-- /setup-engine 填 -->
- **Scheme**: [TO BE CONFIGURED]  <!-- Keyboard+Mouse / Gamepad / Both / Touch -->
- **Framework**: Enhanced Input(UE 5.x 默认)

---

## Naming Conventions
<!-- /setup-engine 填,以下为 UE 默认建议,可改 -->
- **C++ Class**: `U`/`A`/`F`/`I`/`S` 前缀(UObject/Actor/Struct/Interface/Slate)
- **Header**: `PascalCase.h`,与类同名
- **Source**: `PascalCase.cpp`
- **Blueprint**: `BP_<PascalCase>`
- **DataAsset**: `DA_<PascalCase>`
- **DataTable**: `DT_<PascalCase>`
- **Enum**: `E<PascalCase>`
- **Member Variable**: `b<P>`(bool)/`<P>`(其余),private 加 `_` 前缀
- **Method**: `<verb><Object>`(PascalCase)

---

## Performance Budget
<!-- /setup-engine 填 -->
- **Target FPS**: [TO BE CONFIGURED]  <!-- 30 / 60 / 90(VR) / 120 -->
- **Frame Budget (ms)**: [TO BE CONFIGURED]  <!-- 16.67 @60fps -->
- **CPU Budget**: [TO BE CONFIGURED]
- **GPU Budget**: [TO BE CONFIGURED]
- **Memory Cap**: [TO BE CONFIGURED]
- **Network Bandwidth (if multiplayer)**: [TO BE CONFIGURED]

---

## Testing
<!-- /setup-engine 填 -->
- **Framework**: Unreal Automation Tests(`IMPLEMENT_SIMPLE_AUTOMATION_TEST` / `IMPLEMENT_COMPLEX_AUTOMATION_TEST`)
- **Minimum Coverage**: [TO BE CONFIGURED]  <!-- 如 Logic story 100% 覆盖 -->
- **Test Location**: `tests/`(独立测试模块)或 Source 内 `*.Tests.cpp`
- **CI**: [TO BE CONFIGURED]  <!-- 如 Jenkins / GitHub Actions / None -->

---

## Build & VCS
- **VCS**: Git
- **Branch Strategy**: [TO BE CONFIGURED]  <!-- trunk-based / gitflow -->
- **Build System**: UnrealBuildTool
- **Build Commands**:
  - Build: `Engine/Binaries/DotNET/UnrealBuildTool/<Project>Editor Win64 Development -Project=<uproject>`
  - Cook: `Engine/Build/BatchFiles/RunUAT.bat BuildCookRun -project=<uproject> -cook -stage -pak`
- **LFS**: 建议启用(Content 二进制资产)

---

## 状态
> **Setup Status**: [TO BE CONFIGURED]
> 完成 `/setup-engine` 后改为 `Configured`,并填完上述 `[TO BE CONFIGURED]`。
