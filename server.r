library(shiny)
library(shinythemes)
library(tidyverse)
library(ggiraph)
library(lubridate)
library(leaflet)
library(leaflet.esri)
library(DT)

st = read_csv('../csv/sourcetracker.csv')
points = read_csv('../csv/site_locations.csv')
love_creek = read.csv('../csv/love_creek_chem.csv')

st2 = st %>% 
  select(-SampleID, -Iteration, -Site, -STORET, -Month2) %>%
  group_by(Path, Month) %>%
  summarise_all(mean) %>%
  gather(Factor, Percent, 3:15)

love_creek = love_creek %>% 
  mutate(Date = ymd(Date), Site = as.factor(Site), 
         thres = ifelse(Entero >= 104 & Salinity >= 15, T, 
                        ifelse(Entero >= 185 & Salinity <= 2, T, F)))

server = function(input, output) {
  output$plot = renderggiraph({
    st.plot = st2 %>% 
      filter(Month == input$var) %>% 
      mutate(Hover = paste0(Factor, '<br/>', 'Percent: ', Percent * 100)) %>%
      ggplot() +
      geom_bar_interactive(aes(x = Path, y = Percent, 
                               fill = Factor, tooltip = Hover, 
                               data_id = Factor), 
                           stat = 'identity', position = position_fill(reverse = TRUE)) +
      scale_fill_manual(name="Fecal\nSource", 
                        values = c('#a6cee3', 
                                   '#1f78b4', 
                                   '#b2df8a', 
                                   '#33a02c', 
                                   '#fb9a99', 
                                   '#e31a1c', 
                                   '#fdbf6f', 
                                   '#ff7f00', 
                                   '#cab2d6', 
                                   '#6a3d9a', 
                                   '#ffff99', 
                                   '#b15928', 
                                   '#313695'), 
                        guide = guide_legend())  +
      theme(panel.grid.major = element_blank(), 
            panel.grid.minor = element_blank(), 
            axis.title.x = element_blank(), 
            axis.title.y = element_text(face = 'bold', size = 14), 
            legend.title = element_text(face = 'bold'), 
            panel.background = element_blank(), 
            panel.border = element_rect(color = 'black', fill = NA), 
            legend.position = 'bottom',
            axis.text.x = element_text(size = 12),
            axis.text.y = element_text(size = 14)) +
      labs(y = 'Percentage') + 
      scale_x_continuous(breaks = c(1,2,3,4,5,6,7), 
                         labels = c('Jimtown\nRd', 
                                    'Bundicks\nBranch', 
                                    'Goslee\nPond', 
                                    'Misty\nLane', 
                                    'Rt.\n24', 
                                    'West\nLane', 
                                    'Mouth of\nLove Creek')) + 
      scale_y_continuous(labels = scales::percent)
    
    ggiraph(code = print(st.plot))
  })
  
  output$fecal_plot = renderPlot({
    st3 = st %>% 
      gather(Factor, Percent, 3:15)
    
    st3 %>%  
      filter(STORET == input$site) %>%
      filter(Factor != 'Unknown') %>%
      filter(Factor == input$fecal) %>%
      ggplot() +
      geom_boxplot(aes(as.factor(Month2), Percent, fill = Factor)) +
      theme(panel.grid.major = element_blank(), 
            panel.grid.minor = element_blank(), 
            axis.title.x = element_blank(), 
            axis.title.y = element_text(face = 'bold', size = 14), 
            legend.title = element_text(face = 'bold'), 
            panel.background = element_blank(), 
            panel.border = element_rect(color = 'black', fill = NA),
            axis.text = element_text(size = 14)) +
      labs(y = 'Percentage') +
      scale_fill_manual(name="Fecal\nSource", 
                        values = c('#a6cee3', 
                                   '#1f78b4', 
                                   '#b2df8a', 
                                   '#33a02c', 
                                   '#fb9a99', 
                                   '#e31a1c', 
                                   '#fdbf6f', 
                                   '#ff7f00', 
                                   '#cab2d6', 
                                   '#6a3d9a', 
                                   '#ffff99', 
                                   '#b15928', 
                                   '#313695'), 
                        guide = FALSE) + 
      scale_y_continuous(labels = scales::percent) +
      scale_x_discrete(breaks = c(1:9),
                       labels = c('March',                                         
                                  'April', 
                                  'May', 
                                  'June', 
                                  'June Rain',
                                  'July',
                                  'August',
                                  'September',
                                  'October'))
  })
  
  output$entero_plot = renderPlot({
    love_creek %>% 
      filter(Site == input$site) %>%
      group_by(Month, Site) %>%
      summarise(Entero = mean(Entero)) %>%
      ggplot() + 
      geom_hline(yintercept = 104, color = 'blue', linetype = 2, size = 0.75) + 
      geom_hline(yintercept = 185, color = 'red', linetype = 4, size = 0.75) + 
      geom_bar(stat = 'identity', aes(as.factor(Month), Entero)) + 
      scale_y_continuous(limits = c(0, 1000)) +
      theme(panel.grid.major = element_blank(), 
            panel.grid.minor = element_blank(), 
            axis.title.x = element_blank(), 
            axis.title.y = element_text(face = 'bold', size = 14), 
            legend.title = element_text(face = 'bold'), 
            panel.background = element_blank(), 
            panel.border = element_rect(color = 'black', fill = NA),
            axis.text = element_text(size = 14)) +
      labs(y = expression(paste('Enterococci (mpn 100 ml'^-1,')'))) +
      scale_x_discrete(breaks = c(1:9),
                       labels = c('March',                                         
                                  'April', 
                                  'May', 
                                  'June', 
                                  'June Rain',
                                  'July',
                                  'August',
                                  'September',
                                  'October'))
  })
  
  output$love_creek = renderLeaflet({
    leaflet(data = points) %>%
      addEsriBasemapLayer(esriBasemapLayers$Imagery) %>%
      addEsriFeatureLayer(url = paste('https://maps.sussexcountyde.gov/gis/rest/services/County_Layers/WatershedsLayers/MapServer/18'), fillOpacity = 0.1) %>%
      setView(lng = -75.200828, lat = 38.695446, zoom = 13) %>%
      addMarkers(~Long, ~Lat, popup = ~Location)
  })
  
  output$raw_data = renderDataTable({
    st4 = st %>%
      select(Site, STORET, Month, Iteration, Cat:Unknown)
    datatable(st4, 
              options = list(pageLength = 10, dom = 'ftip'), 
              rownames = FALSE)
  })
  
}