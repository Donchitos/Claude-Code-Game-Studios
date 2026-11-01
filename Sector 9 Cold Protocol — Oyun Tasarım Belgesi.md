# Sector 9: Cold Protocol — Oyun Tasarım Belgesi

Oct 21, 2026 · @Ali Cömert

Sector 9, dört kişiye kadar co-op oynanan, LoL tarzı eğik kameralı ve fareyle nişan alınan, yumuşak-gergin tonlu bir sızma oyunudur. Her operasyon sabit bir koridorda, rastgele birleşen odalarla ve Yönetmen'in sürprizleriyle geçer. Belgedeki sayılar ilk öneridir, prototipte test edilerek değişir.

## Karar özeti

| Konu | Karar |
| --- | --- |
| Kimlik cümlesi (öneri) | "Planı yap. Plan bozulsun. Birlikte doğaçlayıp çık." |
| Ton | Yumuşak-gergin: kan hafif var, komik başarısızlık, gerçek risk |
| İki sütun | Takım etkileşimi ve eğlence; strateji ve aksiyon |
| Kamera | Sabit eğik perspektif (yaklaşık 55°), LoL tarzı |
| Kontrol | WASD + serbest fare; imleç elindeki şeye ve yapılabilecek eyleme göre değişir |
| Oyuncu | 2-4 kişi (2 kişide melez roller); solo sonraya |
| Roller | Kilit, Kırıcı, Yük, Göz; kombolar ve Uyum çubuğu |
| Yapı | Operasyon başına bir koridor, 6 kapı; 4 oda + Çekirdek Odası + tahliye |
| Rastgelelik | Oda = iskelet + kaplama + mutatör + engel + ödül; tehlike bütçesi, seed, doğrulama |
| Sürpriz | Yönetmen + olay destesi, Garip Oda |
| Kasa | Odalarda kasalar + PUBG tarzı Düşüş Kasası |
| Motor | Godot 4, GDScript, Forward+, host yetkili ağ, Steam (GodotSteam) |

## Araştırma: co-op'ta ne tutuyor?

Açılan kaynaklar tek bir örüntü gösteriyor: en çok önerilen co-op oyunlar kazanmaktan çok birlikte komik ve anlatılabilir anlar üretmeye, rol bağımlılığına ve kısa oturumlara dayanıyor. Ton genelde hafif ve kaotik; tehlike gerilimi sürdürmek için duruyor ama korkutmak için değil.

