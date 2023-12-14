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
library(tidyr)


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

  # create new column, to zoom in to coc
  michigan_homeless_df_new = coc_data %>%
    st_centroid() %>%
    st_transform(crs = st_crs(4326)) %>%
    mutate(lng = sf::st_coordinates(.)[,1], lat = sf::st_coordinates(.)[,2]) %>%
    
    mutate(zoom_in_map_link = 
             paste(
               '<a class="go-map" href=""',
               'data-lat="', lat, '" data-lng="', lng, '"data-coc="', COCNUM,
               '"><i class="fas fa-search-plus"></i></a>',
               sep=""
             )
    ) %>%
    st_drop_geometry() %>%
    dplyr::select(c(`COCNUM`,`zoom_in_map_link`))
  # dplyr::relocate(`CoC Number`,zoom_in_map_link)
  
  colnames(michigan_homeless_df_new)[1] = "CoC Number"
  
  michigan_homeless_df <- left_join(michigan_homeless_df, michigan_homeless_df_new, by = "CoC Number")
    
  
  # 创建一个颜色映射函数
  pal <- colorFactor(palette = brewer.pal(8, "Set1"), domain = coc_data$COCNUM)
  
  # the map for homelessness
  output$homeless_map = renderLeaflet({
    leaflet() %>%
      addProviderTiles(providers$CartoDB.Positron) %>%  # 添加默认的地图瓦片
      addPolygons(data = coc_data, fillColor = ~pal(COCNUM), weight = 2, color = "#444444", opacity = 1, fillOpacity = 0.7, group = "coc", 
                  popup = ~paste0(
                    '<table style="width:100%; border-collapse: collapse;" align="center">',
                    '<tr><td style="text-align:center; padding: 4px; border: 1px solid #ddd;"><b>Name</b></td>',
                    '<td style="text-align:center; padding: 4px; border: 1px solid #ddd;">', COCNAME, '</td></tr>',
                    '<tr><td style="text-align:center; padding: 4px; border: 1px solid #ddd;"><b>ARD</b></td>',
                    '<td style="text-align:center; padding: 4px; border: 1px solid #ddd;">$', scales::comma(ARD), '</td></tr>',
                    '<tr><td style="text-align:center; padding: 4px; border: 1px solid #ddd;"><b>PPRN</b></td>',
                    '<td style="text-align:center; padding: 4px; border: 1px solid #ddd;">$', scales::comma(PPRN), '</td></tr>',
                    '<tr><td style="text-align:center; padding: 4px; border: 1px solid #ddd;"><b>FPRN</b></td>',
                    '<td style="text-align:center; padding: 4px; border: 1px solid #ddd;">$', scales::comma(FPRN), '</td></tr>',
                    '</table>'
                  )
                  ) %>%
      addPolygons(data = michigan_county_data, color = "#555555", weight = 1, fill = FALSE, dashArray = "5, 5", group = "county", popup = ~NAME)
  })
  
  observe({
    if (is.null(input$goto)) return()
    
    isolate({
      # map = leafletProxy("homeless_map")
      
      lat = input$goto$lat
      lng = input$goto$lng
      coc = input$goto$coc
      
      # setView(map, lng, lat, zoom = 10)
      selected_coc_bounds <- st_bbox(coc_data[coc_data$COCNUM == coc, ])
      leafletProxy("homeless_map", session) %>% 
        # setView(lng, lat, zoom = 10)
        # fitBounds(
        #   lng1 = selected_coc_bounds$xmin,
        #   lat1 = selected_coc_bounds$ymin,
        #   lng2 = selected_coc_bounds$xmax,
        #   lat2 = selected_coc_bounds$ymax
        # )
        clearMarkers() %>%
        flyToBounds(
            as.numeric(selected_coc_bounds$xmin),
            as.numeric(selected_coc_bounds$ymin),
            as.numeric(selected_coc_bounds$xmax),
            as.numeric(selected_coc_bounds$ymax)
        ) %>%
        addMarkers(lng = lng, lat = lat, popup = coc)
    })
  })
  
  TABLE_COLUMN_NAMES = c(
    "CoC Number" = "CoC Number",
    "Zoom to CoC" = "zoom_in_map_link",
    "CoC Name" = "CoC Name",
    "Overall Homeless" = "Overall Homeless",
    "Homeless Individuals" = "Overall Homeless Individuals",
    "Homeless Families" = "Overall Homeless Family Households",
    "Chronically Homeless" = "Overall Chronically Homeless Individuals",
    "Year" = "Year"
  )
  
  # The table for homelessness
  output$homeless_table = renderDT({
    selected_year = input$yearInput
    homeless_df_table = michigan_homeless_df[,TABLE_COLUMN_NAMES] %>%
      filter(Year == selected_year)
    
    action = DT::dataTableAjax(session, homeless_df_table, rownames = F)
    
    datatable(
      homeless_df_table,
      colnames = {TABLE_COLUMN_NAMES},
      rownames = F,
      options = list(
        columnDefs = list(list(className = 'dt-center', targets = '_all')),
        ajax = list(url = action)
      ),
      escape = F
    ) %>%
    formatStyle(
      columns = names(TABLE_COLUMN_NAMES)[TABLE_COLUMN_NAMES == "Overall Homeless"],
      # start the bar from left
      background = styleColorBar(c(0, 1.1*max(homeless_df_table[,"Overall Homeless"])), 'steelblue', angle = -90),
      # fix vertical length to avoid differences in the height of the bar when row height varies
      backgroundSize = '100% 2rem',
      backgroundRepeat = 'no-repeat',
      backgroundPosition = 'right'
    ) %>%
    formatStyle(
      columns = names(TABLE_COLUMN_NAMES)[TABLE_COLUMN_NAMES == "Overall Homeless Individuals"],
      # start the bar from left
      background = styleColorBar(c(0, 1.1*max(homeless_df_table[,"Overall Homeless Individuals"]) + 50), 'salmon', angle = -90),
      # fix vertical length to avoid differences in the height of the bar when row height varies
      backgroundSize = '100% 2rem',
      backgroundRepeat = 'no-repeat',
      backgroundPosition = 'right'
    ) %>%
    formatStyle(
      columns = names(TABLE_COLUMN_NAMES)[TABLE_COLUMN_NAMES == "Overall Homeless Family Households"],
      # start the bar from left
      background = styleColorBar(c(0, 1.1*max(homeless_df_table[,"Overall Homeless Family Households"]) + 50), 'turquoise', angle = -90),
      # fix vertical length to avoid differences in the height of the bar when row height varies
      backgroundSize = '100% 2rem',
      backgroundRepeat = 'no-repeat',
      backgroundPosition = 'right'
    ) %>%
    formatStyle(
      columns = names(TABLE_COLUMN_NAMES)[TABLE_COLUMN_NAMES == "Overall Chronically Homeless Individuals"],
      # start the bar from left
      background = styleColorBar(c(0, 1.1*max(homeless_df_table[,"Overall Chronically Homeless Individuals"]) + 50), 'olivedrab', angle = -90),
      # fix vertical length to avoid differences in the height of the bar when row height varies
      backgroundSize = '100% 2rem',
      backgroundRepeat = 'no-repeat',
      backgroundPosition = 'right'
    )
  })
  
  # Output function for dashboard
  output$dashboard_coc_filter_ui = renderUI({
    selectInput(
      inputId = "dashboard_coc_filter",
      label = "Choose a Specific COC",
      choices = setNames(
        c("all", coc_data$COCNUM),
        c("All", coc_data$COCNAME)
      ),
      selected = "all"
    )
  })
  
  # select the coc data by the filter
  dashboard_coc_filtered = reactive({
    dsb_coc_filtered = michigan_homeless_df
    # filter by selected coc
    coc_chosen = if (is.null(input$dashboard_coc_filter)) "all" else input$dashboard_coc_filter
    if (input$dashboard_coc_filter != "all") {
      dsb_coc_filtered = filter(michigan_homeless_df, `CoC Number` == coc_chosen)
    }
    
    # filter by selected year
    dsb_coc_filtered = filter(dsb_coc_filtered, Year >= input$dashboard_year_filter[1] & Year <= input$dashboard_year_filter[2])

    # print(nrow(dsb_coc_filtered))
    
    dsb_coc_filtered
  })
  
  # the outputs
  
  output$infobox_total_num = renderInfoBox({
    n_homeless = sum(dashboard_coc_filtered()$`Overall Homeless`)
    
    infoBox(
      title = "",
      value = format(n_homeless, big.mark = ","),
      subtitle = "Homelessness Count",
      icon = icon("house-circle-xmark"),
      color = "black"
    )
  })
  
  output$infobox_total_family = renderInfoBox({
    n_homeless_fam = sum(dashboard_coc_filtered()$`Overall Homeless People in Families`)
    
    infoBox(
      title = "",
      value = format(n_homeless_fam, big.mark = ","),
      subtitle = "Homelessness in families",
      icon = icon("people-roof"),
      color = "orange"
    )
  })
  
  output$infobox_age = renderInfoBox({
    ave_age = sum(dashboard_coc_filtered()$`Overall Homeless - Under 18` * 18 +
    dashboard_coc_filtered()$`Overall Homeless - Age 18 to 24` * 21 +
    dashboard_coc_filtered()$`Overall Homeless - Over 24` * 40) /
      sum(dashboard_coc_filtered()$`Overall Homeless - Under 18` +
            dashboard_coc_filtered()$`Overall Homeless - Age 18 to 24` +
            dashboard_coc_filtered()$`Overall Homeless - Over 24`)
    
    infoBox(
      title = "",
      value = format(ave_age, big.mark = ","),
      subtitle = "Estimated Mean Age",
      icon = icon("person-cane"),
      color = "red"
    )
  })
  
  output$infobox_shelter_percent = renderInfoBox({
    shelter_rate = 1 - sum(dashboard_coc_filtered()$`Unsheltered Homeless`) / sum(dashboard_coc_filtered()$`Overall Homeless`)
    
    infoBox(
      title = "",
      value = format(shelter_rate, big.mark = ","),
      subtitle = "The shelter rate",
      icon = icon("person-shelter"),
      color = "orange"
    )
  })
  
  output$dashboard_map = renderLeaflet({
    filtered_coc = unique(dashboard_coc_filtered()$`CoC Number`)
    coc_data_filtered = coc_data[coc_data$COCNUM == filtered_coc,]
    leaflet() %>%
      addProviderTiles(providers$CartoDB.Positron) %>%  # 添加默认的地图瓦片
      addPolygons(data = coc_data_filtered, fillColor = ~pal(COCNUM), weight = 2, color = "#444444", opacity = 1, fillOpacity = 0.7, group = "coc", 
                  popup = ~paste0(
                    '<table style="width:100%; border-collapse: collapse;" align="center">',
                    '<tr><td style="text-align:center; padding: 4px; border: 1px solid #ddd;"><b>Name</b></td>',
                    '<td style="text-align:center; padding: 4px; border: 1px solid #ddd;">', COCNAME, '</td></tr>',
                    '<tr><td style="text-align:center; padding: 4px; border: 1px solid #ddd;"><b>ARD</b></td>',
                    '<td style="text-align:center; padding: 4px; border: 1px solid #ddd;">$', scales::comma(ARD), '</td></tr>',
                    '<tr><td style="text-align:center; padding: 4px; border: 1px solid #ddd;"><b>PPRN</b></td>',
                    '<td style="text-align:center; padding: 4px; border: 1px solid #ddd;">$', scales::comma(PPRN), '</td></tr>',
                    '<tr><td style="text-align:center; padding: 4px; border: 1px solid #ddd;"><b>FPRN</b></td>',
                    '<td style="text-align:center; padding: 4px; border: 1px solid #ddd;">$', scales::comma(FPRN), '</td></tr>',
                    '</table>'
                  )
      ) %>%
      addPolygons(data = michigan_county_data, color = "#555555", weight = 1, fill = FALSE, dashArray = "5, 5", group = "county", popup = ~NAME)
  })
  
  output$age_distribution_plot = renderPlotly({
    plot_data <- data.frame(
      `Age.Group` = c("Under 18", "18 to 24", "Over 24"),
      `Age.Count` = c(
        sum(dashboard_coc_filtered()$`Overall Homeless - Under 18`),
        sum(dashboard_coc_filtered()$`Overall Homeless - Age 18 to 24`),
        sum(dashboard_coc_filtered()$`Overall Homeless - Over 24`)
      )
    )
    
    plot_by_age = ggplot(
      plot_data, aes(x = `Age.Group`, y = `Age.Count`, fill = `Age.Group`)) +
        geom_bar(stat = "identity") +
        coord_flip() +
        # scale_fill_manual(values = ) +
        theme_minimal() +
        theme(
          axis.title.y = element_blank(),
          panel.grid.major.y = element_blank(),
          panel.grid.minor.y = element_blank(),
          legend.position = "none"
        )
    
    ggplotly(plot_by_age, tooltip = c("x", "y"))
  })
  
  output$shelter_status_plot = renderPlotly({
    plot_data <- data.frame(
      `Shelter.Type` = c("Sheltered ES", "Sheltered TH", "Unsheltered"),
      `Shelter.Count` = c(
        sum(dashboard_coc_filtered()$`Sheltered ES Homeless`),
        sum(dashboard_coc_filtered()$`Sheltered TH Homeless`),
        sum(dashboard_coc_filtered()$`Unsheltered Homeless`)
      )
    )
    
    plot_by_shelter = ggplot(
      plot_data, aes(x = `Shelter.Type`, y = `Shelter.Count`, fill = `Shelter.Type`)) +
      geom_col(width = 1) +
      # coord_polar("y", start = 0) +
      theme_void()
      # theme(
      #   axis.title.y = element_blank(),
      #   panel.grid.major.y = element_blank(),
      #   panel.grid.minor.y = element_blank(),
      #   legend.position = "none"
      # )
    
    ggplotly(plot_by_shelter, tooltip = c("x", "y"))
  })
  
  output$year_trend_plot = renderPlotly({
    plot_data <- data.frame()
    
    filtered_coc_data = dashboard_coc_filtered()
    
    for (year in unique(filtered_coc_data$Year)) {
      this_year = filtered_coc_data[filtered_coc_data$Year == year,]
      
      overall_homeless <- sum(this_year$`Overall Homeless`)
      unsheltered_homeless <- sum(this_year$`Unsheltered Homeless`)
      sheltered_homeless <- overall_homeless - unsheltered_homeless
      shelter_rates <- sheltered_homeless / overall_homeless
      
      mean_age <- sum(
        this_year$`Overall Homeless - Under 18` * 18 +
          this_year$`Overall Homeless - Age 18 to 24` * 21 +
          this_year$`Overall Homeless - Over 24` * 40
      ) / overall_homeless
      
      # 将计算结果添加到数据框中
      plot_data <- rbind(plot_data, data.frame(Years = year, 
                                               Overall.Homeless = overall_homeless,
                                               Shelter.Rates = shelter_rates,
                                               Mean.Age = mean_age))
    }
    
    if (nrow(plot_data) == 1) {return()}
    
    plot_data_long <- gather(plot_data, key = "Variable", value = "Value", -Years)
    
    plot_by_year = ggplot(
      plot_data_long, aes(x = `Years`, y = `Value`, color = `Variable`, group = Variable)) +
      geom_line() +
      geom_point() +
      # coord_polar("y", start = 0) +
      theme_minimal() +
      scale_color_manual(values = c("blue", "red", "green")) +
      labs(x = "Year", y = "Value", color = "Metrics") +
      theme(legend.position = "bottom")
    
    ggplotly(plot_by_year, tooltip = c("x", "y"))
  })
  
  # Event listeners
  observe({
    if (input$show_county) {
      leafletProxy("homeless_map") %>%
        addPolygons(data = michigan_county_data, weight = 1, color = "#555555", dashArray = "5, 5", fill = FALSE, group = "county", popup = ~NAME)
    } else {
      leafletProxy("homeless_map") %>%
        clearGroup("county")
    }
  })
  
  observe({
    if (input$show_coc) {
      leafletProxy("homeless_map") %>%
        addPolygons(data = coc_data, fillColor = ~pal(COCNUM), weight = 2, color = "#444444", opacity = 1, fillOpacity = 0.7, group = "coc", 
                    popup = ~paste0(
                      '<table style="width:100%; border-collapse: collapse;" align="center">',
                      '<tr><td style="text-align:center; padding: 4px; border: 1px solid #ddd;"><b>Name</b></td>',
                      '<td style="text-align:center; padding: 4px; border: 1px solid #ddd;">', COCNAME, '</td></tr>',
                      '<tr><td style="text-align:center; padding: 4px; border: 1px solid #ddd;"><b>ARD</b></td>',
                      '<td style="text-align:center; padding: 4px; border: 1px solid #ddd;">$', scales::comma(ARD), '</td></tr>',
                      '<tr><td style="text-align:center; padding: 4px; border: 1px solid #ddd;"><b>PPRN</b></td>',
                      '<td style="text-align:center; padding: 4px; border: 1px solid #ddd;">$', scales::comma(PPRN), '</td></tr>',
                      '<tr><td style="text-align:center; padding: 4px; border: 1px solid #ddd;"><b>FPRN</b></td>',
                      '<td style="text-align:center; padding: 4px; border: 1px solid #ddd;">$', scales::comma(FPRN), '</td></tr>',
                      '</table>'
                    ),
                    )
    } else {
      leafletProxy("homeless_map") %>%
        clearGroup("coc")
    }
  })
  
  observeEvent(input$clear_markers, {
    # 使用 leafletProxy 清除地图上的标记
    leafletProxy("homeless_map", session) %>%
      clearMarkers()
  })
  
  observeEvent(input$reset_view, {
    MI_500_bounds <- st_bbox(coc_data[coc_data$COCNUM == "MI-500", ])
    # 使用 leafletProxy 重置地图视图到初始状态
    leafletProxy("homeless_map", session) %>%
      flyToBounds(
        as.numeric(MI_500_bounds$xmin),
        as.numeric(MI_500_bounds$ymin),
        as.numeric(MI_500_bounds$xmax),
        as.numeric(MI_500_bounds$ymax)
      )
  })
}



