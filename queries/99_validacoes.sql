/*
Arquivo:
99_validacoes.sql

Objetivo:
Validar contagens, totais, cardinalidade e integridade das
relações utilizadas nas análises do projeto.

Princípio:
Uma query analítica não é considerada confiável apenas porque
executa sem erro.

Antes de utilizar métricas derivadas de JOINs, devem ser
comparados os volumes e totais antes e depois dos relacionamentos.

Principais riscos:
- multiplicação de linhas por cardinalidade incorreta;
- perda de linhas por INNER JOIN;
- alteração do universo analisado por filtros;
- categorias ausentes;
- inclusão ou exclusão indevida de determinados status;
- divergência entre o grain esperado e o grain produzido.
*/

-- =========================================================
-- 1. BASELINE DE ORDER_ITEMS
-- Objetivo:
-- Criar valores de referência antes dos JOINs.
-- =========================================================

SELECT
    COUNT(*) AS total_de_linhas,
    COUNT(DISTINCT order_id) AS total_order_id_distinto,
    SUM(price) AS total_price
from olist_order_items_dataset;

/*
Resultado:
total_de_linhas: 112.650
total_order_id_distinto: 98.666
total_price: 13.591.643,70

Interpretação:
O total de linhas é maior que o total de order_id distintos, indicando que há múltiplos itens por pedido.
Isso está de acordo com o esperado, pois seu grain é uma linha por item de pedido.
A soma de price deve permanecer igual em JOINs que preservem a mesma população e não multipliquem as linhas de order_items.
Logo, o total_price é um valor de referência para validar a integridade dos relacionamentos.
*/

-- =========================================================
-- 1.1 verificando quantos preços nulos existem
-- Objetivo:
-- Verificar se existem preços nulos na tabela order_items, pois isso pode afetar a integridade dos cálculos de total_price.
-- =========================================================

SELECT
    SUM(
        CASE WHEN price IS NULL 
            THEN 1 
            ELSE 0 
        END) AS total_precos_nulos
from olist_order_items_dataset;

/*
Resultado:
total_precos_nulos: 0
Interpretação:
Não existem preços nulos na tabela order_items, o que é um bom sinal para a integridade dos cálculos de total_price.
Entretanto, é importante manter essa verificação em mente para futuras análises, caso novos dados sejam adicionados à tabela. 
Bem como, em caso de alterações no modelo de dados que possam introduzir valores nulos.

Riscos:
- SUM(price) ignora valores NULL; por isso a ausência de preços
  deve ser validada antes de usar a soma como controle.

- O total_price funciona como baseline do grain de order_items.
  JOINs que deveriam apenas enriquecer os itens não devem alterar
  esse valor.

- Se um JOIN multiplicar linhas, SUM(price) poderá ser inflado.

- Se um JOIN ou filtro eliminar itens, SUM(price) poderá diminuir.

- total_price representa a soma do preço dos itens nos dados
  observados. Não deve ser interpretado automaticamente como
  lucro, margem, receita líquida ou LTV.

- Orders possui 99.441 pedidos, enquanto order_items contém
  98.666 order_id distintos. A diferença de 775 corresponde aos
  pedidos sem itens já identificados na exploração.
*/

-- =========================================================
-- 2. VALIDAÇÃO DO JOIN ORDER_ITEMS → PRODUCTS
-- Objetivo:
-- Validar se o JOIN com a tabela de produtos mantém a integridade do total_price.
-- =========================================================
-- Antes do join, o total_price é 13.591.643,70
-- E a população de order_items é de 112.650 linhas.
-- Depois do join, o total_price deve permanecer igual ao baseline de order_items, bem como a população de order_items deve permanecer igual, caso contrário, há perda ou multiplicação de linhas.

SELECT
    COUNT(*) AS total_de_linhas,
    SUM(oi.price) AS total_price
from olist_order_items_dataset oi
left JOIN olist_products_dataset p
    ON oi.product_id = p.product_id;

/*
Resultado:
total_de_linhas: 112.650
total_price: 13.591.643,70

Interpretação:
A contagem de linhas e a soma de price permaneceram iguais
ao baseline após o LEFT JOIN com products.

Como product_id é único em products, cada item encontra no
máximo uma linha correspondente, evitando multiplicação.

A validação anterior de integridade também mostrou que todos
os product_id presentes em order_items possuem correspondência
em products.

Combinadas, essas evidências indicam que o relacionamento
order_items -> products é compatível com cardinalidade N:1
e pode ser usado para enriquecer os itens sem alterar o
baseline de linhas ou de price.

Risco ainda existente:
A correspondência com products não garante categoria válida;
610 produtos possuem categoria ausente.
*/

