library(glmnet)

dataset <- na.omit(dataset)
X  <- model.matrix(NU_NOTA_MT ~ . - MEDIA - NU_INSCRICAO - CO_MUNICIPIO_PROVA, data = dataset)[, -1]
yv <- dataset$NU_NOTA_MT

set.seed(1)
idx <- sample(nrow(dataset), 0.7 * nrow(dataset))   # 70% treino / 30% teste

set.seed(1)
cvl <- cv.glmnet(X[idx, ], yv[idx], alpha = 1)
set.seed(1)
cvr <- cv.glmnet(X[idx, ], yv[idx], alpha = 0)
plot(cvl)

cvl$lambda.min
cvl$lambda.1se
cl <- coef(cvl, s = "lambda.1se")
cl[as.vector(cl) != 0, ]
c(lasso = min(cvl$cvm), ridge = min(cvr$cvm))

pl <- predict(cvl, X[-idx, ], s = "lambda.1se")
pr <- predict(cvr, X[-idx, ], s = "lambda.1se")
c(lasso = sqrt(mean((yv[-idx] - pl)^2)), ridge = sqrt(mean((yv[-idx] - pr)^2)))
sd(yv[-idx])
