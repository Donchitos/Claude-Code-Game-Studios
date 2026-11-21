# Clube do Bairro — Game Brief (fatia vertical)

**Visão:** Num clube de bairro com dinheiro curto, cada semana você escolhe entre escalar, reformar ou economizar — e uma decisão errada fecha as portas.

## Loop (6 semanas)
`ler painel → escolher 1 decisão → partida simulada → receitas/despesas → atualizar meta → próximo turno`

Repetir exatamente 6 vezes (semanas 1–6). Painel mostra: semana, caixa, pontos, nível `N`, reforços `R`, salário vigente.

## Decisões — exatamente 1 por semana
| Decisão | Efeito na semana | Efeito permanente |
|---|---|---|
| Escalar titulares | `T = 1` (senão `T = 0`) | nenhum |
| Contratar reforço | `−R$ 1.500`; `R += 1` | `+1` força nas semanas seguintes |
| Melhorar instalação | `−R$ 2.000`; `N += 1` (máx. 3) | bilheteria e força acompanham `N` |
| Cortar gastos | salário `R$ 600`; `C = 1` | nenhum |

## Sistemas e regras
- **Escalação:** `F = T + R + (N − 1) − C`, com `T, C ∈ {0,1}`, `R` = reforços acumulados, `N ∈ {1,2,3}` (inicia 1).
- **Partida:** determinística, sem aleatoriedade: `F ≥ 3 → 3 pts`; `F = 2 → 1 pt`; `F ≤ 1 → 0 pts`.
- **Orçamento:** bilheteria `800 + 400 × N` creditada após a decisão; salário `R$ 1.200` debitado (`R$ 600` com corte). Compras podem deixar o caixa negativo.
- **Metas:** `7 pontos` em `6` jogos.
- **Fim de run:** falência (`caixa < 0`) encerra imediatamente após qualquer mutação de caixa e tem precedência sobre o desfecho da semana 6. Sobrevivendo à semana 6: `≥ 7 pts` = vitória; `< 7 pts` = derrota.

## Números-base
| Parâmetro | Valor |
|---|---|
| Caixa inicial | R$ 5.000 |
| Salário semanal | R$ 1.200 (`R$ 600` com corte) |
| Bilheteria | `800 + 400 × N` |
| Reforço | R$ 1.500 (uma vez, `+1` força) |
| Reforma | R$ 2.000 (`N + 1`, máx. 3) |
| Meta | 7 pts em 6 jogos |
| Falência | `caixa < 0` |

## Fora do escopo
Partida em tempo real, IA elaborada, transferências, arbitragem, salvamento, múltiplas temporadas, arte/áudio/narrativa.

## Critérios de aceite
1. **Inicial:** semana 1, caixa `5000`, `0 pts`, `N=1`, `R=0`.
2. **Turno:** 1 decisão por semana, 6 no total; painel atualizado entre turnos; sem turnos extras.
3. **Força:** `N=1,R=0,T=1,C=0 → F=1 → 0 pts`; `R=1,N=2,T=1,C=0 → F=3 → 3 pts`; `T=0,C=1 → F=−1 → 0 pts`.
4. **Caixa:** sem custos, `N=1 → Δ0`, `N=2 → Δ+400`, `N=3 → Δ+800`.
5. **Vitória:** reforço s1, reforma s2, escalar titulares s3–s6 → `0+1+3+3+3+3 = 13 pts`, caixa final R$ 3.500 → tela de vitória.
6. **Falência:** reforço s1, reforma s2, reforma s3 → caixa `−100` na semana 3 → encerra na hora, sem partida nem vitória/derrota.
7. **Derrota:** escalar titulares nas 6 semanas, sem reforço/reforma → `0 pts`, caixa `5000` → derrota na semana 6.
8. **Limites:** `N` nunca passa de 3; reforços acumulam; corte vale só na semana corrente.
