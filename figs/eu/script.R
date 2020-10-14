# This script generates the figures present in the folder

# Load libraries and functions
library(parallel)
numCores <- parallel::detectCores()
source('./auxs.R')

# Get the desired city names
cities_eu <- get_towns(regions_generator(), pop_threshold = 5e5)
city_names <- cities_eu$name

# Perform create all the plots (if multiple cores are available, this process will be parallelised)
mclapply(city_names, 
         function(city_name) plot_static_city(city_name, save_path = "./figs/eu/", language = "EN"), 
         mc.cores = numCores - 1)
