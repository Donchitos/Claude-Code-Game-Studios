# Godot Audio — Quick Reference

Last verified: 2026-08-14 | Engine: Godot 4.7.1

## What Changed Since ~4.3 (LLM Cutoff)

### 4.7 Changes
- **`AudioEffectSpectrumAnalyzer.tap_back_pos` 属性完全移除**：无替代（GH-114355）。
- **`AudioStreamPlayer.area_mask` 默认值 `1` → `0`（禁用）**：若用 `Area2D`/`Area3D` 的 `audio_bus_override` 且依赖默认 mask（layer 1），需手动重置 `area_mask` 为 1（GH-107679）。
- **`AudioStreamInteractive.TRANSITION_TO_TIME_PREVIOUS_POSITION` 现已绑定**（GH-114129）。

### 4.6 Changes
- **No audio-specific breaking changes** in this release

### 4.5 Changes
- **No audio-specific breaking changes** in this release

## Current API Patterns

### Playing Audio
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
```gdscript
@onready var audio_3d: AudioStreamPlayer3D = %AudioPlayer3D

func _ready() -> void:
    audio_3d.max_distance = 50.0
    audio_3d.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
    audio_3d.unit_size = 10.0
```

### Audio Buses
```gdscript
# Set bus volumes
AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"Music"), volume_db)
AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"SFX"), volume_db)

# Mute a bus
AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Music"), true)
```

### Object Pooling for SFX
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
- Creating new AudioStreamPlayer nodes at runtime instead of pooling
- Not using audio buses for volume categories (Music, SFX, UI, Voice)
- Using `_process()` for audio timing instead of signals (`finished`)
