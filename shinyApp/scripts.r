library(tm)
library(openNLP)
library(RWeka)
library(dplyr)
library(stringr)
library(slam)
library(data.table)
library(stringr)
library(RSQLite)
source('functions.r')

# Set the wd
setwd("/Users/brianhudnall/Programming/R/NLP_Capstone/shinyApp/")
source('functions.r')

# pull in the data
twitter <- createSample(file("en_US.twitter.txt", "r"), .003)
blogs <- createSample(file("en_US.blogs.txt", "r"), .006)
news <- createSample(file("en_US.news.txt", "r"), .006)

# combine sources into a connected list
lines_collapsed <- paste(twitter, blogs, news, collapse = " ")

# create the corpus
corpus <- create_corpus(lines_collapsed)

# create the N-grams
bigram <- bigram_token(corpus)
trigram <- trigram_token(corpus)
quadgram <- quadgram_token(corpus)
pentagram <- pentagram_token(corpus)

# create the term document matrix
bi_tdm <- TermDocumentMatrix(corpus, control = list(tokenize = bigram_token))
tri_tdm <- TermDocumentMatrix(corpus, control = list(tokenize = trigram_token))
quad_tdm <- TermDocumentMatrix(corpus, control = list(tokenize = quadgram_token))
pent_tdm <- TermDocumentMatrix(corpus, control = list(tokenize = pentagram_token))

# create dataframes of the N-grams
bigram_df <- as.data.frame(table(bigram))
trigram_df <- as.data.frame(table(trigram))
quadgram_df <- as.data.frame(table(quadgram))
pentagram_df <- as.data.frame(table(pentagram))

# order the n-gram dataframes
bigram_df <- bigram_df[order(bigram_df$Freq, decreasing = TRUE),]
trigram_df <- trigram_df[order(trigram_df$Freq, decreasing = TRUE),]
quadgram_df <- quadgram_df[order(quadgram_df$Freq, decreasing = TRUE),]
pentagram_df <- pentagram_df[order(pentagram_df$Freq, decreasing = TRUE),]

# assign the column names to the dataframes
colnames(bigram_df) <- c("phrase", "count")
colnames(trigram_df) <- c("phrase", "count")
colnames(quadgram_df) <- c("phrase", "count")
colnames(pentagram_df) <- c("phrase", "count")

# parse the previous and current words
bigram_df <<- parsePhrase(bigram_df)
trigram_df <<- parsePhrase(trigram_df)
quadgram_df <<- parsePhrase(quadgram_df)
pentagram_df <<- parsePhrase(pentagram_df)

# connect to db and create tables
ngram_data <- dbConnect(SQLite(), dbname="ngram_data.db")
createTable(ngram_data, "bigram")
createTable(ngram_data, "trigram")
createTable(ngram_data, "quadgram")
createTable(ngram_data, "pentagram")

# statements
bi_insert <- "insert into bigram values ($prev, $pred, $count)"
tri_insert <- "insert into trigram values ($prev, $pred, $count)"
quad_insert <- "insert into quadgram values ($prev, $pred, $count)"
pent_insert <- "insert into pentagram values ($prev, $pred, $count)"

# indert into the premade tables
sqlInsert(ngram_data, bi_insert, bigram_df)
sqlInsert(ngram_data, tri_insert, trigram_df)
sqlInsert(ngram_data, quad_insert, quadgram_df)
sqlInsert(ngram_data, pent_insert, pentagram_df)

# close the db connection
dbDisconnect(ngram_data)



