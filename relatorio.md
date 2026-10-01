# Relatório — Desafio 05: Modelagem de Taper e Estimativa de Sortimento

**Talhão 8** — Filial 2, clone 1501, idade 7 anos, espaçamento 3×3 m, regime Reforma.

---

## Parte A — Etapa 1: comparação estatística dos três modelos de taper

Os três modelos foram ajustados usando as 1.125 seções medidas nas 36 árvores
cubadas (`cubagem.xlsx`), por regressão linear em `Z = hi/HT`. As métricas
abaixo foram calculadas na escala do diâmetro observado (`di`, cm), e não na
escala transformada de cada modelo, para permitir comparação direta.

| Modelo            | Nº de parâmetros | R²     | R² ajustado | Syx (%) |
|-------------------|:---:|--------|-------------|---------|
| Kozak (1969)      | 3 | 0,9777 | 0,9776      | 6,42    |
| Schöpfer (1966)   | 6 | 0,9895 | 0,9894      | 4,42    |
| **Hradetzky (1976)** | 7 | **0,9910** | **0,9909** | **4,09** |

O Hradetzky apresenta o melhor ajuste nos três critérios simultaneamente,
mesmo descontando o parâmetro extra em relação ao Schöpfer.

**Análise gráfica dos resíduos** (`figuras/residuos_vs_Z.png`): o Kozak exibe
um padrão sistemático nítido — resíduos positivos concentrados perto da base
do fuste (Z → 0, onde o modelo subestima o diâmetro real) e resíduos
fortemente negativos perto do topo (Z → 1, onde superestima), formando um
"U" invertido característico de um polinômio de 2º grau tentando acomodar uma
curva de afilamento com inflexões que ele não consegue capturar. Schöpfer e
Hradetzky não mostram esse padrão de tendência; os resíduos ficam
razoavelmente centrados em zero ao longo de todo o perfil relativo.

Por classe de DAP (`figuras/residuos_vs_classeDAP.png`), o Kozak também
mantém maior dispersão e viés nas árvores de maior diâmetro (classe
14,4–18,8 cm), enquanto Hradetzky e Schöpfer se comportam de forma mais
estável entre classes.

**Modelo selecionado: Hradetzky (1976)**, com expoentes
`pk = {0,1 ; 0,5 ; 1 ; 2 ; 3 ; 5 ; 8}`, tratado como referência de maior
precisão na Etapa 2.

---

## Parte B — Etapa 2: sortimento por hectare (3 modelos)

Aplicando os três modelos ajustados às 215 árvores do inventário (alturas
completas do Desafio 02: 109 medidas + 106 estimadas por Chapman-Richards),
segmentando o fuste em toras de 2,20 m a partir do toco de 0,10 m e
calculando o volume de cada tora por integração da função de taper, obteve-se
(expandido para 1 ha, fator de expansão = 3,8715):

| Modelo    | Produto       | Nº toras/ha | Volume/ha (m³) |
|-----------|---------------|------------:|---------------:|
| Hradetzky | Laminação     | 0           | 0,00            |
| Hradetzky | Serraria      | 209         | 14,66           |
| Hradetzky | Mourão/Poste  | 6.148       | 189,75          |
| Hradetzky | Celulose      | 1.204       | 12,36           |
| Hradetzky | Residual      | —           | 8,34            |
| **Hradetzky — total** |   |             | **225,12**      |
| Kozak     | Laminação     | 0           | 0,00            |
| Kozak     | Serraria      | 418         | 28,46           |
| Kozak     | Mourão/Poste  | 5.850       | 178,60          |
| Kozak     | Celulose      | 1.359       | 13,76           |
| Kozak     | Residual      | —           | 9,59            |
| **Kozak — total** |       |             | **230,42**      |
| Schöpfer  | Laminação     | 0           | 0,00            |
| Schöpfer  | Serraria      | 228         | 16,11           |
| Schöpfer  | Mourão/Poste  | 6.063       | 187,23          |
| Schöpfer  | Celulose      | 1.254       | 12,84           |
| Schöpfer  | Residual      | —           | 8,73            |
| **Schöpfer — total** |    |             | **224,90**      |

(ver `figuras/comparacao_volume_produto.png` e `comparacao_toras_produto.png`)

### Comparação com o modelo de referência (Hradetzky)

