---
paths:
  - "Source/ai/**"
---

# AI Code Rules

- Separate behavior execution (Behavior Tree / StateTree) from decision data — never hard-code `if/else` decision chains in C++
- Decouple perception (`UAIPerceptionComponent` / AI Sense) from decision-making — perception only emits events, decision only consumes them
- All AI parameters (BT weights, perception ranges, timers) MUST be tunable from data assets
- AI must be debuggable: implement visualization hooks (EQS paths, perception cones, current state) viewable in the editor
- AI should telegraph intentions — give players time to read and react before commitment
- AI update budget: define and track per-frame cost; profile with Unreal Insights before shipping
- Group AI must support formation, flanking, and role assignment driven by data, not by class hierarchy
- Never trust AI input received over the network without server-side validation
- 写 UE API 前先用 Context7 MCP（resolve-library-id + query-docs）查证,不得仅依赖训练数据

## Examples

**Correct** (perception emits event, BT decides):

```cpp
// Perception component only fires an event — it holds no decision logic
void UMyAIPerceptionComponent::OnTargetPerceived(AActor* Target)
{
    OnTargetPerceivedEvent.Broadcast(Target); // decision made by BehaviorTree / StateTree
}
```

**Incorrect** (decision logic embedded in perception):

```cpp
void UMyAIPerceptionComponent::OnTargetPerceived(AActor* Target)
{
    if (Target->GetDistanceTo(GetOwner()) < 300.0f) // VIOLATION: hardcoded range
    {
        GetOwner()->FindComponentByClass<UWeaponComponent>()->Fire(); // VIOLATION: decision in perception
    }
}
```
