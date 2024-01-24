-- 각 테이블 살펴보기
USE olist_ecommerce;
SHOW tables;
SELECT * FROM olist_customers_dataset;
SELECT * FROM olist_geolocation_dataset;
SELECT * FROM olist_order_items_dataset;
SELECT * FROM olist_order_payments_dataset;
SELECT * FROM olist_order_reviews_dataset;
SELECT * FROM olist_orders_dataset;
SELECT * FROM olist_products_dataset;
SELECT * FROM olist_sellers_dataset;
SELECT * FROM product_category_name_translation;

-- 주문 상태 컬럼의 데이터 종류 파악
SELECT DISTINCT order_status
FROM olist_orders_dataset;

-- 지불 유형 파악
SELECT DISTINCT payment_type
FROM olist_order_payments_dataset;

-- customer_state별 카운트(내림차순)
SELECT customer_state, COUNT(*)
FROM olist_customers_dataset
GROUP BY customer_state
ORDER BY COUNT(*) DESC;

-- payment_installments별 평균 payment_value(내림차순)
SELECT payment_installments, ROUND(AVG(payment_value), 2) avg_payment
FROM olist_order_payments_dataset
GROUP BY payment_installments
ORDER BY avg_payment DESC;

-- 제품 카테고리별 평균 리뷰 상위 TOP5
-- 제품 카테고리 이름을 영어로 사용하기 위해 product_category_name_translation 테이블과 조인
SELECT 
	product_category_name_english, 
    ROUND(AVG(review_score), 2) avg_review_score
FROM olist_order_reviews_dataset R
JOIN olist_order_items_dataset O ON R.order_id = O.order_id
JOIN olist_products_dataset P ON O.product_id = P.product_id
JOIN product_category_name_translation T ON P.product_category_name = T.product_category_name
GROUP BY product_category_name_english
ORDER BY avg_review_score DESC LIMIT 5;

-- 제품 카테고리별 평균 리뷰 하위 TOP5
-- 제품 카테고리 이름을 영어로 사용하기 위해 product_category_name_translation 테이블과 조인
SELECT 
	product_category_name_english, 
    ROUND(AVG(review_score), 2) avg_review_score
FROM olist_order_reviews_dataset R
JOIN olist_order_items_dataset O ON R.order_id = O.order_id
JOIN olist_products_dataset P ON O.product_id = P.product_id
JOIN product_category_name_translation T 
ON P.product_category_name = T.product_category_name
GROUP BY product_category_name_english
ORDER BY avg_review_score LIMIT 5;

-- 배송일별 평균 리뷰점수 조회 
-- order_id로 조인 / 배송일(day_difference) 데이터 활용
SELECT 
	day_difference, 
    ROUND(AVG(review_score), 2) avg_review_score
FROM (
	SELECT 
		order_id,
		TIMESTAMPDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date) AS day_difference
	FROM olist_orders_dataset
) AS D
JOIN olist_order_reviews_dataset R ON D.order_id = R.order_id
GROUP BY D.day_difference
ORDER BY avg_review_score DESC;

-- customer_state(주), customer_city(도시)별 고객의 수
-- 추후 고객 지역별 리뷰점수 등과 같은 분석을 할 때, 고려해 볼 만한 사항이라고 생각했습니다..!
-- 고객의 수가 적은데, 리뷰가 너무 편향되어 있으면 유의미한 자료라고 생각하기 어려우므로!
SELECT customer_state, customer_city, COUNT(*)
FROM olist_customers_dataset
GROUP BY customer_state, customer_city
ORDER BY COUNT(*) DESC;

-- 총 배송 일수에 관한 총 배송 건수
SELECT 
	day_difference,
    COUNT(*) delivery_count
FROM olist_orders_dataset O
JOIN (
	SELECT 
		order_id,
		TIMESTAMPDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date) AS day_difference
	FROM olist_orders_dataset
) AS D ON O.order_id = D.order_id
GROUP BY day_difference
ORDER BY delivery_count DESC;

# 배송일수의 count를 이용한 가중평균 구하기( count* 배송일수/ 전체 배송일수들의 count합 )
# 12.09가 나옴!
SELECT 
    ROUND(SUM(count * day_difference) / SUM(count), 2 ) AS weighted_average_delivery_days
FROM (
    SELECT 
        TIMESTAMPDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date) AS day_difference,
        COUNT(*) AS count
    FROM olist_orders_dataset
    WHERE order_status = 'delivered'
    GROUP BY day_difference
    ORDER BY day_difference
) AS subquery;

-- 고객이 선호하는 카테고리 파악
-- 필요 테이블: customer, orders, order_items, products, product_category_name_translation 
SELECT 
	product_category_name_english,
    COUNT(customer_unique_id)
FROM olist_customers_dataset C
JOIN olist_orders_dataset OO ON C.customer_id = OO.customer_id
JOIN olist_order_items_dataset OI ON OO.order_id = OI.order_id
JOIN olist_products_dataset OP ON OI.product_id = OI.product_id
JOIN product_category_name_translation P ON OP.product_category_name = P.product_category_name
GROUP BY product_category_name_english
ORDER BY product_category_name_english DESC LIMIT 10;

