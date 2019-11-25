
library(leaflet)
library(shiny)
library(tidyverse)
library(plotly)

df_custom <- readRDS("./sample_data.rds")

df_custom <- df_custom[1:30,]

df_custom$Group <- rep(c("A","B","C"),10)

df_custom$Color <- rep(c("#0000FF", "#FF0000"), 15)

x = rnorm(30)

# normalize
min.x = min(x)
max.x = max(x)

x.norm = (x - min.x)/(max.x - min.x + 1)

df_custom["FailureProbability"] <- x.norm 
df_custom <- df_custom[order(-df_custom$FailureProbability),]



type <- c("Radiator Failure","Axle Failure","Brake Failure","Light Failure","Engine Failure","Tire Failure")
freq <- as.numeric(c(175, 143, 110, 80, 74,67))

defects <- data.frame(type, freq)


defects <- arrange(defects, freq) %>%
  mutate(
    cumsum = cumsum(freq),
    temp = round(freq / sum(freq), 3),
    cum_freq = cumsum(temp)
  )
