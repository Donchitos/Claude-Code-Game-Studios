# Security Policy

## Supported Versions

Only the `main` branch receives security fixes. Forks and older releases are
not supported.

# 安全策略

## 支持的版本

只有 `main` 分支会收到安全修复。分叉（fork）和较旧的版本
不受支持。

## Reporting a Vulnerability

**Do not report security vulnerabilities through public GitHub issues.**

Use GitHub's private vulnerability reporting instead:

**[Report a vulnerability →](https://github.com/Donchitos/Claude-Code-Game-Studios/security/advisories/new)**

Include as much detail as possible:
- Description of the vulnerability and what it affects
- Steps to reproduce
- Potential impact and attack scenarios
- Any suggested mitigations

**What to expect:**
- Acknowledgment within **48 hours**
- Status update within **7 days**
- Resolution within **90 days** for confirmed vulnerabilities

## 报告漏洞

**不要通过公开的 GitHub issue 报告安全漏洞。**

请改用 GitHub 的私密漏洞报告功能：

**[报告漏洞 →](https://github.com/Donchitos/Claude-Code-Game-Studios/security/advisories/new)**

请尽可能包含更多细节：
- 漏洞的描述及其影响范围
- 复现步骤
- 潜在影响和攻击场景
- 任何建议的缓解措施

**可以预期的是：**
- **48 小时内**确认收到
- **7 天内**提供状态更新
- 已确认的漏洞在**90 天内**得到解决

## What Is In Scope

CCGS is a **local development tool** — it installs shell hooks and coordinates
AI agents that run directly on your machine. Security issues are primarily about
contributed code that executes in users' environments without their awareness.

### High Severity
- Hooks (`.claude/hooks/*.sh`) that execute malicious or undisclosed shell
  commands on user machines
- Skills or agents that exfiltrate environment variables, API keys, or secrets
- Prompt injection via skill or agent definitions that causes Claude to bypass
  safety measures or take unauthorized destructive actions
- Contributions that silently alter behavior in ways users cannot audit

### Medium Severity
- Skills that make undisclosed outbound network requests
- Agent definitions that escalate permissions or bypass user confirmation prompts
- Hook patterns that behave differently across platforms to conceal behavior
- Skills that write outside their documented scope without an explicit user
  approval step

### Out of Scope
- The behavior of Claude or the Claude Code CLI itself
  (report to [Anthropic](https://www.anthropic.com/security))
- Bugs in the user's Claude Code installation or editor extension
- Theoretical vulnerabilities with no realistic attack path
- Issues requiring physical access to the user's machine

## 范围内的是什么

CCGS 是一个**本地开发工具**——它安装 shell 钩子并协调
直接在你的机器上运行的 AI 智能体。安全问题主要涉及
在用户环境中、用户不知情的情况下执行的贡献代码。

### 高严重性
- 在用户机器上执行恶意或未披露 shell
  命令的钩子（`.claude/hooks/*.sh`）
- 窃取环境变量、API key 或机密的技能或智能体
- 通过技能或智能体定义进行的提示注入，导致 Claude 绕过
  安全措施或采取未经授权的破坏性操作
- 以用户无法审计的方式静默改变行为的贡献

### 中等严重性
- 发起未披露的出站网络请求的技能
- 提升权限或绕过用户确认提示的智能体定义
- 在不同平台上表现不同以隐藏行为的钩子模式
- 在没有明确用户
  批准步骤的情况下，写出其记录范围之外的技能

### 范围之外
- Claude 或 Claude Code CLI 本身的行为
  （请报告给 [Anthropic](https://www.anthropic.com/security)）
- 用户的 Claude Code 安装或编辑器扩展中的缺陷
- 没有现实攻击路径的理论性漏洞
- 需要物理接触用户机器的问题

## Security Guidelines for Contributors

When contributing hooks, skills, or agents:

- **Hooks must be POSIX-compatible** — use `grep -E`, not `grep -P`; avoid
  platform-specific syntax that behaves differently across operating systems
- **No silent network calls** from hooks or skills unless explicitly documented
  and opt-in by the user
- **No reading secrets or environment variables** beyond what is minimally
  required and clearly documented in the skill's header
- **Skills must not write outside their documented scope** without an explicit
  user confirmation step

## 贡献者安全指南

在贡献钩子、技能或智能体时：

- **钩子必须 POSIX 兼容** —— 使用 `grep -E`，不要用 `grep -P`；避免
  在不同操作系统上表现不同的平台特有语法
- **不得有静默的网络调用**，除非明确记录
  并由用户选择启用
- **不得读取机密或环境变量**，超出最低限度
  需要且在技能头部清楚记录的范围
- **技能不得写出其记录范围之外**，除非有明确的
  用户确认步骤

## Disclosure Policy

We follow a **90-day coordinated disclosure** timeline:

1. You submit the vulnerability privately
2. We acknowledge within 48 hours
3. We confirm and assess severity within 7 days
4. We develop and test a fix
5. We notify you before any public disclosure
6. Public disclosure happens after the fix ships, or at 90 days — whichever
   comes first

We credit reporters in release notes unless you prefer to remain anonymous.

## 披露政策

我们遵循**90 天协同披露**时间表：

1. 你私下提交漏洞
2. 我们在 48 小时内确认收到
3. 我们在 7 天内确认并评估严重性
4. 我们开发和测试修复
5. 在任何公开披露前通知你
6. 公开披露在修复发布之后进行，或满 90 天时进行——以先到者
   为准

除非你希望保持匿名，否则我们会在发布说明中为报告者署名。