-- 각 테이블의 결측치 파악
-- customers 테이블
SELECT 
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) customer_id_null,
    SUM(CASE WHEN customer_unique_id IS NULL THEN 1 ELSE 0 END) customer_unique_id_null,
    SUM(CASE WHEN customer_zip_code_prefix IS NULL THEN 1 ELSE 0 END) customer_zip_code_prefix_null,
    SUM(CASE WHEN customer_city IS NULL THEN 1 ELSE 0 END) customer_city_null,
    SUM(CASE WHEN customer_state IS NULL THEN 1 ELSE 0 END) customer_state_null
FROM olist_customers_dataset;

-- geolocation 테이블
SELECT 
    SUM(CASE WHEN geolocation_zip_code_prefix IS NULL THEN 1 ELSE 0 END) geolocation_zip_code_prefix_null,
    SUM(CASE WHEN geolocation_lat IS NULL THEN 1 ELSE 0 END) geolocation_lat_null,
    SUM(CASE WHEN geolocation_lng IS NULL THEN 1 ELSE 0 END) geolocation_lng_null,
    SUM(CASE WHEN geolocation_city IS NULL THEN 1 ELSE 0 END) geolocation_city_null,
    SUM(CASE WHEN geolocation_state IS NULL THEN 1 ELSE 0 END) geolocation_state_null
FROM olist_geolocation_dataset;

-- order_items 테이블
SELECT 
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) order_id_null,
    SUM(CASE WHEN order_item_id IS NULL THEN 1 ELSE 0 END) order_item_id_null,
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) product_id_null,
    SUM(CASE WHEN seller_id IS NULL THEN 1 ELSE 0 END) seller_id_null,
    SUM(CASE WHEN shipping_limit_date IS NULL THEN 1 ELSE 0 END) shipping_limit_date_null,
    SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) price_null,
    SUM(CASE WHEN freight_value IS NULL THEN 1 ELSE 0 END) freight_value_null    
FROM olist_order_items_dataset;

-- order_payments 테이블
SELECT 
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) order_id_null,
    SUM(CASE WHEN payment_sequential IS NULL THEN 1 ELSE 0 END) payment_sequential_null,
    SUM(CASE WHEN payment_type IS NULL THEN 1 ELSE 0 END) payment_type_null,
    SUM(CASE WHEN payment_installments IS NULL THEN 1 ELSE 0 END) payment_installments_null,
    SUM(CASE WHEN payment_value IS NULL THEN 1 ELSE 0 END) payment_value_null    
FROM olist_order_payments_dataset;

-- order_reviews 테이블
SELECT 
    SUM(CASE WHEN review_id IS NULL THEN 1 ELSE 0 END) review_id_null,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) order_id_null,
    SUM(CASE WHEN review_score IS NULL THEN 1 ELSE 0 END) review_score_null,
    SUM(CASE WHEN review_comment_title IS NULL THEN 1 ELSE 0 END) review_comment_title_null,
    SUM(CASE WHEN review_comment_message IS NULL THEN 1 ELSE 0 END) review_comment_message_null,
    SUM(CASE WHEN review_creation_date IS NULL THEN 1 ELSE 0 END) review_creation_date_null,
    SUM(CASE WHEN review_answer_timestamp IS NULL THEN 1 ELSE 0 END) review_answer_timestamp_null    
FROM olist_order_reviews_dataset;

-- orders 테이블
SELECT 
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) order_id_null,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) customer_id_null,
    SUM(CASE WHEN order_status IS NULL THEN 1 ELSE 0 END) order_status_null,
    SUM(CASE WHEN order_purchase_timestamp IS NULL THEN 1 ELSE 0 END) order_purchase_timestamp_null,
    SUM(CASE WHEN order_approved_at IS NULL THEN 1 ELSE 0 END) order_approved_at_null,
    SUM(CASE WHEN order_delivered_carrier_date IS NULL THEN 1 ELSE 0 END) order_delivered_carrier_date_null,
    SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) order_delivered_customer_date_null,
    SUM(CASE WHEN order_estimated_delivery_date IS NULL THEN 1 ELSE 0 END) order_estimated_delivery_date_null
FROM olist_orders_dataset;

-- products 테이블
SELECT 
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) product_id_null,
    SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END) product_category_name_null,
    SUM(CASE WHEN product_name_lenght IS NULL THEN 1 ELSE 0 END) product_name_lenght_null,
    SUM(CASE WHEN product_description_lenght IS NULL THEN 1 ELSE 0 END) product_description_lenght_null,
    SUM(CASE WHEN product_photos_qty IS NULL THEN 1 ELSE 0 END) product_photos_qty_null,
    SUM(CASE WHEN product_weight_g IS NULL THEN 1 ELSE 0 END) product_weight_g_null,
    SUM(CASE WHEN product_length_cm IS NULL THEN 1 ELSE 0 END) product_length_cm_null,
    SUM(CASE WHEN product_height_cm IS NULL THEN 1 ELSE 0 END) product_height_cm_null,
    SUM(CASE WHEN product_width_cm IS NULL THEN 1 ELSE 0 END) product_width_cm_null
FROM olist_products_dataset;

