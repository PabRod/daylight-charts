rm(list = ls())
library(parallel)
numCores <- parallel::detectCores()
source('auxs.R')

# Config
population_threshold <- 100000

# Create the dataset
cities_es <- get_towns(c('Spain', 'Canary Islands'), population_threshold)
city_names <- cities_es$name


mclapply(city_names, function(city_name) plot_static_city(city_name, population_threshold = population_threshold, save_path = "./img/es/"), mc.cores = numCores - 1)