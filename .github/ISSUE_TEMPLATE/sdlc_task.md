---
name: AI-Native SDLC Görevi (2 Kişilik Çakışmasız)
about: İki geliştiricinin birbiriyle çakışmadan çalışmasını sağlayan görev ve yazma alanı şablonu
title: "[Faz 1] [Görev ID] Başlık"
labels: sdlc-task
assignees: ''
---

### 1. Görev Kimliği ve Sorumlusu (Manifest Eşleşmesi)
- **Manifest Görev ID:** `P1-A01` / `P1-O01` / `P1-I01` (Bkz: `.sdlc/phase1_tasks.json`)
- **Manifest Revizyonu:** `1`
- **Geliştirici (Assignee):** @alicomert veya @okanipk
- **Çalışılacak Dal (Branch):** `feat/[alicomert|okanipk]/[gorev-id]`
- **Önkoşul Bağımlılıklar (Depends On):** `[örn: P1-A01]`

### 2. İzinli Yazma Alanı (Write Scopes)
> *Yalnız bu görevin manifestte tanımlı ayrık dosya ve klasörleri seçilmelidir:*
- [ ] `src/player` / `src/camera` (P1-A01)
- [ ] `src/interaction` (P1-O01)
- [ ] `src/combat` (P1-A02, P1-A04)
- [ ] `src/inventory` (P1-O02)
- [ ] `src/input` / `src/ui` (P1-A03, P1-A08)
- [ ] `src/objects` (P1-O03)
- [ ] `src/roles/` (P1-O04: lock, carrier | P1-A05: breaker, scout)
- [ ] `src/ai` (P1-O06, P1-O07)
- [ ] `src/world/` (P1-O08: engeller, P1-O09: üretim, P1-O10: yönetmen, P1-O11: olaylar, P1-O13: senaryo)
- [ ] `src/team/` (P1-A06: kurtarma, P1-A07: kombolar)
- [ ] **Ortak Entegrasyon (Yalnızca alicomert):** `src/lab/mechanics_lab.gd`, `src/lab/mechanics_lab.tscn`, `project.godot` (P1-I01, P1-I02)

### 3. Problem ve Hedeflenen Çıktı (Intent Özeti)
[Bu görevde tam olarak ne yapılacak? Hangi mekanik eklenecek veya test edilecek?]

### 4. Kabul Ölçütleri ve Kanıt
- [ ] Görev kabul kriterleri sağlandı (Bkz: `production/phase-1-workstreams.md`)
- [ ] Test kanıt belgesi hazırlandı (`production/qa/[gorev-id].md`)
- [ ] Kullanıcı hissiyat değerlendirmesi teknik kabulden ayrı tutuldu

### 5. Doğrulama ve Yerel Koordinasyon Komutları
- [ ] Başlangıç ve dal kontrolü: `python -B tools/sdlc/runner.py start`
- [ ] Yerel oturum rezervasyonu: `python -B tools/sdlc/locks.py acquire --dev [dev] --session [session-id] --scope "[kapsam]" --title "[baslik]"`
- [ ] Birim testleri: `python -B tools/sdlc/runner.py test`
- [ ] Oturum kilit serbest bırakma: `python -B tools/sdlc/locks.py release --dev [dev] --session [session-id]`

