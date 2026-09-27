---
name: agnes-ai-support
version: "1.3.2"
description: |
  Agnes AI API 接入支持与问题排查 Skill。帮助新用户完成 Agnes AI API 的接入配置，
  诊断和解决接入过程中遇到的认证、参数、响应、图像生成、视频生成等各类问题。
  涵盖 Thinking 模式开启、视频长度调节、流式输出、工具调用等高级功能指导。
  兼容 OpenClaw、Claude Code、Hermes、Codex 等工具链。
>  触发词：Agnes AI、agnes、接入、API Key、401、400、排查、错误、视频生成、图像生成、
  thinking、stream、tool calling、模型选择、Base URL、响应格式、timeout、超时、轮询、
  FAQ、问题排查、调试、免费调用、RPM、video_id、task_id、Prompt 模板、提示词、
  生图、生视频、图生图、文生图、图生视频、文生视频、灰度自检、1M 上下文、4K 图片、4K 图、4K、灰度、自检、反馈、Bug、issue、问题反馈、功能建议。
---

# Agnes AI API 接入支持与问题排查

> **Skill 版本：** v1.3.2
> **适用工具：** OpenClaw / Claude Code / Claude Desktop / Hermes / Codex / WorkBuddy / Cherry Studio / Opencode / Kimi Work
> **更新日期：** 2026-09-23
> **官方 Bug 反馈：** https://github.com/AgnesAI-Labs/Agnes-AI/issues
> **官方进度看板：** https://github.com/users/AgnesAI-Labs/projects/1
> **官方 Bug 反馈：** https://github.com/AgnesAI-Labs/Agnes-AI/issues
> **官方进度看板：** https://github.com/users/AgnesAI-Labs/projects/1
> **GitHub 仓库：** https://github.com/lj1270998580-crypto/Agnes-help-skill
> **官方平台：** https://platform.agnes-ai.com
> **官方文档：** https://agnes-ai.com/doc/overview
> **操作手册：** https://agnes-ai.com/doc/%E5%B8%B8%E7%94%A8%E6%8E%A5%E5%85%A5%E6%96%87%E6%A1%A3
> **社区教程：** https://github.com/Yacey/agnes-ai-generation-skill
> **社区 Skill：** https://github.com/kangarooking/agnes-free-model-skills
> **ComfyUI 节点：** https://github.com/16nic/comfyui-agnes-ai
> **常见问题 QA（飞书）：** https://icn1d2hdv39m.feishu.cn/wiki/R7TEwjadJibD62kWeS9cubtpnPi

---

## 版本检查与更新提醒

**每次加载本 Skill 时，请执行以下检查：**

### 步骤 1：检测版本

1. 读取 GitHub 仓库最新 commit 信息：
   ```
   https://api.github.com/repos/lj1270998580-crypto/Agnes-help-skill/commits?per_page=1
   ```

2. 比较远程最新 commit 的 `sha` 与本地记录的版本（`v1.2.11` 对应 `sha: `）。

3. 如果 `sha` 不匹配 → 说明有新版本，继续步骤 2。

### 步骤 2：读取更新内容（重要）

如果检测到更新，**必须读取 README.md 的更新记录**来获取本次更新内容：

```
https://raw.githubusercontent.com/lj1270998580-crypto/Agnes-help-skill/main/README.md
```

从 README 中提取「更新记录」表格的第一行（最新的那条），获取：
- 更新日期
- 更新内容

### 步骤 3：向用户报告（在回复开头）

> 📢 **本 Skill 有新版本可用！**
> 
> **当前版本：** v1.2.11（您的版本）
> **最新版本：** [远程版本号]
> 
> **本次更新内容：**
> [从 README 更新记录读取的具体内容，例如：]
> - Agnes-2.0-Flash 上下文升级至 512K
> - 4K 图片已全面支持
> - 新增灰度自检功能
> - 新增官方 GitHub 反馈渠道
> 
> **是否需要更新？**
> 如果您想获取最新功能，请回复「更新 Skill」，我会帮您安装最新版。
> 
> **一键更新指令：**
> ```
> 请读取并安装 Agnes AI 支持 Skill 最新版：https://raw.githubusercontent.com/lj1270998580-crypto/Agnes-help-skill/main/SKILL.md
> ```
> 
> 如果您暂时不想更新，也可以继续使用当前版本。

### 步骤 4：用户选择更新

如果用户回复「更新 Skill」或「安装最新版」：
1. 读取最新版 SKILL.md 的 URL
2. 指导用户完成安装（或直接帮用户安装，取决于工具能力）
3. 安装完成后确认：「已更新至最新版本 vX.X.X」

如果用户不更新：
- 继续正常帮助用户，不强制更新
- 但建议用户在方便时更新以获得最新功能和修复

### 步骤 5：HTML 助手和 API 文档检查

如果用户正在使用 HTML 助手或 API 文档，同样提醒：
> 检测到 HTML 助手 / API 文档也有更新，建议从仓库下载最新版。

---

## Agnes AI 官方问题反馈渠道

> **注意：以下渠道是 Agnes AI 官方的反馈渠道，不是本 Skill 的反馈渠道。**
> 
> 当用户遇到 **Agnes AI API 官方服务**的问题（如 API 返回错误、功能异常、模型行为不符合预期等）时，主动提供以下官方渠道。

### 情况 1：用户遇到 Bug 或异常

如果用户报告了 API 异常、返回错误、功能不正常等：

> 🐛 **遇到 Bug 了？** 您可以通过以下官方渠道反馈：
> 
> **1. GitHub Issues（推荐）**
> - 地址：https://github.com/AgnesAI-Labs/Agnes-AI/issues
> - 用途：提交 Bug 反馈、API 使用咨询、需求与建议
> - 团队会按优先级标记处理
> 
> **2. 反馈处理进度看板**
> - 地址：https://github.com/users/AgnesAI-Labs/projects/1
> - 用途：查看问题修复进度、新模型上线、文档更新等
> - 建议收藏，可随时查看
> 
> **3. 支持邮箱**
> - 邮箱：support@agnes-ai.com
> - 适用于：需要详细描述的问题
> 
> **反馈前准备：**
> - 错误码（如 400、500）
> - 请求参数（脱敏 API Key）
> - 复现步骤
> - 期望行为 vs 实际行为

### 情况 2：用户有需求或建议

如果用户提出了功能需求、改进建议：

> 💡 **有建议？** 欢迎通过以下渠道提交：
> 
> **GitHub Issues：** https://github.com/AgnesAI-Labs/Agnes-AI/issues
> - 标题格式：`[Feature Request] 您的建议标题`
> - 内容描述：使用场景 + 期望功能 + 优先级
> - 团队会评估并纳入开发排期
> 
> 也可以在反馈进度看板查看需求处理状态：
> https://github.com/users/AgnesAI-Labs/projects/1

### 情况 3：用户想查询问题处理进度

> 📋 **查询反馈进度：**
> 
> https://github.com/users/AgnesAI-Labs/projects/1
> 
> 看板包含：
> - 所有已提交的 Issues 状态
> - 问题修复进度
> - 新模型上线计划
> - 文档更新进度
> - 开发排期
> 
> 建议收藏此链接，可随时查看官方最新动态。

---

## 如何使用本 Skill

> 本 Skill 是你的 Agnes AI 接入助手。安装后，Agent 会自动理解 Agnes API 的完整信息，帮你完成接入、生成内容、排查问题。

