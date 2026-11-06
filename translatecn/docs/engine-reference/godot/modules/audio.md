# Godot Audio — Quick Reference
# Godot 音频 — 快速参考

Last verified: 2026-10-17 (4.7 changes); 2026-02-12 (rest) | Engine: Godot 4.7
最后验证：2026-10-17（4.7 变更）；2026-02-12（其余部分） | 引擎：Godot 4.7

## What Changed Since ~4.3 (LLM Cutoff)
## 自约 4.3（LLM 截止）以来的变更

No major breaking changes to the audio API in 4.4–4.6; 4.7 removes one
property and changes one default:
4.4–4.6 中音频 API 没有重大的破坏性变更；4.7 移除了一个属性并更改了一个默认值：

### 4.7 Changes
### 4.7 变更
- **`AudioEffectSpectrumAnalyzer.tap_back_pos` removed**
- **`AudioEffectSpectrumAnalyzer.tap_back_pos` 已移除**
- **`area_mask` on `AudioStreamPlayer2D`/`3D` defaults to `0`** (was layer `1`):
  `audio_bus_override` on an `Area2D`/`Area3D` stops working with the default
  mask until it is set back to layer `1` (4.7 migration guide: https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html)
- **`AudioStreamPlayer2D`/`3D` 上的 `area_mask` 默认值为 `0`**（原为层 `1`）：`Area2D`/`Area3D` 上的 `audio_bus_override` 在默认掩码下会停止工作，直到将其重新设为层 `1`（4.7 迁移指南：https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html）

### 4.6 Changes
### 4.6 变更
- **No audio-specific breaking changes** in this release
- 此版本**没有音频相关的破坏性变更**

### 4.5 Changes
### 4.5 变更
- **No audio-specific breaking changes** in this release
- 此版本**没有音频相关的破坏性变更**

## Current API Patterns
## 当前 API 模式

### Playing Audio
### 播放音频
```gdscript
@onready var sfx_player: AudioStreamPlayer = %SFXPlayer
@onready var music_player: AudioStreamPlayer = %MusicPlayer

func play_sfx(stream: AudioStream) -> void:
    sfx_player.stream = stream
    sfx_player.play()

func play_music(stream: AudioStream, fade_time: float = 1.0) -> void:
    var tween: Tween = create_tween()
    tween.tween_property(music_player, "volume_db", -80.0, fade_time)
    await tween.finished
    music_player.stream = stream
    music_player.volume_db = 0.0
    music_player.play()
```

### 3D Spatial Audio
### 3D 空间音频
```gdscript
@onready var audio_3d: AudioStreamPlayer3D = %AudioPlayer3D

func _ready() -> void:
    audio_3d.max_distance = 50.0
    audio_3d.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
    audio_3d.unit_size = 10.0
```

### Audio Buses
### 音频总线
```gdscript
# Set bus volumes
AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"Music"), volume_db)
AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"SFX"), volume_db)

# Mute a bus
AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Music"), true)
```

### Object Pooling for SFX
### 音效对象池
```gdscript
# Pre-create multiple AudioStreamPlayer nodes for concurrent sounds
var _sfx_pool: Array[AudioStreamPlayer] = []

func _ready() -> void:
    for i in range(8):
        var player := AudioStreamPlayer.new()
        player.bus = &"SFX"
        add_child(player)
        _sfx_pool.append(player)

func play_pooled(stream: AudioStream) -> void:
    for player in _sfx_pool:
        if not player.playing:
            player.stream = stream
            player.play()
            return
```

## Common Mistakes
## 常见错误
- Creating new AudioStreamPlayer nodes at runtime instead of pooling
- 在运行时创建新的 AudioStreamPlayer 节点，而非使用对象池
- Not using audio buses for volume categories (Music, SFX, UI, Voice)
- 未使用音频总线来划分音量类别（Music、SFX、UI、Voice）
- Using `_process()` for audio timing instead of signals (`finished`)
- 使用 `_process()` 处理音频计时，而非使用信号（`finished`）
