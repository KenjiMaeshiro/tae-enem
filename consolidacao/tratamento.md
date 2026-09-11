# Tratamento e preparação dos dados do ENEM

Este código realiza a **importação, limpeza, transformação e preparação** de uma base de dados do ENEM para que as informações possam ser utilizadas posteriormente em análises estatísticas e modelos.

## 1. Importação da base de dados

```r
dataset <- read.csv("dados-enem-2021-2025.csv", header = TRUE, sep = ";")
```

A função `read.csv()` importa o arquivo CSV para o R e armazena os dados no objeto `dataset`.

- `header = TRUE`: indica que a primeira linha do arquivo contém os nomes das colunas.
- `sep = ";"`: informa que os campos estão separados por ponto e vírgula.

---

## 2. Verificação inicial da dimensão da base

```r
dim(dataset)
```

A função `dim()` mostra a quantidade de **linhas e colunas** da base antes do tratamento.

Isso permite verificar o tamanho inicial do conjunto de dados e posteriormente comparar com o tamanho após a limpeza.

---

## 3. Seleção das colunas que serão tratadas como texto

```r
colunas_char <- c(
  "NU_ANO",
  "TP_COR_RACA",
  "CO_MUNICIPIO_PROVA",
  "Q020",
  "Q021"
)
```

Aqui é criado um vetor contendo os nomes das variáveis que serão convertidas para o tipo `character`.

Essas variáveis contêm informações categóricas ou códigos que serão manipulados posteriormente.

---

## 4. Conversão das colunas para `character`

```r
dataset[colunas_char] <- lapply(
  dataset[colunas_char],
  as.character
)
```

A função `lapply()` aplica `as.character()` a cada uma das colunas selecionadas.

O objetivo é garantir que essas variáveis sejam tratadas como **texto**, evitando problemas durante as transformações das respostas.

---

## 5. Seleção das cinco notas do ENEM

```r
colunas_int <- c(
  "NU_NOTA_CN",
  "NU_NOTA_CH",
  "NU_NOTA_LC",
  "NU_NOTA_MT",
  "NU_NOTA_REDACAO"
)
```

São selecionadas as cinco notas utilizadas na análise:

- `NU_NOTA_CN`: Ciências da Natureza;
- `NU_NOTA_CH`: Ciências Humanas;
- `NU_NOTA_LC`: Linguagens e Códigos;
- `NU_NOTA_MT`: Matemática;
- `NU_NOTA_REDACAO`: Redação.

Essas variáveis serão convertidas para valores numéricos.

---

## 6. Conversão das notas para valores numéricos

```r
dataset[colunas_int] <- lapply(
  dataset[colunas_int],
  function(x) as.numeric(gsub(",", ".", x))
)
```

As notas são convertidas para o tipo numérico.

Primeiro, `gsub(",", ".", x)` substitui a **vírgula decimal por ponto decimal**. Isso é necessário porque valores como `650,5` precisam ser transformados em `650.5` para serem interpretados corretamente pelo R.

Depois, `as.numeric()` converte os valores para números.

---

## 7. Limpeza das respostas de Q020

```r
dataset$Q020 <- trimws(dataset$Q020)
```

A função `trimws()` remove espaços em branco desnecessários no início e no final das respostas.

Por exemplo:

```text
" B " → "B"
```

Isso evita que espaços extras causem problemas na classificação das respostas.

---

## 8. Padronização das letras

```r
dataset$Q020 <- toupper(dataset$Q020)
```

A função `toupper()` transforma as letras em maiúsculas.

Assim, respostas como `b`, `B` ou ` b ` podem ser padronizadas antes da transformação da variável.

---

## 9. Transformação da Q020 em variável binária

```r
dataset$Q020 <- ifelse(dataset$Q020 == "B", 1, 0)
```

A variável `Q020` é transformada em uma variável binária.

A interpretação passa a ser:

| Valor | Interpretação |
|---|---|
| `1` | Sim |
| `0` | Não |

