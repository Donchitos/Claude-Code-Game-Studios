# asset-audit — 资产审计（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/asset-audit/SKILL.md) ｜ 阶段：Phase 6 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/asset-audit [category|all]`
- **一句话职责**：按命名约定、文件体积预算、格式标准审计资产，找出孤儿资产与缺失引用。只读诊断技能——无专家代理派生。
- **触发前置**：可测量的资产文件存在；体积预算/格式/命名标准来自 `design/art/art-bible.md` 的 Asset Standards 节（或相关设计文档）；引擎与代码根可解析。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | `design/art/art-bible.md` 的 Asset Standards 节（按节读：Grep `^#` 定位 + Read offset/limit）及相关设计文档中的资产标准；资产根目录文件列表（Glob）；每文件的测量值（`stat`/`file`/`od`/`wc`/`du`）；代码根的资产引用（Grep） | 标准 / 扫描对象 / 体积·格式·孤儿判定 |
| 产出 | 审计报告（会话内输出）——本技能只读，产出报告但不写任何文件 | 报告含 `Sections not assessed` 清单 |
| 派生智能体 | 无，主会话直接执行 | 只读诊断，无需专家 |

## 3. 核心规则（逐条编号 R1、R2……）

### 测量纪律
R1. 本技能报告需要文件体积对预算、纹理尺寸（2 的幂）、音频采样率、孤儿检测用的最后修改时间——这些都无法从 Read/Glob/Grep 获得，只允许预批准的只读测量命令 `stat`、`file`、`od`、`wc`、`du`；用 Glob 列文件；其它任何命令先征求同意。（测量前言）
R2. 无法测量的格必须记 `NOT ASSESSED`，**绝不估算**。用猜测填的体积预算表比空表更糟——它看起来像证据。这在满是真资产的项目上也是活体造假向量：模板若索取工具白名单给不出的数字表，完成它的唯一方式就是编造。（测量前言）

### 输入不足前置检查
R3. 产出任何报告前先核对本技能所需输入的存在性：
   1. 列出全部输入（数据文件、先前报告、profiler 输出、测试结果、registry、源代码）；
   2. 逐项记 `FOUND` 或 `ABSENT`（不是"假设存在"）；
   3. 某节必需输入 ABSENT 时该节记 **`NOT ASSESSED — NO DATA`**——禁止估算、禁止从相邻工件推断、禁止把必填格留给下次读模板的人；
   4. **每一个**必需输入都 ABSENT 时停止并整体报告 `NOT ASSESSED — NO DATA`，点名缺了什么、哪个技能产出它。（Insufficient input）
R4. `NOT ASSESSED` 裁决是成功——它是"数据说什么"在无数据时的正确答案；禁止产生假性干净通过。"无证据"绝不是"不存在证据"：零文件可扫的扫描没有验证任何东西，必须说明是哪一种。（Insufficient input）

### Phase 1 — 读标准
R5. 读 art bible 的 Asset Standards 节（`design/art/art-bible.md`，按节读）与相关设计文档中的任何资产标准——体积预算与格式规则来自那里；命名模式默认用 Phase 3 的，除非 art bible 自定。两者都不给体积预算、或无 art bible 时，Size 节记 `NOT ASSESSED — no size budget set`，且报告点名 `/art-bible`（其 Asset Standards 节设定预算、格式与命名约定）。（Phase 1）

### Phase 2 — 扫描资产目录
R6. 资产位于引擎的资产根：Godot `assets/`、Unity `Assets/`、Unreal `Content/`；按 `.claude/docs/code-root-resolution.md` 解析引擎与代码根——Phase 3 的孤儿与缺失资产搜索读的是该代码根。解析失败即停止：`NOT ASSESSED — engine unresolved`，点名 `/setup-engine`。（Phase 2）
R7. 按引擎用 Glob 扫描：Godot——`assets/art/**/*`、`assets/audio/**/*`、`assets/vfx/**/*`、`assets/shaders/**/*`、`assets/data/**/*`；Unity——`Assets/**/*`（排除脚本 `*.cs`、`*.asmdef` 与 `*.meta`）；Unreal——`Content/**/*.uasset` 与 `Content/**/*.umap`。匹配的文件数即 Total assets scanned；为零时，对扫描文件的检查（Naming、Size、Format、Orphaned）记 `NOT ASSESSED — no assets under <asset root>`——缺失资产搜索仍执行。（Phase 2）

### Phase 3 — 合规检查
R8. 命名约定（Godot 系）：Art `[category]_[name]_[variant]_[size].[ext]`；Audio `[category]_[context]_[name]_[variant].[ext]`；全部文件小写加下划线。Unity 与 Unreal 以 PascalCase 命名，这两个引擎只对照 art bible 明示的命名规则检查；无规则时 Naming 记 `NOT ASSESSED — no naming rule for <engine>`（点名 `/art-bible`）。（Phase 3）
R9. 文件标准：
   - **纹理**——2 的幂尺寸、正确格式（UI 用 PNG、3D 用压缩格式）、体积在预算内；
   - **音频**——正确采样率与格式（SFX 用 OGG、音乐 OGG/MP3）、时长在限内——但 `file` 只报格式与采样率不报时长且无预批准工具可测，故时长预算记 `NOT ASSESSED — duration not measurable here`，点名其覆盖的文件；
   - **数据**——合法 JSON/YAML 且符合 schema；
   - **Unreal 特例**——资产文件（`.uasset`/`.umap`）不保留源文件格式与尺寸，Format 在该引擎记 `NOT ASSESSED`，体积仍测量。（Phase 3）
