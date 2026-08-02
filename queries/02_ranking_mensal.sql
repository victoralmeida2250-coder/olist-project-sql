-- =========================================================
-- 1. VALOR BRUTO MENSAL DOS PEDIDOS ENTREGUES
-- Objetivo:
-- Avaliar o valor bruto mensal dos pedidos entregues, bem como seu crescimento MoM (Month-over-Month).
-- Grain do resultado:
-- Uma linha por combinação de mês e status.
-- =========================================================

WITH limites AS (
    SELECT
        MIN(order_purchase_timestamp)::DATE AS data_min,
        MAX(order_purchase_timestamp)::DATE AS data_max
    FROM olist_orders_dataset
),
calendario_mensal AS (
    SELECT
        GENERATE_SERIES(
            DATE_TRUNC('month', data_min) + INTERVAL '1 month',
            DATE_TRUNC('month', data_max) - INTERVAL '1 month',
            INTERVAL '1 month'
        )::DATE AS mes
    FROM limites
),
agrupar_mes AS (
    SELECT
        DATE_TRUNC(
            'month',
            o.order_purchase_timestamp
        )::DATE AS mes,
        SUM(oi.price) AS valor_bruto_mensal
    FROM olist_orders_dataset o
    INNER JOIN olist_order_items_dataset oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY
        DATE_TRUNC(
            'month',
            o.order_purchase_timestamp
        )::DATE
),
serie_completa AS (
    SELECT
        cm.mes,
        am.valor_bruto_mensal
    FROM calendario_mensal cm
    LEFT JOIN agrupar_mes am
        ON cm.mes = am.mes
),
comparacao_mensal AS (
    SELECT
        mes,
        valor_bruto_mensal,
        LAG(valor_bruto_mensal) OVER (
            ORDER BY mes
        ) AS valor_bruto_mes_anterior
    FROM serie_completa
)
SELECT
    mes,
    valor_bruto_mensal,
    valor_bruto_mes_anterior,
    ROUND(
        100.0 * (
            valor_bruto_mensal
            / NULLIF(valor_bruto_mes_anterior, 0)
            - 1
        ),
        2
    ) AS crescimento_mom_percentual,
    valor_bruto_mensal - valor_bruto_mes_anterior as variacao_absoluta
FROM comparacao_mensal
ORDER BY mes;

-- =========================================================
-- 1.1 VERIFICAÇÃO DE LACUNAS NO CALENDÁRIO MENSAL
-- Objetivo:
-- Novembro de 2016 e setembro de 2018 não possuem valor bruto observado no universo analítico de pedidos entregues.
-- Motivo atestado na query abaixo: não há pedidos entregues registrados nesses meses. Novembro de 2016 não possui pedidos registrados na fonte.
-- Setembro de 2018 possui 15 pedidos registrados, sendo 14 canceled e 1 shipped, mas nenhum delivered.
-- Grain do resultado:
-- Uma linha por mês.
-- =========================================================
-- Use junto com nossas cte.

SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp)::DATE AS mes,
    o.order_status AS status,
    COUNT(DISTINCT o.order_id) AS total_pedidos,
    COUNT(oi.order_id) AS total_itens,
    SUM(oi.price) AS valor_bruto
FROM olist_orders_dataset o
LEFT JOIN olist_order_items_dataset oi
    ON o.order_id = oi.order_id
WHERE DATE_TRUNC('month', o.order_purchase_timestamp)::DATE IN (
    DATE '2016-11-01',
    DATE '2018-09-01'
)
GROUP BY
    DATE_TRUNC('month', o.order_purchase_timestamp)::DATE,
    o.order_status
ORDER BY
    mes,
    status;

/*
Interpretação:

A série mensal utiliza como universo analítico apenas pedidos
com status 'delivered'.

O calendário mensal preservou meses sem observações, impedindo
que LAG comparasse períodos não consecutivos.

Novembro de 2016 não possui pedidos registrados na fonte.
Não é possível determinar apenas com esses dados se isso
representa ausência real de atividade ou lacuna de registro.

Setembro de 2018 possui 15 pedidos registrados, sendo
14 canceled e 1 shipped, mas nenhum delivered.

Por isso, setembro não apresenta valor bruto mensal dentro do
universo analítico adotado. Esses pedidos não foram removidos
da base; apenas não contribuem para a métrica de pedidos entregues.

Os valores NULL foram preservados para não transformar ausência
ou falta de comparabilidade em valor zero automaticamente.

Consequentemente:
- o primeiro mês não possui comparação anterior;
- meses sem valor bruto possuem MoM NULL;
- o mês seguinte a uma lacuna também possui MoM NULL;
- afirmações de crescimento não devem utilizar meses sem
  observação comparável.

Limitação:
A exclusão do primeiro e do último mês foi adotada após verificar
que as datas mínima e máxima da fonte pertencem a meses-calendário
parciais.

Essa regra é específica para a cobertura observada neste dataset
e não deve ser aplicada automaticamente a outras fontes.

COLUNAS: 
mes:
Mês-calendário representado pelo primeiro dia do mês.

valor_bruto_mensal:
Soma de price dos itens pertencentes a pedidos entregues no mês.

valor_bruto_mes_anterior:
Valor bruto do mês-calendário imediatamente anterior na série.

variacao_absoluta:
Diferença monetária entre o mês atual e o mês anterior.

crescimento_mom_percentual:
Variação percentual do valor bruto em relação ao mês anterior.

A métrica permanece NULL quando não existe uma comparação
mensal válida.

*/