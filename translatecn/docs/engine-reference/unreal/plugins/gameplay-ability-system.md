# Unreal Engine 5.8 — Gameplay Ability System (GAS)
# Unreal Engine 5.8 — Gameplay Ability System（GAS）

**Last verified:** 2026-10-17 (ability asset tags, re-confirmed against the 5.8 header); 2026-02-13 (rest of file, written against 5.7)
**Status:** Production-Ready
**Plugin:** `GameplayAbilities` (built-in, enable in Plugins)

**最后验证：** 2026-10-17（能力资产标签，已对照 5.8 头文件再次确认）；2026-02-13（文件其余部分，基于 5.7 编写）
**状态：** 生产就绪
**插件：** `GameplayAbilities`（内置，在 Plugins 中启用）

---

## Overview
## 概述

**Gameplay Ability System (GAS)** is a modular framework for building abilities, attributes,
effects, and gameplay mechanics. It's the standard for RPGs, MOBAs, shooters with abilities,
and any game with complex ability systems.

**Gameplay Ability System（GAS）** 是用于构建能力、属性、效果与玩法机制的模块化框架。它是 RPG、MOBA、带技能的射击游戏，以及任何拥有复杂能力系统的游戏的标准方案。

**Use GAS for:**
- Character abilities (spells, skills, attacks)
- Attributes (health, mana, stamina, stats)
- Buffs/debuffs (temporary effects)
- Cooldowns and costs
- Damage calculation
- Multiplayer-ready ability replication

**使用 GAS 的场景：**
- 角色能力（法术、技能、攻击）
- 属性（生命、法力、耐力、数值）
- 增益/减益（临时效果）
- 冷却与消耗
- 伤害计算
- 可直接用于多玩家的能力复制

---

## Core Concepts
## 核心概念

### 1. **Ability System Component** (ASC)
- The main component that owns abilities, attributes, and effects
- Added to Characters or PlayerStates

### 1. **Ability System Component**（ASC）
- 持有能力、属性与效果的主要组件
- 添加到 Character 或 PlayerState 上

### 2. **Gameplay Abilities**
- Individual skills/actions (fireball, heal, dash, etc.)
- Activated, committed (cost/cooldown), and can be cancelled

### 2. **Gameplay Abilities**
- 单个技能/动作（火球、治疗、冲刺等）
- 可激活、提交（消耗/冷却），也可被取消

### 3. **Attributes & Attribute Sets**
- Stats that can be modified (Health, Mana, Stamina, Strength, etc.)
- Stored in Attribute Sets

### 3. **Attributes & Attribute Sets**
- 可被修改的数值（Health、Mana、Stamina、Strength 等）
- 存储在 Attribute Set 中

### 4. **Gameplay Effects**
- Modify attributes (damage, healing, buffs, debuffs)
- Can be instant, duration-based, or infinite

### 4. **Gameplay Effects**
- 修改属性（伤害、治疗、增益、减益）
- 可以是瞬时、持续一段时间或无限持续

### 5. **Gameplay Tags**
- Hierarchical tags for ability logic (e.g., `Ability.Attack.Melee`, `Status.Stunned`)

### 5. **Gameplay Tags**
- 用于能力逻辑的层级标签（例如 `Ability.Attack.Melee`、`Status.Stunned`）

---

## Setup
## 设置

### 1. Enable Plugin
### 1. 启用插件

`Edit > Plugins > Gameplay Abilities > Enabled > Restart`

`Edit > Plugins > Gameplay Abilities > Enabled > Restart`

### 2. Add Ability System Component
### 2. 添加 Ability System Component

```cpp
#include "AbilitySystemComponent.h"
#include "AttributeSet.h"

UCLASS()
class AMyCharacter : public ACharacter {
    GENERATED_BODY()

public:
    AMyCharacter() {
        // Create ASC
        AbilitySystemComponent = CreateDefaultSubobject<UAbilitySystemComponent>(TEXT("AbilitySystem"));
        AbilitySystemComponent->SetIsReplicated(true);
        AbilitySystemComponent->SetReplicationMode(EGameplayEffectReplicationMode::Mixed);

        // Create Attribute Set
        AttributeSet = CreateDefaultSubobject<UMyAttributeSet>(TEXT("AttributeSet"));
    }

protected:
    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Abilities")
    TObjectPtr<UAbilitySystemComponent> AbilitySystemComponent;

    UPROPERTY()
    TObjectPtr<const UAttributeSet> AttributeSet;
};
```

