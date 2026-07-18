# Data Persistence Layer

> **Status**: Approved ✅
> **Author**: User + Agents
> **Last Updated**: 2026-07-04
> **Implements Pillar**: Pillar 1 — Kỷ Luật Thật → Phần Thưởng Thật (every real-world action must be durably recorded — no effort lost)

## Overview

Data Persistence Layer là module quản lý toàn bộ việc đọc/ghi dữ liệu game vào Firebase Firestore. Nó sử dụng **offline-first strategy**: mọi write được commit vào local Firestore cache ngay lập tức — bé submit task, mua item, hay Mochi đổi outfit đều được ghi tức thì dù không có mạng. Firebase SDK tự động sync lên cloud khi kết nối được khôi phục.

System này định nghĩa **Firestore schema hoàn chỉnh** của PetQuest — tất cả paths, collections, và document structures. Mọi system khác đọc/ghi data đều phải đi qua contract được định nghĩa ở đây, không tự tạo Firestore paths riêng.

**Tại sao critical**: Nếu bé làm bài xong và submit task nhưng app crash hoặc mất mạng trước khi data được lưu — effort của bé bị mất. Đây là vi phạm Pillar 1 nghiêm trọng nhất có thể xảy ra. Offline persistence ngăn chặn điều này hoàn toàn.

## Player Fantasy

Người chơi không thấy Data Persistence — họ thấy kết quả của nó:

**Bé**: Submit task lúc 4h chiều khi đang ở vùng sóng yếu → Hạt giống rơi vào túi ngay lập tức. Bố mẹ về nhà 7h tối, approve → xu xuất hiện. Không có gì bị mất. Effort của bé được ghi nhận dù điều kiện kỹ thuật như thế nào.

**Bố mẹ**: Approve task trên điện thoại → khi bé mở app (dù offline ngay lúc đó), Mochi đã nhảy vui rồi. Không bao giờ có tình huống "bố approve rồi nhưng game không thấy".

Persistence tốt = game cảm thấy **đáng tin cậy**. Bé tin rằng nỗ lực của mình luôn được ghi nhận.

## Detailed Design

### Core Rules

**1. Firestore Initialization**

> ⚠️ **Sửa 2026-07-13** (ADR-0003 Correction note, xác nhận qua `/vertical-slice`): bản `cloud_firestore` 6.6.0 thực tế **không có** API `cacheSettings`/`PersistentCacheSettings` — cặp `persistenceEnabled`/`cacheSizeBytes` mới là API đúng cho version này. Xem lại đúng version production trước khi implement.

```dart
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```
Khởi tạo một lần trong `main()` trước khi app chạy. Mọi Firestore operation sau đó đều offline-capable. (`Settings.CACHE_SIZE_UNLIMITED` vẫn là hằng số đúng; fallback 50MB = `cacheSizeBytes: 50 * 1024 * 1024`.)

**2. Complete Firestore Schema**
```
families/{parentId}
  ├── email: String
  ├── displayName: String
  ├── fcmToken: String
  └── createdAt: Timestamp

families/{parentId}/children/{childId}
  ├── name: String
  ├── avatarId: String
  ├── mochiName: String
  ├── xuBalance: int            (owned by Currency System)
  ├── seedCount: int            (owned by Seed Buffer)
  ├── chestCount: int           (owned by Gacha/Loot System)
  ├── approvedTaskCount: int    (owned by Gacha/Loot System — free chest milestone tracker)
  ├── storedEnergy: float       (owned by Time & Decay)
  ├── lastApprovedAt: Timestamp (owned by Time & Decay)
  ├── petLevel: int             (owned by Pet Leveling)
  ├── totalXuEarned: int        (owned by Pet Leveling — lifetime xu counter, never decrements)
  ├── nextLevelThreshold: int   (owned by Pet Leveling — derived/cached from petLevel, see Pet Leveling GDD Formulas)
  ├── equippedItems: Map<String, String>  (slotId → itemId)
  └── createdAt: Timestamp

families/{parentId}/children/{childId}/private/credentials   (owned by Auth & Account — ADR-0002 §7 / ADR-0003)
  ├── pinHash: String           (PBKDF2-HMAC-SHA256 output)
  └── pinSalt: String           (16-byte random hex salt)
  Ghi chú: pinHash/pinSalt tách khỏi document children/{childId} (dùng render profile-selection list)
  để PIN material KHÔNG bị kéo vào working set mỗi khi list render. Chỉ get() lúc nhập PIN, không stream.

families/{parentId}/children/{childId}/tasks/{taskId}
  ├── title: String
  ├── flavorText: String
  ├── categoryId: String
  ├── status: String            ('pending' | 'approved' | 'rejected')
  ├── xuReward: int
  ├── energyReward: float
  ├── submittedAt: Timestamp
  ├── approvedAt: Timestamp     (null nếu chưa approve)
  └── rejectedAt: Timestamp     (null nếu chưa reject — owned by Parent Approval #11, field riêng biệt với approvedAt)

families/{parentId}/customTasks/{customTaskId}   (owned by Parent Dashboard UI #21 — family-scoped, KHÔNG child-scoped vì bố mẹ chọn targetChildId khi tạo)
  ├── title: String
  ├── categoryId: String        (1 trong 5 category có sẵn — không phải 'custom' tag)
  ├── targetChildId: String
  └── createdAt: Timestamp
  Ghi chú: đây là TEMPLATE, không phải task instance — không có status/xuReward/energyReward.
  Xuất hiện như picker option thêm trong Task Management UI (#19); khi bé chọn và submit,
  một tasks/{taskId} document thật được tạo (copy title/categoryId, tính reward từ category table).

families/{parentId}/children/{childId}/inventory/{itemId}
  ├── itemId: String
  ├── acquiredAt: Timestamp
  └── source: String            ('shop' | 'gacha')
```

