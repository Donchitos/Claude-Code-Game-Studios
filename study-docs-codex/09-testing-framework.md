# 09 自测框架与质量方法

## 1. 测试的对象

`CCGS Skill Testing Framework/` 测试的是 CCGS 的 Skill 和 Agent 指令，不是游戏。它是自包含的 QA 层，主框架运行不依赖它；删除后游戏工作流仍能运行，但 `/skill-test` 的 spec/category/audit 能力会失去目录和规格来源。

这种测试大多是“读取提示词并按断言判断”，不是执行每个 Skill 的端到端自动化测试。因此它擅长发现结构缺失、协议不一致和明确行为遗漏，但不能替代真实 Claude Code 会话、Hook 模拟或游戏测试。

## 2. 四种模式

### static

```text
/skill-test static help
/skill-test static all
```

检查 frontmatter、阶段结构、Verdict、协作协议、下一步、上下文复杂度和参数提示等七项静态规范。

### spec

```text
/skill-test spec gate-check
```

读取 Skill 和对应行为规格，逐个评估 Fixture、Expected behavior 和 Assertions。它验证“在某个假设项目状态下，Skill 文本是否明确要求正确行为”。

### category

```text
/skill-test category design-system
/skill-test category all
```

按类别量表检查。例如 authoring 类关注逐章节批准、retrofit、骨架优先和 Gate 模式；analysis 类关注只读扫描、结构化发现和禁止自动写入。

### audit

```text
/skill-test audit
```

汇总每个 Skill/Agent 是否有规格、最后测试时间和结果，主要用于覆盖率管理。

## 3. 目录结构

```text
CCGS Skill Testing Framework/
├── catalog.yaml
├── quality-rubric.md
├── skills/<category>/<name>.md
├── agents/<tier>/<name>.md
├── templates/
└── results/                 # 运行时结果，通常忽略版本控制
```

`catalog.yaml` 是规格路径的权威索引，不应根据名字猜路径。规格描述当前预期行为，不一定代表理想设计；真实使用中发现缺陷时，应先判断 Skill 是否应修复，再更新规格。

## 4. 当前覆盖观察

仓库主目录有 73 个 Skill，但测试规格类别合计 72 个：

- analysis 12
- authoring 7
- gate 1
- pipeline 6
- readiness 2
- review 3
- sprint 6
- team 9
- utility 26

差异来自 `vertical-slice`：主框架已有 `.claude/skills/vertical-slice/SKILL.md`，当前测试 catalog 和 spec 目录尚未登记。49 个 Agent 均能在测试规格目录找到同名规格。

这是很好的维护练习：新增能力时，代码/提示词、参考清单、测试目录和 README 计数必须一起更新。

## 5. 验证金字塔

对 CCGS 的合理验证组合是：

1. 格式层：JSON/YAML/frontmatter、Bash 语法；
2. 静态层：`/skill-test static`；
3. 规格层：spec 和 category；
4. 集成层：在临时项目中真实运行 Skill，观察文件、停顿和 Agent 路由；
5. 结果层：人工评审生成工件是否真的可用。

只通过 static 不代表行为正确；只做一次真实会话又很难稳定覆盖边界条件。

## 6. 最小验证命令

```bash
python -m json.tool .claude/settings.json
sed 's/\r$//' .claude/statusline.sh | bash -n
for f in .claude/hooks/*.sh; do sed 's/\r$//' "$f" | bash -n || exit 1; done
```

管道中的 `sed` 用于兼容 Windows `core.autocrlf=true` 产生的 CRLF checkout，
只规范化检查输入，不修改文件。真实运行前仍应确保 Hook 文件为 LF。

然后在 Claude Code 中：

```text
/skill-test static help
/skill-test category gate-check
/skill-test audit
```

这些检查可能提示是否写入 `results/` 或更新 catalog。先查看草稿和 `git diff`，再批准写入。

## 7. 如何为新 Skill 写规格

1. 选择最贴近的 category；
2. 复制 `templates/skill-test-spec.md`；
3. 写至少正常、缺参数、缺上游、拒绝写入、Agent 阻塞等案例；
4. 把路径登记到 `catalog.yaml`；
5. 运行 spec 和 category；
6. 在临时分支做一次真实会话验证；
7. 更新 skills reference 和总计数。

## 本课检查

1. 为什么 spec 测试不等于端到端执行？
2. static、spec、category、audit 各回答什么问题？
3. 当前哪个 Skill 缺少规格登记？
4. 为什么测试规格也可能固化已有缺陷？
