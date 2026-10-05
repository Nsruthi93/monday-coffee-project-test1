-- monday coffee -- Data Analysis

select * from city;
select * from products;
select * from customers;
select * from sales;

--Report  & Data Analysis

--Q.1
-- Coffee consumers count
-- How many people in each city are estimated to consume coffee , given that 25% of population does?


select 
   city_name,
   ROUND((
  population *0.25)/1000000 ,2) as coffee_consume_in_millions,
   city_rank
   from city
   order by 2 desc 


--Q.2
--Total revenue from coffee sale
--what is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

select  *,
       extract(year from sale_date) as year,
	   extract(quarter from sale_date) as qtr
from sales
where 
     extract(year from sale_date) = 2023
	 and
	 extract(quarter from sale_date) = 4

;

--Total revenue

select  
       sum(total) as total_revenue
from sales
where 
     extract(year from sale_date) = 2023
	 and
	 extract(quarter from sale_date) = 4;

	 -- Finding each city and their revenue

select  
       ci.city_name,
	   sum(s.total) as total_revenue
from sales as s
join customers as c
on s.customer_id = c.customer_id
join city as ci
on ci.city_id = c.city_id
where 
     extract(year from s.sale_date) = 2023
	 and
	 extract(quarter from s.sale_date) = 4
 group by 1	 
 order by 2 desc;

 --Q.3
 -- Sales count for each product
 --How many units of each coffee product have been sold?

 select 
      p.product_name, 
	  count(s.sale_id)as total_orders
 from products as p
 LEFT JOIN 
 sales as s
 on s.product_id = p.product_id
 group by 1
 order by 2 desc;
 
--Q.4
--Average sales amounts per city
--What is the average sales amounts per customer in each city?
--City and totalsale
--No of customers in each of these city

select  
       ci.city_name,
	   sum(s.total) as total_revenue,
	   count( DISTINCT s.customer_id) as total_customers,
	   ROUND(
	         sum(s.total)::numeric/
			 count(DISTINCT s.customer_id)
			 ,2) as avg_sale_per_cus
from sales as s
join customers as c
on s.customer_id = c.customer_id
join city as ci
on ci.city_id = c.city_id
group by 1	 
order by 2 desc;

--Q.5
--City population and coffee consumers
--Provide a list of cities along with their population and estimated coffee consumers?
--Return city_name , total current customers, estimated coffee consumers(25%)

With city_table as
(
select
     city_name,
	 ROUND(population * 0.25/1000000,2) as coffee_consumers
from city
),

customer_table
AS
(
select
      ci.city_name,
	  count(DISTINCT c.customer_id) as unique_customers
from sales as s
join customers as c
on c.customer_id = s.customer_id
join city as ci
on ci.city_id = c.city_id
group by 1
)

 select 
       customer_table.city_name,
	   city_table.coffee_consumers as coffee_consumers_in_millions,
	   customer_table.unique_customers
   from 
       city_table 
	  join  
	  customer_table 
	  on city_table.city_name = customer_table.city_name

--Q.6
--Top selling products by city
--What are the top 3 selling products in each city based on sales volume.
select *
from --table
 (select 
      ci.city_name,
	  p.product_name,
	  count(s.sale_id)as total_orders,
	  DENSE_RANK() OVER(Partition by ci.city_name ORDER BY COUNT(s.sale_id)DESC )as rank
from sales as s
join products as p
on p.product_id = s.product_id
join  customers as c
on c.customer_id = s.customer_id
join city as ci
on ci.city_id = c.city_id
 group by 1,2 )as t1
 where rank <= 3

--Q.7
--Customer segmentation by city
--How many unique customers are there in each city who have purchased coffee products.

select * from products;
 
 select 
     ci.city_name,
	 COUNT(DISTINCT c.customer_id)as unique_customers
