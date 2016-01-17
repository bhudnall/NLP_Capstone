library(shiny)
library(stringr)
library(tm)
library(RSQLite)
source('functions.r')

shinyServer(function(input, output) {
    
    clean_input <- eventReactive(input$predict, {
        
        clean_entry <- tolower(input$inputId) %>%
            removeNumbers %>%
            removePunctuation() %>%
            stripWhitespace() %>%
            str_trim %>%
            strsplit(split = " ") %>%
            unlist
    })
    
    alg_results <- reactive({
        
        db <- dbConnect(SQLite(), dbname="ngram_data.db")
        phrase_entry <- clean_input()
        ifelse(!is.na(returnResults(phrase_entry, db))
                         , returnResults(phrase_entry, db)
                         , "Sorry, I don't know!")
    })
    
    output$prediction <- renderText({
        output <- alg_results()
    })
})