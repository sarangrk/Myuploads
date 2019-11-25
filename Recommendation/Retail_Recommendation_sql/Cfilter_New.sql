-- creating RFM table for training dataset

-- 1. create monitory table

select product from loblaws.pos_training_new

select product from loblaws.pos_training_new



drop table loblaws.monetary;

create table loblaws.monetary as
(select customer_id, 
       TO_CHAR(TO_DATE(txn_date,'DD.MM.YYYY') ,'YYYY-MM-DD') as txn_date,
       sum(nsv)as sum_selling_price 
from loblaws.pos_training_new
group by customer_id, txn_date)
with data;

--verify data
select * from loblaws.monetary;

select count(*)from loblaws.monetary;
select min(nsv)from loblaws.pos_training_new;

--create RFM (Recency Frequency Monetary table)

drop table  loblaws.RFM;


select CURRENT_DATE-txn_date from loblaws.monetary


select CURRENT_DATE -(CURRENT_DATE-1)


select TO_CHAR(TO_DATE(txn_date,'DD.MM.YYYY') ,'YYYY-MM-DD HH:MI:SS') from loblaws.monetary;

create table  loblaws.RFM as
(select customer_id, 
      min(CURRENT_DATE  - to_date(txn_date,'YYYY-MM-DD')) as Recency ,
       count(customer_id)            as Frequency,
       sum(sum_selling_price)        as Monetary
from loblaws.monetary
group by customer_id)
with data






--verify data
select * from loblaws.RFM;
select count(1) from loblaws.RFM;
select count(distinct(customer_id)) from loblaws.rfm;



drop table  loblaws.rfm_norm;

CREATE TABLE loblaws.rfm_norm AS
(

SELECT * FROM Scale (
ON ScaleMap (
ON loblaws.RFM
USING
TargetColumns ('[1:3]')
) AS STATISTIC DIMENSION
ON loblaws.RFM AS "input" PARTITION BY ANY
USING
ScaleMethod('maxabs')
Accumulate('customer_id')
) as dt
)
with data;


select * from loblaws.rfm_norm;


select count(*)from loblaws.rfm_norm;



--- Kmeans;
--The following call clusters the normalized data.

drop table loblaws.rfm_norm_cluster; 
drop table loblaws.rfm_cluster_output;



SELECT * FROM KMeans (
 ON loblaws.rfm_norm AS InputTable
 OUT TABLE OutputTable (loblaws.rfm_norm_cluster)
 OUT TABLE ClusteredOutput (loblaws.rfm_cluster_output)
 USING
 NumClusters (5)
 StopThreshold (0.01)
 MaxIterNum (10)
) AS dt;



select * from loblaws.rfm_norm_cluster;

select * from loblaws.rfm_cluster_output;


-- appending cluster id to each row in RFM table

drop table loblaws.RFM_Cluster;

create table loblaws.RFM_Cluster as
(select a.clusterid, b.*
from loblaws.rfm_cluster_output a
left join loblaws.RFM b
on a.customer_id = b.customer_id)
with data;



select count(*) as num_customer,clusterid
from loblaws.RFM_Cluster
group by clusterid;

--RFM table stats
drop table loblaws.RFM_Statistics;


create table loblaws.RFM_Statistics as
(select  clusterid
       ,AVG(recency) as avg_recency
       ,MIN(recency) as min_recency 
       ,MAX(recency) as max_recency 
       ,AVG(frequency) as avg_freq 
       ,MIN(frequency) as min_freq 
       ,MAX(frequency) as max_freq
       ,AVG(monetary) as avg_monetary 
       ,MIN(monetary) as min_monetary 
       ,MAX(monetary) as max_monetary
       ,count(customer_id) as num_cust
from loblaws.RFM_Cluster
group by clusterid)
with data;



select * from loblaws.RFM_Statistics order by clusterid;

drop table loblaws.pos_cluster;

-- assign cluster id for each pos record


CREATE TABLE loblaws.pos_cluster  
as
(select
   a.customer_id, 
   a.txn_date, 
   a.txn_id, 
   a.product, 
   b.clusterid 
from loblaws.pos_training_new a
left join loblaws.rfm_cluster b
on a.customer_id = b.customer_id)
with data
;


	
select * from loblaws.pos_cluster;
select count(*) from loblaws.pos_cluster;
select distinct clusterid from loblaws.pos_cluster;
  

-- CFilter