-- sellers 테이블
SELECT 
    SUM(CASE WHEN seller_id IS NULL THEN 1 ELSE 0 END) seller_id_null,
    SUM(CASE WHEN seller_zip_code_prefix IS NULL THEN 1 ELSE 0 END) seller_zip_code_prefix_null,
    SUM(CASE WHEN seller_city IS NULL THEN 1 ELSE 0 END) seller_city_null,
    SUM(CASE WHEN seller_state IS NULL THEN 1 ELSE 0 END) seller_state_null
FROM olist_sellers_dataset;

-- product_category_name_translation 테이블
SELECT 
    SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END) product_category_name_null,
    SUM(CASE WHEN product_category_name_english IS NULL THEN 1 ELSE 0 END) product_category_name_english_null
FROM product_category_name_translation;


SELECT *
FROM olist_orders_dataset
WHERE order_approved_at IS NULL;

SELECT *
FROM olist_orders_dataset
WHERE order_approved_at IS NULL
AND order_status = 'delivered';

SELECT *
FROM olist_orders_dataset
WHERE order_approved_at IS NULL
AND order_status = 'created';

SELECT order_status, COUNT(*)
FROM olist_orders_dataset
WHERE order_approved_at IS NULL
GROUP BY order_status;

SELECT order_status, COUNT(*)
FROM olist_orders_dataset
GROUP BY order_status;

-- 제품 카테고리 별 평균 제품 가격(내림차순)
SELECT product_category_name_english, AVG(price)
FROM olist_order_items_dataset OI
JOIN olist_products_dataset P ON OI.product_id = P.product_id
JOIN product_category_name_translation CN ON P.product_category_name = CN.product_category_name
GROUP BY product_category_name_english
ORDER BY AVG(price) DESC;

-- 카테고리별 매출액(내림차순)
SELECT
	P.product_category_name_english,
    ROUND(SUM(OPA.payment_value), 2) sales
FROM olist_products_dataset OPU
JOIN product_category_name_translation P ON OPU.product_category_name = P.product_category_name
JOIN olist_order_items_dataset OI ON OI.product_id =  OPU.product_id
JOIN olist_order_payments_dataset OPA ON OPA.order_id =  OI.order_id
GROUP BY P.product_category_name_english
ORDER BY sales DESC;


-- payment_installments별 평균 price
SELECT 
	CAST(payment_installments AS SIGNED) AS payment_installments, 
	ROUND(AVG(OI.price), 2) avg_price
FROM olist_order_payments_dataset OP
JOIN olist_order_items_dataset OI ON OI.order_id = OP.order_id
GROUP BY OP.payment_installments
ORDER BY payment_installments;

SELECT COUNT(*)
FROM olist_products_dataset OP
JOIN product_category_name_translation P ON OP.product_category_name = P.product_category_name
WHERE product_category_name_english = 'security_and_services';

SELECT *
FROM olist_products_dataset
WHERE product_weight_g IS NULL;

-- 요일별 매출
SELECT
	date_format(order_purchase_timestamp, '%w') day_order,
    date_format(order_purchase_timestamp, '%W') day_name,
    sum(payment_value) revenue
FROM olist_orders_dataset O
JOIN olist_order_payments_dataset OP ON O.order_id = OP.order_id
GROUP BY day_order, day_name
ORDER BY day_order;

-- 배송비(freight_value)에 따른 평균 리뷰 점수
SELECT 
	CAST(freight_value AS DECIMAL(10, 2)) AS freight_value, 
	AVG(review_score)
FROM olist_order_items_dataset I
JOIN olist_order_reviews_dataset R ON I.order_id = R.order_id
GROUP BY freight_value
HAVING freight_value >= 99.99
ORDER BY freight_value DESC;

-- 카테고리별 평균 배송일과 평균 추정 배송일
SELECT
    PC.product_category_name_english,
    AVG(TIMESTAMPDIFF(DAY, O.order_purchase_timestamp, O.order_delivered_customer_date)) AS avg_delivery_days,
    AVG(TIMESTAMPDIFF(DAY, O.order_purchase_timestamp, O.order_estimated_delivery_date)) AS avg_estimate_delivery_days
FROM olist_orders_dataset O
JOIN olist_order_items_dataset OI ON O.order_id = OI.order_id
JOIN olist_products_dataset P ON OI.product_id = P.product_id
JOIN product_category_name_translation PC ON PC.product_category_name = P.product_category_name
GROUP BY product_category_name_english
ORDER BY avg_delivery_days DESC;


-- 실제 배송일이 추정 배송일보다 높은 데이터만 조회
SELECT
    PC.product_category_name_english,
    TIMESTAMPDIFF(DAY, O.order_purchase_timestamp, O.order_delivered_customer_date) AS delivery_days,
    TIMESTAMPDIFF(DAY, O.order_purchase_timestamp, O.order_estimated_delivery_date) AS estimate_delivery_days
FROM olist_orders_dataset O
JOIN olist_order_items_dataset OI ON O.order_id = OI.order_id
JOIN olist_products_dataset P ON OI.product_id = P.product_id
JOIN product_category_name_translation PC ON PC.product_category_name = P.product_category_name
HAVING delivery_days > estimate_delivery_days
ORDER BY delivery_days DESC;

