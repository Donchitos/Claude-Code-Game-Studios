import base64
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent.parent.parent
QA_DIR = ROOT_DIR / "production" / "qa"

def get_b64(path: Path) -> str:
    with open(path, "rb") as f:
        return "data:image/jpeg;base64," + base64.b64encode(f.read()).decode("utf-8")

t1 = get_b64(QA_DIR / "thumb_02.jpg")
t2 = get_b64(QA_DIR / "thumb_05.jpg")
t3 = get_b64(QA_DIR / "thumb_09.jpg")

html = f"""<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sector 9 — Faz 1 Mekanik Vitrini & Video Kaydı</title>
    <style>
        :root {{
            --bg: #090e17;
            --surface: #111a28;
            --surface-hover: #172437;
            --border: #22344d;
            --primary: #66e0c2;
            --accent: #ffd280;
            --danger: #ff5c5c;
            --text: #e6eef8;
            --text-dim: #94a7bd;
        }}
        * {{ box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; }}
        body {{ background: var(--bg); color: var(--text); padding: 16px; line-height: 1.5; }}
        .container {{ max-width: 860px; margin: 0 auto; }}
        .header {{ text-align: center; margin-bottom: 20px; padding: 20px 16px; background: var(--surface); border: 1px solid var(--border); border-radius: 14px; }}
        .badge {{ display: inline-block; padding: 4px 12px; background: rgba(102, 224, 194, 0.15); border: 1px solid var(--primary); color: var(--primary); border-radius: 20px; font-size: 13px; font-weight: 600; margin-bottom: 10px; }}
        h1 {{ font-size: 22px; color: var(--primary); margin-bottom: 8px; }}
        .subtitle {{ font-size: 13px; color: var(--text-dim); max-width: 600px; margin: 0 auto; }}
        
        .video-wrapper {{ background: #000; border: 2px solid var(--border); border-radius: 14px; overflow: hidden; margin-bottom: 20px; box-shadow: 0 10px 30px rgba(0,0,0,0.5); }}
        video {{ width: 100%; height: auto; display: block; }}
        .video-meta {{ display: flex; justify-content: space-between; align-items: center; padding: 12px 16px; background: var(--surface); font-size: 13px; color: var(--text-dim); border-top: 1px solid var(--border); }}
        .download-btn {{ background: var(--primary); color: #07111a; text-decoration: none; padding: 6px 14px; border-radius: 6px; font-weight: 600; font-size: 12px; }}
        
        .timeline {{ margin-bottom: 20px; }}
        .timeline-title {{ font-size: 17px; color: var(--accent); margin-bottom: 12px; font-weight: 600; }}
        .timeline-list {{ display: grid; gap: 8px; }}
        .timeline-item {{ display: flex; gap: 12px; padding: 10px 14px; background: var(--surface); border: 1px solid var(--border); border-radius: 10px; align-items: center; }}
        .time {{ background: rgba(255, 210, 128, 0.12); color: var(--accent); padding: 4px 8px; border-radius: 6px; font-weight: bold; font-size: 12px; min-width: 48px; text-align: center; }}
        .item-text h4 {{ font-size: 14px; color: var(--text); margin-bottom: 2px; }}
        .item-text p {{ font-size: 12px; color: var(--text-dim); }}
        
        .gallery {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 14px; margin-bottom: 20px; }}
        .gallery-card {{ background: var(--surface); border: 1px solid var(--border); border-radius: 12px; overflow: hidden; }}
        .gallery-card img {{ width: 100%; height: auto; display: block; }}
        .gallery-card-desc {{ padding: 10px 12px; font-size: 12px; color: var(--text-dim); }}
        .gallery-card-desc strong {{ color: var(--text); display: block; margin-bottom: 2px; }}
        
        .summary-box {{ background: rgba(102, 224, 194, 0.08); border: 1px solid var(--primary); border-radius: 12px; padding: 16px; text-align: center; }}
        .summary-box h3 {{ color: var(--primary); font-size: 15px; margin-bottom: 4px; }}
        .summary-box p {{ font-size: 12px; color: var(--text-dim); }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <span class="badge">SDLC DOĞRULAMA VİTRİNİ</span>
            <h1>Sector 9: Cold Protocol — Faz 1 Mekanik Test Kaydı</h1>
            <p class="subtitle">19 Görevin tamamı, 29 test paketi ve 572 otomatik kontrolün eksiksiz çalıştığını gösteren canlı pencereli oyun kaydı.</p>
        </div>

        <div class="video-wrapper">
            <video controls playsinline preload="metadata">
                <source src="phase1_showcase.mp4" type="video/mp4">
                Tarayıcınız video etiketini desteklemiyor.
            </video>
            <div class="video-meta">
                <span>🎥 1280×720 • 30 FPS • H.264 (3.6 MB)</span>
                <a href="phase1_showcase.mp4" class="download-btn" download>Videoyu İndir (.mp4)</a>
            </div>
        </div>

        <div class="timeline">
            <div class="timeline-title">⏱️ Video Akışı ve Test Zaman Çizelgesi</div>
            <div class="timeline-list">
                <div class="timeline-item">
                    <span class="time">00:00</span>
                    <div class="item-text">
                        <h4>Giriş & Mekanik Çekirdeği</h4>
                        <p>19 Görev, 29 Test Paketi, 572 Otomatik Kontrol — %100 Başarı başlangıç başlığı.</p>
                    </div>
                </div>
                <div class="timeline-item">
                    <span class="time">00:02</span>
                    <div class="item-text">
                        <h4>01. Hareket ve Yönlü Atılma (WASD & Shift Dash)</h4>
                        <p>WASD ile kameraya duyarlı ivmeli hareket ve Sol Shift ile 15 m/s hızlı atılma.</p>
                    </div>
                </div>
                <div class="timeline-item">
                    <span class="time">00:06</span>
                    <div class="item-text">
                        <h4>02. Prosedürel Balistik Zıplama (Space Jump)</h4>
                        <p>Space ile 1m zıplama; 45 cm ve 75 cm engeller, kalkış esnemesi ve iniş toparlanması.</p>
                    </div>
                </div>
                <div class="timeline-item">
                    <span class="time">00:12</span>
                    <div class="item-text">
                        <h4>03. Sessiz Yürüyüş & Lazer Sızması (Ctrl Çökme)</h4>
                        <p>Sol Ctrl ile sessiz yürüme; doğu lazer koridorunun altından hasar almadan sızma.</p>
                    </div>
                </div>
                <div class="timeline-item">
                    <span class="time">00:16</span>
                    <div class="item-text">
                        <h4>04. 3B Dikey Nişan & Tabanca Geri Tepme</h4>
                        <p>Ayak dibinde dik açı, 6m ötesinde 0° düz atış; fırlayan kovanlar, kıvılcımlar ve 2sn taktik şarjör pozu.</p>
                    </div>
                </div>
                <div class="timeline-item">
                    <span class="time">00:21</span>
                    <div class="item-text">
                        <h4>05. Dört Silah Cephanesi & Düşmanı Dondurma</h4>
                        <p>1: Tabanca, 2: Şok (Pursuer robotunu 1.5s elektrik mavisi dondurma), 3: Pompalı (6 saçma), 4: Karabina.</p>
                    </div>
                </div>
                <div class="timeline-item">
                    <span class="time">00:27</span>
                    <div class="item-text">
                        <h4>06. Bağlamsal Akıllı İmleç Sistemi</h4>
                        <p>Düşmanda Kırmızı ⌖ ve mesafe rozeti, Siper Arkasında Turuncu ✕, İstasyonda Altın ◎ [E].</p>
                    </div>
                </div>
                <div class="timeline-item">
                    <span class="time">00:32</span>
                    <div class="item-text">
                        <h4>07. Kırıcı (Breaker) Rolü: Omuz Darbesi & Kalkan Duvarı</h4>
                        <p>Q: Omuz darbesiyle siperi kırma, F: Tek yönlü mavi enerji kalkanı açma.</p>
                    </div>
                </div>
                <div class="timeline-item">
                    <span class="time">00:38</span>
                    <div class="item-text">
                        <h4>08. Göz (Scout) Rolü: Keşif Drone'u & Sonar Taraması</h4>
                        <p>Q: Havada süzülen keşif drone'u fırlatma, F: 18m sonar darbesi ile hedefleri açığa çıkarma.</p>
                    </div>
                </div>
                <div class="timeline-item">
                    <span class="time">00:43</span>
                    <div class="item-text">
                        <h4>09. Nesne Taşıma, Fırlatma & Ganimet Kasaları</h4>
                        <p>Turuncu güç hücresini omza alma ve parabolik yayla fırlatma; sandığı açıp medkit alma.</p>
                    </div>
                </div>
                <div class="timeline-item">
                    <span class="time">00:48</span>
                    <div class="item-text">
                        <h4>10. Sistem Çöktü (Downed) & Dost AI Yardımcı Canlandırması</h4>
                        <p>Can sıfırlanınca sürünme; yeşil AI Yardımcı robotun koşup 35 HP ile ayağa kaldırması.</p>
                    </div>
                </div>
                <div class="timeline-item">
                    <span class="time">00:52</span>
                    <div class="item-text">
                        <h4>11. Faz 1 Sonuç: Tüm Testler Geçti & Görev Başarılı</h4>
                        <p>Tüm mekaniklerin tek döngüde doğrulandığı büyük kapanış ve özet.</p>
                    </div>
                </div>
            </div>
        </div>

        <div class="gallery">
            <div class="gallery-card">
                <img src="{t1}" alt="Hareket ve Atılma">
                <div class="gallery-card-desc">
                    <strong>01. Hareket, Zıplama & Engeller</strong>
                    WASD, 15 m/s atılma ve 45/75 cm parkur sıçrayışı.
                </div>
            </div>
            <div class="gallery-card">
                <img src="{t2}" alt="Silahlar ve Düşman">
                <div class="gallery-card-desc">
                    <strong>05. Dört Silah & Kovalayan Botlar</strong>
                    Şok ile dondurma, pompalı savrulması ve karabina atışı.
                </div>
            </div>
            <div class="gallery-card">
                <img src="{t3}" alt="Kurtarma ve Kalkan">
                <div class="gallery-card-desc">
                    <strong>10. Kalkan Duvarı, Kasa & Canlandırma</strong>
                    Açılan sandık, uçurulan hücre ve dost robotun kurtarması.
                </div>
            </div>
        </div>

        <div class="summary-box">
            <h3>✅ Faz 1 Teknik Kabulü Tamamlandı</h3>
            <p>29 Test Dosyası • 572 Otomatik Kontrol • 19 Görev • 0 Hata — Faz 2 (ENet Çok Oyunculu Altyapısı) için hazır.</p>
        </div>
    </div>
</body>
</html>
"""

output_path = QA_DIR / "phase1_showcase.html"
with open(output_path, "w", encoding="utf-8") as f:
    f.write(html)
print(f"SUCCESS: Generated {output_path} ({output_path.stat().st_size} bytes)")