select * from loblaws.pos_cluster_new


drop table loblaws.pos_cluster_new

create table loblaws.pos_cluster_new as
(select cast(customer_id as VARCHAR(100)) as customer_id,
txn_date,
txn_id,
product,
clusterid

from loblaws.pos_cluster)
with data


drop table loblaws.cf_pos_cluster_2;


SELECT * FROM CFilter (
 ON loblaws.pos_cluster_new AS InputTable
 OUT TABLE OutputTable (loblaws.cf_pos_cluster_2)
 USING
 TargetColumns ('customer_id')
 JoinColumns ('product')

) AS dt;

drop table loblaws.cf_pos_cluster_product_2;


select * from loblaws.cf_pos_cluster_product_2



select * from loblaws.pos_cluster_new

SELECT * FROM CFilter (
 ON loblaws.pos_cluster_new AS InputTable
 OUT TABLE OutputTable (loblaws.cf_pos_cluster_product_2)
 USING
 TargetColumns ('product')
 JoinColumns ('txn_id')

) AS dt;


select * from loblaws.cf_pos_cluster_product_2



--name=Customer_Affinity_without_bags
select * from loblaws.cf_pos_cluster_1 where Confidence>=0.1;
--name=Product_Affinity_without_bags
select * from loblaws.cf_pos_cluster_product_1 where Confidence>=0.1;

--name=Customer_Affinity_without_Accesories
select * from loblaws.cf_pos_cluster_2 where Confidence>=0.1;
--name=Product_Affinity_without_Accesories
select * from loblaws.cf_pos_cluster_product_2 where Confidence>=0.1;






-- recommendation
-- we will run recommendation on training set, and manually validate against actuals in the validation set. We will use existing 
--customers for validation. For examle: Customers who have made purchases prior to and after June 2016

drop table loblaws.pos_training_set1;

create table loblaws.pos_training_set1 as
(select * from loblaws.pos_training_new where customer_id in (select distinct(customer_id) from loblaws.pos_validation_new))
with data;



select * from loblaws.pos_training_set1;
select count(*)from loblaws.pos_training_set1;




-- Recommandations using WSRecommender 




select count(*) from loblaws.pos_training_set1;
select count(distinct(customer_id))from loblaws.pos_training_set1;




select * from loblaws.cf_pos_cluster_product_2 


select * from loblaws.pos_cluster_new



drop table loblaws.user_product_affinity

create table loblaws.user_product_affinity as
(select customer_id,product,count(*) as frequency from loblaws.pos_cluster_new group by customer_id,product) with data;

select * from loblaws.user_product_affinity


drop table loblaws.cf_recommendation

create table loblaws.cf_recommendation as

(
	SELECT * FROM WSRecommender (
	 ON (
	 SELECT * FROM WSRecommenderReduce (
	 ON (
	 SELECT * FROM loblaws.cf_pos_cluster_product_2 
	 ) AS item_table PARTITION BY col1_item1
	 ON (
	 SELECT * FROM loblaws.user_product_affinity
	 ) AS user_table PARTITION BY product
	 USING
	 Item1 ('col1_item1')
	 Item2 ('col1_item2')
	 ItemSimilarity ('cntb')
	 UserItem ('product')
	 UserID ('customer_id')
	 UserPref ('frequency')
	 ) AS dt1
	 ) AS temp_input_table PARTITION BY usr, col1_item2
	) AS dt2 )
with data;

--name=Recommendations
select * from loblaws.cf_recommendation;




--spliting strings



drop table  loblaws.cf_reco_split;

create table loblaws.cf_reco_split (
customer_id VARCHAR(100), 
item VARCHAR(200),
recommendation VARCHAR(100),
new_recommendation VARCHAR(100),
subbrand VARCHAR(100),
department VARCHAR(100),
category VARCHAR(100),
sub_category VARCHAR(100),
sleeve VARCHAR(100),
size VARCHAR(100),
product_type VARCHAR(100)
)
;

insert into loblaws.cf_reco_split 
 select  usr
        ,item
        ,recommendation
        ,new_reco_flag
        ,STRTOK(item,'_',1)
		,STRTOK(item,'_',2)
		,STRTOK(item,'_',3)
		,STRTOK(item,'_',4)
		,STRTOK(item,'_',5)
		,STRTOK(item,'_',6)
		,STRTOK(item,'_',7)
  from loblaws.cf_recommendation;
  
  
  
