# Consolidação da Análise: k-fold, Treino/Teste e Bootstrap — NU_NOTA_MT x MEDIA_MT (ENEM)

## 1. Objetivo

Aplicar **validação (k-fold e treino/teste 70/30)** e **bootstrap** sobre as notas do ENEM para avaliar:

- se incluir a renda (`RENDA`) melhora o erro de previsão da nota de matemática;
- quão estável é o coeficiente da média das demais áreas (`MEDIA_MT`).

| Variável | Papel | Significado |
|---|---|---|
| `NU_NOTA_MT` | Variável prevista | Nota de matemática (separada) |
| `MEDIA_MT` | Preditor | Média das notas do ENEM **sem considerar matemática** |
| `RENDA` | Controle | Variável socioeconômica de renda |

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

## 3. Dúvidas iniciais

Nos primeiros resultados (k-fold e bootstrap nos dados inteiros, antes de adotar o esquema 70/30), surgiram duas dúvidas:

- **"A RENDA parece aleatória."** O modelo com RENDA ganhou por apenas 0,25 ponto de RMSE (87,30 → 87,05, ~0,6% do MSE), um ganho prático mínimo. Não é aleatório, é **redundante**: com `MEDIA_MT` no modelo, a RENDA acrescenta quase nada.
- **"Onde k-fold e bootstrap são úteis no ENEM?"** A validação compara modelos pelo erro em dados novos; o bootstrap mede a incerteza de qualquer estatística (coeficientes, medianas, diferença entre grupos), sem depender de normalidade.

Em seguida, tudo foi refeito dentro do esquema 70/30.

---

## 4. K-fold no treino (70%)

```r
k <- 5
d <- sample(rep(1:k, length.out = nrow(treino)))

cv <- function(formula) {
  mse <- sapply(1:k, function(j) {
    m <- lm(formula, data = treino[d != j, ])
    mean((treino$NU_NOTA_MT[d == j] - predict(m, treino[d == j, ]))^2)
  })
  c(MSE = mean(mse), RMSE = sqrt(mean(mse)), DP_MSE = sd(mse))
}
```

- **`rep(1:k, ...)` + `sample`**: distribui as linhas do treino aleatoriamente em 5 folds.
- **`cv()`**: em cada fold, ajusta o modelo nos outros 4 e mede o erro no fold deixado de fora; devolve a média e o desvio padrão do MSE.

```
== K-fold (5 folds) no treino 70% ==
                         MSE  RMSE DP_MSE
M1: MEDIA_MT         7646.28 87.44 116.04
M2: MEDIA_MT + RENDA 7603.97 87.20 126.58
```

- O modelo com RENDA melhora o RMSE em **0,24 ponto** (~0,6% do MSE): ganho mínimo em termos práticos.
- Como os dois modelos usam os mesmos folds, testar se esse ganho é consistente exigiria comparar a diferença de MSE fold a fold (pareada); o DP_MSE sozinho não serve para isso.

---

## 5. Avaliação final no teste (30%)

```r
avalia <- function(formula) {
  m <- lm(formula, data = treino)
  mse <- mean((teste$NU_NOTA_MT - predict(m, teste))^2)
  c(MSE = mse, RMSE = sqrt(mse))
}
```

```
== Teste 30% ==
                         MSE  RMSE
M1: MEDIA_MT         7563.48 86.97
M2: MEDIA_MT + RENDA 7515.30 86.69
```

- O RMSE no teste (86,97) é parecido com o do k-fold no treino (87,44): o desempenho **se mantém em dados novos**, sem sinal de "viciar".
- A melhora com RENDA (0,28 ponto) tem o mesmo tamanho da do k-fold: os modelos são **praticamente equivalentes**.

### Referência: desvio padrão

O desvio padrão de `NU_NOTA_MT` no teste é **121,62** (erro de "chutar" sempre a média). Com `MEDIA_MT`, o RMSE cai para **86,97**, redução de ~28% no erro, o que corresponde a **R² ≈ 0,49**: o modelo reduz bastante o erro, mas deixa cerca de metade da variabilidade sem explicar.

---

## 6. Bootstrap do coeficiente de MEDIA_MT

```r
B <- 2000

boot <- function(base) {
  nb <- nrow(base)
  b <- replicate(B, {
    i <- sample(nb, nb, replace = TRUE)
    c(sem = coef(lm(NU_NOTA_MT ~ MEDIA_MT,         data = base[i, ]))[[2]],
      com = coef(lm(NU_NOTA_MT ~ MEDIA_MT + RENDA, data = base[i, ]))[[2]])
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
sem     0.9818      0.0070   0.9679   0.9953
com     0.9709      0.0071   0.9569   0.9843
```

**Bootstrap nos dados completos**
```
    Estimativa Erro_padrao IC95_inf IC95_sup
sem     0.9803      0.0059   0.9686   0.9921
com     0.9690      0.0060   0.9570   0.9810
```

- O coeficiente é de ~**0,97**: mantendo a renda constante, cada ponto a mais em `MEDIA_MT` está associado a cerca de 0,97 ponto a mais em `NU_NOTA_MT`.
- O IC é estreito e longe de 0, e o **1 fica fora do intervalo**: o coeficiente é um pouco menor que 1.
- Incluir `RENDA` reduz o coeficiente em ~0,011 (cerca de 1%), e os ICs praticamente se sobrepõem.
- O resultado quase não depende da base usada; com os dados completos o erro padrão é um pouco menor (0,0059 contra 0,0070), como esperado por ter mais dados.

---

## 7. Conclusão geral

- No esquema 70/30, o k-fold (no treino) e o teste (30%) apontam o mesmo: incluir `RENDA` melhora o RMSE em menos de 0,3 ponto, diferença **mínima, sem relevância prática**.
- O coeficiente de `MEDIA_MT` é **estável** (~0,97), tanto no treino quanto nos dados completos, e quase não muda ao incluir a renda (queda de ~1%).
- A associação é, portanto, **robusta à renda**. Isso não prova que o modelo é bom (R² ≈ 0,49) nem exclui o efeito de variáveis não observadas; também pode indicar que a `RENDA` separa pouco os alunos.
- Como próximo passo, vale testar controles com mais poder de separação, como tipo de escola ou escolaridade da mãe.
