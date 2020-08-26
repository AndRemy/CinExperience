# [1]: Library dependencies
if (!require("textdata")) install.packages("textdata")
if (!require("ggplot2")) install.packages("ggplot2")

# Text Analytics libraries
library(dplyr)
library(textreadr)
library(tidyverse)
library(tidytext)
library(topicmodels)
library(textdata)

#Library plots
library(ggplot2)
library(plotly)
library(igraph)
library(ggraph)
library(wordcloud)
library(reshape2)

# Library for shiny app
library(shiny)
# [1]: End


# [2]: Loading required libraries
tryCatch({
  afinn_sentiment <<- get_sentiments(lexicon="afinn")
  bing_sentiment  <<- get_sentiments(lexicon="bing")
  nrc_sentiment   <<- get_sentiments(lexicon="nrc")
}, error = function(ex) {
  # This lines were addedd because in the shinyapps server I couldn't dowload them
  afinn_sentiment <<- read.csv("./libraries/afinn.csv")
  bing_sentiment  <<- read.csv("./libraries/bing.csv")
  nrc_sentiment   <<- read.csv("./libraries/nrc.csv")
}
)

# Custom stop words
custom_stop_words <<- data.frame(word = "null", stringsAsFactors = FALSE)
# [2]: End


# [3]: Loading and formating survey answers
load_data <- function(){
  text_file     <- "./answers/SurveyAnswers1and2.txt"
  answers       <- read_document(file = text_file)
  surveyed      <- c(0, rep(1:(length(answers)-1)%/%6)) + 1
  question      <- rep(1:6, time = length(answers)/6)
  
  answers_df <- data.frame(
    id               = paste(surveyed, question, sep = '-'),
    surveyed         = surveyed,
    question         = question,
    text             = answers,
    stringsAsFactors = FALSE
  )
  
  return(answers_df)
}
# [3]: End


# [4]: Function that allows the tokenization of the data.
tokenize_data <- function(answers_df, bigram = FALSE, include_stopwords = 0){
  
  if(bigram == FALSE){
    tidy_answers <- answers_df %>%
      unnest_tokens(word, text) %>%
      anti_join(stop_words, by="word") %>%
      anti_join(custom_stop_words, by="word") %>%
      count(question, word) %>%
      mutate(word = reorder(word, n))
  }
  else{
    afinn_data <- afinn_sentiment
    
    if(include_stopwords == 0){
      tidy_answers <- answers_df %>%
        unnest_tokens(bigram, text, token = "ngrams", n=2)%>%
        separate(bigram, c("word1", "word2"), sep=" ")%>%
        inner_join(afinn_data, by=c(word2="word")) %>%
        count(word1, word2, value, sort=TRUE)
    }
    else{
      if(include_stopwords == 1){
        tidy_answers <- answers_df %>%
          unnest_tokens(bigram, text, token = "ngrams", n=2)%>%
          separate(bigram, c("word1", "word2"), sep=" ")%>%
          anti_join(stop_words, by=c(word1="word")) %>%
          anti_join(custom_stop_words, c(word1="word")) %>%
          inner_join(afinn_data, by=c(word2="word")) %>%
          count(word1, word2, value, sort=TRUE)
      }
      else{
        if(include_stopwords == 2){
          tidy_answers <- answers_df %>%
            unnest_tokens(bigram, text, token = "ngrams", n=2)%>%
            separate(bigram, c("word1", "word2"), sep=" ")%>%
            anti_join(stop_words, by=c(word2="word")) %>%
            anti_join(custom_stop_words, c(word2="word")) %>%
            inner_join(afinn_data, by=c(word2="word")) %>%
            count(word1, word2, value, sort=TRUE)
        }
        else{
            tidy_answers <- answers_df %>%
              unnest_tokens(bigram, text, token = "ngrams", n=2)%>%
              separate(bigram, c("word1", "word2"), sep=" ")%>%
              anti_join(stop_words, by=c(word1="word")) %>%
              anti_join(custom_stop_words, c(word1="word")) %>%
              anti_join(stop_words, by=c(word2="word")) %>%
              anti_join(custom_stop_words, c(word2="word")) %>%
              inner_join(afinn_data, by=c(word2="word")) %>%
              count(word1, word2, value, sort=TRUE)
        }
      }
    }
  }
  
  return(tidy_answers)
}
# [4]: End


# [5]: Function that returns the LDA model based on the number of topics sent as parameter
lda_analysis_per_question <- function(data_set, topic_number = 2){
  #Casting DTM by question
  answers_dtm <- data_set %>%
    cast_dtm(question, word, n)
  
  #Applyting LDA per question
  ap_lda <- LDA(answers_dtm, k=topic_number, control=list(seed=123))
  
  return(ap_lda)
}
# [5]: End


