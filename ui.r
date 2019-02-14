library(shiny)
library(shinythemes)
library(tidyverse)
library(ggiraph)
library(lubridate)
library(leaflet)
library(leaflet.esri)
library(DT)

ui = fluidPage(
  theme = shinytheme('paper'),
  title = 'DNREC MST Pilot Study',
  tabsetPanel(type = 'tabs',
              tabPanel('Introduction', includeHTML('about.html')),
              tabPanel('Watershed Map', 
                       leafletOutput('love_creek', 
                                     height = '800px'
                                    )
                      ),
              tabPanel('Monthly Plots',
                       sidebarLayout(
                         sidebarPanel(width = 2,
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
                                                                   'October')
                                                    )
                           ),
                       mainPanel(
                         ggiraphOutput('plot')
                                 )
                       )
                       ),
              tabPanel('Fecal Source',
                sidebarLayout(
                  sidebarPanel(width = 2,
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
                                               'Sheep')),
                    selectInput('site',
                                label = 'Choose Site',
                                choices = list(
                                  'Jimtown Road' = '308411',
                                  'Bundicks Branch' = '308371',
                                  'Goslee Pond' = '308291',
                                  'Misty Lane' = '308024',
                                  'Rt 24 Marina' = '308021',
                                  'West Lane' = '308018',
                                  'Mouth' = '308015'))
                  ),
                  mainPanel(
                    plotOutput('fecal_plot'),
                    plotOutput('entero_plot')
                  )
                )
              ),
              tabPanel('Multi-Dimensional Scaling Plot',
                       ggiraphOutput('mds'))
              tabPanel('Sourcetracker Raw Data',
                       dataTableOutput('raw_data')
                       ),
              tabPanel('Environmental Raw Data',
                       dataTableOutput('raw_lovecreek')
              )
  ))