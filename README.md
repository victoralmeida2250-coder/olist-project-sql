# O Detetive de Dados — Análise SQL com Olist

Projeto final da Semana 1 do Bootcamp Analytics Engineering 4.0.

A análise utiliza PostgreSQL para explorar, validar e analisar dados de pedidos, itens e produtos do dataset Olist.

## Objetivo

Investigar a distribuição do valor bruto dos itens por status, categoria, produto e período mensal, aplicando validações de grain, cardinalidade, JOINs e qualidade dos dados.

> `SUM(price)` representa o valor bruto dos itens e não deve ser interpretado automaticamente como receita, margem ou lucro.

## Principais resultados

- Pedidos com status `delivered` concentram **97,28%** do valor bruto dos itens, totalizando **R$ 13.221.498,11**.

- **8.352 de 32.216 produtos** presentes em pedidos entregues concentram **80,0019%** do valor bruto. Isso corresponde a **25,93%** dos produtos do universo analisado.

- As cinco maiores categorias concentram **39,83%** do valor bruto dos itens entregues.

- Foram identificados **610 produtos sem categoria válida**. Esses registros foram preservados como `SEM_CATEGORIA`.

## Stack

- PostgreSQL
- Docker
- DBeaver
- VS Code
- Git e GitHub

## Estrutura do projeto

```text
queries/
├── 00_exploracao_schema.sql
├── 01_top_categorias.sql
├── 02_ranking_mensal.sql
├── 03_ranking_produtos.sql
├── 04_limpeza_status.sql
├── 05_pareto.sql
└── 99_validacoes.sql

docs/
└── analise_1_pagina.md

data_dictionary.md
README.md
```

## Ordem sugerida de leitura

1. `queries/00_exploracao_schema.sql`
2. `queries/99_validacoes.sql`
3. `queries/01_top_categorias.sql`
4. `queries/04_limpeza_status.sql`
5. `queries/02_ranking_mensal.sql`
6. `queries/03_ranking_produtos.sql`
7. `queries/05_pareto.sql`

## Decisões analíticas

- As análises principais consideram apenas pedidos com status `delivered`.
- Categorias nulas, vazias ou compostas apenas por espaços são tratadas como `SEM_CATEGORIA`.
- Os meses de borda parcial foram retirados da comparação MoM.
- Produtos são apresentados por `product_id`, pois a fonte não disponibiliza nomes comerciais.

## Documentação

- [Análise executiva de uma página](docs/analise_1_pagina.md)
- [Dicionário de dados](data_dictionary.md)

## Limitações

A fonte não contém informações suficientes sobre custos, margem, estoque, impostos, estornos ou desempenho de campanhas.

Os resultados podem apoiar priorizações, monitoramento e investigações, mas não sustentam isoladamente decisões completas de investimento.