# [6]: Server side code to the UI
shinyServer(function(input, output) {
  answers_df <- load_data()
  tidy_answers <- tokenize_data(answers_df = answers_df,
                                bigram = FALSE)
  
  output$intro_text <- renderUI({
    html <-
      "<span>
        While talking between different colleagues, we found that most of us like to watch movies BUT there was one problem. Not all of them were going to the movie theatre lately.
        To understand why was this happening, <u>our team designed a survey that aimed to help us understand what can this industry do to attract students back to the movie theatre.</u>
        <br/>
        <br/>
        <b>Audience:</b> Students in San Francisco<br />
        <b>Sample Size:</b> 50<br />
        <b>Survey Date:</b> Feb. 3rd, 2020<br />
        <b>Questions:</b>
          <ol>
            <li>What do you do in your free time?</li>
            <li>Why do you like these activities?</li>
            <li>How much you spend?</li>
            <li>What do you like to do on dates?</li>
            <li>When was the last time yo went to a cinema?</li>
            <li>Would you go to the cinema?</li>
          </ol>
        <b>Method:</b> Recorded speech transformed to text
      </span>
    "
    HTML(html)
  })
  
  output$wordcloud_text <- renderUI({
    html <- "
    <span>
      According to our survey, we found that people have a neutral sentiment towards our questions. Nonetheless, if we disaggregate these sentiments, we can see that when people talk about their favorite activity and why they do it they express joy mostly (as expected); nonetheless, There is a trend feeling of anticipation and anger may be due to the fact that people can't really do these activities they like from the lack of time and/or money.<br />
      <br />
      Generally speaking, during free time, people like to watch a movie, read books, and go to the gym. The activities that people most liked was watching movies. People also enjoy having dinner and watch movies on their dates. However, the insights through the frequency graph are just one aspect of the analysis.<br/>
      <br/>
      <b>Questions:</b>
        <ol>
          <li>What do you do in your free time?</li>
          <li>Why do you like these activities?</li>
          <li>How much you spend?</li>
          <li>What do you like to do on dates?</li>
          <li>When was the last time yo went to a cinema?</li>
          <li>Would you go to the cinema?</li>
        </ol>
    </span>"
    HTML(html)
  })
  
  output$wordcloud <- renderPlot({
    library_select <- input$library_select
    
    tidy_answers %>%
      with(wordcloud(word, n, max.words = 100))
    
    if(library_select == "nrc"){
      sentiment_data <- nrc_sentiment
    }
    else{
      sentiment_data <- bing_sentiment
    }
    
    tidy_answers %>%
      inner_join(sentiment_data, by = "word") %>%
      count(word, sentiment, sort=TRUE) %>%
      acast(word ~sentiment, value.var="n", fill=0) %>%
      comparison.cloud(colors = c("grey20", "gray80"),
                       max.words=100)
  })
  
  output$frequency <- renderPlotly({
    tidy_plot <- tidy_answers %>%
      group_by(question)%>%
      arrange(desc(n)) %>%
      top_n(7) %>%
      ungroup() %>%
      mutate(word = reorder(word, n)) 
    
    frequency_plot <- ggplot(
      tidy_plot,
      aes(x = word, y = n, fill = factor(question))
      ) + 
      geom_col() + 
      coord_flip() + 
      facet_wrap(~question, ncol = 2, scales = "free") +
      labs(x=NULL, y="Frequency") +
      theme(legend.position = "none")
    
    ggplotly(frequency_plot)
  })
  
  output$ngram_text <- renderUI({
    html <- "
    <span>
      Plotting how words were structured in sentences, we can see some positive and negative clusters. But our main takeaway is that people do like and want to go to the cinema and watch movies. But we can also some word groups in which we sense the frustration we were looking in the previous sentiment word cloud.
    </span>"
    HTML(html)
  })
  
  output$ngrams_network <- renderPlot({
    selection    <- input$include_stop_words
    bigram_graph <- tokenize_data(answers_df = answers_df,
                                  bigram = TRUE,
                                  include_stopwords = selection) %>%
      graph_from_data_frame()
    
    ggraph(bigram_graph, layout = "fr") +
      geom_edge_link()+
      geom_node_point()+
      geom_node_text(aes(label=name), vjust =1, hjust=1)
  })
  
  output$tfidf_text <- renderUI({
    html <-
    "<span>
      Main takeaways by question:
      <ol>
        <li>People like reading books, going gym, listening music, and watching Netflix.</li>
        <li>People do certain activities to feel less stress, relax and be happy.</li>
        <li>They spend average $50 when they go out.</li>
        <li>Lots of people go on a movie date.</li>
        <li>Most of the people watch movie once in a month.</li>
        <li>People still like going to movie!!!!</li>
      </ol>
    </span>"
    HTML(html)
  })
  
  output$tfidf_plot <- renderPlotly({
    tfidf_data <- tidy_answers %>%
      bind_tf_idf(word, question, n) %>%
      group_by(question) %>%
      arrange(desc(tf_idf)) %>%
      ungroup() %>%
      mutate(word = factor(word, levels = rev(unique(word))))
    
    question_input <- input$question_input
    
    limit = 7
    
    if(question_input == 0){
      tfidf_to_plot <- tfidf_data %>%
        group_by(question) %>%
        top_n(limit) %>%
        ungroup()
    }
    else {
      tfidf_to_plot <- tfidf_data[tfidf_data$question == question_input,] %>%
        top_n(limit)
    }
    
    tfidf_plot <- ggplot(
      tfidf_to_plot,
      aes(
        x    = word,
        y    = tf_idf,
        fill = factor(question)
      )
    ) +
      geom_col(show.legend = FALSE) +
      labs(x = NULL, y = "tf-idf") +
      facet_wrap(~question, ncol = 2, scales = "free") +
      theme(legend.position = "none") +
      coord_flip()
    
    ggplotly(tfidf_plot)
  })
  
  output$topic_text <- renderUI({
    html <-
      "<span>
        In order to prove our hypothesis, we want to analyze how our questions were answered and what specific topics were talked about in each question.</br>
        To see this better, we developed an option to classify the question in 2, 3 or 4 topics</br>
        We found that classifying our questions in 3 topics there is a better understanding of what people were talking about</br>
        By choosing 3, we found the following topics:
        <ol>
          <li>Feelings in Hobbies</li>
          <li>Cinema</li>
          <li>Spending & Dating</li>
        </ol>
        <br/>
        <b>Questions:</b>
          <ol>
            <li>What do you do in your free time?</li>
            <li>Why do you like these activities?</li>
            <li>How much you spend?</li>
            <li>What do you like to do on dates?</li>
            <li>When was the last time yo went to a cinema?</li>
            <li>Would you go to the cinema?</li>
          </ol>
       </span>"
    HTML(html)
  })
  
  output$betaMatrix <- renderPlotly({
    topic_Number <- input$topicNumber
    
    lda_object <- lda_analysis_per_question(tidy_answers, topic_Number)
    
    my_beta  <- tidy(lda_object, matrix = "beta")
    
    #lets plot the term frequencies by topic
    top_terms <- my_beta %>%
      group_by(topic) %>%
      top_n(10, beta) %>%
      ungroup() %>%
      arrange(topic, -beta) %>%
      mutate(term = reorder(term, beta))
    
    #lets plot the term frequencies by topic
    plot_beta <- ggplot(top_terms,
                        aes(term, beta, fill = factor(topic))) +
      geom_col(show.legend = FALSE) +
      facet_wrap(~topic, scales = "free") +
      coord_flip() +
      theme(legend.position = "none",
            axis.title.x = element_blank(),
            axis.title.y = element_blank())
    
    ggplotly(plot_beta)
  })
  
  output$gammaMatrix <- renderPlotly({
    topic_Number <- input$topicNumber
    
    lda_object <- lda_analysis_per_question(tidy_answers, topic_Number)
    
    my_gamma <- tidy(lda_object, matrix = "gamma")

    #lets plot the term frequencies by topic
    plot_gamma <- ggplot(my_gamma,
                        aes(x = document, y = gamma, fill = factor(topic))) +
      geom_col(show.legend = FALSE) +
      facet_wrap(~topic, scales = "free") +
      coord_flip() +
      theme(legend.position = "none",
            axis.title.x = element_blank(),
            axis.title.y = element_blank())
    
    ggplotly(plot_gamma)
  })
  
  output$recomm_output <- renderUI({
    html<-
    "<span>
      Given the data, we observe <b>two</b> factors that can be used to incentivize movie going within students:
      <ol>
        <li>Since several students seem to have difficulty to afford movie tickets, as suggested by their $50 spending limit on going out, and also like to spend their free time reading, <u>we suggest to offer discounts on movie tickets that are based on books</u>.</li>
        <li>The questions in our survey reflected some constraints on the movie-going experience and habits. To improve the quality of the insights and prove if our recommendations might work, <u>we suggest doing another survey focused more on the goers' experience rather than their preferred activities in terms of genre, expenditure, and so forth.</u></li>
      </ol>
    </span>
    "
    HTML(html)
  })
})
# [6]: End