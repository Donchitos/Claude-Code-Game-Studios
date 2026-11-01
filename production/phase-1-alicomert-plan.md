# Faz 1 — alicomert'in çalışma planı

> Bu sayfa **Ali'nin neyi, hangi sırayla ve nasıl doğrulayarak yapacağını** anlatır. Atama ve yazma yetkisinin kaynağı [Faz 1 görev manifestidir](<../.sdlc/phase1_tasks.json>); buradaki görev kartları ikinci bir görev veritabanı değildir. [İki kişilik genel plan](<phase-1-workstreams.md>) ve [mekanik kapsamı](<phase-1-mechanics.md>) birlikte okunur.

## Başlangıç fotoğrafı ve hedef

- **28 Ekim 2026'da kontrol edilen bu checkout:** `main`, `origin/main` ile eşit; çalışma ağacı temiz, son commit `f65a6e7`. Bu bir anlık gözlemdir; sonraki açılışta `git status` ve başlangıç komutuyla tekrar bak. Okan'ın bilgisayarının güncelliği burada doğrulanmadı.
- Manifest revizyonu **1**; Ali'nin P1-A01–P1-A08 ve P1-I01–P1-I02 görevleri henüz `done` değildir. **İlk uygun iş P1-A01**; mevcut çalışan hareket/silah temellerini yeniden yazmak değil, eksik kabul kanıtlarını tamamlamak amaçtır.
- Ali'nin hattı: **oyuncu hareketi ve kamera → silah/hasar/ateş hissi → sol/sağ tık ve bağlamsal imleç → Kırıcı/Göz → kurtarma ve takım sistemleri → erişilebilirlik → laboratuvar entegrasyonu**. Okan kendi nesne/dünya hattını yürütür. İki insanın aynı ana sahneye eşzamanlı yazması planlanmaz.
- Güncel karar: **Space zıplama, genel atılma yok**. Kırıcı'nın Omuz Darbesi ayrı bir rol yeteneğidir. Son mermi ve R, **aynı iki saniyelik doldurma** yolunu kullanır. [Mekanik listesindeki](<phase-1-mechanics.md>) eski `V/Space atılma` ve `anlık R` satırları yeni karar değildir.

## Sıra ve bağımlılık şeması

```text
ALI:  A01 → A02 → A04 ────────────────────────────┐
                   └──────┐                       ├── I01 ──────────────────┐
OKAN: O01 → O02 ──────────┴→ A03 ─┐               │                         │
              └→ O03 ──────────────────────────────┘                         │
ALI:                   A03 + A04 → A05 → A06* ─┐                              │
OKAN: O03 → O04*; O03 + O07 → O08 ─────────────┴→ A07 → A08 ───────────────┤
OKAN: O04 + O09* + O11* + O12* → O13 ─────────────────────────────────────────┤
ALI:                                                               I01 + A08 + O13 → I02

* Tasarım kararı / bloke durum çözülmeden ilgili görev kapanmaz.
```

Şema kısa bir rehberdir; **kesin bağımlılıklar, dallar ve yazma kapsamları** her zaman [manifestte](<../.sdlc/phase1_tasks.json>) geçerlidir. A03 için O02; I01 için A03 + A04 + O03; A07 için A06 + O04 + O08; A08 için A03 + A04 + A07; I02 için I01 + A08 + O13 gerekir. Okan'ın engelli kararları Ali'nin bağımsız A01/A02/A04 işlerini durdurmaz.

## Ali'nin görev kartları

