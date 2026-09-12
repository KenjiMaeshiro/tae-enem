# Consolidação da Análise: Regressão Logística — RAÇA x MEDIA (ENEM)

## 1. Objetivo

Investigar a relação entre a **média das notas do ENEM** (`MEDIA`) e a **cor/raça declarada** (`RACA`), usando regressão logística binária: **branco** vs. **não branco**.

---

## 2. Preparação dos dados

- **Importação**: CSV separado por `;`.
- **Notas**: convertidas de texto (vírgula decimal) para numérico.
- **Colunas categóricas** (`NU_ANO`, `TP_COR_RACA`, `CO_MUNICIPIO_PROVA`): convertidas para `character`, por serem identificadores, não números.
- **MEDIA**: média aritmética das cinco notas.

### Tratamento de `TP_COR_RACA` → `RACA`

Codificação oficial do INEP:

| Código | Categoria |
|:---:|---|
| 1 | Branca |
| 2 | Preta |
| 3 | Parda |
| 4 | Amarela |
| 5 | Indígena |
| 6 | Não informado (usado em anos anteriores) |

```r
dataset <- subset(dataset, TP_COR_RACA %in% 1:5)
```
O código `6` (não informado) é removido, pois não representa uma raça de fato.

```r
dataset$RACA <- ifelse(dataset$TP_COR_RACA == 1, FALSE, TRUE)
```
As categorias 2 a 5 são unificadas em `TRUE` (não branco), contra `FALSE` (branco = categoria 1). Essa junção é necessária porque a regressão logística exige uma variável resposta binária.

- **`na.omit(dataset)`**: remove linhas com valores ausentes.

---

## 3. Modelo de regressão logística

```r
m <- glm(RACA ~ MEDIA, data = dataset, family = binomial)
```

### Saída (`summary(m)`)
```
              Estimate Std. Error z value Pr(>|z|)    
(Intercept)  0.9148136  0.0692103   13.22   <2e-16 ***
MEDIA       -0.0025800  0.0001253  -20.59   <2e-16 ***

Null deviance: 47040 em 35470 gl
Residual deviance: 46608 em 35469 gl
AIC: 46612
```

- Coeficiente de `MEDIA` **negativo e significativo** (`p < 2e-16`): quanto maior a média, menor a chance de o participante ser não branco.
- A queda pequena da *deviance* nula para a residual indica que `MEDIA`, sozinha, explica pouco da variabilidade de `RACA` — é um preditor significativo, mas fraco isoladamente.

### Odds Ratio (`exp(coef(m))`)

| Termo | Odds Ratio |
|---|:---:|
| (Intercept) | 2,4963 |
| MEDIA | 0,9974 |

A cada ponto a mais na média, as chances de ser não branco caem ~0,26%. O efeito é pequeno por ponto, mas se acumula na escala de 0 a 1000 pontos.

---

## 4. Visualização do modelo

O gráfico mostra os pontos observados (azul), uma reta linear de referência (verde tracejada) e a curva sigmoide de probabilidades previstas pelo modelo logístico (laranja).

> 📌 **[ESPAÇO RESERVADO PARA A IMAGEM DO GRÁFICO DE REGRESSÃO LOGÍSTICA]**
>
> ![Gráfico de regressão logística RACA x MEDIA](imagem_regressao_logistica.png)

---

## 5. Matrizes de confusão por limiares fixos

Três limiares arbitrários (0.3, 0.5, 0.7) foram testados para converter as probabilidades em classificação binária.

**Limiar 0.3**
```
       previsto
real        0     1
  FALSE  1897 20166
  TRUE    659 12749
```
Superprevê o grupo não branco (muitos falsos positivos).

**Limiar 0.5**
```
       previsto
real        0     1
  FALSE 21719   344
  TRUE  13155   253
```
Inverte: subprevê fortemente o grupo não branco (muitos falsos negativos).

**Limiar 0.7**
```
       previsto
real        0     1
  FALSE 22063     0
  TRUE  13407     1
```
Praticamente não classifica ninguém como não branco.

