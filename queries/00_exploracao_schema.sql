/*
Arquivo:
00_exploracao_schema.sql

Objetivo:
Explorar estrutura, volume, período, grain, unicidade
e integridade básica das tabelas utilizadas no projeto.

Tabelas:
- olist_orders_dataset
- olist_order_items_dataset
- olist_products_dataset

Objetivo da exploração:
Entender os dados antes de construir métricas analíticas
e identificar riscos de duplicação ou perda de linhas.
*/


-- =========================================================
-- 1. CONTAGEM DE LINHAS POR TABELA
-- Objetivo:
-- Conhecer o volume inicial das tabelas utilizadas.
-- =========================================================

SELECT
    COUNT(*) AS total_orders
FROM olist_orders_dataset;

SELECT
    COUNT(*) AS total_order_items
FROM olist_order_items_dataset;

SELECT
    COUNT(*) AS total_products
FROM olist_products_dataset;

/*
Resultado:
orders      = 99.441 linhas
order_items = 112.650 linhas
products    = 32.951 linhas

Observação:
order_items possuir mais linhas que orders é compatível com
o grain esperado de uma linha por item de pedido.
*/


-- =========================================================
-- 2. PERÍODO DOS PEDIDOS
-- Objetivo:
-- Identificar o período mínimo e máximo disponível
-- na tabela de pedidos.
-- =========================================================

SELECT
    MIN(order_purchase_timestamp)::DATE AS periodo_min,
    MAX(order_purchase_timestamp)::DATE AS periodo_max,
    MAX(order_purchase_timestamp)::DATE
        - MIN(order_purchase_timestamp)::DATE AS diferenca_dias
FROM olist_orders_dataset;

/*
Resultado:
período mínimo: 2016-09-04
período máximo: 2018-10-17
amplitude entre datas: 773 dias

Observação:
A amplitude não prova existência de pedidos em todos os dias
do intervalo. Os períodos nas extremidades também podem
representar meses parciais.
*/


-- =========================================================
-- 3. UNICIDADE E GRAIN DE ORDERS
-- Objetivo:
-- Verificar se o grain esperado de uma linha por pedido
-- é compatível com os dados observados.
-- =========================================================

SELECT 
    COUNT(*) AS contagem_todas_linhas_order,
    COUNT(order_id) AS contagem_order_id,
    COUNT(DISTINCT order_id) AS contagem_distinta_order_id
FROM olist_orders_dataset;

/*
Resultado:
- total de linhas: 99.441
- order_id não nulos: 99.441
- order_id distintos: 99.441

Interpretação:
A coluna order_id não apresenta valores nulos nem duplicados
nos dados observados.

Isso é compatível com o grain esperado de uma linha por pedido.

Importante:
Essa validação demonstra unicidade e ausência de NULL no dataset,
mas não significa que exista uma constraint PRIMARY KEY definida
no PostgreSQL.
*/

-- =========================================================
-- 3.1. DUPLICIDADE E GRAIN DE ORDERS
-- Objetivo:
-- Verificar se o grain esperado de uma linha por pedido
-- é compatível com os dados observados.
-- =========================================================

select 
	order_id as order_id_duplicado, 
	count(*) as contagem_duplicatas
from olist_orders_dataset
group by order_id
having count(*) > 1;

/*
Resultado:
0 linhas retornadas.

Interpretação:
Não foram encontrados order_id duplicados na tabela
olist_orders_dataset.

Isso reforça a hipótese de grain de uma linha por pedido.
*/

-- =========================================================
-- 4. Verificação de unicidade E GRAIN DE ORDER_ITEMS
-- Objetivo:
-- Verificar se o grain esperado de uma linha por item de pedido
-- é compatível com os dados observados. Ou seja, é esperado duplicatas aqui.
-- Ao analisar a tabela de order_items, encontrei uma possível chave candidata composta por (order_id, order_item_id), que deve ser única.
-- Para validar isso, podemos contar a quantidade de linhas distintas para essa chave composta e comparar com o total de linhas da tabela.
-- =========================================================

SELECT
    COUNT(*) AS total_linhas_order_items,
    COUNT(DISTINCT (order_id, order_item_id))
        AS total_distinto_chave_composta
