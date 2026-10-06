# Consolidação da Análise: k-fold, Treino/Teste e Bootstrap — NU_NOTA_MT x MEDIA_MT (ENEM)

## 1. Objetivo

Aplicar **validação (k-fold e treino/teste 70/30)** e **bootstrap** sobre as notas do ENEM para avaliar:

- se incluir a renda (`RENDA`) melhora o erro de previsão;
- quão estável é o coeficiente da nota de matemática.

| Variável | Significado |
|---|---|
| `NU_NOTA_MT` | Nota de matemática (separada) |
| `MEDIA_MT` | Média das notas do ENEM **sem considerar matemática** |
| `RENDA` | Variável socioeconômica de renda |

---

## 2. Preparação dos dados e divisão 70/30

```r
set.seed(123)
dados <- na.omit(dataset[, c("NU_NOTA_MT", "MEDIA_MT", "RENDA")])
n <- nrow(dados)

i_treino <- sample(n, 0.7 * n)
treino <- dados[i_treino, ]
teste  <- dados[-i_treino, ]
```

- **`na.omit`**: mantém só linhas completas nas variáveis usadas.
- **`sample(n, 0.7 * n)`**: sorteia 70% das linhas para treino; os 30% restantes formam o teste.
- **Regra do esquema**: tudo que ajusta ou compara modelos (k-fold, bootstrap) usa o **treino**; o **teste** fica intocado e é usado **uma vez**, no final. Isso evita avaliar o modelo nos mesmos dados em que ele foi ajustado.

---

## 3. Teste inicial e dúvidas

Antes de adotar o esquema 70/30, foi feito um primeiro teste com **k-fold (5 folds) e bootstrap nos dados inteiros**, prevendo a nota de matemática pela média das outras áreas (`NU_NOTA_MT ~ MEDIA_MT` e `NU_NOTA_MT ~ MEDIA_MT + RENDA`):

| Modelo | MSE | RMSE | DP_MSE |
|---|:---:|:---:|:---:|
| M1: MEDIA_MT | 7621,54 | 87,30 | 152,74 |
| M2: MEDIA_MT + RENDA | 7577,63 | 87,05 | 145,91 |

Bootstrap do coeficiente de `MEDIA_MT`: **0,969**, IC 95% **[0,958; 0,980]**.

**Dúvidas que surgiram:**

- **"A RENDA parece aleatória."** O M2 ganhou por apenas 0,25 ponto de RMSE (~0,6% do MSE), um ganho prático mínimo. Não é aleatório, é **redundante**: com `MEDIA_MT` no modelo, a RENDA acrescenta quase nada.
- **"Onde k-fold e bootstrap são úteis no ENEM?"** A validação compara modelos pelo erro em dados novos; o bootstrap mede a incerteza de qualquer estatística (coeficientes, medianas, diferença entre grupos), sem depender de normalidade.

Para focar na matemática como variável de interesse, a análise final passou a usar `MEDIA_MT` como resposta e `NU_NOTA_MT` como preditor, já no esquema 70/30.

---

## 4. K-fold no treino (70%)

```r
k <- 5
d <- sample(rep(1:k, length.out = nrow(treino)))

cv <- function(formula) {
  mse <- sapply(1:k, function(j) {
    m <- lm(formula, data = treino[d != j, ])
    mean((treino$MEDIA_MT[d == j] - predict(m, treino[d == j, ]))^2)
  })
  c(MSE = mean(mse), RMSE = sqrt(mean(mse)), DP_MSE = sd(mse))
}
```

- **`rep(1:k, ...)` + `sample`**: distribui as linhas do treino aleatoriamente em 5 folds.
- **`cv()`**: em cada fold, ajusta o modelo nos outros 4 e mede o erro no fold deixado de fora; devolve a média e o desvio padrão do MSE.

```
== K-fold (5 folds) no treino 70% ==
                           MSE  RMSE DP_MSE
M1: NU_NOTA_MT         3908.79 62.52  95.70
M2: NU_NOTA_MT + RENDA 3899.38 62.44  95.21
```

