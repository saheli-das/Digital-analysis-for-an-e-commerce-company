--** Data cleaning and merging ** 

ALTER TABLE ORDERS
ALTER COLUMN PRICE_USD DECIMAL(5,2)

ALTER TABLE ORDER_ITEMS
ALTER COLUMN PRICE_USD DECIMAL(5,2)

ALTER TABLE ORDERS
ALTER COLUMN cogs_USD DECIMAL(5,2)

ALTER TABLE ORDER_ITEMS
ALTER COLUMN cogs_USD DECIMAL(5,2)

ALTER TABLE order_item_refunds
ALTER COLUMN refund_amount_usd DECIMAL(5,2)

/*Data type of price_usd and cogs_usd (cost) given in the orders table, orders_item table
and order_item_refunds table are taking in ‘float’ by default while importing
the data from ‘csv’ to ‘sql’ and thus taking the value upto 5-6 decimal places.
Changed the data type of price_usd & cogs_usd columns of both orders 
and order_item table and order_refund_amount columns in order_refund table
to ‘decimal (5,2)’ to take upto two decimal place*/



 
 ---creating Or_oritm table by joining orders table,order_item table and product table
 
select o.order_id,o.created_at as order_creation_time,[user_id],o.website_session_id,
           o.items_purchased, o.primary_product_id,
          order_item_id,OI.product_id,p.created_at as product_creation_time,p.product_name,
           is_primary_item,OI.price_usd,OI.cogs_usd into Or_oritm from  orders as o
join order_items as OI
on o.order_id=OI.order_id
 and
 o.created_at=OI.created_at
 join products as p
 on OI.product_id=p.product_id



 /*creating table_1 by joining Or_oritm table and order_item_refunds table.
  after joining these tables itemwise price_usd and cogs_usd for each order_id,and refund value
  of that order_id and product_id and name for each item  came in one table.
  For the order items which were not refunded ,
  the refund value has come to null which were subsequently changed to 0.*/
 
 select o.order_id,o.order_creation_time,o.[user_id],o.website_session_id,o.items_purchased,
           o.order_item_id,o.is_primary_item,
           o.primary_product_id,o.product_id,product_creation_time,o.product_name,
		   o.price_usd,o.cogs_usd,
		   ord.order_item_refund_id,ord.created_at as refund_time,ord.refund_amount_usd
		   into table_1
 from Or_oritm as o
 left join order_item_refunds as ord
 on o.order_id=ord.order_id
   and
 o.order_item_id=ord.order_item_id


/*creating table_2  by joining website_pageviews table and website_sessions table .
 Session creation time and pageview creation time can be seen in one table.*/

 
 select wp.website_pageview_id,wp.created_at as webpage_creation_time,wp.pageview_url,
     ws.website_session_id,ws.created_at as session_creation_time,ws.[user_id],
	 ws.is_repeat_session,ws.device_type,ws.utm_source,ws.utm_campaign,ws.utm_content,
	 ws.http_referer into table_2
 from website_pageviews as wp
 join website_sessions as ws
 on wp.website_session_id=ws.website_session_id




 
update table_2 set utm_campaign='N/A'
where utm_campaign='null'

update table_2 set utm_source='N/A'
where utm_source='null'

update table_2 set utm_content='N/A'
where utm_content='null'

update table_2 set http_referer='N/A'
where http_referer='null'




update table_1 set refund_amount_usd=0
where refund_amount_usd is null

ALTER TABLE table_1
Add  Revenue DECIMAL(5,2)


-- order_itemwise revenue

update table_1 set Revenue=price_usd-refund_amount_usd

---------------------------------------------**---------------------------------------------------
---------------------------------------------**-------------------------------------------------------

--** High Level Metrics **-- 

 -- Total Revenue and Total Cost

   Select Sum(Revenue) as Total_Revenue from table_1 

 -- Revenue (CAGR from 01.01.2013 to 31.12.2014 -for two years)

 select (SQRT(max(total_revenue)/min(total_revenue))-1)*100.00 as CAGR_revenue
 from (
 select '31-12-2012' as period_upto, sum(revenue) as total_revenue
 from table_1
 where order_creation_time<'2013-01-01'
 union
select '31-12-2014' as period_upto, sum(revenue) as total_revenue
 from table_1
 where order_creation_time<'2015-01-01') as x


 -- Order price per order

SELECT 
    sum(Revenue)*1.00/count(distinct order_id) AS average_order_value
FROM 
    table_1
where order_item_refund_id is null

 -- Total Refund price
 Select sum(A.refund_amount_usd) from table_1 A

 -- Total orders
 Select count(A.order_id) from orders A

 -- Total Refunded Orders
 Select count(distinct A.order_id) 
 From table_1 A
 where order_item_refund_id is null

 -- Total Customers
 Select count(distinct user_id) From table_1
 where order_item_refund_id is null


 -- Total Revenue per product
 Select A.product_name,Sum(A.Revenue) Product_revenue From table_1 A
 group by A.product_name
 order by Product_revenue desc


-- Gross Profit

SELECT sum(Revenue) - SUM(cogs_usd) AS gross_profit
FROM table_1 
where order_item_refund_id is null

--or

SELECT sum(price_usd)-sum(refund_amount_usd) - SUM(cogs_usd) AS gross_profit
FROM table_1 
where order_item_refund_id is null

--Profit (CAGR from 01.01.2013 to 31.12.2014 -for two years)

select (SQRT(max(total_profit)/min(total_profit))-1)*100.00 as CAGR_profit
 from (
 select '31-12-2012' as period_upto, sum(revenue)-sum(cogs_usd) as total_profit
 from table_1
 where order_creation_time<'2013-01-01' and order_item_refund_id is null
 union
select '31-12-2014' as period_upto, sum(revenue)-sum(cogs_usd) as total_profit
 from table_1
 where order_creation_time<'2015-01-01' and order_item_refund_id is null) as x

 --profit percentage
 SELECT (sum(Revenue) - SUM(cogs_usd))*100.00/sum(cogs_usd) AS profit_percent
FROM table_1 
 where order_item_refund_id is null



--average revenue per customer
select sum(revenue)/count(distinct user_id) as avg_rev_per_cust from
table_1
where order_item_refund_id is null

--average profit per customer
select (sum(revenue)-sum(cogs_usd))/count(distinct user_id) as avg_profit_per_cust from
table_1
where order_item_refund_id is null



-- New Customer Revenue Generation
Select count(T.user_id) total_cust,sum(T.Total_Revenue) total_revenue from (
SELECT 
    user_id, 
    COUNT(order_id) AS orders_per_customer,  Sum(Revenue) as Total_Revenue
FROM 
    table_1
where order_item_refund_id is null
GROUP BY 
    user_id) T
where T.orders_per_customer = 1


-- Repeat Customer Revenue Generation
Select count(T.user_id) total_cust, sum(T.Total_Revenue) total_revenue from (
SELECT 
    user_id, 
    COUNT(order_id) AS orders_per_customer,  Sum(Revenue) as Total_Revenue
FROM 
    table_1
where order_item_refund_id is null
GROUP BY 
    user_id) T
where T.orders_per_customer > 1

-- Percentage of Order Refunded
SELECT 
    COUNT(DISTINCT order_item_refund_id) * 1.0 / COUNT(DISTINCT order_id) * 100 AS refund_rate
FROM 
    table_1;

-- Avg items per order
SELECT 
    count(items_purchased)*1.00/count(distinct order_id) AS avg_items_per_order
	FROM 
    table_1
	where order_item_refund_id is null

-- Conversion rate

select count(distinct order_id)*100.00/count(distinct w.website_session_id) as conversion_rate 
from table_1 as T
right join website_sessions as W
on T.website_session_id=w.website_session_id
and order_item_refund_id is null

--types of device

select count(distinct device_type) from table_2

--types of UTM source

select count(distinct UTM_source) from table_2
where UTM_source <> 'N/A'

--Total_Website sessions

select count(distinct website_session_id) as total_sessions
from table_2

--Total_Pageviews

select count(distinct website_pageview_id) as total_sessions
from table_2

--Total_Visitors

select count(distinct [user_id]) as total_users
from table_2




--One Time_Visitors 

select count(*)
from(
select [user_id] as users
from table_2
group by [user_id]
having count(distinct website_session_id)=1) as x

--Repeat_Visitors 

select count(*)
from(
select [user_id] as users
from table_2
group by [user_id]
having count(distinct website_session_id)>1) as x


 --Bounce Rate overall

 with cte1 as(select website_session_id as single_page_session
               from table_2
			   group by website_session_id
			   having count(pageview_url)=1)
select count(single_page_session)*100.00/count( distinct website_session_id) as bounce_rate
from table_2 as T
left join CTE1 as C
on single_page_session=website_session_id

--average time per session

with cte1 as(
select website_session_id,datediff(second,min(webpage_creation_time),max(webpage_creation_time))
    as time_gap
from table_2
group by website_session_id)select avg(time_gap) as avg_session_duration
from cte1



-------------------------------------------------**------------------------------------------------
-------------------------------------------------**------------------------------------------------

--** Business patterns and seasonality **--



/*Q1.First, I’d like to show our volume growth. Can you pull overall session and 
     order volume, trended by quarter for the life of the 
     business? Since the most recent quarter is incomplete, you can decide how to handle it.*/

--yearly trend 
 
    select year(created_at) as years,
         count(items_purchased) as total_sales,
		 (sum(price_usd)-sum(refund_amount_usd)) as total_revenue,
		 (sum(price_usd)- sum(refund_amount_usd) - sum(cogs_usd)) as margin
		 
  from website_sessions as w
  left join table_1 as t
  on w.website_session_id=t.website_session_id
    and w.[user_id]=t.[user_id]
	where order_item_refund_id is null
  group by year(created_at)
  order by years
 -----------
     select year(created_at) as years,
         count(distinct t.[user_id]) as total_customers,
		 count(distinct w.[user_id]) as total_visitors,
		 count(distinct w.website_session_id) as total_sessions
		 
  from website_sessions as w
  left join table_1 as t
  on w.website_session_id=t.website_session_id
    and w.[user_id]=t.[user_id]
  group by year(created_at)
  order by years
 
//*separate coding has not been done for slide 33-34. This has been done from quarterly analysis
using pivot table in excel*//

---session volume(quarter_wise) slide no. 35---------

select datepart(quarter,created_at) as quarter_no,year(created_at) as years,
        count(website_session_id) as total_session
from website_sessions
group by datepart(quarter,created_at),year(created_at)
order by years,quarter_no

---session volume growth(quarter_wise)

select *,(curr_total_session-prev_total_session)*100/prev_total_session as
              session_volume_growth_percent from(
select quarter_no,years,curr_total_session,
      lag(curr_total_session)over(order by years,quarter_no) as prev_total_session
	  from(
		select datepart(quarter,created_at) as quarter_no,year(created_at) as years,
        count(website_session_id) as curr_total_session
        from website_sessions
		 where cast(created_at as date)>='2012-04-01'
        group by datepart(quarter,created_at),year(created_at)
		) as x) as y

---order volume(quarter_wise)

select  datepart(quarter,order_creation_time) as quarter_no,year(order_creation_time) as years,
       count(distinct order_id) as total_orders
       from table_1
where order_item_refund_id is  null
group by datepart(quarter,order_creation_time),year(order_creation_time)
order by years,quarter_no

---order volume growth(quarter_wise)

select *,(curr_orders-prev_orders)*100/prev_orders as order_volume_growth_percent
from(
select quarter_no,years,curr_orders,
   lag(curr_orders)over( order by years,quarter_no) as prev_orders
from(
       select  datepart(quarter,order_creation_time) as quarter_no,year(order_creation_time) as years,
       count(distinct order_id) as curr_orders
       from table_1
	   where cast(order_creation_time as date)>='2012-04-01'
	    and  order_item_refund_id is  null
       group by datepart(quarter,order_creation_time),year(order_creation_time)
     ) as x) as y

------Customer(Quarter_wise)

select  datepart(quarter,order_creation_time) as quarter_no,year(order_creation_time) as years,
       count(distinct [user_id]) as customers
       from table_1
	   where cast(order_creation_time as date)>='2012-04-01'
	    and  order_item_refund_id is  null
       group by datepart(quarter,order_creation_time),year(order_creation_time)
	   order by years,quarter_no

------Margin(Quarter_wise)

select  datepart(quarter,order_creation_time) as quarter_no,year(order_creation_time) as years,
       sum(price_usd)-sum(refund_amount_usd)-sum(cogs_usd) as margin
       from table_1
	   where cast(order_creation_time as date)>='2012-04-01'
	    and  order_item_refund_id is  null
       group by datepart(quarter,order_creation_time),year(order_creation_time)
	   order by years,quarter_no


/*Q2. Next, let’s showcase all of our efficiency improvements. I would love to show quarterly
    figures since we launched, for session-to
    order conversion rate, revenue per order, and revenue per session.*/

--session to order conversion rate 

with orders as(
    SELECT datepart(quarter,order_creation_time) as quarter_no,
      datepart(year,order_creation_time) as years,
      count(distinct order_id) as total_orders  
	from table_1 
	where cast(order_creation_time as date)>='2012-04-01'
	and order_item_refund_id is  null
	group by datepart(quarter,order_creation_time),datepart(year,order_creation_time)),

	web_sessions as(
	select datepart(quarter,created_at) as quarter_no,
      datepart(year,created_at) as years,
	  count(distinct website_session_id) as total_session
	from website_sessions
	where cast(created_at as date)>='2012-04-01'
	group by datepart(quarter,created_at),datepart(year,created_at))

	select w.quarter_no,w.years,total_orders,total_session,
	       total_orders*100.00/total_session as conversion_rate
	from web_sessions as w
	join orders as o
	on w.years=o.years
	and    w.quarter_no=o.quarter_no
	order by w.years,w.quarter_no


--Revenue per order(quarter_wise)

select datepart(quarter,order_creation_time) as quarter_no,
      datepart(year,order_creation_time) as years,
	  sum(revenue) as revenue,count(distinct order_id) as total_order,
	  (sum(price_usd)-sum(refund_amount_usd)) /count(distinct order_id) as revenue_per_order
	  
from table_1
where cast(order_creation_time as date)>='2012-04-01'
     and order_item_refund_id is null
group by datepart(quarter,order_creation_time),datepart(year,order_creation_time)
order by years,quarter_no


--Revenue per session (quarter_wise)

select datepart(quarter,created_at) as quarter_no,
      datepart(year,created_at) as years,(sum(price_usd)-sum(refund_amount_usd)) as revenue,
	  count(distinct w.website_session_id) as total_session,
(sum(price_usd)-sum(refund_amount_usd))/count(distinct w.website_session_id) as revenue_per_session
	  from website_sessions as w
left join table_1 as t
on w.website_session_id=t.website_session_id
 and w.[user_id]=t.[user_id]
where cast(created_at as date)>='2012-04-01'
group by datepart(quarter,created_at),datepart(year,created_at)
order by years,quarter_no


/*I’d like to show how we’ve grown specific channels. Could you pull a quarterly
   view of orders from G search nonbrand, B search 
   nonbrand, brand search overall, organic search, and direct type-in?*/

   --nonbrand search overall((quarter_wise)) 

 select DATEPART(quarter,order_creation_time) as quarter_no,year(order_creation_time) as years,
        count(distinct order_id) as total_orders,
        sum(Revenue) as total_revenue from table_1 as t
 join website_sessions as w
 on t.website_session_id=w.website_session_id
 and
    t.[user_id]=w.[user_id]
where  utm_campaign='nonbrand'
      and  cast(order_creation_time as date)>='2012-04-01'
	  and order_item_refund_id is null
group by DATEPART(quarter,order_creation_time),year(order_creation_time)
order by years,quarter_no

--brand search overall(quarter_wise) 

 select DATEPART(quarter,order_creation_time) as quarter_no,year(order_creation_time) as years,
        count(distinct order_id) as total_orders,
        sum(Revenue) as total_revenue from table_1 as t
 join website_sessions as w
 on t.website_session_id=w.website_session_id
 and
    t.[user_id]=w.[user_id]
where  utm_campaign='brand'
      and  cast(order_creation_time as date)>='2012-04-01'
	  and order_item_refund_id is null
group by DATEPART(quarter,order_creation_time),year(order_creation_time)
order by years,quarter_no

 
 --G search nonbrand(quarter_wise) 
 
 -- revenue and orders

 select DATEPART(quarter,order_creation_time) as quarter_no,year(order_creation_time) as years,
        count(distinct order_id) as total_orders,
        SUM(revenue) as total_revenue from table_1 as t
 join website_sessions as w
 on t.website_session_id=w.website_session_id
 and
    t.[user_id]=w.[user_id]
where utm_source='gsearch' and utm_campaign='nonbrand'
     and  cast(order_creation_time as date)>='2012-04-01'
	 and order_item_refund_id is null
group by DATEPART(quarter,order_creation_time),year(order_creation_time)
order by years,quarter_no


 --B search nonbrand(quarter_wise)

  select DATEPART(quarter,order_creation_time) as quarter_no,year(order_creation_time) as years,
        count(distinct order_id) as total_orders,
        sum(revenue) as total_revenue from table_1 as t
 join website_sessions as w
 on t.website_session_id=w.website_session_id
 and
    t.[user_id]=w.[user_id]
where utm_source='bsearch' and utm_campaign='nonbrand'
      and  cast(order_creation_time as date)>='2012-04-01'
	  and order_item_refund_id is null
group by DATEPART(quarter,order_creation_time),year(order_creation_time)
order by years,quarter_no

--organic search(quarter_wise) 

 select DATEPART(quarter,order_creation_time) as quarter_no,year(order_creation_time) as years,
        count(distinct order_id) as total_orders,
        sum(Revenue) as total_revenue from table_1 as t
 join website_sessions as w
 on t.website_session_id=w.website_session_id
 and
    t.[user_id]=w.[user_id]
where  utm_content ='null'
      and  cast(order_creation_time as date)>='2012-04-01'
	   and order_item_refund_id is null
group by DATEPART(quarter,order_creation_time),year(order_creation_time)
order by years,quarter_no


--direct type-in(quarter_wise)

 select DATEPART(quarter,order_creation_time) as quarter_no,year(order_creation_time) as years,
        count(distinct order_id) as total_orders,
        sum(Revenue)as total_revenue from table_1 as t
 join website_sessions as w
 on t.website_session_id=w.website_session_id
 and
    t.[user_id]=w.[user_id]
where http_referer ='null'
      and  cast(order_creation_time as date)>='2012-04-01'
	  and order_item_refund_id is null
group by DATEPART(quarter,order_creation_time),year(order_creation_time)
order by years,quarter_no


/* Next, let’s show the overall session-to-order conversion rate trends for those same channels,
   by quarter. Please also make a note of 
   any periods where we made major improvements or optimizations.*/

 --G search nonbrand  session-to-order conversion rate (quarter_wise)

