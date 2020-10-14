# This script generates the figures present in the folder

# Load libraries and functions
library(parallel)
numCores <- parallel::detectCores()
source('./auxs.R')

# Get the desired city names
cities_es <- get_towns(c('Spain', 'Canary Islands'), pop_threshold = 1e5)
city_names <- cities_es$name

# Perform create all the plots (if multiple cores are available, this process will be parallelised)
mclapply(city_names, 
         function(city_name) plot_static_city(city_name, save_path = "./figs/es/", language = "ES"), 
         mc.cores = numCores - 1)

# Add outliers
plot_static_city("Mahon", population_threshold = 1000, save_path = "./figs/es/", language = "ES")
