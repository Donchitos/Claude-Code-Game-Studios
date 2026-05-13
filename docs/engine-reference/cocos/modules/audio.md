# Cocos Creator Audio — Quick Reference

Last verified: 2026-06-27 | Engine: Cocos Creator 3.8.6

## What Changed Since v3.0

### v3.0 — Major API replacement
- `cc.audioEngine.*` (URL-based) → `AudioSource` component (asset-based)
- Audio playback moved from global function to a per-node component

### v3.8 — Minor additions
- Streaming audio support for long tracks (BGM)
- Audio mixer groups (route audio through bus / effect chains)
- 3D spatial audio via `AudioSource` + node position

### v3.8.6 — No audio-specific breaking changes

## Current API Patterns

### AudioSource component (primary API)
```typescript
import { _decorator, Component, AudioSource, AudioClip } from 'cc';
const { ccclass, property } = _decorator;

@ccclass('MusicManager')
export class MusicManager extends Component {
    @property({ type: AudioClip })
    public bgm: AudioClip | null = null;

    private _audioSource: AudioSource | null = null;

    onLoad() {
        this._audioSource = this.getComponent(AudioSource) ?? this.addComponent(AudioSource);
        if (this.bgm) this._audioSource.clip = this.bgm;
    }

    start() {
        this._audioSource?.play();
    }
}
```

### One-shot SFX
```typescript
import { AudioSource, AudioClip } from 'cc';

// Cache the AudioSource, play one-shots through it
const audio = this.getComponent(AudioSource)!;
audio.playOneShot(clip, 1.0);  // clip, volumeScale
```

### Async loading audio
```typescript
const bundle = await loadBundle('audio-bundle');
const clip = await loadAsync(bundle, 'bgm/level1', AudioClip);
audioSource.clip = clip;
audioSource.play();
```

### 3D Spatial Audio
- Place `AudioSource` on a 3D node in the scene
- Set `audioSource.spatialBlend = 1.0` (fully 3D)
- Set `audioSource.rolloffMode = RolloffMode.LOGARITHMIC` for natural distance attenuation
- Listener is on the main camera by default

## Common Mistakes
- Using `cc.audioEngine.play(url, ...)` (removed in 3.0) — use `AudioSource`
- Calling `audioSource.play()` before `clip` is set — silent failure
- Not unsubscribing from one-shot events — listener leak if you do `audioSource.node.on('ended', ...)`
- Forgetting to release audio clips after level change — memory grows
- Loading large BGM via `resources.load()` — use streaming or bundle preload
- Setting `audioSource.volume = 0` instead of `audioSource.mute = true` — volume state lost
