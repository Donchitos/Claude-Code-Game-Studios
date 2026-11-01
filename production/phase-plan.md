# Sector 9 — Geliştirme fazları

2026-10-22 • Kullanıcının onayladığı mekanik-önce geliştirme sırası.
Kaynak: [oyun özeti](../design/game-brief.md). Bu belge orijinal tasarımdaki eksik gömülü yol haritasının yerine geliştirme sırasını belirler; oyunun co-op hedefini değiştirmez.

## Faz 1 — Tek oyunculu mekanik laboratuvarı

**Amaç:** bütün oynanış davranışlarının işlevsel örneklerini aynı test ortamında deneyebilmek. Yalnız hareket/ateş demosu değil; roller, eşyalar, AI, engeller, Yönetmen ve takım eylemlerinin solo tetiklenebilir karşılıkları da kapsamda.

**Teslim:** ayarlanabilir değerler, tekrar kurulabilir test senaryoları, dört role erişim, kontrollü yardımcı karakterler, kısa çekirdek/tahliye provası. Sanat sade; mekanik geri bildirimi okunabilir.

**Çıkış kapısı:** [mekanik listesinde](phase-1-mechanics.md) bütün kapsam satırları kanıtla değerlendirilir; bloke/bilinmeyen satırlar açıkça görünür. Kullanıcı alışılabilirlik ve hissiyatı açıkça onaylar. Yardımcıyla test, gerçek co-op eğlencesinin/ağ davranışının kanıtı değildir. Onay olmadan Faz 2 başlamaz.

**Güncel koordinasyon (2026-10-27):** Faz 1 işleri [iki çalışma hattına](<phase-1-workstreams.md>) bölündü; sahiplik, bağımlılık, dosya kapsamı ve kabul ölçütleri [manifestte](<../.sdlc/phase1_tasks.json>) tutulur. alicomert oyuncu/silah/hissiyat ve ortak entegrasyon; okanipk nesne/dünya/karşılaşmalar. `python -B tools/sdlc/runner.py start` kimliğe göre sıradaki görevi gösterir; kod yazmaz ve GitHub'a bağlanmaz. Mevcut hareket/silah/etkileşim temelleri yeniden doğrulanacaktır; bu altyapı kurulumu oyun mekaniklerini tamamlanmış saymaz. [Son mekanik teslim kaydı](<qa/phase-packages-2026-10-26.md>) tarihsel kanıttır; kullanıcı hissiyat ve Faz 2 geçiş onayı hâlâ ayrıdır.

## Faz 2 — Gerçek co-op doğrulaması

**Amaç:** 2, 3 ve 4 gerçek oyuncu ile çok oyunculu oynanışı ve host yetkisini (server-authoritative) ENet üzerinde doğrulamak.

**İş:**
- **Ağ Altyapısı & Lobi:** Godot 4.7 `ENetMultiplayerPeer`, 4-6 haneli oda koduyla lobiye bağlanma ve `MultiplayerSpawner` ile oyuncu eşlemesi.
- **Sunucu Otoritesi (Host-Authoritative):** Hasar, düşman yapay zekası, alarmlar, kasa içerikleri ve Yönetmen host tarafında hesaplanır; istemciler 30 Hz hızında girdi ve nişan yönü gönderir.
- **Eşzamanlama (Synchronization):** `MultiplayerSynchronizer` ile sık değişen (konum/hız) ve seyrek değişen (can/kalkan/durum) verilerin ayrı kanallarda gecikmesiz senkronu.
- **Oyuncu Sayısına Göre Ölçekleme & Melez Roller:**
  - *4 Oyuncu:* Dört tam rol (Kırıcı, Göz, Kilit, Yük).
  - *3 Oyuncu:* Üç rol seçilir; eksik rolün yetenekleri kasa modülü veya alternatif rotayla kompanse edilir.
  - *2 Oyuncu (Çift Modu):* İki melez rol devreye girer: **Teknik Gözcü** (Kilit + Göz: hack ve drone) ve **Baskın Taşıyıcı** (Kırıcı + Yük: darbe ve fırlatma).
- **Dost Ateşi Yok, Fiziksel Sürtüşme Var:** Mermiler dost birimlere zarar vermez; fakat oyuncular birbirini iter, kaydırır ve güç hücrelerini elden ele atıp yakalar.
- **Kopma & Yeniden Bağlanma:** Oyuncunun bağlantısı koptuğunda bot yerine geçmez; takım eksik devam eder ve 60–90 saniyelik geri dönme (reconnect) rezervasyon penceresi açık tutulur.

**Çıkış:** Bütün oyuncu sayılarıyla (2, 3 ve 4 kişi) kritik senaryolar test edilir; gecikme ve paket kaybı dayanıklılığı doğrulanır. Host düşmesinde tur kurtarma/sonlandırma davranışı açıktır. Kullanıcı gerçek takım hissiyatını değerlendirir.

## Faz 3 — Tam operasyon döngüsü

**Amaç:** mekanikleri 20–25 dakikalık operasyon bağlamında doğrulamak.

**İş:** koridor/kapı kartları/oylama, dört oda + Çekirdek Odası + tahliye, güvenli noktalar, rol alternatifleri; Faz 1 üretim/tempo sistemlerinin operasyon ölçeğine taşınması; hedef süre ve risk/ödül dengesi.

**Çıkış:** baştan sona tekrar oynanabilir ve seed ile yeniden üretilebilir operasyon; iki kişilik takımda zorunlu rol kilidi yok; döngü ve kaynak dengesi playtest ile değerlendirilir.

## Faz 4 — İçerik ve sunum

**Amaç:** doğrulanmış mekanikleri hedef kimlikte, yeterli içerikle sunmak.

**İş:** oda konseptleri ve iskelet çeşitleri, karakterler, animasyonlar, dreamcore mekanlar, nihai ses/VFX, görsel dil, tam UI/erişilebilirlik ve performans iyileştirmeleri. Temel okunabilirlik ve gerekli erişilebilirlik bu faza kadar ertelenmez.

**Çıkış:** içerik hedefleri ve sanat/ses standartları karşılanır; efektler mekanik bilgiyi örtmez; hedef donanımda performans ölçülür.

## Faz 5 — Steam ve yayın hazırlığı

**İş:** GodotSteam bağlantısı/lobi/ses, kalıcı Parça ve yan seçenek modülleri, kayıt ve başarımlar, platform entegrasyonu; regresyon, güvenlik, performans ve yayın kontrol listesi. Günlük seed/kozmetik/üst Protokoller kapsam onayıyla ele alınır; hepsi ilk yayın için otomatik taahhüt değildir.

**Çıkış:** yayın adayı gerçek hedef donanım/platform üzerinde doğrulanır; başarısız ve çalıştırılamayan kontroller açıkça raporlanır.

## Durum dili

- **Planlandı:** uygulama yok.
- **Uygulanıyor:** kodlama sürüyor; tamamlanma iddiası değil.
- **Doğrulama bekliyor:** kod var, gerekli test/gözlem eksik.
- **Kullanıcı hissiyat onayı bekliyor:** teknik kanıt var, öznel değerlendirme açık.
- **Onaylandı:** ilgili kanıtlar ve gerekli kullanıcı kararı mevcut.
- **NOT ASSESSED:** kontrol gerçekleştirilemedi; nedeni yazılır. Başarılı sayılmaz.

Bu oyun fazları, stüdyo iş akışının `Concept`/`Systems Design` aşamalarıyla aynı şey değildir; dosya sayısından otomatik üretim olgunluğu çıkarılmaz.
