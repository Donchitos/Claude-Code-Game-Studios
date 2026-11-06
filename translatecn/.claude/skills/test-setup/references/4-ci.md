# /test-setup — Phase 4: Create CI/CD Workflow

# /test-setup — 第 4 阶段：创建 CI/CD 工作流

> Part of `/test-setup`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> 属于 `/test-setup` 的一部分。`SKILL.md` 指明何时阅读本文件；它解析出的设置
> 以及其后续标题下的规则在此仍然适用。

## Phase 4: Create CI/CD Workflow

## 第 4 阶段：创建 CI/CD 工作流

**In this file:**

**本文件内容：**

- Godot 4
- Unity
- Unreal Engine

- Godot 4
- Unity
- Unreal Engine

### Godot 4

Create `.github/workflows/tests.yml`:

创建 `.github/workflows/tests.yml`：

```yaml
name: Automated Tests

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    name: Run GdUnit4 Tests
    runs-on: ubuntu-latest
    # The action publishes its results as a check run. A new repository's
    # token is read-only, and without checks: write the job fails even when
    # every test passes. If you protect main, require the `Run GdUnit4 Tests` job
    # check, not `test-results`: that check run concludes success even when a
    # test fails.
    permissions:
      contents: read
      checks: write

    steps:
      - name: Checkout
        uses: actions/checkout@v7
        with:
          lfs: true

      # godot-version must be a full release such as 4.7.2 (`godot --version`
      # shows it); VERSION.md's "4.7" is not one. version: installed runs the
      # gdUnit4 committed in addons/ -- without it the action deletes that
      # copy and installs the latest release, which may not match your tests.
      - name: Run GdUnit4 Tests
        uses: godot-gdunit-labs/gdUnit4-action@v1
        with:
          godot-version: '[FULL GODOT VERSION, e.g. 4.7.2]'
          version: 'installed'
          paths: |
            tests/unit
            tests/integration
          report-name: test-results

      - name: Upload Test Results
        if: always()
        uses: actions/upload-artifact@v7
        with:
          name: test-results
          path: reports/
```

### Unity

Create `.github/workflows/tests.yml`:

创建 `.github/workflows/tests.yml`：

```yaml
name: Automated Tests

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    name: Run Unity Tests
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v7
        with:
          lfs: true

      - name: Run Edit Mode Tests
        uses: game-ci/unity-test-runner@v4
        env:
          UNITY_LICENSE: ${{ secrets.UNITY_LICENSE }}
        with:
          testMode: editmode
          artifactsPath: test-results/editmode

      - name: Run Play Mode Tests
        uses: game-ci/unity-test-runner@v4
        env:
          UNITY_LICENSE: ${{ secrets.UNITY_LICENSE }}
        with:
          testMode: playmode
          artifactsPath: test-results/playmode

      - name: Upload Test Results
        if: always()
        uses: actions/upload-artifact@v7
        with:
          name: test-results
          path: test-results/
```

Note: Unity CI requires a `UNITY_LICENSE` secret. Add to GitHub repository
secrets before the first CI run.

注意：Unity CI 需要一个 `UNITY_LICENSE` 密钥。请在首次 CI 运行之前将其添加到
GitHub 仓库密钥中。

### Unreal Engine

Create `.github/workflows/tests.yml`:

创建 `.github/workflows/tests.yml`：

```yaml
name: Automated Tests

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    name: Run UE Automation Tests
    runs-on: [self-hosted, windows]  # UE requires a local runner with the editor installed

    # The quoted "{0}" in each `shell:` below: the Windows runner passes bash
    # its script path unquoted, so with plain `shell: bash` every step fails
    # ("No such file or directory") when the runner's folder has a space.
    steps:
      - name: Checkout
        uses: actions/checkout@v7
        with:
          lfs: true

      # Binaries/ is gitignored, so a fresh checkout has no compiled game
      # module: without this step the editor stops with "The game module could
      # not be found" before running any test. UnrealBuildTool.exe, not
      # Build.bat -- from bash, Build.bat fails on an engine path with spaces.
      - name: Build Editor Target
        run: |
          "$UE_ROOT/Engine/Binaries/DotNET/UnrealBuildTool/UnrealBuildTool.exe" [ProjectName]Editor Win64 Development \
            -Project="${{ github.workspace }}/[ProjectName].uproject"
        shell: bash --noprofile --norc -eo pipefail "{0}"

      # -stdout -FullStdOutLogOutput: without them the editor prints nothing
      # here, and the results are only in Saved/Logs/.
      - name: Run Automation Tests
        run: |
          "$UE_ROOT/Engine/Binaries/Win64/UnrealEditor-Cmd.exe" "${{ github.workspace }}/[ProjectName].uproject" \
            -nullrhi -nosound \
            -ExecCmds="Automation RunTests [ProjectName].; Quit" \
            -unattended -stdout -FullStdOutLogOutput
        shell: bash --noprofile --norc -eo pipefail "{0}"

      - name: Upload Logs
        if: always()
        uses: actions/upload-artifact@v7
        with:
          name: test-logs
          path: Saved/Logs/
```

Note: UE CI requires a self-hosted Windows runner with Unreal Editor installed.
The `windows` label keeps the job off any Linux self-hosted runner the
repository also has. Set the `UE_ROOT` environment variable on the runner to the engine folder
(e.g. `C:/Program Files/Epic Games/UE_5.8`). `[ProjectName]Editor` is the
editor target in `Source/[ProjectName]Editor.Target.cs`. `actions/checkout@v7`
and `actions/upload-artifact@v7` run on Node.js 24, which needs Actions Runner
2.327.1 or newer: update the self-hosted runner before the first run
(https://github.com/actions/checkout/blob/v7.0.1/README.md).

注意：UE CI 需要一台已安装 Unreal Editor 的自托管 Windows 运行器。
`windows` 标签会让该作业避开仓库中同样存在的任何 Linux 自托管运行器。
请将运行器上的 `UE_ROOT` 环境变量设置为引擎文件夹
（例如 `C:/Program Files/Epic Games/UE_5.8`）。`[ProjectName]Editor` 是
`Source/[ProjectName]Editor.Target.cs` 中的编辑器目标。`actions/checkout@v7`
和 `actions/upload-artifact@v7` 运行在 Node.js 24 上，这需要 Actions Runner
2.327.1 或更高版本：请在首次运行之前更新自托管运行器
（https://github.com/actions/checkout/blob/v7.0.1/README.md）。

---
