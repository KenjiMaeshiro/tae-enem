# Consolidação da Análise: Splines (Modelo Aditivo Generalizado, GAM)

## 1. Objetivo

Ajustar um **modelo aditivo com splines** (pacote `mgcv`) para estimar o **formato** da relação entre cada variável (`x1`, `x2`, `x3`) e `y`, e verificar se permitir curvas melhora a previsão em relação aos modelos anteriores.

Itens a responder:

- o erro do modelo comparado à linha de base e aos demais métodos;
- o grau de flexibilidade (EDF) que cada variável recebeu;
- o formato e a incerteza da curva de cada variável;
- uma frase com o que os splines disseram sobre o problema.

| Variável | Papel | Significado |
|---|---|---|
| `y` | Variável prevista | Binária (0/1), isto é, a probabilidade de `y = 1` |
| `x1`, `x2`, `x3` | Preditores | Cada um entra por uma função suave `s(x)`, somadas entre si |

---

## 2. Como o modelo funciona

- Um GAM escreve o logit da probabilidade como uma **soma de curvas suaves**, uma por variável: `logit P(y=1) = β₀ + s(x1) + s(x2) + s(x3)`.
- O `mgcv` escolhe a **suavidade de cada curva por conta própria**, penalizando curvas muito onduladas. O resultado é medido pelo **EDF** (graus de liberdade efetivos):
  - **EDF = 1**: a relação é uma **reta**.
  - **EDF > 1**: a relação é **curva**, e quanto maior o EDF, mais sinuosa.
- Cada curva é desenhada **centrada em zero**: o valor `0` é o efeito médio, e a faixa cinza é o intervalo de confiança de 95%.

---

## 3. Erro e comparação com os demais métodos

```
0.232590812250284
0.216075665039398
0.213788679699905

1. 0.212614530033379
2. 0.212617048875087
3. 0.212476039655739
4. 0.212459639792112
5. 0.212451486144522
6. 0.212444019295381
7. 0.212441398984395

0.212434030372048
```

| Modelo | Erro (EQM) | Ganho vs. linha de base |
|---|:---:|:---:|
| Linha de base (variância de y) | 0,23259 | 0% |
| Modelo comparativo 1 | 0,21608 | ≈ 7,1% |
| Modelo comparativo 2 | 0,21379 | ≈ 8,1% |
| GAM, primeiro valor da grade | 0,21261 | ≈ 8,6% |
| GAM, último valor da grade | 0,21244 | ≈ 8,7% |
| **GAM final** | **0,21243** | **≈ 8,7%** |

- O erro **cai a cada etapa e depois estabiliza**: da grade, os valores caem de 0,21261 para 0,21244, e as diferenças já ficam na 5ª casa decimal. Mais flexibilidade além disso não ajuda.
- Em relação aos métodos anteriores desta análise: **árvore 0,2178**, **floresta aleatória 0,2158** e **GAM 0,2124**. O GAM é o melhor, mas as medidas de erro foram obtidas por esquemas diferentes (CV, OOB), então a comparação é aproximada.
- O ganho total sobre a média é de ≈ 8,7%: **melhor que os demais métodos, mas ainda um poder preditivo baixo**.

---

## 4. Flexibilidade de cada variável (EDF)

```
s(x1)   3
s(x2)   7.21
s(x3)   1
```

| Termo | EDF | Leitura |
|---|:---:|---|
| `s(x1)` | 3 | Curva suave, com leve curvatura |
| `s(x2)` | 7,21 | **Curva bem sinuosa**: relação claramente não linear |
| `s(x3)` | 1 | **Reta**: o modelo não encontrou curvatura |

---

## 5. Os gráficos das curvas

![Curvas suaves estimadas pelo GAM para x1, x2 e x3](../imagens/splines.png)

Como ler: o eixo horizontal é a variável, o vertical é o efeito no logit (acima de 0, aumenta a probabilidade de `y = 1`; abaixo de 0, diminui). A faixa cinza é o IC de 95%.

| Variável | Formato da curva | Incerteza |
|---|---|---|
| **`x2`** (0 a 20) | Queda **forte e contínua**: efeito de ≈ +0,9 em x ≈ 0 para ≈ −1,6 em x ≈ 20. A queda é mais íngreme até x ≈ 5 e depois segue mais suave | **Faixa estreita**: efeito bem estimado e claramente diferente de 0 |
| **`x1`** (0 a ~830) | Descida **quase linear**, de ≈ +0,6 para ≈ −0,8 | Faixa **larga** em valores baixos, e o IC inclui o 0 até x ≈ 500. Só fica longe do 0 acima de x ≈ 600 |
| **`x3`** (0 a ~830) | Reta **levemente crescente**, de ≈ −0,5 para ≈ +0,25 | A faixa **cobre o 0 em toda a extensão**: efeito não distinguível de zero |

- As três curvas se cruzam em 0 perto de x ≈ 550. Isso é efeito da centralização, e não um achado.
- **`x2` domina o modelo.** Seu efeito é o maior e o mais preciso.
- **`x1` contribui na parte alta**: acima de ≈ 600, valores maiores reduzem a probabilidade de `y = 1`.
- **`x3` não tem efeito detectável** e é candidata a sair do modelo.

---

## 6. O que os splines disseram sobre o problema

> A probabilidade de `y = 1` cai de forma contínua e não linear com `x2` (EDF 7,2) e, bem mais fracamente, com `x1` nos valores altos, enquanto `x3` não tem efeito distinguível de zero; permitir curvas reduz o erro para ≈ 0,2124 (≈ 8,7% abaixo da média), o melhor resultado até aqui, mas ainda com poder preditivo baixo.

---

## 7. Conclusão geral

- **`x2` é a variável central**, e a relação é uma **queda contínua**, não um degrau. A árvore, que dividiu `x2` em um único corte em 3,125, aproximou essa queda por um degrau, e o spline mostra que ela continua até x ≈ 20.
- **`x1`** tem efeito moderado, concentrado nos valores altos. **`x3`** não tem efeito detectável (EDF = 1 e faixa cobrindo o 0).
- O GAM tem o **menor erro** entre os métodos, e como ele é **aditivo (sem interações)**, isso sugere que não há necessidade de interações para descrever os dados.
- O ganho de permitir curvas é **pequeno mas consistente**: 0,2161 → 0,2138 → 0,2124.
- O poder preditivo continua **baixo** (≈ 8,7% de redução do erro). Faltam variáveis ou o fenômeno tem muito ruído.
- **Cuidados na leitura**:
  - **Diferenças pequenas**: entre os modelos, as diferenças são de ≈ 0,001 a 0,002. É preciso repetir a CV com outras sementes antes de apontar um vencedor.
  - **Medidas de erro diferentes**: comparar GAM, árvore e floresta exige o mesmo esquema de validação.
  - **Associação não é causa**: as curvas descrevem relações preditivas.
  - **Sem o significado das variáveis**: não dá para interpretar os formatos em termos substantivos.

### Próximos passos

1. Repetir a CV com várias sementes e comparar GAM, árvore e floresta nas **mesmas dobras**.
2. **Remover `x3`** e ver se o erro permanece igual.
3. Testar uma interação entre `x1` e `x2` (`te(x1, x2)`).
4. Calcular **AUC** e **log-loss**, que são mais adequados que o erro quadrático para `y` binário.
5. Examinar a região de `x1` abaixo de ≈ 500, onde o IC é largo, e verificar a quantidade de dados ali.
