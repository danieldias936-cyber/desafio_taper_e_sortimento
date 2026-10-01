# =============================================================================
# Desafio 05 - Funcoes compartilhadas para taper e sortimento (Etapa 2)
# =============================================================================

EXPOENTES_HRADETZKY <- c(0.1, 0.5, 1, 2, 3, 5, 8)

# -----------------------------------------------------------------------------
# diam_taper(): diametro estimado (cm) em qualquer altura h do fuste,
# dado o modelo de taper, seus coeficientes, o DAP e a HT da arvore.
# Vetorizada em h (aceita vetor de alturas).
# -----------------------------------------------------------------------------
diam_taper <- function(modelo, coefs, dap, ht, h) {

  Z <- h / ht
  Z <- pmin(pmax(Z, 0), 1)   # nao extrapola alem do fuste (0 <= Z <= 1)

  # NOTA: indexacao posicional (coefs[1], coefs[2], ...), pois os coeficientes
  # vêm diretamente de coef(lm(...)) e carregam nomes tecnicos do R
  # (ex.: "(Intercept)", "Z", "I(Z^2)"), nao "b0", "b1", ...

  if (modelo == "kozak") {
    # (d/DAP)^2 = b0 + b1*Z + b2*Z^2
    raz2 <- coefs[1] + coefs[2] * Z + coefs[3] * Z^2
    raz2 <- pmax(raz2, 0)
    d <- dap * sqrt(raz2)

  } else if (modelo == "schopfer") {
    # d/DAP = b0 + b1*Z + b2*Z^2 + b3*Z^3 + b4*Z^4 + b5*Z^5
    raz <- coefs[1] + coefs[2] * Z + coefs[3] * Z^2 +
           coefs[4] * Z^3 + coefs[5] * Z^4 + coefs[6] * Z^5
    raz <- pmax(raz, 0)
    d <- dap * raz

  } else if (modelo == "hradetzky") {
    # d/DAP = soma bk * Z^pk , pk = 0.1, 0.5, 1, 2, 3, 5, 8
    raz <- rep(0, length(Z))
    for (k in seq_along(EXPOENTES_HRADETZKY)) {
      raz <- raz + coefs[k] * Z^EXPOENTES_HRADETZKY[k]
    }
    raz <- pmax(raz, 0)
    d <- dap * raz

  } else {
    stop("Modelo de taper desconhecido: ", modelo)
  }

  d
}

# -----------------------------------------------------------------------------
# volume_tora(): volume (m3) de uma tora entre h0 e h1, pela integracao da
# funcao de taper: V = (pi/40000) * integral[h0,h1] d(h)^2 dh  (d em cm, h em m)
# -----------------------------------------------------------------------------
volume_tora <- function(modelo, coefs, dap, ht, h0, h1) {
  if (h1 <= h0) return(0)
  integrando <- function(h) diam_taper(modelo, coefs, dap, ht, h)^2
  area_integral <- stats::integrate(integrando, lower = h0, upper = h1,
                                     rel.tol = 1e-6)$value
  (pi / 40000) * area_integral
}

# -----------------------------------------------------------------------------
# classificar_produto(): classifica uma tora segundo o diametro na ponta fina
# (topo da tora, d(h1)), por ordem de prioridade (mais valioso primeiro).
# -----------------------------------------------------------------------------
classificar_produto <- function(d_top) {
  if (d_top >= 25)      return("laminacao")
  else if (d_top >= 18) return("serraria")
  else if (d_top >= 8)  return("mourao_poste")
  else if (d_top >= 6)  return("celulose")
  else                  return(NA_character_)  # abaixo de 6 cm -> residual
}

# -----------------------------------------------------------------------------
# segmentar_arvore(): segmenta o fuste de UMA arvore em toras de
# `comprimento_tora` m a partir da altura de toco `htoco`, classifica cada
# tora no produto correspondente e calcula o volume residual.
# Retorna uma lista com: $toras (data.frame por tora) e $residual (volume, m3)
# -----------------------------------------------------------------------------
segmentar_arvore <- function(modelo, coefs, dap, ht,
                              htoco = 0.10, comprimento_tora = 2.20,
                              dmin_celulose = 6) {

  toras <- list()
  vol_residual <- 0
  h0 <- htoco

  if (ht <= htoco) {
    return(list(toras = data.frame(), residual = 0))
  }

  repeat {
    h1 <- h0 + comprimento_tora

    if (h1 > ht) {
      # nao ha comprimento suficiente para completar mais uma tora:
      # o restante do fuste (h0 ate HT) e residual
      if ((ht - h0) > 1e-9) {
        vol_residual <- vol_residual +
          volume_tora(modelo, coefs, dap, ht, h0, ht)
      }
      break
    }

    d_top <- diam_taper(modelo, coefs, dap, ht, h1)
    produto <- classificar_produto(d_top)

    if (is.na(produto)) {
      # diametro no topo da tora ja e < 6 cm: a partir daqui e tudo residual
      vol_residual <- vol_residual +
        volume_tora(modelo, coefs, dap, ht, h0, ht)
      break
    }

    vol <- volume_tora(modelo, coefs, dap, ht, h0, h1)
    toras[[length(toras) + 1]] <- data.frame(
      h0 = h0, h1 = h1, d_top = d_top, produto = produto, volume = vol
    )
    h0 <- h1
  }

  toras_df <- if (length(toras) > 0) do.call(rbind, toras) else data.frame()
  list(toras = toras_df, residual = vol_residual)
}
