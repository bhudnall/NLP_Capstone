library(shiny)

shinyUI(fluidPage(
    
    navbarPage("NLP Capstone Project for the John Hopkins Data Science Certificate"),
    h5("Author: Brian Hudnall"),
    p("App Background: the main objective of the data science certificate capstone course 
       is to create a product to highlight a prediction algorithm created using datasets
       compiled from Twitter, News Articles and Blog Posts."),
    br(),
    p("The model in the app uses ",
        a(href="https://en.wikipedia.org/wiki/N-gram", "n-grams"),
        "to find a high probability of sets of words."),
    br(),
    p("The model also has a ",
      a(href="https://en.wikipedia.org/wiki/Katz%27s_back-off_model", "back-off feature"),
      "to oscilate between different n-gram models to make the most accurate prediction."),
    br(),
    p("For answers regarding the model created and how to use the app, please reference the "
      , a(href="http://rpubs.com/bhudnall/NLP_capstone_doc", "documentation.")),
    br(),
    br(),
    sidebarLayout(
        sidebarPanel(
            textInput("inputId"
                      , "Please enter your phrase"
                      , value = "hundred years ago wireless"),
            actionButton("predict", "Predict"),
            helpText("Type in a phrase and press predict to find out what word would come next!")
        ),
        mainPanel(
            h5("The word predicted based on the phrase provided is: "),
            strong(textOutput("prediction"))
        )
    )
))