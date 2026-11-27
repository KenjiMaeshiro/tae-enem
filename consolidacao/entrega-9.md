# Consolidação da Análise: PCA e k-means — notas e renda × cor/raça (ENEM 2021–2025)

## 1. Objetivo

Aplicar **PCA** e **k-means** às notas do ENEM e à renda para descobrir **quais eixos resumem os dados**, se existem **grupos naturais** de participantes e se esses grupos se diferenciam pela proporção de **não brancos** (`y`).

Itens a responder:

- quanto da variância cada componente principal explica e o que ele representa;
- quantos grupos a silhueta indica e quão bem separados eles são;
- como os grupos diferem nas variáveis originais e na proporção de não brancos;
- uma frase com o que a análise disse sobre o problema.

| Variável | Papel | Significado |
|---|---|---|
| `y` | Resposta (fica **fora** do PCA e do k-means) | 0 = branco, 1 = não branco (`TP_COR_RACA != 1`) |
| `CN`, `CH`, `LC`, `MT`, `RED` | Variáveis do PCA | Notas de Ciências da Natureza, Ciências Humanas, Linguagens, Matemática e Redação |
| `RENDA` | Variável do PCA | Renda da faixa da Q007, em salários mínimos |

O PCA e o k-means são métodos **não supervisionados**: eles agrupam os participantes sem usar `y`. A resposta só entra no fim, para ver como ela se distribui em cada grupo.

---

## 2. Preparação dos dados

```r
dd <- dataset[dataset$TP_COR_RACA %in% 1:5, ]

d <- na.omit(data.frame(
  y     = as.numeric(dd$TP_COR_RACA != 1),
  CN    = dd$NU_NOTA_CN,
  CH    = dd$NU_NOTA_CH,
  LC    = dd$NU_NOTA_LC,
  MT    = dd$NU_NOTA_MT,
  RED   = dd$NU_NOTA_REDACAO,
  RENDA = dd$RENDA
))

X <- d[, -1]   # só os preditores: a resposta fica de fora
```

- **`TP_COR_RACA %in% 1:5`**: remove o código 6 (não informado).
- **`na.omit`**: o PCA e o k-means não aceitam valores ausentes.
- **`X <- d[, -1]`**: tira `y` para que o agrupamento não use a resposta.
- **Resultado**: **35.471 linhas**, sendo **22.063 brancos** (y = 0) e **13.408 não brancos** (y = 1), ou seja, **37,8%** de não brancos.

---

## 3. PCA

```r
pca <- prcomp(X, scale. = TRUE)
summary(pca)
round(pca$rotation[, 1:2], 2)
round(cor(pca$x[, 1], d$y), 3)
```

- **`scale. = TRUE`**: padroniza as variáveis, para que notas (centenas de pontos) e renda (poucos salários mínimos) tenham o mesmo peso de partida.

### Variância explicada

| Componente | Desvio-padrão | Variância | Acumulada |
|---|:---:|:---:|:---:|
| **PC1** | 1,838 | 56,3% | 56,3% |
| **PC2** | 0,979 | 16,0% | 72,3% |
| PC3 | 0,784 | 10,2% | 82,5% |
| PC4 | 0,681 | 7,7% | 90,3% |
| PC5 | 0,567 | 5,4% | 95,6% |
| PC6 | 0,513 | 4,4% | 100% |

### Pesos de PC1 e PC2

| Variável | PC1 | PC2 |
|---|:---:|:---:|
| CN | 0,45 | −0,03 |
| CH | 0,47 | −0,12 |
| LC | 0,46 | −0,13 |
| MT | 0,46 | 0,00 |
| RED | 0,38 | −0,02 |
| **RENDA** | 0,14 | **0,98** |

- **PC1 (56,3%) é o eixo de desempenho geral**: as cinco notas pesam de 0,38 a 0,47 e a renda quase não entra (0,14). Um valor alto em PC1 significa notas altas em todas as provas.
- **PC2 (16,0%) é o eixo da renda**: peso de 0,98 na `RENDA` e ≈ 0 nas notas.
- **A renda é quase independente das notas**: em vez de se juntar ao eixo de desempenho, ela forma um componente próprio. Quando o PCA foi feito só com as cinco notas, o PC1 explicava 65,7%, e a queda para 56,3% se deve à renda ocupar o PC2.
- Dois componentes resumem **72%** da informação, e três chegam a **83%**.
- **`cor(PC1, y) = −0,127`**: quanto maior o desempenho, menor a chance de ser não branco, mas a relação é **fraca** (r² ≈ 1,6%).

---

## 4. Número de grupos pela silhueta

```r
set.seed(1); amostra <- sample(nrow(d), 2000)
Za <- scale(X[amostra, ]); Da <- dist(Za)

S <- sapply(2:8, function(k) {
  set.seed(1)
  g <- kmeans(Za, centers = k, nstart = 25, iter.max = 50)$cluster
  mean(silhouette(g, Da)[, "sil_width"])
})
K <- (2:8)[which.max(S)]
```

