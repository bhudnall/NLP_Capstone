library(tm)
library(openNLP)
library(RWeka)
library(dplyr)
library(ggplot2)
library(cluster)

setwd("/Users/brianhudnall/Programming/R/NLP_Capstone/final")

## DATA GATHERING SECTION
prob <- 0.5
profanity <- read.table("profanity.txt"
                    , header = FALSE
                    , sep = "\n")

createSample <- function(lines_file, size, prob) {
    lines_file <- lines_file[rbinom(
        length(lines_file) * size,
        length(lines_file),
        prob
    )]
    return(lines_file)
}

set.seed(333)

us_twitter <- file("en_US/en_US.twitter.txt", "r") 
twitter_lines <- readLines(us_twitter, skipNul = TRUE) 
# Sample Twitter data
twitter_lines <- createSample(twitter_lines, .003, prob)
## twitter_lines <- sample_frac(as.data.frame(twitter_lines), .003)
length(twitter_lines)


us_blogs <- file("en_US/en_US.blogs.txt", "r")
blogs_lines <- readLines(us_blogs, skipNul = TRUE)
# Sample Blog data
blogs_lines <- createSample(blogs_lines, .006, prob)
## blogs_lines <- sample_frac(as.data.frame(blogs_lines), .006)


us_news <- file("en_US/en_US.news.txt", "r")
news_lines <- readLines(us_news, skipNul = TRUE)
# Sample News data
news_lines <- createSample(news_lines, .006, prob)
## news_lines <- sample_frac(as.data.frame(news_lines), .006)

## Close all connections with finished
close(us_twitter)
close(us_blogs)
close(us_news)

lines_collapsed <- paste(twitter_lines
                         , blogs_lines
                         , news_lines
                         , collapse = " ")
lines_source <- VectorSource(lines_collapsed)

## INSERT WORD AND LINE COUNT*****

# Create Corpus
us_corpus <- Corpus(lines_source)

# Convert to lower
us_corpus <- tm_map(us_corpus
                    , tolower)
# Remove Punctuation
us_corpus <- tm_map(us_corpus
                    , removePunctuation)
# Strip whitespace
us_corpus <- tm_map(us_corpus
                    , stripWhitespace)
# Remove numbers
us_corpus <- tm_map(us_corpus
                    , removeNumbers)
# Remove Bad words
us_corpus <- tm_map(us_corpus
                    , removeWords, profanity[1,])

# Completed preprocessing
us_corpus <- tm_map(us_corpus
                    , PlainTextDocument)

## EXPLORATORY ANALYSIS SECTION

# Includes all words except profanity
doc_matrix <- DocumentTermMatrix(us_corpus)
doc_matrix <- removeSparseTerms(doc_matrix, 0.10)
doc_matrix
doc_as_matrix <- as.matrix(doc_matrix)

## Sort terms to see the highest frequency
frequency <- colSums(doc_as_matrix)
frequency_sort <- sort(frequency, decreasing = TRUE)
head(frequency_sort)

## Show terms with higher than 500 count
findFreqTerms(doc_matrix, lowfreq = 500)

## Make Bi Gram
bigram <- NGramTokenizer(us_corpus
                         , Weka_control(min=2, max=2))
bigram_df <- as.data.frame(table(bigram))
bigram_df_sort <- bigram_df[order(bigram_df$Freq
                                  , decreasing = TRUE),]

## Filter to top 20 then chart
bigram_df_top <- bigram_df_sort[1:20,]
colnames(bigram_df_top) <- c("Phrase", "Count")
ggplot(bigram_df_top, aes(x=reorder(Phrase, Count), y=Count)) +
    geom_bar(stat='identity') +
    coord_flip() +
    ggtitle("Top Bigram Phrases by Count") +
    xlab("Phrases") +
    theme_minimal()

## Make Tri Gram
trigram <- NGramTokenizer(us_corpus
                          , Weka_control(min=3, max=3))
trigram_df <- as.data.frame(table(trigram))
trigram_df_sort <- trigram_df[order(trigram_df$Freq
                                    , decreasing = TRUE),]
## filter to top 20 then chart
trigram_df_top <- trigram_df_sort[1:20,]
colnames(trigram_df_top) <- c("Phrase", "Count")
ggplot(trigram_df_top, aes(x=reorder(Phrase, Count), y=Count)) +
    geom_bar(stat='identity') +
    coord_flip() +
    ggtitle("Top Trigram Phrases by Count") +
    xlab("Phrases") +
    theme_minimal()






