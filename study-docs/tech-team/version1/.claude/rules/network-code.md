---
paths:
  - "Source/network/**"
---

# Network Code Rules

- Server is AUTHORITATIVE for all gameplay-critical state — never trust client input
- Client predicts locally and reconciles with the server — implement rollback/correction for mispredictions
- Minimum replication: only replicate what players can perceive; use `DOREPLIFETIME` conditions (`COND_OwnerOnly`, `COND_SimulatedOnly`, relevance) to cut bandwidth
- All RPCs must specify reliability deliberately — `Server` RPCs reliable only when state-critical, `Client` RPCs unreliable for cosmetic feedback
- All networked values must declare replication strategy (reliable/unreliable, frequency, interpolation)
- Network messages must be versioned for forward/backward compatibility (network version handshake)
- Handle disconnection, reconnection, and host migration gracefully — no soft-locks on reconnect
- Validate all incoming packet sizes and field ranges server-side; reject malformed packets
- 写 UE API 前先用 Context7 MCP（resolve-library-id + query-docs）查证,不得仅依赖训练数据

## Examples

**Correct** (server-authoritative damage RPC):

```cpp
// Client requests, server validates and applies — client never mutates health directly
UFUNCTION(Server, Reliable, WithValidation)
void Server_RequestDealDamage(AActor* Target, float Damage);

bool AMyCharacter::Server_RequestDealDamage_Validate(AActor* Target, float Damage)
{
    return Target != nullptr && Damage > 0.f && CanAttack(Target); // server-side sanity
}
```

**Incorrect** (client trusted):

```cpp
void AMyCharacter::ClientDealDamage(AActor* Target, float Damage)
{
    Target->TakeDamage(Damage, FDamageEvent(), nullptr, this); // VIOLATION: client mutates authoritative state
}
```
