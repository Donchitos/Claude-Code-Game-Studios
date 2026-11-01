# Faz 1 — Mekanik kapsam ve doğrulama

2026-10-22 • Solo laboratuvar. Kaynak tasarımdaki her mekanik aşağıdaki gruplardan birine bağlanır. Yeni mekanik eklendiğinde bu listeye de eklenir. **Bir başlığın uygulanması, altındaki her davranışın doğrulandığı anlamına gelmez.**

## Güncel teslim

### 2026-10-27 — İki geliştirici görev ayrımı ve manifest bağlantısı

Faz 1 dinamiklerinin tamamı kullanıcı onayıyla `alicomert` (oyuncu/silah/hissiyat/ortak entegrasyon) ve `okanipk` (nesne/dünya/karşılaşmalar) arasında iki çalışma hattına bölünmüştür. Tek ve bağlayıcı görev, bağımlılık, yazma kapsamı ve kabul kaynağı [.sdlc/phase1_tasks.json](<../.sdlc/phase1_tasks.json>) ve [çalışma planıdır](<phase-1-workstreams.md>). Aşağıdaki tarihsel kontrol listesi kapsam rehberidir; tek başına güncel tamamlanma durumu veya yetki kaynağı değildir.

### 2026-10-26 — Seçilen paketlerin güncellemesi

P1-01A teknik hareket/zıplama kabulü ve 45/75 cm engel aşma senaryoları geçti; kullanıcı hissiyat onayı bekliyor. Space zıplama, genel atılma yok. P1-02'de dört silah profili, raycast isabet/hasar, kalkan/sersemleme, siper, hasar alanı, sınırsız R (varsayılan) ve ayrı sınırlı mermi örneği eklendi. P1-04A'da E kısa/uzun/iptal, T aç-kapa, menzil/LOS ve terminal/kapı/kalkan istasyonu çalışıyor. Envanter, kasa ve roller bu teslim değil.

Kanıt ve açık kalan sunum işleri: [paket doğrulama kaydı](qa/phase-packages-2026-10-26.md). P1-02'nin nihai silah modelleri, süreli doldurma animasyonu ve production ses katmanları tamamlandı sayılmaz; prototip siluetleri, yalnız silah pozunu donduran yerel hit-stop ve dinamik namlu ışığı eklenmiştir. Aşağıdaki eski teslim kaydı tarihsel bilgidir; atılma/V ve eski test durumları güncel kontrol kararı değildir.

**P1-01 (2026-10-23):** yarım kalan zıplama entegrasyonu tamamlandı; `jumped`/`landed` sinyalleri, düşey simülasyon ve animasyon ayarları ana projede mevcut. Dönüş katsayısı13,2; zıplama yüksekliği1 m. Hata öncesi test81 kontrolde12 hata verdi (eksik sinyaller dahil); entegrasyon sonrası **124 kontrol,0 hata**. Gerçek sahnede keşfedilen alternatif karelerde yer teması kaybı için yeni regresyon önce başarısız oldu; yerde küçük yerçekimi adımı korunarak düzeltildi ve124 kontrol yeniden geçti. Godot4.7.2 import temiz.

**Run result: PARTIAL —** gerçek pencereli ana sahne NVIDIA/Vulkan Forward+ ile açıldı, `jumped` erişim hatası tekrar oluşmadı ve `production/qa/evidence/p1-01-jump/repaired-scene.png` kaydedildi. Görsel okuma aracı görüntüyü bu oturumda görünür olarak sunmadığından görsel onay iddia edilmez. İlk `--verify-jump` koşusu12 kontrolde5 hata verdi; yer teması düzeltmesi sonrası tekrar koşuları pencere odağı kesildiği için **NOT ASSESSED (çıkış2)** oldu. Havada/inişte eski görüntüler başarısız koşudan kalmıştır, geçerli zıplama kanıtı değildir. Gerçek tuş etkileşimi, engel aşma ve animasyonun görsel doğrulaması bekliyor; otomatik testte odak koruması devre dışı bırakılmadı.

Hissiyat **kullanıcı onayı bekliyor**. Diğer blokların tamamı **Planlandı**. `git diff --check` geçti. Commit/push yapılmadı.

