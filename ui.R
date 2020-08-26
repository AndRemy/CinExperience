library(plotly)
library(shiny)
library(shinydashboard)

shinyUI(
    dashboardPage(
        tags$head(
            tags$meta(name="application-name", content="Text Mining Student Cinema Experience"),
            tags$meta(name="author", content="HULT MSBA 2020 Candidates"),
            tags$meta(name="description", content="Text mining project to understand the motivation the motivation that drives students from San Francisco to the cinema."),
            tags$meta(name="keywords", content="NLP, LDA, Speech-to-Text, Text Analytics, Sentiment Analysis"),
            tags$meta(name="image", content="./docs/images/dashboard.png")
        ),
        skin   = "green",
        header = dashboardHeader(
            title = "Enhancing Cinema Experience" # Title of the entire shiny board
        ),
        sidebar = dashboardSidebar(
            sidebarMenu(          # Side bar that will contain the tabs
                menuItem(
                    "Challenges",      # Displayed itle of the tab
                    tabName = "intro", # Name of the tab. This will be used later in the body to put the content
                    icon = icon(name = "flag-checkered",
                                lib  = "font-awesome")
                ),
                menuItem(
                    "Current Experience", # Displayed itle of the tab
                    tabName = "wordCloud", # Name of the tab. This will be used later in the body to put the content
                    icon = icon(name = "film",
                                lib  = "font-awesome")
                ),
                menuItem(
                    "What People are Saying?", # Displayed itle of the tab
                    tabName = "ngrams", # Name of the tab. This will be used later in the body to put the content
                    icon = icon(name = "bullhorn",
                                lib  = "font-awesome")
                ),
                menuItem(
                    "Opportunities",    # Displayed itle of the tab
                    tabName = "tfidf", # Name of the tab. This will be used later in the body to put the content
                    icon = icon(name = "search",
                                lib  = "font-awesome")
                ),
                menuItem(
                    "Topics",    # Displayed itle of the tab
                    tabName = "topics", # Name of the tab. This will be used later in the body to put the content
                    icon = icon(name = "copy",
                                lib  = "font-awesome")
                ),
                menuItem(
                    "Recommendations",          # Displayed itle of the tab
                    tabName = "recommendations", # Name of the tab. This will be used later in the body to put the content
                    icon = icon(name = "lightbulb",
                                lib  = "font-awesome")
                ),
                menuItem(
                    "The Team",       # Displayed itle of the tab
                    tabName = "team", # Name of the tab. This will be used later in the body to put the content
                    icon = icon(name = "users",
                                lib  = "font-awesome")
                )
            )
        ),
        body = dashboardBody(
            tabItems(                      # A collection of items
                tabItem(                   # An individual item
                    tabName = "intro",     # Name of the tab to which the content will be embedded (see the items in sidebarMenu)
                    fluidPage(             #The content of the tab
                        titlePanel("The Challenge"),  #Title of the Panel
                        mainPanel(                   #The main content of the Panel
                            htmlOutput(outputId = "intro_text")
                        )
                    )
                ),
                tabItem(                     # An individual item
                    tabName = "wordCloud",   # Name of the tab to which the content will be embedded (see the items in sidebarMenu)
                    fluidPage(               # The content of the tab
                        titlePanel("The Current Experience"),  # Title of the Panel
                        sidebarPanel(                          # Include only if needed
                            radioButtons(
                                inputId = "library_select",
                                label   = "Select a sentiment library",
                                choices = c(
                                    "Bing library" = "bing",
                                    "NRC library"  = "nrc"
                                    ),
                                selected = "bing"
                            ),
                            htmlOutput("wordcloud_text")
                        ),
                        mainPanel(                             # The main content of the Panel
                            h2("Sentiment Word Cloud"),
                            plotOutput(outputId = "wordcloud", height = 500),
                            h2("Frequency per Question"),
                            plotlyOutput(outputId = "frequency", height = 600)
                        )
                    )
                ),
                tabItem(                     # An individual item
                    tabName = "ngrams",      # Name of the tab to which the content will be embedded (see the items in sidebarMenu)
                    fluidPage(               # The content of the tab
                        titlePanel("What People are Saying?"),  # Title of the Panel
                        sidebarPanel(
                            radioButtons(
                                inputId = "include_stop_words",
                                label   = "Include Stop Words?",
                                choices = c(
                                    "Include stop words"            = 0,
                                    "Remove stop words from word 1" = 1,
                                    "Remove stop words from word 2" = 2,
                                    "Remove all stop words"         = 3
                                ),
                                selected = 0
                            ),
                            htmlOutput(outputId = "ngram_text")
                        ),                         # Include only if needed
                        mainPanel(                              # The main content of the Panel
                            plotOutput("ngrams_network")
                        )
                    )
                ),
                tabItem(                     # An individual item
                    tabName = "tfidf",       # Name of the tab to which the content will be embedded (see the items in sidebarMenu)
                    fluidPage(               # The content of the tab
                        titlePanel("Business Opportunities"),  # Title of the Panel
                        sidebarPanel(                          # Include only if needed
                            selectInput(
                                inputId  = "question_input",
                                label    = "Questions",
                                choices  = c(
                                    "All questions"                                  = 0,
                                    "1) What do you do in your free time?"           = 1,
                                    "2) Why do you like these activities?"           = 2,
                                    "3) How much you spend?"                         = 3,
                                    "4) What do you like to do on dates?"            = 4,
                                    "5) When was the last time yo went to a cinema?" = 5,
                                    "6) Would you go to the cinema?"                 = 6
                                ),
                                selected = 0
                            ),
                            htmlOutput("tfidf_text")
                        ),
                        mainPanel(                             # The main content of the Panel
                            h2("Digging deeper into what people say"),
                            plotlyOutput("tfidf_plot", height = 900)
                        )
                    )
                ),
                tabItem(                         # An individual item
                    tabName = "topics",          # Name of the tab to which the content will be embedded (see the items in sidebarMenu)
                    fluidPage(                   # The content of the tab
                        titlePanel("Classifying the questions by topic"),  # Title of the Panel
                        sidebarPanel(                 # Include only if needed
                            sliderInput(
                                inputId = "topicNumber",
                                label   = "Select the Number of Topics",
                                min     = 2,
                                max     = 4,
                                value   = 3,
                                step    = 1,
                                round   = TRUE
                            ),
                            htmlOutput(outputId = "topic_text")
                        ),
                        mainPanel(                     # The main content of the Panel
                            h2("Topics"),
                            plotlyOutput("betaMatrix", height = 500),
                            h2("Questions per Topic"),
                            plotlyOutput("gammaMatrix", height = 500)
                        )
                    )
                ),
                tabItem(                         # An individual item
                    tabName = "recommendations", # Name of the tab to which the content will be embedded (see the items in sidebarMenu)
                    fluidPage(                   # The content of the tab
                        titlePanel("Recommendations"),  # Title of the Panel
                        mainPanel(                      # The main content of the Panel
                            htmlOutput("recomm_output")
                        )
                    )
                ),
                tabItem(              # An individual item
                    tabName = "team", # Name of the tab to which the content will be embedded (see the items in sidebarMenu)
                    fluidPage(        # The content of the tab
                        titlePanel("The Team"),  # Title of the Panel
                        mainPanel(               # The main content of the Panel
                            fluidRow(
                                box(
                                    title = "Mohammed Yahya",
                                    icon(name = "linkedin", lib = "font-awesome"),
                                    span(": "),
                                    tags$a("linkedin.com/", href="https://www.linkedin.com/", target="_blank")
                                ),
                                box(
                                    title = "Mario Palazuelos",
                                    icon(name = "linkedin", lib = "font-awesome"),
                                    span(": "),
                                    tags$a("in/mario-palazuelos-argaiz/", href="https://www.linkedin.com/in/mario-palazuelos-argaiz/", target="_blank")
                                )
                            ),
                            fluidRow(
                                box(
                                    title = "Zhiyi Chen",
                                    icon(name = "linkedin", lib = "font-awesome"),
                                    span(": "),
                                    tags$a("linkedin.com/", href="https://www.linkedin.com/in/zhiyi-chen-4a987619a/", target="_blank")
                                ),
                                box(
                                    title = "Hye Lim Kim",
                                    icon(name = "linkedin", lib = "font-awesome"),
                                    span(": "),
                                    tags$a("linkedin.com/", href="https://www.linkedin.com/in/hyelimkim93/", target="_blank")
                                )
                            ),
                            fluidRow(
                                box(
                                    title = "Mats Lunde",
                                    icon(name = "linkedin", lib = "font-awesome"),
                                    span(": "),
                                    tags$a("in/matsblunde/", href="https://www.linkedin.com/in/matsblunde/", target="_blank")
                                ),
                                box(
                                    title = "Andre Remy",
                                    icon(name = "linkedin", lib = "font-awesome"),
                                    span(": "),
                                    tags$a("in/andremy/", href="https://www.linkedin.com/in/andremy/", target="_blank")
                                )
                            )
                        )
                    )
                )
            )
        )
    )
)