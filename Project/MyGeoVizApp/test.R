coc_data <- st_read("Data/CoC_Michigan_2021.shp")
# 
# # 读取密歇根州县界数据
# michigan_county_data <- st_read("Data/Michigan_County_Boundaries.shp")
# pal <- colorFactor(palette = brewer.pal(8, "Set1"), domain = coc_data$COCNUM)
# 
# leaflet() %>%
#   addTiles() %>%  # 添加默认的地图瓦片
#   # addPolygons(data = coc_data, fillColor = ~pal(COCNUM), weight = 2, color = "#444444", opacity = 1, fillOpacity = 0.7) %>%
#   addPolygons(data = michigan_county_data, color = "#555555", weight = 1, fill = FALSE)

library(dplyr)
library(readxl)
library(stringr)

# 初始化一个空的数据框，用于存储所有年份的数据
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
# michigan_homeless_df = michigan_homeless_df[michigan_homeless_df$Year == 2021,]

michigan_homeless_df_new = coc_data %>%
  st_centroid() %>%
  st_transform(crs = st_crs(4326)) %>%
  mutate(lng = sf::st_coordinates(.)[,1], lat = sf::st_coordinates(.)[,2]) %>%
  
  mutate(zoom_in_map_link = 
           paste(
             '<a class="go-map" href=""',
             'data-lat="', lat, '" data-lng="', lng,
             '"><i class="fas fa-search-plus"></i></a>',
             sep=""
           )
         ) %>%
  st_drop_geometry() %>%
  dplyr::select(c(`COCNUM`,`zoom_in_map_link`))
  # dplyr::relocate(`CoC Number`,zoom_in_map_link)

colnames(michigan_homeless_df_new)[1] = "CoC Number"

michigan_homeless_df <- left_join(michigan_homeless_df, michigan_homeless_df_new, by = "CoC Number")
