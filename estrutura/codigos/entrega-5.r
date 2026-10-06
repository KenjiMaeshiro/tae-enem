set.seed(123)

# Usa só linhas completas nas variáveis do modelo
dados <- na.omit(dataset[, c("NU_NOTA_MT", "MEDIA_MT", "RENDA")])
n <- nrow(dados)

# ---- Treino/teste 70/30 ----
i_treino <- sample(n, 0.7 * n)
treino <- dados[i_treino, ]
teste  <- dados[-i_treino, ]

# ---- K-fold dentro do treino (70%) ----
k <- 5
d <- sample(rep(1:k, length.out = nrow(treino)))

cv <- function(formula) {
  mse <- sapply(1:k, function(j) {
    m <- lm(formula, data = treino[d != j, ])
    mean((treino$NU_NOTA_MT[d == j] - predict(m, treino[d == j, ]))^2)
  })
  c(MSE = mean(mse), RMSE = sqrt(mean(mse)), DP_MSE = sd(mse))
}

# ---- Avaliação final no teste (30%) ----
avalia <- function(formula) {
  m <- lm(formula, data = treino)
  mse <- mean((teste$NU_NOTA_MT - predict(m, teste))^2)
  c(MSE = mse, RMSE = sqrt(mse))
}

modelos <- list(
  "M1: MEDIA_MT"         = NU_NOTA_MT ~ MEDIA_MT,
  "M2: MEDIA_MT + RENDA" = NU_NOTA_MT ~ MEDIA_MT + RENDA
)

res_cv    <- t(sapply(modelos, cv))
res_teste <- t(sapply(modelos, avalia))

cat("\n== K-fold (", k, " folds) no treino 70% ==\n", sep = "")
print(round(res_cv, 2))
cat("\n== Teste 30% ==\n")
print(round(res_teste, 2))
cat("\nDesvio padrão de NU_NOTA_MT no teste:", round(sd(teste$NU_NOTA_MT), 2), "\n")

# ---- Bootstrap do coeficiente de MEDIA_MT (sem e com RENDA) ----
B <- 2000

boot <- function(base) {
  nb <- nrow(base)
  b <- replicate(B, {
    i <- sample(nb, nb, replace = TRUE)
    c(sem = coef(lm(NU_NOTA_MT ~ MEDIA_MT,         data = base[i, ]))[[2]],
      com = coef(lm(NU_NOTA_MT ~ MEDIA_MT + RENDA, data = base[i, ]))[[2]])
  })
  est <- c(sem = coef(lm(NU_NOTA_MT ~ MEDIA_MT,         data = base))[[2]],
           com = coef(lm(NU_NOTA_MT ~ MEDIA_MT + RENDA, data = base))[[2]])
  cbind(
    Estimativa  = est,
    Erro_padrao = apply(b, 1, sd),
    IC95_inf    = apply(b, 1, quantile, 0.025),
    IC95_sup    = apply(b, 1, quantile, 0.975)
  )
}

cat("\n== Bootstrap no treino 70% (", B, " reamostras) ==\n", sep = "")
print(round(boot(treino), 4))

cat("\n== Bootstrap nos dados completos (", B, " reamostras) ==\n", sep = "")
print(round(boot(dados), 4))
