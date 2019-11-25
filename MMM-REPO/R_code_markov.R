install.packages("ChannelAttribution")

library(ChannelAttribution)

setwd <- setwd('C:\\Users\\KT250034\\PROJECTS\\MMM\\Offer_development')

df <- read.csv('Final_Path_count.csv')

df <- df[c(1,2)]

df[2]

M <- markov_model(df, 'Path', var_value = 'Conversion', var_conv = 'Conversion', sep = '>', order=1, out_more = TRUE)

write.csv(M$result, file = "Markov - Output - Conversion values.csv", row.names=FALSE)

write.csv(M$transition_matrix, file = "Markov - Output - Transition matrix.csv", row.names=FALSE)