| Oyun | Oyuncu | Neden tutuyor | Sector 9'a çıkarım |
| --- | --- | --- | --- |
| [R.E.P.O.](https://en.wikipedia.org/wiki/R.E.P.O.) | 6 | Rastgele modüler düzen, komik eşyalar ve canavarlar, sözlü koordinasyon. Mart 2025'te bir hafta boyunca Steam'in en yüksek gelirli ücretli oyunu oldu | Rastgele modüler odalar + komik tehlike |
| [Lethal Company](https://gamegeeker.com/editors-picks/best-co-op-games-on-steam) | 3-4 | Korku-komedi, kota, gece döngüsü, yakın ses sohbeti kaosu | Gerçek baskı + gülmek bir arada olabilir |
| [Deep Rock Galactic](https://gamegeeker.com/editors-picks/best-co-op-games-on-steam) | 4 | Sınıflar birbirine bağlı, yaklaşık 25 dk görev döngüsü, prosedürel mağaralar | Rol bağımlılığı ve kısa döngü |
| [It Takes Two / Split Fiction](https://www.esports.net/news/gaming/best-coop-games/) | 2 | Çiftlere en çok önerilen tipler; bağlı yetenekler, sürekli yeni mekanik | Her odada yeni bir mekanik hissi |
| [Overcooked 2](https://www.esports.net/news/gaming/best-coop-games/) | 1-4 | Aksilikler komik, hafif ton | Hata komik, ceza ağır değil |
| [Evolve ve Left 4 Dead Yönetmeni](https://shacknews.com/article/82787/how-evolve-assures-action-peaks-and-valleys) | 4 | Sessiz arama, zorunlu temas, kaçış, toparlanma döngüsü | Dinamik tempo için Yönetmen |

### Ortak kalıplar

1. **Başarısızlık eğlencelik olmalı.** Bir kılavuz "comedic failure states" tasarlamayı ve ölümü izlenebilir yapmayı öneriyor ([Cinevva](https://app.cinevva.com/guides/co-op-game-design)).
2. **Karşılıklı bağımlılık.** Oyuncular birbirine ihtiyaç duymalı ve bir yandan birbirinin yoluna girmeli ([Cinevva](https://app.cinevva.com/guides/co-op-game-design)). Ayrı sınıflar, sınırlı kaynak ve zor tahliye paylaşım ve karşılıklı korumayı zorlar ([Co-Optimus](https://www.co-optimus.com/blog/article-poster/3388/how-co-op-mechanics-turn-teamwork-into-the-main-event.html)).
3. **Kısa oturumlar.** 15-30 dakikalık turlar, akşamın içine birkaç tur sığdırmayı sağlar.
4. **Düşük beceri tabanı ve iletişim araçları.** Ping, işaret ve bağlam yazıları sesli sohbet olmasa da bilgi taşır ([Co-Optimus](https://www.co-optimus.com/blog/article-poster/3388/how-co-op-mechanics-turn-teamwork-into-the-main-event.html)).
5. **Tempo dalgası.** İyi akış sakin arama, zorunlu temas, kaçış ve toparlanma arasında gidip gelir.
6. **Rastgele modüler düzen.** R.E.P.O. gibi oyunlar oda düzenini, eşya ve düşman dağılımını her oyunda değiştirir.

**Sınır:** Bunlar editör listeleri, rehberler ve tek bir ansiklopedi sayfası; oyuncu tercihini ölçen bir anket verisi bulamadım. Bu yüzden sonuçlar "yaygın kalıp" olarak okunmalı, kesin istatistik olarak değil.

## Ton ve tasarım dili: yumuşak ama gergin

Karar: Sector 9 **yumuşak-gergin** bir tonla yapılır. Tehlike, alarm ve zaman baskısı gerçek kalır; fakat görsel dil, düşman tipi ve başarısızlık sonuçları sevgililerin ve arkadaşların rahatça oynayabileceği biçimde komik ve sıcak tutulur. Gerekçe: araştırmada en çok önerilen co-op oyunlar bu karmaşık tonu kullanıyor (korku-komedi, kaotik hafiflik), çift oyunları ise hafif ve işbirliğine dayalı.

| Boyut | Sert ton | Seçilen: yumuşak-gergin |
| --- | --- | --- |
| Görsel | Gerçekçi, soluk, kasvetli | Stilize 3D, yuvarlak formlar, koyu ortam + sıcak neon vurgu ışıkları |
| Düşman | İnsan askerler, kan | Güvenlik droidleri ve botlar; yenilince kıvılcım ve parça düşer, kan yok |
| Başarısızlık | Kalıcı ölüm, ceza | Sistem "yeniden başlatılır" (yere düşme), partner kaldırır; başarısızlık komik an üretir |
| Ses | Ciddi telsiz, sessizlik | Kuru mizahlı sistem anonsu, komik uyarı sesleri, tehlikede gerçek gerilim müziği |
| Dreamcore | Korku ve kaçış | Tuhaf, yanlış mekanlar; huzursuz eder ama öldürmez |
| Zorluk | Hata affetmez | Düşük beceri tabanı, yükselen Protokol seviyeleriyle sertleşen üst sınır |

### Tasarım dili kuralları

- **Kimlik cümlesi (öneri):** "Planı yap. Plan bozulsun. Birlikte doğaçlayıp çık." Eski "sessizce sız" fikri korunur; yeni cümle plan bozulma ve doğaçlama kimliğini öne alır.
- Gerilim ve mizah aynı anda olabilir: alarm çalarken kapının sıkışması komik, ama alarm hala gidiyor.
- Şiddet görsel olarak hafiftir (kan yok, parlak vuruş efekti), mekanik olarak ciddidir (can, mermi, risk).
- Renk paleti: koyu mavi-mor ortam, sıcak turuncu ve pembe vurgu ışıkları; Yönetmen olayları renk değişimiyle haber verir.
- Karakterler karikatürleşmiş oranlara sahiptir; zayıflıkları animasyonla komik hissettirir (Yük'ün çantası sallanır, Kırıcı her adımda gürülder).
- Çift dostu özellikler: 2 kişiyle tam oynanabilir, partner kaldırma süresi kısa ve kolay, hataları geri alan yeniden başlatma, 20-25 dk tur, ping ile sessiz iletişim.
- Şiddet ve mizah ayarı: "Sert mod" ileriki bir seçenek olarak düşünülür; ilk sürümde tek ton vardır.

## İki temel sütun

Her özellik iki sütundan en az birine hizmet eder: **takım etkileşimi ve eğlence** ile **strateji ve aksiyon**. İkisine de hizmet etmeyen özellik eklenmez.

### Sütun 1: Takım etkileşimi ve eğlence

- **Zorunlu karşılıklı bağımlılık.** Rol zayıflıkları oyuncuları birbirine bağlar (Kilit hack sırasında savunmasız, Yük çekirdekle ateş edemez).
- **Birbirinin yoluna girme.** Fizik itme, çarpışan kalkanlar, fırlatılan çanta yakalama. Hasar yoktur, itme ve komik sonuç vardır.
- **Ortak eylemler.** İki ya da dört kişinin aynı anda yaptığı eylemler (bkz. takım etkileşim sistemi).
- **İletişim.** Ping tekeri, dünya işaretleri, isteğe bağlı yakın ses sohbeti.
- **Tasarlanmış komik başarısızlık.** Sıkışan kapı, yanlış düğme, yönü şaşıran lamba; ceza hafif, an komik.
- **Anlatılabilir anlar.** Yönetmen her turda en az iki üç "hikâye anı" üretmeyi hedefler; tur sonu özet ekranı en gürültülü, en riskli, en iyi kurtarıcı gibi unvanlar verir.

### Sütun 2: Strateji ve aksiyon

- **Planlama.** Kapı önünde keşif (Göz'ün dronu), kimin neyi taşıyacağı, hangi rotanın seçileceği.
- **Risk ve ödül kararları.** Sessiz ve yavaş rota veya gürültülü ve hızlı rota; kasayı açmak ve alarm riskini göze almak.
- **Kaynak yönetimi.** Sınırlı mermi, bekleme süreli yetenekler, ortak çanta.
- **Aksiyon.** Nişan, siper, fırlatma, kapanışma; imleçle doğrudan kontrol.
- **Tempo.** Yönetmen sessizlik, gerilim, patlama ve nefes aralığını sırayla kurar.

### Her özellik için test

Bir özelliğin şu üç sorudan en az ikisine "evet" demesi gerekir:

1. İki oyuncunun konuşmasını veya birbirine yardım etmesini gerektiriyor mu?
2. Oyuncuya anlamlı bir risk ve ödül karşılaştırması yapıyor mu?
3. Anlatılabilir, gülünecek veya heyecan veren bir an üretiyor mu?

## Kamera, kontrol ve imleç

Oyun LoL tarzı sabit eğik kamerayla, serbest fareyle oynanır: karakter fareye bakar, imleç o an elindeki şeye ve yapabileceğine göre değişir. İmleç, klasik HUD'un yerini tutan ana bilgi kanalıdır.

### Kamera

- Perspektif kamera, yaklaşık 55° eğim. Dünya tam 3D, kamera yönü sabit (döndürülmez); bu "2.5D" okunabilirlik verir.
- Oyuncuyu yumuşak takip eder. Fare ekran kenarına yaklaşınca kamera o yöne en fazla 4 metre kayar; Space basılıyken kamera sabitlenir.
- Kamerayla oyuncu arasındaki duvarlar şeffaflaşır (dither). Kapalı odalarda tavan kesilir.
- Her oyuncunun kamerası bağımsızdır. Yere düşen oyuncu partnerinin kamerasını izleyebilir.

### Kontroller (klavye + fare)

| Girdi | İşlev |
| --- | --- |
| WASD | Hareket (karakter her zaman fareye bakar) |
| Fare | Nişan yönü ve imleç |
| Sol tık | Birincil eylem: ateş, seçili eşyayı kullan, hedefli eylemi onayla |
| Sağ tık | İkincil eylem: nişan daraltma, kalkan kaldırma, eşya fırlatma iptali (role göre) |
| E | Etkileşim (kasa, terminal, kapı, partner). Basılı tut = uzun etkileşim |
| Q, F | Rol yetenekleri |
| R | Yeniden doldur |
| Shift | Sessiz yürüme (yavaş, ses üretmez) |
| Space | Kısa atılma (bekleme süreli) |
| 1-4 ve tekerlek | Hızlı slot seçimi |
| Tab | Çanta |
| Orta tık veya Alt | Ping ve ping tekeri |

Gamepad desteği prototipten sonra eklenir.

### Bağlama göre değişen imleç

| Durum | İmleç | Davranış |
| --- | --- | --- |
| Boş el | İnce nokta + yön halkası | Yalnızca bakış yönünü gösterir |
| Silah | Nişan halkası | Halka genişliği isabet konisidir; hareketle ve geri tepmeyle şişer, yeniden doldururken döner |
| Fırlatılan eşya (duman, yem) | Atış yayı + iniş halkası | Menzil sınırında soluklaşır |
| Etkileşilebilir nesne (menzilde) | El ikonu + ilerleme halkası | Uzun etkileşimde halka dolar |
| Etkileşilebilir nesne (menzil dışı) | Soluk kilit ikonu | Neden kullanılamadığı yazar |
| Kasa | Kasa ikonu | Kilit türü ve gereken anahtar görünür |
| Partner | Yeşil çerçeve | Kaldır, eşya ver, ortak eylem seçenekleri |
| Terminal | Devre ikonu | Hack başlatır |
| Düşman | Kırmızı çember | Tehdit türü; sessiz etkisizleştirme menzilinde hançer ikonu |
| Yetenek hedefleme | Yarıçap veya koni önizlemesi | Etki alanı zemine çizilir |
| Ping modu | İşaret ucu | Partnerlere dünya işareti bırakır |
| Engellenmiş eylem | İmleç + üstü çizili ikon | "Çok uzak", "Elinde anahtar yok" gibi kısa neden |

Kural: imleç değişimi oyuncuya "şu an ne yapabilirim?" sorusunu cevaplar. Yeni bir eylem eklendiğinde önce imleç durumu tanımlanır, sonra eylem yazılır.

## Karakterler ve roller

Dört rol vardır ve her biri diğerlerinin çözemediği bir problemi çözer. Her rolün iki yeteneği (Q, F), bir pasifi, net bir güçlü yanı ve net bir zayıflığı vardır; zayıflık o rolü başkasına bağlar.

### Kilit — Teknisyen

- **Q Hack Darbesi:** imleçle terminal, kapı veya kamera seçilir; ilerleme halkası dolana kadar sessizce hack sürer (yaklaşık 3 sn).
- **F Sigorta Ağı:** zemine koni çizilir; konideki elektrikli tuzaklar ve lazerler 6 sn yeniden yönlendirilir, düşman droidleri sersemler.
- **Pasif Kablo Gözü:** tesisat ve panelleri kısa mesafede duvar arkasından görür.
- **Güçlü yan:** sessiz kapı ve sistem kontrolü, zincirleme arızayı yönetme.
- **Zayıflık:** hack sırasında yerinden oynayamaz, silahı zayıftır. Hack sürerken korunmaya ihtiyaç duyar.

### Kırıcı — Baskıncı

- **Q Omuz Darbesi:** kısa atılış; ince duvar ve kapıları kırar, çarptığı düşmanı sersemletir. Ses çok büyüktür.
- **F Kalkan Duvarı:** taşınabilir kalkan yere kurulur, 8 sn mermi emer; arkasından ateş edilebilir.
- **Pasif Sağlam:** yüksek can, yaralıyken yavaşlamaz.
- **Güçlü yan:** hat açma, dikkat çekme, kapanışmada önde durma.
- **Zayıflık:** her eylemi ses üretir, sessiz yürüme etkisi yarım. Gizli rotada takımın risk kaynağıdır.

### Yük — Taşıyıcı

- **Q Çanta Fırlat:** atış yayıyla eşya veya veri çekirdeğini bir partnere fırlatır.
- **F Duman/Yem Kutusu:** hedefe duman bulutu veya ses yemi bırakır; düşmanlar yeme gider.
- **Pasif Büyük Çanta:** 8 slot (diğer roller 4). Takımın yedek malzeme deposudur; veri çekirdeğini yalnız o taşıyabilir.
- **Güçlü yan:** kayıp malzemeyi tamamlama, kaçış yolu açma, tahliyenin taşıyıcısı.
- **Zayıflık:** çekirdek taşırken %25 yavaş ve ateş edemez; korunmaya muhtaçtır.

### Göz — Gözcü

- **Q Drone:** drone kamerasına geçilir (ikinci imleç modu); duvar arkasını, tuzakları ve olay ön belirtilerini görür.
- **F Tarama Darbesi:** halka yayılır, düşmanları 4 sn işaretler. Duyan düşmanlar uyarılır; bu bir risk kararlıdır.
- **Pasif Hızlı Kaldırma:** yaralı partneri yarı sürede kaldırır, sessiz etkisizleştirme menzili uzundur.
- **Güçlü yan:** bilgi üretimi, takımı kurtarma, hedef işaretleme.
- **Zayıflık:** düşük can; drone sırasında kendi karakteri savunmasızdır.

### İç içe geçen kombolar

Bir kombo, iki rolün yeteneklerini 3 sn içinde birbirine bağlamasıyla tetiklenir ve **Uyum çubuğunu** doldurur (takım eylemleri bölümünde).

| Kombo | Roller | Etki |
| --- | --- | --- |
| Kör Nokta Kapatma | Göz + Kilit | Göz'ün işaretlediği kameraları Kilit uzaktan hackler |
| Aşırı Yük | Kilit + Kırıcı | Kilit kapıyı hacklerken Kırıcı kapıyı kırar: kapı patlar, odadaki düşmanlar sersemler |
| Taşıma Tankı | Kırıcı + Yük | Kalkan Duvarı taşıma yolunu açar, Yük kalkanın içinde hızlanmadan ilerler |
| Yem Pusu | Göz + Yük | Göz tarar, Yük yem atar; işaretli düşmanlar yemde toplanır |
| Ark Kutusu | Kilit + Yük | Yük kutuyu fırlatır, Kilit elektrikler: alan hasarı ve sersemletme |
| İşaretli Atılış | Göz + Kırıcı | Göz'ün işaretlediği hedefe Omuz Darbesi menzili ve hasarı artı alır |

Eksik rol durumunda: 2 ve 3 kişilik takımlarda rolü olmayan iş, görevde alternatif rota ve özel eşya ile çözülür (örneğin Kilit yoksa kapı yalnız kırılır veya Kilit'in yerine terminal kartı bulunur).

## Operasyon döngüsü

&#91;embedded content: operasyon döngüsü · 7 adım, 1 karar\]

Koridor ile oda arasında bir döngü oluşur; dört oda bitince Çekirdek Odası ve tahliye gelir. Yönetmen hem koridorda hem odalarda olay ekleyebilir.

## Hub koridor ve oda sistemi

Her operasyon tek bir koridorda geçer. Koridor operasyonun omurgasıdır: içinde sabit kalır, tanıdık yer olur; kapıların arkasındaki odalar her seferinde farklıdır. Operasyondan operasyona koridorun kimliği de değişir (örneğin Ofis Katı, Depo Hattı, Havuz Kanadı), böylece her koridor kendi hissini taşır.

### Koridorun yapısı

- **Uzunluk ve kapılar.** Yaklaşık 60-80 m uzunlukta, iki yanda toplam 6 kapı. Başlangıçta giriş noktası, sonda tahliye asansörü.
- **Kapı kartı.** Her kapının üzerinde oda konseptinin ikonu, tehlike seviyesi ve ödül ipucu (kasa sayısı) yazar. Bilgi kısıtlıdır; Göz'ün dronu kapının arkasından daha fazlasını gösterir.
- **Güvenli nokta.** Koridorun belli yerlerinde (kamp) çanta düzenleme, kasa açma, yeniden doğma ve karışım istasyonu bulunur.
- **Koridor olayları.** Yönetmen koridorda da etkilidir: lamba kararması, devriye botu, kapıların kendiliğinden yer değiştirmesi gibi küçük dreamcore değişiklikler. Uyarı verilmez.

### Operasyon yapısı

1. Takım koridora çıkar ve kapı kartlarını inceler.
2. Bir kapı seçilir (takım ping ile oylar, çoğunluk kazanır), oda yüklenir.
3. Oda görevi tamamlanır (3-5 dk), takım koridora döner.
4. Dört oda ve son kapıdaki Çekirdek Odası tamamlanır.
5. Çekirdek taşınarak tahliye asansörüne koşulur; tahliye son kriz ve son kapanışmadır.

Hedef tur süresi 20-25 dakikadır (dört oda yaklaşık 16 dk, Çekirdek Odası yaklaşık 4 dk, tahliye yaklaşık 3 dk). Süreler test sonrasında ayarlanır.

### Oda anatomisi

Her oda elle tasarlanmış bir şablondur ve şu parçaları içerir: giriş, çıkış, hedef, en az iki çözüm yolu, kasa yuvaları, engel yuvaları ve bir olay yuvası. Yuvaların içini rastgele birleşim sistemi doldurur.

### İlk oda konseptleri

Her konseptin bir imza mekaniği vardır; oda adını duyunca oyuncu ne yapacağını hatırlar.

| Konsept | İmza mekaniği | Kapanışma hissi | Dreamcore dokunuşu |
| --- | --- | --- | --- |
| Açık Ofis | Hareketli fotokopi botları, bölme duvarları | Siper ve kanat oyunu | Bitişi olmayan bölme sırası |
| Depo | Forklift botları, kırılabilir koli yığınları | Uzun görüş hatları, pusu | Raflar kendiliğinden yer değiştirir |
| Havuz Odası | Kaygan zemin, elektrikli su | Açık alan, yansıma ışıkları | Su yansıması odanın başka bir halini gösterir |
| Çocuk Odası | Dev oyuncak eşyalar, müzik kutusu tuzağı | Ani baskın | Müzik sustuğunda her şey bir adım yaklaşır |
| Kafeterya | Kaygan zeminli mutfak, otomat kasalar | Kaotik yakın mesafe | Otomat zamanla çok daha fazla ürün üretir |
| Sunucu Odası | Lazer ızgara, hack bulmacası | Dar geçit, tek hat savunma | Soğuk mavi ışık, uzaktan telsiz fısıltısı |
| Asansör Lobisi (son) | Zaman baskılı savunma | Tahliye kapanışması | Asansör müziği bozulur |
| Atrium Serada | Yüksek bitkiler, düşük görüş | Gizlilik ve pusu | Bitkiler pencere gibi davranır |

Prototip için ilk altı konsept yeterlidir (Atrium ve Kafeterya sonraya bırakılabilir).

## Rastgele birleşim sistemi

Sürpriz, rastgele anlamsız oda üretmekten değil, **kurallı parçaların beklenmedik birleşiminden** gelir. Oda yapısı elle tasarlanır; rastgele olan üstüne giren katmanların seçimidir. Böylece her birleşim oynanabilir kalır.

### Katmanlar

| Katman | Ne seçilir | Örnek |
| --- | --- | --- |
| 1. İskelet | Konseptin elle tasarlanmış planı (konsept başına 3 varyant hedefi) | Depo B: iki raf sırası + orta geçit |
| 2. Kaplama | Dekor, ışık paleti, ses katmanı | Sıcak turuncu floresan, uzak müzik |
| 3. Mutatör | Oda kuralını değiştirir (1-2 adet) | Işıklar Kapalı, Kaygan Zemin |
| 4. Engel seti | Dinamik engeller (bkz. dinamik engeller) | Forklift botu, lazer geçidi |
| 5. Ödül seti | Kasa türleri ve loot tablosu | Bir büyük kasa + iki küçük kasa |
| 6. Olay yuvası | Yönetmen sürprizi için boş yuva | Yangın alarmı, devriye dalgası |

### İlk mutatör listesi

- **Işıklar Kapalı:** yalnız fener ve namlu ateşi aydınlatır.
- **Kaygan Zemin:** hareket kayar, atılma mesafesi artar.
- **Yankı Odası:** tüm sesler iki kat uzağa gider.
- **Küçülen Oda:** duvarlar zamanla yaklaşır, çıkış baskısı oluşur.
- **Konveyör Zemin:** zemin periyodik yön değiştirir.
- **Sis:** görüş düşer, ışık çeşitleri ön plana çıkar.
- **Ağır Çekim Bölgesi:** belli alanda hareket yavaşlar, fırlatılan eşyalar daha uzun uçar.
- **Tek Yönlü Kapılar:** geri dönüş yolu kapanır, plan gerekir.
- **Ayna Odası:** yansımalar düşman gibi görünür, gerçek düşmanın konumunu karmaşıklaştırır.
- **Sessizlik:** ateş edilirse alarm değeri iki kat artar.

### Tehlike bütçesi

Her oda bir puan bütçesiyle üretilir. Mutatörler, engeller ve düşmanlar puan harcar; ödül ise bütçe arttırır (daha fazla ödül = daha fazla risk). Bütçe şu faktörlere bağlıdır: koridor derinliği, Protokol seviyesi ve oyuncu sayısı. Bu, ne kadar absürt birleşim çekilirse çekilsin odanın aşırı zor veya boş olmasını engeller.

### Uyumluluk kuralları

- Her mutatör ve engelin etiketleri vardır (örneğin görüş, ses, zemin, elektrik). Aynı etiketten en fazla bir öğe bir odada bulunur.
- Kabul edilemez ikililer elle yasaklanır (Işıklar Kapalı + Sis + gizli lazer gibi okunamaz kombinasyonlar).
- Kontrollü absürt kombinasyonlar bilinçli olarak serbest bırakılır (Kaygan Zemin + Konveyör + büyük kasa); komik ve oynanabilir.

### Garip Oda

Odaların yaklaşık onda biri "Garip Oda" olur: içi dışından büyük, aynı kapıya iki kez giriş, ters sıralı geçit gibi mantık dışı düzen. Kısa ve tamamlanabilirdir, ödülü büyüktür, dreamcore hissinin ana kaynağıdır.

### Doğrulama ve tekrarlanabilirlik

- Tüm seçim tek bir seed ile yapılır; host seed'i paylaşır, aynı seed aynı sonucu verir (günlük meydan okuma temeli).
- Oda yüklendikten sonra otomatik kontroller çalışır: giriş, hedef ve çıkış arasında yol var mı, en az iki çözüm yolu duruyor mu, tehlike bütçesi aşılmadı mı, ödül ulaşılabilir mi. Başarısızsa yeni birleşim çekilir.
- Taban birleşim sayısı: 8 konsept x 3 iskelet x 10 mutatör = 240 (engel, ödül ve olaylar bunu çok daha artırır).

## Dinamik engeller ve sürprizler

Odaların üzerinde iki katman çalışır: **engeller** odaya özgü ve öngörülebilir problemlerdir; **olaylar** ise Yönetmen'in oyun sırasında tetiklediği sürprizlerdir. Her ikisi de bir rolün yeteneğiyle çözülebilir, yeteneğin olmaması yalnız daha zor veya daha gürültülü bir çözüm doğurur.

### Engel türleri

| Engel | Davranışı | Karşı hamleler | Komik sonuç |
| --- | --- | --- | --- |
| Forklift botu | Sabit rotada gider, çarpar | Göz rotayı izler, Yük yemle çevirir, Kırıcı kalkanla durdurur | Bot yemde dönmeye başlar |
| Lazer geçidi | Zamana göre açılır ve kapanır | Kilit kapatır, Kırıcı duvarı kırar (alarm) | Yanlış zamanlamada yeniden başlar |
| Kaygan yüzey | Hareketi kaydırır | Atılma ile kontrollü geçilir | Partnerlere çarpıp kayarlar |
| Sıkışan kapı | Yarım açık kalır | İki oyuncu aynı anda iter (ortak eylem) | Biri bırakırsa kapı geri kapanır |
| Güvenlik kamera ve tareti | Görüş konisi tarar | Kilit hack, Göz tarama, Kırıcı kalkan | Hack'lendiğinde düşman botlara ateş eder |
| Elektrikli su | Yürünmez bölge | Kilit yeniden yönlendirir, Yük eşya köprüsü kurar | Suya basan oyuncu çarpılır ve komik bir sesle zıplar |
| Çöken raf | Devrilen raf yolu kapatır veya açar | İtme ve kırma | Dominolar |
| Çift anahtar kapısı | İki noktada aynı anda basılı tutulur | Oyuncular ayrı noktalara gider | Biri erken bırakırsa kapı bip sesiyle geri kapanır |
| Müzik kutusu tuzağı | Süre dolunca baskın başlar | Susturma etkileşimi | Müzik hafifçe durur, sonra hızlanır |

### Yönetmen

Yönetmen oyun sırasında bir **gerilim puanı** takip eder ve temposunu bu puana göre ayarlar. Girdileri: son olaydan beri geçen süre, takımın can ve mermi durumu, yerdeki oyuncular, üretilen ses, alarm seviyesi ve odada geçirilen süre. Ağırlıklar prototipte ayarlanır.

Tempo döngüsü dört aşamalıdır: **sakin, artan gerilim, tepe, toparlanma**. Bu döngü araştırmadaki iyi tempo kalıbıyla uyumludur (sessiz arama, zorunlu temas, kaçış, toparlanma).

Kurallar:

- İlk iki dakikada tepe olayı yoktur.
- Aynı olay art arda iki kez çıkmaz.
- Takım zayıfken (düşük can, yerde partner, mermi bitti) Yönetmen nefes aralığı verir.
- Takım çok rahat gidiyorsa baskayı artırır.
- Her tehlikeli olayın bir ön belirtisi vardır (kıvılcım, ışık titremesi, anons). Önlenemeyen şey yoktur, ama bazen karşı hamle için süre kısıttır.
- Oda başına en fazla bir büyük ve bir küçük olay; ilk oda daha sakin.

### Olay destesi (ilk set)

| Olay | Ön belirti | Etki | Karşı hamle |
| --- | --- | --- | --- |
| Yangın alarmı fırtınası | Kırmızı ışık titremesi, anons | Fiskıyeler açılır; ıslak zemin ve elektrik | Kilit sistemi kapatır |
| Devriye dalgası | Telsiz sızıltısı | Üç bot koridordan gelir | Kalkan Duvarı, yem, sessiz saklanma |
| Güç kesintisi | Lambalar yanıp söner | Oda karanır, kapılar kilitlenir | Jeneratörü bulup Kilit çalıştırır |
| Yanlış anons | "Kafeterya açıldı" gibi komik anons | Botların bir kısmı yemekhaneye gider | Fırsat: koridoru geçmek |
| Kasa yağmuru | Tavandan gürültü | Birkaçı düşer, herkes koşar | Takım eylemi: kimin hangisini kapacağı |
| Taşınmış kapı | Kapı ikonu söner | Bir kapının arkası değişir | Kapı kartlarını yeniden okumak |
| Kayıp eşya | Çanta hafifçe sallanır | Çantadan rastgele eşya kayar | Yerden toplama koşusu |
| Aşırı ısınma | Terminal uğultusu | Hack süresi kısalır | Soğutma eşyası kullanılır veya işlem yarıda bırakılır |
| İkiz düşman | Ayna kırılma sesi | Bir botun ayna kopyası oluşur | Göz taraması gerçeği ayırt eder |
| Konfeti teslimatı | Parti müziği | Tehlike yok; ufak ödül düşer | Yalnız gülümse |

## Kasa ve loot sistemi

PUBG tarzı kasa fikri bu oyunda iki yerde bulunur: odaların içindeki **sıradan kasalar** ve Yönetmen'in tetiklediği **Düşüş Kasası**. Düşüş Kasası, "herkes önündeki şeyi bırakıp oraya koşsun mu?" sorusuyla hem strateji hem takım eğlencesi üretir.

### Kasa türleri

| Tür | Nerede | Açma yöntemi | İçerik | Risk |
| --- | --- | --- | --- | --- |
| Küçük kasa | Odalarda | E ile açılır | Sıradan eşyalar | Düşük |
| Kilitli kasa | Odalarda | Anahtar kartı veya Kilit'in hack'i | Nadir eşyalar | Orta |
| Ağır kasa | Depo ve Kafeterya'da | İki kişi birlikte taşır veya Kırıcı kırar | Ağır eşya ve modül | Orta, gürültülü |
| Tuzaklı kasa | Göz taramasıyla belirir | Tuzağı önce Kilit ayarlar | Orta eşya | Tuzak komik veya tehlikeli |
| Düşüş Kasası | Yönetmen olayı | Uzun etkileşim (yaklaşık 5 sn basılı tutma) | Epik veya Efsane eşya | Yüksek: ses ve ışık huzmesi düşman çeker |

### Düşüş Kasası akışı

1. **İşaret:** Yönetmen tetikler, tavandan duman işareti ve komik bir sistem anonsu gelir.
2. **Düşüş:** 8-10 saniyelik geri sayım, düşecek yer zeminde işaretlenir; kasa yalnızca odanın riskli bir noktasına düşer.
3. **Karar:** Takım koşar mı, plan mı yapar, yoksa boş mı verir? Tehlike ve ödül düşünülür.
4. **Açma:** E tuşuna basılı tutulur, imleç halkası dolar. Açılma sırasında alarm seviyesi yükselir ve ışık huzmesi düşmanları çeker.
5. **Sonuç:** Eşyalar yere saçılır, takım paylaşır; düşmanlar kasanın konumuna yönelir.

### Rollerin kasa etkileşimi

- **Kilit:** açma süresini yarıya indirir, tuzakı önceden etkisiz hale getirir.
- **Kırıcı:** kasayı çok hızlı kırar ama çok ses üretir.
- **Yük:** İçerikleri otomatik olarak büyük çantaya toplar, ağır kasayı kaldırır.
- **Göz:** tuzakı ve etraftaki düşmanı tarayıp takıma bilgi verir.
- **Ortak açma:** iki oyuncu aynı kasayı birlikte açarsa süre kısalar (ortak eylem).

### Eşya ve nadirlik

Nadirlik dört kademedir: Sıradan, Nadir, Epik, Efsane (renk ve kıvılcım ile ayrılır). Eşya sınıfları:

- **Tüketim:** onarım kiti, kalkan pili, enerji içeceği.
- **Saldırı:** mermi türleri, el bombası, elektrik tuzağı.
- **Yardımcı:** duman, yem, drone pili, ping bayrağı.
- **Modül:** o tur için rol yeteneğini değiştirir (örneğin Hack'i daha hızlı yapan yonga).
- **Garip eşya:** komik etkili, bazen riskli (fırlatınca ters dönen top gibi).

Loot kuralı: kasa içeriği takım içindir; bir kasanın içinde her rolün kullanabileceği bir şey bulunma olasılığı yüksek tutulur. Olasılık ağırlıkları prototipte ayarlanır.

Kasa içindeki eşyalar yalnız o tur boyunca kullanılır; kalıcı ilerleme ayrı sistemdir (bkz. ilerleme).

## Takım etkileşim sistemi

Bu bölüm Sütun 1'in mekanik karşılığıdır: oyuncuların konuşmasını, birbirine yardım etmesini ve birlikte gülmesini sağlayan araçlar.

### Ping ve iletişim

- **Ping tekeri** (orta tık veya Alt): Buraya gel, Tehlike, Eşya, Hack gerek, Kasa, Bekle, Ben yaparım, Yardım.
- **Bağlamsal ping:** bir nesneye ping atmak onu işaretler (terminale ping = "bunu hackle"), partnere görünür ve rolüne özel bir ipucu çıkarır.
- **Sesli sohbet:** Steam ses sohbeti; isteğe bağlı yakın ses (uzaklaşınca ses kısılır). Ping sistemi sesli sohbet olmadan da oynanabilmeyi sağlar.
- **Karar anları:** kapı oylaması, kasa kararı ve tahliye zamanı için "Hazır" ping'i kullanılır.

### Ortak eylemler

| Eylem | Nasıl çalışır | Neden eğlenceli |
| --- | --- | --- |
| İki kişilik itme | Sıkışan kapı veya ağır nesneyi iki oyuncu aynı anda iter | Biri bırakırsa nesne geri gelir |
| Çift anahtar | İki oyuncu iki ayrı noktada aynı anda basılı tutar | Zamanlama ve iletişim gerekir |
| At ve yakala | Yük çantayı fırlatır, partner yakalar | Kaçırılan eşya komik sonuç verir |
| Sedye | İki oyuncu yere düşenü taşır | Hareket yavaşlar, başka biri korumalıdır |
| Yükselt | Bir oyuncu diğerini yüksek rafa fırlatır | Yeni rota açar |
| Ortak kasa açma | İki oyuncu aynı kasayı birlikte açar | Açma süresi kısalır |
| Kalkan arkası ateş | Kırıcı'nın Kalkan Duvarı arkasından herkes ateş eder | Pozisyon dayanışması |

### Kurtarma (Yeniden Başlatma)

- Can sıfıra düşerse karakter **"Sistem Çöktü"** durumuna girer: yerde kalır, ölmez. Yalnızca ping atabilir ve sürünebilir.
- Partner E'ye basılı tutarak kaldırır (yaklaşık 3 sn; Göz yarı sürede kaldırır). Süre dolarsa karakter en yakın güvenli noktada yeniden doğar ve bir eşya kaybeder.
- Bir takım yerlerde kalkıp çökünce son güvenli noktaya dönülen kısıtlı sayıda "Yeniden Başlatma Hakkı" vardır. Sayılar ilk öneridir, test sonrası ayarlanır.
- Yerde kalan oyuncu izleyici olur ve partnerinin kamerasını görebilir (ölümü izlenebilir yapma ilkesi).

### Eşya aktarımı

- İmleç partnerin üzerindeyken sol tıkla seçili eşya verilir.
- Yük eşyayı uzaktan fırlatabilir.
- Kasa içeriği yere saçılır; ping ile "bunu sen al" işareti verilir.

### Uyum çubuğu ve Takım Hamlesi

Roller arası kombolar ve ortak eylemler takımın **Uyum çubuğunu** doldurur. Çubuk dolunca dört (veya mevcut) oyuncu birlikte yakınken **Takım Hamlesi** tetiklenebilir: kısa bir süre (yaklaşık 6 sn) takımın gürültüsü sıfırlanır, hızı artar ve yetenek bekleme süreleri sıfırlanır. Birlikte oynamak böylece açık bir ödül alır.

### Sürtüşme ve dost ateşi

Dost ateşi yoktur (çift dostu). Bunun yerine **fiziksel sürtüşme** vardır: itme, kayma, çarpışma ve fırlatılan eşyalar komik anlar yaratır ama zarar vermez.

### Tur sonu özeti

Tur biterken Yönetmen ve oyun kaydı en gürültülü, en riskli, en iyi kurtarıcı ve en sürprizli an gibi unvanları özetler; oyuncular bu anları birlikte gülüp konuşur.

## Düşmanlar, algılama ve alarm

Düşmanlar güvenlik droidleri ve botlardır (kan yok; yenilince kıvılcım ve parça düşer). Algılama (ne gördü, ne duydu) ile davranış (ne yapacak) ayrı sistemlerdir.

### Düşman türleri

| Tür | Davranış | Zayıf nokta | Karşı hamle |
| --- | --- | --- | --- |
| Devriye botu | Sabit rota, görüş konisi, şüphe LED'i | Arkası | Göz veya Kilit sessiz etkisizleştirir |
| Kalkanlı bot | Önünde kalkan, yavaş | Arkası ve elektrik | Kilit sersemletir, Kırıcı iter |
| Telsiz botu | Takviye çağırır | Konuşmadan önce susturulursa işe yaramaz | Göz işaretler, herhangi biri susturur |
| Tarayıcı dron | Uçar, ışık konisi tarar | Hack | Kilit hackler |
| Temizlik ve forklift botu | Çevresel tehlike, rotalı | Yem | Yük yemle çevirir |
| Güvenlik Şefi (Çekirdek Odası) | Fazlı, ağır | Fazlar arası açık nokta | Dört rolün koordinasyonu gerekir |

### Algı kanalları

- **Görüş:** koni ve raycast; duvar arkasını görmez.
- **Ses:** her eylem bir ses olayı üretir (adım, atılma, ateş, kasa açma); yarıçap duvar ve kapı malzemesine göre kısılır.
- **Işık:** fener ve namlu ateşi fark edilme olasılığını artırır (görmek ve görünmemek arasında seçim).
- **İz:** açık bırakılmış kapı, etkisizleştirilmiş bot, kırık kamera şüphe puanını artırır.

Her bot 0-100 arası bir şüphe puanı tutar. Puan LED rengiyle gösterilir (yeşil, sarı, kırmızı) ve kafasının üstünde kısa komik ses/ikon çıkar ("hm?" balonu). Böylece oyuncu arayüz kullanmadan durumu okur.

### Davranış durumları

`PATROL`, `INVESTIGATE`, `SUSPICIOUS`, `ENGAGED`, `SEARCH` ve `RETURN_TO_PATROL`. Bilgi telsiz, kamera ve görüş hattıyla yayılır; düşmanlar birbirinin zihnini okumaz.

### Alarm seviyeleri

| Seviye | Ad | Etki |
| --- | --- | --- |
| 0 | Sessiz | Normal devriye |
| 1 | Şüpheli | Devriye daha sık bakar |
| 2 | Alarm | Takviye botlar gelir |
| 3 | Kilitleme | Bazı kapılar kapanır |
| 4 | Tahliye modu | Çekirdek alındıktan sonra, geçici çıkış koşusu |

Alarm zamanla düşer; Kilit terminalden hızlıca düşürebilir. Alarm sadece daha fazla bot demek değildir: rota ve kapı düzeni de değişir (kriz sistemi).

### Kriz yapısı

Her kriz beş parçadır: tetikleyici, ön belirti, sonuç, karşı hamle, kalıcı etki. Oyuncu krizi her zaman önleyemez ama sonucunu etkileyebilir.

## Çatışma ve silah hissi

Çatışma, nişanın imleçle doğrudan kontrol edildiği, kısa ve yoğun anlardır. Üstün amacı çatışmanın çok sık değil, çok aklında kalan olmasıdır.

### Rol silahları

| Rol | Ana silah | Karakter |
| --- | --- | --- |
| Kilit | Şok tabancası | Kısa menzil, sersemletir, öldürmez |
| Kırıcı | Pompalı | Kısa menzil, güçlü, çok gürültü |
| Yük | Hafif tabanca | Çekirdek taşırken kullanılamaz |
| Göz | Sessiz karabina | Uzun menzil, sessiz, az mermi |

Silah değiştirme kasalardan gelen modüllerle kısmı olarak olur. Mermi sınırlıdır ve paylaşım gerektirir.

### Hissi oluşturan parçalar

- **Nişan halkası:** halka genişliği isabet konisidir, hareketle ve geri tepmeyle genişler.
- **Geri tepme ve kamera:** her atış kısa kamera sarsıntısı ve karakter animasyonu verir.
- **Vuruş geri bildirimi:** kıvılcım, parlak vuruş işareti, kısa vuruş duraklaması (hit-stop).
- **Ses katmanları:** namlu, ortam yankısı, mermi kovanı, vuruş sesi ayrı katmanlar.
- **Namlu ışığı:** her atış odaya kısa ışık verir; hem görsel şölen hem konum ele verme.
- **Siper:** alçak, yüksek ve kırılabilir siper; Kırıcı kalkanı taşınabilir siper görevi görür.
- **Atılma:** kısa bekleme süreli, kurtulma ve konum değiştirme aracı.

### Düşman tepkisi

Düşmanlar siperden ateş eder, yandan dolanır, bastırma ateşi yapar, kalkanla ilerler ve telsizle takviye çağırır. Işığı hedefleyebilirler: fener veya namlu ateşi onların çekicisidir.

### Sessiz etkisizleştirme

Bota arkadan yaklaşıp E'ye kısa basılı tutmak; imleç hançer ikonuna dönüşür. Göz'ün menzili uzundur. Sessiz yöntem hem ses üretmez hem şüphe puanını çok az artırır.

### Can ve zarar

Karakterin canı ve yeniden dolan bir kalkan pili vardır. Can sıfıra düşene kadar kalkan önce hasarı emer. Sayılar prototip sırasında ayarlanır.

### Ton

Kan ve gerçekçi vahşet yoktur. Düşman botlar kapanır, kıvılcım ve parça düşer; oyuncu düşerse "Sistem Çöktü" animı oynar. Mekanik risk gerçek, görsel şiddet hafiftir.

## İlerleme ve ödüller

İlerleme yalnızca silah gücünü artırmaz; yeni taktikler açar ve oyuncuya özgü bir kimlik verir. Kalıcı güç artışı yoktur: eski oyuncu yeni oyuncunun deneyimini bozmaz.

### Üç kanal

- **Operasyon ustalığı:** sessiz tamamlama, kaypsız tahliye, alternatif rota keşfi gibi madalyalar ve istatistikler.
- **Teçhizat ve hazırlık:** tur sonunda **Parça** (kalıcı para birimi) kazanılır. Koridor mağazasında rol modüllerine ve yeni eşya tohumlarına harcanır. Her rolün üç seçenekli küçük bir modül ağacı vardır.
- **Protokol meydan okumaları:** günlük seed, özel kontratlar ve arkadaşla tamamlanan çift görevleri.

Kasadan çıkan eşyalar yalnız o tur kalır; kalıcı olan yalnız Parça, modüller ve kozmetiklerdir.

### Protokol seviyeleri

Sekiz seviye hedeflenir. Her seviye operasyona bir sertleştirici ekler (daha sık telsiz botu, daha kisa Yönetmen nefes aralığı, ek mutatör). Seviye 1 öğretici ve yumuşaktır; sert ton yalnız üst seviyelerde artar. İlk sürümde bir ila üç seviye yeterlidir.

### Kozmetik

Kostüm, çanta, boya, drone görünümü, emote ve imleç stili. Kozmetikler güç vermez ve ilerleme hissini görsel olarak verir.

### Çift başarımları

Birlikte kazanılan başarımlar (örneğin ilk Düşüş Kasasını birlikte açmak, kimse yere düşmeden tur bitirmek) takımın ortak profiline yazılır.

## Arayüz ve erişilebilirlik

Arayüz iki katmandır: dünya içine yerleşik bilgi (diegetik) ve imleç. Tam HUD'suz değil, **minimum ve okunabilir** bir ekran hedeflenir; oyuncu canını, mermisini ve alarm durumunu hiçbir zaman yanlış anlamamalıdır.

### Bilgi katmanları

| Bilgi | Nerede gösterilir |
| --- | --- |
| Can ve kalkan | Karakterin sırtındaki LED + küçük halka göstergesi |
| Mermi | Silah üzerinde LED + imleç halkasında kalan mermi dilimleri |
| Yetenek (Q, F) | Ekranın altında küçük ikonlar ve bekleme halkası |
| Partner durumu | Ekran kenarında küçük halkalar (yerdeki partner için ping işareti) |
| Şüphe ve alarm | Bot LED rengi, ışık, telsiz anonsu, alarm seviyesi sesi |
| Görev | Bilek ekranı (Tab) ve kapı üzerindeki işaretler |
| Kapı bilgisi | Kapı kartı (ikon + tehlike + ödül ipucu) |

### Okunabilirlik

- Karanlık atmosfer korunur; ancak etkileşilebilir nesneler hafif çerçeve ışığı ile işaretlenir.
- Karakter silueti ve düşman silueti her zaman ayrı seçilebilmelidir (okunabilirlik testi).
- Dünya işaretleri (ping, kasa, hedef) duvarın arkasından da görünür.

### Erişilebilirlik

- Renk körü dostu semboller (renge ek olarak şekil ve ikon).
- Parlama ve bloom azaltma, titreme azaltma, ışığa duyarlılık uyarısı.
- Ses yönü göstergesi ve altyazılar.
- Basılı tutma yerine açma/kapama seçeneği.
- İmleç boyutu ve rengi ayarı.
- Tuş atamaları serbest.
- Erişilebilirlik yardımları: daha uzun hack penceresi, daha yavaş tehlike zamanlayıcıları.

## Teknik mimari (Godot 4)

Her sistem tek sorumluluğa sahip, veri odaklı parçalara ayrılır. Roller, silahlar, eşyalar, mutatörler, engeller ve olaylar kodun içine gömülmez; Godot Resource (`.tres`) dosyalarıdır. Yeni bir olay eklemek yeni bir `.tres` dosyası ve küçük bir betik demektir.

### Autoload sistemleri

| Sistem | Görevi |
| --- | --- |
| `GameState` | Tur durumu, alarm, görev ilerlemesi |
| `NetworkManager` | Host/client, seed paylaşımı, Steam bağlantısı |
| `RoomDirector` | Seed ile oda birleşimi, bütçe, doğrulama |
| `EventDirector` | Yönetmen: gerilim puanı, olay destesi |
| `CursorManager` | İmleç durumu ve çizimi |
| `InteractionSystem` | Etkileşim, ortak eylem, kasa açma |
| `LootSystem` | Loot tabloları, nadirlik |
| `AudioBus` | Ses olayları, reverb, ses yayılımı |

### Fare, imleç ve bakış

- Donanım imleci gizlenir; imleç bir `CanvasLayer` üzerinde kendi çizimimizle yapılır (halka genişlemesi, doluma göre ilerleme ve durum ikonları bu yöntemle kolaydır).
- Bakış yönü: kameradan fare konumuna bir ışın atılır (`Camera3D.project_ray_origin` ve `project_ray_normal`), zemin düzlemiyle kesişim noktası karakterin bakacağı yerdir.
- Etkileşilebilir nesne seçimi: aynı ışınla fizik sorgusu ("Interactable" katmanı) ve menzil kontrolü.
- `CursorManager` bir durum makinesidir: `IDLE`, `WEAPON`, `THROW`, `INTERACT`, `INTERACT_BLOCKED`, `PARTNER`, `PING`, `TARGET_ABILITY`, `ENEMY`, `SILENT_TAKEDOWN`. Durumları oyuncunun elindeki eşyadan, hover edilen nesneden ve menzilden hesaplanır.

### Oda üretimi

`RoomDirector` seed'den oda planını üretir. Aşağıdaki kısa kod örneği akışı gösterir; gerçek kod Faz 3'te yazılır.

```gdscript
func build_room(seed: int, depth: int, players: int) -> RoomPlan:
    var rng := RandomNumberGenerator.new()
    rng.seed = seed
    var budget := compute_budget(depth, players)
    var plan := RoomPlan.new()
    plan.concept = pick_weighted(concepts, rng)
    plan.layout = pick(plan.concept.layouts, rng)
    plan.mutators = pick_mutators(plan.concept, rng, budget)
    plan.hazards = fill_slots(plan.layout.hazard_slots, plan, rng, budget)
    plan.loot = fill_loot(plan.layout.loot_slots, rng)
    if validate(plan):
        return plan
    return build_room(seed + 1, depth, players)
```

Oda şablonu bir `.tscn` dosyasıdır ve `Entrance`, `Exit`, `Objective`, `HazardSlots`, `LootSlots`, `EventSlot`, `EnemySpawns` düğümlerini içerir. Doğrulama `NavigationServer3D` ile yol kontrolü yapar.

### Ağ

- **Host yetkilidir:** hasar, görev, alarm, düşman davranışı, kasa içeriği ve Yönetmen host'ta hesaplanır. Client girdi ve istek yollar ("kasayı açmak istiyorum"), host mesafeyi ve koşulları doğrular.
- Nişan yönü client'ta hesaplanır ve host'a düzenli aralıklarla gönderilir.
- `MultiplayerSpawner` ve `MultiplayerSynchronizer` oyuncu ve düşman eşlemesi için kullanılır; sık değişen (konum) ve seyrek değişen (görev) veri ayrı tutulur.
- Geliştirmede ENet ile localhost; Steam için GodotSteam + `SteamMultiplayerPeer` (Faz 6).
- Test: 2, 3 ve 4 oyuncu; bağlantı kopması ve yeniden bağlanma.

### Görsel ve performans

- Forward+ renderer, glow ve emissive materyaller (parlak neon hissi), hacimli sis düşük yoğunlukta.
- Gölgeli ışık bütçesi: odada en fazla dört altı gölgeli ışık; namlu ışıkları havuzdan alınır.
- Odalar kullanılmadığında bellekten atılır. Hedef: orta seviye PC'de 60 FPS.

### Otomatik testler

Seed taraması: yüzlerce seed ile oda üretip doğrulama çalıştırılır (ulaşılabilir hedef, çıkış, bütçe). Başarısız seed'ler kayıt altına alınır.

## Zorluk ölçekleme

Oyun 2, 3 ve 4 kişiyle tam oynanabilir olmalıdır; çift olarak oynayanlar da eksiksiz bir deneyim almalıdır.

| Oyuncu | Rol düzeni | Ölçekleme |
| --- | --- | --- |
| 4 | Dört rol | Taban tehlike bütçesi |
| 3 | Üç rol, biri boşta | Eksik rolün işi kasa modülleri ve alternatif rotayla çözülür; bütçe düşür |
| 2 | İki melez rol: **Teknik Gözcü** (Kilit + Göz), **Baskın Taşıyıcı** (Kırıcı + Yük) | Her melez iki rolün birer yeteneğini alır (düşük güçte); bütçe daha da düşer, Yönetmen nefes aralığını artırır |
| 1 | İlk sürümde yok | Sonraki sürümde yapay zekâ partner ile düşünülür |

Ölçekleme parametreleri şunlardır: düşman sayısı, kasa sayısı, alarm artış hızı ve Yönetmen aralığı. Çarpanlar prototipte test edilerek ayarlanır.

Bağlantı kuralı: bir oyuncu düşerse karakteri bot olmaz; takım bir kişi eksik devam eder ve yeniden bağlanma için kısa bir pencere açık kalır. Host düşerse ilk sürümde tur biter.

## Yol haritası ve ilk prototipin kapsamı

&#91;embedded content: yol haritası · 7 faz, her birinin çıkış kriteri\]

Fazlar tarih değil, çıkış kapılarıdır. Faz 4 sonunda ilk oynanabilir dikey dilim hazır olur; Faz 5 ve 6 bunun üzerine cila ve Steam ekler.

### Dikey dilimin kapsamı

- 1 koridor, 6 oda konsepti (her biri 1-2 iskelet), 6 mutatör.
- 4 rol, kombolar ve Uyum çubuğu.
- 3 düşman türü ve Güvenlik Şefi.
- Yönetmen ve yaklaşık 5 olay, bir Düşüş Kasası.
- İmleç sistemi, ping, kurtarma.
- 2, 3 ve 4 oyuncu, ENet ile yerel ağ.

### Kapsam dışı (sonraya)

Solo mod, kozmetikler, günlük seed, üst Protokol seviyeleri, ek koridor kimlikleri, Steam entegrasyonu (Faz 6).

## Açık sorular

Aşağıdakiler için belgede önerilen bir varsayılan yazılıdır. Farklı istediğin yeri yorumla; ona göre güncelleyelim.

1. **Koridor yorumu.** "Tek farklı koridor" ifadesini şöyle yorumladım: her operasyonun kendi koridoru ve kimliği var, içinde sabit kalıyor, odalar değişiyor. Yoksa her turda koridorun kendisi de mi tamamen değişsin?
2. **Ton.** Yumuşak-gergin ton seçildi. "Sert mod" ileride seçenek olsun mu, yoksa hiç olmasın mı?
3. **Hareket.** WASD + fare nişan seçildi (nişan odaklı olduğu için). LoL'deki gibi sağ tıkla gitme istiyor musun?
4. **İki oyuncu modu.** Melez roller (Teknik Gözcü, Baskın Taşıyıcı) uygun mu?
5. **Solo.** İlk sürümde yok. Bu kabul edilebilir mi?
6. **Yakın ses sohbeti.** Varsayılan açık mı, kapalı mı olsun?
7. **Düşüş Kasası sıklığı.** Her turda bir tane mi, yoksa nadir olay mı?
8. **Kimlik cümlesi.** "Planı yap. Plan bozulsun. Birlikte doğaçlayıp çık." uygun mu?

## Kaynaklar

Belgede kullanılan araştırma, aşağıdaki açılan ve okunan sayfalara dayanır (21 Ekim 2026'da erişildi).

- [R.E.P.O. — Wikipedia](https://en.wikipedia.org/wiki/R.E.P.O.)
- [10 Best Co-op Games on Steam in 2026, Ranked by Session Shape — GameGeeker](https://gamegeeker.com/editors-picks/best-co-op-games-on-steam)
- [Co-op Game Design in 2026 — Cinevva](https://app.cinevva.com/guides/co-op-game-design)
- [How Co-op Mechanics Turn Teamwork Into the Main Event — Co-Optimus](https://www.co-optimus.com/blog/article-poster/3388/how-co-op-mechanics-turn-teamwork-into-the-main-event.html)
- [10 Best Co-op Games to Experience With a Partner — Esports.net](https://www.esports.net/news/gaming/best-coop-games/)
- [How Evolve learned from Left 4 Dead's AI director — Shacknews](https://shacknews.com/article/82787/how-evolve-assures-action-peaks-and-valleys)
