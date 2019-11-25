project <- "driven-teradata"
token <- "~/driven-teradata-ccafee4c6309.json"
set_service_token(token)


sql<- "
SELECT 
SHOP
, ltrim(Rtrim(PRODUCT)) as PRODUCT
,  DATE
, LOST_DEMAND
, STOCK_LEVEL 
, avg(net_PRICE)  as PRICE
#, ifnull(avg(PRICE),0) AS PRICE
, avg(LICOST) as LICOST
, ifnull(RAIN, 0) as  RAIN
, ifnull(SNOW, 0)  as SNOW
, avg(APPLIED_MKDOWN) as APPLIED_MKDOWN
, sum(UNITS) as DEMANDED_PRODUCT
, ifnull(NEARBYCAR, 0)          as NEARBYCAR
, ifnull(Count_DIRECT_COMPETITOR, 0)  as DIRECT_COMPETITOR
, ifnull(Count_INDIRECT_COMPETITOR, 0) as INDIRECT_COMPETITOR
, ifnull(STORE_SATURATION, 0) as STORE_SATURATION 
, 0 as IS_HOLIDAY
, ifnull(CLUSTER, 1) as CLUSTER
FROM `driven-teradata.t5analytics.Final_Trans_View`  
where  PRODDUCTGROUP in ('BIG4', 'OIL CHANGE') 
and SHOP not in (select * from  `driven-teradata.t5analytics.BadStoreNum`  )
and shop not in ('0228' ,'0048','0245','1002','1003','1004' )
#store don`t have data are ('0048','1002','1003','1004' )
#added store '0228' , '0245' should fail for RADIATOR
#)
#and shop in ('0001', '0003', '0217')
#,'0355' , '0397' , '0231' , '0217','0233','0282'
#'0233' , 0282 --RADIATOR, issue is in log price , has same amount
#'0217', 0231,0397,0355  --RADIATOR, no data
and  PRODUCT not like 'DIESEL%'
and net_price > 0
# and APPLIED_MKDOWN > 0
#and PRODUCT in ('SYNTHETIC','SYNBLEND','RADIATOR')
group by 1,2,3,4,5,8,9,12,13,14,15,16, 17 
"


bqtab <- bq_project_query(project, sql)
results_data <- bq_table_download(bqtab)
#saveRDS(results_data, file = 'data/results.rds')
#################  ######################

sql <- " SELECT  ltrim(Rtrim(PRODUCT)) as PRODUCT ,
ltrim(Rtrim(PRODUCT)) as NAME , 
PRODDUCTGROUP      as CATEGORY, 
'high'             as ROTATION_CLASS,
1                  as PRICE_ELASTICITY,
AVg(LICOST)            AS  COST,
avg(net_PRICE)  as PRICE
FROM `driven-teradata.t5analytics.Final_Trans_View` 
where  PRODDUCTGROUP in ('BIG4', 'OIL CHANGE')
and  PRODUCT not like 'DIESEL%'
group by 1,2,3,4,5
order by PRODUCT desc
"

bqtab <- bq_project_query(project, sql)
product_data <- bq_table_download(bqtab)
#saveRDS(product_data, file = 'data/products.rds')

###############################################################

sql<- "select  
round(Avg(prod.LineItemTotal),2) as AvgLineItemTotal
,count(rh.ReceiptID )as count_of_ReceiptID
,PRODUCT
,RH.storeNum  as storeNum1 
,RH.ReceiptDate  as date
from (
SELECT case when s1.mastergroup like '%DIESEL%' then concat('DIESEL ', s2.productsubgroup) else s2.productsubgroup end as PRODUCT,
li.LineItemTotal as LineItemTotal ,
li.ReceiptID as ReceiptID
FROM `driven-data-proto.teradata.ReceiptLineItems` li
left JOIN `driven-data-proto.teradata.Take5_ProductSKUTest` s1
On Concat(TRIM(li.ProductCode), '-', TRIM(li.Service)) = s1.ProductSKU
left join `driven-data-proto.teradata.SkuMap` s2
On Concat(TRIM(li.ProductCode), '-', TRIM(li.Service)) = s2.ProductSKU
where s2.productgroup in ('OIL CHANGE', 'BIG4') )
prod        
JOIN `driven-data-proto.teradata.ReceiptHeaders` rh 
on rh.ReceiptID = prod.ReceiptID  
where RH.ReceiptDate  > '2018-01-01' 
and PRODUCT not like 'DIESEL%'
group by
RH.storeNum
,RH.ReceiptDate
,PRODUCT "


Price_Store_Wise <- bq_project_query(project, sql)
Price_Store_Wise_Data <- bq_table_download(Price_Store_Wise)
#saveRDS(Price_Store_Wise_Data, file = 'data/Price_Store_Wise_opi.rds')
#print(Price_Store_Wise_Data)

######################data For Address  ##################

sql <- "SELECT lpad(License_Number, 4, '0') as License_Number, Center_Email2, Location_Address ,Location_City ,  Location_State  FROM `driven-data-proto.teradata.DrivenBrandsShopMaster` where alignment_brand = 'Take 5'"

