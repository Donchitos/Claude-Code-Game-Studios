---
paths:
  - "Source/ui/**"
---

# UI Code Rules

- UI must NEVER own or directly modify game state — display only; request changes via commands / events / Gameplay Tag queries
- Event-driven, never polling: bind to delegates / `UAbilitySystemComponent` attribute change events; do not query state every Tick
- Follow CommonUI conventions: prefer `UCommonActivatableWidget` / `UCommonButton` / `UCommonLazyImage`; respect the activatable widget stack
- All user-facing text must go through the localization system (`FText` + NSLOCTEXT / LOCTABLE) — never raw `FString` displayed to players
- Support both keyboard/mouse AND gamepad navigation for every interactive element (CommonUI input routing)
- All UI animations must be skippable and respect accessibility/motion-reduction preferences
- UI must never block the game thread — heavy work dispatches to async tasks
- Scalable text and colorblind modes are mandatory, not optional; test at min and max supported resolutions
- 写 UE API 前先用 Context7 MCP（resolve-library-id + query-docs）查证,不得仅依赖训练数据

## Examples

**Correct** (event-driven CommonUI widget, no game state held):

```cpp
// Listens to a delegate — does NOT poll PlayerState every frame
void UCommonHealthWidget::NativeOnActivated()
{
    HealthComponent->OnHealthChanged.AddDynamic(this, &UCommonHealthWidget::HandleHealthChanged);
}

void UCommonHealthWidget::HandleHealthChanged(float NewHealth, float MaxHealth)
{
    HealthBar->SetPercent(NewHealth / MaxHealth); // display only
}
```

**Incorrect** (polls game state every frame):

```cpp
void UMyHealthWidget::NativeTick(const FGeometry& Geometry, float DeltaTime)
{
    Super::NativeTick(Geometry, DeltaTime);
    const float Hp = PlayerState->Health;          // VIOLATION: holds/reads game state directly
    HealthBar->SetPercent(Hp / 100.f);             // VIOLATION: hard-coded 100, polling UI
}
```
