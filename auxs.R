# Libraries
library(suncalc)
library(lubridate)
library(ggplot2)
library(scales)
library(dplyr)
library(maps)
library(readr)

# Functions
# Auxiliary function that reads the csv file containing information in different languages
get_text <- function(language = "EN", file = "text.csv") {
  text <- read_csv(file)
  text <- filter(text, Language == language)
  
  return(text)
}

# Returns an ordered list of towns in the given list of countries
get_towns <- function(countrylist, pop_threshold = 0) {
  
  cities <- filter(world.cities, country.etc %in% countrylist & pop > pop_threshold)
  cities <- select(cities, name, lat, long, country.etc)
  cities <- arrange(cities, name)
  
  return(cities)
  
}

get_case <- function (daylight_saving, summer_time, city) {
  case <- list()

  if(city$country.etc != "Canary Islands") { # Canary islands are in a different time zone
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

plot_result <- function(data, text) {
  
  p <- ggplot(data = data, aes(ymin = 0, ymax = 24))
  p <- p + geom_ribbon(aes(x = date, ymin = sunrise_decimal, ymax = sunset_decimal), fill = 'yellow', alpha = 0.5, color = 'yellow')
  p <- p + theme_dark()
  p <- p + theme(axis.text.x = element_text(angle = 45, hjust = 1))
  p <- p + scale_x_date(date_labels = "%d %b", date_breaks = '1 month')
  p <- p + scale_y_continuous(breaks = seq(0, 24, 2))
  p <- p + coord_cartesian(ylim = c(0, 24), expand = FALSE)
  p <- p + labs(title = text$SunlightHours, subtitle = paste(text$DisplayYear, get_current_year(), sep = ' '))
  p <- p + xlab(text$Date) + ylab(text$Hour)
  p <- p + guides(fill = FALSE)

  print(p)
}

get_current_year <- function() {
  
  year <- format(Sys.Date(), "%Y")
  return(year)
  
}

# Information about european countries and its timezone
regions_generator <- function(save = FALSE) {
  regions <- c("Austria", "Belgium", "Bulgaria", "Croatia", "Cyprus",
               "Czech Republic", "Denmark", "Estonia", "Finland", "France",
               "Germany", "Greece", "Hungary", "Ireland", "Italy", 
               "Latvia", "Lithuania", "Luxembourg", "Malta", "Netherlands",
               "Poland", "Portugal", "Romania", "Slovakia", "Slovenia", 
               "Spain", "Sweden", "Canary Islands") #, "UK", "Norway", "Switzerland")
  
  timezone <- c("CET", "CET", "EET", "CET", "EET", 
                "CET", "CET", "EET", "EET", "CET",
                "CET", "EET", "CET", "WET", "CET",
                "EET", "EET", "CET", "CET", "CET",
                "CET", "WET", "EET", "CET", "CET",
                "CET", "CET", "WET")
  
  eu_regions <- data.frame(regions, timezone)
  
  if(save) write.csv(eu_regions, file = "eu_regions.csv")
  
  return(eu_regions)
}