store <- bq_project_query(project, sql)
Store_Date <- bq_table_download(store)
#saveRDS(Store_Date, file = 'data/Store_LOC_Date.rds')

#print(Store_Date)

################# data for store clustering  ####################################

sql<- " SELECT storenum, CN.cluster   as cluster, Location_Latitude, Location_Longitude , clustername
FROM `driven-teradata.t5analytics.StoreClusters`  SC 
JOIN `driven-data-proto.teradata.DrivenBrandsShopMaster` SM
ON SC.storenum = lpad( License_Number,4,'0')
LEFT JOIN `driven-teradata.t5analytics.ClusterNames`  CN
ON CN.cluster = SC.cluster
where Alignment_Brand = 'Take 5'  "

StoreCluster <- bq_project_query(project, sql)
store <- bq_table_download(StoreCluster)
#saveRDS(Store_Date, file = 'data/Store_Graph_Date.rds')

#################################################################
sql <- " select storeNum as SHOP,
CASE WHEN TRIM(Product) = 'Air Filters' Then 'AIR FILTER'
WHEN TRIM(Product) = 'Cabin Air Filters' then 'CABIN FILTER'
WHEN TRIM(Product) = 'Synthetic Blend (Oil Change-Gas)' then 'SYNBLEND'
WHEN TRIM(Product) = 'Conventional  (Oil Change-Gas)' then 'CONVENTIONAL'
WHEN TRIM(Product) = 'Conventional Wiper Blades' then 'WIPER BLADES'
WHEN TRIM(Product) = 'Full Synthetic (Oil Change-Gas)' then 'HIGHMILE'
WHEN TRIM(Product) = 'Advanced Synthetic (Oil Change-Gas)' then 'SYNTHETHIC'
ELSE NUll END as PRODUCT,
CompetitorAvgPrice as maxPrice
from `driven-teradata.t5analytics.max_price`
"

bqtab <- bq_project_query(project, sql)
Competitor_data <- bq_table_download(bqtab)
saveRDS(Competitor_data, file = 'data/Competitor_data.rds')

#################################################




if(!("NAME" %in% names(product_data))) product_data$NAME <- product_data$PRODUCT

df_processed <-  results_data %>%
  mutate(SALES = DEMANDED_PRODUCT - LOST_DEMAND,
         OOS = ifelse(STOCK_LEVEL < DEMANDED_PRODUCT, 1, 0),
         log_sales = log(SALES + 1),
         log_demand = log(DEMANDED_PRODUCT + 1),
         log_price = log(PRICE),
         #log_price = log(abs(PRICE)),
         ds = as.POSIXct(DATE)) %>%
  inner_join(product_data %>%
               select(PRODUCT, NAME, CATEGORY, COST, ROTATION_CLASS, PRICE_ELASTICITY), by = 'PRODUCT') %>%
  select(ds, PRODUCT, SHOP
         , CLUSTER
         , NAME, CATEGORY, ROTATION_CLASS, DEMANDED_PRODUCT, log_demand,
         STOCK_LEVEL, OOS, PRICE, log_price, SALES, log_sales, APPLIED_MKDOWN, LICOST, PRICE_ELASTICITY
         , RAIN
         , SNOW
         ,NEARBYCAR,DIRECT_COMPETITOR, INDIRECT_COMPETITOR, STORE_SATURATION,IS_HOLIDAY 
  ) %>%
  # mutate(PRODUCT = factor(PRODUCT),
  #        SHOP = factor(SHOP)) %>%
  group_by(PRODUCT, SHOP) %>%
  mutate(STOCK_MORNING = lag(STOCK_LEVEL)) %>%
  #mutate(STOCK_MORNING = (STOCK_LEVEL)) %>%
  ungroup 


# print(df_processed)



if(REMOVE_OOS){
  df_processsed <- df_processed %>%
    filter(!is.na(STOCK_MORNING),
           STOCK_MORNING > 0,
           STOCK_LEVEL > 0) 
}

if(!is.null(products_filter)){
  df_processed <- df_processed %>% 
    filter(PRODUCT %in% products_filter)
}

if(!is.null(shops_filter)){
  df_processed <- df_processed %>% 
    filter(SHOP %in% shops_filter)
}

if(!is.null(categories_filter)){
  df_processed <- df_processed %>% 
    filter(CATEGORY %in% categories_filter)
}

prod_weekly_demand <- df_processed %>% 
  group_by(PRODUCT, SHOP) %>% 
  mutate(week_demand = RcppRoll::roll_sum(DEMANDED_PRODUCT, 7, align ="left", na.rm=TRUE, fill=NA)) %>%
  group_by(PRODUCT) %>%
  summarise(mean_week_demand = round(mean(week_demand, na.rm=TRUE),0))



product_data <- product_data %>% inner_join(prod_weekly_demand, by="PRODUCT")




df_processed <- df_processed %>% 
  mutate_(y = Y) %>% 
  select(ds, y, log_price
         , RAIN
         , SNOW, PRODUCT, SHOP, NAME, ROTATION_CLASS
         , IS_HOLIDAY 
         ,NEARBYCAR
         ,DIRECT_COMPETITOR
         ,INDIRECT_COMPETITOR
         ,STORE_SATURATION
         ,CLUSTER
  )

