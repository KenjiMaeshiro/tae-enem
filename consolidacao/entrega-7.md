# Consolidação da Análise: Comparação de Modelos — `MEDIA_MT` × `MEDIA_MT` + `RENDA` (NU_NOTA_MT)

## 1. Objetivo

Comparar dois modelos de regressão linear para prever a nota de matemática (`NU_NOTA_MT`) e verificar se **acrescentar `RENDA` melhora a previsão**, usando três formas de avaliação: validação cruzada, teste (30%) e bootstrap.

Itens a responder:

- o erro de cada modelo na validação cruzada (K-fold) e no teste;
- quanto da variação da nota cada modelo explica;
- o tamanho e a precisão do coeficiente de `MEDIA_MT`, com e sem `RENDA`;
- uma frase com o que a comparação disse sobre o problema.

| Modelo | Preditores | Significado |
|---|---|---|
| **M1** | `MEDIA_MT` | Média das notas do ENEM **sem considerar matemática** |
| **M2** | `MEDIA_MT` + `RENDA` | M1 mais a variável de renda |

> **Nota de leitura:** esta consolidação foi feita a partir das saídas. Assumiu-se que `DP_MSE` é o desvio-padrão do MSE entre as 5 dobras e que a "Estimativa" do bootstrap é o **coeficiente de `MEDIA_MT`** nos modelos sem (`sem`) e com (`com`) `RENDA`.

---

## 2. Esquema de avaliação

| Etapa | Base usada | O que mede |
|---|---|---|
| K-fold (5 dobras) | Treino (70%) | Erro em dados deixados de fora, para comparar os modelos |
| Teste | 30% restantes | Erro em dados novos, usado **uma vez**, no final |
| Bootstrap (2.000 reamostras) | Treino (70%) e dados completos | Estimativa e incerteza do coeficiente de `MEDIA_MT` |

- **Regra do esquema**: tudo que ajusta ou compara modelos (a validação cruzada) usa só o **treino**; o **teste** fica intocado e é usado uma única vez.
- A métrica de erro é o **MSE** (erro quadrático médio) e sua raiz, o **RMSE**, que fica na mesma unidade da nota.
- **Linha de referência**: o desvio padrão de `NU_NOTA_MT` no teste é **121,62**. Esse é o RMSE de "chutar" sempre a média.

---

## 3. Validação cruzada (5 dobras, treino 70%)

```
== K-fold (5 folds) no treino 70% ==
                         MSE  RMSE DP_MSE
M1: MEDIA_MT         7646.28 87.44 116.04
M2: MEDIA_MT + RENDA 7603.97 87.20 126.58
```

| Modelo | MSE | RMSE | DP_MSE |
|---|:---:|:---:|:---:|
| M1: `MEDIA_MT` | 7646,28 | 87,44 | 116,04 |
| M2: `MEDIA_MT` + `RENDA` | 7603,97 | 87,20 | 126,58 |

- M2 reduz o MSE em ≈ 42 pontos (≈ **0,55%**) e o RMSE em ≈ 0,24.
- O erro-padrão do MSE médio é ≈ DP/√5, ou seja, ≈ 52 (M1) e ≈ 57 (M2). **A diferença entre os modelos (≈ 42) é menor que esse erro-padrão**, então não dá para apontar um vencedor só com a CV.

---

## 4. Teste (30%)

```
== Teste 30% ==
                         MSE  RMSE
M1: MEDIA_MT         7563.48 86.97
M2: MEDIA_MT + RENDA 7515.30 86.69

Desvio padrão de NU_NOTA_MT no teste: 121.62
```

| Modelo | MSE | RMSE | R² |
|---|:---:|:---:|:---:|
| Só a média | ≈ 14.791 | 121,62 | 0 |
| M1: `MEDIA_MT` | 7563,48 | 86,97 | ≈ 0,489 |
| M2: `MEDIA_MT` + `RENDA` | 7515,30 | 86,69 | ≈ 0,492 |

O R² é `1 − (RMSE / 121,62)²`.

- Os dois modelos reduzem o RMSE de "chutar a média" em cerca de **29%** e explicam ≈ **49%** da variância da nota.
- A `RENDA` acrescenta **≈ 0,3 ponto de RMSE** e **≈ 0,3 ponto percentual de R²**: ganho muito pequeno.
- O RMSE no teste (86,7 a 87,0) é parecido com o da validação cruzada (87,2 a 87,4): o desempenho **se mantém em dados novos**, sem sinal de sobreajuste.

