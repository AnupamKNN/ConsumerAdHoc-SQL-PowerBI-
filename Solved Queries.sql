/* Q1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in APAC region */

select * from dim_customer;
select distinct(market)
from dim_customer
where customer = "Atliq Exclusive"
and region = "APAC";

/* Q2. What is the percentage of unique product increase in 2021 vs 2020?

select * from fact_sales_monthly;

with unique_product_count as
(
select count(distinct case when fiscal_year = 2020 then product_code END) as unique_products_2020, # Count of distinct products sold in 2020
count(distinct case when fiscal_year = 2021 then product_code END) as unique_products_2021 # Count of distinct products sold in 2021
from fact_sales_monthly)
select unique_products_2020, unique_products_2021, 
concat(round(((unique_products_2021 - unique_products_2020)*1.0/unique_products_2020)*100,2),'%') as percentage_increase
from unique_product_count;

/* Q3. Provide a report with all the unique product counts for each segment and sort them in descending order of product counts */

select * from dim_product;

select segment, count(distinct(product_code)) as product_count
from dim_product
group by segment
order by product_count desc;

/* Q4. Follow-up: Which segment had the most increase in unique products in 2021 vs 2020?

select * from fact_sales_monthly;
select * from dim_product;

with unique_product as
(
select b.segment as segment,
count(distinct (case when fiscal_year = 2020 then a.product_code END)) as product_count_2020,
count(distinct (case when fiscal_year = 2021 then a.product_code END)) as product_count_2021
from fact_sales_monthly as a
inner join dim_product as b
on a.product_code = b.product_code
group by b.segment)
select segment, product_count_2020, product_count_2021,
(product_count_2021 - product_count_2020) as difference
from unique_product
order by difference desc;

/* Q5. Get the products that have highest and lowest manufacturing costs. */

select * from fact_manufacturing_cost;
select * from dim_product;

select a.product_code as product_code,
a.product as product,
concat('$', round(b.manufacturing_cost,2)) as manufacturing_cost
from dim_product as a
inner join fact_manufacturing_cost as b
on a.product_code = b.product_code
where b.manufacturing_cost = (select max(manufacturing_cost) from fact_manufacturing_cost)
or b.manufacturing_cost = (select min(manufacturing_cost) from fact_manufacturing_cost)
order by b.manufacturing_cost desc;

/* Q6. Generate a report which contains top 5 costomers who received an average high pre_invoice_discount_pct for the fiscal year 2021
and in the Indian market */

select * from fact_pre_invoice_deductions;
select * from dim_customer;

select a.customer_code as customer_code,
b.customer as customer,
concat(round(avg(pre_invoice_discount_pct)*100,2), '%') as average_discount_percentage
from fact_pre_invoice_deductions as a
inner join dim_customer as b
on a.customer_code = b.customer_code
where market = 'India'
and fiscal_year = 2021
group by customer, customer_code
order by avg(pre_invoice_discount_pct) desc
limit 5;

/* Q7. Get complete report of the gross sales amount for the customer "Atliq Exclusive" for each momth. This analys helps to get an idea of low and high-performing
months and take strategic decisions. */

select * from fact_sales_monthly;
select * from dim_customer;
select * from fact_gross_price;

select monthname(date) as month_name,
year(date) as year_,
concat('$',round(sum(a.sold_quantity * b.gross_price)/1000000,2)) as gross_sales_amount_millions
from fact_sales_monthly as a
inner join fact_gross_price as b
on a.product_code = b.product_code
and a.fiscal_year = b.fiscal_year
inner join dim_customer as c
on c.customer_code = a.customer_code
where c.customer = "Atliq Exclusive"
group by month_name, year_
order by year_;



/* Q8. In which quarter of 2020, got the maximum total_sold_quantity? */

select * from fact_sales_monthly;

select
case
	when month(date) in (9, 10, 11) then 'Q1' # Atliq Hardware has september as its first financial momth
    when month(date) in (12, 1, 2) then 'Q2'
    when month (date) in (3,4,5) then 'Q3'
    else 'Q4'
    end as quarters,
sum(sold_quantity) as total_quantity_sold
from fact_sales_monthly
where fiscal_year = 2020
group by quarters
order by total_quantity_sold desc;


/* Q9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? */

select * from fact_sales_monthly;
select * from dim_customer;
select * from fact_gross_price;

with gross_sales as
(
select c.channel as channel_,
round(sum(b.gross_price * a.sold_quantity)/1000000,2) as gross_sales_mln
from fact_sales_monthly as a
left join fact_gross_price as b
on a.product_code = b.product_code
and a.fiscal_year = b.fiscal_year
left join dim_customer as c
on c.customer_code = a.customer_code
where a.fiscal_year = 2021
group by c.channel)
select channel_,
concat('$',gross_sales_mln) as gross_sales_mln,
concat(round(gross_sales_mln/ sum(gross_sales_mln)
over() * 100, 2), '%') as percentage
from gross_sales
order by percentage desc;


/* Q10. Get top 3 products in each division that have high total_sales_quantity in fiscal year 2021 */

select * from fact_sales_monthly;
select * from dim_product;

with top_sold_products as
(
select b.division as division,
b.product_code as product_code,
b.product as product,
sum(a.sold_quantity) as total_sold_quantity
from fact_sales_monthly as a
inner join dim_product as b
on a.product_code = b.product_code
where a.fiscal_year = 2021
group by b.division, b.product_code, b.product
order by total_sold_quantity desc
),
top_products_per_division as 
(
select division, product_code, product, total_sold_quantity,
dense_rank() over (partition by division order by total_sold_quantity desc) as rank_order
from top_sold_products
)
select * from top_products_per_division
where rank_order <= 3;