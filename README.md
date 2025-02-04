**Business Context:** A newly launched E-commerce company, selling animal stuff toys, provided its sales data for the 3 years and requested to prepare a compelling story from the given data to help them to raise its next round of funding for further growing of the business. The client also wants dashboards for different stakeholders which helps in tracking business metrics and KPIs regularly, so that the stakeholders can make data-driven decisions to improve the company’s performance. In addition to this, the Analytics team needs to provide a detailed analysis of company performance and new product analysis.

**Data Availability:** The client provided data in six tables:
a.	Orders table – Containing order level data consists of 8 columns – order_id, created_at, website_session_id, user_id, primary_product_id, items_purchased, price_usd, cogs_usd
b.	Order_items table: Containing order_item level data consists of 7 columns – order_item_id, created_at, order_id, product_id, is_primary_item, price_usd, cogs_usd
c.	Order_item_refunds table: Containing oder_item_refund level data consists of 5 columns – order_item_refund_id, created_at, order_item_id, order_id, refund_amount_usd
d.	Website_sessions  table: Containing website session level data consists of 9 columns – website_session_id, created_at, user_id, is_repeat_session, utm_source, utm_campaign, utm_content, device_type, http_referer
e.	Website_pageviews table: Containing website pageview level data consists of 4 columns – website_pageview_id, created_at, website_session_id, pageview_url
f.	products table: Consists of 3 columns – product_id, created_at, product_name

**Tools used:** Excel, SQL, Power BI and MS PPT

**Techniques used:** Data Cleaning, Exploratory Data Analysis, Trend and Seasonality analysis, Customer &  user Behaviour Analysis, Channel portfolio analysis, Website performance analysis, Product analysis, Cross Selling Analysis, Traffic source analysis, Creation of Charts showing results of the analysis, Insights Generation and Dashboard creation in power BI .
Types of Charts Used: Line Chart, Column Chart, Stacked column chart, Combo chart, Bar Chart, Pie Chart, Doughnut chart , table etc.

**Detailed Steps:**
1.	As part of this project, I analyzed 11,88,124 records of website pageviws, 4,72,871 records of website sessions, and 40,025 records of order items provided by the e-commerce Company 
2.	Initially, I performed data cleaning steps viz.
	Data type of price_usd and cogs_usd columns of orders and order_item tables have been changed to Decimal(5,2)
	Data type of refund_amount_usd column of order_refund table has been changed to Decimal(5,2)
3.	After cleaning of the data, created two master tables.
	Created Table_1 by joining Orders table, Order_items table, Order_item_refunds table and product table so that the order value and refund value can be alongwith their product can be taken at one place for convenience of analysis
	Where the ‘refund_amout_usd’ was ‘null’ it has been replaced with ‘0’ for the convenience of calculation
	Then, created a new column ‘Revenue’ in Table_1, using price_usd – refund_amount_usd
	Total no. of rows in Table_1 is 40,025 and order_item_id is the primary key of Table_1
	Created Table_2 by joining website_sessions and website_pageviews tables
	Replaced the ‘null’ values of ‘UTM-source’, ‘UTM_content’, ‘UTM_campaign’ and ‘http_referer’ with ‘N/A’.
	Total no. of rows in Table_2 is 11,88,124 and website_pageview_id is the primary key of Table_2
4.	Calculated the high-level metrics like total revenue, total profit, profit percentage, Revenue CAGR %, profit CAGR, total orders, total orders after refund, total customer, Average session duration, bounce rate, conversion rate, etc.
5.	Also analyzed the Sales trend i.e. year on year, quarter on quarter, month on month and week on week sale and profit, website visits, etc. and seasonality analysis such as by month, quarter, days of week, weekdays vs. weekend analysis, etc.
6.	Performed customer behaviour analysis, such as one time vs. repeat customer, first time vs. repeat purchase behaviour, customer segmentation (RFM), customer cohort analysis, churn rate, customer lifetime value, etc.
7.	Analyzed website activities such as conversion rate, bounce rate, click through rate, etc.
8.	Further, performed detailed analysis with respect to various channels and traffic sources for the above metrics, 
9.	Analyzed the cross selling of products, performance of previous products after launch of new products as well as performance of newly launch products
10.	Performed bid-optimization analysis
11.	Prepared growth story for Investor 
12.	Prepared dashboard for CEO, Website manager and Marketing manager(used dynamic x axis ,dynamic y axis, buttons, slicer etc)