-- 실제 배송일이 추정 배송일보다 높은 데이터의 카테고리별 빈도수 파악
SELECT 
	product_category_name_english,
    COUNT(*) AS delivery_over_count
FROM (SELECT
    PC.product_category_name_english,
    TIMESTAMPDIFF(DAY, O.order_purchase_timestamp, O.order_delivered_customer_date) AS delivery_days,
    TIMESTAMPDIFF(DAY, O.order_purchase_timestamp, O.order_estimated_delivery_date) AS estimate_delivery_days
FROM olist_orders_dataset O
JOIN olist_order_items_dataset OI ON O.order_id = OI.order_id
JOIN olist_products_dataset P ON OI.product_id = P.product_id
JOIN product_category_name_translation PC ON PC.product_category_name = P.product_category_name
HAVING delivery_days > estimate_delivery_days
ORDER BY delivery_days DESC
) AS delivery_over
GROUP BY product_category_name_english
ORDER BY delivery_over_count DESC;

-- 실제 배송일이 추정 배송일보다 높은 데이터의 카테고리별 빈도수와 리뷰점수 
SELECT
	category_delivery_over_count.product_category_name_english,
    category_delivery_over_count.delivery_over_count,
    ROUND(AVG(R.review_score), 2) avg_review_score
FROM olist_order_reviews_dataset R
JOIN olist_order_items_dataset OI ON R.order_id = OI.order_id
JOIN olist_products_dataset P ON OI.product_id = P.product_id
JOIN product_category_name_translation T 
ON P.product_category_name = T.product_category_name
JOIN (
	SELECT 
		product_category_name_english,
		COUNT(*) AS delivery_over_count
	FROM (
		SELECT
		PC.product_category_name_english,
		TIMESTAMPDIFF(DAY, O.order_purchase_timestamp, 
						   O.order_delivered_customer_date) AS delivery_days,
		TIMESTAMPDIFF(DAY, O.order_purchase_timestamp, 
						   O.order_estimated_delivery_date) AS estimate_delivery_days
		FROM olist_orders_dataset O
		JOIN olist_order_items_dataset OI ON O.order_id = OI.order_id
		JOIN olist_products_dataset P ON OI.product_id = P.product_id
		JOIN product_category_name_translation PC ON PC.product_category_name = P.product_category_name
		HAVING delivery_days > estimate_delivery_days
		ORDER BY delivery_days DESC
		) AS delivery_over
	GROUP BY product_category_name_english
	ORDER BY delivery_over_count DESC
	) category_delivery_over_count 
ON T.product_category_name_english = category_delivery_over_count.product_category_name_english
GROUP BY category_delivery_over_count.product_category_name_english;

-- 실제 배송일이 추정 배송일보다 높은 데이터의 카테고리별 빈도수와 해당 카테고리의 빈도수, 리뷰점수 
SELECT
	category_delivery_over_count.product_category_name_english,
    category_delivery_over_count.delivery_over_count,
    COUNT(P.product_category_name) category_total_count,
    ROUND(AVG(R.review_score), 2) avg_review_score
FROM olist_order_reviews_dataset R
JOIN olist_order_items_dataset OI ON R.order_id = OI.order_id
JOIN olist_products_dataset P ON OI.product_id = P.product_id
JOIN product_category_name_translation T 
ON P.product_category_name = T.product_category_name
JOIN (
	SELECT 
		product_category_name_english,
		COUNT(*) AS delivery_over_count
	FROM (
		SELECT
		PC.product_category_name_english,
		TIMESTAMPDIFF(DAY, O.order_purchase_timestamp, 
						   O.order_delivered_customer_date) AS delivery_days,
		TIMESTAMPDIFF(DAY, O.order_purchase_timestamp, 
						   O.order_estimated_delivery_date) AS estimate_delivery_days
		FROM olist_orders_dataset O
		JOIN olist_order_items_dataset OI ON O.order_id = OI.order_id
		JOIN olist_products_dataset P ON OI.product_id = P.product_id
		JOIN product_category_name_translation PC ON PC.product_category_name = P.product_category_name
		HAVING delivery_days > estimate_delivery_days
		ORDER BY delivery_days DESC
		) AS delivery_over
	GROUP BY product_category_name_english
	ORDER BY delivery_over_count DESC
	) category_delivery_over_count 
ON T.product_category_name_english = category_delivery_over_count.product_category_name_english
GROUP BY category_delivery_over_count.product_category_name_english;

-- 실제 배송일이 추정 배송일보다 높은 데이터의 카테고리별 비율(해당 빈도/전체 빈도)과 리뷰점수 
SELECT
	product_category_name_english,
    ROUND((delivery_over_count / category_total_count) * 100, 2) AS delivery_over_rate,
    delivery_over_count,
    category_total_count,
    avg_review_score
