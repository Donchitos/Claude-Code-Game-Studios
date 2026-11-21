# Clube do Bairro — Economia (fatia vertical, 6 semanas)

Documento de tuning e rastros determinísticos da economia. Fonte canônica de
valores em máquina: `data/economy.json` (consumido por `ClubState` em GDScript).
Este documento explica e verifica esses números; em caso de divergência, o JSON
vale como contrato de implementação e a divergência deve ser corrigida aqui e
no brief.

Não há sistemas probabilísticos nesta fatia (sem loot, sem drops, sem RNG):
todas as receitas, custos e pontuações são determinísticos. Por isso a seção
de tabela de recompensas aleatórias não se aplica.

---

## 1. Tabela de tuning

| Parâmetro | Valor aprovado | Chave em `data/economy.json` | Papel econômico |
|---|---:|---|---|
| Caixa inicial | R$ 5.000 | `starting_cash` | Reserva de partida (faucet único no início) |
| Semanas | 6 | `weeks` | Horizonte fixo; sem turnos extras |
| Meta | 7 pontos | `target_points` | Condição de vitória ao final da semana 6 |
| Salário semanal | R$ 1.200 | `salary` | Sink fixo recorrente |
| Salário com corte | R$ 600 | `austerity_salary` | Sink reduzido, válido só na semana do corte |
| Bilheteria base | R$ 800 | `gate_receipts.base` | Faucet recorrente mínimo |
| Bilheteria por nível | R$ 400 | `gate_receipts.per_level` | Faucet incremental ligado a `N` |
| Custo do reforço | R$ 1.500 | `reinforcement.cost` | Sink de capital; `+1` força permanente |
| Bônus de força do reforço | +1 | `reinforcement.strength_bonus` | Multiplicador de `R` |
| Custo da reforma | R$ 2.000 | `facility.upgrade_cost` | Sink de capital; `N += 1` |
| Nível máximo | 3 | `facility.max_level` | Teto do sink de reforma (máx. 2 compras) |
| Nível inicial | 1 | `facility.start_level` | Baseline de `N` e da força |
| Força por titular escalado | 1 | `match.starters_strength` | Termo de `T` (booleano) |
| Penalidade de corte | 1 | `match.crowd_penalty` | Termo de `C` (booleano) |
| Limiar de vitória | F ≥ 3 | `match.win_threshold` | Concede `points_win` |
| Limiar de empate | F ≥ 2 | `match.draw_threshold` | Concede `points_draw` (após falhar o de vitória) |
| Pontos por vitória | 3 | `match.points_win` | — |
| Pontos por empate | 1 | `match.points_draw` | — |
| Pontos por derrota | 0 | `match.points_loss` | — |
| Falência | caixa < 0 | `bankruptcy_below` | Encerramento imediato, com precedência |

**Decisões** (`decisions`, uma por semana, exatamente 6 no total):

| Decisão | Efeito imediato | Efeito permanente |
|---|---|---|
| `escalar_titulares` | `T = 1`; custo R$ 0 | nenhum |
| `contratar_reforco` | custo R$ 1.500; `R += 1` | `+1` força por semana restante |
| `melhorar_instalacao` | custo R$ 2.000; `N += 1` limitado a 3 | bilheteria `+400`/semana e força `+1` |
| `cortar_gastos` | salário da semana = R$ 600; `C = 1` | nenhum |

`T` e `C` são booleanos **da semana corrente**. `R` e `N` são acumulativos.

---

## 2. Fórmulas

### 2.1 Força

```
F = (T ? starters_strength : 0)
  + R × reinforcement.strength_bonus
  + (N − facility.start_level)
  − (C ? match.crowd_penalty : 0)
```

Com os valores aprovados: `F = T + R + (N − 1) − C`, com `T, C ∈ {0,1}`,
`R ≥ 0` e `1 ≤ N ≤ 3`. Faixa observável: `F ∈ [−1 … 6]` (mínimo `T=0, C=1,
R=0, N=1`; máximo `T=1, C=0, R=3, N=3`).

### 2.2 Resultado da partida (determinístico)

```
F ≥ 3  → points_win   (3 pts)
F ≥ 2  → points_draw  (1 pt)   // somente se F < 3
senão  → points_loss  (0 pts)
```

### 2.3 Fluxo de caixa

```
bilheteria = gate_receipts.base + gate_receipts.per_level × N
salario_vigente = (C ? austerity_salary : salary)
delta_semanal = bilheteria − salario_vigente
```

