#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(shinydashboard)
library(shinyWidgets)
library(leaflet)
library(DT)

ui <- dashboardPage(
  dashboardHeader(
    title = "Michigan Homelessness Visualization App",
    titleWidth = 500,
    
    tags$li(a(
      href = "https://humblepasty.shinyapps.io/mygeovizapp/",
      icon(name = "globe-asia"),
      title = "Website"
    ),
    class = "dropdown"
    ),
    tags$li(a(
      href = "https://github.com/HumblePasty/EAS648/tree/master/Project",
      icon("github"),
      title = "GitHub"
    ),
    class = "dropdown"
    ),
    tags$li(a(
      href = "mailto: go.haolinli@outlook.com",
      icon("envelope"),
      title = "Email Me"
    ),
    class = "dropdown"
    )
  ),
  
  
  dashboardSidebar(
    sidebarMenu(
      # homelessness map
      menuItem(" Homelessness in Michigan", tabName = "homeless", icon = icon("house-chimney-crack"))
    )
  ),
  
  
  dashboardBody(
    tags$style(type = "text/css", ".content {padding:0}"),
    tags$style(type = "text/css", ".box-body {padding:0}"),
    # tags$style(type = "text/css", ".col-sm-9 {padding:0}"),
    # tags$style(type = "text/css", "html, body, .container-fluid { height:100vh !important}"),
    
    # tags$head(
    #   tags$style(HTML('
    #     #controls {
    #       position: absolute;
    #       top: 50px;
    #       right: 20px;
    #       width: 300px;
    #       z-index: 400;
    #     }
    #     #homeless_table {
    #       position: absolute;
    #       height: 30vh;
    #       bottom: 20px;
    #       left: 20px;
    #       width: calc(100% - 40px);
    #       z-index: 400;
    #     }
    #     .leaflet-control {
    #       z-index: 401;
    #     }
    #   '))
    # ),
    # add custom css style for the data filter panel
    tags$head(
      tags$link(rel = "stylesheet", type = "text/css", href = "styles.css"),
      includeScript("gomap.js")
    ),
    
    # 使用 tabItems 来创建不同的页面内容
    tabItems(
      tabItem(tabName = "homeless",
        fluidRow(
          box(
            width = 12,
            title = span(icon("house-chimney-crack"), "Homelessness in Michigan"),
            column(
              width = 9,
              tags$style(type = "text/css", "#homeless_table {height:30vh !important}"),
              leafletOutput(outputId = "homeless_map", height = "50vh"),
              
              h4(span(icon("table"), "Homelessness Table")),
              
              DTOutput(outputId = "homeless_table")
            ),
            
            column(
              width = 3,
              h3(span(icon("circle-info")), "   ", "Descriptions"),
              h4("Data Source") %>% shinyhelper::helper(type = "markdown", colour = "#0d0d0d",
                                                        content = "desc_data_source"),
              p("Click the CoC zones on the map to explore these data!"),
              
              hr(),
              
              h3(span(icon("book")), "   ", "Glossaries"),
              h5("CoC") %>% shinyhelper::helper(type = "markdown", colour = "#0d0d0d",
                                                content = "desc_coc"),
              h5("ARD") %>% shinyhelper::helper(type = "markdown", colour = "#0d0d0d",
                                                content = "desc_ard"),
              h5("PPRN") %>% shinyhelper::helper(type = "markdown", colour = "#0d0d0d",
                                                 content = "desc_pprn"),
              h5("FPRN") %>% shinyhelper::helper(type = "markdown", colour = "#0d0d0d",
                                                 content = "desc_fprn"),
              
              hr(),
              
              # Options
              tags$style(type = "text/css", ".col-sm-3 {height: 93vh}"),
              id = "controls", class = "panel panel-default",
              
              h3(span(icon("gear")), "   ", "Options"),
              
              checkboxInput("show_coc", "Show CoC Areas", TRUE),
              checkboxInput("show_county", "Show County Boundaries", TRUE),
              selectInput("yearInput", "Year of Data", choices = 2007:2022, selected = 2021),
              
              fluidRow(
                column(6, actionButton("clear_markers", "Clear Map", icon = icon("eraser"))),
                column(6, actionButton("reset_view", "Reset View", icon = icon("globe")))
              ),
              
              hr()
            )
            
          )
        )
      )
    )
  )
)

