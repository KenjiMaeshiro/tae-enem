# Regressão Linear — Previsão da Nota de Matemática

## 1. Objetivo

Foi realizada uma análise de regressão linear com o objetivo de avaliar a relação entre o desempenho dos participantes nas demais áreas do ENEM e a nota obtida em Matemática.

Inicialmente, foi calculada a variável `MEDIA`, correspondente à média das cinco áreas do exame:

- Ciências da Natureza;
- Ciências Humanas;
- Linguagens;
- Matemática;
- Redação.

Entretanto, para a construção do modelo de regressão, foi utilizada a variável `MEDIA_MT`, calculada a partir das quatro áreas do ENEM **sem incluir a nota de Matemática**.

O modelo principal foi definido como:

`NU_NOTA_MT ~ MEDIA_MT`

Dessa forma, buscou-se verificar se o desempenho médio nas demais áreas poderia ser utilizado como variável explicativa para a nota de Matemática.

## 2. Preparação dos dados

Inicialmente, a base de dados foi importada e as cinco variáveis referentes às notas do ENEM foram convertidas para o formato numérico. Como os dados utilizavam vírgula como separador decimal, foi realizada a substituição da vírgula por ponto antes da conversão.

Em seguida, foram removidas as observações que apresentavam valores ausentes nas variáveis utilizadas.

Após o tratamento, foram calculadas duas médias:

- `MEDIA`: média das cinco notas do ENEM, incluindo Matemática;
- `MEDIA_MT`: média das quatro notas do ENEM, excluindo Matemática.

A variável `MEDIA` foi mantida na base para outras análises, enquanto `MEDIA_MT` foi utilizada como variável explicativa da regressão.

## 3. Definição da variável explicativa

A escolha de `MEDIA_MT` foi uma etapa importante da análise.

Inicialmente, a utilização de `MEDIA` poderia parecer adequada para explicar a nota de Matemática. Entretanto, existe um problema nessa abordagem: a própria nota de Matemática participa do cálculo de `MEDIA`.

Consequentemente, a relação entre `MEDIA` e `NU_NOTA_MT` seria naturalmente muito forte, pois parte da variável utilizada para explicar a nota já contém a própria nota que se deseja prever.

Isso produz uma relação enviesada por construção e dificulta a interpretação do modelo como uma análise do efeito do desempenho nas demais áreas sobre Matemática.

Por esse motivo, foi criada a variável `MEDIA_MT`, calculada pela média de:

- Ciências da Natureza;
- Ciências Humanas;
- Linguagens;
- Redação.

A nota de Matemática foi retirada do cálculo. Assim, `MEDIA_MT` representa exclusivamente o desempenho do participante nas demais áreas do exame.

Essa escolha permite avaliar de maneira mais adequada se existe uma relação entre o desempenho geral nas outras áreas e a nota de Matemática.

## 4. Ajuste da regressão linear

Foi ajustado o modelo:

`m <- lm(NU_NOTA_MT ~ MEDIA_MT, data = dataset)`

Nesse modelo, `NU_NOTA_MT` é a variável resposta e `MEDIA_MT` é a variável explicativa.

![Gráfico de dispersão entre a média sem Matemática e a nota de Matemática](imagens/regressao_media_mt)

O modelo apresentou os seguintes coeficientes:

| Variável | Coeficiente |
|---|---:|
| Intercepto | 8,8511 |
| `MEDIA_MT` | 0,9803 |

A equação estimada pode ser representada aproximadamente por:

`Nota de Matemática = 8,8511 + 0,9803 × MEDIA_MT`

O intercepto indica a nota estimada de Matemática quando `MEDIA_MT` é igual a zero. Como esse valor não possui uma interpretação prática relevante dentro da escala observada das notas do ENEM, o principal interesse está no coeficiente de `MEDIA_MT`.

O coeficiente de `MEDIA_MT` foi **0,9803**, indicando uma relação positiva entre o desempenho nas demais áreas e a nota de Matemática.

Em termos práticos, para cada aumento de **1 ponto na média das demais áreas**, o modelo estima um aumento de aproximadamente **0,98 ponto na nota de Matemática**, em média.

Portanto, os resultados indicam uma associação positiva e aproximadamente linear entre o desempenho nas quatro áreas consideradas em `MEDIA_MT` e o desempenho em Matemática.

## 5. Visualização dos resíduos

Também foi realizada uma análise dos resíduos do modelo, comparando os valores ajustados pela regressão com os resíduos.

![Gráfico de resíduos](imagens/residuos_regressao.png)

Os resíduos representam a diferença entre a nota observada e a nota estimada pelo modelo.

A análise gráfica permite verificar se os resíduos estão distribuídos aleatoriamente ao redor de zero. Um padrão de dispersão crescente ou decrescente pode indicar que a variância dos erros não permanece constante.

Esse comportamento foi posteriormente investigado de forma estatística por meio do teste de Breusch-Pagan.

## 6. Visualização dos resíduos em uma amostra reduzida

Para facilitar a visualização do funcionamento da regressão, foram selecionados os 15 primeiros participantes da base.

Foi ajustado um modelo específico para essa pequena amostra e adicionadas linhas verticais representando a distância entre a nota observada e a nota estimada pela regressão.


![Visualização dos resíduos dos 15 primeiros participantes](imagens/residuos_15.png)

Essa representação permite visualizar diretamente os erros de previsão do modelo. Quanto maior a distância entre o ponto observado e a reta de regressão, maior é o resíduo daquele participante.

A utilização dos 15 primeiros registros possui finalidade exclusivamente visual e didática, não sendo utilizada para tirar conclusões sobre o conjunto completo dos participantes.

