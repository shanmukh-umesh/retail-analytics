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

-- select * from  sales limit 2000;

alter table sales
drop column tran_date_updates;

-- 22-02-2025

use coding_ninjas;

create table prac_1(
 id int PRIMARY KEY,
 student_name varchar(20) NOT NULL,
 dob date NOT NULL
 );
 
 create table prac_2(
	student_id int ,
    father_name varchar(20),
    mother_name varchar(20),
    FOREIGN KEY (student_id) REFERENCES prac_1(id)
    );
    
    describe prac_2;
 