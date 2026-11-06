# Unity 6.3 — UI Module Reference
# Unity 6.3 — UI 模块参考

**Last verified:** 2026-02-13
**最后验证：** 2026-02-13
**Knowledge Gap:** Unity 6 UI Toolkit is production-ready for runtime UI
**知识盲区：** Unity 6 的 UI Toolkit 已可用于生产环境的运行时 UI

---

## Overview
## 概述

Unity 6 UI systems:
- **UI Toolkit** (RECOMMENDED): Modern, performant, HTML/CSS-like (production-ready in Unity 6)
- **UGUI (Canvas)**: Legacy system, still supported but not recommended for new projects
- **IMGUI**: Editor-only, deprecated for runtime UI

Unity 6 UI 系统：
- **UI Toolkit（推荐）**：现代、性能良好、类 HTML/CSS（在 Unity 6 中已生产就绪）
- **UGUI（Canvas）**：旧版系统，仍受支持但不推荐用于新项目
- **IMGUI**：仅限编辑器，运行时 UI 已弃用

---

## UI Toolkit (Modern UI)
## UI Toolkit（现代 UI）

### Setup UI Document
### 设置 UI Document

1. Create UXML (UI structure):
   - `Assets > Create > UI Toolkit > UI Document`
2. Create USS (styling):
   - `Assets > Create > UI Toolkit > StyleSheet`
3. Add to scene:
   - `GameObject > UI Toolkit > UI Document`
   - Assign UXML to `UIDocument > Source Asset`

1. 创建 UXML（UI 结构）：
   - `Assets > Create > UI Toolkit > UI Document`
2. 创建 USS（样式）：
   - `Assets > Create > UI Toolkit > StyleSheet`
3. 添加到场景：
   - `GameObject > UI Toolkit > UI Document`
   - 将 UXML 指派到 `UIDocument > Source Asset`

---

### UXML (UI Structure)
### UXML（UI 结构）

```xml
<!-- MainMenu.uxml -->
<ui:UXML xmlns:ui="UnityEngine.UIElements">
    <ui:VisualElement class="container">
        <ui:Label text="Main Menu" class="title" />
        <ui:Button name="play-button" text="Play" />
        <ui:Button name="settings-button" text="Settings" />
        <ui:Button name="quit-button" text="Quit" />
    </ui:VisualElement>
</ui:UXML>
```

---

### USS (Styling)
### USS（样式）

```css
/* MainMenu.uss */
.container {
    flex-direction: column;
    align-items: center;
    justify-content: center;
    width: 100%;
    height: 100%;
    background-color: rgb(30, 30, 30);
}

.title {
    font-size: 48px;
    color: white;
    margin-bottom: 20px;
}

Button {
    width: 200px;
    height: 50px;
    margin: 10px;
    font-size: 24px;
}

Button:hover {
    background-color: rgb(100, 150, 200);
}
```

---

### C# Scripting (UI Toolkit)
### C# 脚本（UI Toolkit）

```csharp
using UnityEngine;
using UnityEngine.UIElements;

public class MainMenu : MonoBehaviour {
    void OnEnable() {
        var root = GetComponent<UIDocument>().rootVisualElement;

        // Query elements by name
        var playButton = root.Q<Button>("play-button");
        var settingsButton = root.Q<Button>("settings-button");
        var quitButton = root.Q<Button>("quit-button");

        // Register callbacks
        playButton.clicked += OnPlayClicked;
        settingsButton.clicked += OnSettingsClicked;
        quitButton.clicked += Application.Quit;
    }

    void OnPlayClicked() {
        Debug.Log("Play clicked");
        // Load game scene
    }

    void OnSettingsClicked() {
        Debug.Log("Settings clicked");
        // Open settings menu
    }
}
```

---

### Common UI Elements
### 常见 UI 元素

```csharp
// Label (text display)
var label = root.Q<Label>("score-label");
label.text = "Score: 100";

// Button
var button = root.Q<Button>("submit-button");
button.clicked += OnSubmit;

// TextField (text input)
var textField = root.Q<TextField>("name-input");
string playerName = textField.value;

// Toggle (checkbox)
var toggle = root.Q<Toggle>("music-toggle");
bool isMusicEnabled = toggle.value;

// Slider
var slider = root.Q<Slider>("volume-slider");
float volume = slider.value; // 0-1

// DropdownField (dropdown menu)
var dropdown = root.Q<DropdownField>("difficulty-dropdown");
dropdown.choices = new List<string> { "Easy", "Normal", "Hard" };
dropdown.value = "Normal";
```

---

### Dynamic UI Creation (No UXML)
### 动态创建 UI（不使用 UXML）

```csharp
void CreateUI() {
    var root = GetComponent<UIDocument>().rootVisualElement;

    // Create elements
    var container = new VisualElement();
    container.AddToClassList("container");

    var label = new Label("Hello, UI Toolkit!");
    var button = new Button(() => Debug.Log("Clicked")) { text = "Click Me" };

    container.Add(label);
    container.Add(button);
    root.Add(container);
}
```

---

### USS Flexbox Layout
### USS Flexbox 布局

```css
/* Horizontal layout */
.horizontal {
    flex-direction: row;
}

/* Vertical layout (default) */
.vertical {
    flex-direction: column;
}

/* Center children */
.centered {
    align-items: center;
    justify-content: center;
}

/* Spacing */
.spaced {
    justify-content: space-between;
}
```

---