| Görev / dal | Ne yapacağım? | Ne zaman başlayabilirim? | Kanıt / bitiş kapısı |
|---|---|---|---|
| **P1-A01** `feat/alicomert/p1-a01` | WASD, Shift, yönlenme, Space zıplama, 45/75 cm engel ve 55° kamera/kenar merkezleme; odak, pause ve reset. | Hemen; bağımlılık yok. | Hareket ve klavye testleri **ayrı ayrı**, gerçek pencerede tuş/görüntü ve kişisel hareket hissi incelemesi. Yeni genel dash ekleme. |
| **P1-A02** `feat/alicomert/p1-a02` | Şok/pompalı/hafif tabanca/karabina atış ritmi; raycast, pellet, saçılma, siper/hasar, mermi ve R/son mermi doldurma. | A01 kanıtla tamamlanınca. | Atış/hasar/reload birimleri; boş/dolu şarjör, silah değişimi, pause, ölüm ve F7 sınırlı örnek; nişan–ateş davranışını elle dene. |
| **P1-A04** `feat/alicomert/p1-a04` | Geri tepme, namlu ışığı, ses katmanları, isabet ve hasar geri bildirimi, yerel hit-stop ve düşük can/efekt azaltma. | A02 tamamlanınca; A03 ile bağımsız ilerleyebilir. | Atış ≠ isabet ≠ hasar olayları; tek tetiklenen kamera/silah efektleri; dünya/girdi donmaz; ses/ışık/poz ve erişilebilirlik için gerçek pencere testi ve Ali'nin hissiyat notu. |
| **P1-A03** `feat/alicomert/p1-a03` | Sol/sağ tık press/hold/release önceliği; silah/eşya/yetenek yönlendirmesi; bağlamsal imleç, menzil ve engel nedeni. | **A02 ve O02**; Okan'ın envanter/slot arayüzü teslim edilmeli. | Odak/pause/menu ile yanlışlıkla ateş yok; iki eylem bir tıkta tetiklenmez; tüm imleç durumları ve erişilebilir semboller görünür. Sağ tık anlamı mod başına tasarlanır. |
| **P1-A05** `feat/alicomert/p1-a05` | Kırıcı: Omuz Darbesi/Kalkan Duvarı/pasif/gürültü. Göz: drone/tarama/hızlı kaldırma/sessiz menzil. | A03 ve A04. | Yetenek süre/cooldown, hedef geçersizliği, drone sırasında savunmasız beden, rol değişiminde pasif reseti; ayrı test düzeneği. |
| **P1-A06** `feat/alicomert/p1-a06` | Sistem Çöktü, yerde sürünme/ping, kaldırma, yeniden doğma/eşya kaybı ve kontrollü yardımcı. | A05; **şimdilik blocked**. | Önce kullanıcıyla yerde kalma süresi, sürünme–izleyici sırası kararını netleştir. Tek ve toplu çökme/reset, yardımcıyla kaldırma; solo kanıtı ağ/co-op kanıtı sayma. |
| **P1-A07** `feat/alicomert/p1-a07` | Altı rol kombosu, 3 sn pencere, Uyum, Takım Hamlesi, ping/hazır provası. | **A06, O04, O08** tamamlanınca. | Yardımcı + Okan modülleriyle kombo penceresi, tekrarlı dolum sömürüsü ve cooldown; gerçek multiplayer uygulanmaz. |
| **P1-A08** `feat/alicomert/p1-a08` | İmleç boyut/renk/sembol, altyazı/yön, hold-toggle, yeniden tuş atama, zamanlama ve efekt azaltma. | A03, A04, A07. | Her ayar gerçek davranışı değiştirir; yalnız renge dayanmaz; yeni kamera shake/iniş ve silah efektleri azaltılır, reset eski durumu taşımaz. |
| **P1-I01** `feat/alicomert/p1-i01` | İlk modülleri **tek entegratör olarak** ana laboratuvar, ana sahne ve InputMap'e sırayla bağla. | **A03, A04, O03** tesliminden sonra; A05/A06'dan bağımsız yürütülebilir. | API ve test kanıtı incele; tekil atış/isabet/hasar bağlantısı, doğru eşya önceliği; headless + pencereli regresyon, başarısız odak `NOT ASSESSED`. |
| **P1-I02** `feat/alicomert/p1-i02` | Dört rol, eşyalar, düşman/olay seçimleri ve kısa hedef–çekirdek–tahliye provasını aynı laboratuvarda bütünleştir. | **I01, A08, O13** bitince; çekme dahil bloke kararlar çözülmeli. | Bütün Faz 1 satırları gerçek davranış ve kanıtla değerlendirilsin; pause/reset/odak, tekrar kurulabilir senaryo; hareket/silah/etkileşim hissi ve Faz 2 geçişi için ayrı kullanıcı onayı. |

Kartlardaki dosya yolları kısaltılmıştır: işe başlamadan **ilgili görev nesnesinin `write_scopes` listesini** [manifestten](<../.sdlc/phase1_tasks.json>) aynen oku. Ortak [laboratuvar kodu](<../src/lab/mechanics_lab.gd>), [sahnesi](<../src/lab/mechanics_lab.tscn>), [proje girdi haritası](<../project.godot>) ve ortak veri bağlantıları **yalnız I01/I02** kapsamındadır; erken A görevlerine otomatik izin verilmez.

## Okan'dan ne zaman ne isteyeceğim?