select * from loblaws.cf_reco_split 
  
  

  

  


 
--- ACCURACY CHECKS
-- check accuracy of cFilter recommendation
select * from loblaws.cf_reco_split  order by customer_id, recommendation desc;

select customer_id, count(recommendation)as cnt from loblaws.cf_reco_split where recommendation > 15
group by customer_id order by cnt desc  ;

select max(recommendation) from loblaws.cf_reco_split

select * from loblaws.cf_reco_split

drop table loblaws.cf_reco_split_top10;

create table loblaws.cf_reco_split_top10 as
  (
  select * from (select cf.*, row_number()over (partition by cf.customer_id order by cf.recommendation desc) as row_id from 
  loblaws.cf_reco_split cf) as A where row_id < 11
  
  ) with data;
  
  
  
select * from loblaws.cf_reco_split_top10; 


-- assuming a match in category, sub category, and sleev and product_type


subbrand||'_'||department||'_'||category||'-'||sub_category||'_'||sleeve|| '_' ||size|| '_'  ||product_type


select * from loblaws.cf_reco_split_top10

select distinct reco.recommendation,
	   act.customer_id as customer_id,
       reco.subbrand as reco_sub_brand,
	   act.subbrand  as act_sub_brand,
	   act.department as act_dept,
	   reco.department as reco_dept,
       reco.category  as reco_category,
       act.category   as act_category,
       reco.sub_category  as reco_sub_category,
       act.sub_category   as act_sub_category,
       reco.sleeve    as reco_sleeve,
       act.sleeve     as act_sleeve,
       reco.product_type as reco_product_type,
       act.product_type  as act_product_type,
       reco.size    as reco_apparel_size ,
       act.size     as act_apparel_size
       
from   loblaws.cf_reco_split_top10 reco, 
       loblaws.pos_validation_new act
where act.customer_id = reco.customer_id
and act.department     = reco.department
  --and act.category     = reco.category
  --and act.sub_category = reco.sub_category
 --and act.sleeve       = reco.sleeve
  --and act.product_type          = reco.product_type
order by 
      act.customer_id,
      reco.recommendation desc
  ;
  
  
  
  --- Recall
  
  -----1
  
  select distinct 
	   act.customer_id as customer_id,
   
	   act.department as act_dept,
	  
       act.category   as act_category,
      
       act.sub_category   as act_sub_category,
     
       act.sleeve     as act_sleeve,
   
       act.product_type  as act_product_type from loblaws.pos_validation_new act
  
       
  
       
       select distinct
	   act.customer_id as customer_id,
     
	   act.department as act_dept,
	   reco.department as reco_dept,
       reco.category  as reco_category,
       act.category   as act_category,
       reco.sub_category  as reco_sub_category,
       act.sub_category   as act_sub_category,
       reco.sleeve    as reco_sleeve,
       act.sleeve     as act_sleeve,
       reco.product_type as reco_product_type,
       act.product_type  as act_product_type
      
       
from   loblaws.cf_reco_split_top10 reco, 
       loblaws.pos_validation_new act
where act.customer_id = reco.customer_id
and act.department     = reco.department
  and act.category     = reco.category
  and act.sub_category = reco.sub_category
 and act.sleeve       = reco.sleeve
  and act.product_type          = reco.product_type
order by 
      act.customer_id
      
      
      
       
       dep,cat,subcat,sleev,protype 41/2177
       
       
        -----2
  
  select distinct 
	   act.customer_id as customer_id,
   
	   act.department as act_dept,
	  
       act.category   as act_category,
      
       act.sub_category   as act_sub_category,
     
   
       act.product_type  as act_product_type from loblaws.pos_validation_new act
  
       
  
       
       select distinct 
	   act.customer_id as customer_id,
     
	   act.department as act_dept,
	   reco.department as reco_dept,
       reco.category  as reco_category,
       act.category   as act_category,
       reco.sub_category  as reco_sub_category,
       act.sub_category   as act_sub_category,

       reco.product_type as reco_product_type,
       act.product_type  as act_product_type
      
       
from   loblaws.cf_reco_split_top10 reco, 
       loblaws.pos_validation_new act
where act.customer_id = reco.customer_id
and act.department     = reco.department
  and act.category     = reco.category
  and act.sub_category = reco.sub_category
  and act.product_type          = reco.product_type
