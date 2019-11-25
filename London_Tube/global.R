if(!require(shiny))           {install.packages('shiny', dependencies = TRUE);require(shiny)}
if(!require(leaflet))         {install.packages('leaflet', dependencies = TRUE);require(leaflet)}
if(!require(dplyr))           {install.packages('dplyr', dependencies = TRUE);require(dplyr)}
if(!require(shinydashboard))         {install.packages('shinydashboard', dependencies = TRUE);require(shinydashboard)}
if(!require(readxl))           {install.packages('readxl', dependencies = TRUE);require(readxl)}

library(shiny)
library(leaflet)
library(dplyr)
#library(tidyr)
#library(tidyverse)
library(shinydashboard)
library(leaflet)
library(readxl)


df <- read_excel("location.xlsx")


#df_1 = read.csv("location_2.csv", stringsAsFactors = F)

my_loc<-data.frame(code=double(),place=character(),lattitude=double(), longitude=double())