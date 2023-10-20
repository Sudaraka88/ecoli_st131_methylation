library(shiny)
library(shinyWidgets)
library(shinyalert)
library(JBrowseR)
library(bslib)
library(tibble)
library(DT)
library(dplyr)

## get the methylation data from local source if it exists, else load from s3
if(file.exists("methy_data.rds")) {
  methy_data = readRDS("methy_data.rds")
} else {
  methy_data = readRDS(url("https://ecoli-st131.s3.ap-southeast-2.amazonaws.com/methy_data.rds"))
  saveRDS(methy_data, "methy_data.rds")
}

# break it apart
cpg = methy_data$cpg
dam = methy_data$dam
dcm = methy_data$dcm
rm(methy_data)

# cpg = list()
# for(i in dir('data', 'cpg', full.names = T)){
#   tmp = readRDS(i)
#   nm = unlist(strsplit(unlist(strsplit(i, "/"))[2], "_"))[1]
#   cpg[[nm]] = tmp
# }
# dam = list()
# for(i in dir('data', 'dam', full.names = T)){
#   tmp = readRDS(i)
#   nm = unlist(strsplit(unlist(strsplit(i, "/"))[2], "_"))[1]
#   dam[[nm]] = tmp
# }
# dcm = list()
# for(i in dir('data', 'dcm', full.names = T)){
#   tmp = readRDS(i)
#   nm = unlist(strsplit(unlist(strsplit(i, "/"))[2], "_"))[1]
#   dcm[[nm]] = tmp
# }



patch_multi_line_json = function(json){
  if(length(json) == 1) return(json)

  l = length(json)
  if(l > 1){
    for(i in 1:l){
      if(i > 1 & i < l) {
        json[i] = gsub(pattern = "]$", replacement = ",", x = json[i])
        json[i] = gsub(pattern = "^\\[", replacement = "" , x = json[i])
      } else if (i == 1){
        json[i] = gsub(pattern = "]$", replacement = ",", x = json[i])
      } else if (i == l){
        json[i] = gsub(pattern = "^\\[", replacement = "" , x = json[i])
      }
    }
    return(paste(json, collapse = " "))
  }
}