FROM olist_order_items_dataset;

/*
Resultado da query anterior:
- total_linhas_order_items: 112.650
- total_distinto_chave_composta: 112.650

Interpretação:
A combinação das colunas (order_id, order_item_id) é única.
Isso confirma que o grain da tabela olist_order_items_dataset
é uma linha por item dentro de um pedido.

A coluna order_item_id, por si só, não é única, pois representa
a sequência de itens dentro de um pedido (ex: item 1, item 2, etc.).
A unicidade da combinação (order_id, order_item_id) foi observada nos dados analisados.
*/

-- =========================================================
-- 4.1. DUPLICIDADE DE ORDER_ITEMS (CHAVE COMPOSTA)
-- Objetivo:
-- Confirmar explicitamente a ausência de duplicatas para a chave
-- composta (order_id, order_item_id).
-- =========================================================

select
    order_id,
    order_item_id,
    count(*) as contagem_duplicatas
from olist_order_items_dataset
group by
    order_id,
    order_item_id
having count(*) > 1;/*
Resultado:
0 linhas retornadas.

Interpretação:
Não foram encontrados registros duplicados para a chave composta
(order_id, order_item_id) na tabela olist_order_items_dataset.

Isso valida que o grain da tabela é uma linha por item de pedido,
identificado de forma única pela combinação dessas duas colunas.
*/

-- =========================================================
-- 4.2. VERIFICAÇÃO DE NÃO NULOS NAS CHAVES COMPOSTAS
-- Objetivo:
-- Confirmar que não existem valores nulos nas colunas que compõem
-- a chave composta (order_id, order_item_id).  
-- =========================================================
SELECT
    COUNT(*) - COUNT(order_id) AS order_id_nulos,
    COUNT(*) - COUNT(order_item_id) AS order_item_id_nulos
FROM olist_order_items_dataset;

/*
Resultado:
order_id_nulos: 0
order_item_id_nulos: 0
Interpretação:
Não foram encontrados valores nulos nas colunas order_id e order_item_id,
Isso reforça a evidência de que a combinação
(order_id, order_item_id) se comporta como chave candidata.
E confirma que o grain da tabela é uma linha por item de pedido.
*/

-- =========================================================
-- 5. UNICIDADE E GRAIN DE PRODUCTS
-- Objetivo:
-- Verificar se o grain esperado de uma linha por produto
-- é compatível com os dados observados.
-- =========================================================

SELECT
    COUNT(*) AS contagem_todas_linhas_products,
    COUNT(product_id) AS contagem_product_id,
    COUNT(DISTINCT product_id) AS contagem_distinta_product_id
FROM olist_products_dataset;

/*
Resultado:
- total de linhas: 32.951
- product_id não nulos: 32.951
- product_id distintos: 32.951

Interpretação:
A coluna product_id não apresenta valores nulos nem duplicados
nos dados observados.

Isso é compatível com o grain esperado de uma linha por produto.
*/

-- =========================================================
-- 5.1. DUPLICIDADE DE PRODUCTS
-- Objetivo:
-- Confirmar explicitamente a ausência de duplicatas para a chave
-- product_id.
-- =========================================================
SELECT
    product_id,
    COUNT(*) AS contagem_duplicatas
FROM olist_products_dataset
GROUP BY product_id 
HAVING COUNT(*) > 1;

/*
Resultado:
0 linhas retornadas.

Interpretação:
Não foram encontrados product_id duplicados na tabela
olist_products_dataset.

Isso reforça a hipótese de grain de uma linha por produto.
*/


-- =========================================================
-- 6. PRODUTOS SEM CATEGORIA
-- Objetivo:
-- Identificar produtos sem categoria válida, considerando
-- NULL, string vazia e valores compostos apenas por espaços.
-- =========================================================

SELECT
    COUNT(*) AS total_produtos,
    SUM(
        CASE
            WHEN NULLIF(TRIM(product_category_name), '') IS NULL
            THEN 1
            ELSE 0
        END
    ) AS produtos_sem_categoria,
    SUM(
        CASE
            WHEN NULLIF(TRIM(product_category_name), '') IS NOT NULL
            THEN 1
            ELSE 0
        END
    ) AS produtos_com_categoria
