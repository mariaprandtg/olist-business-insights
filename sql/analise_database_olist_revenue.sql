-- ANÁLISES DE VOLUMES --

-- ANÁLISE 1: Meses com maior e menor volume de pedidos
SELECT 
	MONTH(ORDER_PURCHASE_DATE) AS MES,
    COUNT(DISTINCT ORDER_ID) AS VOLUME_PEDIDOS
FROM OLIST.ORDERS
GROUP BY MONTH(ORDER_PURCHASE_DATE)
ORDER BY VOLUME_PEDIDOS ASC;

-- ANÁLISE 2: Volume de pedidos por categoria e por mês
SELECT 
	YEAR(A.ORDER_PURCHASE_DATE) AS ANO,
	MONTH(A.ORDER_PURCHASE_DATE) AS MES,
    C.product_category_name AS CATEGORIA_PRODUTO,
    COUNT(DISTINCT A.ORDER_ID) AS VOLUME_PEDIDOS
FROM OLIST.ORDERS A
INNER JOIN OLIST.ITEMS B ON A.ORDER_ID = B.ORDER_ID
INNER JOIN OLIST.PRODUCTS C ON B.PRODUCT_ID = C.PRODUCT_ID
GROUP BY A.ORDER_PURCHASE_DATE, YEAR(A.ORDER_PURCHASE_DATE), MONTH(A.ORDER_PURCHASE_DATE),DAY(A.ORDER_PURCHASE_DATE), c.product_category_name
ORDER BY VOLUME_PEDIDOS DESC;

-- ANÁLISES DE TICKET MÉDIO --

-- ANÁLISE 1: Ticket Médio Por Pedido
SELECT 
    A.ORDER_ID, 
    AVG(B.PRICE) AS TICKET_MEDIO
FROM OLIST.ORDERS A                                                                                               
INNER JOIN OLIST.ITEMS B ON A.ORDER_ID = B.ORDER_ID
GROUP BY A.ORDER_PURCHASE_DATE, A.ORDER_ID
ORDER BY TICKET_MEDIO DESC
;

-- ANÁLISE 2: Ticket Médio Por Categoria de Produto
SELECT 
    C.PRODUCT_CATEGORY_NAME AS CATEGORIA_PRODUTO, 
    AVG(B.PRICE) AS TICKET_MEDIO
FROM OLIST.ORDERS A
INNER JOIN OLIST.ITEMS B ON A.ORDER_ID = B.ORDER_ID
INNER JOIN OLIST.PRODUCTS C ON B.PRODUCT_ID = C.PRODUCT_ID
GROUP BY C.PRODUCT_CATEGORY_NAME
ORDER BY TICKET_MEDIO DESC
;

-- ANÁLISE 3: Média de Itens por pedido
SELECT 
	YEAR(B.order_purchase_date) AS ANO,
    MONTH(B.order_purchase_date) AS MES,
	ROUND(COUNT(A.ORDER_ITEM_ID) / COUNT(DISTINCT A.ORDER_ID),2) AS MEDIA_ITENS_PEDIDO
FROM OLIST.ITEMS A
LEFT JOIN OLIST.ORDERS B ON A.ORDER_ID = B.ORDER_ID 
GROUP BY YEAR(B.order_purchase_date), MONTH(B.order_purchase_date)
ORDER BY ANO ASC, MES ASC
;

-- ANÁLISES DE RECEITA --

-- ANÁLISE 1: Receita total por tempo
SELECT
	YEAR(B.ORDER_PURCHASE_DATE) AS ANO,
    MONTH(B.ORDER_PURCHASE_DATE) AS MES,
	SUM(A.PAYMENT_VALUE) AS RECEITA
FROM OLIST.PAYMENTS A
LEFT JOIN OLIST.ORDERS B ON A.ORDER_ID = B.ORDER_ID
WHERE B.ORDER_STATUS NOT IN ('canceled', 'unavailable')
GROUP BY YEAR(B.ORDER_PURCHASE_DATE), MONTH(B.ORDER_PURCHASE_DATE)
;


-- ANÁLISE 2: Receita total por tempo e categoria de produto

-- Considerando que um pedido pode ter mais de um produto de categorias diferentes e que a tabela de payments tem apenas o total 
-- pago por pedido, foi aplicado uma proporção a fim de não gerar duplicidades na análise da receita total

WITH PROPORCAO AS (
	SELECT
		YEAR(B.ORDER_PURCHASE_DATE) AS ANO,
		MONTH(B.ORDER_PURCHASE_DATE) AS MES,
        A.ORDER_ID,
        D.PRODUCT_CATEGORY_NAME,
		(A.PRICE + A.FREIGHT_VALUE)/ SUM(A.PRICE + A.FREIGHT_VALUE) OVER(PARTITION BY A.ORDER_ID) AS PROPORCAO
	FROM OLIST.ITEMS A
	LEFT JOIN OLIST.ORDERS B ON A.ORDER_ID = B.ORDER_ID
	LEFT JOIN OLIST.PRODUCTS D ON A.PRODUCT_ID = D.PRODUCT_ID
	WHERE B.ORDER_STATUS NOT IN ('canceled', 'unavailable')
	GROUP BY YEAR(B.ORDER_PURCHASE_DATE), MONTH(B.ORDER_PURCHASE_DATE), A.PRICE, A.FREIGHT_VALUE,A.ORDER_ID, D.PRODUCT_CATEGORY_NAME
)

SELECT 
	A.PRODUCT_CATEGORY_NAME,
	SUM(PROPORCAO * B.PAYMENT_VALUE) AS RECEITA
FROM PROPORCAO A
LEFT JOIN OLIST.PAYMENTS B ON  A.ORDER_ID = B.ORDER_ID
GROUP BY PRODUCT_CATEGORY_NAME
ORDER BY RECEITA DESC