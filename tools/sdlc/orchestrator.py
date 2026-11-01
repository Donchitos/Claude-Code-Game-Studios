#!/usr/bin/env python3
"""
tools/sdlc/orchestrator.py
30+ Subagent Orkestrasyonu, Görev Yönlü Graf (DAG) ve Yazma Alanı İzolasyonu Yöneticisi.
Herhangi bir LLM çalışma ortamında görevleri güvenle bölümlendirir ve sıralar.
"""

import argparse
import json
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Set

ROOT_DIR = Path(__file__).resolve().parent.parent.parent

@dataclass
class SubagentTask:
    id: str
    role: str
    description: str
    write_scopes: List[str] = field(default_factory=list)
    blocked_by: List[str] = field(default_factory=list)
    tier: str = "specialist"  # director | lead | specialist

class SwarmOrchestrator:
    """30+ Subagent için görev dağıtımı ve yazma alanı çakışma yöneticisi."""

    def __init__(self):
        self.tasks: Dict[str, SubagentTask] = {}

    def add_task(self, task: SubagentTask):
        self.tasks[task.id] = task

    def check_write_conflicts(self, task_ids: List[str]) -> List[tuple]:
        """Aynı anda çalışacak görevler arasında yazma kapsamı çakışması olup olmadığını denetler."""
        conflicts = []
        scope_map: Dict[str, str] = {}
        for tid in task_ids:
            task = self.tasks[tid]
            for scope in task.write_scopes:
                clean_scope = scope.strip("/").replace("\\", "/")
                # Üst dizin veya doğrudan dosya çakışması kontrolü
                for existing_scope, existing_tid in scope_map.items():
                    if clean_scope.startswith(existing_scope) or existing_scope.startswith(clean_scope):
                        conflicts.append((tid, existing_tid, scope, existing_scope))
                scope_map[clean_scope] = tid
        return conflicts

    def compute_execution_batches(self) -> List[List[str]]:
        """
        Bağımlılıkları (blocked_by) ve yazma kapsamı çakışmalarını gözeterek
        paralel çalıştırılabilecek görev kümelerini (batches) hesaplar.
        """
        completed: Set[str] = set()
        remaining: Set[str] = set(self.tasks.keys())
        batches: List[List[str]] = []

        while remaining:
            # Bağımlılıkları tamamlanmış adayları bul
            ready_candidates = [
                tid for tid in remaining
                if all(dep in completed for dep in self.tasks[tid].blocked_by)
            ]

            if not ready_candidates:
                raise ValueError("Döngüsel görev bağımlılığı (Circular dependency) tespit edildi!")

            # Adaylar arasından birbiriyle çakışmayan en büyük paralel kümesi oluştur (en fazla 32 worker)
            current_batch: List[str] = []
            current_scopes: Set[str] = set()

            for tid in ready_candidates:
                task = self.tasks[tid]
                conflict = False
                for scope in task.write_scopes:
                    clean_scope = scope.strip("/").replace("\\", "/")
                    if any(clean_scope.startswith(s) or s.startswith(clean_scope) for s in current_scopes):
                        conflict = True
                        break
                if not conflict:
                    current_batch.append(tid)
                    for scope in task.write_scopes:
                        current_scopes.add(scope.strip("/").replace("\\", "/"))
                if len(current_batch) >= 32:  # 30+ üst sınır
                    break

            batches.append(current_batch)
            for tid in current_batch:
                completed.add(tid)
                remaining.remove(tid)

        return batches

def sample_sprint_plan():
    """Örnek 30+ subagent iş planını oluşturur ve paralel kümeleri gösterir."""
    orch = SwarmOrchestrator()

    # Tier 1 - Liderlik ve Planlama (Sıralı)
    orch.add_task(SubagentTask("plan-intent", "producer", "Intent belgesini doğrula", ["production/intent/"]))
    orch.add_task(SubagentTask("tech-spec", "technical-director", "Teknik şartnameyi hazırla", ["production/spec/"], blocked_by=["plan-intent"]))

    # Tier 3 - 10 Farklı Alanda Paralel Çalışan Bağımsız Uzmanlar
    parallel_roles = [
        ("combat-core", "godot-gdscript-specialist", "Silah ateşleme döngüsü", ["src/combat/"]),
        ("player-motion", "gameplay-programmer", "Karakter ivmelenme ayarı", ["src/player/"]),
        ("hud-refresh", "ui-programmer", "HUD sağlık göstergesi tasarımı", ["src/ui/"]),
        ("laser-fx", "godot-shader-specialist", "Lazer vuruş parçacık gölgelendiricisi", ["assets/shaders/"]),
        ("gun-sfx", "sound-designer", "Silah ateş ve yeniden doldurma sesleri", ["assets/audio/sfx/"]),
        ("level-blockout", "level-designer", "Koridor 9 mekanik test odası", ["design/levels/"]),
        ("dialog-lines", "writer", "Telsiz ve ortam anons replikleri", ["design/narrative/"]),
        ("balance-curve", "economy-designer", "Mermi ve şarjör düşme olasılıkları", ["design/balance/"]),
        ("net-packet", "network-programmer", "Çok oyunculu pozisyon senkronizasyonu", ["src/network/"]),
        ("test-scaffold", "qa-tester", "Otomatik vuruş doğrulama testleri", ["tests/unit/player/"]),
    ]

    for tid, role, desc, scopes in parallel_roles:
        orch.add_task(SubagentTask(tid, role, desc, scopes, blocked_by=["tech-spec"]))

    # Tier 2 - İnceleme ve Entegrasyon Geçidi
    orch.add_task(SubagentTask("qa-gate", "qa-lead", "Tüm birim testleri ve kalite kapısını doğrula", ["production/qa/"], blocked_by=[t[0] for t in parallel_roles]))
    orch.add_task(SubagentTask("deploy-signoff", "release-manager", "Sürüm manifestosunu oluştur", ["production/releases/"], blocked_by=["qa-gate"]))

    batches = orch.compute_execution_batches()
    print("=== 30+ Subagent Paralel Görev Dağıtım Planı ===")
    for i, batch in enumerate(batches, 1):
        print(f"\n[Aşama / Küme {i}] Eşzamanlı Çalışan Alt Ajan Sayısı: {len(batch)}")
        for tid in batch:
            t = orch.tasks[tid]
            print(f"  • {t.id} ({t.role}) -> Yazma Kapsamı: {', '.join(t.write_scopes)}")

def main():
    parser = argparse.ArgumentParser(description="AI-Native SDLC Çoklu Ajan Orkestratörü")
    parser.add_argument("--demo", action="store_true", help="Örnek 30+ subagent DAG planını göster")
    args = parser.parse_args()

    sample_sprint_plan()

if __name__ == "__main__":
    main()