| Okan teslimi | Ali'ye açtığı iş | En az gereken devir |
|---|---|---|
| **O01:** etkileşim hedefi, E/LOS/menzil | O02'nin temeli; A03'ün imleç nedenleri | Hedef önceliği, kısa neden/progress API'si ve iptal testleri. |
| **O02:** envanter, hızlı slot, eşya türleri | **A03** tık ve bağlamsal imleç | Slot/seçim komutları, değişim sinyali, dolu/boş örnekleri ve birim test kanıtı. |
| **O03:** taşıma, at–yakala | **I01** erken entegrasyon, O04 | Atış yayı/iniş önizlemesi, iptal ve sahiplik/reset sözleşmesi; ana sahneyi Okan değiştirmez. |
| **O04 + O08:** Kilit/Yük ve nesne ortak eylemleri | **A07** takım komboları | Yetenek ve ortak eylem olayları, bitiş/iptal sinyali; açık çekirdek kuralı karara bağlanır. |
| **O13:** kısa hedef–çekirdek–tahliye | **I02** son entegrasyon | Bağımsız tekrar kurulabilir prova, seed, temizleme/reset ve başarısızlık testleri. |

Okan'ın O05–O11 çıktıları da I02 için canlı kasa/düşman/alarm/engel/Yönetmen/olay tüketicileridir. Sinyal yayılması tek başına görünen oyun olayı değildir. Her teslimde **API/sinyal sözleşmesi, test dosyaları, test çıktısı, veri varsayılanları, pause/focus/reset davranışı, dokunulan dosya listesi** ve varsa açık karar istenir. İki clone'daki güncel manifest/baseline sürümü insan iletişimi veya PR incelemesiyle teyit edilir; GitHub Issue ve yerel kilit, dağıtık atomik dosya kilidi değildir.

## Her görev için tekrarlanabilir çalışma reçetesi

**1 — Kimlik ve başlangıç (bir defalık ayarı yineleme):**

```powershell
git status --short --branch
git config --local sdlc.developer alicomert
# İlk görev için yalnız DAL MEVCUT DEĞİLSE, temiz main'den:
git switch -c feat/alicomert/p1-a01
python -B tools/sdlc/runner.py start
```

Başlangıç `BLOCKED` diyorsa **dosya yazmaya geçme**: yanlış dal, yabancı dirty dosya, kimlik çelişkisi, yerel kayıt bozukluğu veya eksik bağımlılığı düzeltmeden görevi başlatma. Bir iş bitince yeni görev dalını uygun, gözden geçirilmiş ortak baseline'dan oluştur; başka özellik dalındaki henüz bütünleşmemiş işi otomatik taşıma. Başlangıç aracı dal oluşturmaz, ajan açmaz veya GitHub'dan güncellik almaz. Mevcut checkout'ta [yerel kilit kaydı](<../.sdlc/locks.json>) mevcut; yeni clone'da bulunmaması halinde başlangıç güvenli biçimde bloke olur. **Dikkat:** Mevcut `locks.py` CLI'sında `init` alt komutu tanımlanmış olsa da çalıştırma dalı yok; `python -B tools/sdlc/locks.py init` kaydı oluşturmuyor. Bu kusur ayrı düzeltme/onay gerektirir; yokmuş gibi çalıştığını varsayma.

**2 — Görev taslağı:** Manifestteki kabul maddelerini ve ilgili [motor referansını](<../docs/engine-reference/godot/VERSION.md>) oku. Bir görev için ayrı `intent → spec → plan` yaz; tam değişecek dosya listesini ve davranış kararlarını kullanıcıya sunup onay al. Görev planı/kanıt/manifest dosyasını güncelleme izni, oyundaki `write_scopes` tarafından otomatik verilmez. Gerekirse kapsama açık revizyon iste.

**3 — Yerel rezervasyon (onaydan sonra):** Yalnız o görevde gerçekten dokunacağın manifest alt kapsamını seç; eşsiz oturum kimliği kullan:

```powershell
$env:SDLC_SESSION = "alicomert-p1-a01-<benzersiz-oturum-kimliği>"
python -B tools/sdlc/locks.py acquire --dev alicomert --session $env:SDLC_SESSION --scope "src/player,src/camera" --title "P1-A01"
# Oturumu bitirirken yalnız kendi kaydını bırak:
python -B tools/sdlc/locks.py release --dev alicomert --session $env:SDLC_SESSION
```

