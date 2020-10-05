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
cities_db <- get_towns(regions)
text <- get_text(language)

# Define UI
ui <- fluidPage(

   # Application title
   titlePanel(text$Title),

   # Sidebar with a slider input for number of bins
   sidebarLayout(
      sidebarPanel(
        selectInput('town_name', text$ChooseCity, cities_db$name),
        helpText(text$ChooseTime),
        radioButtons('time_scheme', text$DisplayTime, 
                     choiceValues = c('Daylight saving time in summer', 'Winter time all year', 'Summer time all year') , 
                     choiceNames = c(text$WithDST, text$WithWinter, text$WithSummer))
      ),

      # Show output
      mainPanel(
         plotOutput('lightPlot'),
         h6(text$EarlierSunrise),
         textOutput('earlier_sunrise'),
         h6(text$EarlierSunset),
         textOutput('earlier_sunset'),
         h6(text$LatestSunrise),
         textOutput('later_sunrise'),
         h6(text$LatestSunset),
         textOutput('later_sunset'),
         h4('Pablo Rodríguez-Sánchez (pabrod.github.io)')
      )
   )
)

# Define server logic
server <- function(input, output) {

  # Parameters
  city_selected <- reactive({
    city_selected <- filter(cities_db, name %in% input$town_name)
  })

  daylight_saving <- reactive({
    identical(input$time_scheme, 'Daylight saving time in summer')
  })

  summer_time <- reactive({
    identical(input$time_scheme, 'Summer time all year')
  })

  times <- reactive({
    ## Set position
    city <- city_selected()

    ## Set conditions
    daylight_saving <- daylight_saving()
    summer_time <- summer_time()

    case <- get_case(daylight_saving, summer_time, city)

    ## Get the sunrise and sunset times
    times <- get_sunlight_times(city$lat, city$lon, case)

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
    plot_result(times, text)

  })

}

# Run the application
shinyApp(ui = ui, server = server)
