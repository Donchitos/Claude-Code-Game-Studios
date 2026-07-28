# Systems Index: PetQuest

> **Status**: Draft
> **Created**: 2026-06-26
> **Last Updated**: 2026-06-26
> **Source Concept**: design/gdd/game-concept.md

---

## Overview

PetQuest là mobile game nuôi thú ảo nơi năng lượng của thú cưng (Mochi) đến từ
hành động thực tế của bé ngoài đời — làm bài tập, giúp việc nhà, luyện đàn.
Core loop: **Task submit → Hạt Giống (instant) → Parent approve → Xu + Gacha →
Shop → Pet dressed up → Mochi happy → Social flex**. Hệ thống chia làm 5 nhóm
chính: pet care (Flame visuals), task/reward pipeline (Flutter UI + Firebase),
economy (currency + shop + gacha), social (Phase 2), và infrastructure (auth,
persistence, state bridge). Kiến trúc Flutter + Flame đòi hỏi một State Bridge
đặc biệt để đồng bộ Flutter state management với Flame game loop — đây là
bottleneck kỹ thuật rủi ro cao nhất của toàn project.

---

## Systems Enumeration

| # | System Name | Category | Priority | Status | Design Doc | Depends On |
|---|-------------|----------|----------|--------|------------|------------|
| 1 | Auth & Account | Core | MVP | Approved | design/gdd/auth-account.md | — |
| 2 | Time & Decay | Gameplay | MVP | Approved | design/gdd/time-decay.md | — |
| 3 | Item Database | Economy | MVP | Approved | design/gdd/item-database.md | — |
| 4 | Data Persistence Layer | Core | MVP | Approved | design/gdd/data-persistence-layer.md | Auth & Account |
| 5 | Flutter-Flame State Bridge | Core | MVP | Approved | design/gdd/flutter-flame-state-bridge.md | Auth & Account |
| 6 | Pet State Machine | Gameplay | MVP | Approved | design/gdd/pet-state-machine.md | Time & Decay, Data Persistence |
| 7 | Currency System | Economy | MVP | Approved | design/gdd/currency-system.md | Auth & Account, Data Persistence |
| 8 | Task Library | Gameplay | MVP | Approved | design/gdd/task-library.md | Auth & Account, Data Persistence |
| 9 | Push Notification System | Core | MVP | Approved | design/gdd/push-notification.md | Auth & Account, Data Persistence, Task Library |
| 10 | Seed Buffer Mechanic | Gameplay | MVP | Approved | design/gdd/seed-buffer.md | Task Library, Pet State Machine |
| 11 | Parent Approval System | Gameplay | MVP | Approved | design/gdd/parent-approval.md | Seed Buffer, Push Notification, Currency |
| 12 | Gacha / Loot System | Economy | MVP | Approved | design/gdd/gacha-loot.md | Item Database, Currency, Shop System |
| 13 | Shop System | Economy | MVP | Approved | design/gdd/shop-system.md | Item Database, Currency, Gacha/Loot |
| 14 | Pet Interaction System | Gameplay | MVP | Approved | design/gdd/pet-interaction.md | Pet State Machine, Flutter-Flame Bridge |
| 15 | Pet Equipment System | Economy | MVP | Approved | design/gdd/pet-equipment.md | Item Database, Pet State Machine, Shop System |
| 16 | Pet Leveling & Evolution | Progression | MVP | Approved | design/gdd/pet-leveling-evolution.md | Pet State Machine, Currency |
| 17 | Main Navigation Shell | UI | MVP | Approved | design/gdd/main-navigation-shell.md | Auth & Account, Currency System |
| 18 | Pet Room Screen UI | UI | MVP | Approved | design/gdd/pet-room-screen-ui.md | Pet State Machine, Pet Equipment, Pet Interaction, Pet Leveling, Flutter-Flame Bridge, Item Database, Main Navigation Shell |
| 19 | Task Management UI | UI | MVP | Approved | design/gdd/task-management-ui.md | Task Library, Seed Buffer, Main Navigation Shell, Parent Dashboard UI |
| 20 | Shop & Reward UI | UI | MVP | Approved | design/gdd/shop-reward-ui.md | Shop System, Gacha/Loot System, Currency System, Pet Equipment, Main Navigation Shell |
| 21 | Parent Dashboard UI | UI | MVP | Approved | design/gdd/parent-dashboard-ui.md | Parent Approval System, Task Library, Auth & Account, Push Notification, Main Navigation Shell |
| 22 | Background Music System | Audio | Vertical Slice | Not Started | — | — |
| 23 | SFX System | Audio | Vertical Slice | Not Started | — | — |
| 24 | Onboarding Flow | Meta | Vertical Slice | Not Started | — | Auth, Task Library, Pet State Machine, Shop |
| 25 | Settings & Preferences | Meta | Vertical Slice | Not Started | — | Auth & Account |
| 26 | Friend & Neighbor System | Social | Alpha | Not Started | — | Auth & Account, Data Persistence |
| 27 | Decoration Database | Economy | Alpha | Not Started | — | — |
| 28 | Room Layout System | Economy | Alpha | Not Started | — | Decoration Database, Data Persistence |
| 29 | Visit System | Social | Alpha | Not Started | — | Friend & Neighbor, Room Layout |
| 30 | Gift System | Social | Alpha | Not Started | — | Friend & Neighbor, Currency |
| 31 | Leaderboard System | Social | Alpha | Not Started | — | Friend & Neighbor, Pet Leveling |
| 32 | Analytics System | Meta | Full Vision | Not Started | — | All |

