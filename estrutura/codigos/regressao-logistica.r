# Importa a base de dados do ENEM usando ponto e vírgula como separador  
dataset <- read.csv("dados-enem-2021-2025.csv", header = TRUE, sep = ";")  
  
# Seleciona as cinco notas do ENEM que serão utilizadas nos cálculos  
colunas_int <- c("NU_NOTA_CN", "NU_NOTA_CH", "NU_NOTA_LC", "NU_NOTA_MT", "NU_NOTA_REDACAO")  
  
# Troca vírgula por ponto e converte as notas para valores numéricos  
dataset[colunas_int] <- lapply(  
  dataset[colunas_int],  
  function(x) as.numeric(gsub(",", ".", x))  
)  
  
# Seleciona as colunas que devem ser tratadas como texto  
colunas_char <- c("NU_ANO", "TP_COR_RACA", "CO_MUNICIPIO_PROVA")  
  
# Converte as colunas selecionadas para o tipo character  
dataset[colunas_char] <- lapply(  
  dataset[colunas_char],  
  as.character  
)  
  
# Calcula a média das cinco notas do ENEM para cada participante  
dataset$MEDIA <- rowMeans(  
  dataset[, c(  
    "NU_NOTA_CN",  
    "NU_NOTA_CH",  
    "NU_NOTA_LC",  
    "NU_NOTA_MT",  
    "NU_NOTA_REDACAO"  
  )]  
)  
  
# Mantém somente as categorias de cor/raça de 1 a 5  
dataset <- subset(dataset, TP_COR_RACA %in% 1:5)  
  
# Transforma a variável em binária:  
# categoria 1 = FALSE; categorias 2 a 5 = TRUE  
dataset$RACA <- ifelse(dataset$TP_COR_RACA == 1, FALSE, TRUE)  

# Remove as linhas que possuem pelo menos um valor ausente
dataset <- na.omit(dataset)
  
# Configura o gráfico  
par(mar = c(4, 4, 1, 1), pty = "s")  
  
# Ajuste do modelo logístico e odds ratio  
m <- glm(RACA ~ MEDIA, data = dataset, family = binomial)  
summary(m); exp(coef(m))  
  
# Mostra os valores observados de RACA em função da MEDIA  
plot(dataset$MEDIA, as.numeric(dataset$RACA),  
     pch = 19, col = "blue",  
     xlab = "MEDIA",  
     ylab = "P(RACA = TRUE)",  
     main = "Relação entre raça e média")  
  
# Adiciona uma reta linear apenas como referência visual  
abline(lm(as.numeric(RACA) ~ MEDIA, data = dataset),  
       col = "green", lwd = 2, lty = 2)  
  
# Cria valores de MEDIA para desenhar a curva logística  
s <- seq(min(dataset$MEDIA, na.rm = TRUE),  
         max(dataset$MEDIA, na.rm = TRUE),  
         length = 200)  
  
# Calcula e desenha as probabilidades previstas pelo modelo logístico  
lines(s,  
      predict(m, newdata = data.frame(MEDIA = s), type = "response"),  
      col = "orange", lwd = 3)  
  
abline(h = c(0,1), col ="gray", lty = 3)  
  
# Previsão probabilidade de ser de uma raça vulnerável socialmente  
# De acordo com a média, criando matriz de confusão  
p <- predict(m, type = "response")  
  
# Cria os limiares de classificação  
limiares <- c(0.3, 0.5, 0.7)  
  
for (limiar in limiares){  
    yhat <- as.integer(p > limiar) # Limiar que o modelo usará para classificar 
    
    # Matriz de confusão para cada limiar  
    print(paste("Limiar:", limiar))  
    print(table(real = dataset$RACA[!is.na(dataset$MEDIA)], previsto = yhat))  
}  
  
# Teste AUC da classificação de modelo  
mean(outer(  
  p[dataset$RACA[!is.na(dataset$MEDIA)] == TRUE],  
  p[dataset$RACA[!is.na(dataset$MEDIA)] == FALSE],  
  ">"  
))

# 1) Divide os dados em 70% para treinamento e 30% para teste 
set.seed(1)  
itr <- sample(nrow(dataset), round(0.7 * nrow(dataset)))  
tr <- dataset[itr,]; te <- dataset[-itr,]  

# 2) Ajusta dois modelos usando apenas os dados de treinamento 
m1 <- glm(RACA ~ MEDIA, data = tr, family = binomial)  
m2 <- glm(RACA ~ MEDIA + Q020, data = tr, family = binomial)  

# 3) Compara os modelos nos dados de teste usando o RMSE 
mse <- function(m, d) mean((as.numeric(d$RACA) - predict(m, d, type = "response"))^2)  
sqrt(c(m1 = mse(m1, te), m2 = mse(m2, te)))
