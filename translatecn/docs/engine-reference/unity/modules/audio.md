# Unity 6.3 — Audio Module Reference
# Unity 6.3 — 音频模块参考

**Last verified:** 2026-02-13
**最后验证：** 2026-02-13
**Knowledge Gap:** Unity 6 audio mixer improvements
**知识盲区：** Unity 6 的音频混合器改进

---

## Overview
## 概述

Unity 6.3 audio systems:
- **AudioSource**: Play sounds on GameObjects
- **Audio Mixer**: Mix, effect processing, dynamic mixing
- **Spatial Audio**: 3D positioned sound

Unity 6.3 音频系统：
- **AudioSource**：在 GameObject 上播放声音
- **Audio Mixer**：混音、效果处理、动态混音
- **空间音频（Spatial Audio）**：3D 定位的声音

---

## Basic Audio Playback
## 基本音频播放

### AudioSource Component
### AudioSource 组件

```csharp
AudioSource audioSource = GetComponent<AudioSource>();

// ✅ Play
audioSource.Play();

// ✅ Play with delay
audioSource.PlayDelayed(0.5f); // 0.5 seconds

// ✅ Play one-shot (doesn't interrupt current sound)
audioSource.PlayOneShot(clip);

// ✅ Stop
audioSource.Stop();

// ✅ Pause/Resume
audioSource.Pause();
audioSource.UnPause();
```

### Play Sound at Position (Static Method)
### 在指定位置播放声音（静态方法）

```csharp
// ✅ Quick 3D sound playback (auto-destroys when done)
AudioSource.PlayClipAtPoint(clip, transform.position);

// ✅ With volume
AudioSource.PlayClipAtPoint(clip, transform.position, 0.7f);
```

---

## 3D Spatial Audio
## 3D 空间音频

### AudioSource 3D Settings
### AudioSource 的 3D 设置

```csharp
AudioSource source = GetComponent<AudioSource>();

// Spatial Blend: 0 = 2D, 1 = 3D
source.spatialBlend = 1.0f; // Fully 3D

// Doppler effect (pitch shift based on velocity)
source.dopplerLevel = 1.0f;

// Distance attenuation
source.minDistance = 1f;   // Full volume within this distance
source.maxDistance = 50f;  // Inaudible beyond this distance
source.rolloffMode = AudioRolloffMode.Logarithmic; // Natural falloff
```

### Volume Rolloff Curves
### 音量衰减曲线（Rolloff）
- **Logarithmic**: Natural, realistic (RECOMMENDED)
- **Linear**: Steady decrease
- **Custom**: Define your own curve

- **对数（Logarithmic）**：自然、真实（推荐）
- **线性（Linear）**：均匀衰减
- **自定义（Custom）**：定义你自己的曲线

---

## Audio Mixer (Advanced Mixing)
## Audio Mixer（高级混音）

### Setup Audio Mixer
### 设置 Audio Mixer

1. `Assets > Create > Audio Mixer`
2. Open mixer: `Window > Audio > Audio Mixer`
3. Create groups: Master > SFX, Music, Dialogue

1. `Assets > Create > Audio Mixer`
2. 打开混音器：`Window > Audio > Audio Mixer`
3. 创建分组：Master > SFX、Music、Dialogue

### Assign AudioSource to Mixer Group
### 将 AudioSource 指派到混音器分组

```csharp
using UnityEngine.Audio;

public AudioMixerGroup sfxGroup;

void Start() {
    AudioSource source = GetComponent<AudioSource>();
    source.outputAudioMixerGroup = sfxGroup; // Route to SFX group
}
```

### Control Mixer from Code
### 通过代码控制混音器

```csharp
using UnityEngine.Audio;

public AudioMixer audioMixer;

// ✅ Set volume (exposed parameter)
audioMixer.SetFloat("MusicVolume", -10f); // dB (-80 to 0)

// ✅ Get volume
audioMixer.GetFloat("MusicVolume", out float volume);

// Convert linear (0-1) to dB
float volumeDB = Mathf.Log10(volumeLinear) * 20f;
audioMixer.SetFloat("MusicVolume", volumeDB);
```

### Expose Mixer Parameters
### 暴露混音器参数
In Audio Mixer window:
1. Right-click parameter (e.g., Volume)
2. "Expose 'Volume' to script"
3. Rename in "Exposed Parameters" tab (e.g., "MusicVolume")

在 Audio Mixer 窗口中：
1. 右键单击参数（例如 Volume）
2. 选择 "Expose 'Volume' to script"
3. 在 "Exposed Parameters" 选项卡中重命名（例如 "MusicVolume"）

---

## Audio Effects
## 音频效果

### Add Effects to Mixer Groups
### 为混音器分组添加效果