order by 
      act.customer_id
      
      
      
       
       dep,cat,subcat,protype 70/2039
       
       
               -----3
  
  select distinct 
	   act.customer_id as customer_id,
   
	   act.department as act_dept,
	  
       act.category   as act_category,
      
       act.sub_category   as act_sub_category
       
       from loblaws.pos_validation_new act
  
       
  
       
       select distinct 
	   act.customer_id as customer_id,
     
	   act.department as act_dept,
	   reco.department as reco_dept,
       reco.category  as reco_category,
       act.category   as act_category,
       reco.sub_category  as reco_sub_category,
       act.sub_category   as act_sub_category
      
       
from   loblaws.cf_reco_split_top10 reco, 
       loblaws.pos_validation_new act
where act.customer_id = reco.customer_id
and act.department     = reco.department
  and act.category     = reco.category
  and act.sub_category = reco.sub_category

order by 
      act.customer_id
      
      
      
       
       dep,cat,subcat, 131/1652
       
       
                      -----4
  
  select distinct 
	   act.customer_id as customer_id,
   
	   act.department as act_dept,
	  
       act.category   as act_category
       
       from loblaws.pos_validation_new act
  
       
  
       
       select distinct
	   act.customer_id as customer_id,
     
	   act.department as act_dept,
	   reco.department as reco_dept,
       reco.category  as reco_category,
       act.category   as act_category
      
       
from   loblaws.cf_reco_split_top10 reco, 
       loblaws.pos_validation_new act
where act.customer_id = reco.customer_id
and act.department     = reco.department
  and act.category     = reco.category


order by 
      act.customer_id
      
      
      
       
       dep,cat 198/904
       
       
       
       
                             -----5
  
  select distinct 
	   act.customer_id as customer_id,
   
	   act.department as act_dept
       
       from loblaws.pos_validation_new act
  
       
  
       
       select distinct 
	   act.customer_id as customer_id,
     
	   act.department as act_dept,
	   reco.department as reco_dept
      
       
from   loblaws.cf_reco_split_top10 reco, 
       loblaws.pos_validation_new act
where act.customer_id = reco.customer_id
and act.department     = reco.department



order by 
      act.customer_id
      
      
      
       
       dep 241/499
       
       
       
                             -----6
  
  select distinct 
	   act.customer_id as customer_id,
	  
       act.category   as act_category
       
       from loblaws.pos_validation_new act
  
       
  
       
       select distinct
	   act.customer_id as customer_id,
    
       reco.category  as reco_category,
       act.category   as act_category
      
       
from   loblaws.cf_reco_split_top10 reco, 
       loblaws.pos_validation_new act
where act.customer_id = reco.customer_id

  and act.category     = reco.category


order by 
      act.customer_id
      
      
      
       
       cat 148/266
       
       

  
  
       
       
       
       
  --------- Cofacto Model
        
  --- Recall
  
  -----1
  
       
 select * from loblaws.COFACTO_RECOMMENDATIONS
 
 
 drop table  loblaws.cofacto_reco_split;

create table loblaws.cofacto_reco_split (
customer_id VARCHAR(100), 
item VARCHAR(200),
recommendation VARCHAR(100),
new_recommendation VARCHAR(100),
subbrand VARCHAR(100),
department VARCHAR(100),
category VARCHAR(100),
sub_category VARCHAR(100),
sleeve VARCHAR(100),
size VARCHAR(100),
product_type VARCHAR(100)
);

insert into loblaws.cofacto_reco_split 
 select  "user"
        ,item
        ,score
        ,2
        ,STRTOK(item,'_',1)
		,STRTOK(item,'_',2)
		,STRTOK(item,'_',3)
		,STRTOK(item,'_',4)
		,STRTOK(item,'_',5)
		,STRTOK(item,'_',6)
		,STRTOK(item,'_',7)
  from loblaws.COFACTO_RECOMMENDATIONS;
  
  
  select * from loblaws.cofacto_reco_split

 
  select distinct 
	   act.customer_id as customer_id,
   
	   act.department as act_dept,
	  
       act.category   as act_category,
      
       act.sub_category   as act_sub_category,
     
       act.sleeve     as act_sleeve,
   
       act.product_type  as act_product_type from loblaws.pos_validation_new act
  
       
  
       
       select distinct
	   act.customer_id as customer_id,
     
	   act.department as act_dept,
	   reco.department as reco_dept,
       reco.category  as reco_category,
       act.category   as act_category,
       reco.sub_category  as reco_sub_category,
       act.sub_category   as act_sub_category,
       reco.sleeve    as reco_sleeve,
       act.sleeve     as act_sleeve,
       reco.product_type as reco_product_type,
       act.product_type  as act_product_type
      
       
