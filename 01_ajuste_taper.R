# =============================================================================
# Desafio 05 - Etapa 1: Ajuste e selecao do modelo de taper
# Talhao 8 - 36 arvores cubadas (cubagem.xlsx)
# =============================================================================

library(readxl)
library(dplyr)
library(ggplot2)

set.seed(42)

# --- 1. Leitura e preparacao dos dados -------------------------------------

cub <- read_excel("dados/cubagem.xlsx")
names(cub) <- c("talhao", "arv", "hi", "di", "dap", "ht")

# Variaveis de taper: altura relativa (Z) e razao di/DAP
cub <- cub %>%
  mutate(
    Z      = hi / ht,          # altura relativa (0 a 1)
    y_lin  = di / dap,         # razao di/DAP  (Schopfer, Hradetzky)
    y_quad = (di / dap)^2      # razao ao quadrado (Kozak)
  )

cat("N arvores:", length(unique(cub$arv)), "\n")
cat("N secoes:", nrow(cub), "\n")

# --- 2. Ajuste dos tres modelos de taper ------------------------------------

# Modelo 1: Kozak (1969) - polinomio de 2o grau
# (di/DAP)^2 = b0 + b1*Z + b2*Z^2
mod_kozak <- lm(y_quad ~ Z + I(Z^2), data = cub)

# Modelo 2: Schopfer (1966) - polinomio de 5o grau
# di/DAP = b0 + b1*Z + b2*Z^2 + b3*Z^3 + b4*Z^4 + b5*Z^5
mod_schopfer <- lm(y_lin ~ Z + I(Z^2) + I(Z^3) + I(Z^4) + I(Z^5), data = cub)

# Modelo 3: Hradetzky (1976) - polinomio de potencias fracionarias e inteiras
# di/DAP = soma bk * Z^pk , pk = 0.1, 0.5, 1, 2, 3, 5, 8  (sem intercepto,
# conforme a formulacao Sum b_k Z^pk do enunciado)
expoentes_hradetzky <- c(0.1, 0.5, 1, 2, 3, 5, 8)
cub <- cub %>%
  mutate(
    Z_p1 = Z^0.1, Z_p2 = Z^0.5, Z_p3 = Z^1, Z_p4 = Z^2,
    Z_p5 = Z^3,   Z_p6 = Z^5,   Z_p7 = Z^8
  )
mod_hradetzky <- lm(y_lin ~ 0 + Z_p1 + Z_p2 + Z_p3 + Z_p4 + Z_p5 + Z_p6 + Z_p7,
                     data = cub)

# --- 3. Funcoes de predicao do diametro (di, em cm) na escala original ------
# Usadas para calcular Syx% e R2 numa base comum (di), pois os 3 modelos tem
# variaveis-resposta transformadas diferentes (y_quad vs y_lin).

pred_di_kozak <- function(coefs, dap, Z) {
  raz2 <- coefs[1] + coefs[2] * Z + coefs[3] * Z^2
  raz2 <- pmax(raz2, 0)
  dap * sqrt(raz2)
}

pred_di_schopfer <- function(coefs, dap, Z) {
  raz <- coefs[1] + coefs[2] * Z + coefs[3] * Z^2 + coefs[4] * Z^3 +
         coefs[5] * Z^4 + coefs[6] * Z^5
  raz <- pmax(raz, 0)
  dap * raz
}

pred_di_hradetzky <- function(coefs, dap, Z, pk = expoentes_hradetzky) {
  raz <- rep(0, length(Z))
  for (k in seq_along(pk)) raz <- raz + coefs[k] * Z^pk[k]
  raz <- pmax(raz, 0)
  dap * raz
}

cub$di_pred_kozak     <- pred_di_kozak(coef(mod_kozak), cub$dap, cub$Z)
cub$di_pred_schopfer  <- pred_di_schopfer(coef(mod_schopfer), cub$dap, cub$Z)
cub$di_pred_hradetzky <- pred_di_hradetzky(coef(mod_hradetzky), cub$dap, cub$Z)

# --- 4. Metricas de avaliacao (na escala de di, cm) -------------------------

avaliar_modelo <- function(di_obs, di_pred, n_par) {
  n    <- length(di_obs)
  res  <- di_obs - di_pred
  sqe  <- sum(res^2)
  sqt  <- sum((di_obs - mean(di_obs))^2)
  r2   <- 1 - sqe / sqt
  r2aj <- 1 - (1 - r2) * (n - 1) / (n - n_par - 1)
  syx  <- sqrt(sqe / (n - n_par))
  syx_pct <- syx / mean(di_obs) * 100
  list(R2 = r2, R2_ajustado = r2aj, Syx = syx, Syx_pct = syx_pct, n = n)
}

met_kozak     <- avaliar_modelo(cub$di, cub$di_pred_kozak,     n_par = 3)
met_schopfer  <- avaliar_modelo(cub$di, cub$di_pred_schopfer,  n_par = 6)
met_hradetzky <- avaliar_modelo(cub$di, cub$di_pred_hradetzky, n_par = 7)