---

## Categories

| Category | Description | Systems in PetQuest |
|----------|-------------|---------------------|
| **Core** | Foundation systems everything depends on | Auth, Data Persistence, Flutter-Flame Bridge, Push Notification |
| **Gameplay** | Systems that drive the core loop | Task Library, Seed Buffer, Parent Approval, Pet State Machine, Time & Decay, Pet Interaction |
| **Progression** | How pet and bé grow over time | Pet Leveling & Evolution |
| **Economy** | Resource creation and consumption | Currency, Item DB, Gacha, Shop, Pet Equipment, Decoration DB, Room Layout |
| **Social** | Neighbor and friend interactions (Phase 2) | Friend & Neighbor, Visit, Gift, Leaderboard |
| **UI** | Player-facing screens | Navigation Shell, Pet Room, Task Management, Shop & Reward, Parent Dashboard |
| **Audio** | Sound and music | Background Music, SFX |
| **Meta** | Outside core loop | Onboarding, Settings, Analytics |

---

## Priority Tiers

| Tier | Definition | Target Milestone | Systems Count |
|------|------------|-----------------|---------------|
| **MVP** | Core loop must function end-to-end: bé submit task → bố mẹ approve → Mochi thay đổi | Month 1–3 build | 21 |
| **Vertical Slice** | Full polished experience: audio + onboarding complete | Demo-ready | 4 |
| **Alpha** | Social layer open — Phase 2 neighborhood features | Month 4–6 | 6 |
| **Full Vision** | Analytics, polish, edge cases | Beta/Release | 1 |

---

## Dependency Map

### Foundation Layer (no dependencies)

1. **Auth & Account** — identity của mọi user, family unit; mọi thứ cần biết "ai đang dùng"
2. **Item Database** — pure data catalog; không cần runtime system nào
3. **Time & Decay** — chỉ cần `DateTime.now()`; độc lập hoàn toàn
4. **Background Music System** — standalone audio player
5. **SFX System** — standalone audio player
6. **Decoration Database** — pure data catalog (Phase 2)

### Core Layer (depends on Foundation)

1. **Data Persistence Layer** — depends on: Auth & Account — Firebase Firestore với offline-first caching
2. **Flutter-Flame State Bridge** — depends on: Auth & Account — bridge Riverpod/Bloc state sang Flame game loop events
3. **Currency System** — depends on: Auth & Account, Data Persistence — xu balance per user, persisted
4. **Pet State Machine** — depends on: Time & Decay, Data Persistence — 5 emotional states + energy model
5. **Task Library** — depends on: Auth & Account, Data Persistence — task catalog + custom tasks per family
6. **Push Notification System** — depends on: Auth & Account, Data Persistence — FCM delivery cho parent approval alerts

