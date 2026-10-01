# Desafio 05 — Modelagem de Taper e Estimativa de Sortimento

Talhão 8 (Filial 2, clone 1501, 7 anos, espaçamento 3×3 m, regime Reforma).

Este repositório reaproveita os artefatos dos Desafios 01 (área amostrada) e 02
(relação hipsométrica) para, a partir da base de cubagem de 36 árvores, ajustar
três modelos de taper e aplicá-los às 215 árvores do inventário, estimando o
sortimento multiproduto do talhão por hectare.

## Estrutura do repositório

```
desafio-05-taper-e-sortimento/
├── dados/
│   ├── cubagem.xlsx                 # 36 árvores cubadas (Talhão, Arv, hi, di, DAP, HT)
│   └── inventario_completo.xlsx     # 215 árvores do inventário, com HT_final
│                                       (medida ou estimada pela rel. hipsométrica
│                                       do Desafio 02) e a coluna ORIGEM_HT
├── scripts/
│   ├── 00_funcoes_taper.R           # funções compartilhadas (taper, integração,
│   │                                   segmentação em toras, classificação)
│   ├── 01_ajuste_taper.R            # Etapa 1 — ajuste e seleção do modelo de taper
│   └── 02_sortimento.R              # Etapa 2 — sortimento por hectare (3 modelos)
├── saidas/
│   ├── ajuste_taper.csv             # coeficientes, R², R² ajustado, Syx% (Etapa 1)
│   ├── coefs_taper.rds              # coeficientes salvos p/ reuso na Etapa 2
│   ├── sortimento_por_modelo.csv    # nº de toras/ha e volume/ha por modelo×produto
│   └── comparacao_sortimento.csv    # comparação dos 3 modelos vs. referência
├── figuras/
│   ├── residuos_vs_Z.png
│   ├── residuos_vs_classeDAP.png
│   ├── comparacao_volume_produto.png
│   └── comparacao_toras_produto.png
└── relatorio.md
```

Como rodar (a partir da raiz do repositório):

```r
install.packages(c("readxl", "dplyr", "tidyr", "ggplot2"))  # se necessário
source("scripts/01_ajuste_taper.R")   # Etapa 1 (gera saidas/coefs_taper.rds)
source("scripts/02_sortimento.R")     # Etapa 2 (usa o RDS da Etapa 1)
```

## Etapa 1 — Formulação exata dos modelos de taper

Em todos os modelos, `Z = hi/HT` é a altura relativa (0 a 1) e os coeficientes
foram ajustados por regressão linear (mínimos quadrados ordinários, `lm()`),
usando o conjunto de 1.125 seções medidas nas 36 árvores cubadas.

**Kozak (1969)** — polinômio de 2º grau, variável resposta `(di/DAP)²`:

```
(di/DAP)² = b0 + b1·Z + b2·Z²
```

**Schöpfer (1966)** — polinômio de 5º grau, variável resposta `di/DAP`:

```
di/DAP = b0 + b1·Z + b2·Z² + b3·Z³ + b4·Z⁴ + b5·Z⁵
```

**Hradetzky (1976)** — polinômio de potências fracionárias e inteiras, variável
resposta `di/DAP`, **sem intercepto** (a soma é definida apenas pelos termos
`bk·Z^pk`, sem um termo constante b0):

```
di/DAP = Σ bk · Z^pk ,   pk = {0,1 ; 0,5 ; 1 ; 2 ; 3 ; 5 ; 8}
```

Os expoentes `pk` usados foram exatamente os sugeridos no enunciado do
desafio: 0,1 — 0,5 — 1 — 2 — 3 — 5 — 8. Essa escolha cobre tanto a curvatura
acentuada perto da base do fuste (expoentes fracionários, que crescem rápido
para Z pequeno) quanto o afilamento mais suave em direção ao topo (expoentes
inteiros maiores).

Em todos os três casos, o diâmetro predito é obtido revertendo a
transformação (multiplicando por DAP e, no caso de Kozak, extraindo a raiz
quadrada), sempre truncando a razão em zero antes da transformação inversa
(`pmax(razão, 0)`) para impedir diâmetros negativos por extrapolação do
polinômio perto da ponta do fuste.

### Avaliação e seleção do modelo (36 árvores, 1.125 seções)

Métricas calculadas na escala comum do diâmetro (`di`, cm) — e não na escala
transformada de cada modelo — para permitir comparação direta entre eles:

| Modelo            | R²     | R² ajustado | Syx (%) |
|-------------------|--------|-------------|---------|
| Kozak (1969)      | 0,9777 | 0,9776      | 6,42    |
| Schöpfer (1966)   | 0,9895 | 0,9894      | 4,42    |
| **Hradetzky (1976)** | **0,9910** | **0,9909** | **4,09** |

**Modelo selecionado: Hradetzky (1976).**

Justificativa técnica:
1. **Melhor desempenho estatístico em todos os critérios simultaneamente**:
   maior R² e R² ajustado, e o menor erro padrão da estimativa em percentual
   (Syx% = 4,09%, contra 4,42% do Schöpfer e 6,42% do Kozak), mesmo com um
   parâmetro a mais que o Schöpfer (7 vs. 6).
