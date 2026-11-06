# /setup-engine — Sections 8 and 8.5: Verify and Read Back

# /setup-engine — 第 8 节和第 8.5 节：验证与回读

> Part of `/setup-engine`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> 属于 `/setup-engine` 的一部分。`SKILL.md` 指明了何时读取本文件；它解析出的设置
> 及其后续标题下的规则在此同样适用。

## 8. Verify the CLAUDE.md Import

**This import was already written in Section 4 — do not edit it again and do not
ask again.** Section 4 sets it as part of the same CLAUDE.md write, anchored to
the `ENGINE-REFERENCE-IMPORT` marker. This step only confirms the result.

Read `CLAUDE.md` and confirm the line under the marker reads:

## 8. 验证 CLAUDE.md 导入

**这一导入已在第 4 节写入 —— 不要再编辑它，也不要
再次询问。** 第 4 节将其作为同一次 CLAUDE.md 写入的一部分设置，锚定于
`ENGINE-REFERENCE-IMPORT` 标记。这一步只确认结果。

读取 `CLAUDE.md`，确认标记下方的那一行读作：

```markdown
@docs/engine-reference/<engine>/VERSION.md
```

```markdown
@docs/engine-reference/<engine>/VERSION.md
```

with `<engine>` the engine just configured. If it still points at a different
engine, Section 4 did not complete — go back and finish it rather than patching
the line here.

其中 `<engine>` 是刚刚配置的引擎。如果它仍指向别的
引擎，说明第 4 节未完成 —— 回去完成它，而不是在这里
修补该行。

> **Why this is a check and not a second write.** Repeating the edit here with
> its own approval prompt would ask the user twice for one change, and the second
> ask would be for work already done. Locate the line by its marker, never by the
> `## Engine Version Reference` heading — the marker exists precisely so the line
> can still be found when the heading moves or is reworded.

> **为什么这是检查而不是第二次写入。** 在这里重复该编辑并附带
> 自己的批准提示，会为同一项更改向用户询问两次，而第二次
> 询问针对的是已完成的工作。通过其标记来定位该行，绝不要通过
> `## Engine Version Reference` 标题 —— 标记的存在正是为了在标题移动或
> 改写时仍能找到该行。

---

## 8.5 Read Back What You Just Wrote

Section 5.5.1's rendering/physics table warns against the two mistakes most
often made here, and it is still easy to make **both** of them, writing
`Forward+` and `Jolt` for a 2D browser game. Section 3's `Installed at pin time`
row is just as easy to drop silently, because a missing row leaves no trace.
Catch both by verifying the files after writing them:

```bash
bash .claude/scripts/project-coherence.sh
```

## 8.5 回读你刚刚写入的内容

第 5.5.1 节的渲染/物理表格警示了此处最常犯的两个错误，
而**同时**犯下**这两个**仍然很容易 —— 为 2D 浏览器游戏写上
`Forward+` 和 `Jolt`。第 3 节的 `Installed at pin time`
行也同样容易被悄悄遗漏，因为缺失的行不会留下任何痕迹。
通过在写入后验证文件来同时捕捉两者：

```bash
bash .claude/scripts/project-coherence.sh
```

It compares `project.yaml` against `docs/engine-reference/<engine>/VERSION.md`,
against `project.godot`, and against the engine binary actually on PATH, and it
checks that the files `commands.build` and `commands.test` name exist.

它将 `project.yaml` 与 `docs/engine-reference/<engine>/VERSION.md` 比较，
与 `project.godot` 比较，并与实际位于 PATH 上的引擎二进制比较，同时
检查 `commands.build` 和 `commands.test` 所命名的文件是否存在。

**Report every `[DIFFERS]` line to the user and resolve it before finishing.**
Each one means two files this skill just wrote disagree, or describe something
that is not there.

**向用户报告每一行 `[DIFFERS]`，并在完成前解决它。**
每一行都意味着本技能刚刚写入的两个文件彼此不一致，或描述了某种
并不存在的东西。

One is expected on a new Godot project: `commands.test` names the gdUnit4
runner under `addons/gdUnit4/`, which `/test-setup` installs later. Report that
line as expected, name `/test-setup` as the step that clears it, and never edit
`commands.test` to make it go away. Every other `[DIFFERS]` line is resolved here.

在新的 Godot 项目中，有一行是预期之内的：`commands.test` 命名了 `addons/gdUnit4/` 下的
gdUnit4 运行器，而 `/test-setup` 会在之后安装它。将那一行
报告为预期之内，指明 `/test-setup` 是清除它的步骤，并绝不
为了让这一行消失而编辑 `commands.test`。其他每一行 `[DIFFERS]` 都在此处解决。

**`[NOT CHECKED]` is not a pass.** Each such line names why a comparison could
not be made -- an absent binary, a missing `project.godot`. Say which ones
applied. A comparison that could not run has not established agreement.

The script emits observations and never a verdict, per the convention in
CLAUDE.md. The judgement is yours and the user's.

**`[NOT CHECKED]` 不是通过。** 每一行这样的内容都说明了为何无法
进行比较 —— 二进制不存在、缺少 `project.godot`。说明其中哪些
适用。无法运行的比较并未确立一致。

按照 CLAUDE.md 中的惯例，该脚本输出观察结果而从不输出裁决。
判断由你和用户做出。

---
