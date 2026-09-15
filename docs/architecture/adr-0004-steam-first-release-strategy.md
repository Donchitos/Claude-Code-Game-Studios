# ADR-0004：Steam 首发，移动端与小游戏后续适配

## Status

Accepted for release strategy on 2026-09-10.

2026-09-11产品规模细化：用户确认主要内容20小时以上，商业工作基线见[产品范围](../../design/steam-1.0-product-scope.md)、[章节任务](../../design/steam-1.0-campaign.md)及[发售计划](../../production/steam-1.0-release-plan.md)。这些作者规划未改变本ADR的平台决策，也不构成新增系统/发行批准；MVP基线仅为商业版的核心子集。

## Decision

本项目发行顺序调整为：

1. 首发目标：Steam PC 商业完整版，Windows 作为首要验证目标；其他 Steam 运行环境只有在同一发行质量门通过后再纳入支持矩阵。
2. 后续目标：Android、iOS，再评估微信小游戏及其他小游戏运行环境。
3. 当前主线优先验证键盘/鼠标与手柄、横屏多分辨率、桌面端存档、完整战斗循环、正式美术音频、性能和玩家体验。
4. 移动端 Touch、竖屏、Android/iOS 原生无障碍桥和小游戏平台 API 均作为后续适配层，不再作为 Steam 首发的前置实现目标。

核心玩法、配置、存档语义和战斗规则应保持平台无关；平台输入、窗口布局、支付/广告、分享、原生无障碍和设备生命周期通过独立 adapter 接入。不得为了保留当前移动端合同而把 Steam 首发继续限制为竖屏或 Touch-only。

## IP 与商业命名门槛

当前《凡人修仙传·掌天试炼》及相关人物、设定和专有名词只作为内部工作语境使用。商业 Steam build、商店页、宣传素材和发行包不得在未取得授权的情况下使用第三方 IP 标识。正式商业化前必须完成原创化改名，并同步清理受保护的名称、角色、设定、文案、素材和商店元数据；改名不等于自动获得任何第三方授权。

## Consequences

- 现有 720×1280 竖屏工程设置、移动优先技术偏好和移动无障碍 ADR 不再代表首发平台，需要在正式 PC runtime 实现前迁移或明确标记为后续适配合同。
- Steam 首发仍不能由当前 75 秒灰盒原型或 Input vertical slice 证明；必须完成正式 BattleScope、全 MVP 战斗/局外循环、PC 输入/UI、资产、音频、存档恢复、性能和玩家测试。
- Android/iOS/小游戏的 touch、读屏、渠道 SDK、广告/支付和备案工作不删除，转为 Steam 首发后的独立适配里程碑。
- 当前状态继续保持 `In Review / Re-review Pending`、`implementation-ready=false`、`integration-ready=false`、`runtime/device verified=false`、`battle_ready=false`；本 ADR 只改变优先级，不构成发行批准。

## Release gates

### Steam 首发前

- 原创化名称、IP 清理和商店素材权利链闭合；
- Windows release build 可安装、启动、运行完整局和卸载/更新；
- 键盘/鼠标与手柄路径可玩，横屏和常见 PC 分辨率布局可用；
- BattleScope、敌人/投射物/掉落、技能构筑、Boss、结算、局外成长和 Save 全链路接线；
- 进程强杀/恢复、性能、音频、可读性、玩家试玩和独立发行复核完成；
- Steam 商店页、Coming Soon、定价、税务和发布包清单完成。

### 后续移动端与小游戏

- 在 Steam 版本核心规则稳定后，分别建立 Android/iOS 和小游戏 adapter、输入/布局分支及平台证据；
- 不把 Steam 的桌面证据直接扩大解释为真机移动证据；
- 国内小游戏/Android 商业运营另行完成对应 IP、版号/备案、实名防沉迷和渠道审核要求。