from city as ci
left join
customers as c
on c.city_id = ci.city_id
join sales as s
on s.customer_id = c.customer_id
where 
    s.product_id IN(1,2,3,4,5,6,7,8,9,10,11,12,13,14)
group by 1

	  
--Q.8
--Average sale vs rent
--Find each city and their average sale per customer and average rent for customer.
--Conclusions

with city_table
as

(select  
       ci.city_name,
	   count( DISTINCT s.customer_id) as total_customers,
	   ROUND(
	         sum(s.total)::numeric/
			 count(DISTINCT s.customer_id)
			 ,2) as avg_sale_per_cus
from sales as s
join customers as c
on s.customer_id = c.customer_id
join city as ci
on ci.city_id = c.city_id
group by 1	 
order by 2 desc
),

city_rent
as
(select 
city_name, 
estimated_rent
from city
)
select 
       cr.city_name, 
       cr.estimated_rent,
	   ct.total_customers,
	   ct.avg_sale_per_cus,
	   ROUND(cr.estimated_rent::numeric/
	            ct.total_customers::numeric ,2) as avg_rent_per_cus
from city_rent as cr
join city_table as ct
on  ct.city_name = cr.city_name
order by 4 desc
--city and total rent/total customers


--Q.9
--Monthly sales growth
--Sales growth rate: caluculate the percentage growth (or decline) in sales over different time periods(monthly).
-- by each city.

with 
monthly_sales
AS
(
select
     ci.city_name,
	 EXTRACT(month from sale_date)as month,
	 EXTRACT(year from sale_date)as year,
	 sum(s.total) as total_sale
from sales s
join customers as c
on c.customer_id = s.customer_id
join city  as ci
on ci.city_id = c.city_id
group by 1,2,3
order by 1,3,2
),
growth_ratio
AS
 (
 select
    city_name,
	month,
	year,
	total_sale as current_month_sale,
	LAG(total_sale,1) over(partition by city_name order by year,month )as last_month_sale
from monthly_sales
)	
select 
city_name,
month,
year,
current_month_sale,
last_month_sale,
   ROUND(
        (current_month_sale-last_month_sale)::numeric/last_month_sale::numeric * 100 
        ,2
)as growth_ratio

from growth_ratio
where last_month_sale is not null


--Q.10
--Market potential analysis
--Identify top 3 city based on highest sales,return city name ,total sales,total rent,total customers,estimated coffee consumers

with city_table
as

(select  
       ci.city_name,
	   sum(s.total)as total_revenue,
	   count( DISTINCT s.customer_id) as total_customers,
	   ROUND(
	         sum(s.total)::numeric/
			 count(DISTINCT s.customer_id)
			 ,2) as avg_sale_per_cus
from sales as s
join customers as c
on s.customer_id = c.customer_id
join city as ci
on ci.city_id = c.city_id
group by 1	 
order by 2 desc
),
city_rent
 as
 (
     select 
          city_name, 
          estimated_rent,
         ROUND((population *0.25)/1000000,3) as estimated_coffee_consumer_in_millions
     from city
)
select 
       cr.city_name,
	   total_revenue,
	   cr.estimated_rent as total_rent,
	   ct.total_customers,
	   estimated_coffee_consumer_in_millions,
	   ct.avg_sale_per_cus,
	   ROUND(cr.estimated_rent::numeric/
	            ct.total_customers::numeric ,2) as avg_rent_per_cus
from city_rent as cr
join city_table as ct
on  ct.city_name = cr.city_name
order by 2 desc

/*
--Recomendations
city :Pune
  1.Avg rent per cus is less.
  2.Highest total revenue. 
  3.Avg sale per cus is high.

city :Delhi
   1.Highest estimated coffee consumer in millions which is 7.7m.
   2.Highest total customers is 86.
   3.Avg rent per cus is 330 (still under 500)

city :Jaipur
   1.Highest no of total customers which is 69.
   2. Avg rent per cus is 156 so very less.
   3.Avg sale per cus better which is 11.6k.