**3. Write Rules**
- Mọi write dùng `set()` với `merge: true` hoặc `update()` — không dùng `add()` cho documents có predictable ID
- Task documents dùng auto-generated ID (`collection.doc()`)
- Inventory items dùng `itemId` làm document ID (idempotent — mua lại không tạo duplicate)

**4. Read Rules**
- Child profile data **của bé đang active** (`activeChildProvider`, sau khi đã chọn hồ sơ): dùng `snapshots()` stream (realtime) — Riverpod `StreamProvider`
  > **Làm rõ 2026-07-15** (Story 005, cross-ref ADR-0003's amendment note cùng ngày): rule này chỉ áp dụng cho 1 bé đang active, KHÔNG áp dụng cho danh sách chọn hồ sơ (profile-selection list, tối đa 4 bé) — màn đó dùng `get()` một lần (`childProfilesProvider`), cùng nhóm ngoại lệ với Item catalog bên dưới, vì không cần realtime (thêm bé chỉ xảy ra từ Parent Dashboard, session state khác hẳn màn chọn hồ sơ).
- Task list: dùng `snapshots()` với query `where('status', isEqualTo: 'pending')`
- Item catalog: dùng `get()` one-time (static data, không cần realtime)

---

### States and Transitions

| Operation | Method | Offline behavior |
|-----------|--------|-----------------|
| Submit task | `tasks.doc().set(...)` | Write to cache → sync khi online |
| Approve task | `WriteBatch`: `FieldValue.increment()` on xuBalance + storedEnergy; set status/timestamps | Write to cache → sync |
| Buy item | `WriteBatch`: `FieldValue.increment(-price)` on xuBalance; `inventory/{itemId}.set(...)` | Batched write — atomic |
| Equip item | `children/{id}.update({equippedItems})` | Write to cache |

**Batched writes** (atomic — cả hai thành công hoặc cả hai fail):
- Approve task → update `xuBalance` + `storedEnergy` + `lastApprovedAt` + task `status` = 1 batch
- Buy item → update `xuBalance` + add inventory record = 1 batch

---

### Interactions with Other Systems

| System | Reads | Writes |
|--------|-------|--------|
| Auth & Account | `families/{parentId}` | `families/{parentId}`, `children/{childId}` |
| Time & Decay | `storedEnergy`, `lastApprovedAt` | `storedEnergy`, `lastApprovedAt` |
| Currency System | `xuBalance` | `xuBalance` |
| Task Library | `tasks/*` | `tasks/{taskId}` (incl. `energyReward` per task) |
| Pet Leveling | `petLevel`, `totalXuEarned`, `nextLevelThreshold` | `petLevel`, `totalXuEarned`, `nextLevelThreshold`, `xuBalance` (bonus), `chestCount` (shared w/ Gacha) |
| Pet Equipment | `equippedItems` | `equippedItems` |
| Parent Approval | `tasks` (pending) | `tasks/{id}.status`, `rejectedAt`, batch reward |
| Parent Dashboard UI | `customTasks/*`, child profile list | `customTasks/{customTaskId}` |

> Note: Flutter-Flame Bridge (#5) does **not** read/write Firestore directly — it reads from Riverpod providers which are downstream consumers of this layer. Bridge is not a direct dependent of Data Persistence.

## Formulas

Không có mathematical formula. Nhưng có **batch write contracts**:

**Approve Task Batch:**
```
xuBalance    → FieldValue.increment(+task.xuReward)
storedEnergy → FieldValue.increment(+task.energyReward)   // NOT absolute set — see note
lastApprovedAt   = FieldValue.serverTimestamp()   // NOT client `now` — tamper-resistant decay clock (ADR-0005); safe from null-until-ack because approve is runTransaction
task.status      = 'approved'
task.approvedAt  = now
```
Tất cả 5 operations trong 1 `WriteBatch.commit()` — atomic.

> ⚠️ **storedEnergy cap enforcement**: `FieldValue.increment()` là server-side atomic và tránh race condition khi nhiều approvals xảy ra gần nhau. Tuy nhiên, Firestore không tự cap tại 100. **Cloud Function `onTaskApproved`** phải enforce cap: sau khi batch commit, nếu `storedEnergy > 100` → set về 100. (Cùng Cloud Function với `onChildProfileDelete` cascade delete.)

**Buy Item Batch:**
```
xuBalance    → FieldValue.increment(-item.price)
inventory/{itemId} = { itemId, acquiredAt: now, source: 'shop' }
```
Tất cả 2 operations trong 1 `WriteBatch.commit()` — atomic.

**Firestore document size budget:**

| Document | Max size | Estimated actual |
|----------|----------|-----------------|
| `children/{childId}` | 1MB | ~500 bytes |
| `tasks/{taskId}` | 1MB | ~200 bytes |
| `inventory/{itemId}` | 1MB | ~100 bytes |

## Edge Cases

- **Nếu app mất mạng khi đang write**: Firestore cache nhận write ngay — operation trả về `Future` complete ngay lập tức. Khi có mạng, SDK tự sync. Không cần xử lý đặc biệt ở app layer.

- **Nếu conflict xảy ra khi sync** (bé và bố mẹ cùng write `xuBalance` khi offline): Firestore dùng **last-write-wins** cho field-level updates. Approve task batch dùng `FieldValue.increment()` thay vì set absolute value — tránh conflict khi cả 2 device sync.

- **Nếu batch write thất bại một phần**: `WriteBatch.commit()` là all-or-nothing — nếu một operation fail, toàn bộ batch rollback. App phải retry hoặc show error. Không bao giờ có trạng thái "xu bị trừ nhưng item chưa vào inventory".

- **Nếu `inventory/{itemId}` đã tồn tại** (mua lại item đã có): `set()` với `merge: true` overwrite `acquiredAt` — idempotent, không tạo duplicate. Item catalog phải check ownership trước khi cho phép mua.

- **Nếu Firestore cache quá lớn**: `CACHE_SIZE_UNLIMITED` có thể tốn storage trên device cũ. Nếu xuất hiện complaint, switch sang `cacheSizeBytes: 50 * 1024 * 1024` (50MB cap).

- **Nếu `parentId` thay đổi** (Firebase Auth token refresh): Firestore paths dùng Auth UID — token refresh không thay đổi UID. An toàn.

- **Nếu bé xóa app và cài lại**: Local Firestore cache bị xóa. Data vẫn còn trên cloud. App tự sync về khi login lại — không mất data.

## Dependencies

**Upstream:**
- **Auth & Account (#1)** ✅: Cung cấp `parentId` và `childId` để scope tất cả Firestore paths

**Downstream (7 systems đọc/ghi qua layer này):**
- Time & Decay (#2), Currency System (#7), Task Library (#8), Push Notification (#9), Pet Equipment (#15), Pet Leveling (#16), Parent Approval (#11)

> Note: Flutter-Flame Bridge (#5) is NOT a direct downstream dependent — it reads from Riverpod providers, not Firestore.

**Cloud Functions (required deployment):**
- `onTaskApproved` — enforces `storedEnergy` cap at 100 post-increment
- `onChildProfileDelete` — recursive delete of `children/{childId}/` subcollections

**Firestore Security Rules (owned by this system):**

> ⚠️ **Đã sửa theo ADR-0003 §5 (amended) + ADR-0009 §3 (2026-07-13)** — bản wildcard đệ quy cũ (`match /families/{parentId}/{document=**}`) đã bị thay bằng các nested match block tường minh, vì Firestore rules OR across matching blocks (bất kỳ block nào match và allow là được phép — không có "narrowest wins"). Wildcard cũ khiến rule chặt hơn cho `tasks` (reward-integrity gate) trở nên vô tác dụng. Độ permissive giữ nguyên cho mọi collection khác (`xuBalance`, `storedEnergy`, inventory, customTasks vẫn client-writable — MVP tradeoff không đổi); chỉ riêng `tasks`' reward/`categoryId` field được gate thêm.

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /items/{itemId} { allow read: if request.auth != null; allow write: if false; }

    match /families/{parentId} {
      allow read, write: if request.auth.uid == parentId;

      match /customTasks/{customTaskId} { allow read, write: if request.auth.uid == parentId; }
      match /children/{childId} {
        allow read, write: if request.auth.uid == parentId;

        match /private/credentials { allow read, write: if request.auth.uid == parentId; }
        match /inventory/{itemId}  { allow read, write: if request.auth.uid == parentId; }

        // reward-integrity gate — see ADR-0009 §3 for the full rewardTable()/rewardOk() rule text
        match /tasks/{taskId} {
          allow read:   if request.auth.uid == parentId;
          allow create: if request.auth.uid == parentId
            && request.resource.data.status == 'pending'
            && rewardOk(request.resource.data);
          allow update: if request.auth.uid == parentId
            && request.resource.data.xuReward     == resource.data.xuReward
            && request.resource.data.energyReward == resource.data.energyReward
            && request.resource.data.categoryId   == resource.data.categoryId;
            // pending→approved/rejected status-transition constraint lives in THIS block
            // (owned by Parent Approval ADR) — must not be in a broader match, or it's bypassable again.
        }
      }
    }
  }
}
```
Child profiles không có Firebase Auth — mọi access đi qua parent auth token. `rewardTable()`/`rewardOk()` helper functions: xem ADR-0009 §3 cho định nghĩa đầy đủ (map literal với quoted CEL string keys).

## Tuning Knobs

| Knob | Default | Safe Range | Ghi chú |
|------|---------|------------|---------|
| `cacheSizeBytes` | UNLIMITED | 50MB–UNLIMITED | Giảm nếu device cũ complaint về storage |
| Max tasks per child | 100 (query limit) | 50–500 | Firestore query limit; archive old tasks sau 30 ngày |
| Max inventory items | 500 | 100–1000 | Firestore document count per child |
| Batch write retry attempts | 3 | 1–5 | Số lần retry nếu batch fail do network |

## Visual/Audio Requirements

Không áp dụng — pure infrastructure.

## UI Requirements

Loading states khi Firestore stream chưa có data (cold start, slow network):
- Child profile screen: skeleton shimmer thay vì blank screen
- Task list: skeleton shimmer
- Wallet display: hiện "..." thay vì 0 xu trong khi đang load

📌 **UX Flag — Data Persistence**: Loading states cần `/ux-design` spec cho skeleton shimmer components.

## Acceptance Criteria

**GIVEN** bé submit task khi device đang offline,
**WHEN** task được ghi vào Firestore,
**THEN** task xuất hiện trong UI ngay lập tức (từ local cache) — không có spinner, không có error.

**GIVEN** app khôi phục kết nối sau khi offline,
**WHEN** Firestore SDK sync,
**THEN** tất cả pending writes được upload — không có data loss, không cần user action.

**GIVEN** approve task batch (5 fields) bắt đầu commit,
**WHEN** network drop giữa chừng,
**THEN** toàn bộ batch rollback — `xuBalance` không tăng nếu `task.status` chưa = 'approved'.

**GIVEN** bé mua item đã có trong inventory,
**WHEN** buy batch commit,
**THEN** inventory không tạo duplicate document — `acquiredAt` được overwrite, `xuBalance` bị trừ đúng 1 lần.

**GIVEN** bé xóa app và cài lại, sau đó login,
**WHEN** app load child profile,
**THEN** toàn bộ data (xu, task history, inventory, energy) được restore từ Firestore cloud.

**GIVEN** Firestore stream đang load (cold start),
**WHEN** UI render,
**THEN** skeleton shimmer hiển thị — không có blank screen, không có NullPointerException.

## Open Questions

- **Firestore cost model**: Khi scale lên 1000+ families, mỗi `snapshots()` stream = 1 read/change. Cần model cost trước beta launch.
- **Task archival**: Tasks cũ sau 30 ngày có nên move sang `tasks_archive/` subcollection để giữ query performance không?
- ~~**Gacha chest loot**: Khi mở rương gacha, result cần được generate server-side (Cloud Function) hay client-side để tránh cheating? Ảnh hưởng đến schema — cần quyết định trước GDD #12.~~ **Resolved (retroactively closing a stale cross-reference, found during `/gate-check` 2026-07-06)**: `gacha-loot.md` (#12) đã quyết định **client-side roll cho MVP** khi được viết — schema không có gì cần Cloud Function riêng cho loot generation, chỉ có `chestCount`/`approvedTaskCount` fields (đã trong schema hiện tại). #12's own Open Questions ghi nhận rủi ro cheat client-side là "acceptable risk cho children's game MVP," Cloud Function roll deferred đến Alpha nếu cần. Quyết định đã có, chỉ chưa được propagate ngược lại đây để đóng open question này.
