#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
source('auxs.R')

# Define UI for application that draws a histogram
ui <- fluidPage(
   
   # Application title
   titlePanel('¿Cómo me afecta el cambio de hora?'),
   
   # Sidebar with a slider input for number of bins 
   sidebarLayout(
      sidebarPanel(
        selectInput('localidad', 'Selecciona tu localidad', cities_db$name),
        helpText('(Las islas Canarias están excluidas por motivos técnicos)'),
        helpText('Selecciona el tipo de horario'),
        radioButtons('horario', 'Tipo de horario:', c('Con cambio de hora', 'Sólo horario de invierno', 'Sólo horario de verano'))
      ),
      
      # Show a plot of the generated distribution
      mainPanel(
         plotOutput('lightPlot'),
         h4('Por Pablo Rodríguez (pabrod.github.io)')
      )
   )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
  
  # Parameters
  city_selected <- reactive({
    city_selected <- filter(cities_db, name %in% input$localidad)
  })
  
  daylight_saving <- reactive({
    identical(input$horario, 'Con cambio de hora')
  })
  
  summer_time <- reactive({
    identical(input$horario, 'Sólo horario de verano')
  })
  
  times <- reactive({
    ## Set position
    
    city <- city_selected()
    
    lat <- city$lat
    lon <- city$lon
    
    ## Set conditions
    daylight_saving <- daylight_saving()
    summer_time <- summer_time()
    
    case <- get_case(daylight_saving, summer_time)
    
    ## Clean results
    times <- get_sunlight_times(lat, lon, case)
    
    return(times)
  })
  
  extremes <- reactive({
    times <- times()
    extremes <- list()
    
    extremes$earlier_sunrise <- filter(times, sunrise_decimal == min(sunrise_decimal))
    extremes$earlier_sunset <- filter(times, sunset_decimal == min(sunset_decimal))
    extremes$later_sunrise <- filter(times, sunrise_decimal == max(sunrise_decimal))
    extremes$later_sunset <- filter(times, sunset_decimal == max(sunset_decimal))
  })
  
  output$lightPlot <- renderPlot({
    times <- times()
    
    ## Plot info
    plot_result(times)
  })
  
}

# Run the application 
shinyApp(ui = ui, server = server)