FROM (
	SELECT
		category_delivery_over_count.product_category_name_english,
		category_delivery_over_count.delivery_over_count,
		COUNT(P.product_category_name) category_total_count,
		ROUND(AVG(R.review_score), 2) avg_review_score
	FROM olist_order_reviews_dataset R
	JOIN olist_order_items_dataset OI ON R.order_id = OI.order_id
	JOIN olist_products_dataset P ON OI.product_id = P.product_id
	JOIN product_category_name_translation T 
	ON P.product_category_name = T.product_category_name
	JOIN (
		SELECT 
			product_category_name_english,
			COUNT(*) AS delivery_over_count
		FROM (
			SELECT
			PC.product_category_name_english,
			TIMESTAMPDIFF(DAY, O.order_purchase_timestamp, 
							   O.order_delivered_customer_date) AS delivery_days,
			TIMESTAMPDIFF(DAY, O.order_purchase_timestamp, 
							   O.order_estimated_delivery_date) AS estimate_delivery_days
			FROM olist_orders_dataset O
			JOIN olist_order_items_dataset OI ON O.order_id = OI.order_id
			JOIN olist_products_dataset P ON OI.product_id = P.product_id
			JOIN product_category_name_translation PC ON PC.product_category_name = P.product_category_name
			HAVING delivery_days > estimate_delivery_days
			ORDER BY delivery_days DESC
			) AS delivery_over
		GROUP BY product_category_name_english
		ORDER BY delivery_over_count DESC
		) category_delivery_over_count 
	ON T.product_category_name_english = category_delivery_over_count.product_category_name_english
	GROUP BY category_delivery_over_count.product_category_name_english
) AS delivery_over_category
ORDER BY delivery_over_rate DESC;

-- 실제 배송일이 추정 배송일보다 높은 데이터만 조회
SELECT
    PC.product_category_name_english,
    TIMESTAMPDIFF(DAY, O.order_purchase_timestamp, O.order_delivered_customer_date) AS delivery_days,
    TIMESTAMPDIFF(DAY, O.order_purchase_timestamp, O.order_estimated_delivery_date) AS estimate_delivery_days
FROM olist_orders_dataset O
JOIN olist_order_items_dataset OI ON O.order_id = OI.order_id
JOIN olist_products_dataset P ON OI.product_id = P.product_id
JOIN product_category_name_translation PC ON PC.product_category_name = P.product_category_name
HAVING delivery_days > estimate_delivery_days
ORDER BY delivery_days DESC;

-- 실제 배송일이 추정 배송일보다 낮은 데이터만 조회
SELECT
    PC.product_category_name_english,
    TIMESTAMPDIFF(DAY, O.order_purchase_timestamp, O.order_delivered_customer_date) AS delivery_days,
    TIMESTAMPDIFF(DAY, O.order_purchase_timestamp, O.order_estimated_delivery_date) AS estimate_delivery_days
FROM olist_orders_dataset O
JOIN olist_order_items_dataset OI ON O.order_id = OI.order_id
JOIN olist_products_dataset P ON OI.product_id = P.product_id
JOIN product_category_name_translation PC ON PC.product_category_name = P.product_category_name
HAVING delivery_days < estimate_delivery_days
ORDER BY delivery_days DESC;

-- 실제 배송일이 추정 배송일보다 높은 데이터와 리뷰 점수
SELECT
    PC.product_category_name_english,
    TIMESTAMPDIFF(DAY, O.order_purchase_timestamp, O.order_delivered_customer_date) AS delivery_days,
    TIMESTAMPDIFF(DAY, O.order_purchase_timestamp, O.order_estimated_delivery_date) AS estimate_delivery_days,
    review_score
FROM olist_orders_dataset O
JOIN olist_order_items_dataset OI ON O.order_id = OI.order_id
JOIN olist_order_reviews_dataset R ON OI.order_id = R.order_id
JOIN olist_products_dataset P ON OI.product_id = P.product_id
JOIN product_category_name_translation PC ON PC.product_category_name = P.product_category_name
HAVING delivery_days > estimate_delivery_days
ORDER BY delivery_days DESC;

-- 실제 배송일이 추정 배송일보다 낮은 데이터와 리뷰 점수
SELECT
    PC.product_category_name_english,
    TIMESTAMPDIFF(DAY, O.order_purchase_timestamp, O.order_delivered_customer_date) AS delivery_days,
    TIMESTAMPDIFF(DAY, O.order_purchase_timestamp, O.order_estimated_delivery_date) AS estimate_delivery_days,
    review_score
FROM olist_orders_dataset O
JOIN olist_order_items_dataset OI ON O.order_id = OI.order_id
JOIN olist_order_reviews_dataset R ON OI.order_id = R.order_id
JOIN olist_products_dataset P ON OI.product_id = P.product_id
JOIN product_category_name_translation PC ON PC.product_category_name = P.product_category_name
HAVING delivery_days < estimate_delivery_days
ORDER BY delivery_days DESC;

-- 실제 배송일이 추정 배송일보다 높은 데이터에 대한 평균 리뷰 점수
SELECT 
	AVG(review_score)