### Feature Layer (depends on Core)

1. **Seed Buffer Mechanic** — depends on: Task Library, Pet State Machine — hạt giống chờ duyệt, instant visual feedback
2. **Parent Approval System** — depends on: Seed Buffer, Push Notification, Currency — approve flow → trigger xu + gacha
3. **Gacha / Loot System** — depends on: Item Database, Currency — weighted random tables, chest opening
4. **Shop System** — depends on: Item Database, Currency, Gacha/Loot — browse + purchase + progress bar
5. **Pet Interaction System** — depends on: Pet State Machine, Flutter-Flame Bridge — tap/vuốt triggers Flame animations
6. **Pet Equipment System** — depends on: Item Database, Pet State Machine — outfit slots, visual overlay
7. **Pet Leveling & Evolution** — depends on: Pet State Machine, Currency — energy → level up → new visual forms
8. **Friend & Neighbor System** — depends on: Auth & Account, Data Persistence (Phase 2)

### Presentation Layer (depends on Features)

1. **Main Navigation Shell** — depends on: Auth & Account — tabs, top bar, wallet display
2. **Pet Room Screen UI** — depends on: Pet State Machine, Pet Equipment, Pet Interaction — màn hình chính của bé
3. **Task Management UI** — depends on: Task Library, Seed Buffer — flavor text quests, submission flow
4. **Shop & Reward UI** — depends on: Shop, Gacha/Loot, Currency — shop grid, gacha animation, progress bar
5. **Parent Dashboard UI** — depends on: Parent Approval System — approval cards ≤10 giây
6. **Room Layout System** — depends on: Decoration Database, Data Persistence (Phase 2)
7. **Visit System** — depends on: Friend & Neighbor, Room Layout (Phase 2)
8. **Gift System** — depends on: Friend & Neighbor, Currency (Phase 2)
9. **Leaderboard System** — depends on: Friend & Neighbor, Pet Leveling (Phase 2)

### Polish Layer (depends on everything)

1. **Onboarding Flow** — depends on: Auth, Task Library, Pet State Machine, Shop — first-run tutorial
2. **Settings & Preferences** — depends on: Auth & Account — notification prefs, account management
3. **Analytics System** — depends on: All (Full Vision)

---

## Circular Dependencies

- **None found.** Chain dài nhất tuyến tính: `Task Library → Seed Buffer → Parent Approval → Currency → Shop → Pet Equipment → Pet State Machine → Pet Room Screen UI`

---

## High-Risk Systems

| System | Risk Type | Risk Description | Mitigation |
|--------|-----------|-----------------|------------|
| **Flutter-Flame State Bridge** | Technical | Kiến trúc Flutter↔Flame boundary chưa được validate — nếu sai thì debug rất khó và ảnh hưởng mọi visual reaction | Spike prototype trước khi GDD; tham khảo `docs/engine-reference/flutter-flame/current-best-practices.md` |
| **Auth & Account** | Scope | 10+ systems phụ thuộc — schema thay đổi = cascade toàn bộ | Lock schema sớm, design GDD đầu tiên, đừng refactor sau |
| **Pet State Machine** | Design | 5 dependents; state transitions sai → pet "bị đơ" hoặc mood không phản ánh effort thật | Validate với Time & Decay rules trước khi implement; cross-reference prototype REPORT |
| **Time & Decay System** | Design | Nếu decay rate không cân bằng: decay quá nhanh → bé lo lắng (anti-pillar); quá chậm → mất urgency hook | Balance test với nhiều "absence scenarios" (1 ngày, 2 ngày, 1 tuần) |
| **Gacha / Loot System** | Design | Economy leak: tỷ lệ drop rate sai → bé hết mục tiêu sau 2 tuần hoặc không bao giờ kiếm đủ | Design loot table cẩn thận; model với spreadsheet trước khi implement |
| **Data Persistence Layer** | Technical | Firebase offline persistence + Firestore rules phức tạp với child/parent dual account | Nghiên cứu Firebase security rules cho family unit pattern sớm |