- O M2 melhora o RMSE em apenas **0,08 ponto** (~0,25% do MSE).
- O ganho é **mínimo em termos práticos**: ~9 de MSE contra um MSE de ~3900. Como os dois modelos usam os mesmos folds, testar se o ganho é consistente exigiria comparar a diferença de MSE fold a fold (pareada); o DP_MSE sozinho não serve para isso.

---

## 5. Avaliação final no teste (30%)

```r
avalia <- function(formula) {
  m <- lm(formula, data = treino)
  mse <- mean((teste$MEDIA_MT - predict(m, teste))^2)
  c(MSE = mse, RMSE = sqrt(mse))
}
```

```
== Teste 30% ==
                           MSE  RMSE
M1: NU_NOTA_MT         3872.31 62.23
M2: NU_NOTA_MT + RENDA 3860.87 62.14
```

- O RMSE no teste (62,23) é parecido com o do k-fold no treino (62,52): o desempenho **se mantém em dados novos**, sem sinal de "viciar".
- A diferença entre M1 e M2 (0,09 ponto) é do mesmo tamanho da do k-fold. Os modelos são **equivalentes na prática**.

### Referência: desvio padrão

O desvio padrão de `MEDIA_MT` é **87,02** (erro de "chutar" sempre a média). Com a matemática, o RMSE cai para **62,23**, redução de ~28% no erro, o que corresponde a **R² ≈ 0,49**: o modelo reduz bastante o erro, mas deixa cerca de metade da variabilidade sem explicar.

---

## 6. Bootstrap do coeficiente de NU_NOTA_MT

```r
B <- 2000

boot <- function(base) {
  nb <- nrow(base)
  b <- replicate(B, {
    i <- sample(nb, nb, replace = TRUE)
    c(sem = coef(lm(MEDIA_MT ~ NU_NOTA_MT,         data = base[i, ]))[[2]],
      com = coef(lm(MEDIA_MT ~ NU_NOTA_MT + RENDA, data = base[i, ]))[[2]])
  })
  ...
}
```

- **`sample(..., replace = TRUE)`**: gera 2000 amostras com reposição do mesmo tamanho da base.
- Em cada amostra, os modelos **sem** e **com** RENDA usam os mesmos dados, o que torna a comparação justa.
- O **IC de 95%** vem dos percentis 2,5% e 97,5% dos coeficientes reamostrados.
- Rodado em duas bases: **treino 70%** (principal, mantém o teste intocado) e **dados completos** (checagem de sensibilidade).

**Bootstrap no treino (70%)**
```
    Estimativa Erro_padrao IC95_inf IC95_sup
sem     0.5018      0.0033   0.4951   0.5083
com     0.4978      0.0033   0.4908   0.5042
```

**Bootstrap nos dados completos**
```
    Estimativa Erro_padrao IC95_inf IC95_sup
sem     0.5013      0.0027   0.4962   0.5065
com     0.4971      0.0027   0.4919   0.5025
```

- O coeficiente é de ~**0,50** nas duas bases, com IC estreito e longe de 0: associação clara e estável.
- Incluir `RENDA` reduz o coeficiente em ~0,004 (menos de 1%), e os ICs praticamente se sobrepõem.
- O resultado quase não depende da base usada; com os dados completos o erro padrão é um pouco menor (0,0027 contra 0,0033), como esperado por ter mais dados.
- O valor difere do 0,969 do teste inicial porque as variáveis trocaram de papel (0,97 × 0,50 ≈ 0,49, o mesmo R² da seção 5).

---

## 7. Conclusão geral

- No esquema 70/30, o k-fold (no treino) e o teste (30%) apontam o mesmo: incluir `RENDA` melhora o RMSE em menos de 0,1 ponto, diferença **mínima, sem relevância prática**.
- O coeficiente da nota de matemática é **estável** (~0,50), tanto no treino quanto nos dados completos, e quase não muda ao incluir a renda (queda < 1%).
- A associação é, portanto, **robusta à renda**. Isso não prova que o modelo é bom (R² ≈ 0,49) nem exclui o efeito de variáveis não observadas; também pode indicar que a `RENDA` separa pouco os alunos.
- Como próximo passo, vale testar controles com mais poder de separação, como tipo de escola ou escolaridade da mãe.
