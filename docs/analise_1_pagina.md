# Análise SQL — Olist

## Objetivo

Analisar o valor bruto dos itens do dataset Olist, identificando
a distribuição por status, categorias, produtos e períodos mensais.

As análises principais consideram somente pedidos com status
`delivered`, utilizados como representação de pedidos concluídos.

## Escopo analítico

- Métrica principal: `SUM(order_items.price)`.
- Universo principal: pedidos com status `delivered`.
- Categorias ausentes: agrupadas como `SEM_CATEGORIA`.
- Grain variável conforme a análise: status, categoria, mês ou produto.

## Principais achados

### 1. Pedidos entregues concentram a maior parte do valor bruto

Pedidos com status `delivered` representam 97,28% do valor bruto
dos itens, totalizando R$ 13.221.498,11.

Os demais status representam aproximadamente 2,72% do valor bruto.
Eles não foram considerados erros, mas ficaram fora das análises
principais porque o universo foi definido como pedidos concluídos.

### 2. A concentração por produto não segue uma divisão exata de 80/20

Entre os 32.216 produtos distintos presentes em pedidos entregues,
8.352 produtos são necessários para atingir 80,0019% do valor bruto.

Isso corresponde a 25,93% dos produtos do universo analisado.
Portanto, a distribuição apresenta concentração relevante, mas não
uma divisão exata em que 20% dos produtos representam 80% do valor.

Esse conjunto pode apoiar a priorização de monitoramento e testes
comerciais, mas a análise não mede margem, estoque, custos ou retorno
de campanhas.

### 3. As principais categorias apresentam combinações diferentes de volume e valor por item

As cinco categorias com maior valor bruto concentram 39,83% do
valor bruto dos itens pertencentes a pedidos entregues.

`beleza_saude` ocupa a primeira posição, com R$ 1.233.131,72,
9.465 itens e participação de 9,33%.

`relogios_presentes` aparece logo depois, com R$ 1.166.176,98,
5.859 itens e participação de 8,82%.

Embora os valores brutos sejam próximos, `relogios_presentes`
atinge esse resultado com uma quantidade consideravelmente menor
de itens e pedidos. O valor bruto médio por item é de aproximadamente
R$ 199,04 nessa categoria, contra R$ 130,28 em `beleza_saude`.

Essa diferença não representa necessariamente maior lucro ou
rentabilidade, pois custos, margens e estoque não estão disponíveis.

## Limitações

- `price` representa o valor bruto do item, sem incluir o frete. A
  métrica não deve ser interpretada automaticamente como faturamento,
  receita contábil, receita líquida, margem ou lucro.

- A fonte não disponibiliza nomes comerciais dos produtos; por isso,
  eles são apresentados por `product_id`.

- Os meses de borda possuem cobertura parcial e foram retirados da
  comparação mensal.

- Novembro de 2016 não possui pedidos registrados na fonte.

- Setembro de 2018 possui pedidos, mas nenhum com status `delivered`,
  produzindo ausência de valor dentro do universo analítico.

- As chaves e cardinalidades utilizadas foram observadas nos dados,
  mas não representam necessariamente constraints declaradas no banco.

- Janeiro de 2017 apresenta crescimento MoM de 1.025.573,03%,
  pois o valor bruto observado em dezembro de 2016 foi de apenas
  R$ 10,90. Esse resultado é matematicamente correto, mas sofre
  forte efeito de base e não deve ser interpretado isoladamente
  como crescimento operacional sustentável.

- Foram identificados 610 produtos sem categoria válida. Esses casos
  representam 1.603 itens e 1,32% do valor bruto geral, sendo
  preservados nas análises como `SEM_CATEGORIA`.

## Recomendação

Utilizar os produtos pertencentes à faixa Pareto e as categorias de
maior valor bruto como ponto de partida para monitoramento e testes
comerciais.

Antes de decisões de investimento, essa priorização deve ser combinada
com informações de margem, custos, estoque e desempenho das campanhas,
que não estão disponíveis nas tabelas analisadas.

