# Importa a base de dados do ENEM usando ponto e vírgula como separador
dataset <- read.csv("dados-enem-2021-2025.csv", header = TRUE, sep = ";")

# Verifica o número de linhas e colunas antes do tratamento
dim(dataset)

# Seleciona as colunas que devem ser tratadas como texto
colunas_char <- c("NU_ANO", "TP_COR_RACA", "CO_MUNICIPIO_PROVA", "Q020", "Q021")

# Converte as colunas selecionadas para o tipo character
dataset[colunas_char] <- lapply(
  dataset[colunas_char],
  as.character
)

# Seleciona as cinco notas do ENEM que serão utilizadas nos cálculos
colunas_int <- c(
  "NU_NOTA_CN",
  "NU_NOTA_CH",
  "NU_NOTA_LC",
  "NU_NOTA_MT",
  "NU_NOTA_REDACAO"
)

# Troca vírgula por ponto e converte as notas para valores numéricos
dataset[colunas_int] <- lapply(
  dataset[colunas_int],
  function(x) as.numeric(gsub(",", ".", x))
)

# Remove as linhas que possuem pelo menos um valor ausente
dataset <- na.omit(dataset)

# Remove espaços extras das respostas de Q020
dataset$Q020 <- trimws(dataset$Q020)

# Garante que as letras estejam em maiúsculo
dataset$Q020 <- toupper(dataset$Q020)

# Transforma Q020 em uma variável lógica:
# B = TRUE e A = FALSE
dataset$Q020 <- ifelse(dataset$Q020 == "B", 1, 0)

# Converte a resposta da Q021 em uma variável binária:
# A = 0 (Não possui notebook) e as demais respostas = 1 (Possui notebook)
dataset$NOTE <- ifelse(dataset$Q021 == "A", 0, 1)

# Mantém somente as categorias de cor/raça de 1 a 5
dataset <- subset(dataset, TP_COR_RACA %in% 1:5)

# Transforma a variável em binária:
# categoria 1 = FALSE; categorias 2 a 5 = TRUE
dataset$RACA <- ifelse(dataset$TP_COR_RACA == 1, FALSE, TRUE)

# Verifica o tamanho do dataset após o tratamento
dim(dataset)

# Verifica se Q020 ficou corretamente codificada
table(dataset$Q020)

# Verifica se RACA ficou corretamente codificada
table(dataset$RACA)
