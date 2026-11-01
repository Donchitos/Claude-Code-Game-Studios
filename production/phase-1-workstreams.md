# Faz 1 — İki geliştiricili çalışma planı

2026-10-27 • Kullanıcı görev dağılımını ve başlangıç altyapısını onayladı. Oyun mekaniklerinin ayrıntılı tasarım/yazma onayı her görevde ayrıca alınır. Çekme türü henüz seçilmedi.

## Tek görev kaynağı ve sınırlar

Sahiplik, dal, bağımlılık, yazma kapsamı, uzmanlar ve kabul ölçütleri [görev manifestinde](<../.sdlc/phase1_tasks.json>) tutulur. İnsanların açılışta farklı görevleri otomatik sahiplenmesi yerine, **önceden atanmış sıradaki hazır görev** gösterilir. Hiçbir görev bu kurulumla tamamlanmış sayılmaz; mevcut kod önce doğrulanır. Manifest `revision` değeri sahiplik/durum/kapsam değişikliklerinde artırılır ve iki geliştirici aynı sürümü kullandığını doğrular.

Bu bir görev yönlendirme protokolüdür; editör/işletim sistemi yazma engeli veya GitHub senkronizasyon servisi değildir. Başlangıç aracı ajan başlatmaz, kod yazmaz, dal değiştirmez, stash/reset/commit/push veya GitHub Issue oluşturmaz. Başlangıç çıktısındaki `can_write`, sadece yerel protokol ön kontrolüdür; kullanıcı onayını, yerel oturum rezervasyonunu ve diğer clone güncelliğini garanti etmez.

## Sahiplik

| Geliştirici | Sorumluluk |
|---|---|
| **alicomert** | Oyuncu/hareket/kamera, silah/hasar/hissiyat, girdi/imleç/HUD, Kırıcı/Göz, kurtarma/yardımcı, takım komboları, erişilebilirlik; **tek ortak entegratör** |
| **okanipk** | Etkileşim, envanter/eşya, taşıma/fırlatma/yakalama, Kilit/Yük, kasalar/loot, AI/alarm/Şef, engeller/gaz odası, üretim/mutatörler, Yönetmen/olaylar ve kısa senaryo |

[Laboratuvar kodu](<../src/lab/mechanics_lab.gd>), [laboratuvar sahnesi](<../src/lab/mechanics_lab.tscn>), [girdi/proje ayarları](<../project.godot>) ve [ortak kural tipi](<../src/data/lab_rules.gd>) yalnız **P1-I01/P1-I02** entegrasyon görevlerinde değiştirilir. İki kişi aynı ana sahnede çalışmaz. Ortak bağlantı gerektiren modül, API/sinyal/parametre listesi ve ayrı test düzeneğiyle entegratöre teslim edilir.

Her iki hattın görevleri aynı geliştirici tarafından sırayla yürütülür. Başka bir geliştiricinin kapsamına ihtiyaç varsa kapsamı sessizce büyütme; manifest revizyonu ve açık onay iste. Alt ajanlara da aynı görev kapsamında ayrık alt dosyalar verilir; araç desteklemiyorsa sıralı çalışılır. Manifestteki roller gerçek ajan tanımlarına referanstır, otomatik dispatch değildir.

## İlk çalışma

### Her bilgisayarda bir kez

```powershell
# Ali'nin clone'unda:
git config --local sdlc.developer alicomert
# Okan'ın clone'unda bunun yerine:
git config --local sdlc.developer okanipk

# Yeni clone'da yerel kilit kaydı yoksa, açık kurulum komutu:
python -B tools/sdlc/locks.py init
```

Var olan kayıtta `init` yeniden çalıştırılmaz; var olan veya bozuk dosyayı üzerine yazarak temizlemez. Yerel kilit kaydı Git'ten hariçtir. `git user.name` GitHub kullanıcı adı veya oturum kimliği olarak kullanılmaz. `--developer`, `SDLC_DEVELOPER` ve yerel Git ayarı arasında farklı değer varsa başlangıç durur; bu değerler beyan edilen kimliktir, kimlik doğrulama değildir.

