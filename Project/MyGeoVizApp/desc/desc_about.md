# Michigan Homelessness Visualization App

> Author: Haolin Li (haolinli@umich.edu)
>
> Last Updated: 12/13/2023



## Overview

The Michigan Homelessness Visualization App is an interactive web application designed to provide insights into the state of homelessness in Michigan. It aims to offer a comprehensive view of the homelessness landscape, aiding in informed decision-making and policy development.



## Data Sources

The data for this application is sourced from two primary locations:

- **Continuum of Care (CoC) Data**: Provided by the U.S. Department of Housing and Urban Development (HUD), this dataset includes information about each CoC, such as CoC Name, CoC Number, Annual Renewal Demand (ARD), Preliminary Pro-Rata Need (PPRN), and Final Pro-Rata Need (FPRN).
- **County Boundary Data**: Geographical boundaries for Michigan's counties, which are essential for overlaying CoC data.

The application also uses historical data spanning from 2007 to 2022, detailing various metrics related to homelessness in each CoC zone within Michigan.



## Technical Architecture

The application is built using the following technologies:

- **R Shiny**: A framework for building interactive web applications directly from R.
- **Leaflet**: An open-source JavaScript library for mobile-friendly interactive maps, integrated with R Shiny for geographical data visualization.
- **readxl and dplyr**: R packages used for data manipulation and processing.
- **shinydashboard**: An R package that provides functions to build dashboards.



## Page Organization

The web application is structured into several key components:

- **Header**: Displays the title of the application.
- **Sidebar**: Contains interactive controls such as checkboxes to toggle the visibility of CoC and county boundaries, and a descriptive box explaining key terms and data sources.
- **Main Panel**: Shows the interactive map, where users can click on different CoC zones or counties to view detailed information in pop-up windows.

The application is designed to be user-friendly, allowing users to interact with the map and toggle different layers for a more customized view of the data.



## References

- https://github.com/Hong-Kong-Districts-Info/hktrafficcollisions/
- https://github.com/byollin/Isolines
- https://rstudio.github.io/DT/shiny.html