-- =========================================================
-- 3. VALIDAÇÃO DO RELACIONAMENTO ORDER_ITEMS ↔ ORDERS
-- Objetivo:
-- Validar o comportamento do relacionamento entre order_items
-- e orders nas duas direções, observando:
-- - preservação de linhas;
-- - preservação de SUM(price);
-- - mudança de grain;
-- - perda de pedidos em INNER JOIN.
--
-- Baseline de order_items:
-- linhas: 112.650
-- pedidos distintos: 98.666
-- SUM(price): 13.591.643,70
--
-- Baseline de orders:
-- pedidos: 99.441
-- =========================================================


-- =========================================================
-- 3.1 ORDER_ITEMS → ORDERS COM LEFT JOIN
-- Objetivo:
-- Verificar se orders pode enriquecer order_items sem
-- multiplicar linhas ou alterar SUM(price).
--
-- Cardinalidade esperada:
-- order_items → orders = N:1
-- =========================================================

SELECT
    COUNT(*) AS total_linhas,
    SUM(oi.price) AS total_price
FROM olist_order_items_dataset oi
LEFT JOIN olist_orders_dataset o
    ON oi.order_id = o.order_id;

/*
Resultado:
total_linhas: 112.650
total_price: 13.591.643,70

Interpretação:
O LEFT JOIN preservou integralmente o baseline de order_items.

Como order_id é único em orders, cada item encontra no máximo
um pedido correspondente, evitando multiplicação de linhas.

Além disso, já foi validado que não existem order_id órfãos
em order_items.
*/


-- =========================================================
-- 3.2 ORDER_ITEMS → ORDERS COM INNER JOIN
-- Objetivo:
-- Confirmar que o INNER JOIN também preserva todos os itens,
-- já que não existem order_id órfãos em order_items.
-- =========================================================

SELECT
    COUNT(*) AS total_linhas,
    SUM(oi.price) AS total_price
FROM olist_order_items_dataset oi
INNER JOIN olist_orders_dataset o
    ON oi.order_id = o.order_id;

/*
Resultado:
total_linhas: 112.650
total_price: 13.591.643,70

Interpretação:
LEFT JOIN e INNER JOIN produziram o mesmo volume e o mesmo
total_price no sentido order_items → orders.

Isso ocorre porque todos os itens possuem pedido correspondente.

Conclusão:
orders pode ser utilizada para enriquecer order_items sem alterar
o grain de uma linha por item nos dados observados.
*/


-- =========================================================
-- 3.3 ORDERS → ORDER_ITEMS COM LEFT JOIN
-- Objetivo:
-- Observar a mudança de grain ao partir de pedidos e adicionar
-- os itens de cada pedido.
--
-- Cardinalidade esperada:
-- orders → order_items = 1:N
-- =========================================================

SELECT
    COUNT(*) AS total_linhas_join,
    COUNT(DISTINCT o.order_id) AS pedidos_representados,
    SUM(oi.price) AS total_price
FROM olist_orders_dataset o
LEFT JOIN olist_order_items_dataset oi
    ON o.order_id = oi.order_id;

/*
Resultado:
total_linhas_join: 113.425
pedidos_representados: 99.441
total_price: 13.591.643,70

Interpretação:
Todos os pedidos foram preservados pelo LEFT JOIN.

Pedidos com múltiplos itens passaram a ocupar múltiplas linhas,
pois o relacionamento é 1:N.

Além das 112.650 linhas relacionadas a itens, permanecem
775 pedidos sem item correspondente:

112.650 + 775 = 113.425

Esses 775 pedidos possuem oi.price NULL e, por isso,
não aumentam SUM(oi.price).

Importante:
O resultado não possui mais grain de uma linha por pedido.
*/


-- =========================================================
-- 3.4 ORDERS → ORDER_ITEMS COM INNER JOIN
-- Objetivo:
-- Verificar quantos pedidos permanecem representados quando
-- exigimos a existência de pelo menos um item.
-- =========================================================

SELECT
    COUNT(*) AS total_linhas_join,
    COUNT(DISTINCT o.order_id) AS pedidos_representados,
    SUM(oi.price) AS total_price
FROM olist_orders_dataset o
INNER JOIN olist_order_items_dataset oi
    ON o.order_id = oi.order_id;

/*
Resultado:
total_linhas_join: 112.650
pedidos_representados: 98.666
total_price: 13.591.643,70

Comparação:
pedidos em orders:                  99.441
pedidos representados após JOIN:    98.666
pedidos excluídos:                     775

Interpretação:
O INNER JOIN excluiu os 775 pedidos que não possuem itens.

Ao mesmo tempo, o resultado possui mais linhas que a tabela
orders original porque pedidos com múltiplos itens aparecem
em múltiplas linhas.

Isso demonstra que aumento de COUNT(*) após um JOIN não prova
que todas as entidades da tabela original foram preservadas.

Para validar a população original, também é necessário acompanhar
COUNT(DISTINCT chave_do_grain).
*/


