#!/usr/bin/env python3
"""
tools/sdlc/runner.py
Evrensel AI-Native SDLC Test ve Doğrulama Çalıştırıcısı.
Sıfır ek kütüphane bağımlılığı (Pure Python 3). Windows, Linux ve macOS ile tam uyumlu.
"""

import argparse
import os
import re
import subprocess
import sys
from pathlib import Path

# Windows terminal Türkçe CP1254 uyumluluğu
if sys.stdout and hasattr(sys.stdout, "reconfigure"):
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass
if sys.stderr and hasattr(sys.stderr, "reconfigure"):
    try:
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass

ROOT_DIR = Path(__file__).resolve().parent.parent.parent

def find_godot_executable() -> str:
    """Godot motoru çalıştırılabilir dosyasını tespit eder."""
    candidates = [
        ROOT_DIR / "godot-test" / "Godot_v4.7.2-stable_win64_console.exe",
        ROOT_DIR / "godot-test" / "Godot_v4.7.2-stable_win64.exe",
        ROOT_DIR / "godot" / "godot.exe",
    ]
    for c in candidates:
        if c.is_file():
            return str(c)
    # Sistem PATH kontrolü
    from shutil import which
    path_bin = which("godot") or which("godot4")
    if path_bin:
        return path_bin
    return ""

def run_headless_tests(filter_pattern: str = "") -> int:
    """Godot birim testlerini headless olarak çalıştırır ve raporlar."""
    godot_bin = find_godot_executable()
    if not godot_bin:
        print("[HATA] Godot motoru bulunamadı. Lütfen godot-test klasörünü veya PATH'i kontrol edin.", file=sys.stderr)
        return 2

    # Yalnızca otomatik sonlanan headless birim testleri (etkileşimli lab testleri hariç)
    unit_tests_dir = ROOT_DIR / "tests" / "unit"
    if not unit_tests_dir.exists():
        print(f"[UYARI] Test dizini bulunamadı: {unit_tests_dir}")
        return 0

    test_files = sorted(unit_tests_dir.rglob("*.gd"))
    p1_core_dir = ROOT_DIR / "tests" / "integration" / "p1_core"
    if p1_core_dir.exists():
        test_files.extend(sorted(p1_core_dir.rglob("*.gd")))
    p1_full_dir = ROOT_DIR / "tests" / "integration" / "p1_full"
    if p1_full_dir.exists():
        test_files.extend(sorted(p1_full_dir.rglob("*.gd")))
    selected_tests = []
    for tf in test_files:
        rel = tf.relative_to(ROOT_DIR).as_posix()
        if filter_pattern and filter_pattern.lower() not in rel.lower():
            continue
        selected_tests.append(tf)

    if not selected_tests:
        print(f"[BİLGİ] Çalıştırılacak test bulunamadı (Filtre: '{filter_pattern}').")
        return 0

    print(f"=== AI-Native SDLC Headless Test Koşusu ({len(selected_tests)} Test) ===")
    total_failures = 0
    passed_count = 0

    for tf in selected_tests:
        rel_path = tf.relative_to(ROOT_DIR).as_posix()
        res_path = f"res://{rel_path}"
        cmd = [godot_bin, "--headless", "--path", str(ROOT_DIR), "--script", res_path]
        
        try:
            res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, timeout=30)
            output = res.stdout + res.stderr
            # Başarısızlık göstergesi ara
            is_fail = res.returncode != 0 or "FAIL" in output or "failure" in output.lower() and "0 failures" not in output
            if is_fail:
                print(f"[FAIL] {rel_path} (Çıkış Kodu: {res.returncode})")
                for line in output.strip().splitlines()[-6:]:
                    print(f"       {line}")
                total_failures += 1
            else:
                # Başarılı assertion sayısını yakala
                match = re.search(r"(\d+)\s*(assertions|checks)", output)
                stat = f" ({match.group(0)})" if match else ""
                print(f"[PASS] {rel_path}{stat}")
                passed_count += 1
        except subprocess.TimeoutExpired:
            print(f"[TIMEOUT] {rel_path} (30 saniye aşıldı)")
            total_failures += 1
        except Exception as e:
            print(f"[HATA] {rel_path}: {e}")
            total_failures += 1

    print("-" * 50)
    print(f"Sonuç: {passed_count} Başarılı, {total_failures} Başarısız")
    return 0 if total_failures == 0 else 2

def check_artifacts() -> int:
    """SDLC çıktı dosyalarının (intent, spec, plan) bütünlüğünü kontrol eder."""
    production_dir = ROOT_DIR / "production"
    required_dirs = ["session-state", "sdlc-templates"]
    missing = [d for d in required_dirs if not (production_dir / d).exists()]
    if missing:
        print(f"[UYARI] Eksik dizinler: {missing}")
        return 2

    # active.md kontrolü
    active_md = production_dir / "session-state" / "active.md"
    if active_md.exists():
        print(f"[PASS] active.md oturum kontrol noktası mevcut ({active_md.stat().st_size} bayt)")
    else:
        print("[UYARI] active.md henüz oluşturulmamış.")

    # Şablonların kontrolü
    templates = ["intent.md", "spec.md", "plan.md"]
    for tmpl in templates:
        p = production_dir / "sdlc-templates" / tmpl
        if p.exists():
            print(f"[PASS] Şablon hazır: production/sdlc-templates/{tmpl}")
        else:
            print(f"[FAIL] Eksik şablon: production/sdlc-templates/{tmpl}")
            return 2

    return 0

