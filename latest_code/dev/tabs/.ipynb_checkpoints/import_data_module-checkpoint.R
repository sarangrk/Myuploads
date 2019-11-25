project <- "driven-teradata"
token <- "~/driven-teradata-ccafee4c6309.json"
set_service_token(token)
#####  BKP ###
#sql <- " SELECT SHOP, PRODUCT,  DATE, LOST_DEMAND, STOCK_LEVEL , 
#avg(PRICE) as PRICE, avg(LICOST) as LICOST,  RAIN , SNOW, avg(APPLIED_MKDOWN) as APPLIED_MKDOWN, sum(DEMANDED_PRODUCT) as DEMANDED_PRODUCT
#FROM `driven-teradata.t5analytics.Final_View_From_New_Table` 
#where PRODDUCTGROUP in ('BIG4', 'OIL CHANGE')
#and SHOP in ('0301', '0047','0053', '0003') 
#group by 1,2,3,4,5,8,9
#"

sql<- "SELECT 
     SHOP
, PRODUCT
,  DATE
, LOST_DEMAND
, STOCK_LEVEL 
, avg(PRICE) as PRICE
, avg(LICOST) as LICOST
, ifnull(RAIN, 0) as  RAIN
, ifnull(SNOW, 0)  as SNOW
, avg(APPLIED_MKDOWN) as APPLIED_MKDOWN
, sum(DEMANDED_PRODUCT) as DEMANDED_PRODUCT
FROM `driven-teradata.t5analytics.Final_View_From_New_Table` 
where PRODDUCTGROUP in ('BIG4', 'OIL CHANGE') and SHOP in ('0301', '0047','0053', '0003') 
group by 1,2,3,4,5,8,9 "




bqtab <- bq_project_query(project, sql)
results_data <- bq_table_download(bqtab)
#saveRDS(results_data, file = "results.rds")
################# not in use for someTime ######################

sql <- " SELECT  PRODUCT    AS  PRODUCT,
PRODUCT            AS NAME,
PRODDUCTGROUP      as CATEGORY, 
'high'             as ROTATION_CLASS,
1                  as PRICE_ELASTICITY,
AVg(LICOST)            AS  COST,
AVG(PRICE)              as PRICE,
ifnull(NEARBYCAR, 0)          as NEARBYCAR
, ifnull(Count_DIRECT_COMPETITOR, 0)  as DIRECT_COMPETITOR
, ifnull(Count_INDIRECT_COMPETITOR, 0) as INDIRECT_COMPETITOR
, ifnull(STORE_SATURATION, 0) as STORE_SATURATION 
,  IS_HOLIDAY as IS_HOLIDAY
FROM `driven-teradata.t5analytics.Final_View_From_New_Table` 
where PRODDUCTGROUP in ('BIG4', 'OIL CHANGE')
group by 1,2,3,4,5 ,8,9,10,11,12 "

bqtab <- bq_project_query(project, sql)
product_data <- bq_table_download(bqtab)
#saveRDS(product_data, file = "products.rds")
###############################################################


############### dataset for Price  ##########################
sql<- "SELECT
RH.storeNum as storeNum1,
RH.ReceiptDate as date,
sm.ProductSubGroup,
count(rh.ReceiptID) as count_of_ReceiptID,
round(avg( LineItemTotal ),2) as AvgLineItemTotal
FROM `driven-data-proto.teradata.ReceiptHeaders` rh
INNER JOIN `driven-data-proto.teradata.ReceiptLineItems` li   on rh.ReceiptID = li.ReceiptID
INNER JOIN `driven-data-proto.teradata.SkuMap` sm   On Concat(TRIM(li.ProductCode), '-', TRIM(li.Service)) = sm.ProductSKU
where
sm.ProductGroup in ('BIG4', 'OIL CHANGE') 
AND RH.ReceiptDate  > '2018-01-01' 
#and ProductSubGroup='RADIATOR'
#AND RH.storeNum='0301'
group by
RH.storeNum
,RH.ReceiptDate
,sm.ProductSubGroup
 "

Price_Store_Wise <- bq_project_query(project, sql)
Price_Store_Wise_Data <- bq_table_download(Price_Store_Wise)
#print(Price_Store_Wise_Data)

######################data For address  ##################

sql <- "SELECT lpad(License_Number, 4, '0') as License_Number, Center_Email2, Location_Address ,Location_City ,  Location_State  FROM `driven-data-proto.teradata.DrivenBrandsShopMaster` where alignment_brand = 'Take 5'"

store <- bq_project_query(project, sql)
Store_Date <- bq_table_download(store)
#print(Store_Date)

#####################################################

if(!("NAME" %in% names(product_data))) product_data$NAME <- product_data$PRODUCT

df_processed <-  results_data %>%
  mutate(SALES = DEMANDED_PRODUCT - LOST_DEMAND,
         OOS = ifelse(STOCK_LEVEL < DEMANDED_PRODUCT, 1, 0),
         log_sales = log(SALES + 1),
         log_demand = log(DEMANDED_PRODUCT + 1),
         log_price = log(PRICE),
         ds = as.POSIXct(DATE)) %>%
  inner_join(product_data %>%
               select(PRODUCT, NAME, CATEGORY, COST, ROTATION_CLASS, PRICE_ELASTICITY, NEARBYCAR,DIRECT_COMPETITOR, INDIRECT_COMPETITOR, STORE_SATURATION,IS_HOLIDAY  ), by = 'PRODUCT') %>%
  select(ds, PRODUCT, SHOP, NAME, CATEGORY, ROTATION_CLASS, DEMANDED_PRODUCT, log_demand,
         STOCK_LEVEL, OOS, PRICE, log_price, SALES, log_sales, APPLIED_MKDOWN, LICOST, PRICE_ELASTICITY, RAIN, SNOW,NEARBYCAR,DIRECT_COMPETITOR, INDIRECT_COMPETITOR, STORE_SATURATION,IS_HOLIDAY   ) %>%
  # mutate(PRODUCT = factor(PRODUCT),
  #        SHOP = factor(SHOP)) %>%
  group_by(PRODUCT, SHOP) %>%
  mutate(STOCK_MORNING = lag(STOCK_LEVEL)) %>%
  ungroup 


print(df_processed)



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
  select(ds, y, log_price, RAIN, SNOW, PRODUCT, SHOP, NAME, ROTATION_CLASS
         , IS_HOLIDAY 
        
        )

###################kaptan Test Work ################################
#teststore <-  reactive_list$workflow@data@training_set$SHOP %>% filter(SHOP == input$store)
#print(teststore)