Bu sadece **aynı checkout'ta işbirliği yapan süreçler** arasında advisory rezervasyondur; Okan'ın ayrı bilgisayardaki düzenlemesini teknik olarak engellemez. Aynı kişinin farklı oturumu bile çakışabilir. Başka oturuma ait kayıt veya mutex dosyası körlemesine silinmez.

**4 — Test-first → küçük uygulama → kanıt:** Önce başarısız kabul testini, sonra en dar kod/veri değişikliğini yaz. Godot API'si için sabit motor sürümünü ve mevcut sınıfları kontrol et. Yeniden kullanılabilir mekanik değerleri dış veriyle ayarla, testleri yaz ve ayrı laboratuvar provası yap. Her modülün pause/focus/reset ve efekt azaltma davranışını yazılı devir notuna koy. Tamamlanmamış, koşturulamayan veya görsel olarak incelenemeyen kontrolü `NOT ASSESSED` bırak.

**5 — İnceleme ve sonraki görev:** Görev branch'ini incelemeye sun, ortak dosyayı yalnız I görevinde değiştir; kanıtı `production/qa/p1-*.md` altındaki göreve özgü kayda işle. Kanıt ve gerekli kullanıcı hissiyatı görülmeden `done` deme. Manifestte `status`, `evidence`, `revision` ve gerekirse Issue bağlantısı değiştirilecekse bunu ayrı ortak koordinasyon kararı ve incelemesiyle yap. Git commit/push yalnız ilgili iş için kullanıcının talimatıyla yapılır.

## Gerçek doğrulama ve his testi kapısı

- **Otomatik test:** `python -B tools/sdlc/runner.py test --filter test_movement` gibi göreve göre dar test; sonra etkilenen tüm testler. Genel `runner.py test` **`test_keyboard_bindings.gd` dosyasını sessizce hariç tutar**; sıfır hata raporu tam klavye/oyun kanıtı değildir. Klavye testi ayrı koşulup sonucu/çalışma ortamı kaydedilir; mevcut başsız Windows çalışmasında bu testin geçmiş başarısızlığı vardır. Sebep kanıtlanmadan testi atlayıp kabul verme.
- **Pencereli kontrol:** Gerçek odaklı pencere ve Godot 4.7.2'de WASD/Shift/Space/C, 1–4/sol tık/R, boş şarjör, hedefe ve sipere atış, odak kaybı/pause/reset tekrar denemeleri. Kendi görüntü ve ses değerlendirmesini belirt; görüntü gözlemlenmediyse 'görsel geçti' deme.
- **Ali'nin hissiyat soruları:** Karakter kayıyor mu; zıplama/iniş okunur mu; imleç eylemi önceden anlatıyor mu; her silah farklı ritimde ve ağırlıkta mı; isabet ile ıskalama ayrılıyor mu; tekrar doldurma bekleme süresi anlaşılır mı; sarsıntı/ışık/ses yorucu mu; azaltılmış efekt modunda bilgi kayboluyor mu?
- **Çıkış:** Teknik test, oyun içi prova ve kullanıcı hissiyatı ayrı kayıtlardır. Kontrollü yardımcıyla prova gerçek 2–4 kişilik co-op değildir. Faz 1 tamamlanması, Faz 2'ye otomatik geçiş değildir.

## Açık kararlar ve kapsam dışı işler

- **Ali tarafı:** P1-A06 yerde kalma süresi, sürünme ve izleme/yeniden doğma durumlarının sırası için kullanıcı kararı gerekir; kararsızken A07/A08 zinciri kapanmaz.
- **Okan tarafı:** O04 çekirdek kuralı, O09 mutatör uyumu, O11 aşırı ısınma ve O12 **'çekme' türü** henüz net değil. Yakındaki nesneyi sürükleme, uzaktan kanca veya atılanı geri çağırma seçeneklerinden hiçbirini kendi başımıza varsaymayız. O13/I02 bunlara bağımlıdır.
- **Sonraki fazlar:** Ağ/Steam, gerçek 2–4 oyuncu doğrulaması, 20–25 dakikalık tam operasyon ve nihai sanat bu planla tamamlanmış sayılmaz.

**Ali için tek cümlelik başlangıç:** `P1-A01` görev dalında `start` ile uygunluğu denetle; hareket/Space zıplama/kamera kabulünü hem birim hem gerçek pencerede kanıtla; hissiyat kararını ayrı kaydet; ardından A02 silah davranışına geç.