### Her oturumda

```powershell
python -B tools/sdlc/runner.py start
# Makine tarafından okunur alternatif:
python -B tools/sdlc/runner.py preflight --json
# Bir defalık açık kimlik (diğer kimlik kaynaklarıyla çelişmemeli):
python -B tools/sdlc/runner.py start --developer okanipk
```

İlk adaylar: **alicomert → P1-A01**, **okanipk → P1-O01**. Başlangıç dalı görev dalıyla eşleşmiyorsa yazma durur. Dal oluşturma/kayıtlı değişiklik taşıma komutları kendiliğinden çalıştırılmaz.

**Mevcut çalışma kopyasında main üzerinde kaydedilmemiş önceki değişiklikler var.** Bu kurulum bunları korur ve oyun geliştirmesini başlatırken `BLOCKED` gösterir. İki bilgisayarın aynı başlangıç sürümüne ulaşması için bu değişikliklerin gözden geçirilip ayrı kullanıcı talimatıyla commit/push edilmesi veya açıkça onaylı bir aktarım yapılması gerekir. Yalnız HEAD'den yeni worktree açmak, kaydedilmemiş bu dosyaları taşımaz. Partnerin henüz görmediği yerel manifesti ortak plan sanmayın.

### Hazır görevden geliştirmeye

1. Başlangıç çıktısından görev/branch/kapsam/bağımlılıkları oku. [Mekanik kapsamını](<phase-1-mechanics.md>) ve görev kabul ölçütlerini aç.
2. Gerekli intent/spec/plan ve **tam dosya listesini** sun; mevcut açık tasarım kararlarını kullanıcıyla netleştir. Dağılım onayı mekanik tasarım onayı değildir.
3. Uygun dal ve temiz/yalnız görev kapsamındaki çalışma ağacında, benzersiz oturum kimliğiyle yerel rezervasyon al. Örnek yalnız P1-A01'in bir alt kapsamıdır:

```powershell
$env:SDLC_SESSION = "alicomert-p1-a01-oturum-1"
python -B tools/sdlc/locks.py acquire --dev alicomert --session $env:SDLC_SESSION --scope "src/player,src/camera" --title "P1-A01"
# Oturum sonunda yalnız kendi dev+session kaydını bırak:
python -B tools/sdlc/locks.py release --dev alicomert --session $env:SDLC_SESSION
```

4. TDD, motor referansı, dış veri ve enjeksiyon kurallarına göre yalnız onaylı kapsamı uygula. Ana sahne ihtiyacını entegrasyon kuyruğuna gönder.
5. Birim, entegrasyon ve gerçek pencereli hissiyat testlerini ayrı kaydet. Odak/girdi yüzünden çalışmayan test `NOT ASSESSED`; atlanan test başarı değildir. Mevcut genel Godot test çalıştırıcısı klavye testini sessiz hariç tutar; tam Faz1 kanıtı sayılmaz.
6. Entegratör modül sözleşmesi, temizleme/reset, test kanıtı ve kapsamı inceleyip entegrasyon görevinde bağlar. `done` için kanıt zorunlu; öznel hissiyat ve Faz2 geçişi ayrıca kullanıcıya aittir. Durum/kanıt manifest düzenlemesi ayrı koordinasyon değişikliğidir; oyun görevinin scope'u otomatik genişlemez.

## Tam kapsam eşlemesi

