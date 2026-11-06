# Unreal Engine 5.8 — Audio Module Reference
# Unreal Engine 5.8 — 音频模块参考

**Last verified:** 2026-10-17 (UE 5.8 changes block); 2026-02-13 (rest of file, written against 5.7)
**Knowledge Gap:** UE 5.7 MetaSounds production-ready; UE 5.8 WASAPI default on Windows

**最后验证：** 2026-10-17（UE 5.8 变更块）；2026-02-13（文件其余部分，基于 5.7 编写）
**知识缺口：** UE 5.7 MetaSounds 生产就绪；UE 5.8 Windows 上默认使用 WASAPI

> **UE 5.8 changes:** The default Windows audio backend is now WASAPI
> (XAudio2 is an opt-in fallback; Epic: "No changes are required on the
> developers end"). `au.EnableRelativeRenderCostVoiceLimit` is on by default,
> so fewer sounds may play under the same voice count — revisit voice-count
> tuning. Attenuation submix sends that were implicitly disabled by
> `bEnableSubmixSends` may now be audible. Audio Insights is production-ready;
> Audio Subtitles is Beta; MetaSound Node Configuration and Templates are
> Experimental. Custom MetaSound nodes: `FNodeClassMetadata::DefaultInterface`
> now takes `FClassInterface`. Source: UE 5.8 release notes, https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-5-8-release-notes?application_version=5.8

> **UE 5.8 变更：** Windows 默认音频后端现在为 WASAPI
> （XAudio2 为可选的回退方案；Epic 表示："开发者端无需任何改动"）。`au.EnableRelativeRenderCostVoiceLimit` 默认开启，
> 因此在相同声道数下可播放的声音可能更少 — 请重新评估声道数调优。此前被 `bEnableSubmixSends` 隐式禁用的衰减子混音发送现在可能变为可听见。Audio Insights 为生产就绪；
> Audio Subtitles 为 Beta；MetaSound Node Configuration 与 Templates 为实验性。自定义 MetaSound 节点：`FNodeClassMetadata::DefaultInterface`
> 现在接受 `FClassInterface`。来源：UE 5.8 发行说明，https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-5-8-release-notes?application_version=5.8

---

## Overview
## 概述

UE 5.8 audio systems:
- **MetaSounds**: Node-based procedural audio (RECOMMENDED, production-ready)
- **Sound Cues**: Legacy node-based audio (use for simple cases)
- **Audio Component**: Play sounds on actors

UE 5.8 音频系统：
- **MetaSounds**：基于节点的程序化音频（推荐，生产就绪）
- **Sound Cues**：旧版基于节点的音频（用于简单场景）
- **Audio Component**：在 Actor 上播放声音

---

## Basic Audio Playback
## 基础音频播放

### Play Sound at Location
### 在指定位置播放声音

```cpp
#include "Kismet/GameplayStatics.h"

// ✅ Play 2D sound (no spatialization)
UGameplayStatics::PlaySound2D(GetWorld(), ExplosionSound);

// ✅ Play sound at location (3D spatial audio)
UGameplayStatics::PlaySoundAtLocation(GetWorld(), ExplosionSound, GetActorLocation());

// ✅ With volume and pitch
UGameplayStatics::PlaySoundAtLocation(GetWorld(), ExplosionSound, GetActorLocation(), 0.7f, 1.2f);
```

---

## Audio Component
## Audio Component

### Audio Component (Persistent Sound)
### Audio Component（常驻声音）

```cpp
// Create audio component
UAudioComponent* AudioComp = CreateDefaultSubobject<UAudioComponent>(TEXT("Audio"));
AudioComp->SetupAttachment(RootComponent);
AudioComp->SetSound(LoopingAmbience);

// Play/Stop
AudioComp->Play();
AudioComp->Stop();

// Fade in/out
AudioComp->FadeIn(2.0f); // 2 seconds
AudioComp->FadeOut(1.5f, 0.0f); // 1.5s to volume 0

// Adjust volume/pitch
AudioComp->SetVolumeMultiplier(0.5f);
AudioComp->SetPitchMultiplier(1.2f);
```

---

## 3D Spatial Audio
## 3D 空间音频

### Attenuation Settings
### 衰减设置

```cpp
// Create Sound Attenuation asset:
// Content Browser > Sounds > Sound Attenuation

// Configure:
// - Attenuation Shape: Sphere, Capsule, Box, Cone
// - Falloff Distance: Distance where sound becomes inaudible
// - Attenuation Function: Linear, Logarithmic, Inverse, etc.

// Assign in C++:
AudioComp->AttenuationSettings = AttenuationAsset;
```

### Attenuation Override in Code
### 在代码中覆盖衰减

```cpp
FSoundAttenuationSettings AttenuationOverride;
AttenuationOverride.AttenuationShape = EAttenuationShape::Sphere;
AttenuationOverride.FalloffDistance = 1000.0f;
AttenuationOverride.AttenuationShapeExtents = FVector(1000.0f);

AudioComp->AttenuationOverrides = AttenuationOverride;
AudioComp->bOverrideAttenuation = true;
```

---

## MetaSounds (Procedural Audio)
## MetaSounds（程序化音频）

### Create MetaSound Source
### 创建 MetaSound Source

1. Content Browser > Sounds > MetaSound Source
2. Open MetaSound editor
3. Build node graph:
   - **Inputs**: Triggers, parameters
   - **Generators**: Oscillators, noise, samples
   - **Modulators**: Envelopes, LFOs
   - **Effects**: Filters, reverb, delay
   - **Output**: Audio output

1. Content Browser > Sounds > MetaSound Source
2. 打开 MetaSound 编辑器
3. 构建节点图：
   - **输入（Inputs）**：触发器、参数
   - **生成器（Generators）**：振荡器、噪声、采样
   - **调制器（Modulators）**：包络、LFO
   - **效果（Effects）**：滤波器、混响、延迟
   - **输出（Output）**：音频输出

### Play MetaSound
### 播放 MetaSound

```cpp
// Play MetaSound like any sound
UGameplayStatics::PlaySound2D(GetWorld(), MetaSoundSource);

// Or with Audio Component
AudioComp->SetSound(MetaSoundSource);
AudioComp->Play();
```

### Set MetaSound Parameters
### 设置 MetaSound 参数

```cpp
// Define parameter in MetaSound (Input node with exposed parameter)
// Set parameter in C++:
AudioComp->SetFloatParameter(FName("Volume"), 0.8f);
AudioComp->SetIntParameter(FName("OctaveShift"), 2);
AudioComp->SetBoolParameter(FName("EnableReverb"), true);
```

---

## Sound Cues (Legacy)
## Sound Cues（旧版）

### Create Sound Cue
### 创建 Sound Cue

1. Content Browser > Sounds > Sound Cue
2. Open Sound Cue editor
3. Add nodes: Random, Modulator, Mixer, etc.

1. Content Browser > Sounds > Sound Cue
2. 打开 Sound Cue 编辑器
3. 添加节点：Random、Modulator、Mixer 等

### Use Sound Cue
### 使用 Sound Cue

```cpp
// Play like any sound
UGameplayStatics::PlaySound2D(GetWorld(), SoundCue);
```

---

## Sound Classes & Sound Mixes
## Sound Class 与 Sound Mix

### Sound Class (Volume Groups)
### Sound Class（音量分组）

```cpp
// Create Sound Class: Content Browser > Sounds > Sound Class
// Hierarchy: Master > Music, SFX, Dialogue

// Assign to sound asset:
// Sound Wave > Sound Class = SFX

// Set volume in C++:
UAudioSettings* AudioSettings = GetMutableDefault<UAudioSettings>();
// Configure via Sound Class hierarchy
```

### Sound Mix (Dynamic Mixing)
### Sound Mix（动态混音）

```cpp
// Create Sound Mix asset
// Define adjustments: Lower music during dialogue, etc.

// Push sound mix
UGameplayStatics::PushSoundMixModifier(GetWorld(), DuckedMusicMix);

// Pop sound mix
UGameplayStatics::PopSoundMixModifier(GetWorld(), DuckedMusicMix);
```

---

## Audio Occlusion & Reverb
## 音频遮挡与混响

### Audio Occlusion (Walls Block Sound)
### 音频遮挡（墙壁阻挡声音）

```cpp
// Enable in Audio Component:
AudioComp->bEnableOcclusion = true;

// Requires geometry with collision
```

### Reverb Volumes
### 混响体积

```cpp
// Add Audio Volume to level (Volumes > Audio Volume)
// Configure reverb settings in Details panel
// Audio component automatically picks up reverb when inside volume
```

---

## Common Patterns
## 常见模式

### Footstep Sounds (Random Variation)
### 脚步声（随机变化）

```cpp
// Use Sound Cue with Random node, or:
UPROPERTY(EditAnywhere, Category = "Audio")
TArray<TObjectPtr<USoundBase>> FootstepSounds;

void PlayFootstep() {
    int32 Index = FMath::RandRange(0, FootstepSounds.Num() - 1);
    UGameplayStatics::PlaySoundAtLocation(GetWorld(), FootstepSounds[Index], GetActorLocation());
}
```

### Music Crossfade
### 音乐交叉淡化

```cpp
UAudioComponent* MusicA;
UAudioComponent* MusicB;

void CrossfadeMusic(float Duration) {
    MusicA->FadeOut(Duration, 0.0f);
    MusicB->FadeIn(Duration);
}
```

### Check if Sound is Playing
### 检查声音是否正在播放

```cpp
if (AudioComp->IsPlaying()) {
    // Sound is playing
}
```

---

## Audio Concurrency
## 音频并发

### Limit Concurrent Sounds
### 限制并发声音

```cpp
// Create Sound Concurrency asset:
// Content Browser > Sounds > Sound Concurrency

// Configure:
// - Max Count: Maximum instances of this sound
// - Resolution Rule: Stop Oldest, Stop Quietest, etc.

// Assign to sound:
// Sound Wave > Concurrency Settings
```

---

## Performance Tips
## 性能建议

### Audio Optimization
### 音频优化

```cpp
// Compression settings (Sound Wave asset):
// - Compression Quality: 40 (balance quality/size)
// - Streaming: Enable for large files (music)

// Reduce audio mixing cost:
// - Limit concurrent sounds via Sound Concurrency
// - Use simple attenuation shapes

// Disable audio for distant actors:
if (Distance > MaxAudibleDistance) {
    AudioComp->Stop();
}
```

---

## Debugging
## 调试

### Audio Debug Commands
### 音频调试命令

```cpp
// Console commands:
// au.Debug.Sounds 1 - Show active sounds
// au.3dVisualize.Enabled 1 - Visualize 3D audio
// stat soundwaves - Show sound statistics
// stat soundmixes - Show active sound mixes
```

---

## Sources
## 来源

- https://docs.unrealengine.com/5.7/en-US/audio-in-unreal-engine/
- https://docs.unrealengine.com/5.7/en-US/metasounds-in-unreal-engine/
