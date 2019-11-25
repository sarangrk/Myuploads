ui <- fluidPage(
  
  leafletOutput("mymap", height=1000),
  plotOutput("pareto_chart")
)

