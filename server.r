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
love_creek = read_csv('../csv/love_creek_chem.csv')
mds = read_csv('../csv/wunifrac.csv')

st2 = st %>% 
  select(-SampleID, -Iteration, -Site, -STORET, -Month2) %>%
  group_by(Path, Month) %>%
  summarise_all(mean) %>%
  gather(Factor, Percent, 3:15)

# According to Title 7 7401 Surface Water Quality Standards
# Marine water are considered >= 5 ppt
# pg 12 gives levels of Primary and Secondary Contact

love_creek = love_creek %>% 
  mutate(Date = ymd(Date), Site = as.factor(Site), 
         thres = ifelse(Entero >= 104 & Salinity >= 5, 1, 
                        ifelse(Entero >= 185 & Salinity < 5, 1, NA)),
         second = ifelse(Entero >= 520 & Salinity >= 5, 1,
                         ifelse(Entero >= 925 & Salinity < 5, 1, NA)))

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
    
    ggiraph(code = print(st.plot), selection_type = 'none')
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
      select(-Sample.ID, -Location) %>% 
      group_by(Site, Month) %>% 
      summarise_all(mean) %>%
      ggplot() + 
      geom_bar(stat = 'identity', aes(as.factor(Month), Entero, 
                                      fill = as.factor(thres),
                                      color = as.factor(second)),
               lwd = 0.75) + 
      theme(panel.grid.major = element_blank(), 
            panel.grid.minor = element_blank(), 
            axis.title.x = element_blank(), 
            axis.title.y = element_text(face = 'bold', size = 14), 
            legend.title = element_text(face = 'bold'), 
            panel.background = element_blank(), 
            panel.border = element_rect(color = 'black', fill = NA),
            axis.text = element_text(size = 14),
            legend.position = 'bottom') +
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
                                  'October')) +
      scale_fill_manual(name = 'Entero Level',
                        values = c('#313695'),
                        labels = c('Above Primary Contact'),
                        breaks = c(1)) +
      scale_color_manual(name = '',
                         values = c('red'),
                         labels = c('Above Secondary Contact'),
                         breaks = c(1))
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
              options = list(pageLength = 10, dom = 'Bftip', 
                             buttons = c('excel')), 
              rownames = FALSE,
              extensions = 'Buttons'
              )
  })
  
  output$raw_lovecreek = renderDataTable({
    love_creek2 = love_creek %>%
      select(-thres, -second, -Path, -Month)
    datatable(love_creek2, 
              options = list(pageLength = 10, dom = 'Bftip', 
                             buttons = c('excel')), 
              rownames = FALSE,
              extensions = 'Buttons'
    )
  })
  
  output$mds = renderggiraph({
    mds.plot = mds %>%
      mutate(Path2 = as.factor(Path2), Month3 = as.factor(Month3)) %>%
      ggplot() +
      geom_point_interactive(aes(x = MDS1, y = MDS2, color = Path2,
                                 tooltip = Location, shape = Month3), 
                             size = 2) +
      theme(panel.grid.major = element_blank(), 
            panel.grid.minor = element_blank(),
            axis.text = element_blank(),
            axis.title = element_blank(), 
            axis.ticks = element_blank(),
            legend.title = element_text(face = 'bold'), 
            panel.background = element_rect(color = 'black', fill = NA), 
            legend.key = element_blank()) +
      scale_shape_manual(values = c(15, 16, 17, 18, 25, 21, 22, 24, 23), 
                         name="Month", 
                         guide = guide_legend(),
                         labels = c('March',
                                    'April',
                                    'May',
                                    'June',
                                    'June Rain',
                                    'July',
                                    'August',
                                    'September',
                                    'October')) + 
      scale_color_manual(name = '',
                         labels = c('Non-tidal',
                                    'Tidal'),
                         values = c('#313695',
                                    '#e31a1c'))
    
    ggiraph(code = print(mds.plot))
  })
  
}