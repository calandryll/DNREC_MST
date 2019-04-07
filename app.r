library(shiny)
library(shinythemes)
library(tidyverse)
library(RSQLite)
library(DBI)
library(DT)

ui = fluidPage(
    theme = shinytheme('paper'),
    title = 'Trinotate Search',
    fluidRow(
      column(3, selectInput('sample_1',
                            label = 'Choose Sample',
                            choices = list(
                              'T0_10' = 'S2',
                              'T11_10' = 'S4',
                              'T0_50' = 'S3',
                              'T11_50' = 'S5',
                              'T0_100' = 'S1',
                              'T11_100' = 'S6'))),
      column(3,
               selectInput('sample_2',
                           label = 'Choose Sample',
                           choices = list(
                             'T0_10' = 'S2',
                             'T11_10' = 'S4',
                             'T0_50' = 'S3',
                             'T11_50' = 'S5',
                             'T0_100' = 'S1',
                             'T11_100' = 'S6'))),
      column(3,
             checkboxInput('checkbox', 'Downregulated?')),
      column(3,
             actionButton('do', 'Display Data'),
             downloadButton('downloadData', 'Download')),
      dataTableOutput('expression')
    )
  )


server = function(input, output) {
  observeEvent(input$do, {
    # Connect to SQLite
    con = dbConnect(SQLite(), 'Trinotate.sqlite')
    
    if(input$checkbox == TRUE){
      # Pull out upregulated transcripts
      diff_expression = dbReadTable(con, 'Diff_expression') %>%
        filter(sample_id_A == input$sample_1 & sample_id_B == input$sample_2) %>%
        filter(log_fold_change <= 0) %>%
        filter(p_value <= 1e-3) %>%
        select(-sample_id_A, -sample_id_B)
    } else {
      # Pull out upregulated transcripts
      diff_expression = dbReadTable(con, 'Diff_expression') %>%
        filter(sample_id_A == input$sample_1 & sample_id_B == input$sample_2) %>%
        filter(log_fold_change >= 0) %>%
        filter(p_value <= 1e-3) %>%
        select(-sample_id_A, -sample_id_B)
    }
    # Get annotations
    de_annot = dbReadTable(con, 'Transcript') %>% 
      filter(gene_id %in% diff_expression$feature_name | 
               transcript_id %in% diff_expression$feature_name) %>%
      gather(gene_id, transcript_id, key = 'feature_type', value = 'feature_name')# %>%
    #select(feature_name, annotation, sequence)
    
    dbDisconnect(con)
    de_final = inner_join(diff_expression, de_annot, by = 'feature_name') %>%
      select(feature_name, feature_type = feature_type.x, 
             log_fold_change, p_value, annotation, sequence)
  output$expression = renderDataTable({
    datatable(de_final, 
              options = list(pageLength = 10, dom = 'Bftip'), 
              rownames = FALSE
              )
  })
  output$downloadData = downloadHandler(
    filename = function(){paste('Trinotate', '.csv', sep = '')},
    content = function(file){
      write.csv(de_final, file, row.names = FALSE)
    }
  )
  
  }
  )
}

shinyApp(ui, server)