### 3. Initialize ASC (Important for Multiplayer)
### 3. 初始化 ASC（对多玩家很重要）

```cpp
void AMyCharacter::PossessedBy(AController* NewController) {
    Super::PossessedBy(NewController);

    // Server: Initialize ASC
    if (AbilitySystemComponent) {
        AbilitySystemComponent->InitAbilityActorInfo(this, this);
        GiveDefaultAbilities();
    }
}

void AMyCharacter::OnRep_PlayerState() {
    Super::OnRep_PlayerState();

    // Client: Initialize ASC
    if (AbilitySystemComponent) {
        AbilitySystemComponent->InitAbilityActorInfo(this, this);
    }
}
```

---

## Attributes & Attribute Sets
## 属性与属性集

### Create Attribute Set
### 创建 Attribute Set

```cpp
#include "AttributeSet.h"
#include "AbilitySystemComponent.h"

UCLASS()
class UMyAttributeSet : public UAttributeSet {
    GENERATED_BODY()

public:
    UMyAttributeSet();

    // Health
    UPROPERTY(BlueprintReadOnly, Category = "Attributes", ReplicatedUsing = OnRep_Health)
    FGameplayAttributeData Health;
    ATTRIBUTE_ACCESSORS(UMyAttributeSet, Health)

    UPROPERTY(BlueprintReadOnly, Category = "Attributes", ReplicatedUsing = OnRep_MaxHealth)
    FGameplayAttributeData MaxHealth;
    ATTRIBUTE_ACCESSORS(UMyAttributeSet, MaxHealth)

    // Mana
    UPROPERTY(BlueprintReadOnly, Category = "Attributes", ReplicatedUsing = OnRep_Mana)
    FGameplayAttributeData Mana;
    ATTRIBUTE_ACCESSORS(UMyAttributeSet, Mana)

    virtual void GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const override;

protected:
    UFUNCTION()
    virtual void OnRep_Health(const FGameplayAttributeData& OldHealth);

    UFUNCTION()
    virtual void OnRep_MaxHealth(const FGameplayAttributeData& OldMaxHealth);

    UFUNCTION()
    virtual void OnRep_Mana(const FGameplayAttributeData& OldMana);
};
```

### Implement Attribute Set
### 实现 Attribute Set

```cpp
#include "Net/UnrealNetwork.h"

UMyAttributeSet::UMyAttributeSet() {
    // Default values
    Health = 100.0f;
    MaxHealth = 100.0f;
    Mana = 50.0f;
}

void UMyAttributeSet::GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const {
    Super::GetLifetimeReplicatedProps(OutLifetimeProps);

    DOREPLIFETIME_CONDITION_NOTIFY(UMyAttributeSet, Health, COND_None, REPNOTIFY_Always);
    DOREPLIFETIME_CONDITION_NOTIFY(UMyAttributeSet, MaxHealth, COND_None, REPNOTIFY_Always);
    DOREPLIFETIME_CONDITION_NOTIFY(UMyAttributeSet, Mana, COND_None, REPNOTIFY_Always);
}

void UMyAttributeSet::OnRep_Health(const FGameplayAttributeData& OldHealth) {
    GAMEPLAYATTRIBUTE_REPNOTIFY(UMyAttributeSet, Health, OldHealth);
}

// Implement other OnRep functions similarly...
```

### Clamping Attributes
### 钳制属性

Attribute Sets have no built-in clamping: the Data Table `Min Value` and
`Max Value` columns have no effect. Clamp in the Attribute Set:
- `PreAttributeChange()` is called just before any modification to an
  attribute, and is the hook for rules like
  `Health = Clamp(Health, 0, MaxHealth)` — its `NewValue` is mutable.
- `PreAttributeBaseChange()` is called just before a change to an attribute's
  **base** value when an aggregator exists, and `PostGameplayEffectExecute()`
  just after a Gameplay Effect is executed to modify the base value — clamp
  base-value changes from instant effects there.

Stacking rules govern re-applications of the same Gameplay Effect; they do not
bound one attribute pushed by different effects.

Attribute Set 没有内置钳制：Data Table 的 `Min Value` 与 `Max Value` 列不会生效。请在 Attribute Set 中进行钳制：
- `PreAttributeChange()` 在对属性做任何修改之前被调用，是诸如
  `Health = Clamp(Health, 0, MaxHealth)` 这类规则的钩子 — 其 `NewValue` 可变。
