----pSalsa -----


select clusterid,count(*) from loblaws.pos_cluster_new group by clusterid;

drop table loblaws.pos_cluster_1;

CREATE TABLE loblaws.pos_cluster_1 as
(select * from loblaws.pos_cluster_new
where clusterid = 1)
with data;


select * from loblaws.pos_cluster_1



drop table loblaws.user_product_nodes_tmp;

create TABLE loblaws.user_product_nodes_tmp   as

(SELECT  
    nodename
FROM 
(
select distinct product as nodename from loblaws.pos_cluster_new
UNION ALL
select distinct customer_id as nodename from loblaws.pos_cluster_new
) x)
with data;


select * from loblaws.user_product_nodes_tmp




drop table loblaws.user_product_nodes ;

create table loblaws.user_product_nodes 
as (
SELECT ROW_NUMBER() OVER (ORDER BY tab1.nodename) as nodeid,
tab1.nodename as nodename
FROM loblaws.user_product_nodes_tmp tab1) with data;

select * from  loblaws.user_product_nodes

--input


drop table  loblaws.user_product_log ;


create TABLE loblaws.user_product_log as
(select customer_id as username
      ,product as product
      ,count(1) as frequency
from loblaws.pos_cluster_new
group by customer_id , product)
with data;

select * from loblaws.user_product_log




drop table loblaws.user_product_nodes_new

create table loblaws.user_product_nodes_new as
(select cast(cast(nodeid as integer) as VARCHAR(100)) as nodeid,
cast(nodename as VARCHAR(200)) as nodename


from loblaws.user_product_nodes)
with data




drop table loblaws.user_product_log_new

create table loblaws.user_product_log_new as
(select cast(username as VARCHAR(200)) as userid,
cast(product as VARCHAR(200)) as product,
frequency


from loblaws.user_product_log)
with data


select * from loblaws.user_product_nodes_new
select * from loblaws.user_product_log_new


drop table loblaws.user_product_salsa


create table loblaws.user_product_salsa as
(
SELECT * FROM PSALSA (
ON loblaws.user_product_nodes_new AS vertices PARTITION BY nodename
ON loblaws.user_product_log_new AS edges PARTITION BY userid

USING  SourceKey ('userid')
TargetKey ('product')
EdgeWeight ('frequency')
MaxHubNum (2)
MaxAuthorityNum (2)
TeleportProb (0.15)
RandomWalkLength (500) ) AS dt

) with data;



select userid,authority_product,authority_score from loblaws.user_product_salsa where userid='100725'



 
select * from loblaws.user_product_salsa

--name--u_u_affinity
select   ('[' || userid || ',' || hub_userid || ']') as path
  ,hub_score as cnt;
FROM loblaws.user_product_salsa where path is not null

--name--u_p_affinity
select   ('[' || userid || ',' || authority_product || ']') as path
  ,authority_score as cnt
FROM loblaws.user_product_salsa where path is not null



 

select * from loblaws.user_product_salsa

select distinct userid,authority_product from loblaws.user_product_salsa where authority_product is not null





drop table  loblaws.ps_reco_split;

create table loblaws.ps_reco_split (
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

insert into loblaws.ps_reco_split 
 select  userid
        ,authority_product
        ,authority_score
        ,2
        ,STRTOK(authority_product,'_',1)
		,STRTOK(authority_product,'_',2)
		,STRTOK(authority_product,'_',3)
		,STRTOK(authority_product,'_',4)
		,STRTOK(authority_product,'_',5)
		,STRTOK(authority_product,'_',6)
		,STRTOK(authority_product,'_',7)
	

  from loblaws.user_product_salsa where authority_product is not null
  
  

select * from loblaws.ps_reco_split 
  


create table loblaws.ps_reco_split_top10 as
  (
  select * from (select ps.*, row_number()over (partition by ps.customer_id order by ps.recommendation desc) as row_id from 
  loblaws.ps_reco_split ps) as A where row_id < 11
  
  ) with data;
  
  

 --- Average Recall
 
  
  -----1
  
  select distinct 
	   act.customer_id as customer_id,
   
	   act.department as act_dept,
	  
       act.category   as act_category,
      
       act.sub_category   as act_sub_category,
     
       act.sleeve     as act_sleeve,
   
       act.product_type  as act_product_type from loblaws.pos_validation_new act
  
       
       
       select distinct userid,authority_product from loblaws.user_product_salsa where authority_product is not null

  
       
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
      
       
from   loblaws.ps_reco_split_top10 reco, 
       loblaws.pos_validation_new act
where act.customer_id = reco.customer_id
and act.department     = reco.department
  and act.category     = reco.category
  and act.sub_category = reco.sub_category
 and act.sleeve       = reco.sleeve
  and act.product_type          = reco.product_type
order by 
      act.customer_id
      
      
      
       
       dep,cat,subcat,sleev,protype 12/2177
       
       
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
      
       
from   loblaws.ps_reco_split_top10 reco, 
       loblaws.pos_validation_new act
where act.customer_id = reco.customer_id
and act.department     = reco.department
  and act.category     = reco.category
  and act.sub_category = reco.sub_category
  and act.product_type          = reco.product_type
order by 
      act.customer_id
      
      
      
       
       dep,cat,subcat,protype 12/2039
       
       
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
      
       
from   loblaws.ps_reco_split_top10 reco, 
       loblaws.pos_validation_new act
where act.customer_id = reco.customer_id
and act.department     = reco.department
  and act.category     = reco.category
  and act.sub_category = reco.sub_category

order by 
      act.customer_id
      
      
      
       
       dep,cat,subcat, 19/1652
       
       
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
      
       
from   loblaws.ps_reco_split_top10 reco, 
       loblaws.pos_validation_new act
where act.customer_id = reco.customer_id
and act.department     = reco.department
  and act.category     = reco.category


order by 
      act.customer_id
      
      
      
       
       dep,cat 28/904
       
       
       
       
                             -----5
  
  select distinct 
	   act.customer_id as customer_id,
   
	   act.department as act_dept
       
       from loblaws.pos_validation_new act
  
       
  
       
       select distinct 
	   act.customer_id as customer_id,
     
	   act.department as act_dept,
	   reco.department as reco_dept
      
       
from   loblaws.ps_reco_split_top10 reco, 
       loblaws.pos_validation_new act
where act.customer_id = reco.customer_id
and act.department     = reco.department



order by 
      act.customer_id
      
      
      
       
       dep 32/499
       
       
       
                             -----6
  
  select distinct 
	   act.customer_id as customer_id,
	  
       act.category   as act_category
       
       from loblaws.pos_validation_new act
  
       
  
       
       select distinct
	   act.customer_id as customer_id,
    
       reco.category  as reco_category,
       act.category   as act_category
      
       
from   loblaws.ps_reco_split_top10 reco, 
       loblaws.pos_validation_new act
where act.customer_id = reco.customer_id

  and act.category     = reco.category


order by 
      act.customer_id
      
      
      
       
       cat 38/266
       
       