## 7. Teste de Breusch-Pagan

A análise dos resíduos foi complementada pelo teste de Breusch-Pagan, realizado **sob orientação do professor**, com o objetivo de verificar estatisticamente a presença de heterocedasticidade.

A heterocedasticidade ocorre quando a variância dos resíduos não é constante ao longo dos valores previstos pelo modelo.

O resultado obtido foi:

- **BP = 63,417**
- **df = 1**
- **p-valor = 1,672 × 10⁻¹⁵**

O teste apresentou um p-valor extremamente inferior a 0,05. Dessa forma, rejeita-se a hipótese nula de homocedasticidade.

Portanto, há **evidência estatística de heterocedasticidade nos resíduos do modelo**.

Esse resultado confirma estatisticamente o comportamento identificado na análise gráfica dos resíduos, indicando que a variabilidade dos erros não permanece constante ao longo dos valores estimados.

Assim, embora o modelo apresente uma relação linear positiva entre `MEDIA_MT` e `NU_NOTA_MT`, a presença de heterocedasticidade deve ser considerada na avaliação das condições do modelo.

## 8. Avaliação e comparação dos modelos

Após o ajuste inicial, os dados foram divididos aleatoriamente em aproximadamente:

- 70% para treinamento;
- 30% para teste.

Foi utilizado `set.seed(1)` para garantir que a divisão pudesse ser reproduzida.

Foram então ajustados dois modelos no conjunto de treinamento:

### Modelo 1 — `m1`

`NU_NOTA_MT ~ MEDIA_MT`

Esse é o modelo principal da análise, pois utiliza como variável explicativa somente a média das quatro áreas que **não incluem Matemática**.

### Modelo 2 — `m2`

`NU_NOTA_MT ~ MEDIA_MT + MEDIA`

O segundo modelo foi utilizado **apenas como parâmetro de teste**, e não como uma alternativa metodologicamente adequada ao modelo principal.

Isso ocorre porque `MEDIA` contém a própria `NU_NOTA_MT` em sua composição. Portanto, ao utilizar `MEDIA` para prever `NU_NOTA_MT`, estamos fornecendo ao modelo uma variável que já possui diretamente a informação que se deseja prever.

Era esperado, portanto, que o erro de previsão do `m2` fosse extremamente próximo de zero.

Os RMSE obtidos no conjunto de teste foram:

| Modelo | RMSE |
|---|---:|
| `m1` | 185,8453 |
| `m2` | 7,7253 × 10⁻¹³ |

O `m1` apresentou RMSE de aproximadamente **185,85 pontos**, representando o erro de previsão do modelo que utiliza exclusivamente `MEDIA_MT`.

Já o `m2` apresentou RMSE praticamente igual a **zero**.

Esse resultado não deve ser interpretado como uma demonstração de que o `m2` é um modelo de previsão extremamente superior. O resultado ocorre principalmente porque `MEDIA` foi calculada utilizando a própria nota de Matemática.

Dessa forma, o `m2` funciona como uma espécie de **parâmetro de teste**, demonstrando empiricamente o problema causado pela inclusão da variável resposta dentro da variável explicativa. Como `MEDIA` contém `NU_NOTA_MT`, o modelo recebe indiretamente a informação que deveria tentar prever, fazendo com que o erro de previsão seja praticamente nulo.

Por esse motivo, o resultado do `m2` reforça a justificativa para a utilização de `MEDIA_MT` no modelo principal.

## 9. Considerações

A análise permitiu avaliar a relação entre o desempenho dos participantes nas diferentes áreas do ENEM e sua nota de Matemática por meio de regressão linear.

Um dos principais cuidados metodológicos foi a definição da variável explicativa. A utilização direta de `MEDIA` produziria uma relação artificialmente forte com `NU_NOTA_MT`, pois a própria nota de Matemática participa do cálculo da média.

Para evitar esse problema, foi criada `MEDIA_MT`, calculada a partir das notas de Ciências da Natureza, Ciências Humanas, Linguagens e Redação, excluindo Matemática. Dessa forma, a variável utilizada para explicar o desempenho em Matemática não contém diretamente a variável que se deseja prever.

O modelo principal apresentou coeficiente de **0,9803 para `MEDIA_MT`**, indicando uma relação positiva: participantes com maiores médias nas demais áreas tendem, em média, a apresentar maiores notas em Matemática.

A análise dos resíduos também foi realizada para avaliar o comportamento dos erros do modelo. Sob orientação do professor, foi aplicado o teste de Breusch-Pagan, que apresentou **p-valor de 1,672 × 10⁻¹⁵**. O resultado fornece forte evidência de heterocedasticidade, indicando que a variância dos resíduos não é constante.

Por fim, foi realizada uma comparação utilizando os modelos `m1` e `m2`. O `m1`, considerado o modelo adequado para a proposta da análise, apresentou RMSE de **185,85** no conjunto de teste. O `m2` apresentou RMSE praticamente igual a zero, mas esse resultado já era esperado e não representa uma melhoria real do modelo.

O `m2` foi utilizado apenas como parâmetro de teste para demonstrar o efeito da inclusão de `MEDIA`, uma variável que contém a própria nota de Matemática. Seu erro praticamente nulo evidencia justamente por que essa variável não deve ser utilizada para explicar `NU_NOTA_MT` em uma análise que pretende avaliar a relação entre Matemática e as demais áreas.

Portanto, para a finalidade proposta, o `m1` constitui a referência metodologicamente adequada, enquanto o `m2` serve para evidenciar, por meio dos resultados de previsão, o problema de utilizar uma variável explicativa que incorpora a própria variável resposta.