R10. 孤儿资产：在代码根搜索对每个资产文件的引用，无引用者标记。缺失资产：在代码根搜索资产引用并验证文件存在。两项搜索都需要代码：代码根无源文件时 Orphaned 与 Missing 记 `NOT ASSESSED — no code to search`；Unity 与 Unreal 上多数资产引用位于场景、prefab 与其它资产而非代码，代码未命名的资产仍可能在使用中——Orphaned 在这两个引擎记 `NOT ASSESSED`。（Phase 3）

### Phase 4 — 输出与裁决
R11. 报告结构：
   ```
   # Asset Audit Report -- [Category] -- [Date]
   ## Summary（Total assets scanned / Naming violations / Size violations / Format
   violations / Orphaned assets / Missing assets 各计数 + Sections not assessed：none 或逐节及原因）
   ## Naming Violations 表（File | Expected Pattern | Issue）
   ## Size Violations 表（File | Budget | Actual | Overage）
   ## Format Violations 表（File | Expected Format | Actual Format）
   ## Orphaned Assets 表（File | Last Modified | Size | Recommendation）
   ## Missing Assets 表（Reference Location | Expected Path）
   ## Recommendations——按违规优先级排列，每违规一条并点名改法
   （体积违规给目标分辨率或压缩、命名违规给修正名、格式违规给目标格式）
   ## Verdict: [...]
   ```（Phase 4）
R12. 裁决按发现首匹配：
   - **NON-COMPLIANT**——任何体积违规，或任何被代码引用但不存在的资产；
   - **WARNINGS**——仅命名、格式或孤儿资产发现；
   - **NOT ASSESSED**——审计未覆盖其范围：完全无数据（上述路径）、零资产扫描、或任何节 `NOT ASSESSED`——点名是哪些；低于两个发现裁决（测得的违规比缺口更可行动）、高于 COMPLIANT；
   - **COMPLIANT**——至少扫描了一个资产、每个节都已评估、无任何发现。（Phase 4）

### Phase 5 — 后续
R13. 审计后：按 Phase 3 模式（或 art bible 自定处）修复命名违规；标准缺失时运行 `/art-bible` 写其 Asset Standards 节；人工复核后删除已确认的孤儿资产；运行 `/content-audit` 交叉核对资产数与 GDD 规定的需求。（Phase 5）

## 4. 门禁与裁决
- **裁决词**：`NOT ASSESSED` / `COMPLIANT` / `WARNINGS` / `NON-COMPLIANT`。
- **排序（首匹配）**：NON-COMPLIANT > WARNINGS > NOT ASSESSED > COMPLIANT（NOT ASSESSED 低于两个发现裁决、高于 COMPLIANT——测得的违规比缺口更可行动）。
- **取最严原则**：任何体积违规或"被引用但不存在"的资产即整体 NON-COMPLIANT；任何节 NOT ASSESSED 整体不得低于 NOT ASSESSED 档。
- **消费方**：`/art-bible`（补标准）、`/content-audit`（资产数交叉核对）、人工孤儿清理。

## 5. 移植建议
- **可直接移植**：R1-R4（测量纪律与"不可测即 NOT ASSESSED 绝不估算"）、R5 的无标准降级、R10 的"引用不在代码里就不可判孤儿"引擎差异处理、R12 首匹配裁决排序、报告模板（含 Sections not assessed 行）。
- **需替换概念**：资产 → 任何二进制/媒体产物（图片、字体、模型、音视频）；art bible → 品牌规范 / 资产规范文档；纹理 2 的幂与音频采样率 → 按产物类型换成尺寸/码率/压缩档预算；引擎资产根（assets/Assets/Content）→ 项目产物目录。
- **改写示例**：
  - R2 → "凡测量工具拿不到的数据格必须记 NOT ASSESSED，绝不估算。用猜测填出的预算表比空表更糟——它看起来像证据；模板索取工具给不出的数字时，完成它的唯一方式就是编造。"
  - R10 → "孤儿判定依赖代码搜索：代码根无源文件时孤儿与缺失两项均记 NOT ASSESSED — no code to search；引用主要存在于配置或其它资产而非代码的平台（如场景/prefab），孤儿判定记 NOT ASSESSED——未命中不等于未使用。"

## 6. 关联文档
- 上游：`/art-bible`（产出 Asset Standards 节：预算、格式、命名约定）、`/setup-engine`（引擎与代码根解析）。
- 下游：`/content-audit`（资产数对 GDD 规定数的交叉核对）、`/asset-spec`（规格来源，被审计对象）。
- 引用：`.claude/docs/code-root-resolution.md`。
