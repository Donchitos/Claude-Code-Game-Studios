# Quick Design Spec: Dönüş tepkisi ve zıplama

**Type:** Addition + Tuning
**System:** P1-01 hareket/kamera
**GDD Reference:** [game-brief.md](../game-brief.md) — İlk teslimin kabul koşulları (bu sistemin ayrı GDD'si ve systems-index'i yok).
**Date:** 2026-10-22
**Onay:** Kullanıcı karakter dönüş hızını seçti; taslağı ve zıplama animasyonunu açıkça onayladı.

## Change Summary

Karakterin fareye dönme tepki katsayısı %40 azaltılır: 22 → 13,2. Hareket hızı ve kamera kenar kayması değişmez. Zıplama, kontrol laboratuvarının kritik bir parçası olarak eklenir.

## Motivation

Kullanıcı mevcut dönüşü hızlı buldu ve zıplamayı Faz 1'e dahil etti. Amaç platform oyunu yapmak değil; alçak engelleri anlaşılır, yeterli ve tekrarlanabilir bir sıçrayışla aşmak. Nihai iskelet/animasyon asset'i yerine mevcut sade karakterde prosedürel kalkış, uçuş ve iniş pozu kullanılacak.

## Design Delta

Özetin önceki kabul koşulu:

> Shift yavaşlatır; Space süre/bekleme sınırlı atılır; duvarların içinden geçmez.

Yeni kural: Space ile yerdeyken tek zıplama başlatılır; Shift ile süre/bekleme sınırlı atılma yapılır; Ctrl ile sessiz yürüme yapılır. Atılma sırasında ve aynı anda dash+jump durumunda zıplama kabul edilmez. Havada ikinci zıplama ve basılı tutarak otomatik hoplama yoktur. Hava yönlendirmesi normal WASD ile sürer; havada atılma dikey hızı silmez. Zıplama dokunulmazlık vermez.

## New Rules / Values

- `turn_sharpness=13.2`: üstel yumuşatma `w=1-exp(-k*dt)`. %40, açısal hız tavanı değil bu tepki katsayısına uygulanır.
- `jump_height=1.0 m`, `gravity=24 m/s²`, ilk hız `sqrt(2*g*h)` ≈6,93 m/s. Aynı seviyeye ideal uçuş ≈0,58 sn; sabit fizik adımında toleranslı değerlendirilir.
- Yere iniş/çarpışma Godot CharacterBody3D tarafından belirlenir. Sıfırlama düşey hız ve zıplama durumunu temizler.
- Kamera havadaki gövde yüksekliğini değil son yer temasının yükseklik referansını izler. Platforma inildiğinde yeni yüksekliğe yumuşak geçer; yatay takip ve kenar kayması korunur.
- Kalkışta kısa esneme, yükseliş/düşüşte hız bazlı poz, inişte sıkışma/toparlanma. Sadece görsel alt düğüm ölçeklenir; collider değişmez, input animasyon bitmesini beklemez.
- Animasyon gücü 0–1 ile kapatılabilir/azaltılabilir. Kalkış/iniş süreleri, stretch/squash ve poz yumuşatma katsayısı dış veri kaynağındadır.
- Zemin işareti ışınla gerçek yüzeye konur; oyuncu havadayken yere göre konumu okunur.
- Test parkuruna 45 ve75 cm engel eklenir;1,2 m duvar geçilemez karşılaştırma örneği olarak kalır.

## Affected Systems

| Sistem | Etki | İşlem |
|---|---|---|
| Hareket | Düşey hız, grounded kapısı, jump/land olayları | Controller ve testler |
| Tuning | Dönüş13,2 ve yükseklik/animasyon parametreleri | .gd Resource + .tres |
| Kamera | Dikey zıplama takibinin ayrılması | Ground-height anchor |
| Lab/UI | Kontrol açıklaması (Space zıpla, Shift atıl, Ctrl yavaş), engeller, prosedürel pozlar | Lab script |
| Input | Space jump, Shift dash, Ctrl slow_walk eylemleri | project.godot |
| Tasarım | P1-01 kapsam/kabul | Özet ve mekanik listesi |

## Acceptance Criteria

- [ ] Dış veri dönüş13,2/yükseklik1/gravity24 içerir; yürüyüş ve kamera kayması değişmez.
- [ ] Yer teması zıplamayı açar, havada tekrar ve dash sırasındaki jump reddedilir.
- [ ] Basılı tuş inişte tekrar başlatmaz; reset düşey durumu temizler.
- [ ] Yaklaşık1m tepe ve tekrar yer teması gerçek sahnede gözlemlenir.
- [ ] Alçak engel aşılabilir; yüksek duvar ve tavan çarpışması işler.
- [ ] Kamera zıplama nedeniyle dikey sekmez.
- [ ] Kalkış/uçuş/iniş animasyonu görünür, collider ölçeklenmez, strength0 nötrdür.
- [ ] Hareket/atılma testleri bozulmaz; eklenen testler önce eski kodda hata verir.
- [ ] Gerçek pencereli sahne sürülür; yerde/havada/inişte ekran görüntüleri production/qa/evidence/ altında saklanıp okunur.
- [ ] Kullanıcı hissiyatı ayrıca değerlendirir; kod/test/görüntü sonucu bu onay değildir.

## GDD Update Required?

Ayrı GDD yok. Onaylanan `design/game-brief.md` ve `production/phase-1-mechanics.md` güncellenir; orijinal tasarım belgesi değiştirilmez. Faz 1 tamamlanmış sayılmaz.
