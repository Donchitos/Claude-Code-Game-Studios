# Phase 6: Parse check and capture on Unity and Unreal

# 第 6 阶段：在 Unity 和 Unreal 上进行解析检查与捕获

Read only when the engine is Unity or Unreal. Report the command, its exit code
and any error lines. No executable: `parse NOT VERIFIED — engine binary not
available`.

仅在引擎为 Unity 或 Unreal 时阅读。报告命令、其退出码以及任何错误行。
没有可执行文件时：`parse NOT VERIFIED — engine binary not
available`。

## Unity

## Unity

**Parse check:** the `commands.smoke` command (`-batchmode -quit -projectPath .
-logFile -`). Exit 1 with `error CS…` lines means a script does not compile.

**解析检查：** 运行 `commands.smoke` 命令（`-batchmode -quit -projectPath .
-logFile -`）。退出码为 1 且出现 `error CS…` 行，表示某个脚本无法编译。

**Capture** needs `Assets/Scripts/ScreenshotOnArg.cs`, given word for word in
`run-and-observe.md` (named in `SKILL.md`, Phase 6). When the project has none
(look for `Assets/**/ScreenshotOnArg.cs`), ask "May I write
`Assets/Scripts/ScreenshotOnArg.cs`?" and write it exactly as given before
launching. Declined: nothing can capture, so report
`Run result: NOT VERIFIED — ScreenshotOnArg.cs not written`.

**捕获**需要 `Assets/Scripts/ScreenshotOnArg.cs`，其内容在
`run-and-observe.md` 中逐字给出（`SKILL.md` 的 Phase 6 中指明）。当项目中没有该文件时
（查找 `Assets/**/ScreenshotOnArg.cs`），询问"May I write
`Assets/Scripts/ScreenshotOnArg.cs`?"，并在启动之前按给定内容原样写入。
若被拒绝：则无法进行任何捕获，因此报告
`Run result: NOT VERIFIED — ScreenshotOnArg.cs not written`。

## Unreal

## Unreal

**Parse check:** build the editor target. A compile error fails it (`Result:
Failed`, non-zero exit).

**解析检查：** 构建编辑器目标。编译错误会使其失败（`Result:
Failed`，非零退出码）。

- Windows: `"<UE root>/Engine/Binaries/DotNET/UnrealBuildTool/UnrealBuildTool.exe" <Project>Editor Win64 Development -Project="<absolute path>/<Project>.uproject"`
- Linux: `"<UE root>/Engine/Build/BatchFiles/Linux/Build.sh" <Project>Editor Linux Development -Project=…`
- macOS: `"<UE root>/Engine/Build/BatchFiles/Mac/Build.sh" <Project>Editor Mac Development -Project=…`

- Windows：`"<UE root>/Engine/Binaries/DotNET/UnrealBuildTool/UnrealBuildTool.exe" <Project>Editor Win64 Development -Project="<absolute path>/<Project>.uproject"`
- Linux：`"<UE root>/Engine/Build/BatchFiles/Linux/Build.sh" <Project>Editor Linux Development -Project=…`
- macOS：`"<UE root>/Engine/Build/BatchFiles/Mac/Build.sh" <Project>Editor Mac Development -Project=…`

The commands are from Epic's documentation, as recorded in
`docs/engine-reference/unreal/current-best-practices.md` ("Command Line").

这些命令来自 Epic 的文档，记录于
`docs/engine-reference/unreal/current-best-practices.md`（"Command Line"）。

**Capture:** launch straight into the map the story touched, as
`run-and-observe.md` gives it.

**捕获：** 直接启动进入故事所涉及的地图，具体方式按
`run-and-observe.md` 中的说明。