**Conclusão:** os três limiares são pontos de corte convencionais, não baseados na distribuição real das probabilidades do modelo. O resultado são matrizes desequilibradas, o que motiva buscar um limiar estatisticamente derivado — o teste de curva ROC/AUC a seguir.

---

## 6. Curva ROC, AUC e limiar ideal

```r
library(pROC)
roc_m <- roc(dataset$RACA, p)
auc(roc_m)
plot(roc_m, col = "orange", lwd = 2, main = "Curva ROC - RACA ~ MEDIA")
limiar_ideal <- coords(roc_m, "best", best.method = "youden")
```

- **`roc()`**: calcula sensibilidade e especificidade para todos os limiares possíveis (não só os três testados manualmente). As mensagens `Setting levels: control = FALSE, case = TRUE` e `Setting direction: controls < cases` são automáticas do pacote, apenas indicando que ele identificou corretamente branco como controle e não branco como caso, com probabilidades maiores associadas a `TRUE`.
- **`auc()`**: mede a capacidade de discriminação do modelo (0,5 = acaso; 1,0 = perfeito).
- **`coords(..., "best", best.method = "youden")`**: encontra o limiar que maximiza sensibilidade + especificidade − 1, ou seja, o ponto de corte mais equilibrado para este modelo.

**Resultados obtidos:**
```
AUC: 0,5674
Limiar ideal (Youden): 0,3714
Sensibilidade: 0,6123
Especificidade: 0,4956
```

![Curva ROC - RACA ~ MEDIA](imagem_curva_roc.png)

A curva (laranja) fica próxima da diagonal (acaso), afastando-se pouco dela — consistente com a AUC de 0,5674 obtida.

### Comparação com os limiares fixos

| Limiar | Origem | Sensibilidade | Especificidade | Observação |
|---|---|:---:|:---:|---|
| 0.3 | Arbitrário | — | — | Superprevê não brancos |
| 0.5 | Arbitrário (padrão) | — | — | Subprevê não brancos |
| 0.7 | Arbitrário | — | — | Quase não prevê não brancos |
| **0,3714** | Ideal (Youden) | **0,6123** | **0,4956** | Equilíbrio parcial: acerta ~61% dos não brancos e ~50% dos brancos |

O limiar ideal (0,371) fica mais próximo de 0.3 do que de 0.5 ou 0.7, confirmando que os limiares 0.5 e 0.7 estavam calibrados alto demais. Ainda assim, sensibilidade e especificidade próximas de 0,5–0,6 — junto com uma **AUC de 0,5674** (pouco acima do acaso) — mostram que o modelo tem **discriminação muito fraca**: mesmo no ponto de corte ótimo, ele erra quase metade das classificações.

---

## 7. Comparação entre modelos (treino/teste e RMSE)

- **Divisão**: 70% treino / 30% teste (`set.seed(1)`).
- **m1**: `RACA ~ MEDIA`
- **m2**: `RACA ~ MEDIA + Q020` (variável socioeconômica)

```
m1: 0,4811
m2: 0,4796
```

O modelo m2 apresenta RMSE ligeiramente menor, mas a diferença (≈0,0016) é pequena — `Q020` contribui de forma marginal além do que `MEDIA` já explica.

---

## 8. Conclusão geral

- `MEDIA` tem relação **significativa e negativa** com a probabilidade de o participante ser não branco, sugerindo disparidade racial associada ao desempenho no ENEM.
- Isoladamente, porém, é um **preditor fraco**: pequena redução de deviance, matrizes de confusão instáveis nos limiares fixos, e **AUC de 0,5674** — próxima do acaso.
- O limiar ideal (0,371) corrige parcialmente o desequilíbrio dos limiares fixos, mas sensibilidade (0,612) e especificidade (0,496) mostram que o modelo ainda erra bastante em ambas as classes.
- Incluir `Q020` (m2) traz melhora apenas marginal em relação a `MEDIA` sozinha (m1).
