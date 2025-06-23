use retail_analytics;

desc customer;
select * from customer;

# to rename column
alter table customer
rename column ï»¿CustomerID to CustomerID;

alter table product 
rename column ï»¿ProductID to ProductID;

alter table sales
rename column ï»¿TransactionID to TransactionID;

# to get duplicates if present based on transactionid
select transactionid,count(*) 
from sales 
group by transactionid
having count(*) > 1;

# creating table with unique rows
create table deduplicate_sales (
	select distinct * from sales 
);

select * from deduplicate_sales;

drop table sales;

alter table deduplicate_sales
rename to sales;

select * from sales;

# to update error in transaction price using inventory price
# to get error transaction prices data
select s.transactionid,s.price as tran_price,p.price as inven_price
from sales s
inner join product p
on (s.productid = p.productid)
and (s.price != p.price);

SET SQL_SAFE_UPDATES = 0;

# to update error tran_price with inventory price
# first method using update and join 
update sales s
inner join product p
on s.productid = p.productid
set s.price = p.price
where s.price != p.price;
# correlated query another method |vv|
-- update sales s
-- set s.price =(
-- 	select p.price from product p where p.productid = s.productid
-- )
-- where s.price != (
-- 	select p.price from product p where p.productid = s.productid 
--     );

#other method using exists() function
-- update sales s 
-- set s.price = (
--     select p.price from product p 
--     where p.productid = s.productid
-- )
-- where exists(
--     select * from product p 
--     where p.productid = s.productid
--     and p.price <> s.price
-- );
# to check if there are any null values
select sum(case when customerid is null then 1 end) as customer_null,
sum(case when age is null then 1 end) as age_null,
sum(case when gender is null then 1 end) as gender_null,
sum(case when location is null then 1 end) as location_null,
sum(case when joindate is null then 1 end) as joindate
 from customer;   

select sum(case when transactionid is null then 1 end) as tran_null,
sum(case when customerid is null then 1 end) as cust_null,
sum(case when productid is null then 1 end) as prod_null,
sum(case when quantitypurchased is null then 1 end) as qp_null,
sum(case when transactiondate is null then 1 end) as trans_null,
sum(case when price is null then 1 end) as price_null
from sales ;

select sum(case when productname is null then 1 end) as pn_null,
sum(case when productid is null then 1 end) as prod_null,
sum(case when category is null then 1 end) as cat_null,
sum(case when stocklevel is null then 1 end) as stock_null,
sum(case when price is null then 1 end) as price_null

from product;

desc sales;

alter table sales
add column tran_date_updates date;
# to check whether is there other formats in date other than below format
select * from sales 
where str_to_date(transactiondate,"%Y-%m-%d") is null;

# updating format of date with two found formats and making null if there are other format
update sales 
set tran_date_updates = (
	case when transactiondate like "____-__-__" and str_to_date(Transactiondate,"%y-%m-%d")
    then str_to_date(Transactiondate,"%y-%m-%d")
	when transactiondate like "__/__/__" and str_to_date(Transactiondate,"%d/%m/%y")
    then str_to_date(Transactiondate,"%d/%m/%y")
    else null
    end
);

select * from sales where tran_date_updates is null;

-- desc sales;

update sales 
set transactiondate = tran_date_updates;

# to summarize the total sales and quantities sold per product by the company
	
select ProductID,sum(QuantityPurchased) as TotalUnitsSold,
sum(QuantityPurchased * Price) as TotalSales
from Sales_transaction
group by ProductID
order by TotalSales desc;


#  count the number of transactions per customer to understand purchase frequency

select CustomerID,first_value(transactiondate) 
        over(partition by customerid order by transactiondate desc
        rows between unbounded preceding and unbounded following) 
            as last_purchase_date,
 datediff(current_date(),
    first_value(transactiondate) 
        over(partition by customerid order by transactiondate desc
        rows between unbounded preceding and unbounded following)
 ) as days_since_last_purchase 
 from Sales_transaction
 order by days_since_last_purchase desc;


#  evaluate the performance of the product categories based on the total sales

select p.Category, sum(s.quantitypurchased) as TotalUnitsSold,
sum(s.quantitypurchased * s.price) as TotalSales
from product_inventory p  
inner join sales_transaction s 
on p.productid = s.productid
group by p.category
order by totalsales desc;

# find the top 10 products with the highest total sales

select ProductID,TotalRevenue from (
    select ProductID,sum(QuantityPurchased * Price) as TotalRevenue,
    row_number() over(order by sum(QuantityPurchased * Price) desc) as rank_revenue
    from sales_transaction
    group by ProductID
) as t
where rank_revenue < 11;

# ten products with the least amount of units sold

select ProductID,sum(quantitypurchased) as TotalUnitsSold
from sales_transaction
group by ProductID
having TotalUnitsSold > 0
order by TotalUnitsSold 
limit 10;

# the sales trend

select TransactionDate_updated as DATETRANS,
count(*) as Transaction_count,
sum(QuantityPurchased) as TotalUnitsSold,
sum(quantityPurchased * price) as TotalSales
from sales_transaction
group by DATETRANS
order by DATETRANS desc;


# month on month growth rate of sales of the company

with monthly_sales as (
    select month(transactiondate_updated) as month,
        sum(quantitypurchased * price) as total_sales
        from sales_transaction
        group by month
)

select month,total_sales,
    lag(total_sales,1) over(order by month) as previous_month_sales,
((total_sales - lag(total_sales) over(order by month))/(lag(total_sales,1) over(order by month)))*100
as mom_growth_percentage
from monthly_sales
order by month;


#  total amount spent by each customer along with number of transactions

select CustomerID,count(*) as NumberOfTransactions,
sum(Quantitypurchased * price) as TotalSpent
from sales_transaction
group by CustomerID
having (NumberOfTransactions > 10) and (TotalSpent > 1000) 
order by TotalSpent desc;


#  customers who are occasional customers or have low purchase frequency in the company

select CustomerID,count(*) as NumberOfTransactions,
sum(QuantityPurchased * price) as TotalSpent
from sales_transaction
group by CustomerID
having NumberOfTransactions <= 2
order by NumberOfTransactions asc,TotalSpent desc;


# total number of purchases made by each customer against each productID

select CustomerID,ProductID,count(*) as TimesPurchased
from Sales_transaction
group by CustomerID,ProductID
having TimesPurchased >1
order by TimesPurchased desc;


#  loyalty of the customer
# duration between the first and the last purchase of the customer

select CustomerID,
min(str_to_date(transactiondate,"%Y-%m-%d")) as FirstPurchase,
max(str_to_date(transactiondate,"%Y-%m-%d")) as LastPurchase,
datediff(max(str_to_date(transactiondate,"%Y-%m-%d")),
    min(str_to_date(transactiondate,"%Y-%m-%d"))) 
    as DaysBetweenPurchases
from Sales_transaction
group by CustomerID
having DaysBetweenPurchases > 0
order by DaysBetweenPurchases desc;


#  segments customers
# based on the total quantity of products they have purchased
#  target a particular segment for marketing

with customer_segement as(
    select c.Customerid,(case
        when sum(s.quantitypurchased) between 1 and 9 then "Low"
        when sum(s.quantitypurchased) between 10 and 30 then "Med"
        when sum(s.quantitypurchased)>30 then "High"
        end) as CustomerSegment
        from customer_profiles c 
        join sales_transaction s 
        on c.customerid = s.customerid
        group by c.customerid
)

select CustomerSegment,COUNT(*) from customer_segement
group by CustomerSegment;

