# =============================================================================
# Desafio 05 - Etapa 2: Estimativa de sortimento por hectare
# Talhao 8 - 215 arvores do inventario (inventario_completo.xlsx)
# Aplica os 3 modelos de taper ajustados na Etapa 1
# =============================================================================

library(readxl)
library(dplyr)

source("scripts/00_funcoes_taper.R")

# --- 1. Entradas -------------------------------------------------------------

coefs_taper <- readRDS("saidas/coefs_taper.rds")

inv <- read_excel("dados/inventario_completo.xlsx")
names(inv) <- c("filial","idade","regime","espacamento","clone","mes_plantio",
                 "ai","talhao","sitio","parcela","fileira","arvore",
                 "dap","ht","ht_estimada","ht_final","origem_ht")

cat("N arvores no inventario:", nrow(inv), "\n")
cat("HT medida:", sum(inv$origem_ht == "medida"),
    "| HT estimada (rel. hipsometrica, Desafio 02):",
    sum(inv$origem_ht == "estimada"), "\n")

# Area amostrada (Desafio 01): 5 parcelas de 0,0441 ha + 1 parcela de 0,0378 ha
area_parcelas_ha <- c(0.0441, 0.0441, 0.0441, 0.0441, 0.0441, 0.0378)
area_total_ha    <- sum(area_parcelas_ha)
fator_expansao   <- 10000 / (area_total_ha * 10000)   # = 1 / area_total_ha

cat("Area total amostrada:", area_total_ha, "ha\n")
cat("Fator de expansao para 1 ha:", round(fator_expansao, 4), "\n\n")

htoco            <- 0.10
comprimento_tora <- 2.20
dmin_celulose    <- 6

modelos <- c("kozak", "schopfer", "hradetzky")
coefs_por_modelo <- list(
  kozak     = coefs_taper$kozak,
  schopfer  = coefs_taper$schopfer,
  hradetzky = coefs_taper$hradetzky
)
# O nome selecionado na Etapa 1 vem no formato "Hradetzky (1976)"; mapeamos
# para a chave curta usada aqui ("kozak" / "schopfer" / "hradetzky").
mapa_nomes <- c("Kozak (1969)" = "kozak",
                "Schopfer (1966)" = "schopfer",
                "Hradetzky (1976)" = "hradetzky")
melhor_modelo_etapa1 <- mapa_nomes[[coefs_taper$melhor_modelo]]
cat("Modelo de referencia (selecionado na Etapa 1):", melhor_modelo_etapa1, "\n\n")

# --- 2. Aplicacao dos 3 modelos as 215 arvores -------------------------------

resultado_arvores <- list()

for (modelo in modelos) {
  coefs <- coefs_por_modelo[[modelo]]

  for (i in seq_len(nrow(inv))) {
    dap <- inv$dap[i]
    ht  <- inv$ht_final[i]

    seg <- segmentar_arvore(modelo, coefs, dap, ht,
                             htoco = htoco,
                             comprimento_tora = comprimento_tora,
                             dmin_celulose = dmin_celulose)

    if (nrow(seg$toras) > 0) {
      tab_prod <- seg$toras %>%
        group_by(produto) %>%
        summarise(n_toras = n(), volume = sum(volume), .groups = "drop")
    } else {
      tab_prod <- data.frame(produto = character(), n_toras = integer(),
                              volume = numeric())
    }

    tab_prod <- bind_rows(
      tab_prod,
      data.frame(produto = "residual", n_toras = 0, volume = seg$residual)
    )

    tab_prod$modelo <- modelo
    tab_prod$arvore_id <- i
    resultado_arvores[[length(resultado_arvores) + 1]] <- tab_prod
  }
  cat("Modelo", modelo, "processado (215 arvores).\n")
}

resultado_arvores <- bind_rows(resultado_arvores)

# --- 3. Consolidacao por modelo x produto, expandido para 1 ha --------------

produtos_ordem <- c("laminacao", "serraria", "mourao_poste", "celulose", "residual")

