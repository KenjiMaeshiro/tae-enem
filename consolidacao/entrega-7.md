# Consolidação da Análise: Regressão Não Paramétrica — `MEDIA` e `RACA`

## 1. Objetivo

Verificar se a variável `MEDIA` ajuda a prever `RACA` (binária) e que forma tem essa relação, comparando métodos de complexidade crescente (reta, logística, KNN e kernel) com **validação cruzada de 5 dobras**.

Itens a responder:

- quanto cada método reduz o erro em relação a "chutar a média";
- qual método e qual parâmetro de suavização funcionam melhor;
- o formato da curva estimada;
- uma frase com o que a análise disse sobre o problema.

| Variável | Papel | Significado |
|---|---|---|
| `RACA` | Variável prevista (y) | Binária: `TRUE` = 1, `FALSE` = 0 |
| `MEDIA` | Preditor (x) | Média das notas |

Como y é 0/1, a regressão estima a **probabilidade de `RACA = TRUE` dado `MEDIA`**.

---

## 2. Preparação dos dados

```r
library(FNN)
dados <- read.csv("banco-limpo.csv")
x <- dados$MEDIA; y <- as.numeric(as.logical(dados$RACA))
ok <- !is.na(x) & !is.na(y); x <- x[ok]; y <- y[ok]
```

- **`as.numeric(as.logical(...))`**: transforma `TRUE`/`FALSE` em 1/0, para que a média de y seja uma proporção.
- **`ok`**: remove as linhas com valores ausentes em x ou y, porque os métodos não aceitam NA.
- **Opcional**: há uma linha comentada com `sample(...)` para testar o código com 5.000 linhas. Ela deve ficar comentada na rodada final.

---

## 3. Métodos comparados

```r
knn_reg <- function(x0, x, y, k) knn.reg(matrix(x), matrix(x0), y, k = k)$pred
nw      <- function(x0, x, y, h) sapply(x0, function(a) { w <- dnorm((x - a) / h); sum(w * y) / sum(w) })
reta    <- function(x0, x, y) { b <- coef(lm(y ~ x)); b[1] + b[2] * x0 }
logit   <- function(x0, x, y) predict(glm(y ~ x, family = binomial),
                                      data.frame(x = x0), type = "response")
```

| Método | O que faz | Parâmetro de suavização |
|---|---|---|
| **Linha de base** | Prevê sempre a média geral de y | — |
| **Reta** | Regressão linear de y em x | — |
| **Logística** | Regressão logística, com curva em S entre 0 e 1 | — |
| **KNN** | Média de y dos k vizinhos mais próximos de x | k |
| **Kernel (Nadaraya-Watson)** | Média de y ponderada por uma gaussiana centrada em x | h (largura de banda) |

Os três últimos são cada vez mais flexíveis: quanto mais flexível, mais o método pode seguir o formato dos dados, mas também mais pode seguir o ruído.

---

## 4. Validação cruzada (CV de 5 dobras)

```r
set.seed(1); dobra <- sample(rep(1:5, length = length(y)))
cv_de <- function(prever) mean(sapply(1:5, function(j) {
  tr <- dobra != j; va <- dobra == j
  mean((y[va] - prever(x[va], x[tr], y[tr]))^2)
}))
```

- Os dados são divididos em 5 partes. Cada método é ajustado em 4 partes e avaliado na 5ª, e o processo se repete 5 vezes.
- A métrica é o **erro quadrático médio** (EQM) nas partes deixadas de fora. Quanto menor, melhor.
- **`set.seed(1)`**: garante que todos os métodos usam as mesmas dobras, o que torna a comparação justa.
- **Linha de base**: `mean((y - mean(y))^2)` é a variância de y, ou seja, o erro de prever sempre a média.

---

## 5. Resultados

```r
mean((y - mean(y))^2)   # linha de base
cv_de(reta)             # a reta
cv_de(logit)            # a logística

ks <- c(3, 5, 10, 20, 40)
sapply(ks, function(k) cv_de(function(x0, x, y) knn_reg(x0, x, y, k)))

hs <- sd(x) * c(0.05, 0.1, 0.2, 0.4)
cvh <- sapply(hs, function(h) cv_de(function(x0, x, y) nw(x0, x, y, h))); cvh
```