| N | Sem corte: bilheteria − salário | Com corte: bilheteria − salário |
|---:|---:|---:|
| 1 | 1200 − 1200 = **0** | 1200 − 600 = **+600** |
| 2 | 1600 − 1200 = **+400** | 1600 − 600 = **+1000** |
| 3 | 2000 − 1200 = **+800** | 2000 − 600 = **+1400** |

### 2.4 Ordem de liquidação (por semana)

1. Aplicar a decisão (muta `T`/`C` da semana, `R` e/ou `N`).
2. Debitar o custo da decisão, se houver.
3. **Checagem de falência**: `caixa < 0` → encerra imediatamente; sem partida,
   sem pontos, sem bilheteria, sem salário.
4. Calcular `F`, resolver a partida e somar os pontos.
5. Creditar a bilheteria e debitar o salário vigente.
6. **Checagem de falência**: `caixa < 0` → encerra imediatamente.
7. **Meta** (somente ao final da semana 6, se não houve falência):
   `pontos ≥ 7` → vitória; senão → derrota.

Falência tem precedência sobre vitória e derrota, inclusive na semana 6.
`caixa == 0` **não** é falência: o limiar é estritamente `< 0`.

### 2.5 Casos-limite

- `melhorar_instalacao` com `N == 3`: não cobra custo e não altera `N`, conforme
  o contrato implementado em `ClubState` (`docs/architecture/slice-architecture.md`).
  Cabe ao painel desabilitar a opção para evitar um turno desperdiçado.
- `cortar_gastos`: `C = 1` e salário R$ 600 apenas na semana corrente; na semana
  seguinte o salário volta a R$ 1.200 e `C = 0`, mesmo que nenhuma outra decisão
  tenha mudado.
- `R` não tem teto no JSON; economicamente, o caixa inicial limita a 3 reforços
  antes da falência (ver §3).

---

## 3. Saúde econômica (faucets e sinks)

**Faucets:** bilheteria semanal (R$ 1.200 → R$ 2.000) e caixa inicial (R$ 5.000).
**Sinks:** salário semanal (R$ 1.200, ou R$ 600 com corte), reforço (R$ 1.500,
ilimitado em regras), reforma (R$ 2.000, no máximo 2 compras).

- O sink de reforma **se esgota** em duas compras (`N`: 1 → 2 → 3); é o único
  sink com teto explícito.
- O sink de reforço não se esgota por regra, mas se esgota por liquidez: 5000 →
  3500 → 2000 → 500; um quarto reforço levaria a −100 e à falência (sem
  reforma, o fluxo semanal é zero).
- O salário em `N=1` consome exatamente a bilheteria (Δ = 0): **nenhuma reserva
  se acumula** enquanto o clube não investe. Reforma é o único modo de gerar
  fluxo positivo sustentado sem corte; corte gera fluxo, mas anula a força de um
  titular (`C=1`).
- Caminhos de vitória verificados (ambos com 13 pts e caixa final positivo):
  reforço s1 + reforma s2 (caixa final R$ 3.500) ou dois reforços s1/s2 (caixa
  final R$ 2.000). A reforma custa R$ 500 a mais, mas devolve R$ 1.500 a mais
  em caixa final — não há estratégia dominante degenerada entre as duas.

---

## 4. Rastros determinísticos

Legenda das colunas: `Caixa p/ custo` = caixa após debitar a decisão;
`Pós-fluxo` = caixa após bilheteria − salário; `—` = etapa não executada.

### 4.1 Vitória — reforço s1, reforma s2, escalar titulares s3–s6

| Sem | Decisão | Custo | Caixa p/ custo | Falência? | T | R | N | C | F | Pts | Pts acum | Bilheteria | Salário | Δ | Pós-fluxo |
|---:|---|---:|---:|:---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | `contratar_reforco` | −1500 | 3500 | não | 0 | 1 | 1 | 0 | 1 | 0 | 0 | 1200 | 1200 | 0 | 3500 |
| 2 | `melhorar_instalacao` | −2000 | 1500 | não | 0 | 1 | 2 | 0 | 2 | 1 | 1 | 1600 | 1200 | +400 | 1900 |
| 3 | `escalar_titulares` | 0 | 1900 | não | 1 | 1 | 2 | 0 | 3 | 3 | 4 | 1600 | 1200 | +400 | 2300 |
| 4 | `escalar_titulares` | 0 | 2300 | não | 1 | 1 | 2 | 0 | 3 | 3 | 7 | 1600 | 1200 | +400 | 2700 |
| 5 | `escalar_titulares` | 0 | 2700 | não | 1 | 1 | 2 | 0 | 3 | 3 | 10 | 1600 | 1200 | +400 | 3100 |
| 6 | `escalar_titulares` | 0 | 3100 | não | 1 | 1 | 2 | 0 | 3 | 3 | 13 | 1600 | 1200 | +400 | 3500 |

