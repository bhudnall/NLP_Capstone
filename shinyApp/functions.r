library(tm)
library(openNLP)
library(RWeka)
library(dplyr)
library(stringr)
library(slam)
library(data.table)
library(stringr)

# Load profanity list
profanity <- read.table("profanity.txt", header = FALSE, sep = "\n")

# this function will pull the data from the data files
# and create a sample that is large enough to be accurate
# but not to big to be manageable. it relies on the 
# rbinom function
createSample <- function(file_name, size, prob = 0.5) {
    
    lines_file <- readLines(file_name, skipNul = TRUE)
    lines_file <- lines_file[rbinom(
        length(lines_file) * size,
        length(lines_file),
        prob
    )]
    close(file_name)
    return(lines_file)
}

# this function creates the corpus and lowers the font,
# strips whitespace, removes punctuation, numbers, profanity,
# and then converts it to a plain text document. It relies 
# heavily on the tm library
create_corpus <- function(x) {
    corpus <- VCorpus(VectorSource(x))
    corpus <- tm_map(corpus, content_transformer(tolower))
    corpus <- tm_map(corpus, stripWhitespace)
    corpus <- tm_map(corpus, removePunctuation)
    corpus <- tm_map(corpus, removeNumbers)
    corpus <- tm_map(corpus, removeWords, profanity[1,])
    corpus <- tm_map(corpus, PlainTextDocument)
    corpus
}

# these functions create the bigram, trigram, quadgram and pentagram
bigram_token <- function(x) NGramTokenizer(x, Weka_control(min=2, max=2))
trigram_token <- function(x) NGramTokenizer(corpus, Weka_control(min=3, max=3))
quadgram_token <- function(x) NGramTokenizer(corpus, Weka_control(min=4, max=4))
pentagram_token <- function(x) NGramTokenizer(corpus, Weka_control(min=5, max=5))

# this function finds the length of the phrase being passed
# and then based on length will filter the top n-gram to predict
# the next word. it relies on the getResults function below.
returnResults <- function(sent, db) {
    
    results_df <- data.frame(pred = character(), count = integer())
    for (word in min(length(sent), 4):1) {
        final_sent <- paste(tail(sent, word), collapse = " ") 
        if (word == 4) {
            query <- paste("select pred, count from pentagram where ", "prev=='"
                           , paste(final_sent), "'", " limit 2", sep="")
            send_query <- dbSendQuery(conn=db, query)
            results <- dbFetch(send_query, n=-1)
            results_df <- bind_rows(results_df, results)
        } else if (word == 3) {
            query <- paste("select pred, count from quadgram where ", "prev=='"
                             , paste(final_sent), "'", " limit 2", sep="")
            send_query <- dbSendQuery(conn=db, query)
            results <- dbFetch(send_query, n=-1)
            results_df <- bind_rows(results_df, results)
        } else if (word == 2) {
            query <- paste("select pred, count from trigram where ", "prev=='"
                             , paste(final_sent), "'", " limit 2", sep="")
            send_query <- dbSendQuery(conn=db, query)
            results <- dbFetch(send_query, n=-1)
            results_df <- bind_rows(results_df, results)
        } else {
            query <- paste("select pred, count from bigram where ", "prev=='"
                             , paste(final_sent), "'", " limit 2", sep="")
            send_query <- dbSendQuery(conn=db, query)
            results <- dbFetch(send_query, n=-1)
            results_df <- bind_rows(results_df, results)
        }
    }
    as.character(results_df[1,1])
}

# for each phrase pull on the words before the last word in the 
# sentence and also the last word of the sentence
parsePhrase <- function(df) {
    df <- df %>% mutate(prev = str_trim(str_match(phrase, ".*[^a-z]+")),
                        pred = str_trim(str_match(phrase, "[ ]+?[a-z]+$")))
}

createTable <- function(db, tableName) {
    dbSendQuery(conn = db, paste("create table", tableName, "(prev text, pred text, count integer)"))
}

sqlInsert <- function(db, query, dataFrame) {
    dbBegin(db)
    dbGetPreparedQuery(db, query, bind.data = dataFrame)
    dbCommit(db)
}