with orders as(
    SELECT datepart(quarter,order_creation_time) as quarter_no,
      datepart(year,order_creation_time) as years,
      count(distinct order_id) as total_orders  
	from table_1 as t
	join website_sessions as w
	on t.website_session_id=w.website_session_id
	 and t.[user_id]=w.[user_id]
	where utm_source='gsearch' and utm_campaign='nonbrand' and
	cast(order_creation_time as date)>='2012-04-01'
	and order_item_refund_id is  null
	group by datepart(quarter,order_creation_time),datepart(year,order_creation_time)),

	web_sessions as(
	select datepart(quarter,created_at) as quarter_no,
      datepart(year,created_at) as years,
	  count(distinct website_session_id) as total_session
	from website_sessions
	where utm_source='gsearch' and utm_campaign='nonbrand' and
	     cast(created_at as date)>='2012-04-01'
	group by datepart(quarter,created_at),datepart(year,created_at))

	select w.quarter_no,w.years,total_session,total_orders,
	       total_orders*100.00/total_session as conversion_rate
	from web_sessions as w
	join orders as o
	on w.years=o.years
	and    w.quarter_no=o.quarter_no
	order by w.years,w.quarter_no

--B search nonbrand session to order conversion rate (quarter_wise) 


with orders as(
    SELECT datepart(quarter,order_creation_time) as quarter_no,
      datepart(year,order_creation_time) as years,
      count(distinct order_id) as total_orders  
	from table_1 as t
	join website_sessions as w
	on t.website_session_id=w.website_session_id
	 and t.[user_id]=w.[user_id]
	where utm_source='bsearch' and utm_campaign='nonbrand' and
	cast(order_creation_time as date)>='2012-04-01'
	and order_item_refund_id is  null
	group by datepart(quarter,order_creation_time),datepart(year,order_creation_time)),

	web_sessions as(
	select datepart(quarter,created_at) as quarter_no,
      datepart(year,created_at) as years,
	  count(distinct website_session_id) as total_session
	from website_sessions
	where utm_source='bsearch' and utm_campaign='nonbrand' and
	     cast(created_at as date)>='2012-04-01'
	group by datepart(quarter,created_at),datepart(year,created_at))

	select w.quarter_no,w.years,total_session,total_orders,
	       total_orders*100.00/total_session as conversion_rate
	from web_sessions as w
	join orders as o
	on w.years=o.years
	and    w.quarter_no=o.quarter_no
	order by w.years,w.quarter_no

--organic search session to order conversion rate (quarter_wise)

with orders as(
    SELECT datepart(quarter,order_creation_time) as quarter_no,
      datepart(year,order_creation_time) as years,
      count(distinct order_id) as total_orders  
	from table_1 as t
	join website_sessions as w
	on t.website_session_id=w.website_session_id
	 and t.[user_id]=w.[user_id]
	where  utm_content='null' and http_referer!='null' and
	cast(order_creation_time as date)>='2012-04-01'
	and order_item_refund_id is  null
	group by datepart(quarter,order_creation_time),datepart(year,order_creation_time)),

	web_sessions as(
	select datepart(quarter,created_at) as quarter_no,
      datepart(year,created_at) as years,
	  count(distinct website_session_id) as total_session
	from website_sessions
	where utm_content='null' and http_referer!='null' and
	     cast(created_at as date)>='2012-04-01'
	group by datepart(quarter,created_at),datepart(year,created_at))

	select w.quarter_no,w.years,total_session,total_orders,
	       total_orders*100.00/total_session as conversion_rate
	from web_sessions as w
	join orders as o
	on w.years=o.years
	and    w.quarter_no=o.quarter_no
	order by w.years,w.quarter_no

--direct type-in search session to order conversion rate (quarter_wise) 

 with orders as(
    SELECT datepart(quarter,order_creation_time) as quarter_no,
      datepart(year,order_creation_time) as years,
      count(distinct order_id) as total_orders  
	from table_1 as t
	join website_sessions as w
	on t.website_session_id=w.website_session_id
	 and t.[user_id]=w.[user_id]
	where   http_referer='null' and
	cast(order_creation_time as date)>='2012-04-01'
	and order_item_refund_id is  null
	group by datepart(quarter,order_creation_time),datepart(year,order_creation_time)),

	web_sessions as(
	select datepart(quarter,created_at) as quarter_no,
      datepart(year,created_at) as years,
	  count(distinct website_session_id) as total_session
	from website_sessions
	where http_referer='null' and
	     cast(created_at as date)>='2012-04-01'
	group by datepart(quarter,created_at),datepart(year,created_at))

	select w.quarter_no,w.years,total_session,total_orders,
	       total_orders*100.00/total_session as conversion_rate
	from web_sessions as w
	join orders as o
	on w.years=o.years
	and    w.quarter_no=o.quarter_no
	order by w.years,w.quarter_no



--brand search overall session to order conversion rate (quarter_wise) 


with orders as(
    SELECT datepart(quarter,order_creation_time) as quarter_no,
      datepart(year,order_creation_time) as years,
      count(distinct order_id) as total_orders  
	from table_1 as t
	join website_sessions as w
	on t.website_session_id=w.website_session_id
	 and t.[user_id]=w.[user_id]
	where  utm_campaign='brand' and
	cast(order_creation_time as date)>='2012-04-01'
	and order_item_refund_id is  null
	group by datepart(quarter,order_creation_time),datepart(year,order_creation_time)),

	web_sessions as(
	select datepart(quarter,created_at) as quarter_no,
      datepart(year,created_at) as years,
	  count(distinct website_session_id) as total_session
	from website_sessions
	where utm_campaign='brand' and
	     cast(created_at as date)>='2012-04-01'
	group by datepart(quarter,created_at),datepart(year,created_at))

	select w.quarter_no,w.years,total_session,total_orders,
	       total_orders*100.00/total_session as conversion_rate
	from web_sessions as w
	join orders as o
	on w.years=o.years
	and    w.quarter_no=o.quarter_no
	order by w.years,w.quarter_no


--non-brand search overall session to order conversion rate (quarter_wise) 

 
with orders as(
    SELECT datepart(quarter,order_creation_time) as quarter_no,
      datepart(year,order_creation_time) as years,
      count(distinct order_id) as total_orders  
	from table_1 as t
	join website_sessions as w
	on t.website_session_id=w.website_session_id
	 and t.[user_id]=w.[user_id]
	where  utm_campaign='nonbrand' and
	cast(order_creation_time as date)>='2012-04-01'
	and order_item_refund_id is  null
	group by datepart(quarter,order_creation_time),datepart(year,order_creation_time)),

	web_sessions as(
	select datepart(quarter,created_at) as quarter_no,
      datepart(year,created_at) as years,
	  count(distinct website_session_id) as total_session
	from website_sessions
	where utm_campaign='nonbrand' and
	     cast(created_at as date)>='2012-04-01'
	group by datepart(quarter,created_at),datepart(year,created_at))

	select w.quarter_no,w.years,total_session,total_orders,
	       total_orders*100.00/total_session as conversion_rate
	from web_sessions as w
	join orders as o
	on w.years=o.years
	and    w.quarter_no=o.quarter_no
	order by w.years,w.quarter_no



/* We’ve come a long way since the days of selling a single product.
   Let’s pull monthly trending for revenue and margin by product, 
   along with total sales and revenue. Note anything you notice about seasonality.*/

   ---------Product wise trend analysis and impact of new product launch --------


  select month(order_creation_time) as months,year(order_creation_time) as years,
          product_id,product_name,count(items_purchased) as total_sales,
		 (sum(price_usd)-sum(refund_amount_usd)) as total_revenue,
		 (sum(price_usd)- sum(refund_amount_usd) - sum(cogs_usd)) as margin
		 
  from table_1
  where  cast(order_creation_time as date)>='2012-04-01'
  and order_item_refund_id is null
  group by month(order_creation_time) ,year(order_creation_time),product_id,product_name
  order by product_id,product_name, years,months


  ---seasonality by month--

  ---sales, revenue & margin monthly seasonality -----

  select month(order_creation_time) as months,datename(month,order_creation_time)as month_name,
         count(items_purchased) as total_sales,
		 (sum(price_usd)-sum(refund_amount_usd)) as total_revenue,
		 (sum(price_usd)- sum(refund_amount_usd) - sum(cogs_usd)) as margin
		 
  from table_1
  where  cast(order_creation_time as date)>='2012-04-01'
  and order_item_refund_id is null
  group by month(order_creation_time) ,datename(month,order_creation_time)
  order by months

---------
 ---customer, visitor & session monthly seasonality -----


    select month(created_at) as months,datename(month,created_at)as month_name,
         count(distinct t.[user_id]) as total_customers,
		 count(distinct w.[user_id]) as total_visitors,
		 count(distinct w.website_session_id) as total_sessions
		 
  from website_sessions as w
  left join table_1 as t
  on w.website_session_id=t.website_session_id
   and w.[user_id]=t.[user_id]
  where  cast(created_at as date)>='2012-04-01'
  group by month(created_at) ,datename(month,created_at)
  order by months


--seasonality by quarter--

----sales volume, revenue & margin quarterly seasonality 

    select datepart(quarter,order_creation_time) as quarters,
         sum(items_purchased) as total_sales,
		 (sum(price_usd)-sum(refund_amount_usd)) as total_revenue,
		 (sum(price_usd)- sum(refund_amount_usd) - sum(cogs_usd)) as margin
		 
  from table_1
  where  cast(order_creation_time as date)>='2012-04-01'
  and order_item_refund_id is null
  group by datepart(quarter,order_creation_time) 
  order by quarters

  --------
  ----customer, total visitor & total session quarterly seasonality 
      select datepart(quarter,created_at) as quarters,
         count(distinct t.[user_id]) as total_customers,
		 count(distinct w.[user_id]) as total_visitors,
		 count(distinct w.website_session_id) as total_sessions
		 
  from website_sessions as w
  left join table_1 as t
  on w.website_session_id=t.website_session_id
    and w.[user_id]=t.[user_id]
  where  cast(created_at as date)>='2012-04-01'
  group by datepart(quarter,created_at)
  order by quarters


----seasonality by day of week-----

--sales volume, revenue & margin 

    select datename(weekday,created_at) as [day], DATEPART(weekday, created_at) AS day_of_week,
         sum(items_purchased) as total_sales,
		 (sum(price_usd)-sum(refund_amount_usd)) as total_revenue,
		 (sum(price_usd)- sum(refund_amount_usd) - sum(cogs_usd)) as margin		 
		 
  from website_sessions as w
  left join table_1 as t
  on w.website_session_id=t.website_session_id
    and w.[user_id]=t.[user_id]
	Where order_item_refund_id is null
  group by datename(weekday,created_at),DATEPART(weekday, created_at)
  order by day_of_week
  -----------------------
  ---customer, total visitors, total session 

     select datename(weekday,created_at) as [day], DATEPART(weekday, created_at) AS day_of_week,
         count(distinct t.[user_id]) as total_customers,
		 count(distinct w.[user_id]) as total_visitors,
		 count(distinct w.website_session_id) as total_sessions
		 
  from website_sessions as w
  left join table_1 as t
  on w.website_session_id=t.website_session_id
    and w.[user_id]=t.[user_id]
  group by datename(weekday,created_at),DATEPART(weekday, created_at)
  order by day_of_week

---------------
 
 

 

/* Let’s dive deeper into the impact of introducing new products. Please pull monthly
   sessions to the /products page, and show how 
   the % of those sessions clicking through another page has changed over time, 
   along with a view of how conversion from /products 
   to placing an order has improved.*/

   --click through analysis 


WITH CTE1 AS (
    SELECT 
        MONTH(created_at) AS months,
        YEAR(created_at) AS years,
        COUNT(website_pageview_id) AS count_of_product_pageview
    FROM website_pageviews AS wp
    WHERE CAST(created_at AS date) >= '2012-04-01'
      AND wp.pageview_url = '/products'
    GROUP BY MONTH(created_at), YEAR(created_at)
),


CTE2 AS (
    SELECT 
        MONTH(wp.created_at) AS months,
        YEAR(wp.created_at) AS years,
        COUNT(wp.website_pageview_id) AS click_through_next_page
    FROM website_pageviews AS wp
    WHERE wp.pageview_url IN (
        '/the-original-mr-fuzzy',
        '/The-Birthday-Sugar-Panda',
        '/The-Forever-Love-Bear',
        '/The-Hudson-River-Mini-bear'
    )
    GROUP BY MONTH(wp.created_at), YEAR(wp.created_at)
),


CTE3 AS (
    SELECT 
        MONTH(wp.created_at) AS months,
        YEAR(wp.created_at) AS years,
        COUNT(wp.website_pageview_id) AS final_order_made
    FROM website_pageviews AS wp
    WHERE wp.pageview_url = '/thank-you-for-your-order'
    GROUP BY MONTH(wp.created_at), YEAR(wp.created_at)
)


SELECT 
    CTE1.years,
    CTE1.months,
    CTE1.count_of_product_pageview,
    CTE2.click_through_next_page AS click_through_next_page,
	100*CTE2.click_through_next_page/CTE1.count_of_product_pageview as percentage_click_through_next_page,
    CTE3.final_order_made AS final_order_made,
	100*CTE3.final_order_made/CTE1.count_of_product_pageview as percentage_final_order_made
FROM 
    CTE1
LEFT JOIN 
    CTE2 ON CTE1.months = CTE2.months AND CTE1.years = CTE2.years
LEFT JOIN 
    CTE3 ON CTE1.months = CTE3.months AND CTE1.years = CTE3.years
ORDER BY 
    CTE1.years, CTE1.months


---------------------------------------------**---------------------------------------------------

--Cross selling and Brand awarness analysis

/*We made our 4th product available as a primary product
   on December 5, 2014 (it was previously only a cross-sell item). 
Could you please pull sales data since then, and show how well each product 
cross-sells from one another?*/ 