`0 + 1 + 3 + 3 + 3 + 3 = 13 ≥ 7`, caixa final R$ 3.500 > 0 → **vitória na
semana 6**. Meta é atingida na semana 4 (7 pts), mas o run continua até a
semana 6 conforme o brief.

### 4.2 Falência — reforço s1, reforma s2, reforma s3

| Sem | Decisão | Custo | Caixa p/ custo | Falência? | T | R | N | C | F | Pts | Pts acum | Bilheteria | Salário | Δ | Pós-fluxo |
|---:|---|---:|---:|:---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | `contratar_reforco` | −1500 | 3500 | não | 0 | 1 | 1 | 0 | 1 | 0 | 0 | 1200 | 1200 | 0 | 3500 |
| 2 | `melhorar_instalacao` | −2000 | 1500 | não | 0 | 1 | 2 | 0 | 2 | 1 | 1 | 1600 | 1200 | +400 | 1900 |
| 3 | `melhorar_instalacao` | −2000 | **−100** | **SIM** | — | — | — | — | — | — | 1 | — | — | — | — |

Na semana 3 o caixa cai para **−100 (< 0)** já na etapa de custo. A falência
encerra o run na hora: não há partida, não há pontos novos, não há bilheteria
nem salário da semana 3. Resultado: **falência na semana 3**, 1 ponto acumulado,
sem tela de vitória ou derrota.

### 4.3 Derrota — escalar titulares nas 6 semanas, sem reforço nem reforma

| Sem | Decisão | Custo | Caixa p/ custo | Falência? | T | R | N | C | F | Pts | Pts acum | Bilheteria | Salário | Δ | Pós-fluxo |
|---:|---|---:|---:|:---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | `escalar_titulares` | 0 | 5000 | não | 1 | 0 | 1 | 0 | 1 | 0 | 0 | 1200 | 1200 | 0 | 5000 |
| 2 | `escalar_titulares` | 0 | 5000 | não | 1 | 0 | 1 | 0 | 1 | 0 | 0 | 1200 | 1200 | 0 | 5000 |
| 3 | `escalar_titulares` | 0 | 5000 | não | 1 | 0 | 1 | 0 | 1 | 0 | 0 | 1200 | 1200 | 0 | 5000 |
| 4 | `escalar_titulares` | 0 | 5000 | não | 1 | 0 | 1 | 0 | 1 | 0 | 0 | 1200 | 1200 | 0 | 5000 |
| 5 | `escalar_titulares` | 0 | 5000 | não | 1 | 0 | 1 | 0 | 1 | 0 | 0 | 1200 | 1200 | 0 | 5000 |
| 6 | `escalar_titulares` | 0 | 5000 | não | 1 | 0 | 1 | 0 | 1 | 0 | 0 | 1200 | 1200 | 0 | 5000 |

`0 pts < 7`, caixa final R$ 5.000 > 0 → **derrota na semana 6**.

---

## 5. Divergências com `design/game-brief.md` (para consolidação)

1. **Critério 6 (falência) — corrigido neste documento.** O brief diz "caixa
   R$ 2.000 na semana 4, escolher reforma → −1600". Não fecha: a reforma custa
   R$ 2.000, o que levaria 2000 → **0**, e `0` não é `< 0`; além disso o fluxo
   da semana (bilheteria − salário) é positivo, nunca −1600. O rastro real e
   verificável é o da §4.2: reforço s1, reforma s2, reforma s3 → caixa **−100**
   na semana 3.
2. **Critério 3 (força) — valores de `F` inconsistentes com o JSON aprovado.**
   Com `starters_strength = 1`: `T=1,R=0,N=1,C=0 → F=1` (o brief afirma 2) e
   `R=1,N=2,T=1 → F=3` (o brief afirma 4). O caso `T=0,C=1 → F=−1` confere.
   Esses exemplos do brief aparentam usar `starters_strength = 2`, valor que
   **não** está no JSON contratual. Correção proposta no brief: `F=1 → 0 pts` e
   `F=3 → 3 pts`.
3. **Critério 7 (derrota) — total de pontos.** "Escalar titulares nas 6 semanas
   → 6 pts" decorre da mesma inconsistência: com `starters_strength = 1` cada
   semana rende `F=1 → 0 pts`, totalizando **0 pts**. O desfecho (derrota) não
   muda, mas o número do brief deve passar a 0.

Itens 2 e 3 são decorrentes do valor contratual `starters_strength = 1`; não
alteramos esse valor, pois faz parte do changeset aprovado.