---

## Recommended Design Order

| Order | System | Priority | Layer | Agent | Est. Effort |
|-------|--------|----------|-------|-------|-------------|
| 1 | Auth & Account | MVP | Foundation | game-designer + lead-programmer | M |
| 2 | Time & Decay | MVP | Foundation | game-designer | S |
| 3 | Item Database | MVP | Foundation | systems-designer | M |
| 4 | Data Persistence Layer | MVP | Core | lead-programmer | M |
| 5 | Flutter-Flame State Bridge | MVP | Core | lead-programmer | **L** ⚠️ |
| 6 | Pet State Machine | MVP | Core | game-designer | M |
| 7 | Currency System | MVP | Core | systems-designer | S |
| 8 | Task Library | MVP | Core | game-designer | M |
| 9 | Push Notification System | MVP | Core | lead-programmer | S |
| 10 | Seed Buffer Mechanic | MVP | Feature | game-designer | S |
| 11 | Parent Approval System | MVP | Feature | game-designer | M |
| 12 | Gacha / Loot System | MVP | Feature | systems-designer | S |
| 13 | Shop System | MVP | Feature | systems-designer | M |
| 14 | Pet Interaction System | MVP | Feature | game-designer + lead-programmer | M |
| 15 | Pet Equipment System | MVP | Feature | systems-designer | S |
| 16 | Pet Leveling & Evolution | MVP | Feature | systems-designer | M |
| 17 | Main Navigation Shell | MVP | Presentation | ux-designer | S |
| 18 | Pet Room Screen UI | MVP | Presentation | ux-designer | L |
| 19 | Task Management UI | MVP | Presentation | ux-designer | M |
| 20 | Shop & Reward UI | MVP | Presentation | ux-designer | M |
| 21 | Parent Dashboard UI | MVP | Presentation | ux-designer | M |
| 22 | Background Music System | Vertical Slice | Foundation | — | M |
| 23 | SFX System | Vertical Slice | Foundation | — | M |
| 24 | Onboarding Flow | Vertical Slice | Polish | ux-designer | M |
| 25 | Settings & Preferences | Vertical Slice | Polish | ux-designer | M |
| 26 | Friend & Neighbor System | Alpha | Core | game-designer | M |
| 27 | Decoration Database | Alpha | Foundation | systems-designer | M |
| 28 | Room Layout System | Alpha | Presentation | ux-designer | M |
| 29 | Visit System | Alpha | Presentation | game-designer | M |
| 30 | Gift System | Alpha | Presentation | game-designer | M |
| 31 | Leaderboard System | Alpha | Presentation | game-designer | M |
| 32 | Analytics System | Full Vision | Polish | — | M |

> S = 1 session (~1–2 giờ), M = 2–3 sessions, L = 4+ sessions

---

## Progress Tracker

| Metric | Count |
|--------|-------|
| Total systems identified | 32 |
| Design docs started | 21 |
| Design docs reviewed | 21 |
| Design docs approved | 21 (3 GDD-revision flags from /architecture-review 2026-07-11 resolved 2026-07-13 — time-decay.md, data-persistence-layer.md, flutter-flame-state-bridge.md all re-synced to their governing ADRs and restored to Approved) |
| MVP systems designed | 21 / 21 |
| Vertical Slice systems designed | 0 / 4 |
| Alpha systems designed | 0 / 6 |
| Full Vision systems designed | 0 / 1 |

---

## Next Steps

- [ ] Review và approve systems enumeration này
- [ ] Design MVP Foundation systems (Auth & Account → Time & Decay → Item Database)
- [ ] **⚠️ Spike Flutter-Flame State Bridge trước khi GDD** — validate kiến trúc Riverpod↔Flame
- [ ] Run `/design-system auth-account` để bắt đầu
- [ ] Run `/design-review` trên mỗi GDD hoàn thành
- [ ] Run `/gate-check pre-production` khi tất cả MVP systems đã được design