- A silhueta usa a matriz de distâncias n × n, então roda numa **amostra de 2.000 linhas**. Depois o k-means é refeito no banco inteiro.
- **`iter.max = 50`**: evita o aviso `did not converge in 10 iterations`.

| K | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Silhueta média | **0,323** | 0,216 | 0,233 | 0,194 | 0,195 | 0,199 | 0,169 |

- O melhor valor é **K = 2** (silhueta 0,323). Para K = 3 a 8 a silhueta fica entre ≈ 0,17 e 0,23.
- **Estrutura fraca**: abaixo de ≈ 0,5, os grupos tendem a ser fatias de um contínuo, e não aglomerados bem separados.

---

## 5. Os grupos

```r
Z <- scale(X)
set.seed(1); km <- kmeans(Z, centers = K, nstart = 25, iter.max = 50)
table(km$cluster)
aggregate(X, list(grupo = km$cluster), mean)
tapply(d$y, km$cluster, mean)
```

| | Grupo 1 | Grupo 2 |
|---|:---:|:---:|
| Tamanho | 16.212 (46%) | 19.259 (54%) |
| CN | 563,3 | 455,4 |
| CH | 599,1 | 478,3 |
| LC | 587,4 | 494,8 |
| MT | 643,3 | 468,7 |
| Redação | 738,6 | 532,2 |
| Renda (média, salários mínimos) | 5,41 | 3,43 |
| **Proporção de não brancos** | **≈ 32%** | **≈ 43%** |

- **Grupo 1 = alto desempenho**: notas de ≈ 100 a 175 pontos acima das do grupo 2, e renda média maior.
- **Grupo 2 = desempenho menor**.
- A proporção geral de não brancos é de **37,8%**. O grupo 1 fica abaixo dela e o grupo 2 acima, com uma diferença de ≈ **11 pontos percentuais** (o grupo de menor desempenho tem cerca de 1,3 vez a proporção de não brancos).

---

## 6. Os gráficos

![PC1 × PC2 colorido pelos grupos e proporção de não brancos por grupo](../imagens/pca-kmeans.png)

Como ler:

- **Esquerda (plano PC1 × PC2)**: cada ponto é um participante (amostra de 3.000), colorido pelo grupo. O grupo 1 (preto) fica à direita (PC1 positivo) e o grupo 2 (rosa) à esquerda.
- **Faixas horizontais**: aparecem porque PC2 é praticamente a renda, e a renda tem só 17 valores (as faixas da Q007). Cada faixa é um nível de renda.
- **Corte em PC1 = 0**: os dois grupos se separam em PC1 = 0, sem espaço vazio entre eles, ou seja, o k-means cortou o desempenho ao meio. A renda (PC2) não entrou na separação.
- **Direita (barras)**: proporção de não brancos em cada grupo (≈ 0,32 e ≈ 0,43). A linha tracejada é a proporção geral (0,378).

---

## 7. O que a análise disse sobre o problema

> O desempenho nas cinco provas forma um eixo único (PC1, 56% da variância) e a renda forma um eixo à parte (PC2, 16%); o k-means os divide em dois grupos de desempenho, de separação fraca (silhueta 0,32), em que a proporção de não brancos é de ≈ 32% no grupo de maior desempenho e ≈ 43% no de menor, uma associação real mas pequena.

---

## 8. Conclusão geral

- Os dados têm **dois eixos independentes**: **desempenho** (PC1) e **renda** (PC2).
- Os grupos do k-means são **faixas de desempenho**, e a separação é **fraca** (silhueta 0,32). Não há grupos naturais bem definidos.
- A cor/raça se associa ao desempenho de forma **fraca** (r = −0,13; 32% contra 43%). O PCA não revela uma estrutura própria de cor/raça nas notas e na renda.
- O resultado combina com a análise de `MEDIA` × `RACA` (associação negativa fraca, ganho de ≈ 1% no erro) e com a das variáveis `x1`, `x2`, `x3` (poder preditivo de ≈ 7 a 9%).
- **Cuidados na leitura**:
  - **Método descritivo**: o PCA e o k-means não usam `y`, então não mostram o que causa as diferenças.
  - **Grupos como fatias de um contínuo**: com silhueta de 0,32, os grupos dependem do corte escolhido e podem mudar com outra amostra ou outro K.
  - **Renda em faixas**: ela tem só 17 valores (pontos médios das faixas da Q007), o que gera as faixas horizontais no gráfico.
  - **Associação não é causa**: a diferença entre os grupos descreve o banco, sem interpretação causal.

### Próximos passos

1. Repetir a silhueta com **outras amostras** (sementes diferentes) e ver se K = 2 se mantém.
2. Comparar com o **PCA só das notas** (sem renda) e com **K = 3**, para ver se aparece um grupo intermediário.
3. Tratar `NU_ANO` como variável e checar se os grupos mudam entre as edições da prova.
4. Usar **PC1 e PC2 como preditores** de `y` (regressão logística) e comparar o erro com os modelos anteriores.
5. Testar se a diferença de proporções entre os grupos (32% e 43%) é significativa, com um intervalo de confiança por bootstrap.