# Define UI for application that draws a histogram
ui <- fluidPage(
  theme = bs_theme(version = 5),
  shinyUI(
    navbarPage("Ecoli ST131 Methylation Browser", id = "ecm",
               tabPanel("Options", value = "Options",
                        h4("Viewing Options"),
                        span("Select the required methylation type and barcodes and click Update Tracks"),
                        br(),
                        br(),
                        checkboxGroupInput(
                          "meth_choice",
                          label = "Methylation Type",
                          choiceNames =  list("dam", "dcm", "cpg"), 
                          choiceValues = list("dam", "dcm", "cpg"), 
                          selected = "dam", inline = T),
                        checkboxGroupInput(
                          "bc_choice",
                          label = "Barcodes",
                          choiceNames = as.character(1:24),  
                          choiceValues = paste("bc", 1:24, "_", sep = ''),
                          selected =  paste("bc", 1:3, "_", sep = ''), inline = T),
                        span("Quick select:"),
                        actionGroupButtons(
                          inputIds = c("btn_all", "btn_reset", "btn_odds", "btn_evens", "btn_1to6", "btn_1to12", "btn_12to18", 
                                       "btn_12to24", "btn_r12"), 
                          size = "s",
                          labels = list("All", "Reset", "Odds", "Evens", "First 6", "First 12", "12 to 18", "Last 12", "Random 12"), 
                          status = "info"
                        ),
                        radioButtons("srt", "Sort tracks by:",
                                     c("Methylation Type" = "meth",
                                       "Barcode" = "bcd"), inline = T),
                        actionButton(
                          "update",
                          label = "Update Tracks",
                          icon = icon("fa-solid fa-dna"),
                          style="color: #fff; background-color: #337ab7; border-color: #2e6da4"
                        ),
                        
                        br(),
                        br(),
                        br(),
                       
                        h5("Navigate using Bookmarked Features"),
                        span("Click any genomic feature in the Browser window (gold segments) and they will be added to this table.
                             You can search, navigate or delete chosen features in the table."),
                        br(),
                        dataTableOutput("bookmarks"),
                        actionButton(
                          "clear",
                          label = "Clear selection",
                          icon = icon("eraser")
                        ),
                        actionButton(
                          "delete",
                          label = "Delete selection",
                          icon = icon("trash")
                        ),
                        actionButton(
                          "navigate",
                          label = "Navigate",
                          icon = icon("arrow-right")
                        )
               ),
               tabPanel("Browser", value = "Browser",
                        # this adds to the browser to the UI, and specifies the output ID in the server
                        JBrowseR::JBrowseROutput("browserOutput")))
  )
)

# Define server logic required to draw a histogram
server <- function(input, output, session) {
  # s = JBrowseR::serve_data('data')
  
  proxy = dataTableProxy('bookmarks')
  ## DEBUG ##
  
  ## DEBUG ##
  
  # create the necessary JB2 assembly configuration
  # assembly <- JBrowseR::assembly("http://127.0.0.1:5000/ecoli_st131.fa.gz", bgzip = TRUE)
  assembly <- JBrowseR::assembly("https://ecoli-st131.s3.ap-southeast-2.amazonaws.com/ecoli_st131.fa.gz",
                                 bgzip = T)
  
  # 
  # # create configuration for a JB2 GFF FeatureTrack
  annotations_track <- JBrowseR::track_feature("https://ecoli-st131.s3.ap-southeast-2.amazonaws.com/ecoli_st131.gff3.gz",
                                               assembly)
  
  # create the tracks array to pass to browser
  
  for(i in 1:length(cpg)){
    assign(paste(names(cpg)[i], "_cpg", sep = ""), JBrowseR::track_data_frame(cpg[[i]], paste(names(cpg)[i],"_cpg",sep = ""), assembly))
  }
  for(i in 1:length(dam)){
    assign(paste(names(dam)[i], "_dam", sep = ""), JBrowseR::track_data_frame(cpg[[i]], paste(names(cpg)[i],"_dam",sep = ""), assembly))
  }
  for(i in 1:length(dcm)){
    assign(paste(names(dcm)[i], "_dcm", sep = ""), JBrowseR::track_data_frame(dcm[[i]],  paste(names(dcm)[i],"_dcm",sep = ""), assembly))
  }
  
  # shown_tracks <- reactiveValues(val = c(annotations_track))
  all_tracks = c(paste("bc", 1:24, "_dam", sep = ""),
                 paste("bc", 1:24, "_dcm", sep = ""),
                 paste("bc", 1:24, "_cpg", sep = ""))
 
  
  # some reactive values that our UI can change
  loc <- reactiveValues(val = "pangenome_0001_length_5277220:2,075,785..2,077,085")
  
  ###### add or remove bookmark logic ######
  # add or remove bookmark logic
  values <- reactiveValues()
  
  values$bookmark_df <- tibble::tibble(
    chrom = character(),
    start = numeric(),
    end = numeric(),
    name = character()
  )
  
  observeEvent(input$selectedFeature, {
    values$bookmark_df <- values$bookmark_df %>%
      add_row(
        chrom = input$selectedFeature$refName,
        start = input$selectedFeature$start,
        end = input$selectedFeature$end,
        name = input$selectedFeature$name
      )
  })
  
  observeEvent(input$delete, {
    if (!is.null(input$bookmarks_rows_selected)) {
      values$bookmark_df <- values$bookmark_df %>%
        slice(-input$bookmarks_rows_selected)
    }
  })
  
  output$bookmarks <- DT::renderDT(values$bookmark_df)
  
  #### Quick selection of barcodes ####
  observeEvent(input$btn_all, {
    updateCheckboxGroupInput(
      session,
      "bc_choice",
      selected = paste("bc", 1:24, "_", sep = ''),
    )
  })
  
  observeEvent(input$btn_reset, {
    updateCheckboxGroupInput(
      session,
      "bc_choice",
      selected = paste("bc", 1:3, "_", sep = ''),
    )
  })
  
  observeEvent(input$btn_odds, {
    updateCheckboxGroupInput(
      session,
      "bc_choice",
      selected = paste("bc", seq(1,24,2), "_", sep = ''),
    )
  })
  
  observeEvent(input$btn_evens, {
    updateCheckboxGroupInput(
      session,
      "bc_choice",
      selected = paste("bc", seq(2,24,2), "_", sep = ''),
    )
  })
  
  observeEvent(input$btn_1to6, {
    updateCheckboxGroupInput(
      session,
      "bc_choice",
      selected = paste("bc", 1:6, "_", sep = ''),
    )
  })
  
  observeEvent(input$btn_1to12, {
    updateCheckboxGroupInput(
      session,
      "bc_choice",
      selected = paste("bc", 1:12, "_", sep = ''),
    )
  })
  
  observeEvent(input$btn_12to18, {
    updateCheckboxGroupInput(
      session,
      "bc_choice",
      selected = paste("bc", 12:18, "_", sep = ''),
    )
  })
  
  observeEvent(input$btn_12to24, {
    updateCheckboxGroupInput(
      session,
      "bc_choice",
      selected = paste("bc", 12:24, "_", sep = ''),
    )
  })
  
  observeEvent(input$btn_r12, {
    updateCheckboxGroupInput(
      session,
      "bc_choice",
      selected = paste("bc", sort(sample(24,12, replace = F)), "_", sep = ''),
    )
  })
  #### Quick selection of barcodes ####
  
  # navigate to bookmark logic
  observeEvent(input$navigate, {
    if (!is.null(input$bookmarks_rows_selected)) {
      
      if(length(input$bookmarks_rows_selected) == 1){
        loc$val <- paste0(
          values$bookmark_df[input$bookmarks_rows_selected, "chrom"],
          ":",
          values$bookmark_df[input$bookmarks_rows_selected, "start"],
          "..",
          values$bookmark_df[input$bookmarks_rows_selected, "end"]
        )
        updateTabsetPanel(session, "ecm",
                          selected = "Browser") ## flip the page to browser view on button click
      } else { # multiple rows selected
        shinyalert("Please select a single table entry to navigate", type = "info")
      }
    } else { # no rows selected
      shinyalert("Please select a table entry to navigate", type = "info")
    }
    
    
  })
  
  observeEvent(input$clear, {
    proxy %>% selectRows(NULL)
  })
  
  
  observeEvent(input$update, {
    ## logic to get proper tracks
    
    # tk = c('bc1_dam', 'bc1_dcm', 'annotations_track')
    # for(i in 1:2){
    
    if(input$srt == "meth"){
      idx = c()
      for(i in input$bc_choice){
        idx = c(idx, grep(i, all_tracks))
      }
      tmp = all_tracks[idx]
      idx = c()
      for(i in input$meth_choice){
        idx = c(idx, grep(i, tmp))
      }
    } else {
      idx = c()
      for(i in input$meth_choice){
        idx = c(idx, grep(i, all_tracks))
      }
      tmp = all_tracks[idx]
      idx = c()
      for(i in input$bc_choice){
        idx = c(idx, grep(i, tmp))
      }
    }
    
    tk1 = tmp[idx]
    
    tk1 = c('annotations_track', tk1)
    tracks <- patch_multi_line_json(JBrowseR::tracks(sapply(tk1, function(x) eval(parse(text = x)))))
    
    
    ds = default_session(assembly, sapply(tk1, function(x) eval(parse(text = x))), display_assembly = TRUE)
    updateTabsetPanel(session, "ecm",
                      selected = "Browser") ## flip the page to browser view on button click
    
    output$browserOutput <- renderJBrowseR(
      JBrowseR(
        "View",
        assembly = assembly,
        tracks = tracks,
        location = loc$val,
        defaultSession = ds,
        text_index = text_index(
          "https://ecoli-st131.s3.ap-southeast-2.amazonaws.com/ecoli_st131.ix",
          "https://ecoli-st131.s3.ap-southeast-2.amazonaws.com/ecoli_st131.ixx",
          "https://ecoli-st131.s3.ap-southeast-2.amazonaws.com/ecoli_st131_meta.json",
          "ecoli_st131")
      )
    )
  })
  
  session$onSessionEnded(function() {
    # s$stop_server()
    stopApp()
  })
}

# Run the application 
shinyApp(ui = ui, server = server)