- 当存在聚合器时，`PreAttributeBaseChange()` 在属性**基础**值变更前被调用；`PostGameplayEffectExecute()` 在 Gameplay Effect 执行以修改基础值之后立即调用 — 请在此处钳制由瞬时效果引起的基础值变更。

堆叠规则管辖的是同一 Gameplay Effect 的重复施加；它们不会限制不同效果对同一属性造成的推高。

---

## Gameplay Abilities
## Gameplay Abilities

### Create Gameplay Ability
### 创建 Gameplay Ability

```cpp
#include "Abilities/GameplayAbility.h"

UCLASS()
class UGA_Fireball : public UGameplayAbility {
    GENERATED_BODY()

public:
    UGA_Fireball() {
        // Ability config
        InstancingPolicy = EGameplayAbilityInstancingPolicy::InstancedPerActor;
        NetExecutionPolicy = EGameplayAbilityNetExecutionPolicy::ServerInitiated;

        // Tags: the ability's own tags (asset tags, formerly AbilityTags).
        // Set them with SetAssetTags(), constructor only; read with GetAssetTags().
        FGameplayTagContainer Tags;
        Tags.AddTag(FGameplayTag::RequestGameplayTag(FName("Ability.Attack.Fireball")));
        SetAssetTags(Tags);
    }

    virtual void ActivateAbility(const FGameplayAbilitySpecHandle Handle, const FGameplayAbilityActorInfo* ActorInfo,
        const FGameplayAbilityActivationInfo ActivationInfo, const FGameplayEventData* TriggerEventData) override {

        if (!CommitAbility(Handle, ActorInfo, ActivationInfo)) {
            // Failed to commit (not enough mana, on cooldown, etc.)
            EndAbility(Handle, ActorInfo, ActivationInfo, true, true);
            return;
        }

        // Spawn fireball projectile
        SpawnFireball();

        // End ability
        EndAbility(Handle, ActorInfo, ActivationInfo, true, false);
    }

    void SpawnFireball() {
        // Spawn fireball logic
    }
};
```

### Grant Abilities to Character
### 向角色授予能力

```cpp
void AMyCharacter::GiveDefaultAbilities() {
    if (!HasAuthority() || !AbilitySystemComponent) return;

    // Grant abilities
    AbilitySystemComponent->GiveAbility(FGameplayAbilitySpec(UGA_Fireball::StaticClass(), 1, INDEX_NONE, this));
    AbilitySystemComponent->GiveAbility(FGameplayAbilitySpec(UGA_Heal::StaticClass(), 1, INDEX_NONE, this));
}
```

### Activate Ability
### 激活能力

```cpp
// Activate by class
AbilitySystemComponent->TryActivateAbilityByClass(UGA_Fireball::StaticClass());

// Activate by tag
FGameplayTagContainer TagContainer;
TagContainer.AddTag(FGameplayTag::RequestGameplayTag(FName("Ability.Attack.Fireball")));
AbilitySystemComponent->TryActivateAbilitiesByTag(TagContainer);
```

---

## Gameplay Effects
## Gameplay Effects

### Create Gameplay Effect (Damage)
### 创建 Gameplay Effect（伤害）

```cpp
// Create Blueprint: Content Browser > Gameplay > Gameplay Effect

// OR in C++:
UCLASS()
class UGE_Damage : public UGameplayEffect {
    GENERATED_BODY()

public:
    UGE_Damage() {
        // Instant damage
        DurationPolicy = EGameplayEffectDurationType::Instant;

        // Modifier: Reduce Health
        FGameplayModifierInfo ModifierInfo;
        ModifierInfo.Attribute = UMyAttributeSet::GetHealthAttribute();
        ModifierInfo.ModifierOp = EGameplayModOp::Additive;
        ModifierInfo.ModifierMagnitude = FScalableFloat(-25.0f); // -25 health

        Modifiers.Add(ModifierInfo);
    }
};
```

### Apply Gameplay Effect
### 应用 Gameplay Effect