FROM olist_products_dataset;
-- Camada de inspeção básica para identificar produtos sem categoria válida, considerando NULL, string vazia e valores compostos apenas por espaços.
SELECT
    product_id,
    product_category_name
FROM olist_products_dataset
WHERE NULLIF(TRIM(product_category_name), '') IS NULL
LIMIT 20;

/*
Resultado:
- total de produtos: 32.951
- produtos sem categoria: 610
- produtos com categoria: 32.341

Interpretação:
Foram encontrados 610 produtos sem categoria válida.

A validação considera como ausência:
- NULL;
- string vazia ('');
- texto formado apenas por espaços.

Isso significa que a cobertura de categoria da tabela products
não é completa.

Risco analítico:
Análises agrupadas por categoria precisam decidir explicitamente
como tratar esses 610 produtos, pois excluí-los pode reduzir
contagens e valor bruto analisado.
*/

-- =========================================================
-- 7. INTEGRIDADE ENTRE ORDER_ITEMS E PRODUCTS
-- Objetivo:
-- Verificar se todos os product_id presentes em order_items
-- possuem correspondência na tabela products.
-- =========================================================

SELECT
    COUNT(DISTINCT oi.product_id) AS total_product_id_order_items,
    COUNT(DISTINCT p.product_id) AS  product_ids_correspondentes,
    COUNT(DISTINCT oi.product_id) - COUNT(DISTINCT p.product_id)
        AS diferenca_product_id
FROM olist_order_items_dataset oi
LEFT JOIN olist_products_dataset p
    ON oi.product_id = p.product_id;

/*
Resultado:
- total_product_id_order_items: 32.951
- product_ids_correspondentes: 32.951
- diferenca_product_id: 0

Interpretação:
Todos os product_id presentes na tabela order_items possuem correspondência na tabela products.
Isso indica integridade referencial observada nos dados analisados, não foram observados product_id órfãos em order_items que não estejam registrados em products.
*/  
-- =========================================================
-- 7.1 INTEGRIDADE ENTRE ORDER_ITEMS E PRODUCTS (DETALHAMENTO)
-- Objetivo:
-- Identificar quais product_id presentes em order_items não possuem correspondência na tabela products.
-- =========================================================

-- Contagem de quantos itens ficaram sem produtos
SELECT 
    SUM(
        CASE
            WHEN p.product_id IS NULL THEN 1
            ELSE 0
        END
    ) AS itens_sem_produto_correspondente
FROM olist_order_items_dataset oi
LEFT JOIN olist_products_dataset p
    ON oi.product_id = p.product_id;
-- Detalhamento dos product_id sem correspondência em products
SELECT 
    oi.product_id AS product_id_sem_correspondencia,
    COUNT(*) AS contagem_ocorrencias
FROM olist_order_items_dataset oi
LEFT JOIN olist_products_dataset p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL
GROUP BY oi.product_id
ORDER BY contagem_ocorrencias DESC
LIMIT 20;

/*
Resultado:
- 0 itens sem product_id correspondente em products.
- A consulta de inspeção retornou 0 linhas.

Interpretação:
Todos os product_id presentes em order_items possuem
correspondência na tabela products nos dados observados.

Risco ainda existente:
A correspondência com products não garante que o produto
possua categoria válida. Já foram identificados 610 produtos
sem categoria válida em products.
*/

-- =========================================================
-- 8. PEDIDOS SEM ITENS
-- Objetivo:
-- Identificar pedidos presentes em orders que não possuem
-- nenhuma linha correspondente em order_items.
-- =========================================================
SELECT
    COUNT(*) AS total_orders_sem_itens
FROM olist_orders_dataset o
LEFT JOIN olist_order_items_dataset oi
    ON o.order_id = oi.order_id
WHERE oi.order_id IS NULL;

