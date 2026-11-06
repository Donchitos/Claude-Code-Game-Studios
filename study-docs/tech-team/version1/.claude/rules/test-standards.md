---
paths:
  - "tests/**"
---

# Test Standards

- Test naming follows `Test_[System]_[Scenario]_[ExpectedResult]` (UE Automation: `Namespace.System.Scenario.Expected`)
- Every test must have a clear Arrange / Act / Assert (AAA) structure
- NO random seeds without explicit seeding — tests must be deterministic and reproducible
- NO time-of-day / wall-clock dependence — inject a controllable time source, never call `FDateTime::Now()` in assertions
- NO external I/O (filesystem, network, live online services) in unit tests — mock or use in-memory fixtures
- Integration tests must clean up after themselves (restore world / actors / spawned state)
- Performance tests must specify acceptable thresholds and fail if exceeded
- Test data must be defined in the test or dedicated fixtures — never shared mutable state
- Every bug fix must ship a regression test that would have caught the original bug
- 写 UE API 前先用 Context7 MCP（resolve-library-id + query-docs）查证,不得仅依赖训练数据

## Examples

**Correct** (descriptive name + Arrange/Act/Assert):

```cpp
IMPLEMENT_SIMPLE_AUTOMATION_TEST(
    FHealthTakeDamageTest,
    "Gameplay.Health.TakeDamage.ReducesHealth",
    EAutomationTestFlags::ApplicationContextMask | EAutomationTestFlags::ProductFilter)

bool FHealthTakeDamageTest::RunTest(const FString& Parameters)
{
    // Arrange
    UHealthComponent* Health = NewObject<UHealthComponent>();
    Health->SetMaxHealth(100.f);
    Health->SetCurrentHealth(100.f);

    // Act
    Health->TakeDamage(25.f);

    // Assert
    TestEqual(TEXT("Health reduced by damage"), Health->GetCurrentHealth(), 75.f);
    return true;
}
```

**Incorrect**:

```cpp
IMPLEMENT_SIMPLE_AUTOMATION_TEST(FTest1, "Gameplay.Test1", EAutomationTestFlags::ProductFilter)

bool FTest1::RunTest(const FString& Parameters)
{
    UHealthComponent* H = NewObject<UHealthComponent>(); // VIOLATION: no arrange (uninitialized)
    H->TakeDamage(25.f);                                 // VIOLATION: no clear state setup
    TestTrue(TEXT("ok"), H->GetCurrentHealth() < 100.f); // VIOLATION: imprecise assertion
    return true;
}
```
