# Windows Internal Release 导出

## 环境与模板来源

- Godot：`4.7.1.stable.official.a13da4feb`
- 导出预设：`Windows Internal`，x86_64，release，不签名
- 官方模板包：`Godot_v4.7.1-stable_export_templates.tpz`
- 模板包大小：`1,280,486,955` bytes
- SHA512：`afcc83d8d3d298038f19c58744a0d660fa75dd4baa33cb55d1011bb2565a2a8c2381728924564cb909e37c205a23f21b521b23bd057993afd43ae4da0b2f9d47`

下载后先核对官方SHA512，再从包内只安装`windows_debug_x86_64.exe`与`windows_release_x86_64.exe`到本机`4.7.1.stable`模板目录；已有`ios.zip`与`version.txt`未覆盖。

## 导出结果

执行：

```text
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --export-release "Windows Internal" build/windows-internal/TrialInternal.exe
```

命令exit 0，资源打包102 steps完成，新增`BatchedCombatRenderer`被编译并装入PCK。输出：

| 文件 | 类型 | 大小 | SHA256 |
| --- | --- | --- | --- |
| `build/windows-internal/TrialInternal.exe` | PE32+ GUI x86-64 Windows executable | 104 MiB | `4e5e07b73a38be1452888ba41c0a7a8729abe601cbf47aca726857b524a79404` |
| `build/windows-internal/TrialInternal.pck` | Godot data pack | 14 MiB | `cb1b09ebf1a6821cd6ff0a52e393beaaaef1106de1135ee2e713f64fbe501fc3` |

## 边界

这是macOS主机上的Windows release交叉导出证据，只证明匹配版本模板可用、项目资源能完成release编译和打包、产物类型与hash可记录。本机没有Wine，也没有Windows设备，因此未执行Windows启动、D3D12/Compatibility renderer、物理键盘、手柄、焦点/暂停、性能、崩溃恢复或安装包验证。

状态保持`runtime/device verified=false`、`battle_ready=false`。下一步应把这两个hash固定到Windows实机测试记录，并在实际运行前后确认产物未变化。