## UGUI (Legacy Canvas UI)
## UGUI（旧版 Canvas UI）

### Basic Setup (Still Works in Unity 6)
### 基本设置（在 Unity 6 中仍然可用）

```csharp
// GameObject > UI > Canvas (creates Canvas, EventSystem)

// UI Elements:
// - Text (use TextMeshPro instead)
// - Button
// - Image
// - Slider
// - Toggle
// - InputField
```

---

### UGUI Scripting
### UGUI 脚本

```csharp
using UnityEngine;
using UnityEngine.UI;
using TMPro; // TextMeshPro

public class LegacyUI : MonoBehaviour {
    public TextMeshProUGUI scoreText;
    public Button playButton;
    public Slider volumeSlider;

    void Start() {
        // Update text
        scoreText.text = "Score: 100";

        // Button click
        playButton.onClick.AddListener(OnPlayClicked);

        // Slider value changed
        volumeSlider.onValueChanged.AddListener(OnVolumeChanged);
    }

    void OnPlayClicked() {
        Debug.Log("Play clicked");
    }

    void OnVolumeChanged(float value) {
        AudioListener.volume = value;
    }
}
```

---

### TextMeshPro (Better Text Rendering)
### TextMeshPro（更好的文本渲染）

```csharp
// Install: Window > TextMeshPro > Import TMP Essential Resources

// Use TMP_Text instead of Unity's Text component
using TMPro;

public TextMeshProUGUI tmpText;
tmpText.text = "High Quality Text";
tmpText.fontSize = 24;
tmpText.color = Color.white;
```

---

## Canvas Settings (UGUI)
## Canvas 设置（UGUI）

### Render Modes
### 渲染模式

```csharp
// Screen Space - Overlay: UI rendered on top of everything (no camera needed)
// Screen Space - Camera: UI rendered by specific camera (allows effects)
// World Space: UI in 3D world (e.g., floating health bars)
```

### Canvas Scaler (Responsive UI)
### Canvas Scaler（响应式 UI）

```csharp
// UI Scale Mode:
// - Constant Pixel Size: UI elements have fixed pixel size
// - Scale With Screen Size: UI scales based on reference resolution (RECOMMENDED)
// - Constant Physical Size: UI elements have fixed physical size (cm)

// Example: Scale With Screen Size
// Reference Resolution: 1920x1080
// Screen Match Mode: Match Width Or Height (0.5 = balanced)
```

---

## Layout Groups (UGUI)
## 布局组（Layout Groups，UGUI）

### Horizontal Layout Group
### Horizontal Layout Group（水平布局组）

```csharp
// Auto-arranges children horizontally
// Add: GameObject > Add Component > Horizontal Layout Group
```

### Vertical Layout Group
### Vertical Layout Group（垂直布局组）

```csharp
// Auto-arranges children vertically
```

### Grid Layout Group
### Grid Layout Group（网格布局组）

```csharp
// Arranges children in a grid
```

---

## Performance (UI Toolkit vs UGUI)
## 性能（UI Toolkit 与 UGUI 对比）

### UI Toolkit Advantages
### UI Toolkit 的优势
- ✅ Faster rendering (retained mode)
- ✅ Better for complex UIs with many elements
- ✅ Easier styling (CSS-like)
- ✅ Better for dynamic UIs

- ✅ 渲染更快（保留模式，retained mode）
- ✅ 更适合元素众多的复杂 UI
- ✅ 样式更简单（类 CSS）
- ✅ 更适合动态 UI

### UGUI Advantages
### UGUI 的优势
- ✅ More mature, widely documented
- ✅ Better integration with Unity Editor
- ✅ Easier for beginners

- ✅ 更成熟，文档更丰富
- ✅ 与 Unity 编辑器集成更好
- ✅ 对初学者更友好

---

## Common Patterns
## 常见模式

### Health Bar (UI Toolkit)
### 血条（UI Toolkit）

```csharp
var healthBar = root.Q<VisualElement>("health-bar");
healthBar.style.width = new StyleLength(new Length(healthPercent, LengthUnit.Percent));
```

### Health Bar (UGUI)
### 血条（UGUI）

```csharp
public Image healthBarImage;

void UpdateHealth(float percent) {
    healthBarImage.fillAmount = percent; // 0-1
}
```

---

### Fade In/Out (UI Toolkit)
### 淡入/淡出（UI Toolkit）

```csharp
IEnumerator FadeIn(VisualElement element, float duration) {
    float elapsed = 0f;
    while (elapsed < duration) {
        elapsed += Time.deltaTime;
        element.style.opacity = Mathf.Lerp(0f, 1f, elapsed / duration);
        yield return null;
    }
}
```

---

## Debugging
## 调试

### UI Toolkit Debugger
### UI Toolkit 调试器
- `Window > UI Toolkit > Debugger`
- Inspect element hierarchy, styles, layout

- `Window > UI Toolkit > Debugger`
- 检视元素层级、样式、布局

### UGUI Event System Debugger
### UGUI 事件系统调试器
- Select EventSystem in Hierarchy
- Inspector shows active input module, raycast info

- 在 Hierarchy 中选择 EventSystem
- Inspector 会显示活动的输入模块、射线检测信息

---

## Sources
## 来源
- https://docs.unity3d.com/6000.0/Documentation/Manual/UIElements.html
- https://docs.unity3d.com/Packages/com.unity.ui@2.0/manual/index.html
- https://docs.unity3d.com/Packages/com.unity.ugui@2.0/manual/index.html