2. **Análise gráfica dos resíduos** (`figuras/residuos_vs_Z.png` e
   `residuos_vs_classeDAP.png`): o Kozak mostra um padrão sistemático nítido
   — resíduos fortemente positivos perto da base (Z próximo de 0) e
   fortemente negativos perto do topo (Z próximo de 1), evidenciando que o
   polinômio de 2º grau é rígido demais para capturar tanto o afinamento
   rápido da base quanto o efeito de "ponta" do fuste. Schöpfer e Hradetzky
   têm resíduos mais dispersos em torno de zero ao longo de todo o perfil,
   sem padrão de tendência evidente; entre os dois, o Hradetzky apresenta
   menor dispersão nas classes de DAP mais altas.
3. **Flexibilidade funcional**: as potências fracionárias do Hradetzky
   (0,1 e 0,5) dão ao modelo mais liberdade para acomodar a curvatura abrupta
   próxima à base (efeito de sapopema/alargamento basal), reduzindo o viés
   sistemático que aparece no Kozak nessa região.

O modelo de Hradetzky é, portanto, tratado na Etapa 2 como a referência de
maior precisão para comparação com os outros dois.

## Etapa 2 — Sortimento por hectare

### Especificações adotadas (idênticas às do enunciado)

| Produto        | Diâmetro mínimo na ponta fina | Comprimento da tora |
|----------------|-------------------------------|----------------------|
| Laminação      | ≥ 25 cm                       | 2,20 m               |
| Serraria       | ≥ 18 cm (e < 25 cm)            | 2,20 m               |
| Mourão/Poste   | ≥ 8 cm (e < 18 cm)             | 2,20 m               |
| Celulose       | ≥ 6 cm (e < 8 cm)              | 2,20 m               |
| Residual       | < 6 cm                         | variável (sobra final) |

### Algoritmo de segmentação (`segmentar_arvore()` em `00_funcoes_taper.R`)

1. Parte-se da altura de toco `h0 = 0,10 m`.
2. Enquanto houver comprimento suficiente (`h0 + 2,20 ≤ HT`):
   - calcula-se o diâmetro no topo da tora, `d(h1)`, pela função de taper do
     modelo em uso;
   - se `d(h1) < 6 cm`, todo o restante do fuste (de `h0` até `HT`) é
     contabilizado como **volume residual** e a árvore é encerrada;
   - caso contrário, a tora é classificada no produto de maior valor cujo
     diâmetro mínimo ela atenda (laminação > serraria > mourão/poste >
     celulose), seu volume é calculado por integração da função de taper
     (ver abaixo), e avança-se `h0 = h1`.
3. Se em algum momento não houver mais 2,20 m de fuste disponível
   (`h0 + 2,20 > HT`), o trecho final (`h0` até `HT`) é todo residual.

### Volume por integração (não por Smalian)

O volume de cada tora é obtido por integração numérica (`stats::integrate`)
da função de taper ao longo do comprimento da tora:

```
V(h0, h1) = (π / 40000) · ∫[h0, h1] d(h)² dh      (d em cm, h em m, V em m³)
```

onde `d(h)` é o diâmetro estimado pela função de taper do modelo em uso.

### Expansão para 1 hectare

Área amostrada (Desafio 01): 5 parcelas de 0,0441 ha e 1 parcela de 0,0378 ha
→ área total amostrada = **0,2583 ha**.

```
fator de expansão = 10.000 m² / (0,2583 ha × 10.000 m²/ha) = 1 / 0,2583 ≈ 3,8715
```

Esse fator multiplica o número de toras e o volume de cada produto, somados
sobre as 215 árvores, para obter as estimativas por hectare.

### Alturas do inventário

A HT usada é a coluna `HT_final` de `inventario_completo.xlsx`, produzida no
Desafio 02: medida diretamente nas fileiras centrais (3, 4 e 5; 109 árvores)
e estimada pelo modelo hipsométrico de Chapman-Richards
(`HT = 32,739·(1 − e^(−0,2227·DAP))^5,333`, R² = 0,9207) nas fileiras
periféricas (1, 2, 6 e 7; 106 árvores).

## Principais resultados (ver `relatorio.md` para a análise completa)

- Nenhum dos três modelos gerou toras de **laminação** nesse povoamento: o
  DAP máximo observado (≈ 22 cm) é insuficiente para produzir uma ponta fina
  ≥ 25 cm mesmo na primeira tora da base.
- O volume total por hectare (soma de todos os produtos + residual) ficou
  muito próximo entre os três modelos (≈ 225–231 m³/ha), o que é esperado,
  já que os três ajustes tiveram bons R² na Etapa 1.
- As maiores divergências entre modelos aparecem na **repartição entre
  serraria e mourão/poste**: o Kozak, por ter um viés sistemático de
  superestimar o diâmetro perto do topo das primeiras toras (ver análise de
  resíduos da Etapa 1), classifica bem mais toras como serraria do que os
  outros dois modelos (418 toras/ha vs. 209 do Hradetzky, uma diferença de
  +100%).
