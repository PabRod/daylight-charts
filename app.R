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
         h6('Amanecer más temprano:'), 
         textOutput('earlier_sunrise'),
         h6('Anochecer más temprano:'),
         textOutput('earlier_sunset'),
         h6('Amanecer más tardío:'),
         textOutput('later_sunrise'),
         h6('Anochecer más tardío:'),
         textOutput('later_sunset'),
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
  
  output$earlier_sunrise <- reactive({
    times <- times()
    
    date <- filter(times, sunrise_decimal == min(sunrise_decimal))
    earlier_sunrise <- format(date$sunrise[1], format = '%d-%B %H:%M:%S')
  })
  
  output$earlier_sunset <- reactive({
    times <- times()
    
    date <- filter(times, sunset_decimal == min(sunset_decimal))
    earlier_sunset <- format(date$sunset[1], format = '%d-%B %H:%M:%S')
  })
  
  output$later_sunrise <- reactive({
    times <- times()
    
    date <- filter(times, sunrise_decimal == max(sunrise_decimal))
    later_sunrise <- format(date$sunrise[1], format = '%d-%B %H:%M:%S')
  })
  
  output$later_sunset <- reactive({
    times <- times()
    
    date <- filter(times, sunset_decimal == max(sunset_decimal))
    later_sunset <- format(date$sunset[1], format = '%d-%B %H:%M:%S')
  })
  
  output$lightPlot <- renderPlot({
    times <- times()
    
    ## Plot info
    plot_result(times)
    
  })
  
}

# Run the application 
shinyApp(ui = ui, server = server)