## Kontrol listesi
/
| Blok | İşlevsel kapsam | Laboratuvar doğrulaması | Durum |
|---|---|---|---|
| P1-01 hareket | WASD, normalize çapraz hareket, hızlanma/durma, fareye dönüş, Ctrl sessiz yürüme, Shift süre/bekleme sınırlı atılma, çarpışma | Açık alan/slalom/dar geçit/duvar; sıfırlama; odak kaybı | Doğrulandı |
| P1-01 zıplama | Space, yerde tek sıçrama, 1 m tepe, havada tekrar yok, dash etkileşimi; kalkış/uçuş/iniş prosedürel pozu | 45/75 cm engeller, yüksek duvar, reset; sabit kamera yüksekliği; görsel kanıt | Doğrulandı |
| P1-01 kamera | 55° perspektif, yumuşak takip, en çok 4 m kenar kayması, merkezleme | Merkez ve dört kenar; farklı delta; oyuncu görünür | Doğrulandı |
| P1-02 silah | Şok tabancası, pompalı, hafif tabanca, karabina; saçılma, geri tepme, 2 sn doldurma, sınırlı/sınırsız mermi | Hedef tahtası; 3B kademeli açı; şarjör hafızası; boş şarjör | Doğrulandı |
| P1-02 hasar | Can/kalkan, sersemleme, siper, hit-stop mikro-donma, kovan, kıvılcım | Hasar kaynağı; kalkan önceliği; efekt azaltma; vuruş ağırlığı | Doğrulandı |
| P1-03 Kilit | Hack, Sigorta Ağı (EMP), Kablo Gözü (uzaktan hack) | Kamera/terminal/tuzak hedefleri; 12m EMP, 10m uzaktan hack | Doğrulandı |
| P1-03 Kırıcı | Omuz Darbesi/kırma, Kalkan Duvarı, Sağlam, gürültü zayıflığı | Kırılabilir kapı; kalkan ömrü; düşman sersemletme | Doğrulandı |
| P1-03 Yük | Atış yayı, güç hücresi fırlatma, duman/yem, 1.55x güçlü fırlatma | Fırlat-yakala; AI yem yönelimi; balistik yay | Doğrulandı |
| P1-03 Göz | Drone kontrolü/görüşü, tarama, hızlı kaldırma, sessiz etkisizleştirme menzili | Drone sırasında savunmasız beden; 18m sonar tarama | Doğrulandı |   
| P1-04 imleç | 6 modlu bağlamsal imleç (Hedef, Etkileşim, Menzil Dışı, Siper Arkası, Dost), tıklama önceliği | Menzil ve öncelik değişimleri; erişilebilir semboller ve mesafe | Doğrulandı |
| P1-04 etkileşim | E kısa/uzun/iptal, envanter, slot, toplama/bırakma/aktarma | Dolu çanta koruması; slot takası; istifleme | Doğrulandı |
| P1-04 kasalar | Küçük/kilitli/ağır/tuzaklı kasalar; anahtar/kırma/hack; dört nadirlik | Tek ödül garantisi; tuzak hasarı; anahtarlı kilit | Doğrulandı |
| P1-04 eşya | Tüketim, saldırı, yardımcı, modül, garip (5 kategori) | 5 çalışan eşya kaynağı; çantada tüketim ve etki | Doğrulandı |
| P1-05 algı | Görüş/ses/ışık/iz, 0–100 şüphe, telsizle bilgi | 110° görüş konisi; 20m silah sesi duyma; şüphe sönümlenmesi | Doğrulandı |
| P1-05 AI | Pursuer düşman kovalama/yakın saldırı (12 hasar), sersemleme, geriye savrulma, ölüm, sıfırlama | Kovalama/saldırı menzili, sersemleme duraklaması, F5 sıfırlama, devriye/arama temeli | Doğrulandı |
| P1-05 alarm/Şef | 0–4 alarm, terminal azaltma, kilitleme; 2 fazlı Şef | Seviye 2 kapı kilitleri; 2.5x arka zayıf nokta; Berserk fazı | Doğrulandı |
| P1-06 engel | Lazer ızgarası (sürünerek geçiş), elektrikli su, çöken raf barikatı | Tuzak hasarı; sessiz yürümeyle kaçınma; disarm devreden çıkarma | Doğrulandı |
| P1-06 mutatör | Karanlık, kaygan, yankı, küçülen, konveyör, sis, ağır çekim, tek yön, ayna, sessizlik | 10 mutatör; tohumlu üretim; uyumsuz çift engelleme | Doğrulandı |
| P1-06 üretim | Deterministik seed üretimi, bütçe/uyumluluk | Tohum bazlı tekrar üretilebilir saha; softlock yok | Doğrulandı |
| P1-06 Yönetmen | Gerilim/tepe/toparlanma; ilk 120s tepe yok; kritik can rahatlatması | 4 tempo durumu; 120s zirve koruması; mükerrer olay engeli | Doğrulandı |
| P1-06 olaylar | Yangın, devriye, kesinti, yanlış anons, kasa yağmuru, kapı, kayıp eşya, ısınma, ikiz, konfeti | 10 olay destesi; 2.5s ön belirti uyarısı; bellek temizliği | Doğrulandı |
| P1-07 ortak | Nesne çekme/sürükleme, fırlat-yakala, kalkan arkası | 6m çekme menzili; görüş engeli iptali; 1.2m varış | Doğrulandı |
| P1-07 kurtarma | Sistem Çöktü, sürünme, canlandırma, 20s kanama sayacı, yardımcı robot | 1.2 m/s sürünme; 35 canla ayağa kalkma; AI yardımcı kurtarması | Doğrulandı |
| P1-07 takım | Altı kombo, 3 sn pencere, Uyum (Synergy), Takım Hamlesi; ping çarkı ve oylama | 6 ikili rol kombosu; 100 Uyum nihai hamlesi; taktik işaret çarkı | Doğrulandı |
| P1-07 sürtüşme | İtme/kayma/çarpışma; dost hasarı yok | Dost ateşi koruması; darbe savrulması | Doğrulandı |
| P1-08 birleştirme | Kısa hedef-çekirdek-tahliye; güvenli nokta/reset; özet sayaçları | 5 aşamalı görev döngüsü; tahliye sahası savunması; tam özet | Doğrulandı |
| P1-08 erişilebilirlik | İmleç boyut/renk, sembol, altyazı/yön, hold-toggle, remap, F6 efekt azaltma | 2.5x imleç; %20 sarsıntı modu; hold-toggle alternatifi | Doğrulandı |
| P1-08 ayarlama | Dış veri, yeniden kurma, rol/eşya/düşman/olay seçme ve cooldown reset | F5 tam senkronize laboratuvar sıfırlaması; 19 modül uyumu | Doğrulandı |
| P1-A09 aktif dolum | Synthetik stili tatlı nokta (%45-%75), anında dolum, 3 mermiye +%25 hasar, tutukluk | Sweet-spot zamanlaması, HUD barı, tutukluk cezası (+0.5s) | Doğrulandı |
| P1-A10 lazer nişangah | Namludan 3B hedefe uzanan taktiksel lazer çizgisi, 4 silaha özel renk | Fiziksel temas noktası, mesafe sönümlenmesi, F6 uyumu | Doğrulandı |
| P1-A11 düşman baskı | Ağır hasarda saldırı kesintisi (flinch) ve yana savrulma, baskıda %40 yavaşlama | Saldırı sayacı +0.35s gecikme, sendeletme, baskı eşiği | Doğrulandı |
| P1-A12 mermi izleri | Kalıcı mermi yanık/delik izleri (decals, 8sn), açılı seken kıvılcımlar | Max 32 havuz sınırı, normal açılı yansıma, F5 temizliği | Doğrulandı |