--(

select p1.product_id primary_product_id,
p1.product_name primary_product_name,
p2.product_id cross_selling_product_id,
p2.product_name cross_selling_product_name,
count(distinct p1.order_id) as cross_selling_count
from table_1 p1
join table_1 p2
on p1.order_id=p2.order_id
and p1.product_id<>p2.product_id
and  p1.order_item_refund_id is null																	  ---products with different ids but with same order id get mapped
where p1.order_creation_time >='2014-12-05'                           --- only filtered for date which greater or equal to 2014-12-05
and p1.is_primary_item=1                                              --- only for primary item
group by p1.product_id,p1.product_name,p2.product_id,p2.product_name

----------------------------------------------------------

/*Gsearch seems to be the biggest driver of our business.
Could you pull monthly trends for Gsearch sessions and orders 
so that we can showcase the growth there?*/

--(

select concat(year(created_at),'-',DATEPART(month,created_at)) as year_month,
        count(distinct w.website_session_id) as total_sessions,
        count(distinct order_id) as total_orders from website_sessions as w 
 left join table_1 as t
 on t.website_session_id=w.website_session_id
 and
    t.[user_id]=w.[user_id]
and  t.order_item_refund_id is null
where utm_source='gsearch' 
     and  cast(created_at as date)>='2012-04-01'
group by DATEPART(month,created_at) ,year(created_at)
order by year(created_at),DATEPART(month,created_at)

-------------------------------------------------------------

/*Next, it would be great to see a similar monthly trend for Gsearch, 
but this time splitting out nonbrand and brand campaigns separately. 
I am wondering if brand is picking up at all. If so, this is a good story to tell.*/

--g-search brand vs non-brand analysis 

select concat(year(b.created_at),'-',right('0'+ cast(month(b.created_at) as varchar(2)),2))Month_Year,
count(distinct a.order_id) count_of_orders,
count(distinct b.website_session_id) count_of_website_session,
count(distinct a.order_id)*100.00/count(distinct b.website_session_id) conversion_rate,
b.utm_campaign
from website_sessions as b
left join table_1 a
on a.user_id=b.user_id
and a.website_session_id=b.website_session_id
and  a.order_item_refund_id is null
where b.utm_source='gsearch'
group by  month(b.created_at),year(b.created_at) ,b.utm_campaign
order by  year(b.created_at),month(b.created_at)


-----------------------------------------------------------
/*While we're on Gsearch, could you dive into nonbrand, and pull monthly sessions and orders 
split by device type? 
I want to flex our analytical muscles a little and show the board we really know 
our traffic sources.*/

--

select  concat(year(b.created_at),'-',right('0'+ cast(month(b.created_at) as varchar(2)),2))Month_Year,
count(DISTINCT a.order_id) count_of_orders,
count(distinct b.website_session_id) count_of_website_session,b.device_type
from website_sessions as b
left join table_1 a
on a.user_id=b.user_id
and a.website_session_id=b.website_session_id
and  a.order_item_refund_id is null
where b.utm_source='gsearch' and utm_campaign='nonbrand'
group by month(b.created_at),year(b.created_at),b.device_type
order by year(b.created_at),month(b.created_at)

-------------------------------------------------------------

-------------------------------------------------**------------------------------------------------

--Billing page and Landing page analysis



/* For the gsearch lander test, please estimate the revenue that test earned us 
  (Hint: Look at the increase in CVR from 
  the test (Jun 19 – Jul 28), and use nonbrand sessions and revenue since then to 
  calculate incremental value) */

--G search lander test from May 10 to Jun 18 and Jun 19 to Jul 28 in 2012  

--For (Jun 19 – Jul 28)
SELECT COUNT(A.website_session_id) AS After_Sessions,
       COUNT(B.order_id) AS After_Order,
	   SUM(B.revenue) AS After_Revenue,
	   (COUNT(B.order_id)*100.0/COUNT(A.website_session_id)) AS After_Conversion_Rate FROM website_sessions AS A
LEFT JOIN 
         table_1 AS B
		 ON A.website_session_id = B.website_session_id
WHERE A.utm_source = 'gsearch' AND A.utm_campaign = 'nonbrand' AND
     A.created_at > = '2012-06-19' AND A.created_at < = '2012-07-28'

--For (May 10 – Jun 18)
SELECT COUNT(A.website_session_id) AS Before_Sessions,
       COUNT(B.order_id) AS Before_Order,
	   SUM(B.revenue) AS Before_Revenue,
	   (COUNT(B.order_id)*100.0/COUNT(A.website_session_id)) AS Before_Conversion_Rate FROM website_sessions AS A
LEFT JOIN 
         table_1 AS B
		 ON A.website_session_id = B.website_session_id
WHERE A.utm_source = 'gsearch' AND A.utm_campaign = 'nonbrand' AND
     A.created_at > = '2012-05-10' AND A.created_at < = '2012-06-18'

-------------------------------------------------------------------

/*  For the landing page test you analyzed previously, it would be great to show
    a full conversion funnel from each of 
    the two pages to orders. You can use the same time period you analyzed
	last time (Jun 19 – Jul 28).*/

--Conversion Funnel for landing page

WITH flagged_sessions AS ( 

  SELECT 

    s.website_session_id, 

    MAX(CASE WHEN p.pageview_url = '/home' THEN 1 ELSE 0 END) AS saw_homepage, 

    MAX(CASE WHEN p.pageview_url = '/lander-1' THEN 1 ELSE 0 END) AS saw_custom_lander, 

    MAX(CASE WHEN p.pageview_url = '/products' THEN 1 ELSE 0 END) AS product_made_it, 

    MAX(CASE WHEN p.pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END) AS mrfuzzy_page_made_it, 

    MAX(CASE WHEN p.pageview_url = '/cart' THEN 1 ELSE 0 END) AS cart_page_made_it, 

    MAX(CASE WHEN p.pageview_url = '/shipping' THEN 1 ELSE 0 END) AS shipping_page_made_it, 

    MAX(CASE WHEN p.pageview_url = '/billing' THEN 1 ELSE 0 END) AS billing_page_made_it, 

    MAX(CASE WHEN p.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END) AS thankyou_page_made_it 

  FROM website_sessions s 

  LEFT JOIN website_pageviews p 

    ON s.website_session_id = p.website_session_id 

  WHERE s.utm_source = 'gsearch' 

    AND s.utm_campaign = 'nonbrand' 

    AND s.created_at BETWEEN '2012-06-19' AND '2012-07-28' 

  GROUP BY s.website_session_id 

), 

--  Group sessions by landing page and calculate conversion funnel metrics 

conversion_funnel AS ( 

  SELECT 

    CASE  

      WHEN saw_homepage = 1 THEN 'saw_homepage' 

      WHEN saw_custom_lander = 1 THEN 'saw_custom_lander' 

      ELSE 'check logic'  

    END AS segment, 

    COUNT(DISTINCT website_session_id) AS sessions, 

    COUNT(DISTINCT CASE WHEN product_made_it = 1 THEN website_session_id ELSE NULL END) AS to_products, 

    COUNT(DISTINCT CASE WHEN mrfuzzy_page_made_it = 1 THEN website_session_id ELSE NULL END) AS to_mrfuzzy, 

    COUNT(DISTINCT CASE WHEN cart_page_made_it = 1 THEN website_session_id ELSE NULL END) AS to_cart, 

    COUNT(DISTINCT CASE WHEN shipping_page_made_it = 1 THEN website_session_id ELSE NULL END) AS to_shipping, 

    COUNT(DISTINCT CASE WHEN billing_page_made_it = 1 THEN website_session_id ELSE NULL END) AS to_billing, 

    COUNT(DISTINCT CASE WHEN thankyou_page_made_it = 1 THEN website_session_id ELSE NULL END) AS to_thankyou 

  FROM flagged_sessions 

  GROUP BY  

    CASE  

      WHEN saw_homepage = 1 THEN 'saw_homepage' 

      WHEN saw_custom_lander = 1 THEN 'saw_custom_lander' 

      ELSE 'check logic'  

    END 

) 

--Calculate click-through rates 

SELECT 

  segment, 

  sessions, 

  ROUND(100.0 * to_products / sessions, 2) AS product_click_rt, 

  ROUND(100.0 * to_mrfuzzy / sessions, 2) AS mrfuzzy_click_rt, 

  ROUND(100.0 * to_cart / sessions, 2) AS cart_click_rt, 

  ROUND(100.0 * to_shipping / sessions, 2) AS shipping_click_rt, 

  ROUND(100.0 * to_billing / sessions, 2) AS billing_click_rt, 

  ROUND(100.0 * to_thankyou / sessions, 2) AS thankyou_click_rt 

FROM conversion_funnel; 

----------------------------------------------------------

/* Impact of the Billing Test on Revenue and Session Metrics */



WITH BillingData AS (
    SELECT 
        wp.pageview_url,
        t1.website_session_id,
        t1.order_creation_time,
        t1.Revenue
    FROM 
        website_pageviews wp
    JOIN 
        table_1 t1 ON wp.website_session_id = t1.website_session_id
    WHERE 
        wp.pageview_url IN ('/billing', '/billing-2')
),
BeforePeriod AS (
    SELECT 
        pageview_url,
        COUNT(DISTINCT website_session_id) AS Before_Sessions,
        SUM(Revenue) AS Before_Revenue,
        ROUND(SUM(Revenue) * 1.0 / NULLIF(COUNT(DISTINCT website_session_id), 0), 2) AS Before_Revenue_Per_Billing_Session
    FROM 
        BillingData
    WHERE 
        order_creation_time BETWEEN '2012-07-10' AND '2012-09-10'
    GROUP BY 
        pageview_url
),
AfterPeriod AS (
    SELECT 
        pageview_url,
        COUNT(DISTINCT website_session_id) AS After_Sessions,
        SUM(Revenue) AS After_Revenue,
        ROUND(SUM(Revenue) * 1.0 / NULLIF(COUNT(DISTINCT website_session_id), 0), 2) AS After_Revenue_Per_Billing_Session
    FROM 
        BillingData
    WHERE 
        order_creation_time BETWEEN '2012-09-10' AND '2012-11-10'
    GROUP BY 
        pageview_url
)
SELECT 
    a.pageview_url,
    b.Before_Sessions,
    b.Before_Revenue,
    b.Before_Revenue_Per_Billing_Session,
    a.After_Sessions,
    a.After_Revenue,
    a.After_Revenue_Per_Billing_Session
FROM 
    AfterPeriod a
LEFT JOIN 
    BeforePeriod b ON a.pageview_url = b.pageview_url

	/*  I’d like to tell the story of our website performance improvements over the course of the first 8 months. 
Could you pull session to order conversion rates, by month?*/

-

	 with cte1 as(
select DATEPART(YEAR,created_at) AS Years,
       DATEPART(MONTH,created_at) AS Months,
	   COUNT(distinct w.website_session_id) AS web_Sessions,
	   COUNT(distinct order_id) AS Orders
from website_sessions as w
left join table_1 as t
on w.website_session_id=t.website_session_id
  and order_item_refund_id is null
  group by DATEPART(YEAR,created_at),DATEPART(MONTH,created_at)) 
  select top 8 years,months,Orders,web_Sessions,Orders*100.00/web_sessions as conversion_rate
  from cte1
  order by years,months

---------------------------------------------------**-----------------------------------------------
---------------------------------------------------**-----------------------------------------------

--** Traffic Source Analysis **

/* Understanding where the customers are coming from and which channels are 
driving the highest quality traffic */

 --Find the no. of visits (website session) in different Traffic Sources

 select utm_source,count(distinct website_session_id) as total_session
 from website_sessions
 group by utm_source
 order by total_session desc

--Unique Visitors (slide no. 87)

 select utm_source,count(distinct [user_id]) as total_unique_visitor
 from website_sessions
 group by utm_source

 --new vs repeat visitors (slide no. 87)

select utm_source,count(distinct [USER_ID]) as new_visitors
from website_sessions
where is_repeat_session=0
group by utm_source

select utm_source,count(distinct [USER_ID]) as repeat_visitors
from website_sessions
where is_repeat_session=1
group by utm_source

-------------------------------------------------------------------
/* Looking at conversion rate (CVR) which is the percentage of the traffic that 
converts into sales or revenue activity ( Traffic Source Conversion Rates)*/

-- conversion rate

select utm_source,count(distinct web_session) as total_session,
                  count(distinct orders) as total_order,
				  count(distinct orders)*100.00/count(distinct web_session) as convertion_rate
from(
select w.website_session_id as web_session,t.website_session_id as orders,
        utm_source from website_sessions as w
left join table_1 as t
on w.website_session_id=t.website_session_id
 and w.[user_id]=t.[user_id]
 and order_item_refund_id is null) as x
 group by utm_source

 --Pageviews

 select utm_source,count(distinct website_pageview_id ) as total_pageview
 from table_2
 group by utm_source

 
--Pages per Session 

 select utm_source,count(distinct website_session_id) as total_sessions,
                   count( distinct website_pageview_id) as total_pages,
    count( distinct website_pageview_id)*1.00/count(distinct website_session_id) as Pages_per_Session 
 from table_2
 group by utm_source

 --Average session duration 

 select utm_source, sum(session_duration) as total_session_duration,
 count(distinct website_session_id) as total_sessions,
 sum(session_duration)/count(distinct website_session_id) as avg_session_duration_seconds
 from(
 select utm_source, website_session_id, min(webpage_creation_time) as start_time,
 max(webpage_creation_time) as end_time, 
 datediff(SECOND, min(webpage_creation_time), max(webpage_creation_time)) as session_duration
 from table_2
 group by utm_source, website_session_id
  )as x
  group by utm_source


  --Bounce rate 

with CTE1 as (select utm_source, website_session_id as single_page_session_id
               from table_2
			   group by utm_source, website_session_id
			   having count(pageview_url)=1)
select t.utm_source, count(single_page_session_id) as single_page_session,
count(distinct website_session_id) as total_sessions,
count(single_page_session_id)*100.00/count(distinct website_session_id) as bounce_rate
from table_2 as T
left join CTE1 as C
on single_page_session_id=website_session_id
and c.utm_source=t.utm_source
group by t.utm_source

--traffic source wise total customers, orders, revenue 

select utm_source,count(distinct [user_id]) as total_customer,
            count(distinct order_id) as total_order,
			SUM(revenue) as total_revenue
from(
select order_id, t.user_id,revenue, utm_source from table_1 as t
join website_sessions as w
on t.website_session_id=w.website_session_id
and t.[user_id]=w.[user_id]
and order_item_refund_id is null) as x
group by utm_source


--Traffic Source Trending (quarter_wise) 

 select utm_source,DATEPART(quarter,created_at) as quarter_no,year(created_at) as years,
        count(distinct w.website_session_id) as total_sessions,
        count(distinct order_id) as total_orders,
        count(distinct order_id)*100.00/ count(distinct w.website_session_id) as convertion_rate,
		count(distinct w.[user_id]) as total_user
		from website_sessions as w
 left join 
 table_1 as t
 on t.website_session_id=w.website_session_id
 and
    t.[user_id]=w.[user_id]
	and order_item_refund_id is null
where   cast(created_at as date)>='2012-04-01'
group by utm_source,DATEPART(quarter,created_at),year(created_at)
order by years,quarter_no

----------------

--Traffic Source Trending (month_wise) 

 select utm_source,month(created_at) as month_no,year(created_at) as years,
        count(distinct w.website_session_id) as total_sessions,
        count(distinct order_id) as total_orders,
        count(distinct order_id)*100/ count(distinct w.website_session_id) as convertion_rate,
		count(distinct w.[user_id]) as total_user
		from website_sessions as w
 left join 
 table_1 as t
 on t.website_session_id=w.website_session_id
 and
    t.[user_id]=w.[user_id]
	and order_item_refund_id is null
where   cast(created_at as date)>='2012-04-01'
group by utm_source,month(created_at),year(created_at)
order by years,month_no

-------------------------------------------------------

--For pitch for funding

--traffic source wise quarterly total visitor, total customer, total order, total revenue

select utm_source,datepart(quarter,created_at) as quarters,year(created_at) as years,
count(distinct w.[user_id]) as total_visitor,count(distinct t.[user_id]) as total_customer,
count(distinct order_id) as total_order,sum(revenue) as total_revenue,
sum(revenue)-sum(cogs_usd) as margin
from website_sessions as w
left join table_1 as t
on w.website_session_id=t.website_session_id
and w.[user_id]=t.[user_id]
and order_item_refund_id is null
where cast(created_at as date) >= '2012-04-01'
group by utm_source,datepart(quarter,created_at) ,year(created_at)
order by years,quarters

----------------------------------------------------**----------------------------------------------
----------------------------------------------------**----------------------------------------------

--** Website Performance Analysis **


/*Identify the most common landing page and the first thing a user sees.*/



SELECT --TOP 1
    wp.pageview_url AS landing_page,
    COUNT(wp.website_pageview_id) AS views
FROM 
    website_pageviews wp
JOIN 
    website_sessions ws ON wp.website_session_id = ws.website_session_id
WHERE 
    wp.created_at = (SELECT MIN(created_at) 
                     FROM website_pageviews 
                     WHERE website_session_id = ws.website_session_id)
GROUP BY 
    wp.pageview_url
ORDER BY 
    views DESC;

------------------------------------------------------------------

/* For most viewed pages and common landing pages, understand how those pages perform
   for business objectives.*/


with cte1 as(
SELECT 
    wp.pageview_url AS pages,
    COUNT(distinct t.order_id) AS total_orders,
    SUM(revenue) AS revenue
FROM 
    website_pageviews wp
LEFT JOIN 
    website_sessions ws ON wp.website_session_id = ws.website_session_id
LEFT JOIN 
    table_1 t ON ws.website_session_id = t.website_session_id
	where order_item_refund_id is null
GROUP BY 
    wp.pageview_url),cte2 as
	( select pageview_url AS pages,
    COUNT(distinct website_pageview_id) AS total_views
	from website_pageviews 
	group by pageview_url)
	select c1.pages,total_views,total_orders,revenue
	from cte1 as c1
	join cte2 as c2 
	on c1.pages=c2.pages
ORDER BY 
    total_views DESC, revenue DESC

----------------------------------------------------------------

--Analyzing Bounce Rates & Landing Page Tests.



WITH LandingPageViews AS (
    -- Get the landing page for each session
    SELECT 
        ws.website_session_id,
        MIN(wp.created_at) AS first_pageview_time,
        wp.pageview_url AS landing_page
    FROM 
        website_pageviews wp
    JOIN 
        website_sessions ws ON wp.website_session_id = ws.website_session_id
    GROUP BY 
        ws.website_session_id, wp.pageview_url
),
SessionPageCounts AS (
    -- Count total pageviews per session
    SELECT 
        ws.website_session_id,
        COUNT(wp.website_pageview_id) AS total_pageviews
    FROM 
        website_pageviews wp
    JOIN 
        website_sessions ws ON wp.website_session_id = ws.website_session_id
    GROUP BY 
        ws.website_session_id
),
BounceAnalysis AS (
    -- Combine landing page info with session page counts
    SELECT 
        lp.landing_page,
        COUNT(DISTINCT lp.website_session_id) AS total_sessions,
        COUNT(DISTINCT CASE WHEN spc.total_pageviews = 1 THEN lp.website_session_id END) AS bounces
    FROM 
        LandingPageViews lp
    JOIN 
        SessionPageCounts spc ON lp.website_session_id = spc.website_session_id
    GROUP BY 
        lp.landing_page
)
SELECT 
    landing_page,
    total_sessions,
    bounces,
    ROUND((bounces * 1.0 / total_sessions) * 100, 2) AS bounce_rate
FROM 
    BounceAnalysis
ORDER BY 
    bounce_rate DESC

---------------------------------------------------------------

/* Understanding the pattern and effect of website pages on customer orders making changes
    to the website pages and pushing 
    maximum products to customer orders.*/

WITH PageConversion AS (
    SELECT 
        wp.pageview_url AS pages,
        ws.website_session_id,
        COUNT(DISTINCT t.order_id) AS orders_count,
        count(t.items_purchased) AS total_items_purchased,
        SUM(revenue) AS total_revenue_generated
    FROM 
        website_pageviews wp
    JOIN 
        website_sessions ws ON wp.website_session_id = ws.website_session_id
    LEFT JOIN 
       table_1 as t  ON ws.website_session_id = t.website_session_id
	   and order_item_refund_id is null
    GROUP BY 
        wp.pageview_url, ws.website_session_id
),
PagePerformance AS (
    SELECT 
        pages,
        COUNT(DISTINCT website_session_id) AS session_count,
        SUM(orders_count) AS total_orders,
        SUM(total_items_purchased) AS total_items_purchased,
        ROUND((SUM(total_items_purchased) * 1.0 / COUNT(DISTINCT website_session_id)), 2) AS avg_items_per_session,
        ROUND((SUM(total_revenue_generated) * 1.0 / COUNT(DISTINCT website_session_id)), 2) AS avg_revenue_per_session
    FROM 
        PageConversion
    GROUP BY 
        pages
)
SELECT 
    pages,
    session_count,
    total_orders,
    total_items_purchased,
    avg_items_per_session,
    avg_revenue_per_session
FROM 
    PagePerformance
ORDER BY 
    total_orders DESC, avg_items_per_session DESC


-------------------------------------------------**-----------------------------------------------
-------------------------------------------------**-----------------------------------------------

--** Channel Portfolio **


/*1.Understanding which marketing channels are driving the most sessions and orders
through your website.*/



select 
case 
when b.utm_source != 'N/A' and b.utm_campaign! = 'N/A' and b.utm_content !='N/A'  then 'Paid_search'
when b.http_referer = 'N/A' then 'Direct search'
when b.http_referer !='N/A'  and b.utm_source = 'N/A' and b.utm_campaign = 'N/A' and b.utm_content ='N/A' then 'Organic search'
else 'others'
end as marketing_channels,
count(distinct a.order_id) count_of_orders,
count(distinct b.website_session_id) count_of_websessions,
count(distinct a.order_id)*100.00/count(distinct b.website_session_id) conversion_rate
from table_1 a
right join table_2 b
on a.user_id=b.user_id
and a.website_session_id=b.website_session_id
and a.order_item_refund_id is null
group by case 
when b.utm_source != 'N/A' and b.utm_campaign! = 'N/A' and b.utm_content !='N/A'  then 'Paid_search'
when b.http_referer = 'N/A' then 'Direct search'
when b.http_referer !='N/A'  and b.utm_source = 'N/A' and b.utm_campaign = 'N/A' and b.utm_content ='N/A' then 'Organic search'
else 'others' end
order by count_of_orders desc,count_of_websessions desc

---------------------------------------------------------------------
/*2.Understanding differences in user characteristics and conversion performance 
across marketing channels.*/



select case 
when b.utm_source != 'N/A' and b.utm_campaign! = 'N/A' and b.utm_content !='N/A'  then 'Paid_search'
when b.http_referer = 'N/A' then 'Direct search'
when b.http_referer !='N/A'  and b.utm_source = 'N/A' and b.utm_campaign = 'N/A' and b.utm_content ='N/A' then 'Organic search'
else 'others'
end as marketing_channel,
count(DISTINCT a.order_id) as count_of_orders,
count(distinct b.website_session_id) as count_of_sessions,
round((count(DISTINCT a.order_id)*1.0/count(distinct b.website_session_id))* 100,2) Conversion_rate,
SUM(CASE WHEN B.PAGEVIEW_URL='/thank-you-for-your-order' THEN A.REVENUE END)/count(distinct a.order_id) as avg_order_value,
b.device_type,
count(distinct case when a.order_id is not null then b.user_id end) as unique_buyer,
count(distinct b.user_id) as unique_user,
round(count(distinct case when a.order_id is not null then b.user_id end)*1.0/count(distinct b.user_id)*100 ,2)Buyers_percent
from table_1 a
right join table_2 b
on a.user_id=b.user_id
and a.website_session_id=b.website_session_id
and a.order_item_refund_id is null
group by case 
when b.utm_source != 'N/A' and b.utm_campaign! = 'N/A' and b.utm_content !='N/A'  then 'Paid_search'
when b.http_referer = 'N/A' then 'Direct search'
when b.http_referer !='N/A'  and b.utm_source = 'N/A' and b.utm_campaign = 'N/A' and b.utm_content ='N/A' then 'Organic search'
else 'others'
end , b.device_type
order by Conversion_rate desc

-----------------------------------------------------------------

/*Analyzing channel portfolios*/


select case
when b.utm_source != 'N/A' and b.utm_campaign! = 'N/A' and b.utm_content !='N/A'  then 'Paid_search'
when b.http_referer = 'N/A' then 'Direct search'
when b.http_referer !='N/A'  and b.utm_source = 'N/A' and b.utm_campaign = 'N/A' and b.utm_content ='N/A' then 'Organic search'
else 'others'
end
as Channel,
count(distinct a.order_id)as count_of_orders,
count(distinct b.website_session_id) as count_of_websessions,
SUM(CASE WHEN B.PAGEVIEW_URL='/thank-you-for-your-order' THEN A.REVENUE END) as total_revenue,
(SUM(CASE WHEN B.PAGEVIEW_URL='/thank-you-for-your-order' THEN A.REVENUE END)/count(distinct a.order_id)) as avg_order_value
--avg(case when a.revenue>0 then a.revenue else null end) as avg_order_value
from table_1 a
right join table_2 b
on a.user_id=b.user_id
and a.website_session_id=b.website_session_id
and a.order_item_refund_id is null
group by case
when b.utm_source != 'N/A' and b.utm_campaign! = 'N/A' and b.utm_content !='N/A'  then 'Paid_search'
when b.http_referer = 'N/A' then 'Direct search'
when b.http_referer !='N/A'  and b.utm_source = 'N/A' and b.utm_campaign = 'N/A' and b.utm_content ='N/A' then 'Organic search'
else 'others'
end
order by total_revenue desc


------------------------------------------------
/*Cross-Channel bid Optimization*/



select 
case
when b.utm_source != 'N/A' and b.utm_campaign! = 'N/A' and b.utm_content !='N/A'  then 'Paid_search'
when b.http_referer = 'N/A' then 'Direct search'
when b.http_referer !='N/A'  and b.utm_source = 'N/A' and b.utm_campaign = 'N/A' and b.utm_content ='N/A' then 'Organic search'
else 'others'
end as channel,
count(b.website_session_id) count_of_sessions,
count(distinct a.order_id) count_of_orders,
SUM(CASE WHEN B.PAGEVIEW_URL='/thank-you-for-your-order' THEN A.REVENUE END) as total_revenue,
sum(CASE WHEN B.PAGEVIEW_URL='/thank-you-for-your-order' then (price_usd-cogs_usd) end)profit_margin,
sum(CASE WHEN B.PAGEVIEW_URL='/thank-you-for-your-order' THEN A.REVENUE END)/count( b.website_session_id) revenue_per_session,
--sum(case when refund_amount_usd is null then a.revenue else a.revenue-a.refund_amount_usd end)/count(distinct b.website_session_id) revenue_per_session,
(SUM(CASE WHEN B.PAGEVIEW_URL='/thank-you-for-your-order' THEN A.REVENUE END)/count(distinct a.order_id)) as avg_order_value
from table_1 a
right join table_2 b
on a.user_id=b.user_id
and a.website_session_id=b.website_session_id
and a.order_item_refund_id is null
group by case
when b.utm_source != 'N/A' and b.utm_campaign! = 'N/A' and b.utm_content !='N/A'  then 'Paid_search'
when b.http_referer = 'N/A' then 'Direct search'
when b.http_referer !='N/A'  and b.utm_source = 'N/A' and b.utm_campaign = 'N/A' and b.utm_content ='N/A' then 'Organic search'
else 'others'
end
order by revenue_per_session desc;

/*Analyzing Channel Portfolio Trends*/


select concat(year(b.session_creation_time),'-',month(b.session_creation_time)) as Year_month,
case
when b.utm_source != 'N/A' and b.utm_campaign! = 'N/A' and b.utm_content !='N/A'  then 'Paid_search'
when b.http_referer = 'N/A' then 'Direct search'
when b.http_referer !='N/A'  and b.utm_source = 'N/A' and b.utm_campaign = 'N/A' and b.utm_content ='N/A' then 'Organic search'
else 'others'
end as channel,
count(distinct a.order_id) as count_of_orders,
count( b.website_session_id) as count_of_websessions,
SUM(CASE WHEN B.PAGEVIEW_URL='/thank-you-for-your-order' THEN A.REVENUE END) as total_revenue
from table_1 a
right join table_2 b
on a.user_id=b.user_id
and a.website_session_id=b.website_session_id
and a.order_item_refund_id is null
group by year(b.session_creation_time),month(b.session_creation_time),
case
when b.utm_source != 'N/A' and b.utm_campaign! = 'N/A' and b.utm_content !='N/A'  then 'Paid_search'
when b.http_referer = 'N/A' then 'Direct search'
when b.http_referer !='N/A'  and b.utm_source = 'N/A' and b.utm_campaign = 'N/A' and b.utm_content ='N/A' then 'Organic search'
else 'others'
end
order by year(b.session_creation_time),month(b.session_creation_time)

--select count( website_session_id) from table_2
--where website_session_id in (select website_session_id from table_1)


/*Analyzing Direct,Broad-Driven Traffic*/



select 
case
when b.http_referer = 'N/A' then 'Direct search'
else 'Broad-Driven Traffic'
end channels,
count(distinct b.website_session_id) count_of_sessions,
count(distinct a.order_id) count_of_orders,
SUM(CASE WHEN B.PAGEVIEW_URL='/thank-you-for-your-order' THEN A.REVENUE END) as total_revenue,
sum(case WHEN B.PAGEVIEW_URL='/thank-you-for-your-order' then (price_usd-cogs_usd) end)profit_margin,
count(distinct a.order_id)*1.0/count(distinct b.website_session_id) *100 conversion_rate
from table_1 a
right join table_2 b
on a.user_id=b.user_id
and a.website_session_id=b.website_session_id
AND a.order_item_refund_id is null
group by 
case
when b.http_referer = 'N/A' then 'Direct search'
else 'Broad-Driven Traffic'
end

----------------------------------------------------**--------------------------------------------
----------------------------------------------------**--------------------------------------------

--** Product Analysis **--

/*1.Analysing product sales & product launches*/



select product_name,
min(product_creation_time) as product_launch_date,
count(DISTINCT order_id) count_of_orders,
sum(revenue) total_revenue 
from table_1 
where order_item_refund_id is null
group by product_name
order by total_revenue desc

--slide 115-118 - code is available in trend & seasonality section

---------------------------------------------------------------------
/*3.Cross-selling & product portfolio analysis*/



with orderproducts as(
select a.order_id,
a.user_id,
a.product_name
from table_1 a
where a.order_item_refund_id is null
),
productpair as(
select op1.order_id,
op1.product_name as product_1,
op2.product_name as product_2                ----max items purchased are only 2 so we are having only 2 combinations
from orderproducts op1
join orderproducts op2
on op1.order_id=op2.order_id
and op1.product_name<op2.product_name
)
select 
pp.product_1,
pp.product_2,
count(distinct pp.order_id) as cross_sell_orders,
sum(a.revenue) as cross_sell_revenue
from productpair pp
join table_1 a
on pp.order_id=a.order_id
where a.order_item_refund_id is null
group by pp.product_1,pp.product_2
order by cross_sell_revenue desc


-----product portfolio analysis---------------------------------

----total revenue and quantity sold-----------------



select 
product_id,
product_name,
count(distinct order_item_id) total_quantity_sold,
sum(revenue) as total_revenue,
avg(revenue) as avg_revenue
from table_1 
where order_item_refund_id is null
group by product_id,product_name
order by total_revenue desc



---page views leading to purchase-------


WITH purchase_views AS (
    SELECT 
        pv.user_id,
        pv.website_session_id,
        pv.pageview_url,
        o.product_id,
        o.product_name,
        COUNT(DISTINCT pv.website_pageview_id) AS total_pageviews
    FROM 
        table_2 pv
    LEFT JOIN 
        table_1 o ON pv.user_id = o.user_id AND pv.website_session_id = o.website_session_id AND o.order_item_refund_id is null
    GROUP BY 
        pv.user_id, pv.website_session_id, pv.pageview_url, o.product_id, o.product_name
)

SELECT 
    product_id,
    product_name,
    COUNT(DISTINCT user_id) AS unique_users,
    SUM(total_pageviews) AS total_pageviews,
    COUNT(DISTINCT website_session_id) AS sessions_with_views
FROM 
    purchase_views
WHERE 
    product_id IS NOT NULL  -- Ensures we only count products that were purchased
GROUP BY 
    product_id, product_name
ORDER BY 
    total_pageviews DESC;


---profit margin----------------------- 


select 
product_id,
product_name,
sum(price_usd-cogs_usd) as total_profit,
sum(revenue) as total_revenue,
sum(price_usd-cogs_usd)/sum(revenue)*100 as profit_margin_Percentage
from table_1
where order_item_refund_id is null   ----considering only orders which are not refunded
group by product_id,product_name
order by profit_margin_Percentage desc

---------------------------------------------------------------

/*4.Analysing product refund rates.*/



select 
product_name,
count(order_item_refund_id) as count_of_refund_orders,
count(case when order_item_refund_id is null then order_id else 0 end) total_orders,
count(order_item_refund_id)*1.0/count(case when order_item_refund_id is null then order_id else 0 end)*100 as Return_rate,
sum(refund_amount_usd) as total_refund_amount,
sum(case when order_item_refund_id is null then revenue else 0 end) as total_revenue,
sum(refund_amount_usd)*1.0/sum(case when order_item_refund_id is null then revenue else 0 end)*100 refund_percent
from table_1
group by product_name
order by refund_percent desc

--------------------------------------------------------------

/*6.Identify the most and least viewed pages by the customer to make creative decisions on 
the enhancement of the pages.*/



select 
pageview_url,
count(distinct user_id) count_of_users
from table_2
group by pageview_url
order by count_of_users desc


/*2.Analysing product-level website pathing & conversion funnels.*/


WITH a AS (
        SELECT 
        b.user_id,
        b.website_session_id,
        b.pageview_url,
        ROW_NUMBER() OVER (PARTITION BY b.user_id, b.website_session_id ORDER BY b.webpage_creation_time ASC) AS rn
    FROM table_2 b
),
journey AS (
    SELECT 
        user_id,
        website_session_id,
        pageview_url,
        LEAD(pageview_url) OVER (PARTITION BY user_id, website_session_id ORDER BY rn) AS page1,
        LEAD(pageview_url, 2) OVER (PARTITION BY user_id, website_session_id ORDER BY rn) AS page2,
        LEAD(pageview_url, 3) OVER (PARTITION BY user_id, website_session_id ORDER BY rn) AS page3,
        LEAD(pageview_url, 4) OVER (PARTITION BY user_id, website_session_id ORDER BY rn) AS page4,
		LEAD(pageview_url, 5) OVER (PARTITION BY user_id, website_session_id ORDER BY rn) AS page5,
		LEAD(pageview_url, 6) OVER (PARTITION BY user_id, website_session_id ORDER BY rn) AS page6
    FROM a
)
select * into #journey from journey
drop table #journey


--------------------------------------------
SELECT 
    'The original mr fuzzy' as product_name,
	COUNT(CASE WHEN pageview_url = '/home' AND page1 = '/products'  then 1 end) as Home_to_products,
	COUNT(CASE WHEN pageview_url = '/home' AND page1 = '/products' AND page2='/the-original-mr-fuzzy'  then 1 end) as Home_to_products_to_the_specific_product,
	COUNT(CASE WHEN pageview_url = '/home' AND page1 = '/products' AND page2='/the-original-mr-fuzzy' and page3 = '/cart' then 1 end) as home_to_cart,
	COUNT(CASE WHEN pageview_url = '/home' AND page1 = '/products' AND page2='/the-original-mr-fuzzy' and page3 = '/cart'
               AND page4 = '/shipping'  then 1 end) as home_to_shipping,
	COUNT(CASE WHEN pageview_url = '/home' AND page1 = '/products' AND page2='/the-original-mr-fuzzy' and page3 = '/cart'
               AND page4 = '/shipping' AND page5 like '/billing%'  then 1 end) as home_to_billing,
    COUNT(CASE WHEN pageview_url = '/home'  AND page1 = '/products' AND page2='/the-original-mr-fuzzy' and page3 = '/cart'
               AND page4 = '/shipping' AND page5 like '/billing%' and page6 = '/thank-you-for-your-order' THEN 1 END) AS LandPage_to_Checkout
	
FROM #journey

union all

SELECT 
    'The forever lover bear' as product_name,
	COUNT(CASE WHEN pageview_url = '/home' AND page1 = '/products'  then 1 end) as Home_to_products,
	COUNT(CASE WHEN pageview_url = '/home' AND page1 = '/products' AND page2='/the-forever-love-bear'  then 1 end) as Home_to_products_to_the_forever_love_bear,
	COUNT(CASE WHEN pageview_url = '/home' AND page1 = '/products' AND page2='/the-forever-love-bear' and page3 = '/cart'  then 1 end) as home_to_cart,
	COUNT(CASE WHEN pageview_url = '/home' AND page1 = '/products' AND page2='/the-forever-love-bear' and page3 = '/cart'
               AND page4 = '/shipping'  then 1 end) as home_to_shipping,
	COUNT(CASE WHEN pageview_url = '/home' AND page1 = '/products' AND page2='/the-forever-love-bear' and page3 = '/cart'
               AND page4 = '/shipping' AND page5 like '/billing%'  then 1 end) as home_to_billing,
    COUNT(CASE WHEN pageview_url = '/home' AND page1 = '/products' AND page2='/the-forever-love-bear' and page3 = '/cart'
               AND page4 = '/shipping' AND page5 like '/billing%' and page6 = '/thank-you-for-your-order' THEN 1 END) AS home_to_Checkout
FROM #journey

union all

SELECT 
    'The birthday sugar panda' as product_name,
	COUNT(CASE WHEN pageview_url = '/home' AND page1 = '/products'  then 1 end) as Home_to_products,
	COUNT(CASE WHEN pageview_url = '/home' AND page1 = '/products' AND page2='/the-birthday-sugar-panda'  then 1 end) as Home_to_products_to_the_birthday_sugar_panda,
	COUNT(CASE WHEN pageview_url = '/home' AND page1 = '/products' AND page2='/the-birthday-sugar-panda' and page3 = '/cart'  then 1 end) as home_to_cart,
	COUNT(CASE WHEN pageview_url = '/home' AND page1 = '/products' AND page2='/the-birthday-sugar-panda' and page3 = '/cart'
               AND page4 = '/shipping'  then 1 end) as home_to_shipping,
	COUNT(CASE WHEN pageview_url = '/home' AND page1 = '/products' AND page2='/the-birthday-sugar-panda' and page3 = '/cart'
               AND page4 = '/shipping' AND page5 like '/billing%'  then 1 end) as home_to_billing,
	COUNT(CASE WHEN pageview_url = '/home' AND page1 = '/products' AND page2='/the-birthday-sugar-panda' and page3 = '/cart'
               AND page4 = '/shipping' AND page5 like '/billing%' and page6 ='/thank-you-for-your-order' then 1 end) as lander_to_checkout  
FROM #journey

union all

SELECT 
    'The Hudson river mini bear' as product_name,
	COUNT(CASE WHEN pageview_url = '/home' AND page1 = '/products'  then 1 end) as Home_to_products,
	COUNT(CASE WHEN pageview_url = '/home' AND page1 = '/products' AND page2='/the-hudson-river-mini-bear'  then 1 end) as Home_to_products_to_the_hudson_river,
	COUNT(CASE WHEN pageview_url = '/home' AND page1 = '/products' AND page2='/the-hudson-river-mini-bear' and page3 = '/cart'  then 1 end) as home_to_cart,
	COUNT(CASE WHEN pageview_url = '/home' AND page1 = '/products' AND page2='/the-hudson-river-mini-bear' and page3 = '/cart'
               AND page4 = '/shipping'  then 1 end) as home_to_shipping,
	COUNT(CASE WHEN pageview_url = '/home' AND page1 = '/products' AND page2='/the-hudson-river-mini-bear' and page3 = '/cart'
               AND page4 = '/shipping' AND page5 like '/billing%'  then 1 end) as home_to_billing,
	COUNT(CASE WHEN pageview_url = '/home' AND page1 = '/products' AND page2='/the-hudson-river-mini-bear' and page3 = '/cart'
               AND page4 = '/shipping' AND page5 like '/billing%' and page6 = '/thank-you-for-your-order' THEN 1 END) AS LandPage_to_Checkout

FROM #journey;

------------------------------------------------------

SELECT 
    'The original mr fuzzy' as product_name,
	COUNT(CASE WHEN pageview_url like '/lander-%' AND page1 = '/products'  then 1 end) as lander_to_products,
	COUNT(CASE WHEN pageview_url like '/lander-%' AND page1 = '/products' AND page2='/the-original-mr-fuzzy'  then 1 end) as lander_to_products_to_the_original_mr_fuzzy,
	COUNT(CASE WHEN pageview_url like '/lander-%' AND page1 = '/products' AND page2='/the-original-mr-fuzzy' and page3 = '/cart'  then 1 end) as lander_to_cart,
	COUNT(CASE WHEN pageview_url like '/lander-%' AND page1 = '/products' AND page2='/the-original-mr-fuzzy' and page3 = '/cart'
               AND page4 = '/shipping'  then 1 end) as lander_to_shipping,
	COUNT(CASE WHEN pageview_url like '/lander-%' AND page1 = '/products' AND page2='/the-original-mr-fuzzy' and page3 = '/cart'
               AND page4 = '/shipping' AND page5 like '/billing%'  then 1 end) as lander_to_billing,
	COUNT(CASE WHEN pageview_url like '/lander-%' AND page1 = '/products' AND page2='/the-original-mr-fuzzy' and page3 = '/cart'
               AND page4 = '/shipping' AND page5 like '/billing%' and page6 = '/thank-you-for-your-order' THEN 1 END) AS LandPage_to_Checkout
FROM #journey

union all

SELECT 
    'The forever lover bear' as product_name,
	COUNT(CASE WHEN pageview_url like '/lander-%' AND page1 = '/products'  then 1 end) as lander_to_products,
	COUNT(CASE WHEN pageview_url like '/lander-%' AND page1 = '/products' AND page2='/the-forever-love-bear'  then 1 end) as lander_to_products_to_the_forever_love_bear,
	COUNT(CASE WHEN pageview_url like '/lander-%' AND page1 = '/products' AND page2='/the-forever-love-bear' and page3 = '/cart'  then 1 end) as lander_to_cart,
	COUNT(CASE WHEN pageview_url like '/lander-%' AND page1 = '/products' AND page2='/the-forever-love-bear' and page3 = '/cart'
               AND page4 = '/shipping'  then 1 end) as lander_to_shipping,
	COUNT(CASE WHEN pageview_url like '/lander-%' AND page1 = '/products' AND page2='/the-forever-love-bear' and page3 = '/cart'
               AND page4 = '/shipping' AND page5 like '/billing%'  then 1 end) as lander_to_billing,
	COUNT(CASE WHEN pageview_url like '/lander-%' AND page1 = '/products' AND page2='/the-forever-love-bear' and page3 = '/cart'
               AND page4 = '/shipping' AND page5 like '/billing%' and page6='/thank-you-for-your-order' THEN 1 END) AS lander_to_checkout

FROM #journey

union all

SELECT 
    'The birthday sugar panda' as product_name,
	COUNT(CASE WHEN pageview_url like '/lander-%' AND page1 = '/products'  then 1 end) as lander_to_products,
	COUNT(CASE WHEN pageview_url like '/lander-%' AND page1 = '/products' AND page2='/the-birthday-sugar-panda'  then 1 end) as lander_to_products_to_the_birthday_sugar_panda,
	COUNT(CASE WHEN pageview_url like '/lander-%' AND page1 = '/products' AND page2='/the-birthday-sugar-panda' and page3 = '/cart'  then 1 end) as lander_to_cart,
	COUNT(CASE WHEN pageview_url like '/lander-%' AND page1 = '/products' AND page2='/the-birthday-sugar-panda' and page3 = '/cart'
               AND page4 = '/shipping'  then 1 end) as lander_to_shipping,
	COUNT(CASE WHEN pageview_url like '/lander-%' AND page1 = '/products' AND page2='/the-birthday-sugar-panda' and page3 = '/cart'
               AND page4 = '/shipping' AND page5 like '/billing%'  then 1 end) as lander_to_billing,
	COUNT(CASE WHEN pageview_url like '/lander-%' AND page1 = '/products' AND page2='/the-birthday-sugar-panda' and page3 = '/cart'
               AND page4 = '/shipping' AND page5 like '/billing%' and page6 = '/thank-you-for-your-order' THEN 1 END) AS LandPage_to_Checkout
FROM #journey

union all

SELECT 
    'The Hudson river mini bear' as product_name,
	COUNT(CASE WHEN pageview_url like '/lander-%' AND page1 = '/products'  then 1 end) as lander_to_products,
	COUNT(CASE WHEN pageview_url like '/lander-%' AND page1 = '/products' AND page2='/the-hudson-river-mini-bear'  then 1 end) as lander_to_products_to_the_hudson_river,
	COUNT(CASE WHEN pageview_url like '/lander-%' AND page1 = '/products' AND page2='/the-hudson-river-mini-bear' and page3 = '/cart'  then 1 end) as lander_to_cart,
	COUNT(CASE WHEN pageview_url like '/lander-%' AND page1 = '/products' AND page2='/the-hudson-river-mini-bear' and page3 = '/cart'
               AND page4 = '/shipping'  then 1 end) as lander_to_shipping,
	COUNT(CASE WHEN pageview_url like '/lander-%' AND page1 = '/products' AND page2='/the-hudson-river-mini-bear' and page3 = '/cart'
               AND page4 = '/shipping' AND page5 like '/billing%'  then 1 end) as lander_to_billing,
	COUNT(CASE WHEN pageview_url like '/lander-%' AND page1 = '/products' AND page2='/the-hudson-river-mini-bear' and page3 = '/cart'
               AND page4 = '/shipping' AND page5 like '/billing%' and page6 = '/thank-you-for-your-order' THEN 1 END) AS LandPage_to_Checkout
FROM #journey;


----------------------------------------------------------------------------------------
/*7.Analyzing the conversion funnels of customers to identify the most common path customers,
the before purchasing products(from landing page to sale) and lower bounce rate.*/



SELECT 
    'The original mr fuzzy' as product_name,
	COUNT(CASE WHEN pageview_url = '/home' AND page1 = '/products' AND page2='/the-original-mr-fuzzy' and page3 = '/cart'
               AND page4 = '/shipping' AND page5 like '/billing%' and page6 = '/thank-you-for-your-order'  then 1 end) as home_to_Checkout,
    COUNT(CASE WHEN pageview_url = '/lander-1'  AND page1 = '/products' AND page2='/the-original-mr-fuzzy' and page3 = '/cart'
               AND page4 = '/shipping' AND page5 like '/billing%' and page6 = '/thank-you-for-your-order' THEN 1 END) AS Lander1_to_Checkout,
	COUNT(CASE WHEN pageview_url = '/lander-2'  AND page1 = '/products' AND page2='/the-original-mr-fuzzy' and page3 = '/cart'
               AND page4 = '/shipping' AND page5 like '/billing%' and page6 = '/thank-you-for-your-order' THEN 1 END) AS Lander2_to_Checkout,
	COUNT(CASE WHEN pageview_url = '/lander-3'  AND page1 = '/products' AND page2='/the-original-mr-fuzzy' and page3 = '/cart'
               AND page4 = '/shipping' AND page5 like '/billing%' and page6 = '/thank-you-for-your-order' THEN 1 END) AS Lander3_to_Checkout,
	COUNT(CASE WHEN pageview_url = '/lander-4'  AND page1 = '/products' AND page2='/the-original-mr-fuzzy' and page3 = '/cart'
               AND page4 = '/shipping' AND page5 like '/billing%' and page6 = '/thank-you-for-your-order' THEN 1 END) AS Lander4_to_Checkout,
	COUNT(CASE WHEN pageview_url = '/lander-5'  AND page1 = '/products' AND page2='/the-original-mr-fuzzy' and page3 = '/cart'
               AND page4 = '/shipping' AND page5 like '/billing%' and page6 = '/thank-you-for-your-order' THEN 1 END) AS Lander5_to_Checkout

from #journey

union all

SELECT 
    'The forever lover bear' as product_name,
	COUNT(CASE WHEN pageview_url = '/home' AND page1 = '/products' AND page2='/the-forever-love-bear' and page3 = '/cart'
               AND page4 = '/shipping' AND page5 like '/billing%' and page6 = '/thank-you-for-your-order'  then 1 end) as home_to_Checkout,
    COUNT(CASE WHEN pageview_url = '/lander-1'  AND page1 = '/products' AND page2='/the-forever-love-bear' and page3 = '/cart'
               AND page4 = '/shipping' AND page5 like '/billing%' and page6 = '/thank-you-for-your-order' THEN 1 END) AS Lander1_to_Checkout,
	COUNT(CASE WHEN pageview_url = '/lander-2'  AND page1 = '/products' AND page2='/the-forever-love-bear' and page3 = '/cart'
               AND page4 = '/shipping' AND page5 like '/billing%' and page6 = '/thank-you-for-your-order' THEN 1 END) AS Lander2_to_Checkout,
	COUNT(CASE WHEN pageview_url = '/lander-3'  AND page1 = '/products' AND page2='/the-forever-love-bear' and page3 = '/cart'
               AND page4 = '/shipping' AND page5 like '/billing%' and page6 = '/thank-you-for-your-order' THEN 1 END) AS Lander3_to_Checkout,
	COUNT(CASE WHEN pageview_url = '/lander-4'  AND page1 = '/products' AND page2='/the-forever-love-bear' and page3 = '/cart'
               AND page4 = '/shipping' AND page5 like '/billing%' and page6 = '/thank-you-for-your-order' THEN 1 END) AS Lander4_to_Checkout,
	COUNT(CASE WHEN pageview_url = '/lander-5'  AND page1 = '/products' AND page2='/the-forever-love-bear' and page3 = '/cart'
               AND page4 = '/shipping' AND page5 like '/billing%' and page6 = '/thank-you-for-your-order' THEN 1 END) AS Lander5_to_Checkout

from #journey

union all

SELECT 
    'The birthday sugar panda' as product_name,
	COUNT(CASE WHEN pageview_url = '/home' AND page1 = '/products' AND page2='/the-birthday-sugar-panda' and page3 = '/cart'
               AND page4 = '/shipping' AND page5 like '/billing%' and page6 = '/thank-you-for-your-order'  then 1 end) as home_to_Checkout,
    COUNT(CASE WHEN pageview_url = '/lander-1'  AND page1 = '/products' AND page2='/the-birthday-sugar-panda' and page3 = '/cart'
               AND page4 = '/shipping' AND page5 like '/billing%' and page6 = '/thank-you-for-your-order' THEN 1 END) AS Lander1_to_Checkout,
	COUNT(CASE WHEN pageview_url = '/lander-2'  AND page1 = '/products' AND page2='/the-birthday-sugar-panda' and page3 = '/cart'
               AND page4 = '/shipping' AND page5 like '/billing%' and page6 = '/thank-you-for-your-order' THEN 1 END) AS Lander2_to_Checkout,
	COUNT(CASE WHEN pageview_url = '/lander-3'  AND page1 = '/products' AND page2='/the-birthday-sugar-panda' and page3 = '/cart'
               AND page4 = '/shipping' AND page5 like '/billing%' and page6 = '/thank-you-for-your-order' THEN 1 END) AS Lander3_to_Checkout,
	COUNT(CASE WHEN pageview_url = '/lander-4'  AND page1 = '/products' AND page2='/the-birthday-sugar-panda' and page3 = '/cart'
               AND page4 = '/shipping' AND page5 like '/billing%' and page6 = '/thank-you-for-your-order' THEN 1 END) AS Lander4_to_Checkout,
	COUNT(CASE WHEN pageview_url = '/lander-5'  AND page1 = '/products' AND page2='/the-birthday-sugar-panda' and page3 = '/cart'
               AND page4 = '/shipping' AND page5 like '/billing%' and page6 = '/thank-you-for-your-order' THEN 1 END) AS Lander5_to_Checkout

from #journey

union all

SELECT 
    'The hudson river mini bear' as product_name,
	COUNT(CASE WHEN pageview_url = '/home' AND page1 = '/products' AND page2='/the-hudson-river-mini-bear' and page3 = '/cart'
               AND page4 = '/shipping' AND page5 like '/billing%' and page6 = '/thank-you-for-your-order'  then 1 end) as home_to_Checkout,
    COUNT(CASE WHEN pageview_url = '/lander-1'  AND page1 = '/products' AND page2='/the-hudson-river-mini-bear' and page3 = '/cart'
               AND page4 = '/shipping' AND page5 like '/billing%' and page6 = '/thank-you-for-your-order' THEN 1 END) AS Lander1_to_Checkout,
	COUNT(CASE WHEN pageview_url = '/lander-2'  AND page1 = '/products' AND page2='/the-hudson-river-mini-bear' and page3 = '/cart'
               AND page4 = '/shipping' AND page5 like '/billing%' and page6 = '/thank-you-for-your-order' THEN 1 END) AS Lander2_to_Checkout,
	COUNT(CASE WHEN pageview_url = '/lander-3'  AND page1 = '/products' AND page2='/the-hudson-river-mini-bear' and page3 = '/cart'
               AND page4 = '/shipping' AND page5 like '/billing%' and page6 = '/thank-you-for-your-order' THEN 1 END) AS Lander3_to_Checkout,
	COUNT(CASE WHEN pageview_url = '/lander-4'  AND page1 = '/products' AND page2='/the-hudson-river-mini-bear' and page3 = '/cart'
               AND page4 = '/shipping' AND page5 like '/billing%' and page6 = '/thank-you-for-your-order' THEN 1 END) AS Lander4_to_Checkout,
	COUNT(CASE WHEN pageview_url = '/lander-5'  AND page1 = '/products' AND page2='/the-hudson-river-mini-bear' and page3 = '/cart'
               AND page4 = '/shipping' AND page5 like '/billing%' and page6 = '/thank-you-for-your-order' THEN 1 END) AS Lander5_to_Checkout

from #journey



---------------------------------------------**---------------------------------------------------
---------------------------------------------**---------------------------------------------------

--** User Analysis **


/* Analyzing Users Repeat Visit (identifying repeat visitors, analysing repeat behaviour)*/



--Identification of Repeat Visitors

select distinct [user_id],count(distinct website_session_id) as total_visits from table_2
group by [user_id] 
having count(distinct website_session_id)>1 

--Identification of one_time Visitors

select distinct [user_id],count(distinct website_session_id) as total_visits from table_2
group by [user_id] 
having count(distinct website_session_id)=1


--calculate the percentage of repeat visitors compared to new visitors

select *,no_of_visitors*100.00/sum(no_of_visitors)over() as perct
from(
select 'repeat_visitors' as visitors,count([user_id]) as no_of_visitors
from(
select [user_id],count(distinct website_session_id) as total_visits from table_2
group by [user_id] 
having count(distinct website_session_id)>1) as x
union
select 'one_time_visitors' as visitors,count([user_id])over() as no_of_visitors
from(
select  [user_id],count(distinct website_session_id) as total_visits from table_2
group by [user_id] 
having count(distinct website_session_id)=1) as y) as z


--Average session duration for one_time visitors


WITH OnetimeVisitors AS (
    
    SELECT 
        distinct [user_id]
    FROM 
        table_2
		group by [user_id]
		having count(distinct website_session_id)=1

),session_duration as


(SELECT 
    t.[user_id], 
    t.website_session_id, 
    MIN(t.webpage_creation_time) AS session_start_time,
    MAX(t.webpage_creation_time) AS session_end_time,
	datediff(second, min(t.webpage_creation_time),MAX(t.webpage_creation_time))as session_duration
FROM 
    table_2 as t
JOIN 
    OnetimeVisitors as o ON t.[user_id] = o.[user_id]
GROUP BY 
    t.[user_id], 
    t.website_session_id
)select sum(session_duration) as total_session_duration,
count(website_session_id) as total_session,
sum(session_duration)/count(website_session_id) as avg_session_duration_in_seconds
from session_duration

--Average session duration for repeat visitors

WITH RepeatVisitors AS (
   
    SELECT 
        distinct [user_id]
    FROM 
        table_2
		group by [user_id]
		having count(distinct website_session_id)>1

),session_duration as


(SELECT 
    t.[user_id], 
    t.website_session_id, 
    MIN(t.webpage_creation_time) AS session_start_time,
    MAX(t.webpage_creation_time) AS session_end_time,
	datediff(second, min(t.webpage_creation_time),MAX(t.webpage_creation_time))as session_duration
FROM 
    table_2 as t
JOIN 
    RepeatVisitors as r ON t.[user_id] = r.[user_id]
GROUP BY 
    t.[user_id], 
    t.website_session_id
)select sum(session_duration) as total_session_duration,
count(website_session_id) as total_session,
sum(session_duration)/count(website_session_id) as avg_session_duration_in_seconds
from session_duration

--first time visit vs Repeat visit conversion rate (slide no. 136)

select sum(total_user) as total_user, sum(total_customer) as total_customer,
sum(total_orders) as total_orders, sum(total_session) as total_session,
sum(total_orders)*100.00/sum(total_session) as conversion_rate
from(
select count(distinct w.[user_id]) as total_user,count(distinct t.[user_id]) as total_customer,
      count(distinct order_id) as total_orders,
	  count(distinct w.website_session_id) as total_session,
	  count(distinct order_id)*100.00/count(distinct w.website_session_id)  as conversion_rate
	  from website_sessions as w
left join table_1 as t
on w.website_session_id=t.website_session_id
 and w.[user_id]=t.[user_id]
 and order_item_refund_id is null
 group by w.[user_id]
having count(distinct w.website_session_id)>1) as x

 union
select sum(total_user) as total_user, sum(total_customer) as total_customer,
sum(total_orders) as total_orders, sum(total_session) as total_session,
sum(total_orders)*100.00/sum(total_session) as conversion_rate
from(
 select count(distinct w.[user_id]) as total_user,count(distinct t.[user_id]) as total_customer,
      count(distinct order_id) as total_orders,
	  count(distinct w.website_session_id) as total_session,
	  count(distinct order_id)*100.00/count(distinct w.website_session_id)  as conversion_rate
	  from website_sessions as w
left join table_1 as t
on w.website_session_id=t.website_session_id
 and w.[user_id]=t.[user_id]
 and order_item_refund_id is null
 group by w.[user_id]
 having count(distinct w.website_session_id)=1) as y

 -----------------------------------------------------------



--One_time vs Repeated customers 

--Repeat customer percentage

SELECT CAST((COUNT(REPEATED_CUSTOMERS)*100.00)/(SELECT COUNT(DISTINCT [user_ID])FROM table_1
             where order_item_refund_id is null) AS FLOAT)
FROM(
SELECT [user_id] AS REPEATED_CUSTOMERS,COUNT(DISTINCT ORDER_ID) AS DISTINCT_ORDER_COUNT
FROM table_1
where order_item_refund_id is null
GROUP BY [user_id]
HAVING COUNT(DISTINCT ORDER_ID)>1 
)
AS X



--One time buyers percentage

SELECT CAST((COUNT(ONETIME_CUSTOMERS)*100.00)/(SELECT COUNT(DISTINCT [user_ID])FROM table_1
          where order_item_refund_id is null) AS FLOAT)
FROM(
SELECT [user_id] AS ONETIME_CUSTOMERS,COUNT(DISTINCT ORDER_ID) AS DISTINCT_ORDER_COUNT
FROM table_1
where order_item_refund_id is null
GROUP BY [user_id]
HAVING COUNT(DISTINCT ORDER_ID)=1 
)
AS X

--Understand the behavior of one time buyers and repeat buyers

--Repeat buyers

with cte1 as(SELECT 
        [user_id]
    FROM 
        table_1
		where order_item_refund_id is null
    GROUP BY 
        [user_id]
    HAVING 
        COUNT(DISTINCT order_id) > 1 ),
cte2 as(
select c.[user_id],price_usd,cogs_usd,order_id,refund_amount_usd,case when refund_amount_usd=0
										then price_usd - cogs_usd
										else 0
									end as margin	
from 
table_1 as t
join cte1 as c
on t.[user_id]=c.[user_id]
where order_item_refund_id is null),cte3 as
(select [user_id],count(distinct order_id) as total_orders,
		 (sum(price_usd)-sum(refund_amount_usd)) as total_revenue,sum(margin) as total_margin
from cte2
group by [user_id])
select 'repeated_buyers' as types_of_customers,count([user_id]) as Total_customers,
       sum(total_orders) as total_orders,
       sum(total_revenue) as Total_revenue,avg(total_revenue) as Total_average,
	   sum(total_margin) as Total_margin
from cte3



--one_time_buyers


with cte1 as(SELECT 
        [user_id]
    FROM 
        table_1
    where order_item_refund_id is null
    GROUP BY 
        [user_id]
    HAVING 
        COUNT(DISTINCT order_id) = 1 ),
cte2 as(
select c.[user_id],order_id,price_usd,cogs_usd,refund_amount_usd,case when refund_amount_usd=0
										then price_usd - cogs_usd
										else 0
									end as margin	
from 
table_1 as t
join cte1 as c
on t.[user_id]=c.[user_id]
where order_item_refund_id is null),cte3 as
(select [user_id],count(distinct order_id) as total_orders,
		 (sum(price_usd)-sum(refund_amount_usd)) as total_revenue,sum(margin) as total_margin
from cte2
group by [user_id])
select 'one_time_buyers' as types_of_customers,count([user_id]) as Total_customers,
        sum(total_orders) as total_orders,
       sum(total_revenue) as Total_revenue,avg(total_revenue) as Total_average,
	   sum(total_margin) as Total_margin
from cte3

--------------------------------------------------------------



---------------------------------------------------------------


/*	Identify frequency and recency of visits to segment users
    by their engagement level (e.g., low, moderate, high repeat visitors) */


with cte1
as(select w.[user_id],
       count(distinct w.website_session_id) as total_sessions,
  max(w.created_at) as latest_websession_date
    from website_sessions as w
	left join table_1 as t
	on w.website_session_id=t.website_session_id 
	group by w.[user_id]
	having  count(distinct w.website_session_id) >1 
	),


 RF_BASE
AS(
SELECT distinct c.[user_ID],
DATEDIFF(DAY,latest_websession_date,dateadd(day,1,max(w.created_at)over()))
       AS DAYS_SINCE_LAST_PURCHASED,
       total_sessions from cte1 as c join website_sessions as w
	   on c.[user_id]=w.[user_id]
),

RF AS(
SELECT *,NTILE(3)OVER(ORDER BY DAYS_SINCE_LAST_PURCHASED DESC)AS RECENCY_SCORE,
        CASE WHEN 
		         total_sessions=2 
              THEN 1
			  WHEN total_sessions=3
			  THEN 2
			  ELSE 3
       END AS FREQUENCY_SCORE
	

FROM RF_BASE),

COMBINE_RF AS(

SELECT *,(RECENCY_SCORE+FREQUENCY_SCORE)AS RF_SCORE
FROM RF), 

RF_SEGMENTATION AS(
SELECT *,
         CASE WHEN 
		         RF_SCORE <=3              
				 THEN 'Low'
			  WHEN RF_SCORE >3 and RF_SCORE<=5
			  THEN 'Moderate'
			  else	 'High'
			  
         END AS RF_SEGMENT
FROM COMBINE_RF)
SELECT distinct RF_SEGMENT,COUNT([user_ID]) over(partition by RF_SEGMENT) AS TOTAL_USER 
FROM RF_SEGMENTATION
ORDER BY total_user DESC



----------------------------------------------------------------

--Investigate what pages or content repeat visitors engage with most



WITH repeat_visitors AS (
    SELECT 
        [user_id]
    FROM table_2
    GROUP BY [user_id]
    HAVING COUNT(DISTINCT website_session_id) > 1 
),
pageview as

(SELECT 
    t.[user_id],
    t.pageview_url,
    COUNT(t.website_pageview_id) AS frequency
FROM 
    table_2 AS t
JOIN 
    repeat_visitors AS rv ON t.[user_id] = rv.[user_id]  
GROUP BY 
    t.[user_id],t.pageview_url)

select pageview_url ,sum(frequency)as total_count,count([user_id]) as total_users
from  pageview
group by pageview_url


/* Assess visit sources (organic, direct, referral) to see which channels are bringing
  in repeat visitors */


  WITH repeat_visitors AS (
    SELECT 
        [user_id]
    FROM website_sessions
    GROUP BY [user_id]
    HAVING COUNT(DISTINCT website_session_id) > 1 
),
channels as
(select 'organic_search' as visit_source,count(distinct rv.[user_id]) as total_user					  
from repeat_visitors as rv
join website_sessions as w
on rv.[user_id]=w.[user_id]
where utm_content='null' and http_referer!='null'
union
select 'direct_search' as visit_source,count(distinct rv.[user_id]) as total_user					  
from repeat_visitors as rv
join website_sessions as w
on rv.[user_id]=w.[user_id]
where http_referer='null'
union
select 'paid_search' as visit_source,count(distinct rv.[user_id]) as total_user					  
from repeat_visitors as rv
join website_sessions as w
on rv.[user_id]=w.[user_id]
where utm_content!='null'
)select * from channels


----------------------------------------------------------------

----Entry page analysis for repeat visitors

WITH RepeatVisitors AS (
    --  Identify users with multiple sessions
    SELECT 
        [user_id] 
		
    FROM 
        table_2
    GROUP BY 
        [user_id]
    HAVING 
        COUNT(DISTINCT website_session_id) > 1),
website_session as (select r.[user_id], website_session_id, min(webpage_creation_time) as entry_time
from table_2 as T
join repeatvisitors as R
on T.[user_id]=R.[user_id]
group by website_session_id, r.[user_id]),
entry_page as (select t.pageview_url, count(t.[USER_ID]) as total_user
from table_2 as T
join website_session as W
on T.[user_id]=W.[user_id]
where webpage_creation_time=entry_time
group by t.pageview_url) select * from entry_page


----Entry page analysis for Onetime visitors


WITH OnetimeVisitors AS (
    --  Identify users with multiple sessions
    SELECT 
        [user_id] 
		
    FROM 
        table_2
    GROUP BY 
        [user_id]
    HAVING 
        COUNT(DISTINCT website_session_id) = 1),
website_session as (select O.[user_id], website_session_id, min(webpage_creation_time) as entry_time
from table_2 as T
join Onetimevisitors as O
on T.[user_id]=O.[user_id]
group by website_session_id, O.[user_id]),
entry_page as (select t.pageview_url, count(t.[USER_ID]) as total_user
from table_2 as T
join website_session as W
on T.[user_id]=W.[user_id]
where webpage_creation_time=entry_time
group by t.pageview_url) select * from entry_page

----------------------------------------------------------

/* Identify at which stages users drop off, especially in 
   multi-step processes (e.g., checkout, sign-up) */
   
   --Exit page analysis for repeat visitor 

   WITH cte_1 AS (
    SELECT 
        [user_id],
        website_session_id,
        pageview_url,
        webpage_creation_time AS exit_time,
        ROW_NUMBER() OVER (PARTITION BY [user_id], website_session_id ORDER BY webpage_creation_time DESC) AS rn
    FROM 
        table_2
),

cte_2 AS (
    SELECT 
        [user_id],
        website_session_id,
        exit_time,
        pageview_url
    FROM 
        cte_1
    WHERE 
        rn = 1 
)

SELECT pageview_url as exit_page,count([user_id]) as total_users 
FROM cte_2
group by pageview_url

----Exit page analysis for repeat visitors

WITH RepeatVisitors AS (
    --  Identify users with multiple sessions
    SELECT 
        [user_id] 
		
    FROM 
        table_2
    GROUP BY 
        [user_id]
    HAVING 
        COUNT(DISTINCT website_session_id) > 1),
website_session as (select r.[user_id], website_session_id, max(webpage_creation_time) as exit_time
from table_2 as T
join repeatvisitors as R
on T.[user_id]=R.[user_id]
group by website_session_id, r.[user_id]),
exit_page as (select t.pageview_url, count(t.[USER_ID]) as total_user
from table_2 as T
join website_session as W
on T.[user_id]=W.[user_id]
where webpage_creation_time=exit_time
group by t.pageview_url) select * from exit_page


----Exit page analysis for Onetime visitors


WITH OnetimeVisitors AS (
    --  Identify users with multiple sessions
    SELECT 
        [user_id] 
		
    FROM 
        table_2
    GROUP BY 
        [user_id]
    HAVING 
        COUNT(DISTINCT website_session_id) = 1),
website_session as (select O.[user_id], website_session_id, max(webpage_creation_time) as exit_time
from table_2 as T
join Onetimevisitors as O
on T.[user_id]=O.[user_id]
group by website_session_id, O.[user_id]),
exit_page as (select t.pageview_url, count(t.[USER_ID]) as total_user
from table_2 as T
join website_session as W
on T.[user_id]=W.[user_id]
where webpage_creation_time=exit_time
group by t.pageview_url) select * from exit_page

-----------------------------------------------------------------
---Visitor cohort analysis (for all website visitors)


with cohort as(
select [user_id], created_at,
       min(created_at) over(partition by [user_id]) as first_visit_date,
		DATEFROMPARTS(year(min(created_at) over(partition by [user_id])), 
		month(min(created_at) over(partition by [user_id])), 1) as cohort_date
from website_sessions), 

cohort_1 as (
select *, (month(created_at)-month(cohort_date))+
(year(created_at)-year(cohort_date))*12+1 as cohort_index from cohort)

select cohort_date, cohort_index, 
case when count(distinct [user_id])>0
then count(distinct [user_id])
else 0 end as no_of_customer from cohort_1
group by cohort_date,cohort_index
order by cohort_date

--For checking

--visitor cohort

select [USER_ID],min(session_creation_time),max(session_creation_time),
datediff(month,min(session_creation_time),max(session_creation_time)) as months
from table_2
group by [user_id]
order by months desc

---------------------------------------------------------


----Segment the customers  based on the revenue 

select  distinct segmentation,count( [user_id])over(partition by segmentation)as total_customer,
                 sum(rev)over(partition by segmentation)  as total_revenue,
 sum(rev)over(partition by segmentation)*100/sum(rev)over() as perct_contri,
        avg(rev)over(partition by segmentation) as avg_rev
from(
select *,ntile(4)over(order by rev desc) as segmentation
from(
select [user_id],sum(revenue)as rev
       from table_1 
	   group by [user_id] )as x
	   where rev>0) as y
order by total_revenue desc


---------------------------------------------------------

--RFM segmentation analysis 


with cte1
as(select [user_id],sum(revenue) as total_rev,
       count(distinct order_id) as total_orders,
  max(order_creation_time) as latest_order_date
    from table_1
	where refund_amount_usd=0
	group by [user_id]
	),


 RFM_BASE
AS(
SELECT c.[user_ID],
DATEDIFF(DAY,latest_order_date,dateadd(day,1,max(t.order_creation_time)over()))
       AS DAYS_SINCE_LAST_PURCHASED,
       total_orders, total_rev from cte1 as c join table_1 as t
	   on c.[user_id]=t.[user_id]
 
	    ),

RFM AS(
SELECT *,NTILE(3)OVER(ORDER BY DAYS_SINCE_LAST_PURCHASED DESC)AS RECENCY_SCORE,
        CASE WHEN 
		         total_orders=1 
              THEN 1
			  WHEN total_orders=2
			  THEN 2
			  ELSE 3
       END AS FREQUENCY_SCORE,
		ntile(3)over(order by total_rev ) as monetary_score

FROM RFM_BASE),

COMBINE_RFM AS(

SELECT *,(RECENCY_SCORE+FREQUENCY_SCORE+MONETARY_SCORE)AS RFM_SCORE
FROM RFM),

RFM_SEGMENTATION AS(
SELECT *,
         CASE WHEN 
		         RFM_SCORE <=5              
				 THEN 'STANDARD'
			  WHEN RFM_SCORE >5 and RFM_SCORE<=7
			  THEN 'SILVER'
			  else	 'GOLD'
			  
         END AS RFM_SEGMENT
FROM COMBINE_RFM)
SELECT distinct RFM_SEGMENT,COUNT([user_ID]) over(partition by RFM_SEGMENT) AS TOTAL_customer ,
	    CAST(SUM(total_rev) over(partition by RFM_SEGMENT) AS DECIMAL(16,2)) AS TOTAL_Revenue,
		cast(SUM(total_rev)over(partition by RFM_SEGMENT)*100/SUM(total_rev)OVER() as decimal(16,2)) as Perc_contri,
        CAST(AVG(total_rev) over(partition by RFM_SEGMENT) AS DECIMAL(12,2)) AS AVG_SALES
FROM RFM_SEGMENTATION

ORDER BY Total_Revenue DESC

-----------------------------------------------------------------------------------

--Cohort Analysis



-----Customer cohort retention analysis (those who made final order) 


with cohort as(
select [user_id], order_creation_time,
       min(order_creation_time) over(partition by [user_id]) as first_purchase_date,
		DATEFROMPARTS(year(min(order_creation_time) over(partition by [user_id])), 
		month(min(order_creation_time) over(partition by [user_id])), 1) as cohort_date
from table_1), 

cohort_1 as (
select *, (month(order_creation_time)-month(cohort_date))+
(year(order_creation_time)-year(cohort_date))*12+1 as cohort_index from cohort)

select cohort_date, cohort_index, count(distinct [user_id]) as no_of_customer from cohort_1
group by cohort_date,cohort_index
order by cohort_date

--customer cohort metrics for each cohort (slide no. 153)

with cohort as(
select [user_id], order_creation_time,price_usd,cogs_usd,refund_amount_usd,
      revenue,case when revenue=0
	               then 0
				   else revenue-cogs_usd
				   end as margin,
              case when refund_amount_usd=0
			       then 1
				   else 0
				   end as item_purchased,
min(order_creation_time) over(partition by [user_id]) as first_purchase_date,
		DATEFROMPARTS(year(min(order_creation_time) over(partition by [user_id])), 
		month(min(order_creation_time) over(partition by [user_id])), 1) as cohort_date
from table_1),
cohort_1 as ( 
select 'first month' as groups, cohort_date, count(distinct [user_id]) as customers, 
sum( revenue)  as total_revenue,
sum(item_purchased) as total_items,
sum(margin) as total_margin
from cohort
where month(order_creation_time)=month(first_purchase_date)
     and year(order_creation_time)=year(first_purchase_date)
group by cohort_date
union
select 'subsequent_month' as groups, cohort_date, count( distinct [user_id]) as customers, 
sum(revenue) as total_revenue,
sum(item_purchased) as total_items,
sum(margin) as total_margin
from cohort
where month(order_creation_time)>month(first_purchase_date) 
      or year(order_creation_time)>year(first_purchase_date)
group by cohort_date
) select * from cohort_1

--------------------------------------------------------------------------
--For checking

--customer cohort

select [USER_ID],min(created_at),max(created_at),
datediff(month,min(created_at),max(created_at)) as months
from orders
group by [user_id]
order by months desc

---------------------------------------------------------------------------

--customer churn quarterly 

With CTE1 as(
select datepart(quarter,last_quarter.created_at) as quarters,year(last_quarter.created_at) as years,
count(distinct last_quarter.[user_id]) as churned_cust
from orders as last_quarter
left join orders as this_quarter
on last_quarter.[user_id]=this_quarter.[user_id]
  and
  datediff(quarter,last_quarter.created_at,this_quarter.created_at)=1
  where this_quarter.[user_id] is null 
  group by datepart(quarter,last_quarter.created_at),year( last_quarter.created_at)),
CTE2 as(
  select datepart(quarter,created_at) as qts, year(created_at) as yrs, 
  count(distinct [user_id]) as total_cust
  from orders
  group by datepart(quarter,created_at), year(created_at))
  select *,churned_cust*100.00/total_cust as churned_rate
  from CTE1 as C1
  join CTE2 as C2
  on C1.quarters=c2.qts and c1.years=c2.yrs


 

 ---------------------------------------------------------------
 

 --Customer Lifetime Value-

With Avg_rev_per_cust as (select datepart(QUARTER, order_creation_time) as Quarters,
year(order_creation_time) as Years,
sum(price_usd - refund_amount_usd) as total_rev, count(distinct order_id) as total_ord,
sum(price_usd - refund_amount_usd)/count(distinct order_id) as avg_order_value,
count(distinct user_id) as total_cust,
count(distinct order_id)*1.00/count(distinct user_id) as avg_ord_per_cust
from table_1
where order_item_refund_id is null
group by datepart(QUARTER, order_creation_time), year(order_creation_time)
),
Churn_rate as(
select datepart(quarter,last_quarter.created_at) as quarters,year(last_quarter.created_at) as years,
count(distinct last_quarter.[user_id]) as churned_cust
from orders as last_quarter
left join orders as this_quarter
on last_quarter.[user_id]=this_quarter.[user_id]
  and
  datediff(quarter,last_quarter.created_at,this_quarter.created_at)=1
  where this_quarter.[user_id] is null 
  group by datepart(quarter,last_quarter.created_at),year( last_quarter.created_at)),
Total_users as(
  select datepart(quarter,created_at) as qts, year(created_at) as yrs, 
  count(distinct [user_id]) as total_user
  from orders
  group by datepart(quarter,created_at), year(created_at))
  select qts, yrs, avg_order_value*avg_ord_per_cust*1*100.00/(churned_cust*100.00/total_user) as CLV 
from Churn_rate as C
join Avg_rev_per_cust as R
on C.quarters=R.Quarters and C.years=R.Years
join Total_users as T
on T.qts=C.quarters and T.yrs=C.years
order by yrs, qts



--------------------------------------------**-----------------------------------------------------
--------------------------------------------**-----------------------------------------------------


--** Case specific Questions **--

--Part 1


/* Q1.1.	Finding Top Traffic Sources: What is the breakdown of sessions by UTM source, campaign,
        and referring domain up to April 12, 2012. */




select utm_source,utm_campaign,http_referer,count(distinct website_session_id) as total_sessions 
from website_sessions
where created_at <= '2012-04-12 23:59:59'
group by utm_source,utm_campaign,http_referer



/* Q2. 2.	Traffic Conversion Rates: Calculate conversion rate (CVR) from sessions to order.
            If CVR is 4% >=, then increase bids to drive volume, otherwise reduce bids.
            (Filter sessions < 2012-04-12, utm_source = gsearch and utm_campaign = nonbrand) */

-- basis for slide no. 160 

select count(distinct order_id)*100.00/count(distinct w.website_session_id) as conversion_rate,
        case when count(distinct order_id)*100.00/count(distinct w.website_session_id) >= 4
             then 'increased bids'
			 else 'reduce bids'
			 end as To_drive_volume

from  website_sessions as w
left join table_1 as t
on w.website_session_id=t.website_session_id
   and
   w.[user_id]=t.[user_id]
   and order_item_refund_id is null
where created_at < '2012-04-12' and utm_source='gsearch' and utm_campaign='nonbrand'


/* Q3.  Traffic Source Trending: After bidding down on Apr 15, 2012, what is the trend and impact
          on sessions for gsearch nonbrand campaign? Find weekly sessions before 2012-05-10. */



--after 15th april 

select datepart(week,created_at) as week_no,count(distinct website_session_id) as total_sessions
from  website_sessions 

where (created_at between  '2012-04-16' and '2012-05-09 23:59:59')
      and utm_source='gsearch' and utm_campaign='nonbrand'
group by datepart(week,created_at)
order by week_no

--conversion rate

select count(distinct order_id)*100.00/count(distinct w.website_session_id) as conversion_rate
       
from  website_sessions as w
left join table_1 as t
on w.website_session_id=t.website_session_id
   and
   w.[user_id]=t.[user_id]
     and order_item_refund_id is null
where created_at between  '2012-04-16' and '2012-05-09 23:59:59'
      and utm_source='gsearch' and utm_campaign='nonbrand'

--before 15th april

select datepart(week,created_at) as week_no,count(distinct website_session_id) as total_sessions
from  website_sessions 

where (created_at between  '2012-03-19' and '2012-04-14 23:59:59')
      and utm_source='gsearch' and utm_campaign='nonbrand'
group by datepart(week,created_at)
order by week_no

--conversion rate

select count(distinct order_id)*100.00/count(distinct w.website_session_id) as conversion_rate
       
from  website_sessions as w
left join table_1 as t
on w.website_session_id=t.website_session_id
   and
   w.[user_id]=t.[user_id]
   and order_item_refund_id is null
where created_at between  '2012-03-19' and '2012-04-14 23:59:59'
      and utm_source='gsearch' and utm_campaign='nonbrand'


/* Q4.	 Traffic Source Bid Optimization: What is the conversion rate
            from session to order by device type? */


select  device_type,utm_source,
       count(distinct order_id)*100.00/count(distinct w.website_session_id) as conversion_rate
      
from  website_sessions as w
left join table_1 as t
on w.website_session_id=t.website_session_id
   and
   w.[user_id]=t.[user_id]
  and order_item_refund_id is  null

group by device_type,utm_source



/* Q5.  Traffic Source Segment Trending: After bidding up on desktop channel
          on 2012-05-19, what is the weekly session trend for both desktop and mobile? */

--after bidding up
		  
select device_type,utm_source,
     datepart(week,created_at) as week_no,
	 count(distinct w.website_session_id) as total_sessions
from  website_sessions as w
 where cast(created_at as date) between '2012-05-20' and '2012-06-23'
 group by device_type,datepart(week,created_at),utm_source
 order by week_no

----------
-- after bidding down


select device_type,utm_source,
     datepart(week,created_at) as week_no,count(distinct w.website_session_id) as total_sessions
from  website_sessions as w
where cast(created_at as date) between '2012-04-16' and '2012-05-18' 
group by device_type,datepart(week,created_at),utm_source
order by week_no

--Q6. Analyzing Seasonality: Pull out sessions and orders by year, monthly and weekly for 2012?



select year(created_at) as years,
     count(distinct order_id) as total_orders,count(distinct w.website_session_id) as total_sessions
from  website_sessions as w
left join table_1 as t
on w.website_session_id=t.website_session_id
   and
   w.[user_id]=t.[user_id]
where year(created_at)='2012'
group by year(created_at) 


select month(created_at) as months,
     count(distinct order_id) as total_orders,count(distinct w.website_session_id) as total_sessions
from  website_sessions as w
left join table_1 as t
on w.website_session_id=t.website_session_id
   and
   w.[user_id]=t.[user_id]
where year(created_at)='2012'
group by month(created_at)
order by months


select datepart(week,created_at)as week_no,
     count(distinct order_id) as total_orders,count(distinct w.website_session_id) as total_sessions
from  website_sessions as w
left join table_1 as t
on w.website_session_id=t.website_session_id
   and
   w.[user_id]=t.[user_id]
where year(created_at)='2012'
group by datepart(week,created_at)
order by week_no


/* Q7. 	Analyzing Business Patterns: What is the average website session volume ,
categorized by hour of the day  and day of the week, 
between September 15th and November 15th ,2013, excluding holidays 
to assist in determining appropriate staffing levels for live chat support on the website? */



select datepart(hour,created_at) as [hour],count(distinct website_session_id) as total_sessions,
count(distinct website_session_id)/(datediff(day,'2013-09-15','2013-11-15')-5) as avg_session_per_hour
from website_sessions
where created_at between '2013-09-15' and '2013-11-15 23:59:59' and 
CAST(created_at AS DATE)  not in('2013-10-02','2013-10-13','2013-10-16','2013-11-03','2013-11-05')
group by datepart(hour,created_at)
order by [hour] 



select datename(weekday,created_at) as [day], DATEPART(weekday, created_at) AS day_of_week,
count(distinct website_session_id) as total_sessions,
count(distinct website_session_id)*7/(datediff(day,'2013-09-15','2013-11-15')-5) as avg_session_per_week
from website_sessions
where created_at between '2013-09-15' and '2013-11-15 23:59:59' and 
CAST(created_at AS DATE)  not in('2013-10-02','2013-10-13','2013-10-16','2013-11-03','2013-11-05')
group by datename(weekday,created_at) ,DATEPART(weekday, created_at)
order by day_of_week


/*Q8.  Identifying Repeat Visitors: Please pull data on how many of our website visitors
         come back for another session?2014 to date is good. */



--Repeat visitors
with cte1 as
(
select [USER_ID] 
from website_sessions
where cast(created_at as date) >='2014-01-01'
group by [user_id]
having count(distinct website_session_id)>1)
select count([USER_id]) as repeat_visitors
from cte1

--one time visitors

with cte1 as
(
select [USER_ID] 
from website_sessions
where cast(created_at as date) >='2014-01-01'
group by [user_id]
having count(distinct website_session_id)=1)
select count([USER_id]) as one_time_visitors
from cte1

--Repeat customers
with cte1 as
(
select [USER_ID] 
from table_1
where cast(order_creation_time as date) >='2014-01-01'
and order_item_refund_id is null
group by [user_id]
having count(distinct website_session_id)>1)
select count([USER_id]) as repeat_customers
from cte1



--Onetime customers
with cte1 as
(
select [USER_ID] 
from table_1
where cast(order_creation_time as date) >='2014-01-01'
and order_item_refund_id is null
group by [user_id]
having count(distinct website_session_id)=1)
select count([USER_id]) as one_time_customers
from cte1

/*Q9. Analyzing Repeat Behavior: What is the minimum , maximum and average time between
     the first and second session for customers who do come back?2014 to date is good.*/


	 
with cte_1 as
(
select [USER_ID] 
from website_sessions
where cast(created_at as date) >='2014-01-01'
group by [user_id]
having count(distinct website_session_id)>1), cte_2 as
(select c1.[user_id],created_at,
 ROW_NUMBER()over(partition by c1.[user_id] order by w.website_session_id) as ranks
from cte_1 as c1
join website_sessions as w
on c1.[user_id]=w.[user_id]
where cast(created_at as date) >='2014-01-01'),cte_3 as
(select [USER_ID],created_at as first_websession
from cte_2 
where ranks=1),cte_4 as
(select [USER_ID],created_at as second_websession
from cte_2 
where ranks=2),cte_5 as(select a.[user_id],first_websession,second_websession,
    datediff(day,first_websession,second_websession) as first_second_session_diff
from cte_3 as a
join cte_4 as b
on a.[user_id]=b.[user_id])select max(first_second_session_diff) as max_day,

min(first_second_session_diff) as min_day,
avg(first_second_session_diff) as avg_day
from cte_5


-------------------------------

	 
with cte_1 as
(
select [USER_ID] 
from orders
where cast(created_at as date) >='2014-01-01'
group by [user_id]
having count(distinct website_session_id)>1), cte_2 as
(select c1.[user_id],created_at,
 ROW_NUMBER()over(partition by c1.[user_id] order by o.website_session_id) as ranks
from cte_1 as c1
join orders as o
on c1.[user_id]=o.[user_id]
where cast(created_at as date) >='2014-01-01'),cte_3 as
(select [USER_ID],created_at as first_websession
from cte_2 
where ranks=1),cte_4 as
(select [USER_ID],created_at as second_websession
from cte_2 
where ranks=2),cte_5 as(select a.[user_id],first_websession,second_websession,
    datediff(day,first_websession,second_websession) as first_second_session_diff
from cte_3 as a
join cte_4 as b
on a.[user_id]=b.[user_id])select max(first_second_session_diff) as max_day,

min(first_second_session_diff) as min_day,
avg(first_second_session_diff) as avg_day
from cte_5


/* Q10.	New Vs. Repeat Channel Patterns: Analyze the channels through which repeat customers
return to our website, comparing them to new sessions? Specifically, interested in understanding
if repeat customers predominantly come through direct type-in or if there’s a significant portion
that originates from paid search ads. This analysis should cover the period 
from the beginning of 2014 to the present date.*/



--Repeat visitor
	 
with cte_1 as
(
select distinct  [USER_ID],website_session_id 
from website_sessions
where cast(created_at as date) >='2014-01-01'
   and is_repeat_session=1

),cte_2 as

(select c1.[user_id],created_at,utm_content,http_referer
from cte_1 as c1
join website_sessions as w
on c1.[user_id]=w.[user_id]
  and c1.website_session_id=w.website_session_id
where cast(created_at as date) >='2014-01-01')
select utm_content,http_referer,count([user_id]) as total_repeat_visitor from 
cte_2
group by utm_content,http_referer



--First time visitor

with cte_1 as
(
select distinct  [USER_ID],website_session_id 
from website_sessions
where cast(created_at as date) >='2014-01-01'
   and is_repeat_session=0

),cte_2 as

(select c1.[user_id],created_at,utm_content,http_referer
from cte_1 as c1
join website_sessions as w
on c1.[user_id]=w.[user_id]
  and c1.website_session_id=w.website_session_id
where cast(created_at as date) >='2014-01-01')
select utm_content,http_referer,count([user_id]) as total_new_visitor from 
cte_2
group by utm_content,http_referer


------------------------------------------------**-----------------------------------------------

--Part 2

/*1.	Analyzing Channel Portfolios: What are the weekly sessions data for both gsearch 
and bsearch from August 22nd to November 29th?*/



select 
b.utm_source,
concat(year(b.session_creation_time),'-W',datepart(weekday,b.session_creation_time)) as weekly_session,
--b.utm_source,
count(distinct a.order_id) as count_of_orders,
count(distinct b.website_session_id) as count_of_websessions
from 
table_1 a
right join table_2 b
on a.user_id=b.user_id
and a.website_session_id=b.website_session_id
and a.order_item_refund_id is null
where b.session_creation_time  between '2012-08-22 00:00:00' and '2012-11-29  23:59:59'
and b.utm_source in( 'gsearch','bsearch')
group by year(b.session_creation_time),datepart(weekday,b.session_creation_time),b.utm_source
order by year(b.session_creation_time),datepart(weekday,b.session_creation_time)



/*2.	Comparing Channel Characteristics: What are the mobile sessions data for non-brand campaigns of gsearch 
and bsearch from August 22nd to November 30th, including details such as utm_source, total sessions, mobile sessions, 
and the percentage of mobile sessions?*/



select 
b.utm_campaign,
b.utm_source,
count(distinct b.website_session_id) total_websessions,
count(distinct case when b.device_type='mobile' then b.website_session_id end) mobile_sessions,
round((count(distinct case when b.device_type='mobile' then b.website_session_id end)*100.0/count(distinct b.website_session_id)),2) percent_of_mobile_sessions

from table_1 a
right join table_2 b
on a.user_id=b.user_id
and a.website_session_id=b.website_session_id
and a.order_item_refund_id is null
where b.session_creation_time  between '2012-08-22 00:00:00' and '2012-11-30 23:59:59'
and b.utm_campaign in ('nonbrand')
and b.utm_source in ( 'gsearch','bsearch')
group by b.utm_campaign,b.utm_source
--having b.utm_source in ( 'gsearch','bsearch') and b.utm_campaign in ('non-brand')



/*3.	Cross-Channel Bid Optimization: provide the conversion rates from sessions to orders for non-brand campaigns of gsearch 
and bsearch by device type, for the period spanning from August 22nd to September 18th?
Additionally, include details such as device type, utm_source, total sessions, total orders, and the corresponding conversion rates.*/ 



select 
utm_source,
b.device_type,
count(distinct a.order_id) as total_orders,
count(distinct b.website_session_id) as total_sessions,
round(count(distinct a.order_id)*100.0/count(distinct b.website_session_id),2) as conversion_rate
from table_1 a
right join table_2 b
on a.user_id=b.user_id
and a.website_session_id=b.website_session_id
and a.order_item_refund_id is null
where  b.session_creation_time  between '2012-08-22 00:00:00' and '2012-09-18 23:59:59'
and b.utm_campaign='nonbrand'
and b.utm_source in ('gsearch','bsearch')
group by b.utm_source,b.device_type
order by conversion_rate desc





/*4.	Channel Portfolio Trends: Retrieve the data for gsearch and bsearch non-brand sessions 
segmented by device type 
from November 4th to December 22nd? Additionally, include details such as the start date of 
each week, device type, utm_source, total sessions, bsearch comparision.*/


WITH weekly_sessions AS (
SELECT 
DATEADD(day, -DATEPART(weekday, b.session_creation_time) + 2, CAST(b.session_creation_time AS DATE)) AS week_start_date,
b.device_type,
b.utm_source,
COUNT(DISTINCT b.website_session_id) AS total_sessions
FROM 
table_2 b
WHERE 
b.session_creation_time BETWEEN '2012-11-04 00:00:00' AND '2015-12-22 23:59:59'
AND b.utm_campaign = 'nonbrand'  -- Assuming there's a campaign filter for non-brand
AND b.utm_source IN ('gsearch', 'bsearch')
GROUP BY 
DATEADD(day, -DATEPART(weekday, b.session_creation_time) + 2, CAST(b.session_creation_time AS DATE)),
b.device_type,
b.utm_source
)

SELECT 
week_start_date,
device_type,
utm_source,
total_sessions,
SUM(CASE WHEN utm_source = 'bsearch' THEN total_sessions ELSE 0 END) OVER (PARTITION BY week_start_date) AS bsearch_comparison
FROM 
weekly_sessions
ORDER BY 
week_start_date, device_type;


/*5.	Analyzing Free Channels: Could you pull organic search , direct type in and paid brand sessions by month and 
show those sessions as a % of paid search non brand?*/



with monthly_sessions as (
select 
year(session_creation_time) year_
,month(session_creation_time) month_,
case
when b.utm_source != 'N/A' and b.utm_campaign = 'brand' and b.utm_content !='N/A'  then 'Paid_search_brand'
when b.utm_source != 'N/A' and b.utm_campaign = 'nonbrand' and b.utm_content !='N/A'  then 'Paid_search_nonbrand'
when b.http_referer = 'N/A' then 'Direct search'
when b.http_referer !='N/A'  and b.utm_source = 'N/A' and b.utm_campaign = 'N/A' and b.utm_content ='N/A' then 'Organic search'
else 'others'
end as channels,
count(distinct website_session_id) as count_of_sessions
from table_2 b
group by year(session_creation_time),month(session_creation_time),
case
when b.utm_source != 'N/A' and b.utm_campaign = 'brand' and b.utm_content !='N/A'  then 'Paid_search_brand'
when b.utm_source != 'N/A' and b.utm_campaign = 'nonbrand' and b.utm_content !='N/A'  then 'Paid_search_nonbrand'
when b.http_referer = 'N/A' then 'Direct search'
when b.http_referer !='N/A'  and b.utm_source = 'N/A' and b.utm_campaign = 'N/A' and b.utm_content ='N/A' then 'Organic search'
else 'others' end
--order by year(session_creation_time),month(session_creation_time)
),
paid_search_non_brand as(
select 
year(session_creation_time) year_,
month(session_creation_time) month_,
count(distinct website_session_id) as paid_search_non_brand_sessions
from table_2 
where utm_source! ='N/A'
and utm_campaign = 'nonbrand'
and utm_content !='N/A'
group by year(session_creation_time),month(session_creation_time)
)
select 
concat(a.year_,'-',a.month_) year_month,
a.channels,
a.count_of_sessions,
b.paid_search_non_brand_sessions,
case when paid_search_non_brand_sessions>0 
then a.count_of_sessions*1.0/b.paid_search_non_brand_sessions 
else 0 end as
session_percentage_of_paid_search_non_brand
from paid_search_non_brand b
left join monthly_sessions a
on a.year_=b.year_
and a.month_=b.month_
where a.channels in ('Organic search','Direct search','paid_search_brand')
order by a.year_,a.month_,a.channels


/*7.	Product Conversion Funnels: provide a comparison of the conversion funnels from the product pages 
to conversion for two products since January 6th, analyzing all website traffic?*/

with partition_ as(
select 
user_id,
website_session_id,
pageview_url,
row_number() over (partition by user_id,website_session_id order by webpage_creation_time asc) as r_n
from table_2
where webpage_creation_time>='2012-01-06 00:00:00'
),
b as(
select user_id,
website_session_id,
pageview_url,
lead(pageview_url) over(partition by user_id,website_session_id order by r_n) as page1,
lead(pageview_url,2) over(partition by user_id,website_session_id order by r_n) as page2,
lead(pageview_url,3)over(partition by user_id,website_session_id order by r_n) as page3,
lead(pageview_url,4)over(partition by user_id,website_session_id order by r_n) as page4,
lead(pageview_url,5)over(partition by user_id,website_session_id order by r_n) as page5,
lead(pageview_url,6)over(partition by user_id,website_session_id order by r_n) as page6
from partition_
)
select * into #journey from b

select * from #journey


SELECT 
    'The original mr fuzzy' as product_name,
	COUNT(CASE WHEN pageview_url = '/home' AND page1 = '/products'  then 1 end) as Home_to_products,
	COUNT(CASE WHEN pageview_url = '/home' AND page1 = '/products' AND page2='/the-original-mr-fuzzy'  then 1 end) as Home_to_products_to_the_specific_product,
	COUNT(CASE WHEN pageview_url = '/home' AND page1 = '/products' AND page2='/the-original-mr-fuzzy' and page3 = '/cart' then 1 end) as home_to_cart,
	COUNT(CASE WHEN pageview_url = '/home' AND page1 = '/products' AND page2='/the-original-mr-fuzzy' and page3 = '/cart'
               AND page4 = '/shipping'  then 1 end) as home_to_shipping,
	COUNT(CASE WHEN pageview_url = '/home' AND page1 = '/products' AND page2='/the-original-mr-fuzzy' and page3 = '/cart'
               AND page4 = '/shipping' AND page5 like '/billing%'  then 1 end) as home_to_billing,
    COUNT(CASE WHEN pageview_url = '/home'  AND page1 = '/products' AND page2='/the-original-mr-fuzzy' and page3 = '/cart'
               AND page4 = '/shipping' AND page5 like '/billing%' and page6 = '/thank-you-for-your-order' THEN 1 END) AS LandPage_to_Checkout
	
FROM #journey

union all

SELECT 
    'The forever lover bear' as product_name,
	COUNT(CASE WHEN pageview_url = '/home' AND page1 = '/products'  then 1 end) as Home_to_products,
	COUNT(CASE WHEN pageview_url = '/home' AND page1 = '/products' AND page2='/the-forever-love-bear'  then 1 end) as Home_to_products_to_the_forever_love_bear,
	COUNT(CASE WHEN pageview_url = '/home' AND page1 = '/products' AND page2='/the-forever-love-bear' and page3 = '/cart'  then 1 end) as home_to_cart,
	COUNT(CASE WHEN pageview_url = '/home' AND page1 = '/products' AND page2='/the-forever-love-bear' and page3 = '/cart'
               AND page4 = '/shipping'  then 1 end) as home_to_shipping,
	COUNT(CASE WHEN pageview_url = '/home' AND page1 = '/products' AND page2='/the-forever-love-bear' and page3 = '/cart'
               AND page4 = '/shipping' AND page5 like '/billing%'  then 1 end) as home_to_billing,
    COUNT(CASE WHEN pageview_url = '/home' AND page1 = '/products' AND page2='/the-forever-love-bear' and page3 = '/cart'
               AND page4 = '/shipping' AND page5 like '/billing%' and page6 = '/thank-you-for-your-order' THEN 1 END) AS home_to_Checkout
FROM #journey


----------------------------------

SELECT 
    'The original mr fuzzy' as product_name,
	COUNT(CASE WHEN pageview_url like '/lander-%' AND page1 = '/products'  then 1 end) as lander_to_products,
	COUNT(CASE WHEN pageview_url like '/lander-%' AND page1 = '/products' AND page2='/the-original-mr-fuzzy'  then 1 end) as lander_to_products_to_the_original_mr_fuzzy,
	COUNT(CASE WHEN pageview_url like '/lander-%' AND page1 = '/products' AND page2='/the-original-mr-fuzzy' and page3 = '/cart'  then 1 end) as lander_to_cart,
	COUNT(CASE WHEN pageview_url like '/lander-%' AND page1 = '/products' AND page2='/the-original-mr-fuzzy' and page3 = '/cart'
               AND page4 = '/shipping'  then 1 end) as lander_to_shipping,
	COUNT(CASE WHEN pageview_url like '/lander-%' AND page1 = '/products' AND page2='/the-original-mr-fuzzy' and page3 = '/cart'
               AND page4 = '/shipping' AND page5 like '/billing%'  then 1 end) as lander_to_billing,
	COUNT(CASE WHEN pageview_url like '/lander-%' AND page1 = '/products' AND page2='/the-original-mr-fuzzy' and page3 = '/cart'
               AND page4 = '/shipping' AND page5 like '/billing%' and page6 = '/thank-you-for-your-order' THEN 1 END) AS LandPage_to_Checkout
FROM #journey

union all

SELECT 
    'The forever lover bear' as product_name,
	COUNT(CASE WHEN pageview_url like '/lander-%' AND page1 = '/products'  then 1 end) as lander_to_products,
	COUNT(CASE WHEN pageview_url like '/lander-%' AND page1 = '/products' AND page2='/the-forever-love-bear'  then 1 end) as lander_to_products_to_the_forever_love_bear,
	COUNT(CASE WHEN pageview_url like '/lander-%' AND page1 = '/products' AND page2='/the-forever-love-bear' and page3 = '/cart'  then 1 end) as lander_to_cart,
	COUNT(CASE WHEN pageview_url like '/lander-%' AND page1 = '/products' AND page2='/the-forever-love-bear' and page3 = '/cart'
               AND page4 = '/shipping'  then 1 end) as lander_to_shipping,
	COUNT(CASE WHEN pageview_url like '/lander-%' AND page1 = '/products' AND page2='/the-forever-love-bear' and page3 = '/cart'
               AND page4 = '/shipping' AND page5 like '/billing%'  then 1 end) as lander_to_billing,
	COUNT(CASE WHEN pageview_url like '/lander-%' AND page1 = '/products' AND page2='/the-forever-love-bear' and page3 = '/cart'
               AND page4 = '/shipping' AND page5 like '/billing%' and page6='/thank-you-for-your-order' THEN 1 END) AS lander_to_checkout

FROM #journey


/*9. 	Portfolio Expansion Analysis: Conduct a pre-post analysis comparing the month before and 
the month after the launch of the “Birthday Bear” 
product on December 12th, 2013? Specifically, containing the changes in session-to-order conversion rate, average order value (AOV),
products per order, and revenue per session.*/



WITH pre_launch AS (
    SELECT
        'Pre-Launch' AS period,
        COUNT(DISTINCT order_id) AS total_orders,
        COUNT(DISTINCT w.website_session_id) AS total_sessions,
        SUM(price_usd)-sum(refund_amount_usd) AS total_revenue
		from website_sessions as w
		left join
        table_1 as t
		on w.website_session_id=t.website_session_id
		and w.[user_id]=t.[user_id]
		and t.order_item_refund_id is null
    WHERE 
      created_at BETWEEN '2013-11-12 00:00:00' AND '2013-12-11 23:59:59'
),
post_launch AS (
    SELECT
        'Post-Launch' AS period,
        COUNT(DISTINCT order_id) AS total_orders,
        COUNT(DISTINCT w.website_session_id) AS total_sessions,
        SUM(price_usd)-sum(refund_amount_usd) AS total_revenue
        
    from website_sessions as w
		left join
        table_1 as t
		on w.website_session_id=t.website_session_id
		and w.[user_id]=t.[user_id]
		and t.order_item_refund_id is null
    WHERE 
       created_at BETWEEN '2013-12-13 00:00:00' AND '2014-01-12 23:59:59'
)

-- Calculate the required metrics
SELECT
    period,
    total_orders,
    total_sessions,
    total_revenue,
    ROUND(total_revenue * 1.0 / total_orders, 2) AS avg_order_value,
    
    ROUND(total_orders * 100.0 / total_sessions, 2) AS session_to_order_conversion_rate,
    ROUND(total_revenue * 1.0 / total_sessions, 2) AS revenue_per_session
FROM (
    SELECT * FROM pre_launch
    UNION ALL
    SELECT * FROM post_launch
) AS combined
ORDER BY period;


/*10.	Product Refund Rates: What is monthly product refund rates, by product and confirm quality issues are now fixed? */




With monthly_sales AS (
select
product_id,
year(order_creation_time) year_,
month(order_creation_time) month_,
count(order_id) AS total_sold,
sum(CASE WHEN order_item_refund_id IS NOT NULL THEN 1 ELSE 0 END) AS refunded_count
from
table_1
group by 
product_id, 
year(order_creation_time), 
month(order_creation_time)
)

select 
product_id,
concat(year_,'-',month_) year_month,
total_sold,
refunded_count,
round((refunded_count * 100.0 / nullif(total_sold, 0)), 2) AS refund_rate_percentage
from
monthly_sales
order by 
year_,month_,product_id;

----------------------------------------------**--------------------------------------------------

--Part 3

/*Q4>>.	Analyzing Landing Page Tests: What are the bounce rates for
     \lander-1 and \home in the A/B test conducted by ST for the gsearch nonbrand campaign,
	 considering traffic received by \lander-1 and \home before*/



-- Step 1: Find when /lander-1 was first displayed and limit by date
WITH FirstPageViews AS (
    SELECT website_session_id, MIN(cast(created_at as date)) AS start_time
    FROM website_pageviews
    WHERE pageview_url = '/home' 
	and website_session_id in 
	(select website_session_id from website_sessions where utm_source = 'gsearch' and utm_campaign = 'nonbrand')
    GROUP BY website_session_id
),
-- Step 2: Filter sessions to include only those before '2012-07-28'
FilteredSessions AS (
    SELECT website_session_id, start_time
    FROM FirstPageViews
    WHERE start_time< '2012-07-28'
	--start_time BETWEEN '2012-06-19' AND '2012-07-28'
),
-- Step 3: Count page views per session
PageViewCounts AS (
    SELECT website_session_id, COUNT(*) AS page_view_count
    FROM website_pageviews
    WHERE website_session_id IN (SELECT website_session_id FROM FilteredSessions)
    GROUP BY website_session_id
),
-- Identify bounces (sessions with only 1 page view)
BouncedSessions AS (
    SELECT website_session_id
    FROM PageViewCounts
    WHERE page_view_count = 1
),
-- Count total sessions and bounced sessions for /home
SessionCounts AS (
    SELECT 
	COUNT(DISTINCT f.website_session_id) AS total_sessions,
    COUNT(DISTINCT b.website_session_id) AS bounced_sessions
    FROM FilteredSessions f
    LEFT JOIN BouncedSessions b
    ON f.website_session_id = b.website_session_id
),
-- Step 1: Find when /lander-1 was first displayed and limit by date
FirstPageViews_1 AS (
    SELECT website_session_id, MIN(created_at) AS start_time
    FROM website_pageviews
    WHERE pageview_url = '/lander-1' 
	and website_session_id in 
	(select website_session_id from website_sessions where utm_source = 'gsearch' and utm_campaign = 'nonbrand')
    GROUP BY website_session_id
),
-- Step 2: Filter sessions to include only those after '2012-06-19' and before '2012-07-28'
FilteredSessions_1 AS (
    SELECT website_session_id, start_time
    FROM FirstPageViews_1
    WHERE start_time< '2012-07-28'
	--start_time BETWEEN '2012-06-19' AND '2012-07-28'
),
-- Step 3: Count page views per session
PageViewCounts_1 AS (
    SELECT website_session_id, COUNT(*) AS page_view_count
    FROM website_pageviews
    WHERE website_session_id IN (SELECT website_session_id FROM FilteredSessions_1)
    GROUP BY website_session_id
),
-- Identify bounces (sessions with only 1 page view)
BouncedSessions_1 AS (
    SELECT website_session_id
    FROM PageViewCounts_1
    WHERE page_view_count = 1
),
-- Count total sessions and bounced sessions for /home
SessionCounts_1 AS (
    SELECT
        COUNT(DISTINCT f.website_session_id) AS total_sessions,
        COUNT(DISTINCT b.website_session_id) AS bounced_sessions
    FROM FilteredSessions_1 f
    LEFT JOIN BouncedSessions_1 b
    ON f.website_session_id = b.website_session_id
)
-- Calculate the bounce rate
SELECT
    '/home' AS landing_page,
    total_sessions,
    bounced_sessions,
    (bounced_sessions * 100.0 / total_sessions) AS bounce_rate
FROM SessionCounts

union

SELECT
    '/lander-1' AS landing_page,
    total_sessions,
    bounced_sessions,
    (bounced_sessions * 100.0 / total_sessions) AS bounce_rate
FROM SessionCounts_1;



/*5.Landing Page Trend Analysis: What is the trend of weekly paid gsearch nonbrand campaign traffic on /home and /lander-1 pages 
since June 1, 2012, along with their respective bounce rates, as requested by ST? Please limit the results to the period between June 1, 2012,
 and August 31, 2012, based on the email received on August 31, 2021.*/



WITH FirstPageViews AS (
    -- Step 1: Find first page view for each session and limit by date range
    SELECT 
        website_session_id, 
        MIN(website_pageview_id) AS first_pageview_id,
        MIN((cast (created_at as date))) AS session_start_time
    FROM website_pageviews
    WHERE website_session_id in 
	(select website_session_id from website_sessions where (cast (created_at as date)) >= '2012-06-01' AND (cast (created_at as date)) <= '2012-08-31'
	and utm_source = 'gsearch' and utm_campaign = 'nonbrand') 
    GROUP BY website_session_id
),
LandingPages AS (
    -- Step 2: Identify landing page of each session (only for /home and /lander-1)
    SELECT 
        A.website_session_id,
        A.first_pageview_id,
        B.pageview_url AS landing_page,
        A.session_start_time
    FROM FirstPageViews A
    INNER JOIN website_pageviews B ON A.first_pageview_id = B.website_pageview_id
    AND B.pageview_url IN ('/home', '/lander-1')
),
BounceCounts AS (
    -- Step 3: Count page views for each session to identify bounces
    SELECT 
        L.website_session_id,
        L.landing_page,
        L.session_start_time,
        COUNT(*) AS page_view_count
    FROM LandingPages L
    INNER JOIN website_pageviews P ON L.website_session_id = P.website_session_id
    GROUP BY L.website_session_id, L.landing_page, L.session_start_time
),
WeeklySummary AS (
    -- Step 4: Summarize sessions, bounced sessions, and calculate bounce rate by week
    SELECT 
        landing_page,
        DATEADD(week, DATEDIFF(week, 0, session_start_time), 0) AS week_start_date,
        COUNT(*) AS sessions_count,
        SUM(CASE WHEN page_view_count = 1 THEN 1 ELSE 0 END) AS bounced_sessions,
        (SUM(CASE WHEN page_view_count = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS bounce_rate
    FROM BounceCounts
    GROUP BY landing_page, DATEADD(week, DATEDIFF(week, 0, session_start_time), 0)
)
-- Final query to fetch the desired result
SELECT 
    landing_page,
    CONVERT(date, week_start_date) AS week_start_date,
    sessions_count,
    bounced_sessions,
    ROUND(bounce_rate, 2) AS bounce_rate
FROM WeeklySummary
ORDER BY week_start_date, landing_page;

----------------------------------------------------------

--Q6 Build Conversion Funnels for gsearch nonbrand traffic from /lander-1 to /thank you page: What are the session counts and click 
--percentages for \lander-1, product, mrfuzzy, cart, shipping, billing, and thank you pages 
--from August 5, 2012, to September 5,2012?



WITH RelevantSessions AS (
    SELECT
        website_session_id,
        MIN(created_at) AS first_pageview
    FROM website_pageviews
    WHERE pageview_url = '/lander-1'
    AND website_session_id in (select website_session_id from website_sessions where 
	utm_source = 'gsearch' and utm_campaign = 'nonbrand')
    AND created_at BETWEEN '2012-08-05' AND '2012-09-05'
    GROUP BY website_session_id
),
FunnelSteps AS (
    SELECT
        pv.website_session_id,
        pv.created_at,
        pv.pageview_url,
        CASE
            WHEN pv.pageview_url = '/lander-1' THEN 'lander1_click'
            WHEN pv.pageview_url = '/products' THEN 'product_click'
            WHEN pv.pageview_url = '/the-original-mr-fuzzy' THEN 'mrfuzzy_click'
            WHEN pv.pageview_url = '/cart' THEN 'cart_click'
            WHEN pv.pageview_url = '/shipping' THEN 'shipping_click'
            WHEN pv.pageview_url = '/billing' THEN 'billing_click'
            WHEN pv.pageview_url = '/thank-you-for-your-order' THEN 'thank_you_click'
            ELSE NULL
        END AS funnel_step
    FROM website_pageviews pv
    INNER JOIN RelevantSessions rs ON pv.website_session_id = rs.website_session_id
    WHERE pv.created_at BETWEEN '2012-08-05' AND '2012-09-05'
),
SessionFunnelView AS (
    SELECT
        website_session_id,
        MAX(CASE WHEN funnel_step = 'lander1_click' THEN 1 ELSE 0 END) AS lander1_click,
        MAX(CASE WHEN funnel_step = 'product_click' THEN 1 ELSE 0 END) AS product_click,
        MAX(CASE WHEN funnel_step = 'mrfuzzy_click' THEN 1 ELSE 0 END) AS mrfuzzy_click,
        MAX(CASE WHEN funnel_step = 'cart_click' THEN 1 ELSE 0 END) AS cart_click,
        MAX(CASE WHEN funnel_step = 'shipping_click' THEN 1 ELSE 0 END) AS shipping_click,
        MAX(CASE WHEN funnel_step = 'billing_click' THEN 1 ELSE 0 END) AS billing_click,
        MAX(CASE WHEN funnel_step = 'thank_you_click' THEN 1 ELSE 0 END) AS thank_you_click
    FROM FunnelSteps
    GROUP BY website_session_id
) 
SELECT
    COUNT(website_session_id) AS sessions,
    SUM(product_click) * 100.0 / SUM(lander1_click) AS product_click_percentage,
    SUM(mrfuzzy_click) * 100.0 / SUM(product_click) AS mrfuzzy_click_percentage,
    SUM(cart_click) * 100.0 / SUM(mrfuzzy_click) AS cart_click_percentage,
    SUM(shipping_click) * 100.0 /  SUM(cart_click)
	AS shipping_click_percentage,
    SUM(billing_click) * 100.0 / SUM(shipping_click) AS billing_click_percentage,
    SUM(thank_you_click) * 100.0 / SUM(billing_click) AS thank_you_click_percentage
FROM SessionFunnelView;

-------------------------------------------------------------

--Qn 7 Analyze Conversion Funnel Tests for /billing vs. new /billing-2 pages:
--what is the traffic and billing to order conversion rate of 
--both pages new/billing-2 page?



WITH PageViewCounts AS ( 

    SELECT  pageview_url, 
        COUNT(*) AS TotalPageViews 
    FROM website_pageviews 
where pageview_url in ('/billing','/billing-2') 
GROUP BY pageview_url 
), 

OrderCounts AS ( 
    SELECT  
        pageview_url, 
        COUNT(*) AS TotalOrders 
    FROM Orders o join website_pageviews wp on o.website_session_id=wp.website_session_id 
where pageview_url in ('/billing','/billing-2') 
    GROUP BY pageview_url 
) 
SELECT  
    pv.pageview_url, 
    pv.TotalPageViews, 
    COALESCE(oc.TotalOrders, 0) AS TotalOrders, 
    CASE  
        WHEN pv.TotalPageViews > 0 THEN  
            CAST(COALESCE(oc.TotalOrders, 0) AS FLOAT) / pv.TotalPageViews
        ELSE  0 
END AS ConversionRate 

FROM  PageViewCounts pv 
LEFT JOIN  
    OrderCounts oc 
ON  
    pv.pageview_url = oc.pageview_url; 
==============================================================================================================================================
--Q9.New Vs. Repeat Performance: Provide analysis on comparison of conversion rates and revenue per session for
--repeat sessions vs new sessions?2014 to date is good. 



select  
case when is_repeat_session =0 then 'New user' else 'Repeat user' end as users, 
count(distinct w.website_session_id) as web_sessions, 
count(distinct t.order_id)*100.0/count(distinct w.website_session_id) conversion_rate, 
sum(revenue)/count(distinct w.website_session_id) revenue_per_session 
from website_sessions w 
left join table_1 as t
on w.website_session_id=t.website_session_id 
 and w.[user_id]=t.[user_id]
  and order_item_refund_id is null
where cast(w.created_at as date) >= '2014-01-01' 
group by case when is_repeat_session =0 then 'New user' else 'Repeat user' end 
-----------------------------------------------------------------------------------------------------------------------------------
/*Q10>>	Product Launch Sales Analysis: Could you generate trended analysis including
monthly order volume, overall conversion rates, revenue per session, 
and a breakdown of sales by product since April 1, 2013, 
considering the launch of the second product on January 6th?*/

--
--monthly order volume, revenue and margin since 1-4-2013



 select month(order_creation_time) as months,year(order_creation_time) as years,
          product_id,product_name,count(distinct order_id) as order_volume,
		 (sum(price_usd)-sum(refund_amount_usd)) as total_revenue,
		 (sum(price_usd)- sum(refund_amount_usd) - sum(cogs_usd)) as margin
		 
  from table_1
  where  cast(order_creation_time as date)>='2013-04-01'
  and order_item_refund_id is null
  and product_id=2
  group by month(order_creation_time) ,year(order_creation_time),product_id,product_name
  order by product_id,product_name, years,months

--revenue per session

select max(total)/min(total) as revenue_per_session
from
(select sum(revenue) as total
from table_1
where product_id=2
and order_creation_time >='2013-04-01'
union
select count(distinct website_session_id) as total from table_2
where pageview_url='/the-forever-love-bear'
and session_creation_time >='2013-04-01') as x


--overall conversion rates

select count(distinct order_id) as total_orders, count(distinct t2.website_session_id) as total_sessions,
count(distinct order_id)*100.00/count(distinct t2.website_session_id) as conversion_rate
from
table_1 as t1
right join table_2 as t2
on t1.website_session_id=t2.website_session_id
and order_item_refund_id is null
where session_creation_time >='2013-04-01' and t2.pageview_url='/the-forever-love-bear'


------------------------------------------**END**---------------------------------------------------