| Produto | Kozak vs. Hradetzky | Schöpfer vs. Hradetzky |
|---|---|---|
| Serraria (toras/ha) | +209 (+100 %) | +19 (+9,3 %) |
| Serraria (m³/ha) | +13,79 (+94,1 %) | +1,44 (+9,8 %) |
| Mourão/Poste (toras/ha) | −298 (−4,8 %) | −85 (−1,4 %) |
| Mourão/Poste (m³/ha) | −11,15 (−5,9 %) | −2,52 (−1,3 %) |
| Celulose (toras/ha) | +155 (+12,9 %) | +50 (+4,2 %) |
| Celulose (m³/ha) | +1,40 (+11,3 %) | +0,47 (+3,8 %) |
| Residual (m³/ha) | +1,24 (+14,9 %) | +0,38 (+4,6 %) |
| **Volume total (m³/ha)** | +5,30 (+2,4 %) | −0,22 (−0,1 %) |

---

## Parte C — Análise geral e implicações práticas

**Consistência do volume total.** O volume total por hectare (soma de todos
os produtos + residual) é muito próximo entre os três modelos — 225,1 m³/ha
(Hradetzky), 230,4 m³/ha (Kozak) e 224,9 m³/ha (Schöpfer), uma amplitude de
apenas 2,4%. Isso é esperado: mesmo o pior dos três ajustes (Kozak, Syx% =
6,4%) ainda descreve razoavelmente bem o volume total do fuste, já que erros
de forma ao longo do perfil tendem a se compensar quando integrados no fuste
inteiro. O impacto real da escolha do modelo aparece na **repartição entre
produtos**, não no volume agregado.

**Divergência na classificação de produtos.** A diferença mais expressiva
está entre serraria e mourão/poste. O Kozak, por superestimar o diâmetro
próximo ao topo do fuste em relação ao Hradetzky (viés visível nos resíduos
da Etapa 1, especialmente na porção intermediária/superior do perfil),
classifica praticamente o dobro de toras como serraria (418 vs. 209
toras/ha) — um erro de classificação que, na prática, tem consequência
comercial direta: log de serraria vale mais que log de mourão/poste, então o
modelo de Kozak levaria a uma expectativa de receita mais otimista do que a
que o talhão de fato entrega, se o Hradetzky (o modelo com melhor ajuste
estatístico) for tomado como a estimativa mais confiável. O Schöpfer, por ter
um ajuste estatístico próximo ao do Hradetzky, produz estimativas de
sortimento bem mais próximas da referência (diferenças de apenas 1–10% por
produto).

**Ausência de laminação.** Nenhum dos três modelos gerou toras de laminação
(diâmetro mínimo de 25 cm na ponta fina) em nenhuma árvore do talhão. Isso é
coerente com a caracterização diamétrica do próprio talhão (Desafio 01: DAP
médio de 15,8 cm, máximo de 22,1 cm) — mesmo a primeira tora da base
(diâmetro próximo ao DAP) fica abaixo do limiar de laminação na quase
totalidade das árvores. Esse resultado não é uma falha da modelagem; é
esperado para um povoamento de eucalipto de 7 anos nesse regime de manejo, e
reforça que o sortimento real do talhão está concentrado em produtos de menor
valor agregado (mourão/poste é, disparado, o produto dominante em volume nos
três modelos).

**Implicações para o planejamento.** Como o volume total é robusto à escolha
do modelo mas a repartição por produto não é, o planejamento de venda por
sortimento (quantas toras destinar a cada comprador/uso) é mais sensível à
qualidade do ajuste de taper do que o planejamento de volume total (por
exemplo, para fins de cubagem de estoque em pé). Isso reforça a importância
do critério de seleção da Etapa 1 (análise de resíduos ao longo do perfil, e
não apenas R² global): um modelo com R² alto mas resíduos sistematicamente
enviesados numa faixa do fuste (como o Kozak) pode levar a decisões de
sortimento comercialmente equivocadas mesmo quando a estimativa de volume
total do povoamento continua parecendo adequada.

**Limitações.** (a) A relação hipsométrica usada para completar a altura das
106 árvores das fileiras periféricas foi ajustada apenas com árvores das
fileiras centrais (Desafio 02); se a relação DAP×HT for de fato diferente nas
bordas, esse viés se propaga para o sortimento de todas as árvores cuja
altura foi estimada. (b) Os três modelos de taper foram ajustados com apenas
36 árvores cubadas; a amplitude de DAP nessa amostra (5,64–18,74 cm) é
ligeiramente mais estreita que a do inventário completo (até 22,1 cm),
exigindo pequena extrapolação do taper para as árvores mais grossas do
talhão. (c) A classificação de produto usa apenas o diâmetro no topo da tora
(d(h1)), conforme especificado no enunciado; toras com afilamento acentuado
dentro do próprio comprimento de 2,20 m podem, na prática, ter parte de seu
volume abaixo do diâmetro mínimo mesmo quando classificadas num produto de
maior exigência — uma simplificação padrão em estudos de sortimento, mas que
tende a favorecer levemente os produtos de maior valor.