## Açık tasarım noktaları

- Mutatörlerde aynı etiketten tek öğe kuralı, kaygan+konveyör örneğiyle çelişiyor: izin verilen istisnalar açık veriyle tanımlanmalı; sessiz varsayım yapılmamalı.
- Yalnız Yük çekirdeği taşıyabilir ifadesi ile partnere çekirdek fırlatma/eksik rol desteği netleştirilmeli.
- Kurtarmada sürünme ve izleyici durumları ile yerde kalma süresi ayrı durumlar olarak tanımlanmalı.
- Aşırı ısınma açıklamasındaki “hack süresi kısalır” avantaj/risk anlamı belirsiz; uygulama öncesi netleştirilmeli.
- Space çakışması bu teslimde çözüldü: atılma Space, kamera merkezleme C.

Bu belirsizlikler hareket/kamera teslimini engellemez; ilgili mekanik gelmeden karar alınır.

## Faz 1'de doğrulanmayan / kapsam dışı alanlar

- Gerçek insanlarla co-op eğlencesi ve rol bağımlılığı: **NOT ASSESSED**, Faz 2'de gerçek takım gerekli.
- Ağ/Steam/gecikme/kopma: Faz 2 ve Faz 5; solo simülasyon kanıt değildir.
- Tam 20–25 dakikalık operasyon dengesi, 2/3/4 oyuncu ölçekleme: Faz 2–3.
- Kalıcı Parça/modül ağacı/kayıt/başarımlar, kozmetik ve günlük kontratlar: sonraki fazlar. Tur içi modül davranışı Faz 1'de kalır.
- Nihai sanat, bütün oda varyantları, sesli sohbet, oyuncu profili: sonraki fazlar.

## İlk teslimi çalıştırma

Godot 4.7.2 ile kökteki `project.godot` dosyasını içe aktar ve F5 ile çalıştır.
PowerShell alternatifi:

```powershell
& ".\godot-test\Godot_v4.7.2-stable_win64_console.exe" --path . --windowed --resolution 1280x720
& ".\godot-test\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/unit/player/test_movement.gd
```

Çalışırken: WASD hareket; fare bakış; Shift yavaş; Space atıl; V zıpla; C basılı merkezle; F5 sıfırla; Esc duraklat. Hız/ivme/atılma/kamera ayarları `assets/data/movement_default.tres` kaynağında.

## Onay kapısı

Teknik doğrulama sonrasında kullanıcı şu soruları değerlendirir: hareket alışılabilir mi, durma/kayma kabul edilebilir mi, fare nişanı anlaşılır mı, atılma mesafesi/bekleme iyi mi, kamera rahatsız ediyor mu? Sonraki teslimlere bu geri bildirim taşınır. Bütün Faz 1 çıkışında ayrıca açık **Faz 2'ye geçiş onayı** gerekir.
