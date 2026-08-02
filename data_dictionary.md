# Dicionário de Dados

## Visão geral

Este documento descreve as tabelas utilizadas no projeto,
seus grains, principais chaves e colunas relevantes para as
análises SQL.

## Relações principais

- `olist_orders_dataset.order_id`
  → `olist_order_items_dataset.order_id`
  → relação observada `1:N`.

- `olist_products_dataset.product_id`
  → `olist_order_items_dataset.product_id`
  → relação observada `1:N`.

As relações foram observadas nos dados, mas não representam
necessariamente constraints declaradas no banco.

## `olist_orders_dataset`

**Grain:** uma linha por pedido.

**Chave observada:** `order_id`.


| Coluna | Tipo | Descrição | Observações |
|---|---|---|---|
| `order_id` | texto | Identificador do pedido | Único e não nulo nos dados observados |
| `customer_id` | texto | Identificador do cadastro de cliente associado ao pedido | Único e não nulo nesta tabela: 99.441 valores distintos em 99.441 linhas. Não deve ser interpretado automaticamente como identificador permanente de uma pessoa |
| `order_status` | texto | Estado do pedido no ciclo operacional, como `delivered`, `shipped` ou `canceled` | Não possui valores nulos. Foram observados 8 status distintos. As análises principais utilizam `delivered` como definição do universo de pedidos concluídos |
| `order_purchase_timestamp` | timestamp | Data e hora em que o pedido foi realizado | Não possui valores nulos. Utilizada como referência temporal nas análises mensais |
| `order_approved_at` | timestamp | Data e hora de aprovação do pedido | Possui 160 valores nulos |
| `order_delivered_carrier_date` | timestamp | Data e hora em que o pedido foi entregue à transportadora | Possui 1.783 valores nulos, o que pode estar relacionado a pedidos que não chegaram a essa etapa |
| `order_delivered_customer_date` | timestamp | Data e hora em que o pedido foi entregue ao cliente | Possui 2.965 valores nulos, o que pode estar relacionado a pedidos não entregues |
| `order_estimated_delivery_date` | timestamp | Data estimada para entrega do pedido | Não possui valores nulos. Representa uma previsão, não a data efetiva de entrega |

## `olist_order_items_dataset`

**Grain:** uma linha por item dentro de um pedido.

**Chave candidata observada:** `(order_id, order_item_id)`.

A combinação apresentou unicidade e ausência de nulos nos dados
observados. Entretanto, não foi identificada uma constraint
`PRIMARY KEY` ou `UNIQUE` declarada no banco.

| Coluna | Tipo | Descrição | Observações |
|---|---|---|---|
| `order_id` | texto | Identificador do pedido ao qual o item pertence | Não possui valores nulos. Não é único, pois um pedido pode conter múltiplos itens |
| `order_item_id` | inteiro | Posição sequencial do item dentro do pedido | Não possui valores nulos. Não é único isoladamente, pois a numeração recomeça em cada pedido |
| `product_id` | texto | Identificador do produto associado ao item | Não possui valores nulos. Um mesmo produto pode aparecer em diferentes itens e pedidos |
| `seller_id` | texto | Identificador do vendedor responsável pelo item | Não possui valores nulos. Um mesmo vendedor pode aparecer em múltiplos itens e pedidos |
| `shipping_limit_date` | timestamp | Data e hora limite para envio do item pelo vendedor | Campo operacional relacionado ao prazo de postagem do item |
| `price` | numérico | Valor bruto do item, sem incluir o frete | Utilizado como métrica principal do projeto. Não deve ser interpretado automaticamente como lucro, margem ou receita líquida |
| `freight_value` | numérico | Valor de frete associado ao item | Está no grain de item. Somá-lo representa o frete registrado nas linhas de itens |

## `olist_products_dataset`

**Grain:** uma linha por produto.

**Chave observada:** `product_id`.

`product_id` apresentou unicidade e ausência de nulos nos dados
observados. Não foi identificada uma constraint `PRIMARY KEY`
ou `UNIQUE` declarada no banco.

| Coluna | Tipo | Descrição | Observações |
|---|---|---|---|
| `product_id` | texto | Identificador do produto | Único e não nulo nos dados observados: 32.951 valores distintos em 32.951 linhas |
| `product_category_name` | texto | Categoria associada ao produto | Foram encontrados 610 produtos sem categoria válida, considerando `NULL`, string vazia ou apenas espaços. Nas análises, esses casos foram agrupados como `SEM_CATEGORIA` |
| `product_name_lenght` | inteiro | Quantidade de caracteres no nome do produto | Possui 610 valores nulos. O nome comercial não é disponibilizado; a coluna contém apenas seu comprimento |
| `product_description_lenght` | inteiro | Quantidade de caracteres na descrição do produto | Possui 610 valores nulos. A descrição não é disponibilizada; a coluna contém apenas seu comprimento |
| `product_photos_qty` | inteiro | Quantidade de fotos associadas ao produto | Possui 610 valores nulos |
| `product_weight_g` | inteiro | Peso do produto em gramas | Possui 2 valores nulos |
| `product_length_cm` | inteiro | Comprimento do produto em centímetros | Possui 2 valores nulos |
| `product_height_cm` | inteiro | Altura do produto em centímetros | Possui 2 valores nulos |
| `product_width_cm` | inteiro | Largura do produto em centímetros | Possui 2 valores nulos |

## Convenções analíticas do projeto

- `price` representa o valor bruto do item, sem incluir `freight_value`.
  Não deve ser interpretado automaticamente como lucro, margem ou
  receita líquida.

- As análises principais utilizam pedidos com
  `order_status = 'delivered'` como universo de pedidos concluídos.

- Categorias `NULL`, vazias ou compostas apenas por espaços são
  normalizadas como `SEM_CATEGORIA`.

- `customer_id` é único na tabela de pedidos observada, mas não deve
  ser interpretado automaticamente como identificador permanente
  de uma pessoa.

- As chaves e relações descritas foram observadas nos dados.
  Não representam necessariamente constraints declaradas no banco.





