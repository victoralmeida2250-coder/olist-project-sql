-- =========================================================
-- 1. IMPACTO DO STATUS NO VALOR BRUTO DOS ITENS
-- Objetivo:
-- Normalizar os status dos pedidos e avaliar a participação
-- de cada status no valor bruto dos itens.
--
-- Grain do resultado:
-- Uma linha por status normalizado.
-- =========================================================

SELECT
    COALESCE(
        NULLIF(TRIM(LOWER(o.order_status)), ''),
        'sem_status'
    ) AS status,
    COUNT(*) AS total_itens,
    COUNT(DISTINCT o.order_id) AS total_pedidos,
    SUM(oi.price) AS valor_bruto_status,
    SUM(SUM(oi.price)) OVER () AS valor_bruto_total,
    ROUND(
        100.0 * SUM(oi.price)
        / NULLIF(SUM(SUM(oi.price)) OVER (), 0),
        2
    ) AS percentual_valor_bruto,
    ROUND(
        100.0 * COUNT(DISTINCT oi.order_id)
        / NULLIF(
            SUM(COUNT(DISTINCT oi.order_id)) OVER (),
            0), 2) AS percentual_pedidos
FROM olist_order_items_dataset oi
LEFT JOIN olist_orders_dataset o
    ON oi.order_id = o.order_id
GROUP BY
    COALESCE(
        NULLIF(TRIM(LOWER(o.order_status)), ''),
        'sem_status'
    )
ORDER BY valor_bruto_status DESC;

/*
Interpretação:

O grain do resultado é uma linha por status normalizado de pedido.

total_itens representa a quantidade de linhas de order_items
associadas a pedidos daquele status.

total_pedidos representa a quantidade de pedidos distintos
associados ao status.

valor_bruto_status representa a soma de price dos itens
associados aos pedidos daquele status.

percentual_valor_bruto representa a participação de cada status
no valor bruto total dos itens.

Pedidos com status 'delivered' concentram 97,28% do valor bruto
dos itens, totalizando R$ 13.221.498,11.

percentual_pedidos representa a participação de cada status entre os pedidos distintos que possuem, 
pelo menos, um item na população analisada.

Com base nessa distribuição, as análises principais que buscam
representar pedidos concluídos utilizarão status = 'delivered'
como definição do universo analítico.

Os demais status não são considerados erros automaticamente.
Eles representam estados diferentes do ciclo do pedido e foram
excluídos das análises principais pela regra analítica adotada.

Importante:
97,28% representa participação no valor bruto, e não participação
na quantidade de itens ou de pedidos.
*/