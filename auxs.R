# Libraries
library(suncalc)
library(lubridate)
library(ggplot2)
library(scales)
library(dplyr)
library(maps)

# Functions
get_spanish_towns <- function () {

  # The peninsular, balearic and african cities are in the database
  cities_pen <- filter(world.cities, country.etc == 'Spain', lat > 30) # Exclude Canary Islands
  cities_pen <- select(cities_pen, name, lat, long)

  # The cities in the Canary islands have to be hardcoded
  names_can <- c('Santa Cruz de Tenerife', 'Las Palmas de Gran Canaria')
  lat_can <- c(28.47, 28.13)
  lon_can <- c(-16.25, -15.43)
  cities_can <- data.frame(name = names_can, lat = lat_can, lon = lon_can)
  names(cities_can) <- names(cities_pen)

  # Paste them together
  cities <- rbind(cities_pen, cities_can)
  cities <- arrange(cities, name)

  return(cities)
}


get_towns <- function(countrylist) {
  
  cities <- filter(world.cities, country.etc %in% countrylist)
  cities <- select(cities, name, lat, long, country.etc)
  cities <- arrange(cities, name)
  
  return(cities)
  
}

cities_db <- get_towns(c("Netherlands", "Belgium"))

get_case <- function (daylight_saving, summer_time, city) {
  case <- list()

  if(city$lat > 30) { # Not Canary islands
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
  } else { # Canary islands
    if(daylight_saving) {
      case$tz <- 'WET'
      case$shift <- 0 # WET (GMT in winter, GMT + 1 in summer)
    } else if(!summer_time) {
      case$tz <- 'GMT'
      case$shift <- 0 # GMT all year
    } else if (summer_time) {
      case$tz <- 'GMT'
      case$shift <- 1 # GMT + 1 all year
    }
  }

  return(case)
}

get_sunlight_times <- function(lat, lon, case) {

  keep <- c('sunrise', 'sunset')

  initDate <- as.Date(paste(get_current_year(), '01', '01', sep = '-')) # January first of current year
  dates <- initDate
  for(i in 2:365) {
    dates[i] <- initDate + i - 1
  }

  output <- getSunlightTimes(date = dates, lat = lat, lon = lon, tz = case$tz, keep = keep)
  output <- mutate(output, date = as_date(date, locale = 'nl_NL.UTF-8'))
  output <- mutate(output, sunrise_decimal = hour(sunrise) + case$shift + minute(sunrise)/60 + second(sunrise)/3600)
  output <- mutate(output, sunrise = sunrise + hours(case$shift))
  output <- mutate(output, sunset_decimal = hour(sunset) + case$shift + minute(sunset)/60 + second(sunset)/3600)
  output <- mutate(output, sunset = sunset + hours(case$shift))
  output <- mutate(output, day_duration = sunset_decimal - sunrise_decimal)

  return(output)
}

plot_result <- function(data) {
  
  p <- ggplot(data = data, aes(ymin = 0, ymax = 24))
  p <- p + geom_ribbon(aes(x = date, ymin = sunrise_decimal, ymax = sunset_decimal, fill = 'Horas de sol'), fill = 'yellow', alpha = 0.5, color = 'yellow')
  p <- p + theme_dark()
  p <- p + theme(axis.text.x = element_text(angle = 45, hjust = 1))
  p <- p + scale_x_date(date_labels = "%d %b", date_breaks = '1 month')
  p <- p + scale_y_continuous(breaks = seq(0, 24, 2))
  p <- p + coord_cartesian(ylim = c(0, 24))
  p <- p + labs(title = 'Zonuren', subtitle = paste('In de jaar',  get_current_year(), sep = ' '))
  p <- p + xlab('Datum') + ylab('Uur')
  p <- p + guides(fill = FALSE)

  print(p)
}

get_current_year <- function() {
  
  year <- format(Sys.Date(), "%Y")
  return(year)
  
}
