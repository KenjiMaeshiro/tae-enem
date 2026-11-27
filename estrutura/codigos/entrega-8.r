library(splines); library(mgcv)
d <- dataset[dataset$TP_COR_RACA %in% 1:5, ]
d <- na.omit(data.frame(y = as.numeric(d$TP_COR_RACA != 1), x1 = d$MEDIA, x2 = d$RENDA_SM, x3 = d$MEDIA_MT))
set.seed(1); dobra <- sample(rep(1:5, length = nrow(d)))
cv_de <- function(ajusta) mean(sapply(1:5, function(j){   # CV(5) de um modelo
  tr <- d[dobra != j, ]; va <- d[dobra == j, ]
  mean((va$y - ajusta(tr, va))^2)
}))
cv_de(function(tr, va) mean(tr$y))                                          # linha de base
cv_de(function(tr, va) predict(lm(y ~ x1 + x2 + x3, data = tr), va))        # MQO
cv_de(function(tr, va) predict(glm(y ~ x1 + x2 + x3, binomial, data = tr), va, type = "response"))  # logística
sapply(2:8, function(k) cv_de(function(tr, va)                              # spline em x2
  predict(glm(y ~ x1 + ns(x2, df = k) + x3, binomial, data = tr), va, type = "response")))
cv_de(function(tr, va) predict(gam(y ~ s(x1) + s(x2) + s(x3), binomial, data = tr), va, type = "response"))  # GAM
g <- gam(y ~ s(x1) + s(x2) + s(x3), binomial, data = d)
round(summary(g)$s.table[, "edf"], 2)                                       # perto de 1 = reta
par(mfrow = c(1, 3), pty = "s"); plot(g, scheme = 1)                        # as curvas