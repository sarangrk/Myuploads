library(odbc)
library(dplyr)
library(dbplyr)
library(tdplyr)

con <- td_create_context(dsn="Teradata_Vantage", uid="GDCDS", pwd="GDCDS",database="loblaws")

con



sales_lp_aug <- read.csv('/Documents/Teradata/LobLaws/Retail/Arranged/data/Next_Recommandadtion/LP_08.2016.csv')

colnames(sales_lp_aug)

colnames(sales_lp_aug)<- c("Cal_Year_Month","Customer","Customer_1","Phone_number","AFS_Customer_Grp_10"
                        ,"Billing_doc_date","Billing_document","City","CATEGORY","Division"           
                        ,"Division_1","EAN_UPC","FG_PRODUCT_TYPE","Material","Promo_Bill_Level"   
                        ,"RETEK_DEPARTMENTS","RETEK_CLASS","RETEK_SUBCLASS","Region","Region_name"        
                        ,"SLEEVE_DETAILS","Size","Store_Type","Street_Name","Transaction_Type"   
                        ,"Time","PC","MRP","Discount","GSV"                
                        ,"NSV","COST","SURCHARGE","TAX_PER_ITEM","VAT"                
                        ,"Number_of_Records","Discount_1","Oddment_discount","Other_Deductions","Base_Cost"          
                        ,"COST2" )


pos <- read.csv('/Documents/Teradata/LobLaws/Retail/Arranged/data/Next_Recommandadtion/POS.csv')

colnames(pos)

head(pos)



crm_data

copy_to(con,pos,overwrite = TRUE,name = 'pos')


summary(sales_lp_aug)

summary(pos)

dim(pos)
dim(sales_lp_aug)

table(pos$Cust_Mob_No)





copy_to(con,crm_data,overwrite = TRUE,name = 'lob_crm')
copy_to(con,user_product_nodes,overwrite = TRUE,name = 'psalsa_user_product_nodes')
copy_to(con,women_apparel_log,overwrite = TRUE,name = 'psalsa_women_apparel_log')



cofacto_results <- read.csv('/Documents/Teradata/Teradata_Vantage/LobLaws/Solution/code/cofactor/COFACTO_RECOMMENDATIONS.csv')
copy_to(con,cofacto_results,overwrite = TRUE,name = 'COFACTO_RECOMMENDATIONS')