![Agnes Help Skill 教程信息图](https://raw.githubusercontent.com/lj1270998580-crypto/Agnes-help-skill/main/assets/agnes-help-skill-tutorial.png)

### 一、用 Skill 让 Agent 帮你生图 / 生视频

**步骤：**
1. **安装 Skill** → 把本 Skill 加载到 Agent（OpenClaw / Claude Code / Kimi Work 等）
2. **配置 API Key** → 告诉 Agent 你的 Agnes API Key
3. **告诉 Agent 需求** → "帮我生成一张赛博朋克城市夜景图" / "帮我生成一段 5 秒产品展示视频"
4. **Agent 自动执行** → Agent 会根据 Skill 中的参数说明自动选择模型、填写参数、调用 API

**示例对话：**
```
用户：帮我安装这个 skill，并帮我配置 Agnes API Key，然后帮我生成一张图片
Agent：（读取 Skill → 指导配置 → 调用 API → 返回图片）

用户：我已经装好 skill，帮我生成一个 5 秒视频
Agent：（读取 Skill → 选择视频模型 → 提交任务 → 轮询 → 返回视频）
```

> 💡 **你无需选择模型**，Agent 会根据你的需求自动判断并选择合适的模型执行。

> ⚠️ **视频查询一定要用 video_id，不要用 task_id**

---

### 二、用 Skill 让 Agent 接入你开发的工具

**场景：** 你有自己的工具、API 或服务，需要让 Agent 帮你接入和使用。

**步骤：**
1. **安装 Agnes Skill** → 让 Agent 以本 Skill 为参考来理解 Agnes 接口
2. **描述你的工具** → 告诉 Agent 你的工具是什么、需要什么能力
3. **Agent 生成接入方案** → Agent 会参考 Skill 中的接口信息，帮你生成接入代码、示例、调用方法
4. **联调修复** → 根据 Agent 提供的步骤调试，直至成功接入

**示例对话：**
```
用户：我想在我的 Next.js 项目中接入 Agnes AI 的图像生成功能
Agent：（参考 Skill → 生成 Next.js API Route 代码 → 提供前端调用示例）

用户：我的工具需要同时支持文本对话和图像生成
Agent：（参考 Skill → 生成多模态接入方案 → 提供统一封装代码）
```

> ⭐ **Skill 的价值：让 Agent 更懂你的工具，更快帮你完成接入。**

---

### 三、用 Skill 来排查问题，快速拿到方案

**步骤：**
1. **描述问题** → 把错误码、日志、截图发给 Agent，清晰描述你遇到了什么问题
2. **Agent 分析** → Agent 会参考 Skill 中的错误码表、常见问题、排查指南进行诊断
3. **给出方案** → Agent 输出：原因分析 + 修复步骤 + 示例代码

**高效提问模板：**
```
现在【正在做】：我在做什么
目标【期望结果/需求】：我需要什么
问题：遇到了什么问题
已尝试：【做过什么】
请给出：【原因 + 修复步骤 + 示例】
```

**常见错误码速查（Agent 会自动匹配）：**

| 错误码 | 含义 | 常见原因 |
|--------|------|----------|
| 401 | 认证错误 | API Key 错误、过期、格式不对 |
| 400 | 参数错误 | 必填参数缺失、类型错误、response_format 放错位置 |
| 429 | 频率限制 | 文本/图像 RPM 超过 20，或视频 RPM 超过 1（每分钟只能生成 1 个视频） | 降低请求频率，视频需排队等待 |
| 503 | 服务繁忙 | 服务端负载高，稍后重试 |

**示例对话：**
```
用户：我调用图像生成接口返回 400，提示参数错误
Agent：（参考 Skill 错误码表 → 分析可能原因 → 给出修复方案）

用户：视频任务提交了但一直查不到结果
Agent：（参考 Skill 视频排查指南 → 检查 video_id vs task_id → 给出正确查询方式）
```

---

> **🔔 Agnes AI 官方反馈渠道（如果以上排查均无效）：**
> 
> 当 Agnes AI 官方 API 服务出现问题（Bug、异常、功能不符合预期），请通过以下**官方渠道**反馈：
> - **GitHub Issues（推荐）：** https://github.com/AgnesAI-Labs/Agnes-AI/issues
> - **反馈进度看板：** https://github.com/users/AgnesAI-Labs/projects/1
> - **支持邮箱：** support@agnes-ai.com
> 
> **反馈前准备：** 错误码 + 请求参数（脱敏 Key）+ 复现步骤 + 期望行为 vs 实际行为

---

### 补充建议

- **新手可先安装 Skill 再使用** → 快速上手，降低使用门槛
- **API 文档可交给 Agent 参考** → 提升理解准确度与效率
- **有更新时查看 GitHub 仓库最新版** → 获取最新功能与修复

---

## 0. 重要公告（最新：2026-09-23）

> 最新公告见下方「Agnes 3.0 Flash 上线通知」。以下为 2026-06 的历史公告，仅作留存。

### Agnes 2.0 全模态模型 API 正式开放全球免费调用（历史公告）

> **Flash 系列模型（文本 / 图像 / 视频）当前全部免费；Pro 推理系列与 `agnes-video-2.5` 为付费模型**
> - 文本模型：免费/默认用户 RPM **10**（2026-09-23 起由 20 下调），企业 RPM **20**（由 40 下调），Token Plan RPM 1000（不变）
> - 图片模型：
>   - 1K 分辨率：免费/默认 RPM 20，企业 RPM 40，Token Plan RPM 100
>   - 2K 分辨率：免费/默认 RPM 10，企业 RPM 20，Token Plan RPM 80
>   - 3K/4K 分辨率：所有用户类型 RPM 均为 1
> - 视频模型：免费/默认用户 RPM 1，企业 RPM 2，Token Plan RPM 5
> - 注册官网 → 生成 KEY → 直接调用
- 文本、图像、视频全能适配，高效便捷
- 模型会持续升级并保持免费
- 欢迎大家多用、多吐槽

**平台直达：** https://platform.agnes-ai.com

### ⏱️ 文本模型 RPM 调整通知（2026-09-23）

> 为进一步优化高峰时段的整体稳定性，自本通知发布起，**免费额度下文本模型的 RPM 限制已下调**（官方说明：免费用户及企业用户的实际限额统一下调 50%）：

| 用户类型 | 调整前 | 调整后（2026-09-23 起） |
|----------|--------|------------------------|
| 免费 / 默认 | 20 RPM | **10 RPM** |
| 企业认证 | 40 RPM | **20 RPM** |
| Token Plan | 1000 RPM | 1000 RPM（不变） |

- 涉及模型：`agnes-2.5-flash`、`agnes-3.0-flash`
- 本次**仅调整文本模型**；图片、视频模型的 RPM 保持不变
- 短时间内超过限制会触发 429 限流，建议在客户端实现合理的重试与退避机制，避免请求过于集中
- 官方文档：https://www.agnes-ai.com/zh-Hans/docs/tokenplan

### 🚀 Agnes 3.0 Flash 上线通知（2026-09-09 更新）

- **Agnes 3.0 Flash 已上线，定位为「面向 Agent 编程与工具驱动任务」的新一代文本模型，当前免费**
- 模型 ID：`agnes-3.0-flash`
- **三个端点，同一把 Key**（这是 3.0 与 2.x 最大的差异）：
  - OpenAI 兼容：`POST /v1/chat/completions`（`Authorization: Bearer`）
  - OpenAI Responses：`POST /v1/responses`
  - Anthropic 兼容：`POST /v1/messages`（请求头用 `x-api-key` + `anthropic-version: 2023-06-01`，**不是** `Authorization`）
- **上下文 512K，最大输出 65,536 Token**；输入支持文本 + 图像 URL（多模态）
- **Thinking 模式**（2.x 不支持）：
  - OpenAI 风格：`"chat_template_kwargs": {"enable_thinking": true}`
  - Anthropic 风格：顶层 `"thinking": {"type": "enabled", "budget_tokens": N}`（`budget_tokens` 至少给最终输出留 1/3，否则可能撞 `max_tokens` 被截断）
- 官方强调的四个方向：任务端到端交付更可靠、工具编排更稳定（少瞎调 / 少死循环）、长任务指令遵循更强、输出更干净（不暴露内部推理）
- 价格：刊例价 输入缓存命中 `$0.005/M`、输入 `$0.05/M`、输出 `$0.15/M`；**现价三项均 `$0/M`（免费）**
- 官方文档（国际站）：https://www.agnes-ai.com/zh-Hans/docs/agnes-30-flash
- 官方文档（国内站）：https://www.agnes-ai.cn/zh-Hans/docs/agnes-30-flash
- 注意：国际站与国内站账号不互通、Key 不通用，混用会报「无效的令牌」

### 🖼️ Agnes Image 2.5 Flash 上线通知（2026-09-09 更新）

- 模型 ID：`agnes-image-2.5-flash`，端点 `POST /v1/images/generations`
- 官方定位：Agnes 最新一代图像模型，**整体能力全面超过 Agnes Image 2.1 Flash**（生成质量、编辑、构图、细节、提示词遵循）
- 请求/响应参数、支持尺寸（`1K`/`2K`/`3K`/`4K` + `ratio`）、价格与计费方法**与 2.1 Flash 完全一致**，可直接替换模型名升级
- 当前免费：所有输出分辨率档位与输入参考图片均 `$0`
- 官方文档（国际站）：https://www.agnes-ai.com/zh-Hans/docs/agnes-image-25-flash

### 🎬 Agnes Video 2.5 Flash 上线通知（2026-08-27 更新）

- **Agnes Video 2.5 Flash 已正式上线 API 平台，限时免费开放使用（$0/秒，原价 $0.025/秒）**
- 模型 ID：`agnes-video-2.5-flash`，端点 `POST /v1/videos`（与 v2.0 相同）
- 支持 **文生视频（text）/ 首尾帧控制（keyframe）/ 图片参考（reference）** 三种模式
- **Flash 专属限制**：`size` 固定为字符串 `"720P"`；`reference` 模式 `images` 最多 5 张；不支持 `videos` 输入；`seconds` 为字符串 `"4"`–`"12"`；`n` 固定为 `1`
- 查询仍推荐 `GET /agnesapi?video_id=<ID>&model_name=agnes-video-2.5-flash`；纯 `video_id` 查询仅适用于 `text` 模式
- 官方文档（国际站）：https://www.agnes-ai.com/zh-Hans/docs/agnes-video-25-flash
- 官方文档（国内站）：https://www.agnes-ai.cn/zh-Hans/docs/agnes-video-25-flash
- 使用中遇到问题或有建议，欢迎在社群内反馈

> ⚠️ **视频模型参数差异提醒（官方重点强调）**：`agnes-video-2.5`、`agnes-video-2.5-flash`、`agnes-video-v2.0` 三者的请求参数**存在差异，不要直接复用或混用参数**，否则可能出现 400 参数校验失败、任务创建失败等问题。请按实际调用的模型查阅对应官方文档：
> - Video 2.5（付费高清）：https://www.agnes-ai.com/zh-Hans/docs/agnes-video-25
> - Video 2.5 Flash（限时免费）：https://www.agnes-ai.com/zh-Hans/docs/agnes-video-25-flash
> - Video V2.0（旧版）：https://agnes-ai.com/doc/agnes-video-v20

### 💰 免费模型一览（2026-08-27 核对官方定价页）

> **目前所有 Flash 系列模型均免费开放**，仅 Pro 推理系列（`agnes-2.5-pro` / `-beta` / `-alpha`）与高清视频 `agnes-video-2.5` 为付费模型：

| 模型 | 类型 | 免费状态 |
|------|------|----------|
| `agnes-3.0-flash` | 文本（Agent） | ✅ 免费（输入缓存/输入/输出 均 $0，刊例价 $0.005/$0.05/$0.15） |
| `agnes-2.0-flash` | 文本 | ✅ 免费（输入/输出 Token 均 $0） |
| `agnes-2.5-flash` | 文本 | ✅ 免费（输入/输出 Token 均 $0） |
| `agnes-image-2.0-flash` | 图像 | ✅ 免费（1K/2K/3K/4K 全档位 $0，参考图 $0） |
| `agnes-image-2.1-flash` | 图像 | ✅ 免费（1K/2K/3K/4K 全档位 $0，参考图 $0） |
| `agnes-image-2.5-flash` | 图像 | ✅ 免费（1K/2K/3K/4K 全档位 $0，参考图 $0） |
| `agnes-video-v2.0` | 视频 | ✅ 免费（$0/秒） |
| `agnes-video-2.5-flash` | 视频 | ✅ 免费（$0/秒，限时免费；原价 $0.025/秒） |
| `agnes-video-2.5` | 视频 | 💰 付费（720P $0.025/秒、1080P 与 1K $0.040/秒、2K $0.055/秒） |
| `agnes-2.5-pro` / `-beta` / `-alpha` | 文本推理 | 💰 付费（$0.10~$0.45 输入，$0.30~$0.90 输出） |

> 官方定价来源：https://www.agnes-ai.com/zh-Hans/docs/pricing
> 注意：免费/付费状态可能随官方活动调整，以官方定价页与账户账单为准。

### 视频接口重要更新

- **必须使用 video_id 查询视频结果**，不要用 task_id 查询
- 使用 task_id 查询会导致视频排队过长（超过 5 分钟大概率是接口搞错了）
- 视频文档（2.5 Flash）：https://www.agnes-ai.com/zh-Hans/docs/agnes-video-25-flash
- 视频文档（v2.0）：https://agnes-ai.com/doc/agnes-video-v20
- 社区 Skill 中的视频接口可能未更新，请以官方文档为准

### ⚠️ Agnes-2.0-Flash 上下文窗口回退说明（2026-06-08 更新）

> **官方更新：** Agnes-2.0-Flash 上下文窗口已升级至 **512K**（此前 256K），Max Output 保持 **64K**。
>
> **当前规格：**
> - Context：512K
> - Max Output：64K
>
> 1.5 Flash 保持 512K/64K 不变。

### 🌐 国内网络域名切换通知（2026-07-28 更新）

> **针对部分国内网络无法正常访问 Agnes API 的情况，请将 API Endpoint 切换为：**
>
> - **原地址（国际）：** `https://apihub.agnes-ai.com/v1`
> - **新地址（国内）：** `https://apihub.agnes-ai.cn/v1`（将域名中的 `.com` 替换为 `.cn`）
>
> **调整说明：**
> - 请将应用配置、环境变量或项目代码中的 `apihub.agnes-ai.com` 统一替换为 `apihub.agnes-ai.cn`
> - 本次调整仅涉及接口域名，API Key、模型名称、请求参数及调用方式均无需修改
> - 修改完成后，请重启应用或服务，再重新发起请求

---

## 1. 快速接入流程（4 步）

### Step 1 — 创建 API Key
1. 访问 https://platform.agnes-ai.com 注册/登录
2. Settings → API Keys → Create new secret key
3. **只显示一次**，立即复制保存
4. 安全提醒：不要暴露在代码仓库、前端代码、截图、公开文档中

### Step 2 — 选择模型

| 场景 | 推荐模型 | 端点 |
|------|----------|------|
| **Agent 编程 / 工具调用 / 长任务（最新 · 免费）** | `agnes-3.0-flash`（免费） | `/v1/chat/completions`、`/v1/responses`、`/v1/messages` |
| 通用对话 / 高并发 / 低成本 | `agnes-2.5-flash`（免费） | `/v1/chat/completions` |
| 编程 / Agent / 推理 / 图片理解 | `agnes-2.5-flash`（免费） | `/v1/chat/completions` |
| 高级推理 / 复杂编码（付费，GA） | `agnes-2.5-pro` | `/v1/chat/completions` |
| 高级推理 / 复杂编码（付费，Beta） | `agnes-2.5-pro-beta` | `/v1/chat/completions` |
| 高级推理 / 复杂编码（付费，Alpha） | `agnes-2.5-pro-alpha` | `/v1/chat/completions` |
| 兼容旧版 / 通用对话 | `agnes-2.0-flash`（免费） | `/v1/chat/completions` |
| 图像生成 / 编辑（最新 · 推荐） | `agnes-image-2.5-flash`（免费） | `/v1/images/generations` |
| 图像生成 / 编辑 | `agnes-image-2.1-flash`（免费） | `/v1/images/generations` |
| 图像快速生成 | `agnes-image-2.0-flash`（免费） | `/v1/images/generations` |
| 视频生成（推荐 / 免费） | `agnes-video-2.5-flash` | `/v1/videos` |
| 视频生成（付费，高清） | `agnes-video-2.5` | `/v1/videos` |
| 视频生成（旧版 / 免费） | `agnes-video-v2.0` | `/v1/videos` |

### Step 3 — 配置请求

```
Base URL（国际）: https://apihub.agnes-ai.com/v1
Base URL（国内）: https://apihub.agnes-ai.cn/v1
Headers:
  Authorization: Bearer YOUR_API_KEY
  Content-Type: application/json
```

### Step 4 — 测试请求

```bash
curl https://apihub.agnes-ai.com/v1/chat/completions \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"agnes-2.0-flash","messages":[{"role":"user","content":"Hello!"}]}'
```

---

## 2. 问题诊断决策树

### 2.1 认证类问题

**401 Unauthorized**
1. 检查 Header 格式：`Authorization: Bearer YOUR_KEY`（Bearer 后有空格）
2. 确认 Key 未过期/被删除（控制台 Settings → API Keys 查看）
3. 确认账户有余额（注册送 $0.1；**目前所有 Flash 模型（文本/图像/视频）均免费**，但有 RPM 限制：文本 10/min（免费/默认额度，2026-09-23 起由 20 下调；企业 20、Token Plan 1000），图片按分辨率 1K:20, 2K:10, 3K/4K:1，视频 1/min；仅 Pro 推理系列与 `agnes-video-2.5` 为付费模型）
4. 检查 Key 是否有多余空格或换行符
5. 用 curl 直接测试，排除 SDK/框架问题

**API Key 泄露**
- 立即在控制台删除旧 Key，创建新 Key
- 检查代码仓库历史，用 git filter-repo / BFG 清理敏感信息
- 检查环境变量配置是否被意外提交

### 2.2 请求类问题（400 Bad Request）

**通用排查清单：**
1. JSON 格式是否合法（用 jsonlint 校验）
2. 必填参数是否缺失
3. 参数类型是否正确

**Chat 模型 400：**
- 必填：`model` + `messages`
- `messages` 必须是数组，元素含 `role` 和 `content`
- `temperature` 范围 0-2
- 图片 URL 输入时，`content` 必须是数组格式

**图像模型 400：**
- 文生图必填：`model` + `prompt` + `size`
- 图生图必填：`model` + `prompt` + `size` + `extra_body.image`（**image 必须放在 extra_body 中，不能放顶层！**）
- **response_format 必须放在 `extra_body` 中**，放根级会 400
- 图生图**不需要**传 `tags: ["img2img"]`
- `size` 格式：1K/2K/3K/4K 四种分辨率，必须是 16 的倍数（详见第 4 章参数速查）
- **图片模型生成尺寸必须为 16 的倍数**（如 1024x1024、1024x768）

**视频模型 400：**
- 必填：`model` + `prompt`
- `num_frames` 必须 ≤ 441 且满足 `8n + 1`
- 有效值：81, 121, 161, 241, 441
- `frame_rate` 范围 1-60
- **视频模型生成尺寸必须为 64 的倍数**（width/height 都需满足）
- **视频长度建议不要超过 15s**，否则有失败概率
- 官方建议：24FPS 不超过 15s，30FPS 不超过 10s，60FPS 不超过 5s
- 图生视频：`image` 需为公网可访问 URL

### 2.3 响应类问题

**无响应 / 超时**
- Chat：超时建议 30s
- 图像：超时建议 60-360s（数秒到几十秒）
- 视频：异步任务，创建后需轮询查询，间隔 5s
- 检查网络能否访问 `apihub.agnes-ai.com`（国际）或 `apihub.agnes-ai.cn`（国内）
- 如在国内网络无法访问 .com 域名，请切换至 .cn 域名
- 检查防火墙/代理是否拦截

**503 Service Unavailable**
- 服务暂时繁忙，指数退避重试：1s → 2s → 4s → 8s
- 关注 Agnes AI 状态公告
- **CC 平台特定**：检查模型名称是否正确、是否获取了模型列表、是否选择了兜底模型、是否开启了路由
- **Codex 特定**：如果显示用模型「gpt-5.4-mini」发送请求，将更多选项里的测试模型也填上 `agnes-2.0-flash`

**502 Bad Gateway**
- 本地网络环境问题，检查本地网络环境，修改 DNS，必要时让 AI 帮忙检查修改

**520 Web Server Error**
- 通常表示网络链路异常或上游服务临时波动，稍后重试

**429 Rate Limited**
- 降低请求频率
- 文本模型：免费/默认 RPM **10**（2026-09-23 起由 20 下调），企业 RPM **20**（由 40 下调），Token Plan RPM 1000（不变）
- 图片模型：按分辨率分档 — 1K RPM 20，2K RPM 10，3K/4K RPM 1（均免费/默认）
- 视频模型：免费/默认 RPM 1（每分钟内只能生成 1 个视频），需排队等待
- 实现客户端队列和退避

**Token Plan 订阅配额（与 RPM 同时生效，超出同样触发 429）：**
- 文本（`agnes-2.5-flash`）：Starter 每 5 小时 1,500 次 / 每周 15,000 次；Plus 每 5 小时 7,500 次 / 每周 75,000 次；Pro 每 5 小时 30,000 次 / 每周 300,000 次（按请求次数计数）
- 图片（`agnes-image-2.1-flash`）：三档均为每天 4,000 张（按生成张数计数）
- 视频（`agnes-video-v2.0` / `agnes-video-2.5-flash`）：三档均为每天 500 秒（按生成时长计数）
- 同一类型的多个 Key 共享同一个限制池，不会叠加额度
- 官方参考：https://www.agnes-ai.com/zh-Hans/docs/tokenplan

### 2.4 视频排队过长（> 5 分钟）

**这是最重要的排查点：**
- **大概率是使用了 task_id 查询接口**
- **必须使用 video_id 查询**：`GET /agnesapi?video_id=<ID>`
- task_id 查询接口会导致排队异常延长
- 正确做法：创建任务后获取 `video_id`，用 video_id 轮询查询
- 轮询间隔建议 5 秒

### 2.5 输出质量问题

- 优化 Prompt 结构：`[Role] + [Task] + [Context] + [Requirements] + [Output Format]`
- 编程/推理任务开启 Thinking 模式
- 调整 `temperature`：确定性任务 0.1-0.3，创意任务 0.7-1.0
- 检查 `max_tokens` 是否足够，避免截断
- 图像任务：提供详细的场景、风格、光照、构图描述

---

## 3. 高级功能指南

### 3.1 Thinking 模式（agnes-2.0-flash / agnes-3.0-flash）

> `agnes-3.0-flash` 同样支持 Thinking；Anthropic 兼容端点（`/v1/messages`）另可用顶层 `thinking` 块：`"thinking": {"type": "enabled", "budget_tokens": 2048}`，注意 `budget_tokens` 至少给最终输出留 1/3。

**OpenAI 兼容格式：**
```json
{
  "model": "agnes-2.0-flash",
  "messages": [...],
  "chat_template_kwargs": {
    "enable_thinking": true
  }
}
```

**Anthropic 兼容格式：**
```json
{
  "model": "agnes-2.0-flash",
  "messages": [...],
  "thinking": {
    "type": "enabled",
    "budget_tokens": 2048
  }
}
```

**budget_tokens 建议：**
- 简单编码：2048
- 复杂调试/重构：4096+
- 多步骤 Agent：4096+

### 3.2 流式输出（SSE）

请求体加 `"stream": true`
- 响应逐块返回，每块以 `data:` 开头
- 最后以 `data: [DONE]` 结束
- 需正确解析 `choices[0].delta.content` 并拼接

### 3.3 工具调用

1. 请求中提供 `tools` 数组（含 function 定义）
2. 模型返回 `finish_reason: "tool_calls"`
3. 解析 `choices[0].message.tool_calls`
4. 执行函数后，以 `role: tool` 回传结果
5. 模型根据工具结果生成最终回复

### 3.4 视频长度调节

**公式：** `seconds = num_frames / frame_rate`

**约束：**
- `num_frames ≤ 441`
- `num_frames = 8n + 1`（81, 121, 161, 241, 441）
- `frame_rate`：1-60，推荐 24
- **视频长度建议不要超过 15s**，否则有失败概率
- 官方建议：24FPS 不超过 15s，30FPS 不超过 10s，60FPS 不超过 5s

**常用配置：**
| 时长 | num_frames | frame_rate |
|------|-----------|------------|
| ~3s | 81 | 24 |
| ~5s | 121 | 24 |
| ~10s | 241 | 24 |
| ~15s | 361 | 24 |
| ~18s | 441 | 24 |

**更长视频：** 增加 num_frames 或降低 frame_rate，但建议不超过 15s

### 3.5 图像输出格式

**URL 输出：**
```json
{
  "extra_body": {
    "response_format": "url"
  }
}
```

**Base64 输出（文生图）：**
```json
{
  "return_base64": true
}
```

**Base64 输出（图生图）：**
```json
{
  "extra_body": {
    "response_format": "b64_json"
  }
}
```

---

## 4. 各模型参数速查

### agnes-3.0-flash（新增 · 免费 · Agent 向，2026-09 上线）

- 端点（三选一，共用同一 Base URL 与同一把 Key）：
  - `POST /v1/chat/completions`（OpenAI 兼容，请求头 `Authorization: Bearer`）
  - `POST /v1/responses`（OpenAI Responses）
  - `POST /v1/messages`（Anthropic 兼容，请求头用 `x-api-key` + `anthropic-version: 2023-06-01`）
- Context：512K；Max Output：65,536 Token
- 输入模态：文本 + 图像 URL；输出：文本
- **Thinking 模式**（2.x 系列不支持）：
  - OpenAI 风格：`"chat_template_kwargs": {"enable_thinking": true}`
  - Anthropic 风格：顶层 `"thinking": {"type": "enabled", "budget_tokens": N}`，`budget_tokens` 至少给最终输出留 1/3，否则易撞 `max_tokens` 被截断
- 参数：model, messages, temperature, top_p, max_tokens, stream, tools, tool_choice, chat_template_kwargs, thinking
- 官方强调：任务端到端交付更可靠、工具编排更稳定、长任务指令遵循更强、输出更干净；`usage` 中可见 `reasoning_tokens`
- 价格：输入缓存命中 `$0.005/M`、输入 `$0.05/M`、输出 `$0.15/M`；**现价三项均 $0/M（免费）**
- **适合**：Agent / 工具调用 / 多步任务编排；普通对话继续用 `agnes-2.5-flash` 即可

### agnes-2.5-flash
- 端点：`POST /v1/chat/completions`（另支持 Responses `POST /v1/responses`、Anthropic 兼容 Messages `POST /v1/messages`）
- Context：512K
- Max Output：65.5K
- 参数：model, messages, temperature, top_p, max_tokens, frequency_penalty, presence_penalty, repetition_penalty, stop, seed, stream, tools, tool_choice, chat_template_kwargs, thinking
- 支持图片 URL 输入（messages[].content 数组格式）
- 支持工具调用、Thinking 模式、流式输出
- **升级自 2.0 Flash**：API 完全兼容，只需改模型名即可迁移
- 价格：Input $0.03/1M, Output $0.15/1M（**现价 $0，RPM ≤ 10（免费/默认额度）**）

### agnes-2.5-pro（正式版 · 付费）
- 端点：`POST /v1/chat/completions`（另支持 Responses `POST /v1/responses`、Messages `POST /v1/messages`）
- Context：**1M**
- Max Output：65536
- 输入模态：文本、图像 URL；输出：文本（Reasoning）
- **Agnes 2.5 Pro Alpha 打榜模型的商业化稳定版**（2026-08-01 发布），付费模型，需账户开通访问权限
- 权重：Proprietary（非开源）；Alpha 权重已 Apache 2.0 开源
- 支持工具调用、Thinking 模式、流式输出
- 价格：Input $0.45/1M, Output $0.90/1M, Cache hit $0.045/1M

### agnes-2.5-pro-beta（Beta · 付费）
- 端点：`POST /v1/chat/completions`（另支持 Responses `POST /v1/responses`、Messages `POST /v1/messages`）
- Context：**1M**
- Max Output：65536
- 输入模态：文本、图像 URL；输出：文本（Reasoning）
- **已正式上线**，付费模型，需账户开通访问权限
- 权重：Proprietary（非开源）
- 支持工具调用、Thinking 模式、流式输出
- 价格：Input $0.10/1M, Output $0.30/1M, Cache hit $0.01/1M

### agnes-2.5-pro-alpha
- 端点：`POST /v1/chat/completions`（另支持 Responses `POST /v1/responses`、Messages `POST /v1/messages`）
- Context：**1M**（此前误标 262K）
- Max Output：65536
- 输入模态：文本、图像 URL；输出：文本（Reasoning）
- **✅ 已转为付费模型，付费通道已开通**（2026-07-24 发布，权重已 Apache 2.0 开源）
- 支持图片 URL 输入、工具调用、Thinking 模式、流式输出
- 价格：Input $0.45/1M, Output $0.90/1M, Cache hit $0.045/1M

### agnes-2.0-flash
- 端点：`POST /v1/chat/completions`
- Context：512K
- Max Output：64K
- 额外参数：stream, tools, tool_choice, chat_template_kwargs, thinking
- 支持图片 URL 输入（messages[].content 数组格式）
- 支持工具调用、Thinking 模式、流式输出
- 价格：Input $0.03/1M, Output $0.15/1M（**现价 $0，RPM ≤ 10（免费/默认额度）**）
- **已升级至 2.5-flash，建议迁移**

### agnes-image-2.0/2.1/2.5-flash

> `agnes-image-2.5-flash`（2026-09 上线，免费）为最新一代，整体能力全面超过 2.1 Flash；**请求/响应参数、支持尺寸、价格与计费方法与 2.1 完全一致，直接换模型名即可升级**。以下说明三者通用。
- 端点：`POST /v1/images/generations`
- 必填：model, prompt, size
- 图生图必填：`extra_body.image`（URL 数组或 Data URI Base64，**必须放在 extra_body 中！**）
- size：官方推荐档位 `1K` / `2K` / `3K` / `4K`（配合 `ratio` 使用），也兼容 `1024x768` 这类历史精确尺寸写法，但不支持的尺寸可能被标准化
- `ratio` 支持：1:1、3:4、4:3、16:9、9:16、2:3、3:2、21:9（默认 1:1）
  - 1K：免费/默认 RPM 20，企业 RPM 40，Token Plan RPM 100
  - 2K：免费/默认 RPM 10，企业 RPM 20，Token Plan RPM 80
  - 3K/4K：所有用户类型 RPM 均为 1
- **尺寸要求：** 历史精确尺寸需为 16 的倍数，否则可能返回 500 错误；推荐使用档位 + ratio
- 输出：URL 或 Base64（`return_base64: true` 或 `extra_body.response_format`）
- 价格（按张）：1K $0.010/张、2K $0.018/张、3K $0.021/张、4K $0.024/张（**现价均 $0**）；前 3 张输入参考图免费，第 4 张起 $0.003/张（**现价 $0**）

### agnes-video-v2.0
- 创建：`POST /v1/videos`
- **查询（强烈推荐）：`GET /agnesapi?video_id=<ID>`**
- 查询（兼容，不推荐）：`GET /v1/videos/{task_id}`
- 参数：model, prompt, image, mode, height(768), width(1152), num_frames, frame_rate(24), num_inference_steps, seed, negative_prompt, extra_body.image, extra_body.mode
- 支持分辨率档位：480p、720p、1080p
- 支持宽高比：16:9、9:16、1:1、4:3、3:4
- 支持关键帧动画模式：`extra_body.mode: "keyframes"`
- 价格：$0.005/second（**现价 $0**）
- **重要：必须用 video_id 查询，task_id 会导致排队过长**

### agnes-video-2.5（付费 · 高清）
- 模型 ID：`agnes-video-2.5`
- 创建：`POST /v1/videos`
- **查询（强烈推荐）：`GET /agnesapi?video_id=<ID>&model_name=agnes-video-2.5`**
- 查询（兼容，仅 text 模式）：`GET /agnesapi?video_id=<ID>`
- 模式：`text`（文生视频）、`keyframe`（首尾帧控制）、`reference`（图片/音频/**视频**参考）
- `size`：`"720P"` / `"1080P"` / `"1K"` / `"2K"`（`1K` 固定 `1024x1024`；`2K` 宽高为 720P 的 2 倍）；`aspect_ratio` 支持 21:9 / 16:9 / 4:3 / 1:1 / 3:4 / 9:16
  - 720P：21:9 `1470x630`、16:9 `1280x720`、4:3 `1112x834`、1:1 `960x960`、3:4 `834x1112`、9:16 `720x1280`
  - 1080P：21:9 `2206x946`、16:9 `1920x1080`、4:3 `1664x1248`、1:1 `1440x1440`、3:4 `1248x1664`、9:16 `1080x1920`
  - 2K：21:9 `2940x1260`、16:9 `2560x1440`、4:3 `2224x1668`、1:1 `1920x1920`、3:4 `1668x2224`、9:16 `1440x2560`
  - ⚠️ 旧文档的 `960P` 档位已取消，传入会返回 400
- `seconds`：字符串 `"4"`–`"12"`（默认 `"5"`）；`n` 固定 `1`
- `reference` 模式：`images`/`audios`/`videos` 至少一类非空
  - 参考图片：最多 **8 张**，单张 < 15 MB，宽高各 `256`–`5760` 像素；前 5 张免费，第 6 张起 $0.005/张
  - 参考视频：最多 **1 个**，时长 `2`–`12` 秒，< 50 MB，帧率 `24`–`60` FPS；对象字段 `{url, start_seconds?, require_audio?}`（`require_audio: true` 时片源必须带音轨）
  - 参考音频：最多 **3 段**，总时长 `2`–`12` 秒，单个 < 15 MB
  - 单次请求参考媒体文件总数 ≤ 12 个，总大小 < 50 MB
- 支持**音画协同**：可结合音频或带音轨的视频参考增强画面节奏与声音一致性
- 价格：720P $0.025/秒、**1080P 与 1K $0.040/秒**、2K $0.055/秒（**付费模型**）
- 计费：`总金额 = 输出秒数 × 输出分辨率单价 + 输入视频秒数 × 输出分辨率单价 + max(0, 图片数 - 5) × $0.005`（**输入视频时长也会计入总时长，按输出分辨率单价计费**）
- **重要：必须用 video_id 查询，task_id 会导致排队过长**

### agnes-video-2.5-flash（新增 · 限时免费）
- 模型 ID：`agnes-video-2.5-flash`
- 创建：`POST /v1/videos`
- **查询（强烈推荐）：`GET /agnesapi?video_id=<ID>&model_name=agnes-video-2.5-flash`**
- 查询（兼容，仅 text 模式）：`GET /agnesapi?video_id=<ID>`
- 模式：`text`（文生视频）、`keyframe`（首尾帧控制）、`reference`（图片/音频参考）
- `size` 固定字符串 `"720P"`（传其他值返回 400 `size must be 720P`）；`aspect_ratio` 支持 21:9 / 16:9 / 4:3 / 1:1 / 3:4 / 9:16
  - 720P 输出像素：21:9 `1680x720`、16:9 `1280x704`、4:3 `960x720`、1:1 `720x720`、3:4 `720x960`、9:16 `720x1280`（以实际生成文件为准）
- `seconds`：字符串 `"4"`–`"12"`（默认 `"5"`）；`n` 固定 `1`
- `reference` 模式：`images` 最多 **5 张**、`audios` 最多 **3 段**（可单独或同时使用）；不支持 `videos` 输入（传有效内容返回 400 `videos is not supported`）
- Flash 专属校验顺序：`size` → `images` → `audios` → `videos`，返回首个检测到的错误；校验失败不创建任务、不计费
- 价格：原价 $0.025/second，**现价 $0/second（限时免费）**；限时免费期间输出视频秒数、输入视频秒数与参考图片均按 `$0` 计费（计费公式与 Video 2.5 相同）
- **重要：必须用 video_id 查询，task_id 会导致排队过长**

## 5. 常见错误速查表

| 状态码 | 含义 | 常见原因 | 解决方案 |
|--------|------|----------|----------|
| 400 | 请求无效 | 参数错误、JSON 格式、必填缺失、尺寸不是16/64倍数 | 检查格式、参数类型、必填字段、尺寸限制 |
| 401 | 未授权 | API Key 错误/过期 | 检查 Authorization 头，确认 Key 有效 |
| 404 | 不存在 | 视频/任务 ID 错误 | 确认 ID 正确 |
| 429 | 速率限制 | 文本 RPM 超过 10（免费/默认额度，2026-09-23 起由 20 下调），图片按分辨率（1K:20, 2K:10, 3K/4K:1），视频 RPM 超过 1 | 降低频率，视频需排队等待，实现退避重试 |
| 500 | 服务器错误 | 服务端异常、参数异常（尺寸限制） | 检查参数是否符合尺寸限制，稍后重试 |
| 502 | 网关错误 | 本地网络环境问题 | 检查网络、修改 DNS、必要时让 AI 帮忙检查 |
| 503 | 服务繁忙 | 负载高或维护、CC 平台配置问题 | 指数退避重试，检查模型名称/路由/兜底模型 |
| 520 | 网络异常 | 网络链路异常或上游服务临时波动 | 稍后重试，检查网络环境 |

> **🔔 如果以上错误排查均无效？**
> 
> 请通过 **Agnes AI 官方反馈渠道**提交问题：
> - **GitHub Issues（推荐）：** https://github.com/AgnesAI-Labs/Agnes-AI/issues
> - **反馈进度看板：** https://github.com/users/AgnesAI-Labs/projects/1
> - **支持邮箱：** support@agnes-ai.com
> 
> **反馈前准备：** 错误码 + 请求参数（脱敏 Key）+ 复现步骤 + 期望行为 vs 实际行为

---

## 6. 接入检查清单

### 通用
- [ ] 已注册账户并创建 API Key（https://platform.agnes-ai.com）
- [ ] Base URL 正确（国际：`https://apihub.agnes-ai.com/v1`，国内：`https://apihub.agnes-ai.cn/v1`）
- [ ] 请求头包含 Authorization 和 Content-Type
- [ ] API Key 未暴露在公开代码中
- [ ] 已实现错误处理和重试逻辑
- [ ] 了解 RPM 限制（文本 10/min（免费/默认额度，2026-09-23 起由 20 下调；企业 20、Token Plan 1000），图片按分辨率 1K:20, 2K:10, 3K/4K:1，视频 1/min）

### Chat
- [ ] 模型名称拼写正确
- [ ] messages 数组格式正确
- [ ] 图片 URL 使用数组 content 格式
- [ ] 流式输出能正确解析 SSE
- [ ] 工具调用能处理 finish_reason: tool_calls

### 图像
- [ ] 模型名称正确（推荐 2.1）
- [ ] 文生图传 model + prompt + size
- [ ] 图生图传了 `extra_body.image` 数组（**不能放顶层！**）
- [ ] response_format 在 extra_body 中
- [ ] 未传 tags: ["img2img"]
- [ ] 输入图片 URL 公网可访问
- [ ] 客户端超时 ≥ 60s

### 视频
- [ ] 模型名称：agnes-video-v2.0
- [ ] num_frames ≤ 441 且满足 8n+1
- [ ] frame_rate 在 1-60
- [ ] 图生视频图片 URL 公网可访问
- [ ] **已实现轮询查询（间隔 5s）**
- [ ] **使用 video_id 查询结果（不要用 task_id）**
- [ ] 视频排队超过 5 分钟时检查查询接口是否正确

---

## 7. 最佳实践

### Prompt 编写
- 使用结构化格式：`[Role] + [Task] + [Context] + [Requirements] + [Output Format]`
- 编程任务：提供语言、框架、错误信息、期望行为
- Agent 任务：清晰描述目标、可用工具、任务约束
- 图像任务：主体 + 场景 + 风格 + 光照 + 构图 + 质量要求
- 视频任务：主体 + 动作 + 场景 + 镜头运动 + 光照 + 风格

### 性能优化
- 高并发场景使用 agnes-2.5-flash
- 需要推理/编程使用 agnes-2.0-flash + Thinking
- 图像生成设置合理超时（60-360s）
- 视频生成使用异步 + 轮询模式
- 实现指数退避重试（1s → 2s → 4s → 8s）
- **视频查询必须用 video_id，避免 task_id 导致的排队**

> Agnes AI，让世界级 AI 属于每一个人。

### 安全
- API Key 存储在环境变量或密钥管理服务中
- 前端代码中绝不硬编码 Key
- 定期轮换 API Key
- 监控异常用量

> Agnes AI，让世界级 AI 属于每一个人。

### 灰度自检（检查你的账户是否支持 1M 上下文和 4K 图片）

> Agnes AI 正在灰度测试以下能力：
> - **1M Token 超长上下文**：约 50% 概率已开放
> - **4K 图片生成**：已全面支持（所有用户可用）
>
> 触发条件：当用户问"灰度自检"、"是否有1M上下文"、"能生成4K图吗"、"4K图片"等时，执行以下测试。
>
> **⚠️ 重要：这些测试是"尽力而为"的方法，结果仅供参考。灰度分配是动态的，可能随时变化。**

---

**测试 1：1M 上下文自检**

> **原理**：需要发送超过 512K tokens 的文本。如果 API 成功返回 → 支持 1M；如果返回 413/400（上下文过长）→ 当前不支持。
>
> **注意**：英文文本约 1 token ≈ 4 字符，因此要超过 512K tokens，需要发送 **约 2M+ 字符** 的 payload。这是一个较大的请求体，可能受客户端/服务端请求大小限制。

**curl 方法**（示例文本较短，实际测试需要更大payload，推荐用 Python 方法）：
```bash
# 此示例payload较小，仅展示调用方式
# 实际测试需要约 1M+ 字符的文本才能超过 256K tokens

curl https://apihub.agnes-ai.com/v1/chat/completions \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "agnes-2.0-flash",
    "messages": [
      {"role": "system", "content": "You are a helpful assistant."},
      {"role": "user", "content": "（此处需要放入约 1M+ 字符的文本）"}
    ],
    "max_tokens": 10
  }'
```

**Python 方法（推荐）**：
```python
import requests

key = "YOUR_API_KEY"

# 生成约 2.5M 字符（约 625K tokens，超过 512K 边界）
# 注意：实际 token 数取决于 tokenizer，但 2.5M 字符应足够超过 512K tokens
sentence = "Hello world this is a test for long context window capability. "
test_text = sentence * 40000  # 约 2.5M 字符

print(f"测试文本长度: {len(test_text)} 字符")

try:
    resp = requests.post(
        "https://apihub.agnes-ai.com/v1/chat/completions",
        headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"},
        json={
            "model": "agnes-2.0-flash",
            "messages": [
                {"role": "system", "content": "You are a helpful assistant."},
                {"role": "user", "content": test_text}
            ],
            "max_tokens": 10
        },
        timeout=60
    )

    if resp.status_code == 200:
        print("✅ 支持 1M 上下文（当前在灰度名单内）")
    elif resp.status_code == 413 or resp.status_code == 400:
        error_msg = resp.json().get("error", {}).get("message", resp.text[:200])
        if "context" in error_msg.lower() or "length" in error_msg.lower() or "too long" in error_msg.lower():
            print(f"❌ 当前不支持 1M 上下文（灰度未命中）：{error_msg}")
        else:
            print(f"⚠️ 请求失败（非上下文问题）：{resp.status_code} {error_msg}")
    else:
        print(f"⚠️ 请求失败：{resp.status_code} {resp.text[:200]}")
except Exception as e:
    print(f"⚠️ 请求异常（可能是payload过大导致客户端限制）：{e}")
```

---

**测试 2：4K 图片自检**

> 4K 图片已全面支持，所有用户均可使用 4096x4096 等 4K 尺寸。

```bash
# 尝试生成 4K 尺寸图片
curl https://apihub.agnes-ai.com/v1/images/generations \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "agnes-image-2.1-flash",
    "prompt": "A beautiful landscape with mountains and lake, 4K ultra HD",
    "size": "4096x4096",
    "extra_body": {"response_format": "url"}
  }'
```

Python 方法：
```python
import requests

key = "YOUR_API_KEY"

resp = requests.post(
    "https://apihub.agnes-ai.com/v1/images/generations",
    headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"},
    json={
        "model": "agnes-image-2.1-flash",
        "prompt": "A beautiful landscape with mountains and lake, 4K ultra HD",
        "size": "4096x4096",
        "extra_body": {"response_format": "url"}
    }
)

if resp.status_code == 200:
    data = resp.json()
    if "data" in data and len(data["data"]) > 0 and data["data"][0].get("url"):
        print("✅ 支持 4K 图片生成（当前在灰度名单内）")
    else:
        print("⚠️ 请求成功但无图片返回，请检查参数")
elif resp.status_code == 400:
    error_msg = resp.json().get("error", {}).get("message", resp.text[:200])
    if "size" in error_msg.lower() or "dimension" in error_msg.lower() or "4096" in error_msg.lower():
        print(f"❌ 当前不支持 4K 图片（灰度未命中）：{error_msg}")
    else:
        print(f"⚠️ 请求失败（非尺寸问题）：400 {error_msg}")
else:
    print(f"⚠️ 请求失败：{resp.status_code} {resp.text[:200]}")
```

---

**测试结果解读：**

| 测试 | 成功 | 失败 | 不确定 |
|------|------|------|--------|
| 1M 上下文 | ✅ 你的账户已开放 1M 上下文 | ❌ 当前仍为 512K | ⚠️ 请求异常（payload过大或网络问题） |
| 4K 图片 | ✅ 已全面支持 4K 图片 | — | — |

> **注意：** 灰度是动态分配的，不支持时无需担心，未来会逐步全量开放。以上测试仅供参考，实际以官方公告为准。

> Agnes AI，让世界级 AI 属于每一个人。

---

## 8. Prompt 模板库

> 复制以下模板，替换方括号中的内容即可直接使用。

### 8.1 文生图 Prompt 模板

**通用结构公式：**
```
[主体] + [场景/背景] + [风格] + [光照] + [构图] + [质量要求]
```

**模板 1 — 电商产品图**
```
A clean product photo of a [产品] on a [背景颜色] studio background, soft shadows, high detail, professional commercial photography, 8K quality
```
*示例：A clean product photo of a wireless earbuds case on a pure white studio background, soft shadows, high detail, professional commercial photography, 8K quality*

**模板 2 — 社交媒体海报**
```
A vibrant social media poster featuring [主题], bold typography space at [位置], [风格] color palette, eye-catching composition, modern design, 4K
```
*示例：A vibrant social media poster featuring summer sale, bold typography space at top, tropical color palette, eye-catching composition, modern design, 4K*

**模板 3 — 人物肖像**
```
Portrait of a [年龄/性别] [职业/角色], [表情], wearing [服装], [场景背景], [风格] lighting, cinematic composition, highly detailed, professional photography
```
*示例：Portrait of a young female scientist, confident smile, wearing a white lab coat, modern laboratory background, soft natural lighting, cinematic composition, highly detailed, professional photography*

**模板 4 — 风景/场景**
```
A breathtaking [场景类型] at [时间], [天气/氛围], [风格] style, dramatic lighting, ultra-wide angle, 8K resolution, photorealistic
```
*示例：A breathtaking mountain lake at golden hour, misty atmosphere, fantasy art style, dramatic lighting, ultra-wide angle, 8K resolution, photorealistic*

**模板 5 — 图标/插画**
```
A minimalist [风格] icon of [对象], flat design, [主色调] color scheme, clean lines, white background, vector style, UI/UX design
```
*示例：A minimalist line art icon of a rocket launching, flat design, blue and orange color scheme, clean lines, white background, vector style, UI/UX design*

---

### 8.2 图生图编辑指令模板

**通用结构公式：**
```
[编辑动作] + [保留元素] + [目标风格/场景] + [光照] + [构图]
```

**模板 1 — 风格转换**
```
Transform this image into [目标风格] style while preserving the main subject and composition
```
*示例：Transform this image into a cinematic cyberpunk style while preserving the main subject and composition*

**模板 2 — 颜色替换**
```
Change the [对象] color to [颜色] while keeping the original lighting and shadows
```
*示例：Change the car color to matte black while keeping the original lighting and shadows*

**模板 3 — 背景替换**
```
Replace the background with [新背景], keep the foreground subject unchanged, match the lighting
```
*示例：Replace the background with a sunset beach scene, keep the foreground subject unchanged, match the lighting*

**模板 4 — 添加元素**
```
Add [元素] to the scene, maintain the original style and perspective, natural integration
```
*示例：Add floating lanterns to the scene, maintain the original style and perspective, natural integration*

**模板 5 — 季节/时间转换**
```
Change the scene to [季节/时间], adjust lighting and atmosphere accordingly, preserve architecture
```
*示例：Change the scene to winter night with snowfall, adjust lighting and atmosphere accordingly, preserve architecture*

---

### 8.3 视频生成 Prompt 模板

**文生视频通用结构：**
```
[主体] + [动作] + [场景] + [镜头运动] + [光照] + [风格] + [时长暗示]
```

**模板 1 — 产品展示视频**
```
A [产品] rotating slowly on a [背景] platform, smooth 360-degree product showcase, soft studio lighting, clean and minimal, professional commercial video
```
*示例：A luxury watch rotating slowly on a marble platform, smooth 360-degree product showcase, soft studio lighting, clean and minimal, professional commercial video*

**模板 2 — 人物动作视频**
```
A [人物描述] [动作], natural movement, [场景], [镜头运动], cinematic lighting, realistic style
```
*示例：A young woman walking through a cherry blossom garden, natural movement, petals falling around her, slow tracking shot, golden hour lighting, realistic style*

**模板 3 — 场景转换视频**
```
A smooth cinematic transition from [场景A] to [场景B], maintaining visual consistency, dramatic lighting change, wide angle
```
*示例：A smooth cinematic transition from a rainy city street to a sunny countryside road, maintaining visual consistency, dramatic lighting change, wide angle*

**图生视频通用结构：**
```
Animate [元素] with [动作], keep [需保持的元素] consistent, [风格]
```
*示例：Animate the character with subtle breathing motion, hair moving gently, while keeping the face and outfit consistent, realistic style*

**关键帧动画结构：**
```
Generate a smooth cinematic transition between keyframes, maintaining [元素] consistent, [风格]
```
*示例：Generate a smooth cinematic transition between keyframes, maintaining character appearance consistent, fantasy art style*

---

### 8.4 文本模型 Prompt 模板

**模板 1 — 代码生成**
```
Role: Senior [语言] Developer
Task: Write a [功能描述]
Context: [框架/库], [已有代码/约束]
Requirements: [具体要求，如错误处理、类型安全、性能]
Output: Complete code with comments
```

**模板 2 — 代码调试**
```
Role: Debugging Expert
Task: Fix the bug in the following code
Context: [语言/框架], [错误信息], [期望行为]
Code: [粘贴代码]
Requirements: Explain the root cause, provide the fix, suggest prevention measures
```

**模板 3 — 内容创作**
```
Role: Professional [领域] Writer
Task: Write a [内容类型] about [主题]
Target Audience: [受众描述]
Tone: [语气，如专业/轻松/权威]
Requirements: [字数、结构、SEO关键词等]
```

**模板 4 — 数据分析**
```
Role: Data Analyst
Task: Analyze the following data and provide insights
Data: [粘贴数据或描述]
Requirements: [分析维度], identify trends, suggest actionable recommendations
Output: Structured report with key findings
```

**模板 5 — Agent 任务**
```
Role: [Agent 角色]
Goal: [明确目标]
Tools Available: [可用工具列表]
Constraints: [限制条件，如时间、预算、格式]
Step-by-step plan required: Yes
```

---

## 9. 社区资源

- **官方平台**：https://platform.agnes-ai.com
- **官方文档**：https://agnes-ai.com/doc/overview
- **操作手册**：https://agnes-ai.com/doc/%E5%B8%B8%E7%94%A8%E6%8E%A5%E5%85%A5%E6%96%87%E6%A1%A3
- **视频文档**：https://agnes-ai.com/doc/agnes-video-v20
- **常见问题 QA**：https://icn1d2hdv39m.feishu.cn/wiki/R7TEwjadJibD62kWeS9cubtpnPi
- **社区教程**：https://github.com/Yacey/agnes-ai-generation-skill
- **社区 Skill**：https://github.com/kangarooking/agnes-free-model-skills
- **ComfyUI 节点**：https://github.com/16nic/comfyui-agnes-ai
- **支持邮箱**：support@agnes-ai.com
- **公司**：Sapiens AI / Agnes AI

---

## 10. 社区 Skill 接入指南

以下社区资源提供了更丰富的 Agnes AI 集成方式，可根据你的使用场景选择。

### 9.1 Yacey 的 Agnes AI 生成 Skill（推荐 Agent 用户）

**仓库：** https://github.com/Yacey/agnes-ai-generation-skill

**特点：**
- 封装 Agnes 官方文本、图片、视频 API 的标准 Skill
- 支持中文提示词自动翻译为英文（提升视频生成稳定性）
- 提供 Python 脚本直接调用
- 兼容 Codex、Claude Code、OpenClaw、Cursor、Windsurf

**安装方式：**
```bash
# 安装到当前 Agent
npx skills add Yacey/agnes-ai-generation-skill

# 安装到所有支持的 Agent
npx skills add Yacey/agnes-ai-generation-skill --all
```

**配置 API Key：**
```bash
# 临时配置（当前 PowerShell 会话）
$env:AGNES_API_KEY="YOUR_API_KEY"

# Windows 用户级持久配置
[Environment]::SetEnvironmentVariable("AGNES_API_KEY", "YOUR_API_KEY", "User")
```

**脚本也识别以下变量名：**
- `AGNES_API_KEY`
- `AGNES_API_TOKEN`
- `APIHUB_AGNES_API_KEY`

**使用示例：**
```bash
# 文本生成
python scripts/agnes_api.py text --prompt "Write a product tagline for an AI assistant."

# 文生图
python scripts/agnes_api.py image --prompt "A luminous floating city above a misty canyon at sunrise, cinematic realism" --size 1024x768

# 图生图
python scripts/agnes_api.py image --prompt "Turn the scene into a rainy cyberpunk night" --image https://example.com/input.png

# 文生视频（默认 num_frames=121, frame_rate=24）
python scripts/agnes_api.py video --prompt "A cinematic shot of a cat walking on the beach at sunset" --poll

# 图生视频
python scripts/agnes_api.py video --prompt "Animate subtle camera movement" --image https://example.com/image.png --poll

# 多图 / 关键帧视频
python scripts/agnes_api.py video --prompt "Create a smooth transition" --image https://example.com/a.png --image https://example.com/b.png --mode keyframes --poll

# 查询视频任务
python scripts/agnes_api.py video-get task_123456

# 运行测试
python scripts/agnes_api.py smoke-test
```

**⚠️ 重要提醒：**
- 该 Skill 的视频查询默认使用 `task_id`，但 Agnes 官方已更新为推荐使用 `video_id` 查询
- 如视频排队超过 5 分钟，请检查是否使用了正确的查询方式
- 中文提示词会自动翻译为英文后再调用 API

---

### 9.2 kangarooking 的免费模型 Skills（推荐 Codex 用户）

**仓库：** https://github.com/kangarooking/agnes-free-model-skills

**特点：**
- 3 个独立 Skill：文本、图片、视频
- 可直接放入 Codex skills 目录使用
- 提供 Python 辅助脚本

**包含 Skill：**

| Skill | 能力 | 触发场景 |
|-------|------|----------|
| `agnes-free-text` | Agnes-2.0-Flash 文本模型，支持 Chat、流式、工具调用 | 用户说"用免费的文本模型""Agnes 文本" |
| `agnes-free-image` | Agnes Image 2.1 Flash 图片模型，支持文生图、图生图 | 用户说"用免费的图片模型""Agnes 图片" |
| `agnes-free-video` | Agnes-Video-V2.0 视频模型，异步任务+轮询+下载 | 用户说"用免费视频模型""Agnes 视频" |

**安装方式：**
```bash
# 克隆仓库
git clone https://github.com/kangarooking/agnes-free-model-skills.git

# 复制需要的 skill 到 Codex skills 目录
cp -R agnes-free-model-skills/agnes-free-text ~/.codex/skills/
cp -R agnes-free-model-skills/agnes-free-image ~/.codex/skills/
cp -R agnes-free-model-skills/agnes-free-video ~/.codex/skills/
```

**配置环境变量：**
```bash
export AGNES_API_KEY="your_api_key_here"
```

**备用变量名：**
- `AGNES_TOKEN`
- `AGNES_API_BASE`（可覆盖默认地址）

**使用示例：**
```bash
# 文本
python3 agnes-free-text/scripts/agnes_text.py chat --message "解释 Agent skill 是什么"

# 图片
python3 agnes-free-image/scripts/agnes_image.py generate --prompt "科技感插画，干净明亮"

# 视频
python3 agnes-free-video/scripts/agnes_video.py create --prompt "竖屏短视频，医疗科普画面"

# 视频轮询并下载
python3 agnes-free-video/scripts/agnes_video.py status --task-id task_123456 --wait --download-dir downloads
```

---

### 9.3 16nic 的 ComfyUI 节点（推荐 ComfyUI 用户）

**仓库：** https://github.com/16nic/comfyui-agnes-ai

**特点：**
- ComfyUI 自定义节点插件
- 7 个功能节点，覆盖 Agnes 全模态能力
- 支持 API Key 持久化、画质选择、宽高比选择
- 视频输出支持 ComfyUI 原生 VIDEO 类型

**功能节点：**

| 节点 | 功能 | 模型 |
|------|------|------|
| Agnes API Key Config | 持久化保存 API Key | — |
| Agnes LLM Chat | 文本对话 | agnes-2.0-flash |
| Agnes Image Reverse Prompt | 图像反推提示词 | agnes-2.0-flash (vision) |
| Agnes Image-to-Image | 图生图/编辑（支持多图） | agnes-image-2.1-flash |
| Agnes Text-to-Image | 文生图 | agnes-image-2.1-flash |
| Agnes Image-to-Video | 图生视频（支持多图/关键帧） | agnes-video-v2.0 |
| Agnes Text-to-Video | 文生视频 | agnes-video-v2.0 |

**安装方式：**
```bash
cd ComfyUI/custom_nodes
git clone https://github.com/16nic/comfyui-agnes-ai.git
cd comfyui-agnes-ai
pip install -r requirements.txt
```

**配置 API Key（推荐方式）：**
1. 在节点菜单 → **Agnes AI** → 添加 **Agnes API Key Config**
2. 在 `api_key` 输入框填入你的 API Key
3. 运行一次（Ctrl+Enter / Queue Prompt）
4. Key 自动保存到 `api_key_config.json`
5. 之后其他 Agnes 节点的 `api_key` 字段留空即可自动加载

**API Key 加载优先级：**
```
环境变量 AGNES_API_KEY > api_key_config.json > 运行时回退加载 > 节点输入框手动填写
```

**画质 × 宽高比对照表（图片）：**

| 比例 | 1K | 2K | 4K |
|------|-----|-----|-----|
| 1:1 | 1024×1024 | 2048×2048 | 4096×4096 |
| 16:9 | 1816×1024 | 3640×2048 | 7280×4096 |
| 9:16 | 1024×1816 | 2048×3640 | 4096×7280 |

**注意事项：**
- 视频生成是异步任务，通常需要 2-6 分钟
- 免费 API 高峰期可能有排队（503）或 GPU OOM（500）
- 建议首次使用先测试文生图，确认 API Key 正常工作

---

## 11. Codex 集成指南

> **区分两个工具：**
> - **Codex++**（Agnes 官方文档推荐）：第三方 GUI 工具，通过管理界面配置供应商
> - **OpenAI Codex CLI**（命令行工具）：OpenAI 官方终端 AI 编程智能体，通过 `~/.codex/config.toml` 配置

---

### 10.1 Codex++ 配置（Agnes 官方推荐）

Codex++ 是一款支持多供应商的 GUI 管理工具，Agnes 官方文档提供完整接入指南。

**Step 1 — 下载 Codex++**

- 仓库：https://github.com/BigPizzaV3/CodexPlusPlus
- 最新版：https://github.com/BigPizzaV3/CodexPlusPlus/releases/latest
- 根据系统选择安装包：
  - Windows：`windows-x64-setup.exe`
  - Intel Mac：`macos-x64.dmg`
  - Apple Silicon Mac：`macos-arm64.dmg`

**Step 2 — 安装**

正常安装即可。Mac 用户若提示"已损坏，无法打开"，在终端执行：
```bash
sudo xattr -rd com.apple.quarantine "/Applications/Codex++.app"
sudo xattr -rd com.apple.quarantine "/Applications/Codex++ 管理工具.app"
```

**Step 3 — 打开管理工具，添加 Agnes 供应商**

打开"Codex++ 管理工具" → 左侧菜单"供应商配置" → "添加供应商"，填写：

| 配置项 | 填写内容 |
|--------|----------|
| 名称 | Agnes |
| 接入模式 | 纯 API |
| 测试模型 | agnes-2.0-flash |
| Base URL | `https://apihub.agnes-ai.com/v1` |
| Key | 你的 Agnes API Key（sk- 开头） |
| 上游协议 | Chat Completions |

**⚠️ 关键注意事项：**
- Key 只填写 `sk-` 开头的密钥，**不要**填写 `Bearer`
- Base URL 只填写到 `/v1`，**不要**填写 `/chat/completions`
- 上游协议必须选择 **Chat Completions**

**Step 4 — 启用并启动**

1. 保存配置后，回到供应商列表，选择 **Agnes**，点击"使用/切换到此供应商"
2. 左侧菜单"概览" → "启动 Codex++"（或右上角"重启 Codex"）
3. 启动完成后，新建会话测试：输入"你好，请介绍一下你自己"，正常回复即配置成功

---

### 10.2 OpenAI Codex CLI 配置（命令行用户）

如果你使用的是 OpenAI 官方的 `codex` 命令行工具，可通过以下方式接入 Agnes：

**Step 1 — 创建配置目录**
```bash
mkdir -p ~/.codex
```

**Step 2 — 编辑 `~/.codex/config.toml`**

```toml
#:schema https://developers.openai.com/codex/config-schema.json

# 使用 Agnes AI 作为后端
model = "agnes-2.0-flash"
model_provider = "openai"
openai_base_url = "https://apihub.agnes-ai.com/v1"

# 推荐日常配置
sandbox_mode = "workspace-write"
approval_policy = "on-request"
```

**Step 3 — 配置 API Key**

方式 A：环境变量（推荐）
```bash
# macOS / Linux
export OPENAI_API_KEY="YOUR_AGNES_API_KEY"

# Windows PowerShell
$env:OPENAI_API_KEY="YOUR_AGNES_API_KEY"
```

方式 B：认证文件
编辑 `~/.codex/auth.json`：
```json
{
  "OPENAI_API_KEY": "YOUR_AGNES_API_KEY"
}
```

**Step 4 — 验证配置**
```bash
codex doctor
```

`codex doctor` 会自动检测运行时、认证、网络连通性和 config.toml 格式，所有项目绿色即配置成功。

**多 Provider 配置（灵活切换）：**

```toml
# 默认使用 Agnes
model = "agnes-2.0-flash"
model_provider = "openai"
openai_base_url = "https://apihub.agnes-ai.com/v1"

# 同时保留官方 OpenAI 配置
[model_providers.openai]
name = "OpenAI Official"
base_url = "https://api.openai.com/v1"
env_key = "OPENAI_API_KEY"

# 或其他 Provider
[model_providers.deepseek]
name = "DeepSeek"
base_url = "https://api.deepseek.com/v1"
env_key = "DEEPSEEK_API_KEY"
```

切换 Provider 时只需修改：
```toml
model_provider = "openai"  # 使用 Agnes
# 或
model_provider = "deepseek"  # 使用 DeepSeek
```

---

### 10.3 使用 Agnes 的各模型

| 模型 | 配置值 |
|------|--------|
| 通用对话 | `agnes-2.5-flash` |
| 编程/Agent | `agnes-2.0-flash` |

**注意：** Codex/Codex++ 主要使用 Chat Completions API，图像和视频生成需要通过 Agnes 的独立端点调用。如需在 Codex 中使用图像/视频生成，建议：
1. 安装 kangarooking 的 `agnes-free-image` / `agnes-free-video` Skill
2. 或直接使用 curl / Python 脚本调用

---

### 10.4 常见问题

**Q: Codex++ 配置后无法连接？**
- 确认 Key 只填写 `sk-` 部分，不含 `Bearer`
- 确认 Base URL 只到 `/v1`，不含 `/chat/completions`
- 确认上游协议选择 **Chat Completions**
- 确认网络可正常访问 `https://apihub.agnes-ai.com`

**Q: OpenAI Codex CLI 提示 "自定义配置不生效"？**
- 确认 `config.toml` 路径正确（`~/.codex/config.toml`）
- 确认 `model_provider` 名称匹配
- 确认 `base_url` 完整（包含 `/v1`）
- 确认环境变量名与 `env_key` 一致

**Q: 如何同时使用 Agnes 和官方 OpenAI？**
- Codex++：在供应商列表中切换
- Codex CLI：使用多 Provider 配置（见 10.2）

**Q: Codex 的 Agent 模式能调用 Agnes 的工具调用吗？**
- 可以。Agnes 2.0 Flash 支持 OpenAI 兼容的工具调用格式
- 在 Codex 中正常使用 `tools` 即可
- 模型返回 `finish_reason: "tool_calls"` 时，Codex 会自动处理

---

> Agnes AI，让世界级 AI 属于每一个人。

---

## 12. OpenClaw 接入指南

> 官方文档：https://agnes-ai.com/doc/cid1

### 11.1 概述

OpenClaw 是一款支持自定义模型服务商的 Agent 工具。配置完成后，OpenClaw 可以通过 Agnes AI API 网关调用模型，用于本地 Agent 任务。

### 11.2 配置步骤

**Step 1 — 打开终端**

- macOS / Linux：使用终端
- Windows：使用命令提示符、PowerShell 或开发环境中的终端

**Step 2 — 进入 OpenClaw 配置界面**

```bash
openclaw config
```

**Step 3 — 选择本地配置**

在配置菜单中选择：`Local`，按 Enter。

**Step 4 — 进入模型配置**

选择：`Model`，按 Enter。

**Step 5 — 选择定制服务商**

选择：`Custom Provider`，按 Enter。

**Step 6 — 配置 API Base URL**

输入：
```
https://apihub.agnes-ai.com/v1
```

**Step 7 — 填写 API Key**

输入你的 Agnes API Key（`sk-` 开头）。

**⚠️ 注意：** 通常不需要手动添加 `Bearer`，除非 OpenClaw 明确要求输入完整的授权标头。

**Step 8 — 填写模型名称**

输入：
```
agnes-2.0-flash
```

**Step 9 — 保存配置**

完成所有必填项后，确认并保存。

### 11.3 完整配置示例

```
Provider Type: Custom Provider
API Base URL: https://apihub.agnes-ai.com/v1
API Key: YOUR_API_KEY
Model: agnes-2.0-flash
```

### 11.4 验证配置

配置完成后，运行一个 OpenClaw 任务或启动测试会话。如果能正常返回模型响应，说明配置成功。

### 11.5 常见问题

**Q: API 请求失败？**
- 检查 API Base URL 是否正确：`https://apihub.agnes-ai.com/v1`
- 确认 API Key 是否有效

**Q: 提示"缺乏模型"？**
- 确认模型名称填写正确，区分大小写
- 建议直接复制平台提供的模型名称

**Q: 鉴权失败？**
- 检查 API Key 是否过期
- 确认账户余额充足
- 确认该 Key 具备访问目标模型的权限

**Q: 网络错误？**
- 确认设备可正常访问 API
- 检查防火墙、代理或 VPN 设置

**Q: API Base URL 到底要不要填 `/chat/completions`？**
- **不要**。只填写到 `/v1`
- 正确：`https://apihub.agnes-ai.com/v1`
- 错误：`https://apihub.agnes-ai.com/v1/chat/completions`
- 除非 OpenClaw 明确要求输入完整接口地址

---

## 13. HermesAgents 接入指南

> 官方文档：https://agnes-ai.com/doc/cid2

### 12.1 概述

HermesAgents 是一款支持自定义模型服务商的 Agent 工具。配置完成后，HermesAgents 将模型请求发送到 Agnes AI API 网关，并使用 Agnes 模型完成 Agent 任务。

### 12.2 配置步骤

HermesAgents 使用命令行配置，格式为：
```bash
hermes config set <配置项> <值>
```

**Step 1 — 配置模型服务商**

```bash
hermes config set model.provider custom
```

**Step 2 — 配置 API Base URL**

```bash
hermes config set model.base_url https://apihub.agnes-ai.com/v1
```

**Step 3 — 配置 API Key**

```bash
hermes config set model.api_key YOUR_API_KEY
```

**⚠️ 注意：** 通常不需要手动添加 `Bearer`，除非 HermesAgents 明确要求输入完整的授权标头。

也可以通过环境变量配置：
```bash
hermes config set OPENAI_API_KEY YOUR_API_KEY
```

但在自定义模型服务商配置中，推荐优先使用 `model.api_key`。

**Step 4 — 配置模型名称**

```bash
hermes config set model.default agnes-2.0-flash
```

### 12.3 完整配置示例

```bash
hermes config set model.provider custom
hermes config set model.base_url https://apihub.agnes-ai.com/v1
hermes config set model.api_key sk-xxxxxxxxxxxxxxxx
hermes config set model.default agnes-2.0-flash
```

### 12.4 验证配置

配置完成后，运行一个 HermesAgents 任务或启动测试会话。如果能正常返回模型响应，说明配置成功。

### 12.5 常见问题

**Q: 鉴权失败？**
- 重新执行 `hermes config set model.api_key YOUR_API_KEY`
- 确认账户余额或积分充足

**Q: API 请求失败？**
- 确认 API Base URL 正确：`https://apihub.agnes-ai.com/v1`
- 确认网络、防火墙、代理或 VPN 设置正常

**Q: 模型名称不生效？**
- 确认模型 ID 区分大小写
- 建议直接复制平台提供的模型名称

**Q: API Base URL 要不要填 `/chat/completions`？**
- **不要**。只填写到 `/v1`
- 正确：`https://apihub.agnes-ai.com/v1`
- 错误：`https://apihub.agnes-ai.com/v1/chat/completions`

---

## 14. Claude CLI 接入指南（通过 CC-Switch）

> 官方文档：https://agnes-ai.com/doc/cid3

### 13.1 概述

Claude CLI 是 Anthropic 官方的终端 AI 编程工具。由于 Claude CLI 原生不支持自定义 OpenAI-Compatible API，需要通过 **CC-Switch** 作为代理路由，将请求转发到 Agnes AI API 网关。

**所需工具：**
- Claude CLI（已安装）
- CC-Switch v3.16.1+（下载：https://github.com/farion1231/cc-switch/releases）
- Agnes AI API Key

### 13.2 配置步骤

**Step 1 — 获取 Agnes API Key**

访问 https://platform.agnes-ai.com/，登录后进入 API Key 页面，创建并复制 API Key。

**Step 2 — 打开 CC-Switch**

启动 CC-Switch，在顶部工具栏选择：`Claude CLI`

**Step 3 — 添加新供应商**

点击右上角加号，添加新供应商：
- 供应商类型选择：`Claude Provider` → `Custom Provider`

**Step 4 — 填写配置信息**

| 配置项 | 填写内容 |
|--------|----------|
| API Key | 你的 Agnes API Key（`sk-` 开头） |
| 请求地址 | `https://apihub.agnes-ai.com/v1` |
| API 格式 | `OpenAI Chat Completions` |
| 认证字段 | 默认即可，或手动配置 `ANTHROPIC_AUTH_TOKEN` |

**⚠️ 注意：** 通常不需要手动添加 `Bearer` 前缀。

**Step 5 — 模型映射**

点击"获取模型列表"，确认可正常连接 Agnes API。

然后将 Claude CLI 的模型映射到 Agnes 模型：

| Claude 模型 | 映射到 Agnes 模型 |
|-------------|------------------|
| Sonnet | `agnes-2.0-flash` |
| Opus | `agnes-2.0-flash` |
| Haiku | `agnes-2.0-flash` |

**Step 6 — 添加自定义参数（重要）**

为避免模型请求中出现不兼容参数，建议在自定义参数中加入：

```json
{
  "allowed_openai_params": [
    "thinking",
    "context_management"
  ],
  "litellm_settings": {
    "drop_params": true
  }
}
```

**作用：**
- 允许指定的 OpenAI 参数通过
- 自动丢弃模型不兼容的未知参数
- 提高 Claude CLI 通过代理调用 OpenAI-Compatible API 时的兼容性

**Step 7 — 保存并启用**

- 保存供应商配置
- 进入 CC-Switch 设置 → `Route` → 打开 `Local Route`
- 在本地路由中启用 Claude 路由切换
- 返回供应商列表，启用 Agnes Provider

### 13.3 验证配置

打开 Claude CLI，执行一次测试对话或代码任务。如果能正常返回 Agnes 模型响应，说明配置成功。

### 13.4 常见问题

**Q: 无法获取模型列表？**
- 检查 API Base URL：`https://apihub.agnes-ai.com/v1`
- 确认 API Key 有效
- 确认网络可正常访问 Agnes API
- **CC 平台**：检查 CC-Switch 版本是否最新，旧版本可能无法获取模型列表

**Q: Claude CLI 返回错误或不兼容参数？**
- 确认已添加自定义参数（`allowed_openai_params` + `litellm_settings.drop_params`）
- 确认 API 格式选择为 `OpenAI Chat Completions`

**Q: 配置保存后 Claude CLI 仍走官方 Anthropic？**
- 确认 CC-Switch 的 Local Route 已开启
- 确认 Claude 路由切换已启用
- 确认 Agnes Provider 已启用

---

## 15. Claude Desktop 接入指南（通过 CC-Switch）

> 官方文档：https://agnes-ai.com/doc/cid4

### 14.1 概述

Claude Desktop 是 Anthropic 官方的桌面端 AI 应用。与 Claude CLI 类似，需要通过 **CC-Switch** 作为代理路由，将请求转发到 Agnes AI API 网关。

**所需工具：**
- Claude Desktop（下载：https://claude.com/download）
- CC-Switch v3.16.1+（下载：https://github.com/farion1231/cc-switch/releases）
- Agnes AI API Key

### 14.2 配置步骤

**Step 1 — 安装 Claude Desktop**

根据系统选择安装包：
- Windows：`.exe`
- macOS：`.dmg`
- Linux：`AppImage`

**Step 2 — 打开 CC-Switch**

启动 CC-Switch，在顶部切换到：`Claude Desktop` 或 `ClaudeCode Desktop`

**Step 3 — 添加新供应商**

点击"添加新供应商"：
- 选择：`Custom Provider`

**Step 4 — 填写配置信息**

| 配置项 | 填写内容 |
|--------|----------|
| API Key | 你的 Agnes API Key（`sk-` 开头） |
| 请求地址 | `https://apihub.agnes-ai.com/v1` |
| API 格式 | `OpenAI Chat Completions` |

**Step 5 — 开启模型映射并获取模型列表**

- 开启"模型映射"功能
- 点击"获取模型列表"，确认可正常连接 Agnes API

**Step 6 — 配置模型映射**

| Claude 模型 | 映射到 Agnes 模型 |
|-------------|------------------|
| Sonnet | `agnes-2.0-flash` |
| Opus | `agnes-2.0-flash` |
| Haiku | `agnes-2.0-flash` |

**Step 7 — 保存并启用路由**

- 保存配置
- 进入 CC-Switch 设置 → `Route` → 打开本地路由开关
- 启用 Claude 路由
- 返回供应商列表，启用 Agnes Provider

### 14.3 验证配置

打开 Claude Desktop，发起一次测试对话。如果能正常通过 Agnes 模型返回响应，说明配置成功。

### 14.4 常见问题

**Q: Claude Desktop 无法调用模型？**
- 确认 CC-Switch 本地路由已开启
- 确认 Claude 路由已启用

**Q: 无法获取模型列表？**
- 检查 API Base URL：`https://apihub.agnes-ai.com/v1`
- 确认 API Key 有效
- **CC 平台**：检查 CC-Switch 版本是否最新，旧版本可能无法获取模型列表
- 确认已开启模型映射功能
- 确认 Claude 模型已映射到 Agnes 模型

**Q: API 请求失败或鉴权失败？**
- 检查网络、防火墙、代理或 VPN 设置
- 确认 API Key 正确，账户余额充足

---

## 16. WorkBuddy 接入指南

> 官方文档：https://agnes-ai.com/doc/cid5

### 15.1 概述

WorkBuddy 是一款支持自定义模型的 AI 工作助手。配置完成后，WorkBuddy 可以直接调用 Agnes 文本模型进行对话、代码和 Agent 任务，也可以通过 Skill 方式使用 Agnes 图像和视频模型。

**本教程基于 WorkBuddy v4.24.5 版本。**

### 15.2 文本模型配置步骤

**Step 1 — 获取 Agnes API Key**

访问 https://platform.agnes-ai.com/，登录后进入 API Key 页面，创建并复制 API Key。

**Step 2 — 进入自定义模型配置**

打开 WorkBuddy，点击：`Auto` → `配置自定义模型`

**Step 3 — 选择自定义提供商**

在提供商列表中向下滑动到最后，选择：`其他` 或 `Custom`

**Step 4 — 添加 Agnes 文本模型**

点击"添加模型"，填写：

| 配置项 | 填写内容 |
|--------|----------|
| Provider | Custom |
| API Base URL | `https://apihub.agnes-ai.com/v1` |
| API Key | 你的 Agnes API Key |
| Model Name | `agnes-2.0-flash` |

**Step 5 — 保存并选择模型**

保存后，在 WorkBuddy 对话界面中选择：`agnes-2.0-flash`

**Step 6 — 验证**

发起一次普通对话，例如："你好，请介绍一下你自己。"正常返回即配置成功。

### 15.3 图像和视频模型配置（通过 Skill）

Agnes 的图像和视频模型可以通过创建 Skill 的方式在 WorkBuddy 中使用。

**创建 Skill 的提示词：**
```
我想要使用 Agnes Image 2.0 模型生图生视频，访问它的 API 平台 https://agnes-ai.com/doc/overview，并将它打包成一份 Skill。
```

WorkBuddy 会根据 Agnes API 文档自动生成图像和视频相关 Skill。

**使用图像 Skill：**
- 点击技能列表，选择图像生成 Skill（如 `agnes-image-gen`）
- 输入提示词，例如："生成一张赛博朋克城市夜景，霓虹灯光，电影感，高细节。"

**使用视频 Skill：**
- 选择视频生成 Skill（如 `agnes-video-gen`）
- 输入提示词，例如："生成一段亚洲女生模特在白色摄影棚中展示黑色连衣裙的视频，从全景缓慢切到半身特写，保持自然转身，5 秒。"

### 15.4 常见问题

**Q: 文本模型无法返回？**
- 检查 API Base URL：`https://apihub.agnes-ai.com/v1`
- 确认 API Key 有效

**Q: 模型列表中看不到 `agnes-2.0-flash`？**
- 确认模型名称填写正确，区分大小写
- 建议直接复制平台提供的模型名称

**Q: 图像或视频 Skill 创建失败？**
- 确认 WorkBuddy 可以正常访问 Agnes 文档地址
- 确认当前模型具备读取文档和创建 Skill 的能力

**Q: 视频任务长时间没有完成？**
- 视频生成通常需要一定时间，请耐心等待
- 确认使用 `video_id` 查询结果（不要用 `task_id`）

**Q: 鉴权失败？**
- 检查 API Key 是否正确
- 确认账户余额或 credits 充足

---

## 17. Cherry Studio 接入指南

> 官方文档：https://agnes-ai.com/doc/cid6

### 16.1 概述

Cherry Studio 是一款支持多模型服务商的 AI 客户端。配置完成后，Cherry Studio 可以调用 Agnes 文本模型进行对话，也可以通过技能或智能体绑定的方式使用 Agnes 图像和视频模型。

### 16.2 文本模型配置步骤

**Step 1 — 获取 Agnes API Key**

访问 https://platform.agnes-ai.com/，登录后进入 API Key 页面，创建并复制 API Key。

**Step 2 — 添加提供商**

进入 Cherry Studio 的 API 服务商或模型设置页面，点击：`添加提供商`

**Step 3 — 选择提供商类型**

提供商类型选择：`OpenAI`（或支持 OpenAI-Compatible API 的自定义类型）

**Step 4 — 填写配置信息**

| 配置项 | 填写内容 |
|--------|----------|
| 提供商名称 | `Agnes` 或 `Agnes AI` |
| API Key | 你的 Agnes API Key（`sk-` 开头） |
| API 地址 | `https://apihub.agnes-ai.com/v1` |

**⚠️ 注意：** 通常不需要手动添加 `Bearer`。

**Step 5 — 获取模型列表**

点击"获取模型列表"，确认可正常连接 Agnes API。选择文本模型：`agnes-2.0-flash`

**Step 6 — 保存并验证**

保存后，在 Cherry Studio 中新建对话框，选择 `agnes-2.0-flash`，发送测试消息。正常返回即配置成功。

### 16.3 图像和视频模型使用方式

Cherry Studio 中，图像和视频模型建议通过**创建技能并绑定智能体**的方式使用。

- 创建图像 Skill（如 `Agnes Image Skill`），绑定到智能体
- 创建视频 Skill（如 `Agnes Video Skill`），绑定到智能体
- 通过对话方式生成图片或视频

### 16.4 常见问题

**Q: 无法获取模型列表？**
- 检查 API 地址：`https://apihub.agnes-ai.com/v1`
- 确认 API Key 有效
- **CC 平台**：检查 CC-Switch 版本是否最新，旧版本可能无法获取模型列表

**Q: 鉴权失败？**
- 确认 API Key 填写正确
- 确认账户余额充足

**Q: 无法从外部链接下载或安装 Skills？**
- 通常表示智能体无法联网请求 skills，检查网络连接
- 尝试手动下载 Skill 文件并本地安装
- 确认 Agent 工具支持外部网络请求

**Q: 文本模型可用，但图片或视频不能用？**
- Cherry Studio 的普通 OpenAI 兼容文本模型配置通常只适合文本对话
- 图像和视频模型建议通过技能或智能体工具绑定方式使用

**Q: API 地址要不要填 `/chat/completions`？**
- **不要**。只填写到 `/v1`
- 正确：`https://apihub.agnes-ai.com/v1`
- 错误：`https://apihub.agnes-ai.com/v1/chat/completions`

---

## 18. Opencode 接入指南

> 官方文档：https://agnes-ai.com/doc/cid7
> 
> 本指南基于 OpenCode 1.15.13 版本整理。

### 18.1 概述

Opencode 是一款支持 OpenAI-Compatible API 的 AI 编程工具。配置完成后，你可以在 OpenCode 中直接使用 Agnes 模型进行代码生成、项目分析、代码修改和多轮对话。

**前置条件：**
- 已注册 Agnes AI 账号
- 已进入 Agnes API Platform 并创建 API Key
- 当前网络环境可以访问 Agnes API Gateway

### 18.2 OpenCode CLI 配置

**适用场景：** 通过终端使用 OpenCode CLI 的用户。

**Step 1 — 打开配置文件**

如果你已有 OpenCode 配置文件，在原有配置中新增 `agnes` provider，并将默认模型设置为：
```json
"model": "agnes/agnes-2.0-flash"
```

**Step 2 — 添加 Agnes Provider 配置**

```json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "agnes/agnes-2.0-flash",
  "provider": {
    "agnes": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Agnes",
      "options": {
        "baseURL": "https://apihub.agnes-ai.com/v1",
        "apiKey": "{env:AGNES_API_KEY}"
      },
      "models": {
        "agnes-2.0-flash": {
          "name": "agnes-2.0-flash"
        }
      }
    }
  }
}
```

> ⚠️ **注意：** 如果你已有其他 provider，不要直接覆盖整个配置文件。只需要在 `provider` 下新增 `agnes`，并将 `model` 改为 `agnes/agnes-2.0-flash`。

**Step 3 — 配置环境变量**

在终端中配置 Agnes API Key：
```bash
export AGNES_API_KEY="你的 Agnes API Key"
```

如果希望长期生效，写入 shell 配置文件：
```bash
# Bash 用户
echo 'export AGNES_API_KEY="你的 Agnes API Key"' >> ~/.bashrc
source ~/.bashrc

# zsh 用户（macOS 默认）
echo 'export AGNES_API_KEY="你的 Agnes API Key"' >> ~/.zshrc
source ~/.zshrc
```

**Step 4 — 验证配置**

启动 OpenCode 后，输入：
```bash
/models
```

如果配置成功，可以看到：
```
Agnes
agnes-2.0-flash
```

选择 `Agnes / agnes-2.0-flash` 后，即可开始使用 Agnes 模型。

### 18.3 OpenCode Desktop 配置

**适用场景：** 使用 OpenCode Desktop 图形界面的用户。

**Step 1 — 打开设置**

启动 OpenCode Desktop，点击左下角的**设置按钮**。

**Step 2 — 选择自定义提供商**

在提供商列表中找到**自定义提供商**，点击右侧的**连接**。

**Step 3 — 填写 Agnes 提供商配置**

| 字段 | 填写内容 |
|------|----------|
| 提供商 ID | `agnes` |
| 显示名称 | `Agnes` |
| 基础 URL | `https://apihub.agnes-ai.com/v1` |
| API Key | 你的 Agnes API Key（`sk-` 开头） |

> ⚠️ **注意：** API Key 只填写密钥本身，不需要填写 `Bearer`。

**Step 4 — 保存配置**

保存后，OpenCode Desktop 将使用 Agnes 模型进行对话和代码生成。

### 18.4 配置参数速查

| 配置项 | 值 |
|--------|-----|
| Provider | `agnes` 或 `Agnes` |
| Base URL | `https://apihub.agnes-ai.com/v1` |
| Model | `agnes/agnes-2.0-flash`（CLI）或 `agnes-2.0-flash`（Desktop） |
| API Key | 你的 Agnes API Key（`sk-` 开头） |
| API Key 格式 | 只填写密钥，不加 `Bearer` |

### 18.5 常见问题

**Q: 配置后不显示 Agnes 模型？**
- 确认 `baseURL` 正确：`https://apihub.agnes-ai.com/v1`
- 确认 `AGNES_API_KEY` 环境变量已正确设置
- 确认 `provider` 下的 `agnes` 配置语法正确

**Q: 已有其他 provider，如何添加 Agnes？**
- 不要覆盖整个 `provider` 对象
- 在 `provider` 下新增 `agnes` 键值对
- 将顶层 `model` 改为 `agnes/agnes-2.0-flash`

**Q: Desktop 和 CLI 配置冲突？**
- CLI 配置保存在 `~/.config/opencode/` 或项目目录的 `.opencode` 文件夹中
- Desktop 配置保存在应用内部设置中
- 两者独立，不会互相覆盖

---

> Agnes AI，让世界级 AI 属于每一个人。
