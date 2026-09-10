# Importa a base de dados do ENEM usando ponto e vírgula como separador
dataset <- read.csv("Dados_Enem_2021-2025.csv", header = TRUE, sep = ";")

# Instala os pacotes usados nas análises e gráficos
install.packages("dplyr")
install.packages("ggplot2")

# Carrega os pacotes para que suas funções possam ser utilizadas
library(dplyr)
library(ggplot2)

# Verifica o número de linhas e colunas antes do tratamento
dim(dataset)

# Seleciona as colunas que devem ser tratadas como texto
colunas_char <- c("NU_ANO", "TP_COR_RACA", "CO_MUNICIPIO_PROVA")

# Converte as colunas selecionadas para o tipo character
dataset[colunas_char] <- lapply(
  dataset[colunas_char],
  as.character
)

# Seleciona as cinco notas do ENEM que serão utilizadas nos cálculos
colunas_int <- c("NU_NOTA_CN", "NU_NOTA_CH", "NU_NOTA_LC", "NU_NOTA_MT", "NU_NOTA_REDACAO")

# Troca vírgula por ponto e converte as notas para valores numéricos
dataset[colunas_int] <- lapply(
  dataset[colunas_int],
  function(x) as.numeric(gsub(",", ".", x))
)

# Remove as linhas que possuem pelo menos um valor ausente
dataset <- na.omit(dataset)

# Representa numericamente cada faixa de renda do questionário Q007.
# Os valores são definidos separadamente para cada ano do ENEM.
medias_renda_21 <- c(
  A = 0, B = 550, C = 1375, D = 1925, E = 2475, F = 3025, G = 3850, H = 4950,
  I = 6050, J = 7150, K = 8250, L = 9350, M = 10450, N = 12100, O = 14850,
  P = 19250, Q = 22000
)

medias_renda_22 <- c(
  A = 0, B = 606, C = 1515, D = 2121, E = 2727, F = 3333, G = 4242, H = 5454,
  I = 6666, J = 7878, K = 9090, L = 10302, M = 11514, N = 13332, O = 16362,
  P = 21210, Q = 24240
)

medias_renda_23 <- c(
  A = 0, B = 660, C = 1650, D = 2310, E = 2970, F = 3630, G = 4620, H = 5940,
  I = 7260, J = 8580, K = 9900, L = 11220, M = 12540, N = 14520, O = 17820,
  P = 23100, Q = 26400
)

medias_renda_24 <- c(
  A = 0, B = 706, C = 1765, D = 2472, E = 3177, F = 3883, G = 4942, H = 6354,
  I = 7766, J = 9178, K = 10590, L = 12002, M = 13414, N = 15532, O = 19062,
  P = 24710, Q = 28240
)

medias_renda_25 <- c(
  A = 0, B = 759, C = 1898, D = 2657, E = 3416, F = 4175, G = 5313, H = 6831,
  I = 8349, J = 9867, K = 11385, L = 12903, M = 14421, N = 16698, O = 20493,
  P = 26565, Q = 30360
)

# Cria a coluna que armazenará a renda numérica de cada participante
dataset$RENDA <- NA_real_

# Substitui as categorias Q007 pelos valores correspondentes de 2021
dataset$RENDA[dataset$NU_ANO == 2021] <- as.numeric(
  medias_renda_21[as.character(dataset$Q007[dataset$NU_ANO == 2021])]
)

# Substitui as categorias Q007 pelos valores correspondentes de 2022
dataset$RENDA[dataset$NU_ANO == 2022] <- as.numeric(
  medias_renda_22[as.character(dataset$Q007[dataset$NU_ANO == 2022])]
)

# Substitui as categorias Q007 pelos valores correspondentes de 2023
dataset$RENDA[dataset$NU_ANO == 2023] <- as.numeric(
  medias_renda_23[as.character(dataset$Q007[dataset$NU_ANO == 2023])]
)

# Substitui as categorias Q007 pelos valores correspondentes de 2024
dataset$RENDA[dataset$NU_ANO == 2024] <- as.numeric(
  medias_renda_24[as.character(dataset$Q007[dataset$NU_ANO == 2024])]
)

# Substitui as categorias Q007 pelos valores correspondentes de 2025
dataset$RENDA[dataset$NU_ANO == 2025] <- as.numeric(
  medias_renda_25[as.character(dataset$Q007[dataset$NU_ANO == 2025])]
)
