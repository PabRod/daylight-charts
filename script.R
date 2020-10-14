rm(list = ls())

source('auxs.R')
# Config
regions <- regions_generator()
population_threshold <- 1e5

# Create the dataset
cities_db <- get_towns(regions, pop_threshold = population_threshold)
timezones <- get_timezones(cities_db)
offsets <- do.call(rbind, lapply(timezones, get_utc_offset))
cities_db <- cbind(cities_db, timezones, offsets)
text <- get_text("ES") # Translate the site to the available languages (default = EN)

city_name <- "Santa Cruz de Tenerife"
city <- filter(cities_db, name == city_name)
times <- times_all(city)

plot_static(times, text)