```cpp
// Apply damage to target
if (UAbilitySystemComponent* TargetASC = UAbilitySystemBlueprintLibrary::GetAbilitySystemComponent(Target)) {
    FGameplayEffectContextHandle EffectContext = AbilitySystemComponent->MakeEffectContext();
    EffectContext.AddSourceObject(this);

    FGameplayEffectSpecHandle SpecHandle = AbilitySystemComponent->MakeOutgoingSpec(
        UGE_Damage::StaticClass(), 1, EffectContext);

    if (SpecHandle.IsValid()) {
        AbilitySystemComponent->ApplyGameplayEffectSpecToTarget(*SpecHandle.Data.Get(), TargetASC);
    }
}
```

---

## Gameplay Tags
## Gameplay Tags

### Define Tags
### 定义标签

`Project Settings > Project > Gameplay Tags > Gameplay Tag List`

`Project Settings > Project > Gameplay Tags > Gameplay Tag List`

Example hierarchy:
```
Ability
  ├─ Ability.Attack
  │   ├─ Ability.Attack.Melee
  │   └─ Ability.Attack.Ranged
  ├─ Ability.Defend
  └─ Ability.Utility

Status
  ├─ Status.Stunned
  ├─ Status.Invulnerable
  └─ Status.Silenced
```

示例层级：
```
Ability
  ├─ Ability.Attack
  │   ├─ Ability.Attack.Melee
  │   └─ Ability.Attack.Ranged
  ├─ Ability.Defend
  └─ Ability.Utility

Status
  ├─ Status.Stunned
  ├─ Status.Invulnerable
  └─ Status.Silenced
```

### Use Tags in Abilities
### 在能力中使用标签

```cpp
UCLASS()
class UGA_MeleeAttack : public UGameplayAbility {
    GENERATED_BODY()

public:
    UGA_MeleeAttack() {
        // This ability has these tags (asset tags; SetAssetTags() is constructor-only)
        FGameplayTagContainer Tags;
        Tags.AddTag(FGameplayTag::RequestGameplayTag(FName("Ability.Attack.Melee")));
        SetAssetTags(Tags);

        // Block these tags while active
        BlockAbilitiesWithTag.AddTag(FGameplayTag::RequestGameplayTag(FName("Ability.Attack")));

        // Cancel these abilities when activated
        CancelAbilitiesWithTag.AddTag(FGameplayTag::RequestGameplayTag(FName("Ability.Defend")));

        // Can't activate if target has these tags
        ActivationBlockedTags.AddTag(FGameplayTag::RequestGameplayTag(FName("Status.Stunned")));
    }
};
```

---

## Cooldowns & Costs
## 冷却与消耗

### Add Cooldown
### 添加冷却

```cpp
// In Ability Blueprint or C++:
// Create Gameplay Effect with Duration = Cooldown time
// Assign to Ability > Cooldown Gameplay Effect Class
```

### Add Cost (Mana)
### 添加消耗（法力）

```cpp
// Create Gameplay Effect that reduces Mana
// Assign to Ability > Cost Gameplay Effect Class
```

---

## Common Patterns
## 常见模式

### Get Current Attribute Value
### 获取当前属性值

```cpp
float CurrentHealth = AbilitySystemComponent->GetNumericAttribute(UMyAttributeSet::GetHealthAttribute());
```

### Listen for Attribute Changes
### 监听属性变更

```cpp
AbilitySystemComponent->GetGameplayAttributeValueChangeDelegate(UMyAttributeSet::GetHealthAttribute())
    .AddUObject(this, &AMyCharacter::OnHealthChanged);

void AMyCharacter::OnHealthChanged(const FOnAttributeChangeData& Data) {
    UE_LOG(LogTemp, Warning, TEXT("Health: %f"), Data.NewValue);
}
```

---

## Sources
## 来源

