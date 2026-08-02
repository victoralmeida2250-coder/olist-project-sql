-- =========================================================
-- 1. TOP 10 PRODUTOS POR VALOR BRUTO DENTRO DE CADA CATEGORIA
-- Objetivo:
-- Identificar os produtos com maior valor bruto de itens
-- dentro de cada categoria, considerando pedidos entregues.
--
-- Grain final:
-- Uma linha por produto dentro de uma categoria normalizada.
-- =========================================================

WITH produtos_agregados AS (
    SELECT
        COALESCE(
            NULL
            IF(TRIM(p.product_category_name), ''),
            'SEM_CATEGORIA'
        ) AS categoria,
        p.product_id,
        SUM(oi.price) AS valor_bruto_produto,
        COUNT(*) AS total_itens_produto,
        COUNT(DISTINCT oi.order_id) AS total_pedidos_produto
    FROM olist_order_items_dataset AS oi
    INNER JOIN olist_products_dataset AS p
        ON oi.product_id = p.product_id
    INNER JOIN olist_orders_dataset AS o
        ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY
        COALESCE(
            NULLIF(TRIM(p.product_category_name), ''),
            'SEM_CATEGORIA'
        ),
        p.product_id
),
produtos_ranqueados AS (
    SELECT
        categoria,
        product_id,
        valor_bruto_produto,
        total_itens_produto,
        total_pedidos_produto,
        DENSE_RANK() OVER (
            PARTITION BY categoria
            ORDER BY valor_bruto_produto DESC
        ) AS posicao_produto,
        SUM(valor_bruto_produto) OVER (
            PARTITION BY categoria
        ) AS valor_bruto_total_categoria
    FROM produtos_agregados
)
SELECT
    categoria,
    product_id,
    valor_bruto_produto,
    total_itens_produto,
    total_pedidos_produto,
    posicao_produto
FROM produtos_ranqueados
WHERE posicao_produto <= 10
ORDER BY
    valor_bruto_total_categoria DESC,
    categoria,
    posicao_produto,
    product_id;
/*
Interpretação:

A consulta identifica os produtos com as dez maiores posições
de valor bruto dentro de cada categoria normalizada, considerando
somente itens pertencentes a pedidos entregues.

Uma linha representa um produto dentro de uma categoria.

valor_bruto_produto representa a soma de price dos itens
associados ao produto.

total_itens_produto representa a quantidade de linhas de
order_items associadas ao produto.

total_pedidos_produto representa a quantidade de pedidos
distintos que possuem pelo menos um item do produto.

posicao_produto representa a posição do produto dentro de sua
categoria, ordenada pelo valor bruto do produto.

DENSE_RANK preserva empates. Por isso, uma categoria pode apresentar
mais de dez linhas quando dois ou mais produtos compartilham uma
das dez primeiras posições.

Produtos sem categoria válida são agrupados como SEM_CATEGORIA,
preservando sua participação no universo analítico.

A fonte não disponibiliza o nome comercial dos produtos.
Por isso, eles são identificados por product_id.

A consulta não mede lucro, margem, rentabilidade ou receita líquida.
*/