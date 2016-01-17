library(tm)
library(openNLP)
library(RWeka)
library(dplyr)
library(stringr)
library(slam)
library(data.table)
library(stringr)

setwd("/Users/brianhudnall/Programming/R/NLP_Capstone/final/en_US/")

## DATA GATHERING SECTION
profanity <- read.table("profanity.txt"
                    , header = FALSE
                    , sep = "\n")

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

twitter <- createSample(file("en_US.twitter.txt", "r"), .003)
blogs <- createSample(file("en_US.blogs.txt", "r"), .006)
news <- createSample(file("en_US.news.txt", "r"), .006)


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

lines_collapsed <- paste(twitter
                         , blogs
                         , news
                         , collapse = " ")

corpus <- create_corpus(lines_collapsed)

bigram_token <- function(x) NGramTokenizer(x, Weka_control(min=2, max=2))
trigram_token <- function(x) NGramTokenizer(corpus, Weka_control(min=3, max=3))
quadgram_token <- function(x) NGramTokenizer(corpus, Weka_control(min=4, max=4))
pentagram_token <- function(x) NGramTokenizer(corpus, Weka_control(min=5, max=5))

bigram <- bigram_token(corpus)
trigram <- trigram_token(corpus)
quadgram <- quadgram_token(corpus)
pentagram <- pentagram_token(corpus)

bi_tdm <- TermDocumentMatrix(corpus, control = list(tokenize = bigram_token))
tri_tdm <- TermDocumentMatrix(corpus, control = list(tokenize = trigram_token))
quad_tdm <- TermDocumentMatrix(corpus, control = list(tokenize = quadgram_token))
pent_tdm <- TermDocumentMatrix(corpus, control = list(tokenize = pentagram_token))

bigram_df <- as.data.frame(table(bigram))
trigram_df <- as.data.frame(table(trigram))
quadgram_df <- as.data.frame(table(quadgram))
pentagram_df <- as.data.frame(table(pentagram))

bigram_df <- bigram_df[order(bigram_df$Freq, decreasing = TRUE),]
trigram_df <- trigram_df[order(trigram_df$Freq, decreasing = TRUE),]
quadgram_df <- quadgram_df[order(quadgram_df$Freq, decreasing = TRUE),]
pentagram_df <- pentagram_df[order(pentagram_df$Freq, decreasing = TRUE),]

colnames(bigram_df) <- c("phrase", "count")
colnames(trigram_df) <- c("phrase", "count")
colnames(quadgram_df) <- c("phrase", "count")
colnames(pentagram_df) <- c("phrase", "count")

parsePhrase <- function(df) {
    df <- df %>% mutate(prev = str_trim(str_match(phrase, ".*[^a-z]+")),
               pred = str_trim(str_match(phrase, "[ ]+?[a-z]+$")))
}

bigram_df <<- parsePhrase(bigram_df)
trigram_df <<- parsePhrase(trigram_df)
quadgram_df <<- parsePhrase(quadgram_df)
pentagram_df <<- parsePhrase(pentagram_df)

sent <- "hello"

clean_entry <- tolower(sent) %>%
    removeNumbers %>%
    removePunctuation() %>%
    stripWhitespace() %>%
    str_trim %>%
    strsplit(split = " ") %>%
    unlist

returnResults <- function(sent) {
    
    results_df <- data.frame(pred = character(), count = integer())
    for (word in min(length(sent), 4):1) {
        final_sent <- paste(tail(sent, word), collapse = " ") 
        if (word == 4) {
            results_df <- bind_rows(results_df, getResults(final_sent, pentagram_df))
        } else if (word == 3) {
            results_df <- bind_rows(results_df, getResults(final_sent, quadgram_df))
        } else if (word == 2) {
            results_df <- bind_rows(results_df, getResults(final_sent, trigram_df))
        } else {
            results_df <- bind_rows(results_df, getResults(final_sent, bigram_df))
        }
    }
    as.character(results_df[1,1])
}

getResults <- function(final_sent, df) {
    
     results <- df %>%
         filter(prev == final_sent) %>%
          top_n(2, count) %>%
          select(pred, count)
}

print(returnResults(clean_entry))









