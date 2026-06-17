# Creating dummy data for the risk map
# Switerland district level data
# Daily level for today and the next 5 days
# Risk level (1-5)
# In the end the data has date, district, and risk level

library(dplyr)
library(tidyr)
library(tidyverse)
# Load shapefile
library(sf)
library(readr)
library(shiny)
library(leaflet)

dummy_shiny_data <- read_csv("04_shiny_app/risk-map/dummy_shiny_data.csv")

shapefile_d <- read_sf("/Volumes/FS/_ISPM/CCH/AnnualTeamProject2026/Boundaries_G1_District_20260101/Boundaries_G1_District_20260101.shp") |>
  dplyr::select(BEZNAME, geometry)
shapefile_d <- sf::st_transform(shapefile_d, 4326)



setwd("~/Desktop/University of Bern/PhD/Projects/Team Project June 2026/team_project_june_26/04_shiny_app/emilie-app")

shapefile_municipality = read_sf("AMTOVZ_SHP_LV95/AMTOVZ_LOCALITY.shp")
data_postcode <- read_delim("georef-switzerland-postleitzahl.csv",
                                              delim = ";", escape_double = FALSE, trim_ws = TRUE)

geo <- st_read("georef-switzerland-postleitzahl.geojson")


source("ui.R")
source("server.R")

shinyApp(ui = ui, server = server)
