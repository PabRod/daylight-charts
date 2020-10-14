# Libraries
library(suncalc)
library(lubridate)
library(ggplot2)
library(scales)
library(dplyr)
library(maps)
library(readr)
library(lutz)
library(plyr)

# Functions
# Auxiliary function that reads the csv file containing information in different languages
get_text <- function(language = "EN", file = "text.csv") {
  
  text <- read_csv(file)
  
  if (language %in% get_available_languages(file)) { # Apply language only if it is supported
    text <- filter(text, Language == language)
  } else { # If an unsupported language is requested, show a warning an switch to English
    text <- filter(text, language == "EN")
    warning(paste("Available languages are:", get_available_languages(file, as.vector = FALSE), ". Setting language to EN."))
  }
  
  return(text)
}

get_available_languages <- function(file = "text.csv", as.vector = TRUE) {
  text <- read_csv(file)
  
  if(as.vector) return(text$Language)
  else return( paste(text$Language, collapse = ", ") ) # Useful for printing a human-readable string
}

# Returns an ordered list of towns in the given list of countries
get_towns <- function(countrylist, pop_threshold = 0) {
  
  cities <- filter(world.cities, country.etc %in% countrylist & pop > pop_threshold)
  cities <- select(cities, name, lat, long, country.etc)
  cities <- arrange(cities, name)
  
  return(cities)
  
}

# Use location to infer the timezone
get_timezones <- function(cities) {
  timezones <- tz_lookup_coords(lat = cities$lat, lon = cities$lon, method = "fast", warn = FALSE)
  
  return(timezones)
}

# Get the offset from UTC in hours
get_utc_offset <- function(timezone, winter = TRUE) {
  # A reference date is required due to possible daylight saving time
  year <- get_current_year()
  
  if(winter) { 
    date <- paste(get_current_year(), "01-01", sep = "-") # Use January as reference
  } else {
    date <- paste(get_current_year(), "06-01", sep = "-") # Use June as reference
  }
  
  offset <- tz_offset(date, timezone)
  offset <- select(offset, zone, utc_offset_h) # Keep only the interesting information
  
  return(offset)
}

get_case <- function (daylight_saving, summer_time, city) {
  
  if(daylight_saving) { # If daylight saving policy applies just return the ...
    
    case <- list(tz = city$zone, shift = 0) # ... official timezone (WE(S)T, CE(S)T, ...)
    
    return(case)
    
  } else { # If daylight policy doesn't apply, just return a fixed summer/winter time
    
    if(summer_time) case <- list(tz = "UTC", shift = city$utc_offset_h + 1)
    else case <- list(tz = "UTC", shift = city$utc_offset_h)
    
    return(case)
  }
  
}

# Return the case as a human readable string, such as GMT + 1 or CET
get_case_string <- function(case) {
  if (case$tz != "UTC") return(case$tz) # Such as CET
  else return(paste("UTC", as.character(case$shift), sep = " + ")) # Such as UTC + 1
}

get_sunlight_times <- function(lat, lon, case) {

  keep <- c('sunrise', 'sunset')

  initDate <- as.Date(paste(get_current_year(), '01', '01', sep = '-')) # January first of current year
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

times_all <- function(city) {

  cases <- list(standard = get_case(TRUE, FALSE, city),
                always_summer = get_case(FALSE, TRUE, city),
                always_winter = get_case(FALSE, FALSE, city))
  
  ## Get the sunrise and sunset times
  times_list <- lapply(cases, function(case) get_sunlight_times(city$lat, city$lon, case))
  times_df <- ldply(times_list)
  
  return(times_df)
}

plot_result <- function(data, text, case) {
  
  p <- ggplot(data = data, aes(ymin = 0, ymax = 24))
  p <- p + geom_ribbon(aes(x = date, ymin = sunrise_decimal, ymax = sunset_decimal), fill = 'yellow', alpha = 0.5, color = 'yellow')
  p <- p + theme_dark()
  p <- p + theme(axis.text.x = element_text(angle = 45, hjust = 1))
  p <- p + scale_x_date(date_labels = "%d %b", date_breaks = '1 month')
  p <- p + scale_y_continuous(breaks = seq(0, 24, 2))
  p <- p + coord_cartesian(ylim = c(0, 24), expand = FALSE)
  p <- p + labs(title = text$SunlightHours, subtitle = paste(text$DisplayYear, get_current_year(), sep = ' '))
  p <- p + xlab(text$Date) + ylab(paste(text$Hour, get_case_string(case), sep = " "))
  p <- p + guides(fill = FALSE)

  print(p)
}

plot_static_city <- function(city_name, regions = regions_generator(), population_threshold = 1e5) {

  # Create the dataset
  cities_db <- get_towns(regions, pop_threshold = population_threshold)
  timezones <- get_timezones(cities_db)
  offsets <- do.call(rbind, lapply(timezones, get_utc_offset))
  cities_db <- cbind(cities_db, timezones, offsets)
  text <- get_text("ES") # Translate the site to the available languages (default = EN)
  
  city <- filter(cities_db, name == city_name)
  times <- times_all(city)
  
  plot_static(times, text)
}

plot_static <- function(data, text) {
  p <- ggplot(data = data, aes(ymin = 0, ymax = 24))
  p <- p + geom_ribbon(data = subset(data, .id == "standard"), 
                       aes(x = date, ymin = sunrise_decimal, ymax = sunset_decimal), fill = 'yellow', alpha = 0.5, color = 'yellow')
  p <- p + geom_line(data = subset(data, .id == "always_winter"), 
                     aes(x = date, y = sunrise_decimal),
                     color = "blue")
  p <- p + geom_line(data = subset(data, .id == "always_winter"), 
                     aes(x = date, y = sunset_decimal),
                     color = "blue", alpha = 0.5)
  p <- p + geom_line(data = subset(data, .id == "always_summer"), 
                     aes(x = date, y = sunset_decimal),
                     color = "red")
  p <- p + geom_line(data = subset(data, .id == "always_summer"), 
                     aes(x = date, y = sunrise_decimal),
                     color = "red", alpha = 0.5)
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
               "Spain", "Sweden", "Canary Islands") # "UK", "Norway", "Switzerland")
  
  if(save) write.csv(regions, file = "eu_regions.csv")
  
  return(regions)
}
