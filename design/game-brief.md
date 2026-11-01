# Sector 9 — Mekanik laboratuvarı

## Kaynak ve karar

Kaynak tasarım: [Sector 9: Cold Protocol](../Sector%209%20Cold%20Protocol%20%E2%80%94%20Oyun%20Tasar%C4%B1m%20Belgesi.md).
2026-10-22 kullanıcı kararı: önce tüm oynanış mekaniklerini tek oyunculu bir laboratuvarda deneyebilmek; alışılabilirlik ve hissiyat onaylanmadan sonraki faza geçmemek. Bu, nihai co-op oyuna solo kampanya veya AI partner ekleme kararı değildir. Kaynak belge korunur; geliştirme sırası için [faz planı](../production/phase-plan.md) geçerlidir.

## Kimlik ve his

“Planı yap. Plan bozulsun. Birlikte doğaçlayıp çık.” Nihai hedef 2–4 kişilik, eğik kameralı, fare nişanlı, stilize 3D sızma/aksiyon. Tehlike mekanik olarak gerçek; başarısızlık hafif ve komik. Faz 1'de görsel üretim yerine kontrol, okunabilirlik ve geri bildirim önceliklidir.

## Motor ve sınırlar

- Windows PC; Godot **4.7.2**, GDScript, Forward+, Jolt. Kurulu sürüm 2026-10-22 tarihinde `4.7.2.stable.official.ed1daf0bf` olarak doğrulandı.
- Kaynak kökü `src/`, veri `assets/data/`, testler `tests/`.
- Ağ, Steam, kalıcı ekonomi, kozmetik üretimi ve tamamlanmış altı oda Faz 1 teslimi değildir.
- Belgede prototip değeri olan sayılar ayarlanabilir başlangıç hipotezleridir.

## Faz 1 kapsamı ve yapım sırası

1. **P1-01 — Hareket/kamera:** WASD, fareye dönme, sessiz yürüme, atılma, takip/kenar kaydırma, çarpışma, test sıfırlama.
2. **P1-02 — Çatışma:** silah verileri, ateş, saçılma, doldurma, hasar/kalkan, geri bildirim, siper.
3. **P1-03 — Roller:** dört rol, Q/F, pasifler, zayıflıklar, hedefleme ve drone.
4. **P1-04 — Etkileşim/eşya:** bağlamsal imleç, envanter, kasalar, tüketimler, modüller, fırlatma/taşıma.
5. **P1-05 — Algı/AI:** görüş/ses/ışık/iz, şüphe, alarm, düşman durumları ve tipleri, Şef test karşılaşması.
6. **P1-06 — Çevre/Yönetmen:** engeller, mutatörler, olaylar, gerilim, seed/bütçe/uyumluluk ve Garip Oda örneği.
7. **P1-07 — Takım laboratuvarı:** kontrollü yardımcılar, kurtarma/ortak eylemler, kombolar, Uyum, ping ve sürtüşme.
8. **P1-08 — Birleştirme/his:** kısa hedef–çekirdek–tahliye provası, ayar karşılaştırmaları, kullanıcı testi ve onay.

Her blok kendi içinde çalıştırılır; ilk bloğun bitmesi Faz 1'in bitmesi değildir. Ayrıntılı izleme: [mekanik kontrol listesi](../production/phase-1-mechanics.md).

## İlk teslimin kabul koşulları

- `project.godot` açılarak F6 değil **F5** ile laboratuvar çalıştırılabilir; çalışırken F5 sıfırlar.
- WASD kameraya göre hareket eder; çapraz hareket hız kazandırmaz. Fare bakışı hareketten bağımsızdır.
- Ctrl yavaşlatır; Shift süre/bekleme sınırlı atılır; Space yerdeyken yaklaşık 1 m zıplatır. Havada tekrar/tuş basılı otomatik zıplama yoktur; atılma sırasında zıplama başlamaz; duvarların içinden geçilmez.
- Fareye dönüş katsayısı kullanıcı kararıyla22'den13,2'ye düşürüldü (%40); kamera kayması ve yürüyüş hızı değişmedi. Kalkış/uçuş/iniş için collider'dan ayrı prosedürel animasyon kullanılır; kamera zemin referansını izler. Taslak ve formüller: [zıplama spec](quick-specs/turn-response-jump-2026-10-22.md).
- Kamera yaklaşık 55° eğimlidir. Kenara yaklaşan fare sınırlı kaydırma yapar; C basılıyken merkezlenir.
- Esc duraklatır; F5 konum, hız, atılma ve kamerayı sıfırlar.
- Ayarlar `assets/data/movement_default.tres` içindedir; değişiklik için kod düzenlemek gerekmez.
- Birim testleri, gerçek sahne çalıştırması ve saklanan ekran görüntüsü ayrı raporlanır. Kullanıcının hissiyat değerlendirmesi otomatik testin yerine geçmez; otomatik test de onun yerine geçmez.

## Geçici kararlar

- Kaynak belgedeki Space çakışması: Space zıplama, Shift atılma, Ctrl sessiz yürüme, C kamera merkezleme.
- Kontrol laboratuvarında rol/ateş/etkileşim henüz yokken bunlar varmış gibi UI gösterilmez.
- Erişilebilirlik, ayarlanabilir imleç, remap ve efekt azaltma Faz 1 çıkışından önce ele alınır; ilk teslimde tamamlanmış sayılmaz.
- Tam test çatısı henüz kurulmadığı için ilk test bağımlılıksız Godot `SceneTree` çalıştırıcısıdır; gdUnit4/CI kurulduğu iddia edilmez.
- Depodaki CLAUDE.md/teknik-tercih aynaları henüz güncellenmedi; bu ilk onaylı paket dışında kaldılar. Motor için `project.yaml` ve çalıştırılmış ikili kaynak alınır.