FROM (
	SELECT
		PC.product_category_name_english,
		TIMESTAMPDIFF(DAY, O.order_purchase_timestamp, O.order_delivered_customer_date) AS delivery_days,
		TIMESTAMPDIFF(DAY, O.order_purchase_timestamp, O.order_estimated_delivery_date) AS estimate_delivery_days,
		review_score
	FROM olist_orders_dataset O
	JOIN olist_order_items_dataset OI ON O.order_id = OI.order_id
	JOIN olist_order_reviews_dataset R ON OI.order_id = R.order_id
	JOIN olist_products_dataset P ON OI.product_id = P.product_id
	JOIN product_category_name_translation PC ON PC.product_category_name = P.product_category_name
	HAVING delivery_days > estimate_delivery_days
	ORDER BY delivery_days DESC
) AS delivery_over;

-- 실제 배송일이 추정 배송일보다 낮은 데이터에 대한 평균 리뷰 점수
SELECT 
	AVG(review_score)
FROM (
	SELECT
		PC.product_category_name_english,
		TIMESTAMPDIFF(DAY, O.order_purchase_timestamp, O.order_delivered_customer_date) AS delivery_days,
		TIMESTAMPDIFF(DAY, O.order_purchase_timestamp, O.order_estimated_delivery_date) AS estimate_delivery_days,
		review_score
	FROM olist_orders_dataset O
	JOIN olist_order_items_dataset OI ON O.order_id = OI.order_id
	JOIN olist_order_reviews_dataset R ON OI.order_id = R.order_id
	JOIN olist_products_dataset P ON OI.product_id = P.product_id
	JOIN product_category_name_translation PC ON PC.product_category_name = P.product_category_name
	HAVING delivery_days < estimate_delivery_days
	ORDER BY delivery_days DESC
) AS delivery_normal;

-- 실제 배송일이 추정 배송일보다 높은 데이터와 낮은 데이터의 빈도수 비교
SELECT 
    COUNT(*)
FROM (
	SELECT
		PC.product_category_name_english,
		TIMESTAMPDIFF(DAY, O.order_purchase_timestamp, O.order_delivered_customer_date) AS delivery_days,
		TIMESTAMPDIFF(DAY, O.order_purchase_timestamp, O.order_estimated_delivery_date) AS estimate_delivery_days
	FROM olist_orders_dataset O
	JOIN olist_order_items_dataset OI ON O.order_id = OI.order_id
	JOIN olist_products_dataset P ON OI.product_id = P.product_id
	JOIN product_category_name_translation PC ON PC.product_category_name = P.product_category_name
	HAVING delivery_days > estimate_delivery_days
	ORDER BY delivery_days DESC
) AS delivery_over
UNION ALL
SELECT 
	COUNT(*)
FROM (
	SELECT
		PC.product_category_name_english,
		TIMESTAMPDIFF(DAY, O.order_purchase_timestamp, O.order_delivered_customer_date) AS delivery_days,
		TIMESTAMPDIFF(DAY, O.order_purchase_timestamp, O.order_estimated_delivery_date) AS estimate_delivery_days
	FROM olist_orders_dataset O
	JOIN olist_order_items_dataset OI ON O.order_id = OI.order_id
	JOIN olist_products_dataset P ON OI.product_id = P.product_id
	JOIN product_category_name_translation PC ON PC.product_category_name = P.product_category_name
	HAVING delivery_days < estimate_delivery_days
	ORDER BY delivery_days DESC
) AS delivery_normal;

-- 실제 배송일이 추정 배송일보다 높은 데이터에서 초과된 배송일을 나타내기
SELECT 
	(delivery_days - estimate_delivery_days) AS delivery_over_days
FROM (
	SELECT
		PC.product_category_name_english,
		TIMESTAMPDIFF(DAY, O.order_purchase_timestamp, O.order_delivered_customer_date) AS delivery_days,
		TIMESTAMPDIFF(DAY, O.order_purchase_timestamp, O.order_estimated_delivery_date) AS estimate_delivery_days
	FROM olist_orders_dataset O
	JOIN olist_order_items_dataset OI ON O.order_id = OI.order_id
	JOIN olist_products_dataset P ON OI.product_id = P.product_id
	JOIN product_category_name_translation PC ON PC.product_category_name = P.product_category_name
	HAVING delivery_days > estimate_delivery_days
	ORDER BY delivery_days DESC
) AS delivery_over;

-- 실제 배송일이 추정 배송일보다 높은 데이터에서 초과된 배송일과 각 리뷰 점수 나타내기
SELECT 
	(delivery_days - estimate_delivery_days) AS delivery_over_days,
    review_score
FROM (
	SELECT
		PC.product_category_name_english,
		TIMESTAMPDIFF(DAY, O.order_purchase_timestamp, O.order_delivered_customer_date) AS delivery_days,
		TIMESTAMPDIFF(DAY, O.order_purchase_timestamp, O.order_estimated_delivery_date) AS estimate_delivery_days,
		review_score
	FROM olist_orders_dataset O
	JOIN olist_order_items_dataset OI ON O.order_id = OI.order_id
	JOIN olist_order_reviews_dataset R ON OI.order_id = R.order_id
	JOIN olist_products_dataset P ON OI.product_id = P.product_id
	JOIN product_category_name_translation PC ON PC.product_category_name = P.product_category_name
	HAVING delivery_days > estimate_delivery_days
	ORDER BY delivery_days DESC
) AS delivery_over;