from   loblaws.cofacto_reco_split reco, 
       loblaws.pos_validation_new act
where act.customer_id = reco.customer_id
and act.department     = reco.department
  and act.category     = reco.category
  and act.sub_category = reco.sub_category
 and act.sleeve       = reco.sleeve
  and act.product_type          = reco.product_type
order by 
      act.customer_id
      
      
      
       
       dep,cat,subcat,sleev,protype 273/2177
       
       
        -----2
  
  select distinct 
	   act.customer_id as customer_id,
   
	   act.department as act_dept,
	  
       act.category   as act_category,
      
       act.sub_category   as act_sub_category,
     
   
       act.product_type  as act_product_type from loblaws.pos_validation_new act
  
       
  
       
       select distinct 
	   act.customer_id as customer_id,
     
	   act.department as act_dept,
	   reco.department as reco_dept,
       reco.category  as reco_category,
       act.category   as act_category,
       reco.sub_category  as reco_sub_category,
       act.sub_category   as act_sub_category,

       reco.product_type as reco_product_type,
       act.product_type  as act_product_type
      
       
from   loblaws.cofacto_reco_split reco, 
       loblaws.pos_validation_new act
where act.customer_id = reco.customer_id
and act.department     = reco.department
  and act.category     = reco.category
  and act.sub_category = reco.sub_category
  and act.product_type          = reco.product_type
order by 
      act.customer_id
      
      
      
       
       dep,cat,subcat,protype 275/2039
       
       
               -----3
  
  select distinct 
	   act.customer_id as customer_id,
   
	   act.department as act_dept,
	  
       act.category   as act_category,
      
       act.sub_category   as act_sub_category
       
       from loblaws.pos_validation_new act
  
       
  
       
       select distinct 
	   act.customer_id as customer_id,
     
	   act.department as act_dept,
	   reco.department as reco_dept,
       reco.category  as reco_category,
       act.category   as act_category,
       reco.sub_category  as reco_sub_category,
       act.sub_category   as act_sub_category
      
       
from   loblaws.cofacto_reco_split reco, 
       loblaws.pos_validation_new act
where act.customer_id = reco.customer_id
and act.department     = reco.department
  and act.category     = reco.category
  and act.sub_category = reco.sub_category

order by 
      act.customer_id
      
      
      
       
       dep,cat,subcat, 255/1652
       
       
                      -----4
  
  select distinct 
	   act.customer_id as customer_id,
   
	   act.department as act_dept,
	  
       act.category   as act_category
       
       from loblaws.pos_validation_new act
  
       
  
       
       select distinct
	   act.customer_id as customer_id,
     
	   act.department as act_dept,
	   reco.department as reco_dept,
       reco.category  as reco_category,
       act.category   as act_category
      
       
from   loblaws.cofacto_reco_split reco, 
       loblaws.pos_validation_new act
where act.customer_id = reco.customer_id
and act.department     = reco.department
  and act.category     = reco.category


order by 
      act.customer_id
      
      
      
       
       dep,cat 218/904
       
       
       
       
                             -----5
  
  select distinct 
	   act.customer_id as customer_id,
   
	   act.department as act_dept
       
       from loblaws.pos_validation_new act
  
       
  
       
       select distinct 
	   act.customer_id as customer_id,
     
	   act.department as act_dept,
	   reco.department as reco_dept
      
       
from   loblaws.cofacto_reco_split reco, 
       loblaws.pos_validation_new act
where act.customer_id = reco.customer_id
and act.department     = reco.department



order by 
      act.customer_id
      
      
      
       
       dep 173/499
       
       
       
                             -----6
  
  select distinct 
	   act.customer_id as customer_id,
	  
       act.category   as act_category
       
       from loblaws.pos_validation_new act
  
       
  
       
       select distinct
	   act.customer_id as customer_id,
    
       reco.category  as reco_category,
       act.category   as act_category
      
       
from   loblaws.cofacto_reco_split reco, 
       loblaws.pos_validation_new act
where act.customer_id = reco.customer_id

  and act.category     = reco.category


order by 
      act.customer_id
      
      
      
       
       cat 120/266
     
       
       
     