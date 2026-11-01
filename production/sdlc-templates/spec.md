# Specification: [Özellik Adı] (Bağlantılı Intent: [intent-id.md])
Tasarımcı / Mimar: [Uzman Rolü / Ad] · Durum: [taslak | onaylandı] · Tarih: [YYYY-AA-GG]

## 1. Niyet Özeti ve Kapsam Doğrulaması
[intent.md belgesindeki hedeflerin teknik gereksinimlere dönüştürülmüş özeti.]

## 2. Mimari ve Bileşen Yapısı
- **Sistem Sorumlusu:** [Örn: Systems Designer / Lead Programmer]
- **Düğüm / Sınıf Hiyerarşisi:**
  - `AnaBileşen` (extends Node / CharacterBody3D)
    - `AltBileşen1`
    - `AltBileşen2`
- **Sinyal Sözleşmesi (Signal Contract):**
  - `signal oge_degisti(yeni_deger: int)` — [Tetiklenme anı ve parametreler]
- **Veri Modeli & Kaynaklar:**
  - Resource sınıfları, konfigürasyon veri yapıları ve tipleri.

## 3. Kodlama Standartları ve Motor Uyumluluğu
- **Motor:** Godot 4.7.2 (GDScript, Forward+, Jolt Physics)
- **Statik Tipler (Mandatory):** Tüm değişkenler ve dönüş tipleri katı biçimde tiplenmelidir (`var health: float = 100.0`, `func run() -> void:`).
- **Yazma Kapsamı (Write Scope):** Yalnızca bu şartnamede adı geçen dosya ve dizinlere dokunulacaktır.

## 4. Güvenlik, Hata Kurtarma ve Kısıtlar
- **Sır ve İzin İzolasyonu:** Harici ağ çağrısı veya hassas veri saklama yapılamaz.
- **Fail-Safe Davranış:** Beklenmeyen girdi veya ağ kesintisinde sistem çökmeden güvenli varsayılan duruma geçmelidir.

## 5. Doğrulama ve Test Senaryoları
- **Birim Testleri (`tests/unit/...`):** Hangi fonksiyonlar için test yazılacak?
- **Entegrasyon Testleri (`tests/integration/...`):** Hangi lab ortamında doğrulanacak?
- **Headless Çalıştırma:** Testler `godot --headless` ile otomatik geçmeli.

## 6. Risk Değerlendirmesi ve Ödünleşimler (Trade-offs)
| Risk / Belirsizlik | Olası Etki | Azaltma Stratejisi |
| :--- | :--- | :--- |
| [Örn: Fizik kare hızı dalgalanması] | [Harakette titreme] | [Jolt alt adımları ve interpolasyon] |

---
## Yönetişim ve Aşama Kapısı (Phase Gate Approval)
- **Teknik Direktör / Mimarlık Onayı:** [ ] Onaylandı
- **Kreatif Direktör Onayı:** [ ] Onaylandı
- **Geçiş:** Aşama 03 (Build / plan.md) hazır.