-- 실제 배송일이 추정 배송일보다 높은 데이터에서 초과된 배송일별 평균 리뷰 점수 나타내기
SELECT
	delivery_over_days,
    ROUND(AVG(review_score), 2) avg_review_score
FROM (
	SELECT 
		(delivery_days - estimate_delivery_days) AS delivery_over_days,
		review_score
	FROM (
		SELECT
			PC.product_category_name_english,
			TIMESTAMPDIFF(DAY, O.order_purchase_timestamp, O.order_delivered_customer_date) AS delivery_days,
			TIMESTAMPDIFF(DAY, O.order_purchase_timestamp, O.order_estimated_delivery_date) AS estimate_delivery_days,
			review_score
		FROM olist_orders_dataset O
		JOIN olist_order_items_dataset OI ON O.order_id = OI.order_id
		JOIN olist_order_reviews_dataset R ON OI.order_id = R.order_id
		JOIN olist_products_dataset P ON OI.product_id = P.product_id
		JOIN product_category_name_translation PC ON PC.product_category_name = P.product_category_name
		HAVING delivery_days > estimate_delivery_days
		ORDER BY delivery_days DESC
	) AS delivery_over
) AS delivery_over2
GROUP BY delivery_over_days;

-- 실제 배송일이 추정 배송일보다 높은 데이터에서 초과된 배송일별 평균 리뷰 점수와 각 빈도수 나타내기
SELECT
	delivery_over_days,
    ROUND(AVG(review_score), 2) avg_review_score,
    COUNT(*) over_days_count
FROM (
	SELECT 
		(delivery_days - estimate_delivery_days) AS delivery_over_days,
		review_score
	FROM (
		SELECT
			PC.product_category_name_english,
			TIMESTAMPDIFF(DAY, O.order_purchase_timestamp, O.order_delivered_customer_date) AS delivery_days,
			TIMESTAMPDIFF(DAY, O.order_purchase_timestamp, O.order_estimated_delivery_date) AS estimate_delivery_days,
			review_score
		FROM olist_orders_dataset O
		JOIN olist_order_items_dataset OI ON O.order_id = OI.order_id
		JOIN olist_order_reviews_dataset R ON OI.order_id = R.order_id
		JOIN olist_products_dataset P ON OI.product_id = P.product_id
		JOIN product_category_name_translation PC ON PC.product_category_name = P.product_category_name
		HAVING delivery_days > estimate_delivery_days
		ORDER BY delivery_days DESC
	) AS delivery_over
) AS delivery_over2
GROUP BY delivery_over_days
ORDER BY delivery_over_days;

SELECT 
	O.order_id,
	C.customer_state,
	S.seller_state,
	TIMESTAMPDIFF(DAY, O.order_purchase_timestamp, O.order_delivered_customer_date) AS Delivery_day,
	R.review_score    
FROM olist_orders_dataset O
JOIN olist_order_reviews_dataset R ON O.order_id = R.order_id
JOIN olist_customers_dataset C ON C.customer_id = O.customer_id
JOIN olist_order_items_dataset OI ON OI.order_id = O.order_id
JOIN olist_sellers_dataset S ON S.seller_id = OI.seller_id
WHERE LOWER(customer_state) != LOWER(seller_state);

-- 다른 지역일 때 배송일에 대한 count
-- 서버가 끊기는 문제 발생
SELECT 
    TIMESTAMPDIFF(DAY, O.order_purchase_timestamp, O.order_delivered_customer_date) AS Delivery_day,
    COUNT(*) count
FROM olist_orders_dataset O
JOIN olist_order_reviews_dataset R ON O.order_id = R.order_id
JOIN olist_customers_dataset C ON C.customer_id = O.customer_id
JOIN olist_order_items_dataset OI ON OI.order_id = O.order_id
JOIN olist_sellers_dataset S ON S.seller_id = OI.seller_id
WHERE LOWER(C.customer_state) != LOWER(S.seller_state)
GROUP BY Delivery_day
ORDER BY Delivery_day ASC;

-- 실제 배송일이 추정 배송일보다 높은 데이터에서 초과된 배송일별 평균 리뷰 점수와 리뷰의 빈도수 나타내기
SELECT
	delivery_over_days,
    ROUND(AVG(review_score), 2) avg_review_score,
    COUNT(review_score) review_count
FROM (
	SELECT 
		(delivery_days - estimate_delivery_days) AS delivery_over_days,
		review_score
	FROM (
		SELECT
			PC.product_category_name_english,
			TIMESTAMPDIFF(DAY, O.order_purchase_timestamp, O.order_delivered_customer_date) AS delivery_days,
			TIMESTAMPDIFF(DAY, O.order_purchase_timestamp, O.order_estimated_delivery_date) AS estimate_delivery_days,
			review_score
		FROM olist_orders_dataset O
		JOIN olist_order_items_dataset OI ON O.order_id = OI.order_id
		JOIN olist_order_reviews_dataset R ON OI.order_id = R.order_id
		JOIN olist_products_dataset P ON OI.product_id = P.product_id
		JOIN product_category_name_translation PC ON PC.product_category_name = P.product_category_name
		HAVING delivery_days > estimate_delivery_days
		ORDER BY delivery_days DESC
	) AS delivery_over
) AS delivery_over2
GROUP BY delivery_over_days
ORDER BY delivery_over_days;

