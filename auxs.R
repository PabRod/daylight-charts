# Libraries
library(suncalc)
library(lubridate)
library(ggplot2)
library(scales)
library(dplyr)
library(maps)

# Functions
get_spanish_towns <- function () {
  
  cities_db <- filter(world.cities, country.etc == 'Spain', lat > 30) # Exclude Canary Islands
  cities_db <- select(cities_db, name, lat, long)
  
  return(cities_db)
}

cities_db <- get_spanish_towns()

get_case <- function (daylight_saving, summer_time) {
  case <- list()
  
  if(daylight_saving) {
    case$tz <- 'CET'
    case$shift <- 0 # CET (GMT + 1 in winter, GMT + 2 in summer)
  } else if(!summer_time) {
    case$tz <- 'GMT'
    case$shift <- 1 # GMT + 1 all year
  } else if (summer_time) {
    case$tz <- 'GMT'
    case$shift <- 2 # GMT + 2 all year
  }
  
  return(case)
}

get_sunlight_times <- function(lat, lon, case) {
  keep <- c('sunrise', 'sunset')
  
  initDate <- as.Date('2019-01-01')
  dates <- initDate
  for(i in 2:365) {
    dates[i] <- initDate + i - 1
  }
  
  output <- getSunlightTimes(date = dates, lat = lat, lon = lon, tz = case$tz, keep = keep)
  output <- mutate(output, date = as_date(date))
  output <- mutate(output, sunrise_decimal = hour(sunrise) + case$shift + minute(sunrise)/60 + second(sunrise)/3600)
  output <- mutate(output, sunrise = sunrise + hours(case$shift))
  output <- mutate(output, sunset_decimal = hour(sunset) + case$shift + minute(sunset)/60 + second(sunset)/3600)
  output <- mutate(output, sunset = sunset + hours(case$shift))
  output <- mutate(output, day_duration = sunset_decimal - sunrise_decimal)
  
  return(output)
}

plot_result <- function(data) {
  p <- ggplot(data = data, aes(ymin = 0, ymax = 24))
  p <- p + geom_ribbon(aes(x = date, ymin = sunrise_decimal, ymax = sunset_decimal, fill = 'Horas de sol'))
  p <- p + theme_dark()
  p <- p + theme(axis.text.x = element_text(angle = 45, hjust = 1))
  p <- p + scale_x_date(date_labels = "%d %b", date_breaks = '1 month')
  p <- p + scale_y_continuous(breaks = seq(0, 24, 2))
  p <- p + coord_cartesian(ylim = c(0, 24))
  p <- p + labs(title = 'Horas de sol', subtitle = 'En 2019')
  p <- p + xlab('Fecha') + ylab('Hora')
  p <- p + guides(fill = FALSE)
  
  print(p)
}