**Findings:**
1.	Yearly trend show steady growth in all the metrics e.g. sessions, orders, revenue, profit, customers. While the data for 2015 is given for less than a quarter, it implies that 2015 would also witnesses a similar trend like previous years
2.	For Revenue, CAGR% (from 1st Jan, 2013 to 31st Dec, 2014) was 255.8% and For Profit,  CAGR% (from 1st Jan, 2013 to 31st Dec, 2014) was 260.4% 
3.	Quarterly order volume shows significant growth from 2012 to 2015, with the highest spike in Q4 2014, indicating a strong upward trend in seasonal demand.
4.	Quarter wise trend comparison also shows steady growth in revenue in each quarter
5.	The conversion rate has steadily improved across quarters, reaching its highest in Q1 2015 (8.25%), indicating more efficient sessions translating into orders 
6.	Total revenue and orders for non-brand is substantively higher than the brand in each quarter consistently Quarter 2 has highest sales (28.29%) and quarter 4 has lowest sales (21.29%)
7.	Month with highest sales, revenue and profit: December and month with highest customer, visitor & session: December 
8.	Quarter with highest sales, revenue and profit: Jan-Mar(Q1) and quarter with highest customer, visitor & session: Oct-Dec (Q4) 
9.	Day with highest sales, revenue and profit: Monday and day with lowest sales, revenue and profit: Saturday
10.	Highest no. of traffic (68%) & highest no. visit (67%) is coming through ‘gsearch’ and lowest no. of traffic (2.4%) & lowest no. of visit (2.2%) is coming through ‘socialbook’. While in case of repeat visit the maximum no. of visitors coming through the ‘direct/organic search’
11.	 The homepage (/home) is the most visited landing page, with 1,37,576 views, followed by /lander-2 
12.	Highest no. of  orders and web sessions are done through paid search while Direct search contribute to least number of orders and web sessions  driving less traffic.
13.	Desktop users are having higher conversion rate across all channels compared to mobile users
14.	The Original Mr. Fuzzy is the product with highest number of orders reaching 23k and The Birthday Sugar Panda is the product with least orders
15.	The Hudson River Mini bear(4th product) and The Original Mr. Fuzzy(1st product) are most cross selling products
16.	The Original Mr. Fuzzy(1st product) is the product which generated highest revenue 
17.	The Original Mr. Fuzzy(1st product)  is the product with highest number of refund orders
18.	The most common path customers follow to purchase a product is “Home to Checkout” and “Lander 2 to Checkout”
19.	Repeat visitor is 13% of total no. of visitors. Total session by repeat visitor is 27.45%.
20.	Conversion rate for repeat visitor is slightly higher (7.15%) than onetime visitor (6.37%) 
21.	Maximum no. of repeat visitors has visited website through Paid search
22.	Home page has maximum no. of times entry page visit by repeat visitors and lander-2 page has maximum no. of times entry page visit by onetime visitors 
23.	The Dec, 2014 cohort has the highest no of customers(2,264) and Mar, 2012 cohort has the lowest no. of customers (60)
24.	The Nov, 2012 cohort and Sep, 2014 cohort has the highest cohort index (5)
25.	The churn rate across all the quarter is very high around 99% or more
26.	The CLV has steadily increased from $49.99 in Q1 2012 to a peak of $64.82 in Q2 2014
27.	It has been seen that after bidding down the total web sessions and conversion rate has been reduced and after subsequent bidding up both web sessions and conversion rate has been increased

**Recommendations:**
	Continue leveraging strategies that drove steady growth in 2013 and 2014, focusing on scalable efforts like optimizing marketing channels and enhancing customer retention programs and also closely monitor 2015's partial data to validate trends and adapt quickly if early indicators deviate from expected performance.
	Continue optimizing the website to drive higher value from each session, such as offering targeted promotions or personalized experiences
	Focus on building stronger brand awareness to increase orders and revenue from branded channels
	Continue optimizing SEO strategies to sustain the steady growth in organic search orders and revenue . So, focus on creating high-quality content and improving site performance to attract more organic traffic and conversions
	Strengthen loyalty programs and personalized marketing to retain the existing users/customers
	: Focus on improving the conversion rates in the checkout process for both segments, particularly from /cart to /shipping, as both segments show a significant drop in engagement at this stage. Consider reducing friction in the checkout process.
	The revenue impact of the billing page test can be quantified by tracking monthly sessions. Increase efforts to drive traffic to the billing page using email reminders or retargeting ads for cart abandoners.
	Use A/B testing to optimize website elements such as CTAs, navigation, and checkout flows to improve conversion rates across all channels.
	Ensure all landing pages load quickly and are mobile-friendly, as these factors significantly impact user engagement and conversions.
	Use data analytics to identify pattern in refund orders and take corrective action.
	Ensure website is responsive and optimized for mobile devices.
	Send exclusive offers, loyalty rewards, or early access to new products/services to Gold customers to maintain their loyalty.
	Identify customers on the higher end of the Silver segment (scores close to 7) and encourage them to spend more frequently or make higher-value purchases by providing loyalty programs or benefits for higher purchases to convert them to Gold customers.
	Develop loyalty programs or subscription models to encourage long-term engagement and reduce churn. This can stabilize and improve CLV over time
	Introduce related or complementary products/services to encourage additional purchases and increase the average revenue per customer.
	Prepared a growth story for investor’s deck for their next round of funding

**Challenges:**
	Data is given for the very early stage of the business. So, its was very unpredictable how the business will perform after growing significantly
	Marketing expenses was not given. Hence, customer acquisition cost could not be calculated. Hence, we could not calculate ROI 
 Digital-analysis-for-an-e-commerce-company