| Faz1 satırları | Görevler |
|---|---|
| P1-01 hareket/zıplama/kamera | A01; I01, I02 birlikte regresyon |
| P1-02 silah/hasar/siper/hissiyat | A02, A04; I01 |
| P1-03 Kilit/Yük | O03, O04 |
| P1-03 Kırıcı/Göz | A05; A06 hızlı kaldırma bağlantısı |
| P1-04 imleç | A03 |
| P1-04 etkileşim/envanter/slot/toplama/bırakma/aktarma | O01, O02 |
| P1-04 kasalar | O05 |
| P1-04 eşya kategorileri | O02; O03 fizik, O04 rol etkileri |
| P1-05 algı ve AI türleri/durumları | O06 |
| P1-05 alarm/Şef | O07 |
| P1-06 engeller; kullanıcının eklediği gaz odası korunur | O08 |
| P1-06 mutatör/üretim/Garip Oda | O09 |
| P1-06 Yönetmen/olaylar | O10, O11 |
| P1-07 ortak eylemler | O03 at-yakala, O08 nesne tarafı; A06 yardımcı, A07 takım |
| P1-07 kurtarma | A06 |
| P1-07 takım/6 kombo/3sn/Uyum/Takım Hamlesi/ping/hazır | A07 |
| P1-07 sürtüşme/dost hasarı yok/softlock önleme | O08, A02, I02 |
| P1-08 birleştirme/güvenli nokta/özet | O13, I02 |
| P1-08 erişilebilirlik | A08; tüm modül kabul testleri ve I02 |
| P1-08 dış veri/yeniden kurma/rol-eşya-düşman-olay seçimi | Her modül kendi verisini üretir; I02 ortak kontrol paneli |
| Kullanıcının çekme isteği | O12 **tasarım kararı bekliyor** |

Önceki kapsamdan kaldırılmış engel/ortak eylemleri GDD'den otomatik geri getirmeyin. P1 kapsam listesi ve kullanıcının güncel kararı esas alınır. Space=zıplama, genel atılma yok; Kırıcı'nın role özgü Omuz Darbesi ayrı. Güncel doldurma yolu son mermi veya R ile 2 saniyedir; laboratuvar sınırsız mermi varsayılanı ile F7 sınırlı örnek birbirinden ayrıdır. Nihai sanat/production ses tamamlandı varsayılmaz.

## Açık kararlar ve bağımlılıklar

O04 çekirdek taşıma/fırlatma/eksik rol; A06 sürünme–izleyici–süre; O09 mutatör istisnası; O11 aşırı ısınma; O12 çekme türü **blocked** tutulur. Bunlar tüm hattı durdurmaz: başlangıç, silah, etkileşim, envanter ve bağımsız dünya modülleri ilerleyebilir. Son entegrasyon açık kararlar çözülmeden kapanmaz. Yeni tasarım kararından sonra status/open_questions güncellenir, revision artırılır, iki kişi onaylar.

Yönetmen için mevcut hook tam teslim değildir: ilk 120 saniye tepe yasağı, olay tekrar/oda limitleri, zayıf takıma nefes aralığı ve gerçek dünya tüketicileri O10/O11 kabul testleridir. Sinyal varlığı gerçek kasa/olay veya doğru tempo kanıtı sayılmaz.

## GitHub ve diğer AI araçları

[GitHub görev şablonu](<../.github/ISSUE_TEMPLATE/sdlc_task.md>) manifest ID/revision/owner/branch/scopes ile doldurulur; henüz gerçek Issue açılmadı ve tüm `issue_url` alanları null. Issues görünürlük verir, transaction lock değildir. Ayrı clone güncelliği ağ sorgulanmadan `unknown` raporlanır. İki geliştirici baseline ve manifest revizyonunu iletişim/PR incelemesiyle doğrular.

Claude Code için mevcut [SessionStart hook'una](<../.claude/hooks/session-start.sh>) sınırlandırılmış salt okunur başlangıç çağrısı eklenmiştir; gerçek native açılış davranışı ayrıca doğrulanmalıdır. Diğer araçlarda [AGENTS kuralları](<../AGENTS.md>) ve aynı komut kullanılır; native hook/ajan yeteneği varmış gibi davranılmaz. Hook başarısız/timeout/Python eksikse oyun kaynaklarına yazmadan elle başlangıcı düzelt.

## Altyapı test komutu

```powershell
python -B -m unittest discover -s tools/sdlc -p test_startup.py -v
```

Bu testler yönlendirme/yerel koordinasyonu sınar; Godot oynanışının, gerçek co-op'un veya hissiyatın onayı değildir. Windows dışında ayrıca çalıştırılmadan platform doğrulaması iddia edilmez.