---

## 5. Bootstrap (2.000 reamostras)

```
== Bootstrap no treino 70% (2000 reamostras) ==
    Estimativa Erro_padrao IC95_inf IC95_sup
sem     0.9818      0.0070   0.9679   0.9953
com     0.9709      0.0071   0.9569   0.9843

== Bootstrap nos dados completos (2000 reamostras) ==
    Estimativa Erro_padrao IC95_inf IC95_sup
sem     0.9803      0.0059   0.9686   0.9921
com     0.9690      0.0060   0.9570   0.9810
```

| Base | Modelo | Estimativa | Erro-padrão | IC 95% |
|---|---|:---:|:---:|:---:|
| Treino 70% | sem `RENDA` | 0,9818 | 0,0070 | [0,968; 0,995] |
| Treino 70% | com `RENDA` | 0,9709 | 0,0071 | [0,957; 0,984] |
| Dados completos | sem `RENDA` | 0,9803 | 0,0059 | [0,969; 0,992] |
| Dados completos | com `RENDA` | 0,9690 | 0,0060 | [0,957; 0,981] |

- **Leitura**: cada ponto a mais em `MEDIA_MT` corresponde a ≈ **0,97 a 0,98 ponto** a mais na nota de matemática, quase uma relação de um para um.
- **Precisão alta**: os erros-padrão são de ≈ 0,006 a 0,007, o que é esperado com muitas linhas.
- **Efeito da `RENDA` no coeficiente**: ao incluí-la, o coeficiente cai só ≈ **0,011** (≈ 1,1%). O efeito de `MEDIA_MT` é **estável** quando se controla por renda.
- **Os ICs se sobrepõem**, e a queda de ≈ 0,011 é cerca de 1,5 erro-padrão. Como os dois ajustes vêm das mesmas reamostras, o certo seria bootstrapar a diferença diretamente. Com estes números, não dá para afirmar que o coeficiente mudou.
- **Treino e dados completos dão praticamente o mesmo resultado**, o que reforça que a estimativa é robusta.

---

## 6. O que a comparação disse sobre o problema

> `MEDIA_MT` sozinha explica cerca de metade da variação da nota de matemática (R² ≈ 0,49, coeficiente ≈ 0,98), e acrescentar `RENDA` melhora o erro em apenas ≈ 0,3 ponto de RMSE, uma diferença menor que a variabilidade entre dobras e que não muda o coeficiente de `MEDIA_MT`.

---

## 7. Conclusão geral

- **`MEDIA_MT` é um bom preditor** da nota de matemática: quem vai bem nas outras provas tende a ir bem em matemática.
- **`RENDA` acrescenta pouco.** O ganho é menor que o erro-padrão da CV, e o coeficiente de `MEDIA_MT` quase não se altera. Pelo princípio da parcimônia, **M1 é suficiente**, e M2 só se justifica se a renda for de interesse por si mesma.
- Os três métodos de avaliação (CV, teste e bootstrap) **concordam**: M2 é marginalmente melhor ou igual a M1, e a conclusão não depende do método.
- O modelo deixa cerca de 51% da variabilidade sem explicar. Os dados não têm tudo o que importa (preparo do aluno, escola, condições no dia da prova). Ao incluir as notas das outras provas separadamente, o RMSE cai para ≈ 80 (análise com Lasso e Ridge).
- **Cuidados na leitura**:
  - **Associação não é causa**: o coeficiente descreve uma relação preditiva, não o efeito de aumentar a média.
  - **Diferenças pequenas**: M2 ganha em todas as métricas, mas por margens dentro do ruído.
  - **Comparação de ICs separados**: dois intervalos que se sobrepõem não provam que não há diferença. Para afirmar isso com rigor, é preciso bootstrapar a diferença.

### Próximos passos

1. Bootstrapar a **diferença de erro entre M1 e M2** (e do coeficiente) para dar um IC direto ao ganho da `RENDA`.
2. Comparar M1 e M2 **dobra a dobra** (teste pareado) e repetir a CV com outras sementes.
3. Incluir as notas CN, CH e LC separadas e o ano, para ver se o R² sobe além de 0,49.
4. Tratar `RENDA` como categoria ou em escala logarítmica, caso a relação não seja linear.
