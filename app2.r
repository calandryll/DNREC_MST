library(shiny)
library(shinythemes)
library(tidyverse)
library(ggiraph)
library(lubridate)

st = read_csv('../csv/sourcetracker.csv')
st2 = st %>% 
  group_by(Path, Month) %>%
  summarise_all(mean) %>%
  gather(Factor, Percent, 5:17)
love_creek = read.csv('../csv/love_creek_chem.csv')
love_creek = love_creek %>% 
  mutate(Date = ymd(Date), Site = as.factor(Site), 
         thres = ifelse(Entero >= 104 & Salinity >= 15, T, 
                        ifelse(Entero >= 185 & Salinity <= 2, T, F)))

ui = fluidPage(
  theme = shinytheme('paper'),
  title = 'DNREC MST Pilot Study',
  tabsetPanel(type = 'tabs',
              tabPanel('Month Plots', ggiraphOutput('plot'), 
                       fluidRow(
                         column(3,
                                selectInput('var',
                                            label = 'Choose Month to display',
                                            choices = list('March',                                         
                                                           'April', 
                                                           'May', 
                                                           'June', 
                                                           'June Rain',
                                                           'July',
                                                           'August',
                                                           'September',
                                                           'October'),
                                            selected = 'March'
                             )))),
              tabPanel('Fecal Source', plotOutput('fecal_plot'),
                       fluidRow(
                         column(3,
                                selectInput('fecal',
                                          label = 'Choose Fecal Source',
                                          choices = list('Cat',
                                                         'Chicken',
                                                         'Cow',
                                                         'Dog',
                                                         'Duck',
                                                         'Effluent',
                                                         'Goat',
                                                         'Goose',
                                                         'Horse',
                                                         'Human',
                                                         'Pig',
                                                         'Sheep')
                              )),
                           column(3,
                              selectInput('site',
                                          label = 'Choose Site',
                                          choices = list('Jimtown Road',
                                                         'Bundicks Branch',
                                                         'Goslee Pond',
                                                         'Misty Lane',
                                                         'Rt 24 Marina',
                                                         'West Lane',
                                                         'Mouth')
                              )))),
              tabPanel('Entero Levels', plotOutput('entero_plot'))
              )

)

server = function(input, output) {
  output$plot = renderggiraph({
    st.plot = st2 %>% 
      filter(Month == input$var) %>% 
      ggplot() +
      geom_bar_interactive(aes(x = Path, y = Percent, fill = Factor, tooltip = Percent, data_id = Factor), stat = 'identity', position = position_fill(reverse = TRUE)) +
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
            axis.title.y = element_text(face = 'bold'), 
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
    
    #colnames(st3) = c('SampleID', 'Iteration', 'STORET', 'Site', 'Month', 'Path', 'Factor', 'Percent')
    
    st3 %>%  
      filter(Month != 'June Rain') %>%
      mutate(Month = parse_date_time2(Month, 'B'), 
             Month = month(Month, label = TRUE)) %>%
      filter(Site == input$site) %>%
      filter(Factor != 'Unknown') %>%
      filter(Factor == input$fecal) %>%
      ggplot(aes(Month, Percent)) +
      geom_boxplot(aes(fill = Factor)) +
      theme(panel.grid.major = element_blank(), 
            panel.grid.minor = element_blank(), 
            axis.title.x = element_blank(), 
            axis.title.y = element_text(face = 'bold'), 
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
      scale_y_continuous(labels = scales::percent)
    
  })
  
  output$entero_plot = renderPlot({
    love_creek %>% 
      ggplot(aes(as.factor(Path), Entero)) + 
      geom_hline(yintercept = 104, color = 'blue', linetype = 2, size = 0.75) + 
      geom_hline(yintercept = 185, color = 'red', linetype = 4, size = 0.75) + 
      stat_boxplot(geom = 'errorbar') + 
      geom_boxplot() + 
      scale_y_continuous(limits = c(0, 1000)) +
      theme(panel.grid.major = element_blank(), 
            panel.grid.minor = element_blank(), 
            axis.title.x = element_blank(), 
            axis.title.y = element_text(face = 'bold'), 
            legend.title = element_text(face = 'bold'), 
            panel.background = element_blank(), 
            panel.border = element_rect(color = 'black', fill = NA)) +
      labs(y = expression(paste('Enterococci (mpn 100 ml'^-1,')'))) + 
      scale_x_discrete(breaks = c(1,2,3,4,5,6,7), 
                       labels = c('Jimtown\nRd', 
                                  'Bundicks\nBranch', 
                                  'Goslee\nPond', 
                                  'Misty\nLane', 
                                  'Rt.\n24', 
                                  'West\nLane', 
                                  'Mouth of\nLove Creek'))
  })
  
}

shinyApp(ui, server)