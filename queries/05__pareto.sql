-- =========================================================
-- 1. TOP 80% PRODUTOS POR VALOR BRUTO
-- Objetivo:
-- Identificar os produtos que, juntos, representam 80% do
-- valor bruto dos itens, considerando pedidos entregues.
--
-- Grain final:
-- Uma linha por produto.   
-- =========================================================

WITH produtos_agregados AS (
    SELECT
        COALESCE(
            NULLIF(TRIM(p.product_category_name), ''),
            'SEM_CATEGORIA'
        ) AS categoria,
        p.product_id,
        SUM(oi.price) AS valor_bruto_produto,
        COUNT(*) AS total_itens_produto,
        COUNT(DISTINCT oi.order_id) AS total_pedidos_produto
    FROM olist_order_items_dataset AS oi
    INNER JOIN olist_orders_dataset AS o
        ON oi.order_id = o.order_id
    INNER JOIN olist_products_dataset AS p
        ON oi.product_id = p.product_id
    WHERE o.order_status = 'delivered'
    GROUP BY
        COALESCE(
            NULLIF(TRIM(p.product_category_name), ''),
            'SEM_CATEGORIA'
        ),
        p.product_id
),
total_geral AS (
    SELECT
        SUM(valor_bruto_produto) AS valor_bruto_geral
    FROM produtos_agregados
),
produtos_com_percentual AS (
    SELECT
        pa.categoria,
        pa.product_id,
        pa.valor_bruto_produto,
        pa.total_itens_produto,
        pa.total_pedidos_produto,
        tg.valor_bruto_geral,
        ROUND(
            100.0 * pa.valor_bruto_produto
            / NULLIF(tg.valor_bruto_geral, 0),
            4
        ) AS percentual_individual
    FROM produtos_agregados AS pa
    CROSS JOIN total_geral AS tg
),
produtos_ordenados AS (
    SELECT
        categoria,
        product_id,
        valor_bruto_produto,
        total_itens_produto,
        total_pedidos_produto,
        valor_bruto_geral,
        percentual_individual,
        ROW_NUMBER() OVER (
            ORDER BY valor_bruto_produto DESC, product_id
        ) AS ordem_produto,
        SUM(valor_bruto_produto) OVER (
            ORDER BY valor_bruto_produto DESC, product_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS valor_bruto_acumulado
    FROM produtos_com_percentual
),
pareto AS (
    SELECT
        categoria,
        product_id,
        valor_bruto_produto,
        total_itens_produto,
        total_pedidos_produto,
        valor_bruto_geral,
        percentual_individual,
        ordem_produto,
        valor_bruto_acumulado,
        100.0 * valor_bruto_acumulado
        / NULLIF(valor_bruto_geral, 0)
            AS percentual_acumulado,
        CASE
		    WHEN valor_bruto_acumulado - valor_bruto_produto
		         < 0.80 * valor_bruto_geral
		    THEN 'FAIXA_80'
		    ELSE 'FORA_FAIXA_80'
		END AS faixa_pareto
    FROM produtos_ordenados
)
SELECT
    categoria,
    product_id,
    valor_bruto_produto,
    total_itens_produto,
    total_pedidos_produto,
    valor_bruto_geral,
    percentual_individual,
    ordem_produto,
    valor_bruto_acumulado,
    ROUND(percentual_acumulado, 4) AS percentual_acumulado,
    faixa_pareto
FROM pareto
WHERE faixa_pareto = 'FAIXA_80'
ORDER BY ordem_produto;

-- =========================================================
-- 1.1. RESUMO DA FAIXA DE PARETO
-- Executar separadamente.
-- =========================================================
-- Objetivo:
-- Resumir a quantidade de produtos que, juntos, representam 80%
-- do valor bruto dos itens, considerando pedidos entregues. 
-- Para ver o detalhamento, consulte a consulta anterior.
-- 
-- Grain final:
-- Uma linha com os totais e percentuais.
-- =========================================================

WITH produtos_agregados AS (
    SELECT
        COALESCE(
            NULLIF(TRIM(p.product_category_name), ''),
            'SEM_CATEGORIA'
        ) AS categoria,
        p.product_id,
        SUM(oi.price) AS valor_bruto_produto,
        COUNT(*) AS total_itens_produto,
        COUNT(DISTINCT oi.order_id) AS total_pedidos_produto
    FROM olist_order_items_dataset AS oi
    INNER JOIN olist_orders_dataset AS o
        ON oi.order_id = o.order_id
    INNER JOIN olist_products_dataset AS p
        ON oi.product_id = p.product_id
    WHERE o.order_status = 'delivered'
    GROUP BY
        COALESCE(
            NULLIF(TRIM(p.product_category_name), ''),
            'SEM_CATEGORIA'
        ),
        p.product_id
),
total_geral AS (
    SELECT
        SUM(valor_bruto_produto) AS valor_bruto_geral
    FROM produtos_agregados
),
produtos_com_percentual AS (
    SELECT
        pa.categoria,
        pa.product_id,
        pa.valor_bruto_produto,
        pa.total_itens_produto,
        pa.total_pedidos_produto,
        tg.valor_bruto_geral,
        ROUND(
            100.0 * pa.valor_bruto_produto
            / NULLIF(tg.valor_bruto_geral, 0),
            4
        ) AS percentual_individual
    FROM produtos_agregados AS pa
    CROSS JOIN total_geral AS tg
),
produtos_ordenados AS (
    SELECT
        categoria,
        product_id,
        valor_bruto_produto,
        total_itens_produto,
        total_pedidos_produto,
        valor_bruto_geral,
        percentual_individual,
        ROW_NUMBER() OVER (
            ORDER BY valor_bruto_produto DESC, product_id
        ) AS ordem_produto,
        SUM(valor_bruto_produto) OVER (
            ORDER BY valor_bruto_produto DESC, product_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS valor_bruto_acumulado
    FROM produtos_com_percentual
),
pareto AS (
    SELECT
        categoria,
        product_id,
        valor_bruto_produto,
        total_itens_produto,
        total_pedidos_produto,
        valor_bruto_geral,
        percentual_individual,
        ordem_produto,
        valor_bruto_acumulado,
        100.0 * valor_bruto_acumulado
        / NULLIF(valor_bruto_geral, 0)
            AS percentual_acumulado,
        CASE
		    WHEN valor_bruto_acumulado - valor_bruto_produto
		         < 0.80 * valor_bruto_geral
		    THEN 'FAIXA_80'
		    ELSE 'FORA_FAIXA_80'
		END AS faixa_pareto
    FROM produtos_ordenados
)
SELECT
    COUNT(*) AS total_produtos,
    COUNT(*) FILTER (
        WHERE faixa_pareto = 'FAIXA_80'
    ) AS produtos_faixa_80,
    ROUND(
        100.0
        * COUNT(*) FILTER (
            WHERE faixa_pareto = 'FAIXA_80'
        )
        / NULLIF(COUNT(*), 0),
        2
    ) AS percentual_produtos_faixa_80,
    MAX(percentual_acumulado) FILTER (
        WHERE faixa_pareto = 'FAIXA_80'
    ) AS percentual_valor_atingido
FROM pareto;

-- =========================================================
-- Interpretação:
-- A consulta ordena os produtos pelo valor bruto dos itens
-- pertencentes a pedidos entregues e calcula sua participação
-- individual e acumulada no valor bruto geral.
-- =========================================================
/*
Resultado:

Entre os 32.216 produtos distintos presentes em pedidos
entregues, 8.352 são necessários para atingir 80,0019%
do valor bruto dos itens.

Isso corresponde a 25,93% dos produtos pertencentes ao
universo analítico de pedidos com status 'delivered'.

Produtos sem categoria válida foram mantidos e agrupados
como SEM_CATEGORIA.

O total de 32.216 não representa todos os 32.951 produtos
cadastrados em products, pois produtos sem participação em
pedidos entregues não entram nessa análise.
*/

/*
Interpretação Final:

A consulta ordena os produtos pelo valor bruto dos itens
pertencentes a pedidos entregues e calcula sua participação
individual e acumulada no valor bruto geral.

Uma linha representa um produto, identificado por product_id,
associado à sua categoria normalizada.

valor_bruto_produto representa a soma de price dos itens
associados ao produto.

percentual_individual representa a participação do produto no
valor bruto total dos itens entregues.

valor_bruto_acumulado e percentual_acumulado representam a soma
progressiva dos produtos, ordenados do maior para o menor valor
bruto.

A classificação FAIXA_80 inclui todos os produtos necessários
para atingir ou ultrapassar 80% do valor bruto total, inclusive
o produto de fronteira.

A análise indica que aproximadamente 26% dos produtos são
necessários para concentrar cerca de 80% do valor bruto dos itens
entregues. Portanto, os dados não apresentam uma divisão exata
de 80% do valor em 20% dos produtos.

Esse conjunto pode apoiar a priorização de análises, monitoramento
e testes comerciais. Entretanto, a consulta não mede margem,
lucro, disponibilidade de estoque ou resposta a campanhas.

Limitação de fronteira:
Quando produtos possuem o mesmo valor bruto na região do corte,
product_id é utilizado como critério determinístico de desempate.
Assim, produtos empatados podem ficar em lados diferentes da
fronteira de 80%.

A fonte não disponibiliza nomes comerciais dos produtos, que são
apresentados por product_id.
*/