Nesse caso, a resposta `B` recebe o valor `1`, enquanto as demais respostas recebem `0`.

Essa transformação facilita a utilização da variável em análises estatísticas e modelos.

---

## 10. Transformação da Q021 em variável binária

```r
dataset$NOTE <- ifelse(dataset$Q021 == "A", 0, 1)
```

A resposta da questão `Q021` é transformada em uma nova variável chamada `NOTE`.

A classificação utilizada é:

| Q021 | NOTE | Interpretação |
|---|---:|---|
| `A` | `0` | Não possui notebook |
| Demais respostas | `1` | Possui notebook |

Dessa forma, a variável `NOTE` representa uma resposta binária sobre a posse de notebook.

---

## 11. Filtragem das categorias de cor/raça

```r
dataset <- subset(dataset, TP_COR_RACA %in% 1:5)
```

São mantidos somente os registros cuja variável `TP_COR_RACA` possui valores de `1` a `5`.

O operador `%in%` verifica se cada valor pertence ao conjunto especificado.

Essa etapa remove categorias que não serão utilizadas na análise.

---

## 12. Criação da variável binária de raça

```r
dataset$RACA <- ifelse(
  dataset$TP_COR_RACA == 1,
  FALSE,
  TRUE
)
```

É criada uma nova variável chamada `RACA`.

A variável original `TP_COR_RACA` é agrupada em duas categorias:

| TP_COR_RACA | RACA |
|---|---|
| `1` | `FALSE` |
| `2` a `5` | `TRUE` |

Ou seja, a categoria `1` é mantida separada, enquanto as categorias `2`, `3`, `4` e `5` são agrupadas.

Essa transformação reduz uma variável com várias categorias para uma variável binária, facilitando análises estatísticas.

---

## 13. Verificação da dimensão após o tratamento

```r
dim(dataset)
```

A dimensão do `dataset` é novamente verificada.

Nesse momento, é possível comparar o número de linhas e colunas antes e depois das transformações e filtragens.

---

## 14. Verificação da variável Q020

```r
table(dataset$Q020)
```

A função `table()` contabiliza quantas observações existem em cada categoria da variável `Q020`.

Isso permite verificar se a transformação para `0` e `1` ocorreu corretamente.

---

## 15. Verificação da variável RACA

```r
table(dataset$RACA)
```

Da mesma forma, essa função verifica a quantidade de observações classificadas como `FALSE` e `TRUE` na variável `RACA`.

Essa etapa serve como uma conferência da transformação realizada anteriormente.

---

## 16. Remoção de valores ausentes

```r
dataset <- na.omit(dataset)
```

Por fim, `na.omit()` remove todas as linhas que possuem **pelo menos um valor ausente (`NA`)**.

Isso deixa a base completa para as análises que serão realizadas posteriormente.

A desvantagem é que uma linha é removida mesmo que apenas uma de suas variáveis possua valor ausente. Portanto, essa decisão deve ser considerada na interpretação dos resultados.

---

# Resumo do tratamento

O código realiza as seguintes etapas:

1. **Importa** a base do ENEM;
2. **Verifica** o tamanho inicial da base;
3. **Converte** variáveis categóricas para texto;
4. **Seleciona** as cinco notas do ENEM;
5. **Converte** as notas para valores numéricos;
6. **Limpa e padroniza** as respostas da Q020;
7. **Transforma Q020** em uma variável binária;
8. **Transforma Q021** em uma variável binária chamada `NOTE`;
9. **Filtra** as categorias de cor/raça utilizadas;
10. **Cria RACA** como variável binária;
11. **Verifica** o tamanho da base após o tratamento;
12. **Confere** as distribuições de `Q020` e `RACA`;
13. **Remove** registros com valores ausentes.

Ao final, o objeto `dataset` contém uma versão **tratada e preparada da base do ENEM**, adequada para as etapas seguintes de análise exploratória, estatística e modelagem.
