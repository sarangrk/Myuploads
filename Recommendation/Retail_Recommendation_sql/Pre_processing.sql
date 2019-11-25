
-------------------------------------------------------------------------------------------------------------------------
-- Split PoS Data into Training and Validation sets. Validation data sets - last 1 week and training datasets previous 3 weeks

select * from loblaws.pos;


create table loblaws.pos_new as
(select Customer as customer_id,Phone_number
                        ,Billing_doc_date as txn_date,Billing_document as txn_id,Division as subbrand 
                        ,Division_1 as division,FG_PRODUCT_TYPE as product_type
                        ,RETEK_DEPARTMENTS as department,RETEK_CLASS as category,RETEK_SUBCLASS as sub_category
                        ,SLEEVE_DETAILS as sleeve,Size
                        ,PC      
                        ,NSV
                        from loblaws.sales_lp_aug) with data;

                        
 select count(*) from loblaws.pos_new;                     

 
 
-- Data Masking

select * from loblaws.pos_new;



SELECT oreplace('Forgetcode','Forget','Nice');

SELECT subbrand,oreplace(oreplace(oreplace(subbrand,'LP','AA'),'LR','BB'),'LY','CC') from loblaws.pos_new;


SELECT subbrand,oreplace(subbrand,'L','X') from loblaws.pos_new;


UPDATE loblaws.pos_new SET subbrand=oreplace(subbrand,'L','X');
UPDATE loblaws.pos_new SET subbrand=oreplace(subbrand,'P','Y');
UPDATE loblaws.pos_new SET subbrand=oreplace(subbrand,'R','Z');


select distinct subbrand from loblaws.pos_new;


select distinct division from loblaws.pos_new;

UPDATE loblaws.pos_new SET division=oreplace(division,'LP','XY');
UPDATE loblaws.pos_new SET division=oreplace(division,'Louis Philippe','XxYy');
 
select distinct department from loblaws.pos_new;

UPDATE loblaws.pos_new SET department=oreplace(department,'LP','XY');
UPDATE loblaws.pos_new SET department=oreplace(department,'LY','XY');
UPDATE loblaws.pos_new SET department=oreplace(department,'LX','XX');
UPDATE loblaws.pos_new SET department=oreplace(department,'LR','XZ');


-- validation set last week of August 2016 


drop table loblaws.POS_VALIDATION_NEW;
drop table loblaws.POS_TRAINING_NEW;

-- we are adding concatenation of columns in the table so that we can use the concatenated column for display and analysis



create table loblaws.POS_VALIDATION_NEW as  (select  customer_id,phone_number,txn_id,txn_date,subbrand,department,division,product_type,category,sub_category,sleeve,size,PC,NSV,subbrand||'_'||department||'_'||category||'_'||sub_category||'_'||sleeve|| '_' ||size|| '_'  ||product_type as product from loblaws.pos_new where txn_date >= '23.08.2016' and nsv >= 0)
with data;


select * from loblaws.POS_VALIDATION_NEW;



select count(*) from loblaws.POS_validation_NEW

drop table loblaws.POS_TRAINING_NEW

create table loblaws.POS_TRAINING_NEW as  (select  customer_id,phone_number,txn_id,txn_date,subbrand,department,division,product_type,category,sub_category,sleeve,size,PC,NSV,subbrand||'_'||department||'_'||category||'_'||sub_category||'_'||sleeve|| '_' ||size|| '_'  ||product_type as product from loblaws.pos_new where txn_date < '23.08.2016' and nsv >= 0)
with data;


select  product,sub_category,product_type from loblaws.POS_Training_new;

select * from loblaws.pos_new


-- identify accesories from the tables
select distinct category from loblaws.pos_training;


Belt
Blazer
Carry Bag
Cufflinks
Handkies
Jacket
Jeans
Pocket Square
Shirt
Shoes
Shorts
Socks
Suit
Sweater
SweatShirt
Tie
Trouser
T Shirt
Wallet
Watches

select distinct category from loblaws.pos_training_new;

Belt
Blazer
Carry Bag
Cufflinks
Handkies
Jacket
Jeans
Pocket Square
Shirt
Shoes
Shorts
Socks
Suit
Sweater
SweatShirt
Tie
Trouser
T Shirt
Wallet
Watches


delete from loblaws.pos_training_new where category in 
(
'Carry Bag'
);


delete from loblaws.pos_validation_new where category in 
(
'Carry Bag'
);



delete from loblaws.pos_training_new where category in 
('Belt',
'Wallet',
'Socks',
'Sandal',
'Watches',
'Cufflinks',
'Handkies',
'Carry Bag',
'Bag',
'Shoes',
'Travel Accessories',
'Tie'
);


delete from loblaws.pos_validation_new where category in 
('Belt',
'Wallet',
'Socks',
'Sandal',
'Watches',
'Cufflinks',
'Handkies',
'Carry Bag',
'Bag',
'Shoes',
'Travel Accessories',
'Tie'
);