def status() -> int:
    """Sistem ve SDLC durumunu özetler."""
    godot_bin = find_godot_executable()
    from locks import get_current_dev, get_current_branch, list_active_locks
    dev = get_current_dev()
    branch = get_current_branch()
    locks = list_active_locks()

    print("=== Evrensel AI-Native SDLC Sistem Durumu ===")
    print(f"Çalışma Alanı   : {ROOT_DIR}")
    print(f"Geliştirici     : {dev} (Dal: {branch})")
    print(f"Aktif Kilitler  : {len(locks)} kayıtlı")
    print(f"Python Sürümü   : {sys.version.split()[0]}")
    print(f"Godot Motoru    : {godot_bin or 'Bulunamadı'}")
    print(f"AGENTS.md       : {'Mevcut' if (ROOT_DIR / 'AGENTS.md').exists() else 'Eksik'}")
    print(f"SDLC.md         : {'Mevcut' if (ROOT_DIR / 'SDLC.md').exists() else 'Eksik'}")
    print(f"CLAUDE.md       : {'Mevcut' if (ROOT_DIR / 'CLAUDE.md').exists() else 'Eksik'}")
    return 0

def preflight(developer="", as_json=False) -> int:
    """Salt okunur görev yönlendirmesi; eski yerel kilit panosunun yerine geçer."""
    from startup import run
    return run(developer, as_json)


def legacy_local_lock_panel() -> int:
    """Eski pano; başlangıç veya güvenlik kararı olarak kullanılmaz."""
    from locks import get_current_dev, get_current_branch, list_active_locks
    dev = get_current_dev()
    branch = get_current_branch()
    locks = list_active_locks()

    print("=" * 65)
    print("[PREFLIGHT] AI-Native SDLC İki Kişilik Ortak Çalışma Kontrolü")
    print("=" * 65)
    print(f"Aktif Geliştirici : {dev}")
    print(f"Çalışma Dalı      : {branch}")
    print("-" * 65)

    partner_locks = [l for l in locks if l.get("developer", "").lower() != dev.lower()]
    my_locks = [l for l in locks if l.get("developer", "").lower() == dev.lower()]

    if partner_locks:
        print("[UYARI] Diğer geliştirici şu anda aşağıdaki alanlarda çalışıyor:")
        for pl in partner_locks:
            print(f"  * Geliştirici : {pl.get('developer')} (Dal: {pl.get('branch')})")
            print(f"    Görev       : {pl.get('issue_id')} - {pl.get('task_title')}")
            print(f"    Kilitli Alan: {', '.join(pl.get('write_scopes', []))}")
        print("-" * 65)
        print("[ONERI] Yukarıda belirtilen kilitli alanlara dokunmayın.")
    else:
        print("[BILGI] Diğer geliştiricinin aktif bir kilidi bulunmuyor. Tüm alanlar serbest.")

    if my_locks:
        print("-" * 65)
        print(f"[KILIT] Senin adına aktif kilitler ({len(my_locks)}):")
        for ml in my_locks:
            print(f"  * {ml.get('issue_id')} - {ml.get('task_title')} -> {', '.join(ml.get('write_scopes', []))}")

    print("=" * 65)
    return 0

def main():
    parser = argparse.ArgumentParser(description="Evrensel AI-Native SDLC Çalıştırıcısı")
    subparsers = parser.add_subparsers(dest="command", help="Alt komut")

    test_parser = subparsers.add_parser("test", help="Headless testleri çalıştır")
    test_parser.add_argument("--filter", default="", help="Test dosyası filtre filtresi")

    subparsers.add_parser("check-artifacts", help="SDLC çıktılarını denetle")
    subparsers.add_parser("check-gameplay", help="Oyun dinamikleri ve hissiyat kancalarını denetle")
    for name in ("start", "preflight"):
        startup_parser = subparsers.add_parser(name, help="Salt okunur Faz1 görev başlangıcı")
        startup_parser.add_argument("--developer", default="", help="alicomert veya okanipk")
        startup_parser.add_argument("--json", action="store_true", help="Makine tarafından okunur rapor")
    subparsers.add_parser("status", help="Sistem durumunu raporla")

    args = parser.parse_args()

    if args.command == "test":
        sys.exit(run_headless_tests(args.filter))
    elif args.command == "check-artifacts":
        sys.exit(check_artifacts())
    elif args.command == "check-gameplay":
        from gameplay_hooks import audit_gameplay_dynamics
        sys.exit(audit_gameplay_dynamics())
    elif args.command in ("start", "preflight"):
        sys.exit(preflight(args.developer, args.json))
    elif args.command == "status":
        sys.exit(status())
    else:
        parser.print_help()
        sys.exit(0)

if __name__ == "__main__":
    main()