sortimento_por_modelo <- resultado_arvores %>%
  group_by(modelo, produto) %>%
  summarise(
    n_toras_amostra = sum(n_toras),
    volume_amostra_m3 = sum(volume),
    .groups = "drop"
  ) %>%
  tidyr::complete(modelo = modelos, produto = produtos_ordem,
                   fill = list(n_toras_amostra = 0, volume_amostra_m3 = 0)) %>%
  mutate(
    n_toras_ha = n_toras_amostra * fator_expansao,
    volume_ha_m3 = volume_amostra_m3 * fator_expansao,
    produto = factor(produto, levels = produtos_ordem)
  ) %>%
  arrange(modelo, produto) %>%
  mutate(produto = as.character(produto)) %>%
  select(modelo, produto, n_toras_ha, volume_ha_m3)

dir.create("saidas", showWarnings = FALSE)
write.csv(sortimento_por_modelo, "saidas/sortimento_por_modelo.csv",
          row.names = FALSE)

cat("\n=== Sortimento por modelo x produto (por hectare) ===\n")
print(sortimento_por_modelo, n = 20)

# --- 4. Comparacao entre os 3 modelos, tomando o de referencia (Etapa 1) ----

referencia <- sortimento_por_modelo %>%
  filter(modelo == melhor_modelo_etapa1) %>%
  select(produto, n_toras_ha_ref = n_toras_ha, volume_ha_m3_ref = volume_ha_m3)

comparacao_sortimento <- sortimento_por_modelo %>%
  left_join(referencia, by = "produto") %>%
  mutate(
    referencia_etapa1 = (modelo == melhor_modelo_etapa1),
    dif_n_toras_ha   = n_toras_ha - n_toras_ha_ref,
    dif_pct_n_toras  = ifelse(n_toras_ha_ref > 0,
                               dif_n_toras_ha / n_toras_ha_ref * 100, NA),
    dif_volume_ha_m3 = volume_ha_m3 - volume_ha_m3_ref,
    dif_pct_volume   = ifelse(volume_ha_m3_ref > 0,
                               dif_volume_ha_m3 / volume_ha_m3_ref * 100, NA)
  ) %>%
  select(modelo, produto, referencia_etapa1, n_toras_ha, volume_ha_m3,
         dif_n_toras_ha, dif_pct_n_toras, dif_volume_ha_m3, dif_pct_volume)

write.csv(comparacao_sortimento, "saidas/comparacao_sortimento.csv",
          row.names = FALSE)

cat("\n=== Comparacao entre modelos (referencia:", melhor_modelo_etapa1, ") ===\n")
print(comparacao_sortimento, n = 20)

# --- 5. Grafico comparativo (volume/ha por produto e modelo) ----------------

library(ggplot2)

p_comp <- ggplot(sortimento_por_modelo,
                  aes(x = factor(produto, levels = produtos_ordem),
                      y = volume_ha_m3, fill = modelo)) +
  geom_col(position = "dodge") +
  labs(x = "Produto", y = expression(Volume~(m^3/ha)),
       title = "Volume por produto e por hectare - comparacao entre modelos de taper",
       fill = "Modelo") +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 15, hjust = 1))

dir.create("figuras", showWarnings = FALSE)
ggsave("figuras/comparacao_volume_produto.png", p_comp, width = 8, height = 5, dpi = 150)

p_comp_n <- ggplot(sortimento_por_modelo %>% filter(produto != "residual"),
                    aes(x = factor(produto, levels = produtos_ordem),
                        y = n_toras_ha, fill = modelo)) +
  geom_col(position = "dodge") +
  labs(x = "Produto", y = "N de toras / ha",
       title = "Numero de toras por produto e por hectare - comparacao entre modelos",
       fill = "Modelo") +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 15, hjust = 1))
ggsave("figuras/comparacao_toras_produto.png", p_comp_n, width = 8, height = 5, dpi = 150)

cat("\nArquivos gerados em saidas/: sortimento_por_modelo.csv, comparacao_sortimento.csv\n")
cat("Figuras geradas em figuras/: comparacao_volume_produto.png, comparacao_toras_produto.png\n")
