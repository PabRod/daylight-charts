# This script generates the figures present in the folder

# Load libraries and functions
library(parallel)
numCores <- parallel::detectCores()
source('./auxs.R')

# Get the desired city names
cities_nl <- get_towns(c('Netherlands'), pop_threshold = 1e5)
city_names <- cities_nl$name

# Perform create all the plots (if multiple cores are available, this process will be parallelised)
mclapply(city_names, 
         function(city_name) plot_static_city(city_name, save_path = "./figs/nl/", language = "NL"), 
         mc.cores = numCores - 1)
