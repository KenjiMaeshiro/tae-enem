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
 
# Calcula a mediana das cinco notas de cada participante 
dataset$MEDIANA <- apply( 
  dataset[, c( 
    "NU_NOTA_CN", 
    "NU_NOTA_CH", 
    "NU_NOTA_LC", 
    "NU_NOTA_MT", 
    "NU_NOTA_REDACAO" 
  )], 
  1, 
  median 
) 
 
# Calcula uma média sem a nota de Matemática. 
# Ela será usada para analisar a relação com a nota de matemática. 
dataset$MEDIA_MT <- rowMeans( 
  dataset[, c( 
    "NU_NOTA_CN", 
    "NU_NOTA_CH", 
    "NU_NOTA_LC", 
    "NU_NOTA_REDACAO" 
  )] 
) 
 
# Mantém somente as categorias de cor/raça de 1 a 5   
dataset <- subset(dataset, TP_COR_RACA %in% 1:5)   
   
# Transforma a variável em binária:   
# categoria 1 = FALSE; categorias 2 a 5 = TRUE   
dataset$RACA <- ifelse(dataset$TP_COR_RACA == 1, FALSE, TRUE)   
 
# Calcula o desvio padrão das médias dos participantes 
desvio <- sd(dataset$MEDIA) 
 
# Exibe o desvio padrão calculado 
print(desvio) 
 
# Mostra as seis primeiras linhas para conferir o resultado do tratamento 
head(dataset) 
 
# Calcula o primeiro e o terceiro quartis das médias 
Q1 <- quantile(dataset$MEDIA, 0.25) 
Q3 <- quantile(dataset$MEDIA, 0.75) 
 
# Calcula o intervalo interquartil (IQR) 
IQR <- Q3 - Q1 
 
# Define os limites usados para identificar possíveis outliers 
limite_inferior <- Q1 - 1.5 * IQR 
limite_superior <- Q3 + 1.5 * IQR 
 
# Seleciona as médias que estão fora dos limites definidos 
outliers <- dataset$MEDIA[ 
  dataset$MEDIA < limite_inferior | 
  dataset$MEDIA > limite_superior 
] 
 
# Organiza os principais resultados em uma tabela 
resultado <- data.frame( 
  Medida = c( 
    "Q1", 
    "Mediana", 
    "Q3", 
    "IQR", 
    "Limite inferior", 
    "Limite superior", 
    "Quantidade de outliers", 
    "Percentual de outliers" 
  ), 
  Valor = c( 
    Q1, 
    median(dataset$MEDIA, na.rm = TRUE), 
    Q3, 
    IQR, 
    limite_inferior, 
    limite_superior, 
    length(outliers), 
    round(length(outliers) / sum(!is.na(dataset$MEDIA)) * 100, 2) 
  ) 
) 
 
# Exibe a tabela com os resultados 
resultado 
 
# Cria um boxplot para comparar a distribuição das médias
# entre os participantes com e sem acesso ao Wifi
boxplot( 
  MEDIA ~ Q020, 
  data = dataset, 
  main = "Distribuição da Média por Acesso à Wifi", 
  xlab = "Acesso ao wifi", 
  ylab = "Média das Notas" 
) 
 
# Cria um boxplot para comparar a distribuição das médias
# entre os participantes com e sem acesso a computador/notebook
boxplot( 
  MEDIA ~ NOTE, 
  data = dataset, 
  main = "Distribuição da Média por Acesso a computador/notebook", 
  xlab = "Acesso ao notebook", 
  ylab = "Média das Notas" 
) 
 
# Cria um boxplot para comparar a distribuição das médias
# entre as diferentes categorias de raça/cor
boxplot( 
  MEDIA ~ TP_COR_RACA, 
  data = dataset, 
  main = "Distribuição da Média por Raça/cor", 
  xlab = "Raça/cor", 
  ylab = "Média das Notas" 
)