-- seller와 customer의 지역이 같을 때의 추정 배송일
SELECT 
	customer_state,
	seller_state,
	TIMESTAMPDIFF(DAY, O.order_purchase_timestamp, O.order_estimated_delivery_date) AS estimate_delivery_days
FROM olist_orders_dataset O	
JOIN olist_order_reviews_dataset R ON O.order_id = R.order_id
JOIN olist_customers_dataset C ON C.customer_id = O.customer_id
JOIN olist_order_items_dataset OI ON OI.order_id = O.order_id
JOIN olist_sellers_dataset S ON S.seller_id = OI.seller_id
WHERE LOWER(C.customer_state) = LOWER(S.seller_state)
ORDER BY estimate_delivery_days ASC;

-- seller와 customer의 지역이 같을 때의 평균 추정 배송일
SELECT
    ROUND(AVG(estimate_delivery_days), 1) avg_estimate_delivery_days
FROM(
	SELECT 
		customer_state,
		seller_state,
		TIMESTAMPDIFF(DAY, O.order_purchase_timestamp, O.order_estimated_delivery_date) AS estimate_delivery_days
	FROM olist_orders_dataset O
	JOIN olist_order_reviews_dataset R ON O.order_id = R.order_id
	JOIN olist_customers_dataset C ON C.customer_id = O.customer_id
	JOIN olist_order_items_dataset OI ON OI.order_id = O.order_id
	JOIN olist_sellers_dataset S ON S.seller_id = OI.seller_id
	WHERE LOWER(C.customer_state) = LOWER(S.seller_state)
	ORDER BY estimate_delivery_days ASC
) AS same_region_delivery;

-- seller와 customer의 지역이 같지 않을 때의 추정 배송일
SELECT 
    customer_state,
    seller_state,
    TIMESTAMPDIFF(DAY, O.order_purchase_timestamp, O.order_estimated_delivery_date) AS estimate_delivery_days
FROM olist_orders_dataset O
JOIN olist_order_reviews_dataset R ON O.order_id = R.order_id
JOIN olist_customers_dataset C ON C.customer_id = O.customer_id
JOIN olist_order_items_dataset OI ON OI.order_id = O.order_id
JOIN olist_sellers_dataset S ON S.seller_id = OI.seller_id
WHERE LOWER(C.customer_state) != LOWER(S.seller_state)
ORDER BY estimate_delivery_days ASC;

-- seller와 customer의 지역이 같지 않을 때의 평균 추정 배송일
SELECT
	ROUND(AVG(estimate_delivery_days), 1) avg_estimate_delivery_days
FROM (
	SELECT 
		customer_state,
		seller_state,
		TIMESTAMPDIFF(DAY, O.order_purchase_timestamp, O.order_estimated_delivery_date) AS estimate_delivery_days
	FROM olist_orders_dataset O
	JOIN olist_order_reviews_dataset R ON O.order_id = R.order_id
	JOIN olist_customers_dataset C ON C.customer_id = O.customer_id
	JOIN olist_order_items_dataset OI ON OI.order_id = O.order_id
	JOIN olist_sellers_dataset S ON S.seller_id = OI.seller_id
	WHERE LOWER(C.customer_state) != LOWER(S.seller_state)
	ORDER BY estimate_delivery_days ASC
) AS dif_region_delivery;

-- price 컬럼의 데이터타입을 실수형으로 변환한 뒤, 가격 순으로 내림차순
SELECT CAST(price AS DECIMAL(10,2)) AS price
FROM olist_order_items_dataset
ORDER BY price DESC;

-- seller와 customer의 지역이 같을 때의 추정 배송일 종류
SELECT 
	TIMESTAMPDIFF(DAY, O.order_purchase_timestamp, O.order_estimated_delivery_date) AS estimate_delivery_days
FROM olist_orders_dataset O	
JOIN olist_order_reviews_dataset R ON O.order_id = R.order_id
JOIN olist_customers_dataset C ON C.customer_id = O.customer_id
JOIN olist_order_items_dataset OI ON OI.order_id = O.order_id
JOIN olist_sellers_dataset S ON S.seller_id = OI.seller_id
WHERE LOWER(C.customer_state) = LOWER(S.seller_state)
GROUP BY estimate_delivery_days
ORDER BY estimate_delivery_days ASC;

-- seller와 customer의 지역이 같을 때, 추정 배송일이 2일인 데이터 조회
SELECT *
FROM (
	SELECT 
		TIMESTAMPDIFF(DAY, O.order_purchase_timestamp, O.order_estimated_delivery_date) AS estimate_delivery_days
	FROM olist_orders_dataset O	
	JOIN olist_order_reviews_dataset R ON O.order_id = R.order_id
	JOIN olist_customers_dataset C ON C.customer_id = O.customer_id
	JOIN olist_order_items_dataset OI ON OI.order_id = O.order_id
	JOIN olist_sellers_dataset S ON S.seller_id = OI.seller_id
	WHERE LOWER(C.customer_state) = LOWER(S.seller_state)
) AS same_region_delivery
WHERE estimate_delivery_days = '2';