In Audio Mixer:
- Click group (e.g., SFX)
- Click "Add Effect"
- Choose: Reverb, Echo, Low Pass, High Pass, Distortion, etc.

在 Audio Mixer 中：
- 单击分组（例如 SFX）
- 单击 "Add Effect"
- 选择：Reverb、Echo、Low Pass、High Pass、Distortion 等

### Duck Music During Dialogue (Sidechain)
### 对白期间压低音乐（侧链，Sidechain）

```csharp
// Setup in Audio Mixer:
// 1. Create "Duck Volume" snapshot
// 2. Lower music volume in that snapshot
// 3. Transition to snapshot when dialogue plays

public AudioMixerSnapshot normalSnapshot;
public AudioMixerSnapshot duckedSnapshot;

public void PlayDialogue(AudioClip clip) {
    duckedSnapshot.TransitionTo(0.5f); // 0.5s transition
    audioSource.PlayOneShot(clip);
    Invoke(nameof(RestoreMusic), clip.length);
}

void RestoreMusic() {
    normalSnapshot.TransitionTo(1.0f); // 1s transition back
}
```

---

## Audio Performance
## 音频性能

### Optimize Audio Loading
### 优化音频加载

```csharp
// Audio Import Settings (Inspector):
// - Load Type:
//   - Decompress On Load: Small clips (SFX), loads fully into memory
//   - Compressed In Memory: Medium clips, decompressed at runtime (RECOMMENDED)
//   - Streaming: Large clips (music), streamed from disk

// Compression Format:
// - PCM: Uncompressed, highest quality, largest size
// - ADPCM: 3.5x compression, good for SFX (RECOMMENDED for SFX)
// - Vorbis/MP3: High compression, good for music (RECOMMENDED for music)
```

### Preload Audio
### 预加载音频

```csharp
// Preload audio clip before playing (avoid stutter)
audioSource.clip.LoadAudioData();

// Check if loaded
if (audioSource.clip.loadState == AudioDataLoadState.Loaded) {
    audioSource.Play();
}
```

---

## Music Systems
## 音乐系统

### Crossfade Between Tracks
### 曲目之间的交叉淡入淡出

```csharp
public IEnumerator CrossfadeMusic(AudioSource from, AudioSource to, float duration) {
    float elapsed = 0f;
    to.Play();

    while (elapsed < duration) {
        elapsed += Time.deltaTime;
        float t = elapsed / duration;

        from.volume = Mathf.Lerp(1f, 0f, t);
        to.volume = Mathf.Lerp(0f, 1f, t);

        yield return null;
    }

    from.Stop();
}
```

### Seamless Music Looping
### 无缝音乐循环

```csharp
// Audio Import Settings:
// - Check "Loop" for seamless music loops
audioSource.loop = true;
```

---

## Common Patterns
## 常见模式

### Random Pitch Variation (Avoid Repetition)
### 随机音高变化（避免重复感）

```csharp
void PlaySoundWithVariation(AudioClip clip) {
    AudioSource source = GetComponent<AudioSource>();
    source.pitch = Random.Range(0.9f, 1.1f); // ±10% pitch variation
    source.PlayOneShot(clip);
}
```

### Footstep Sounds (Random from Array)
### 脚步声（从数组中随机选取）

```csharp
public AudioClip[] footstepClips;

void PlayFootstep() {
    AudioClip clip = footstepClips[Random.Range(0, footstepClips.Length)];
    AudioSource.PlayClipAtPoint(clip, transform.position, 0.5f);
}
```

### Check if Sound is Playing
### 检查声音是否正在播放

```csharp
if (audioSource.isPlaying) {
    // Sound is currently playing
}
```

---

## Audio Listener
## 音频监听器（Audio Listener）

### Single Listener Rule
### 单一监听器规则
- Only ONE `AudioListener` should be active at a time
- Usually attached to Main Camera

- 同一时间只应有一个 `AudioListener` 处于活动状态
- 通常挂载在主摄像机上

```csharp
// Disable extra listeners
AudioListener listener = GetComponent<AudioListener>();
listener.enabled = false;
```

---

## Debugging
## 调试

### Audio Window
### Audio 窗口
- `Window > Audio > Audio Mixer`
- Visualize levels, test snapshots

- `Window > Audio > Audio Mixer`
- 可视化电平、测试快照（snapshot）

### Audio Settings
### 音频设置
- `Edit > Project Settings > Audio`
- Global volume, DSP buffer size, speaker mode

- `Edit > Project Settings > Audio`
- 全局音量、DSP 缓冲区大小、扬声器模式

---

## Sources
## 来源
- https://docs.unity3d.com/6000.0/Documentation/Manual/Audio.html
- https://docs.unity3d.com/6000.0/Documentation/Manual/AudioMixer.html
