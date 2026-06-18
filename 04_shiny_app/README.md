# Heat Mortality Risk Forecast — R Shiny App Documentation

## Overview

This R Shiny application communicates forecasted heat-related mortality risk to the public. 
It translates epidemiological model output into an accessible, interactive interface that allows 
users to explore current and upcoming heat health risks across Switzerland at the district level.

## Data and methodology

The app visualizes output from the heat impact assessment pipeline (group `03_HIA`), which computes 
anomalies in heat-attributable mortality fractions and applies relative thresholds to classify 
heat exposure into four ordered mortality risk levels:

| Level | Description |
|-------|-------------|
| **None** | No elevated heat-related mortality risk |
| **Low** | Mildly elevated risk |
| **Medium** | Moderately elevated risk |
| **High** | Substantially elevated risk |

Risk levels are derived from historical exposure-response relationships and applied to 
temperature forecasts to generate a 5-day forward-looking risk profile for each Swiss district.

## User interface

The app is divided into two panels:

### Left panel — Map view
- A choropleth map of Switzerland displays the spatial distribution of heat mortality risk 
  for a selected day.
- Users can navigate between the current day and the four following forecast days using the 
  date buttons above the map.
- Clicking on a district highlights it and updates the risk timeline in the right panel.

### Right panel — District risk timeline
- A bar chart displays the day-by-day risk level for a selected district over the full 5-day 
  forecast window.
- Users can select a district in two ways:
  - **Map click**: clicking directly on a district in the map.
  - **Address search**: typing a location (street address, city, or canton) into the search bar. 
    The app queries the OpenStreetMap Nominatim API to identify the corresponding district.
- Below the chart, additional information is provided including risk level definitions, 
  recommended actions during heat events, and contact details for the authoring research group.

## Authors

Developed by the Climate Epidemiology and Public Health (CEPH) research group, 
Institute of Social and Preventive Medicine (ISPM), University of Bern.