| Método | Parâmetro | EQM (CV-5) | Ganho vs. linha de base |
|---|---|:---:|:---:|
| Linha de base | — | 0,23512 | 0% |
| Reta | — | 0,23229 | ≈ 1,20% |
| Logística | — | 0,23235 | ≈ 1,17% |
| KNN | k = 3 | 0,30922 | negativo |
| KNN | k = 5 | 0,27749 | negativo |
| KNN | k = 10 | 0,25519 | negativo |
| KNN | k = 20 | 0,24324 | negativo |
| KNN | k = 40 | 0,23790 | negativo |
| Kernel | h = 0,05·sd | 0,23237 | ≈ 1,17% |
| Kernel | h = 0,1·sd | 0,23213 | ≈ 1,27% |
| Kernel | h = 0,2·sd | 0,23197 | ≈ 1,34% |
| **Kernel** | **h = 0,4·sd** | **0,23194** | **≈ 1,35%** |

O ganho é `(base − EQM) / base`.

---

## 6. A curva estimada

```r
g <- seq(min(x), max(x), length = 200)
plot(x, y, col = "gray60", pch = "."); lines(g, nw(g, x, y, hs[which.min(cvh)]), lwd = 2)
```

![Curva do estimador de kernel para P(RACA = TRUE | MEDIA)](../imagens/curva-kernel.png)

Como ler o gráfico: a curva preta é a probabilidade estimada de `RACA = TRUE` para cada valor de `MEDIA`. Os pontos cinza nas alturas 0 e 1 são as observações.

| Faixa de `MEDIA` | O que a curva faz |
|---|---|
| **x < ~150** | Cai de ≈ 1 para ≈ 0,4. Há poucas observações nessa faixa |
| **~210** | Pequeno vale (≈ 0,31), provavelmente ruído |
| **~300 a 500** | Patamar estável em ≈ 0,43 |
| **> 500** | Queda suave até ≈ 0,22 em x ≈ 840 |

O padrão geral é: **quanto maior a `MEDIA`, menor a probabilidade de `RACA = TRUE`**.

---

## 7. Interpretação

- **O sinal em `MEDIA` é fraco.** O melhor método reduz o erro em apenas ≈ 1,35%. Sozinha, `MEDIA` quase não melhora a previsão de `RACA`.
- **O KNN foi pior que "chutar a média".** Com y binário e sinal fraco, poucos vizinhos seguem o ruído. Mesmo com k = 40 o erro ainda fica acima da linha de base, e só um k bem maior se aproximaria dela.
- **Reta e logística empatam.** Já captam quase todo o sinal disponível, e a forma linear (ou em S) basta.
- **O kernel ganha por uma margem mínima.** A diferença para a reta é ≈ 0,0003, provavelmente dentro da variação entre divisões de dobras. **Não há evidência firme de que a relação seja não linear.**
- **O melhor h foi o maior testado** (0,4·sd). O erro ainda estava caindo, então o ótimo pode estar além da grade, com uma curva ainda mais suave.
- **A região x < 150** concentra poucos dados e valores de probabilidade próximos de 1. Pode ser um grupo pequeno ou um artefato (notas zeradas ou ausentes, por exemplo).

---

## 8. O que a análise disse sobre o problema

> Existe uma associação negativa e fraca entre `MEDIA` e a probabilidade de `RACA = TRUE`: o melhor método (kernel) reduz o erro em apenas ≈ 1,35% em relação a prever a média, e a reta e a logística chegam quase ao mesmo resultado, então não há ganho confiável em usar métodos mais flexíveis.

---

## 9. Conclusão geral

- Para **descrever** a relação, uma **regressão logística simples** é suficiente, com tendência de queda suave.
- Para **prever** `RACA`, `MEDIA` sozinha é um preditor muito fraco. Seria preciso incluir outras variáveis.
- **Cuidados na leitura**:
  - **Diferenças minúsculas**: o erro varia só na 4ª casa decimal entre reta, logística e kernel. Não dá para apontar um vencedor sem repetir a CV com outras sementes.
  - **Erro quadrático para y binário**: é um critério fraco. AUC e log-loss descrevem melhor a qualidade de uma probabilidade.
  - **Associação não é causa**: os resultados são descritivos e preditivos, sem interpretação causal.

### Próximos passos

1. Ampliar a grade de h (0,6, 0,8 e 1·sd) e ver se o ótimo está além de 0,4·sd.
2. Calcular **AUC** e **log-loss** além do erro quadrático.
3. Repetir a CV com várias sementes e comparar os métodos dobra a dobra.
4. Investigar as observações com `MEDIA` < 150.
5. Incluir outras variáveis, por exemplo com regressão logística múltipla ou regularização (Lasso e Ridge), como na entrega 6.
