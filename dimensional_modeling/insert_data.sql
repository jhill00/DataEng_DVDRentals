-- insert data to dimension tables

INSERT INTO dim_date
(date_key, date, year, quarter, month, day, weekend) 
SELECT
	DISTINCT(TO_CHAR(payment_date, 'yyyymmdd')::INTEGER) as date_key,
	payment_date::date as date,
	EXTRACT(YEAR from payment_date)	as year,
	EXTRACT(QUARTER from payment_date) as quarter,
	EXTRACT(MONTH from payment_date) as month,
	EXTRACT(DAY from payment_date) as day,
	CASE
		WHEN EXTRACT(ISODOW FROM payment_date) IN(6,7) THEN TRUE
		ELSE FALSE
	END as weekend
FROM
	payment;

INSERT INTO dim_customer
(customer_id, customer_name, email, country, district, city, 
 postal_code, address, phone, active, create_date, last_update)
 SELECT
 	c.customer_id,
	(c.first_name || ' ' || c.last_name) as customer_name,
	c.email,
	co.country,
	a.district,
	ct.city,
	a.postal_code,
	CASE
	WHEN a.address2 <> '' THEN concat(a.address, ', ', a.address2)
	ELSE a.address
	END as address,
	a.phone,
	c.activebool as active,
	c.create_date,
	c.last_update
FROM
	customer as c
INNER JOIN
	address as a ON c.address_id = a.address_id
INNER JOIN
	city as ct ON a.city_id = ct.city_id
INNER JOIN
	country as co ON ct.country_id = co.country_id
;

INSERT INTO dim_film
(film_id, title, description, release_year, category, rental_duration, 
rental_rate, film_length, rating, special_features, film_language)
SELECT
	f.film_id,
	f.title,
	f.description,
	f.release_year,
	c.name as category,
	f.rental_duration,
	f.rental_rate,
	f.length as film_length,
	f.rating,
	f.special_features,
	l.name as film_language
FROM
	film as f
INNER JOIN
	film_category as fc ON f.film_id = fc.film_id
INNER JOIN
	category as c ON fc.category_id = c.category_id
INNER JOIN
	language as l ON f.language_id = l.language_id
;

INSERT INTO dim_store
(store_id, staff_id, employee_name, email, active, staff_username, staff_password, manager_staff_id)
SELECT
	sa.store_id,
	sa.staff_id,
	(sa.first_name || ' ' || last_name) as employee_name,
	sa.email,
	sa.active,
	sa.username as staff_username,
	sa.password as staff_password,
	so.manager_staff_id
FROM
	staff as sa
INNER JOIN
	store as so ON sa.store_id = so.store_id
;

INSERT INTO dim_actor
(film_actor_id, film_id, actor_id, actor_name)
SELECT
	CONCAT(fa.film_id, '_', fa.actor_id) as film_actor_id,
	fa.film_id,
	fa.actor_id,
	(a.first_name || ' ' || a.last_name) as actor_name
FROM
	film_actor as fa
INNER JOIN
	actor as a ON a.actor_id = fa.actor_id
;

-- insert data to fact table

INSERT INTO fact_sales
(date_key, store_id, customer_id, film_id, film_actor_id, sales)
SELECT
	DISTINCT(TO_CHAR(p.payment_date, 'yyyymmdd')::INTEGER) as date_key,
	s.store_id,
	p.customer_id,
	i.film_id,
	CONCAT(fa.film_id, '_', fa.actor_id) as film_actor_id,
	p.amount as sales
FROM
	payment as p
INNER JOIN
	rental as r ON r.rental_id = p.rental_id
INNER JOIN
	inventory as i ON i.inventory_id = r.inventory_id
INNER JOIN
	film_actor as fa ON fa.film_id = i.film_id
INNER JOIN
	staff as s ON s.staff_id = p.staff_id
;