/*
Resultado:
- total_orders_sem_itens: 775

Interpretação:
Foram encontrados 775 pedidos presentes em
olist_orders_dataset sem linha correspondente em
olist_order_items_dataset.

A ausência de correspondência não é tratada automaticamente
como erro, pois pode estar relacionada ao estágio ou desfecho
do pedido.

Risco analítico:
Um INNER JOIN entre orders e order_items excluirá esses
775 pedidos da população analisada. Isso precisa ser considerado
principalmente em métricas de quantidade de pedidos, status e
taxas calculadas sobre o total de pedidos.
*/

-- =========================================================
-- 8.1 PEDIDOS SEM ITENS POR STATUS
-- Objetivo:
-- Entender em quais status estão concentrados os pedidos
-- sem correspondência em order_items.
-- =========================================================
SELECT
    o.order_status,
    COUNT(o.order_id) AS total_orders_sem_itens
FROM olist_orders_dataset o
LEFT JOIN olist_order_items_dataset oi
    ON o.order_id = oi.order_id
WHERE oi.order_id IS NULL
GROUP BY o.order_status
ORDER BY total_orders_sem_itens DESC;

/*
Resultado:
unavailable = 603
canceled    = 164
created     =   5
invoiced    =   2
shipped     =   1
------------------
total       = 775

Interpretação:
Foram encontrados 603 pedidos com status "unavailable" e 164 pedidos com status "canceled" que não possuem itens correspondentes em order_items. 
Além disso, há 5 pedidos com status "created", 2 com status "invoiced" e 1 com status "shipped" sem itens.
Isso sugere que a maioria dos pedidos sem itens está relacionada a situações de indisponibilidade ou cancelamento, mas também existem casos em outros status que merecem investigação adicional, 
pois a ausência de itens não está restrita aos status unavailable e canceled.

Risco analítico:
Tratar todos os pedidos sem itens como inválidos ou excluí-los das análises pode ser uma abordagem, mas é importante considerar o impacto nos resultados e entender a origem desses pedidos para tomar decisões informadas.
*/  

-- =========================================================
-- Seção 9 — itens sem pedido correspondente.
-- Objetivo:
-- Identificar itens presentes em order_items que não possuem
-- nenhuma linha correspondente em orders.
-- =========================================================

SELECT 
    COUNT(*) AS total_itens_sem_pedido_correspondente
FROM olist_order_items_dataset oi
LEFT JOIN olist_orders_dataset o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

/*
Resultado:
- total_itens_sem_pedido_correspondente: 0

Interpretação:
Todos os order_id presentes em olist_order_items_dataset
possuem correspondência na tabela olist_orders_dataset
nos dados observados.

Isso indica integridade referencial observada no sentido
order_items -> orders.

Importante:
Essa validação não significa que exista uma FOREIGN KEY
declarada no PostgreSQL; significa apenas que não foram
encontrados órfãos nos dados analisados.
*/



-- =========================================================
-- 10. RESUMO DA EXPLORAÇÃO
-- =========================================================

/*
RESUMO GERAL:

Grains observados:
- olist_orders_dataset:
  uma linha por pedido, identificado por order_id.

- olist_order_items_dataset:
  uma linha por item dentro de um pedido.
  A combinação (order_id, order_item_id) comporta-se como
  chave candidata composta nos dados observados.

- olist_products_dataset:
  uma linha por produto, identificado por product_id.

Integridade observada:
- não foram encontrados order_id órfãos em order_items;
- não foram encontrados product_id órfãos em order_items;
- order_id é único e não nulo em orders;
- product_id é único e não nulo em products;
- a combinação (order_id, order_item_id) é única e não nula
  em order_items.

Pontos de atenção:
- 775 pedidos em orders não possuem itens correspondentes;
- a maior parte desses casos está nos status unavailable
  e canceled, mas existem outros status;
- 610 produtos não possuem categoria válida;
- meses nas extremidades do período podem ser parciais.

Conclusão:
A estrutura e os relacionamentos observados são compatíveis
com as análises planejadas, mas as métricas ainda precisam ser
validadas antes e depois dos JOINs para garantir ausência de
multiplicação ou perda indevida de linhas e valores.

Próxima etapa:
Executar validações de cardinalidade, contagem de linhas e soma
de price no arquivo 99_validacoes.sql.
*/








