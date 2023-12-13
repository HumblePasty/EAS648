#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(leaflet)
library(sf)
library(readxl)
library(RColorBrewer)
library(dplyr)
library(stringr)
library(DT)


server <- function(input, output, session) {
  
  shinyhelper::observe_helpers(help_dir = "desc")
  
  # 读取 CoC 数据并转换坐标系
  coc_data <- st_read("Data/CoC_Michigan_2021.shp") %>%
    st_transform(crs = 4326)
  
  # 读取密歇根州县界数据并转换坐标系
  michigan_county_data <- st_read("Data/Michigan_County_Boundaries.shp") %>%
    st_transform(crs = 4326)
  
  # read the table for homelessness
  all_data_list <- list()
  
  # 循环处理每一年的数据
  for (year in 2007:2022) {
    # 读取当前年份的数据
    year_data <- read_excel("Data/2007-2022-PIT-Counts-by-CoC.xlsx", sheet = as.character(year))
    
    # standardize the column names
    colnames(year_data) <- str_replace_all(colnames(year_data), ", \\d{4}$", "")
    
    # filter for michigan
    michigan_data <- filter(year_data, grepl("^MI", `CoC Number`))
    
    # add year column
    michigan_data$Year <- year
    
    # add the result to list
    all_data_list[[year]] <- michigan_data
  }
  
  # bind all years
  michigan_homeless_df <- bind_rows(all_data_list)
  
  # 创建一个颜色映射函数
  pal <- colorFactor(palette = brewer.pal(8, "Set1"), domain = coc_data$COCNUM)
  
  # 设置地图输出
  output$map <- renderLeaflet({
    leaflet() %>%
      addProviderTiles(providers$CartoDB.Positron) %>%  # 添加默认的地图瓦片
      addPolygons(data = coc_data, fillColor = ~pal(COCNUM), weight = 2, color = "#444444", opacity = 1, fillOpacity = 0.7, group = "coc", 
                  popup = ~paste(
                    "Name: ", COCNAME, "<br>",
                    "ARD: $", ARD, "<br>",
                    "PPRN: $", PPRN, "<br>",
                    "FPRN: $", FPRN
                  )
                  ) %>%
      addPolygons(data = michigan_county_data, color = "#555555", weight = 1, fill = FALSE, dashArray = "5, 5", group = "county", popup = ~NAME)
  })
  
  # the map for homelessness
  output$homeless_map = renderLeaflet({
    leaflet() %>%
      addProviderTiles(providers$CartoDB.Positron) %>%  # 添加默认的地图瓦片
      addPolygons(data = coc_data, fillColor = ~pal(COCNUM), weight = 2, color = "#444444", opacity = 1, fillOpacity = 0.7, group = "coc", 
                  popup = ~paste(
                    "Name: ", COCNAME, "<br>",
                    "ARD: $", ARD, "<br>",
                    "PPRN: $", PPRN, "<br>",
                    "FPRN: $", FPRN
                  )
      )
  })
  
  TABLE_COLUMN_NAMES = c(
    "CoC Number" = "CoC Number",
    "CoC Name" = "CoC Name",
    "Overall Homeless" = "Overall Homeless",
    "Year" = "Year"
  )
  
  # The table for homelessness
  output$homeless_table = renderDT({
    homeless_df_table = michigan_homeless_df[,TABLE_COLUMN_NAMES]
    
    action = DT::dataTableAjax(session, homeless_df_table, rownames = F)
    
    datatable(
      homeless_df_table,
      colnames = {TABLE_COLUMN_NAMES},
      rownames = F,
      options = list(
        ajax = list(url = action)
      ),
      escape = F
    ) %>%
    formatStyle(
      columns = names(TABLE_COLUMN_NAMES)[TABLE_COLUMN_NAMES == "Overall Homeless"],
      # start the bar from left
      background = styleColorBar(c(0, max(homeless_df_table[,"Overall Homeless"])), 'steelblue', angle = -90),
      # fix vertical length to avoid differences in the height of the bar when row height varies
      backgroundSize = '100% 2rem',
      backgroundRepeat = 'no-repeat',
      backgroundPosition = 'right'
    )
  })
  
  observe({
    if (input$show_county) {
      leafletProxy("map") %>%
        addPolygons(data = michigan_county_data, weight = 1, color = "#555555", dashArray = "5, 5", fill = FALSE, group = "county", popup = ~NAME)
    } else {
      leafletProxy("map") %>%
        clearGroup("county")
    }
  })
  
  observe({
    if (input$show_coc) {
      leafletProxy("map") %>%
        addPolygons(data = coc_data, fillColor = ~pal(COCNUM), weight = 2, color = "#444444", opacity = 1, fillOpacity = 0.7, group = "coc", 
                    popup = ~paste(
                      "Name: ", COCNAME, "<br>",
                      "ARD: $", ARD, "<br>",
                      "PPRN: $", PPRN, "<br>",
                      "FPRN: $", FPRN
                    )
                    )
    } else {
      leafletProxy("map") %>%
        clearGroup("coc")
    }
  })
}



