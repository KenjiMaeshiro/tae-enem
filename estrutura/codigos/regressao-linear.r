dataset <- read.csv("Dados_Enem_2021-2025.csv", header = TRUE, sep = ";")

# Seleciona as cinco notas do ENEM que serão utilizadas nos cálculos
colunas_int <- c("NU_NOTA_CN", "NU_NOTA_CH", "NU_NOTA_LC", "NU_NOTA_MT", "NU_NOTA_REDACAO")

# Troca vírgula por ponto e converte as notas para valores numéricos
dataset[colunas_int] <- lapply(
  dataset[colunas_int],
  function(x) as.numeric(gsub(",", ".", x))
)

# Remove as linhas que possuem pelo menos um valor ausente
dataset <- na.omit(dataset)

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

# Calcula uma média sem a nota de Matemática.
# Ela será usada para analisar a relação com a própria nota de Matemática.
dataset$MEDIA_MT <- rowMeans(
  dataset[, c(
    "NU_NOTA_CN",
    "NU_NOTA_CH",
    "NU_NOTA_LC",
    "NU_NOTA_REDACAO"
  )]
)

# Ajusta as margens e mantém o gráfico com proporção quadrada
par(mar=c(4,4,1,1), pty="s")
# Gráfico de dispersão entre a média sem Matemática e a nota de Matemática
plot(dataset$MEDIA_MT, dataset$NU_NOTA_MT,
     pch=19, col="blue",
     xlab="Média sem matemática",
     ylab="Nota de matemática")

# Adiciona ao gráfico a reta estimada pela regressão linear
abline(m, col="orange", lwd=3)

# Seleciona apenas os 15 primeiros participantes para facilitar a visualização
i <- 1:15
# Ajusta o modelo linear usando os 15 primeiros participantes
m0 <- lm(NU_NOTA_MT[i] ~ MEDIA_MT[i], data = dataset)
# Configura o espaço do gráfico
par(mar = c(4,4,1,1), pty = "s")
# X = média sem Matemática
# Y = nota observada de Matemática
plot(dataset$MEDIA_MT[i], dataset$NU_NOTA_MT[i],
     pch = 19, col = "blue",
     xlab = "Média sem matemática",
     ylab = "Nota de matemática")

# Adiciona a reta de regressão ao gráfico
abline(m0, col = "orange", lwd = 3)

# Mostra os resíduos, isto é, a diferença entre a nota observada e a nota prevista
segments(dataset$MEDIA_MT[i], dataset$NU_NOTA_MT[i],
         dataset$MEDIA_MT[i], fitted(m0),
         col = "green", lwd = 2)

# Ajusta o modelo linear para prever a nota de Matemática usando a média sem Matemática
m <- lm(NU_NOTA_MT ~ MEDIA_MT, data = dataset)
coef (m)

# Gráfico dos valores ajustados contra os resíduos do modelo
par(mar=c(4,4,1,1),pty="s")
plot(fitted(m), resid(m), pch=19, col="blue",
     xlab="ajustado", ylab="residuo")

# Linha de referência para verificar a distribuição dos resíduos em torno de zero
abline(h=0, col="orange", lwd=3, lty=2)''

# Teste de Breusch - Pagan
# Instala e carrega o pacote usado para testes de regressão
install.packages("lmtest")
library(lmtest)
# Aplica o teste de Breusch-Pagan para verificar heterocedasticidade
bptest(m)

# Avaliação e treinamento do modelo

# Garante que a divisão da amostra possa ser reproduzida
set.seed(1)

# Separa aproximadamente 70% dos dados para treino e 30% para teste
n <- nrow(dataset)
itr <- sample(seq_len(n), size = round(0.7 * n))

# Cria os conjuntos de treinamento e teste
tr <- dataset[itr, ]
te <- dataset[-itr, ]

# Modelo 1: prevê MEDIA_MT usando somente a nota de Matemática
m1 <- lm(MEDIA_MT ~ NU_NOTA_MT, data = tr)

# Modelo 2: acrescenta a renda como variável explicativa
m2 <- lm(MEDIA_MT ~ NU_NOTA_MT + MEDIA, data = tr)

# Função para calcular o erro quadrático médio (MSE)
mse <- function(m,d) mean((d$MEDIA-predict(m,d))^2)

# Calcula a raiz do MSE (RMSE) dos dois modelos no conjunto de teste
sqrt(c(m1 = mse(m1,te), m2 = mse(m2,te)))