- https://docs.unrealengine.com/5.7/en-US/gameplay-ability-system-for-unreal-engine/
- Clamping: *Gameplay Attributes and Attribute Sets* https://dev.epicgames.com/documentation/en-us/unreal-engine/gameplay-attributes-and-attribute-sets-for-the-gameplay-ability-system-in-unreal-engine ; `UAttributeSet` API https://dev.epicgames.com/documentation/en-us/unreal-engine/API/Plugins/GameplayAbilities/UAttributeSet ; `PreAttributeChange` https://dev.epicgames.com/documentation/en-us/unreal-engine/API/Plugins/GameplayAbilities/UAttributeSet/PreAttributeChange
- Ability asset tags (`SetAssetTags()` / `GetAssetTags()`) — `UGameplayAbility` API, UE 5.7: https://dev.epicgames.com/documentation/en-us/unreal-engine/API/Plugins/GameplayAbilities/UGameplayAbility?application_version=5.7 ; `SetAssetTags`: https://dev.epicgames.com/documentation/en-us/unreal-engine/API/Plugins/GameplayAbilities/UGameplayAbility/SetAssetTags?application_version=5.7 . The 5.7 reference lists `SetAssetTags(const FGameplayTagContainer&)` as protected, "formerly AbilityTags", callable "only ... during construction"; `GetAssetTags()` as the public read; and `AbilityTags` as a public variable "exposed for backwards compatibility" (no deprecation note on the page). Re-confirmed for UE 5.8 on 2026-10-17 against `Engine/Plugins/Runtime/GameplayAbilities/Source/GameplayAbilities/Public/Abilities/GameplayAbility.h` (5.8.1 install): `GetAssetTags()` public, `SetAssetTags(const FGameplayTagContainer&)` protected ("This can only be called during construction"), and `AbilityTags` still a public `UPROPERTY`, marked `UE_DEPRECATED_FORGAME(5.5, "Use GetAssetTags(). This is being made non-mutable, private and renamed to AssetTags in the future. Use SetAssetTags to set defaults (in constructor only).")` — so game code that touches `AbilityTags` directly gets a deprecation warning. 5.8 API page: https://dev.epicgames.com/documentation/en-us/unreal-engine/API/Plugins/GameplayAbilities/UGameplayAbility/SetAssetTags?application_version=5.8 . Also deprecated in 5.8: the `FActiveGameplayEffectHandle(int32)` constructor (use `GenerateNewHandle` or `GetInstantExecutedHandle()`; `.../Public/ActiveGameplayEffectHandle.h`).
- https://github.com/tranek/GASDocumentation (community guide)

- https://docs.unrealengine.com/5.7/en-US/gameplay-ability-system-for-unreal-engine/
- 钳制：*Gameplay Attributes and Attribute Sets* https://dev.epicgames.com/documentation/en-us/unreal-engine/gameplay-attributes-and-attribute-sets-for-the-gameplay-ability-system-in-unreal-engine ；`UAttributeSet` API https://dev.epicgames.com/documentation/en-us/unreal-engine/API/Plugins/GameplayAbilities/UAttributeSet ；`PreAttributeChange` https://dev.epicgames.com/documentation/en-us/unreal-engine/API/Plugins/GameplayAbilities/UAttributeSet/PreAttributeChange
- 能力资产标签（`SetAssetTags()` / `GetAssetTags()`）— `UGameplayAbility` API，UE 5.7：https://dev.epicgames.com/documentation/en-us/unreal-engine/API/Plugins/GameplayAbilities/UGameplayAbility?application_version=5.7 ；`SetAssetTags`：https://dev.epicgames.com/documentation/en-us/unreal-engine/API/Plugins/GameplayAbilities/UGameplayAbility/SetAssetTags?application_version=5.7 。5.7 参考将 `SetAssetTags(const FGameplayTagContainer&)` 列为 protected，"formerly AbilityTags"，只能在"构造期间"调用；`GetAssetTags()` 为公开读取；`AbilityTags` 是"为向后兼容而暴露"的公开变量（该页无弃用说明）。已于 2026-10-17 对照 `Engine/Plugins/Runtime/GameplayAbilities/Source/GameplayAbilities/Public/Abilities/GameplayAbility.h`（5.8.1 安装）为 UE 5.8 再次确认：`GetAssetTags()` 为公开，`SetAssetTags(const FGameplayTagContainer&)` 为 protected（"This can only be called during construction"），`AbilityTags` 仍是公开的 `UPROPERTY`，标记为 `UE_DEPRECATED_FORGAME(5.5, "Use GetAssetTags(). This is being made non-mutable, private and renamed to AssetTags in the future. Use SetAssetTags to set defaults (in constructor only).")` — 因此直接访问 `AbilityTags` 的游戏代码会产生弃用警告。5.8 API 页面：https://dev.epicgames.com/documentation/en-us/unreal-engine/API/Plugins/GameplayAbilities/UGameplayAbility/SetAssetTags?application_version=5.8 。5.8 中还弃用了：`FActiveGameplayEffectHandle(int32)` 构造函数（请使用 `GenerateNewHandle` 或 `GetInstantExecutedHandle()`；`.../Public/ActiveGameplayEffectHandle.h`）。
- https://github.com/tranek/GASDocumentation（社区指南）