cat("\n--- Kozak ---\n");     print(met_kozak)
cat("\n--- Schopfer ---\n");  print(met_schopfer)
cat("\n--- Hradetzky ---\n"); print(met_hradetzky)

# --- 5. Consolidacao dos coeficientes e metricas (ajuste_taper.csv) ---------

linhas <- list()

linhas[[1]] <- data.frame(
  modelo = "Kozak (1969)",
  coeficiente = paste0("b", 0:2),
  valor = as.numeric(coef(mod_kozak)),
  R2 = met_kozak$R2, R2_ajustado = met_kozak$R2_ajustado,
  Syx_pct = met_kozak$Syx_pct
)

linhas[[2]] <- data.frame(
  modelo = "Schopfer (1966)",
  coeficiente = paste0("b", 0:5),
  valor = as.numeric(coef(mod_schopfer)),
  R2 = met_schopfer$R2, R2_ajustado = met_schopfer$R2_ajustado,
  Syx_pct = met_schopfer$Syx_pct
)

linhas[[3]] <- data.frame(
  modelo = "Hradetzky (1976)",
  coeficiente = paste0("b_p", expoentes_hradetzky),
  valor = as.numeric(coef(mod_hradetzky)),
  R2 = met_hradetzky$R2, R2_ajustado = met_hradetzky$R2_ajustado,
  Syx_pct = met_hradetzky$Syx_pct
)

ajuste_taper <- bind_rows(linhas)
dir.create("saidas", showWarnings = FALSE)
write.csv(ajuste_taper, "saidas/ajuste_taper.csv", row.names = FALSE)

# --- 6. Analise grafica dos residuos ----------------------------------------

dir.create("figuras", showWarnings = FALSE)

cub_res <- cub %>%
  mutate(
    res_kozak     = di - di_pred_kozak,
    res_schopfer  = di - di_pred_schopfer,
    res_hradetzky = di - di_pred_hradetzky,
    classe_dap = cut(dap, breaks = 3)
  ) %>%
  select(arv, Z, dap, res_kozak, res_schopfer, res_hradetzky, classe_dap) %>%
  tidyr::pivot_longer(cols = starts_with("res_"), names_to = "modelo",
                       values_to = "residuo") %>%
  mutate(modelo = recode(modelo,
                          res_kozak = "Kozak",
                          res_schopfer = "Schopfer",
                          res_hradetzky = "Hradetzky"))

p_res_Z <- ggplot(cub_res, aes(x = Z, y = residuo)) +
  geom_point(alpha = 0.4, size = 1) +
  geom_hline(yintercept = 0, color = "red") +
  facet_wrap(~modelo) +
  labs(x = "Altura relativa (Z = hi/HT)", y = "Residuo (di obs - di pred, cm)",
       title = "Residuos ao longo do perfil do fuste, por modelo") +
  theme_bw()
ggsave("figuras/residuos_vs_Z.png", p_res_Z, width = 9, height = 4, dpi = 150)

p_res_dap <- ggplot(cub_res, aes(x = classe_dap, y = residuo)) +
  geom_boxplot() +
  geom_hline(yintercept = 0, color = "red") +
  facet_wrap(~modelo) +
  labs(x = "Classe de DAP", y = "Residuo (di obs - di pred, cm)",
       title = "Residuos por classe de DAP, por modelo") +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 20, hjust = 1))
ggsave("figuras/residuos_vs_classeDAP.png", p_res_dap, width = 9, height = 4, dpi = 150)

# --- 7. Selecao do melhor modelo ---------------------------------------------

resumo <- ajuste_taper %>%
  group_by(modelo) %>%
  summarise(R2 = first(R2), R2_ajustado = first(R2_ajustado),
            Syx_pct = first(Syx_pct)) %>%
  arrange(Syx_pct)

cat("\n=== Resumo comparativo (ordenado por Syx%) ===\n")
print(resumo)

melhor_modelo <- resumo$modelo[1]
cat("\nModelo selecionado (menor Syx%, maior R2 ajustado):", melhor_modelo, "\n")

# Salva os coeficientes de cada modelo em formato de lista (para reuso na Etapa 2)
coefs_para_etapa2 <- list(
  kozak     = coef(mod_kozak),
  schopfer  = coef(mod_schopfer),
  hradetzky = coef(mod_hradetzky),
  expoentes_hradetzky = expoentes_hradetzky,
  melhor_modelo = melhor_modelo
)
saveRDS(coefs_para_etapa2, "saidas/coefs_taper.rds")

cat("\nArquivos gerados em saidas/: ajuste_taper.csv, coefs_taper.rds\n")
cat("Figuras geradas em figuras/: residuos_vs_Z.png, residuos_vs_classeDAP.png\n")
