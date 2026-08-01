-- =========================================================
-- 1. TOP 5 CATEGORIAS POR VALOR BRUTO DOS ITENS
-- Objetivo:
-- Identificar as categorias com maior valor bruto de itens
-- entre pedidos entregues.
-- =========================================================

SELECT 
    COALESCE(
        NULLIF(TRIM(p.product_category_name), ''),
        'SEM_CATEGORIA'
    ) AS categoria,
    SUM(oi.price) AS valor_bruto_categoria,
    COUNT(*) AS total_itens,

    COUNT(DISTINCT o.order_id) AS total_pedidos,
    ROUND(
        100.0 * SUM(oi.price)
        / NULLIF(SUM(SUM(oi.price)) OVER (), 0),
        2
    ) AS percentual_valor_bruto
FROM olist_order_items_dataset oi
LEFT JOIN olist_products_dataset p
    ON oi.product_id = p.product_id
LEFT JOIN olist_orders_dataset o
    ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY
    COALESCE(
        NULLIF(TRIM(p.product_category_name), ''),
        'SEM_CATEGORIA'
    )
ORDER BY
    valor_bruto_categoria DESC,
    total_pedidos DESC
LIMIT 5;

/*
Interpretação:

Esta consulta identifica as cinco categorias com maior valor bruto
de itens entre pedidos com status 'delivered'.

O universo foi restrito aos pedidos entregues porque, conforme
validado na análise de status, essa população concentra 97,28%
do valor bruto dos itens, totalizando R$ 13.221.498,11.

Os demais status não são considerados erros automaticamente.
Eles foram excluídos desta análise pela definição adotada de
universo analítico, que busca representar pedidos concluídos.

Após o GROUP BY, o grain do resultado passa a ser uma linha por
categoria normalizada, considerando apenas pedidos entregues.

valor_bruto_categoria representa a soma de price dos itens
associados à categoria.

total_itens representa a quantidade de linhas de order_items
associadas à categoria.

total_pedidos representa a quantidade de pedidos distintos que
possuem ao menos um item daquela categoria.

Um mesmo pedido pode ser contado em mais de uma categoria caso
contenha itens de categorias diferentes. Isso é coerente com o
grain da análise por categoria, mas significa que a soma de
total_pedidos entre categorias não deve ser interpretada como
quantidade total de pedidos únicos.

percentual_valor_bruto representa a participação da categoria no
valor bruto total dos itens pertencentes a pedidos entregues.

A consulta não mede lucro, margem, rentabilidade ou receita líquida.
*/



