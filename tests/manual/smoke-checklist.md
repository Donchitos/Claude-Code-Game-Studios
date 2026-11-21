# Smoke Checklist — Clube do Bairro (fatia vertical)

> **Estado de execução:** checklist planejado. **Nenhum passo foi executado nesta máquina.**
> **Pré-requisito:** engine Godot disponível. Comando previsto para abrir o jogo quando a engine estiver disponível:
>
> ```bash
> godot --path . --windowed --resolution 1280x720
> ```
>
> **Status aplicável a todos os passos:** ⚠ NÃO EXECUTÁVEL nesta máquina — engine Godot ausente.
> **Referência:** `ACn` = critério de aceite `n` de `design/game-brief.md`. Reiniciar a run entre cenários independentes.

## Passos (6)

### 1. Estado inicial
- **Ação:** abrir o jogo com o comando acima e, sem tomar decisão, ler o painel da semana 1.
- **Resultado esperado:** semana `1`; caixa `R$ 5.000`; `0 pts`; `N=1`; `R=0`; salário vigente `R$ 1.200`.
- **Critério de aceite de origem:** AC1 (Inicial) + parâmetros "Números-base".
- **Status:** ⚠ NÃO EXECUTÁVEL nesta máquina — engine Godot ausente.

### 2. Um turno completo, sem turnos extras
- **Ação:** na semana 1, tomar exatamente **uma** decisão — "Escalar titulares" — e acompanhar a resolução até o painel da semana 2.
- **Resultado esperado:** sequência `1 decisão → partida → bilheteria (R$ 1.200, N=1) → salário (−R$ 1.200) → painel atualizado`; caixa final do turno `R$ 5.000`; semana avança somente para `2`; nenhuma segunda decisão no mesmo turno e nenhum turno adicional.
- **Critério de aceite de origem:** AC2 (Turno) + regra de orçamento.
- **Status:** ⚠ NÃO EXECUTÁVEL nesta máquina — engine Godot ausente.

### 3. Cálculo de força e pontos
- **Ação:** observar `F` e os pontos em três cenários: (a) `N=1, R=0, T=1, C=0`; (b) `R=1, N=2, T=1, C=0`; (c) `T=0, C=1`.
- **Resultado esperado (AC3 consolidado):** (a) `F=1 → 0 pts`; (b) `F=3 → 3 pts`; (c) `F=−1 → 0 pts`.
- **Critério de aceite de origem:** AC3 (Força) + fórmula de escalação.
- **Status:** ⚠ NÃO EXECUTÁVEL nesta máquina — engine Godot ausente.

### 4. Caixa, bilheteria e limite de `N`
- **Ação:** observar a variação de caixa sem custos em `N=1`; em seguida aplicar "Melhorar instalação" na semana 2 (`N=2`) e na semana 3 (`N=3`) e tentar uma nova reforma na semana 4.
- **Resultado esperado:** sem custos, `N=1 → Δ0`, `N=2 → Δ+400`, `N=3 → Δ+800` (`bilheteria 800 + 400×N − salário 1.200`); `N` **nunca** passa de `3` — a tentativa na semana 4 não eleva `N`, não cobra custo e a bilheteria permanece `R$ 2.000`.
- **Critério de aceite de origem:** AC4 (Caixa) + AC8 (Limites).
- **Status:** ⚠ NÃO EXECUTÁVEL nesta máquina — engine Godot ausente.

### 5. Desfecho de vitória
- **Ação:** nova run: semana 1 "Contratar reforço"; semana 2 "Melhorar instalação"; semanas 3 a 6 "Escalar titulares".
- **Resultado esperado:** pontos por semana `0, 1, 3, 3, 3, 3 = 13 ≥ 7`; caixa positivo ao fim (rastro esperado `5.000 → 3.500 → 1.900 → 2.300 → 2.700 → 3.100`); tela de vitória ao encerrar a semana 6, sem falência no percurso.
- **Critério de aceite de origem:** AC5 (Vitória).
- **Status:** ⚠ NÃO EXECUTÁVEL nesta máquina — engine Godot ausente.

### 6. Desfechos de falência e derrota
- **Ação:** (a) rastro de falência verificável: semana 1 "Contratar reforço", semana 2 "Melhorar instalação", semana 3 "Melhorar instalação"; (b) run separada: "Escalar titulares" nas 6 semanas, sem reforço, reforma ou corte.
- **Resultado esperado:** (a) na semana 3, o débito da reforma leva o caixa de `R$ 1.900` para `−R$ 100`; a falência é encerrada **imediatamente após essa mutação de caixa**, sem partida e sem tela de vitória/derrota; (b) caixa final `R$ 5.000` e `0 pts` → tela de derrota na semana 6.
- **Critério de aceite de origem:** AC6 (Falência) e AC7 (Derrota).
- **Status:** ⚠ NÃO EXECUTÁVEL nesta máquina — engine Godot ausente.

## Notas de rastreabilidade (divergências consolidadas)

- **AC3:** exemplos corrigidos para `F=1 → 0 pts` e `F=3 → 3 pts`, conforme `starters_strength = 1` em `data/economy.json`.
- **AC6:** o rastro falso (`caixa 2000` → `−1600`) foi substituído por reforço → reforma → reforma, com falência na semana 3 e caixa `−100`.
- **AC7:** derrota com `0 pts` (não `6`) — escalar sozinho não atinge `draw_threshold = 2`.
- **AC8:** reforma com `N=3` não cobra custo e não incrementa `N`, conforme `ClubState`.
