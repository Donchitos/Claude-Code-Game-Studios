# Sound Bible: [Project Name]
# 声音圣经：[项目名称]

> **Location**: `design/audio/sound-bible.md` — not `design/gdd/`, where the GDD checks count every file as a system GDD
> **位置**：`design/audio/sound-bible.md` — 而非 `design/gdd/`，那里的 GDD 检查会把每个文件都算作系统 GDD
> **Owned By**: audio-director
> **负责人**：audio-director

## Audio Vision
## 音频愿景

### Sonic Identity
### 声音身份
[Describe the overall audio personality of the game in 2-3 sentences. What does the game "sound like"? What emotions should the audio evoke?]
[用 2-3 句话描述游戏的整体音频个性。游戏"听起来像什么"？音频应唤起哪些情绪？]

### Audio Pillars
### 音频支柱
1. **[Pillar 1]**: [How this pillar manifests in audio]
1. **[支柱 1]**：[该支柱如何在音频中体现]
2. **[Pillar 2]**: [How this pillar manifests in audio]
2. **[支柱 2]**：[该支柱如何在音频中体现]
3. **[Pillar 3]**: [How this pillar manifests in audio]
3. **[支柱 3]**：[该支柱如何在音频中体现]

### Reference Games / Media
### 参考游戏 / 媒体
| Reference | What to Take From It | What to Avoid |
| ---- | ---- | ---- |
| [Game/Film 1] | [Specific audio quality to emulate] | [What doesn't fit our vision] |
| [Game/Film 2] | [Specific audio quality to emulate] | [What doesn't fit our vision] |

| 参考 | 从中借鉴什么 | 应避免什么 |
| ---- | ---- | ---- |
| [游戏/影片 1] | [要效仿的具体音频特质] | [不符合我们愿景的部分] |
| [游戏/影片 2] | [要效仿的具体音频特质] | [不符合我们愿景的部分] |

---

## Music Direction
## 音乐方向

### Style and Genre
### 风格与类型
[Primary musical style, instrumentation palette, tempo ranges]
[主要音乐风格、配器调色板、速度范围]

### Instrumentation Palette
### 配器调色板
- **Core instruments**: [List the primary instruments/synths that define the sound]
- **核心乐器**：[列出定义声音的主要乐器/合成器]
- **Accent instruments**: [Used for emphasis, transitions, special moments]
- **强调乐器**：[用于强调、过渡、特殊时刻]
- **Avoid**: [Instruments or styles that do NOT fit the game]
- **避免**：[不符合本游戏的乐器或风格]

### Adaptive Music System
### 自适应音乐系统
| Game State | Music Behavior | Transition |
| ---- | ---- | ---- |
| Exploration | [Tempo, energy, instrumentation] | [How it transitions to next state] |
| Combat | [Tempo, energy, instrumentation] | [Trigger condition and crossfade time] |
| Stealth/Tension | [Tempo, energy, instrumentation] | [Trigger and transition] |
| Victory/Reward | [Stinger or transition behavior] | [Return to exploration] |
| Menu/UI | [Style for menus] | [Fade on game start] |

| 游戏状态 | 音乐行为 | 过渡 |
| ---- | ---- | ---- |
| 探索 | [速度、能量、配器] | [如何过渡到下一状态] |
| 战斗 | [速度、能量、配器] | [触发条件与交叉淡入时间] |
| 潜行/紧张 | [速度、能量、配器] | [触发与过渡] |
| 胜利/奖励 | [短促音效或过渡行为] | [回到探索] |
| 菜单/UI | [菜单风格] | [游戏开始时淡出] |

### Music Rules
### 音乐规则
- [Rule about looping, e.g., "All exploration tracks must loop seamlessly after 2-4 minutes"]
- [关于循环的规则，例如"所有探索曲目必须在 2-4 分钟后无缝循环"]
- [Rule about silence, e.g., "Allow 10-15 seconds of silence between exploration loops"]
- [关于静默的规则，例如"探索循环之间允许 10-15 秒静默"]
- [Rule about intensity, e.g., "Combat music must reach full intensity within 3 seconds of combat start"]
- [关于强度的规则，例如"战斗音乐必须在战斗开始 3 秒内达到满强度"]
- [Rule about transitions, e.g., "All music transitions use 1.5 second crossfades"]
- [关于过渡的规则，例如"所有音乐过渡使用 1.5 秒交叉淡入"]

---

## Sound Effects
## 音效

### SFX Palette
### 音效调色板
| Category | Description | Style Notes |
| ---- | ---- | ---- |
| Player Actions | [Movement, attacks, abilities] | [Punchy, responsive, front-of-mix] |
| Enemy Actions | [Attacks, abilities, death] | [Distinct from player, slightly recessed] |
| UI | [Button clicks, menu transitions, notifications] | [Clean, subtle, never annoying on repeat] |
| Environment | [Ambient loops, weather, objects] | [Immersive, layered, spatial] |
| Feedback | [Damage taken, item pickup, level up] | [Clear, satisfying, non-fatiguing] |

| 类别 | 描述 | 风格备注 |
| ---- | ---- | ---- |
| 玩家动作 | [移动、攻击、技能] | [有力、响应迅速、位于混音前部] |
| 敌人动作 | [攻击、技能、死亡] | [与玩家区分，略微后退] |
| UI | [按钮点击、菜单过渡、通知] | [干净、细微、重复播放不烦人] |
| 环境 | [环境循环、天气、物体] | [沉浸、分层、空间化] |
| 反馈 | [受到伤害、拾取物品、升级] | [清晰、满足、不易疲劳] |

### Audio Feedback Priority
### 音频反馈优先级
When multiple sounds compete, this priority determines what plays:
当多个声音竞争时，该优先级决定播放什么：
1. Player damage / critical warnings (always audible)
1. 玩家受伤 / 危急警告（始终可闻）
2. Player actions (attacks, abilities)
2. 玩家动作（攻击、技能）
3. Enemy actions (nearby enemies first)
3. 敌人动作（优先附近敌人）
4. UI feedback
4. UI 反馈
5. Environment / ambient
5. 环境 / 氛围

### SFX Rules
### 音效规则
- [Rule about repetition, e.g., "Every SFX with >3 plays/minute needs 3+ variations"]
- [关于重复的规则，例如"每分钟播放超过 3 次的音效需要 3 个以上变体"]
- [Rule about spatial audio, e.g., "All gameplay SFX must be 3D positioned, UI SFX are 2D"]
- [关于空间音频的规则，例如"所有游戏性音效必须 3D 定位，UI 音效为 2D"]
- [Rule about ducking, e.g., "Player hit SFX ducks all other SFX by 3dB for 200ms"]
- [关于闪避（ducking）的规则，例如"玩家受击音效使其他所有音效降低 3dB，持续 200ms"]
- [Rule about response time, e.g., "Action SFX must trigger within 1 frame of the action"]
- [关于响应时间的规则，例如"动作音效必须在动作后 1 帧内触发"]

---

## Mixing
## 混音

### Mix Bus Structure
### 混音总线结构
| Bus | Content | Target Level |
| ---- | ---- | ---- |
| Master | Everything | 0 dB |
| Music | All music tracks | [target dBFS] |
| SFX | All sound effects | [target dBFS] |
| Dialogue | All voice/narration | [target dBFS] |
| UI | All interface sounds | [target dBFS] |
| Ambient | Environment loops | [target dBFS] |

| 总线 | 内容 | 目标电平 |
| ---- | ---- | ---- |
| 主输出 | 全部内容 | 0 dB |
| 音乐 | 所有音乐曲目 | [目标 dBFS] |
| 音效 | 所有音效 | [目标 dBFS] |
| 对白 | 所有语音/旁白 | [目标 dBFS] |
| UI | 所有界面声音 | [目标 dBFS] |
| 环境 | 环境循环 | [目标 dBFS] |

### Mixing Rules
### 混音规则
- Dialogue always takes priority — duck music and SFX during dialogue
- 对白始终优先——对白期间压低音乐与音效
- Music should be felt, not dominate — if players can't hear SFX over music, music is too loud
- 音乐应被感受到而非主导——若玩家在音乐之上听不到音效，说明音乐太响
- Master output must never clip — use a limiter on the master bus
- 主输出绝不可削波——在主总线上使用限幅器
- All volumes must be adjustable by the player (per bus)
- 所有音量必须可由玩家调整（按总线）
- Default mix should sound good on both speakers and headphones
- 默认混音应在音箱与耳机上都具有良好听感

### Dynamic Range
### 动态范围
- [Specify loudness targets, e.g., "Target -14 LUFS integrated, -1 dBTP true peak"]
- [指定响度目标，例如"目标 -14 LUFS 整体响度，-1 dBTP 真峰值"]
- [Specify compression policy, e.g., "Light compression on SFX bus, no compression on music"]
- [指定压缩策略，例如"音效总线轻压缩，音乐不压缩"]

---

## Technical Specifications
## 技术规格

### Format Requirements
### 格式要求
| Type | Format | Sample Rate | Bit Depth | Notes |
| ---- | ---- | ---- | ---- | ---- |
| Music | [OGG/WAV] | [44.1/48 kHz] | [16/24 bit] | [Streaming from disk] |
| SFX | [WAV/OGG] | [44.1/48 kHz] | [16 bit] | [Loaded into memory] |
| Ambient | [OGG] | [44.1 kHz] | [16 bit] | [Streaming, loopable] |
| Dialogue | [OGG/WAV] | [44.1 kHz] | [16 bit] | [Streaming] |

| 类型 | 格式 | 采样率 | 位深 | 备注 |
| ---- | ---- | ---- | ---- | ---- |
| 音乐 | [OGG/WAV] | [44.1/48 kHz] | [16/24 位] | [从磁盘流式加载] |
| 音效 | [WAV/OGG] | [44.1/48 kHz] | [16 位] | [加载到内存] |
| 环境 | [OGG] | [44.1 kHz] | [16 位] | [流式，可循环] |
| 对白 | [OGG/WAV] | [44.1 kHz] | [16 位] | [流式] |

### Naming Convention
### 命名约定
`[category]_[subcategory]_[name]_[variation].ext`
`[category]_[subcategory]_[name]_[variation].ext`
- Example: `sfx_weapon_sword_swing_01.wav`
- 示例：`sfx_weapon_sword_swing_01.wav`
- Example: `music_exploration_forest_loop.ogg`
- 示例：`music_exploration_forest_loop.ogg`
- Example: `amb_environment_cave_drip_loop.ogg`
- 示例：`amb_environment_cave_drip_loop.ogg`

### Memory Budget
### 内存预算
- Total audio memory: [target, e.g., 128 MB]
- 音频内存总量：[目标，例如 128 MB]
- SFX pool: [target]
- 音效池：[目标]
- Music streaming buffer: [target]
- 音乐流缓冲：[目标]
- Voice streaming buffer: [target]
- 语音流缓冲：[目标]

---

## Accessibility
## 无障碍

- All critical audio cues must have visual alternatives (subtitles, screen flash, icon)
- 所有关键音频提示都必须有视觉替代（字幕、屏幕闪烁、图标）
- Mono audio option for hearing-impaired players
- 为听障玩家提供单声道音频选项
- Separate volume controls for all buses
- 所有总线均有独立音量控制
- Option to disable sudden loud sounds
- 可选择禁用突然的巨响
- Subtitle support for all dialogue with speaker identification
- 所有对白均支持字幕，并标明说话者
