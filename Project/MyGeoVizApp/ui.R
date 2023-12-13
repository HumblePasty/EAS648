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
      # main map
      menuItem(" CoC in Michigan", tabName = "map", icon = icon("map")),
      # homelessness tab
      menuItem(" Homelessness in Michigan", tabName = "homeless", icon = icon("house-chimney-crack"))
    )
  ),
  
  
  dashboardBody(
    tags$style(type = "text/css", ".content {padding:0}"),
    tags$style(type = "text/css", ".box-body {padding:0}"),
    tags$style(type = "text/css", ".col-sm-9 {padding:0}"),
    tags$style(type = "text/css", "html, body, .container-fluid { height:100vh !important}"),
    # 使用 tabItems 来创建不同的页面内容
    tabItems(
      tabItem(tabName = "map",
              fluidRow(
                box(
                  width = 12,

                  # main map
                  column(
                    width = 9,
                    leafletOutput("map", height = "93vh")
                  ),

                  # options panel
                  column(
                    h3(span(icon("circle-info")), "   ", "Descriptions"),
                    h4("Data Source") %>% shinyhelper::helper(type = "markdown", colour = "#0d0d0d",
                                                      content = "desc_data_source"),
                    p("Click the CoC zones on the map to explore these data!"),
                    
                    hr(),
                    
                    h3("Glossaries"),
                    h5("CoC") %>% shinyhelper::helper(type = "markdown", colour = "#0d0d0d",
                                                     content = "desc_coc"),
                    h5("ARD") %>% shinyhelper::helper(type = "markdown", colour = "#0d0d0d",
                                                      content = "desc_ard"),
                    h5("PPRN") %>% shinyhelper::helper(type = "markdown", colour = "#0d0d0d",
                                                      content = "desc_pprn"),
                    h5("FPRN") %>% shinyhelper::helper(type = "markdown", colour = "#0d0d0d",
                                                      content = "desc_fprn"),
                    
                    hr(),
                    
                    tags$style(type = "text/css", ".col-sm-3 {height: 93vh}"),
                    width = 3,
                    id = "controls", class = "panel panel-default",
                    # tags$style(type = "text/css", "h3 {text-align: center}"),
                    h3(span(icon("gear")), "   ", "Options"),
                    checkboxInput("show_coc", "Show CoC Areas", TRUE),
                    checkboxInput("show_county", "Show County Boundaries", TRUE),
                    
                    # descriptions
                    hr()
                    
                  )
                )
              )
            ),
      # 这里可以添加更多的页面内容
      tabItem(tabName = "homeless",
        fluidRow(
          box(
            width = 12,
            title = span(icon("house-chimney-crack"), "Homelessness in Michigan"),
            leafletOutput(outputId = "homeless_map", height = "60vh"),
            
            tags$br(),
            h4("Homelessness Table"),
            
            DTOutput(outputId = "homeless_table")
            
          )
        )
      )
    )
  )
)

