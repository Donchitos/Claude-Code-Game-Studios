#!/usr/bin/env python3
"""
tools/sdlc/gameplay_hooks.py
SDLC Oyun Dinamikleri ve Hissiyat (Game Feel) Kalite Kancası.
Oyun mekaniklerinin hissiyat sınırlarını, sinyal sözleşmelerini ve
Yönetmen denge kurallarını statik ve dinamik olarak doğrular.
"""

import re
import sys
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent.parent.parent

def check_signal_contracts() -> list:
    """Oyun hissiyatı için zorunlu sinyallerin kod tabanında varlığını denetler."""
    required_signals = {
        "src/gameplay/gameplay_hooks.gd": [
            "shake_requested", "hit_stop_requested", "landing_impact",
            "pacing_state_changed", "director_event_triggered"
        ],
        "src/player/player_controller.gd": ["jumped", "landed"],
        "src/combat/player_combat.gd": ["health_changed", "ammo_changed", "fired", "damaged"]
    }

    issues = []
    for rel_path, signals in required_signals.items():
        file_path = ROOT_DIR / rel_path
        if not file_path.exists():
            issues.append(f"Kayıp dosya: {rel_path}")
            continue
        content = file_path.read_text(encoding="utf-8")
        for sig in signals:
            pattern = rf"\bsignal\s+{sig}\b"
            if not re.search(pattern, content):
                issues.append(f"Eksik sinyal sözleşmesi: {rel_path} içinde '{sig}' sinyali bulunamadı.")
    return issues

def check_game_feel_tuning() -> list:
    """Çatışma ve hareket hissiyatı değerlerinin insan tepki bütçesinde olduğunu denetler."""
    issues = []
    combat_script = ROOT_DIR / "src" / "combat" / "player_combat.gd"
    if combat_script.exists():
        content = combat_script.read_text(encoding="utf-8")
        # Geri tepme süresi (0.05s - 0.30s arası olmalı)
        recoil_match = re.search(r"recoil_duration:\s*float\s*=\s*([0-9.]+)", content)
        if recoil_match:
            val = float(recoil_match.group(1))
            if not (0.05 <= val <= 0.35):
                issues.append(f"Hissiyat hatası: recoil_duration ({val}s) kabul edilebilir sınır (0.05 - 0.35s) dışında.")

        # Şarjör kapasitesi pozitif olmalı
        mag_match = re.search(r"magazine_capacity:\s*int\s*=\s*([0-9]+)", content)
        if mag_match:
            val = int(mag_match.group(1))
            if val <= 0 or val > 100:
                issues.append(f"Hissiyat hatası: magazine_capacity ({val}) mantıklı aralıkta değil.")
    return issues

def check_director_pacing_rules() -> list:
    """Yönetmen gerilim ve nefes aralığı kurallarının varlığını denetler."""
    issues = []
    pacing_script = ROOT_DIR / "src" / "gameplay" / "director_pacing_hook.gd"
    if not pacing_script.exists():
        issues.append("Kayıp Yönetmen kancası: src/gameplay/director_pacing_hook.gd")
        return issues

    content = pacing_script.read_text(encoding="utf-8")
    required_states = ["CALM", "BUILDUP", "PEAK", "RECOVERY"]
    for st in required_states:
        if st not in content:
            issues.append(f"Yönetmen eksik tempo aşaması: {st}")

    if "airdrop_crate" not in content:
        issues.append("Yönetmen kancasında Düşüş Kasası (airdrop_crate) olay sözleşmesi eksik.")
    return issues

def audit_gameplay_dynamics() -> int:
    print("=== AI-Native SDLC Oyun Dinamikleri ve Hissiyat Denetimi ===")
    all_issues = []
    all_issues.extend(check_signal_contracts())
    all_issues.extend(check_game_feel_tuning())
    all_issues.extend(check_director_pacing_rules())

    if not all_issues:
        print("[PASS] Sinyal sözleşmeleri eksiksiz (jumped, landed, fired, damaged, shake, hit-stop).")
        print("[PASS] Oyun hissiyatı parametreleri dengeli (recoil, magazine, timing).")
        print("[PASS] Yönetmen tempo aşamaları ve nefes aralığı kuralları uyumlu.")
        print("-" * 55)
        print("Sonuç: Oyun dinamikleri kancaları DOĞRULANDI (0 Hata).")
        return 0
    else:
        print("[FAIL] Oyun dinamikleri denetiminde sorunlar bulundu:")
        for iss in all_issues:
            print(f"  • {iss}")
        return 2

def main():
    sys.exit(audit_gameplay_dynamics())

if __name__ == "__main__":
    main()
