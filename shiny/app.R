library(shiny)
library(ggplot2)
library(dplyr)
library(DT) # Added DT package
housing_data <- read.csv("../data/final_data.csv")
# str(housing_data )

#' data.frame':   156511 obs. of  18 variables:
#  $ Sale_Date_Raw      : chr  "2012-06-11" "2013-09-17" "2020-03-07" "2004-12-17" ...
#  $ Sale_Price_Raw     : num  625000 120000 250000 320000 822000 369000 32500 259000 220000 141000 ...
#  $ Square_Feet_Raw    : int  1673 1510 620 1364 2484 2375 1512 882 2210 1680 ...
#  $ Latitude_Raw       : num  47.2 47.3 47.3 47.3 47.3 ...
#  $ Longitude_Raw      : num  -123 -123 -123 -123 -123 ...
#  $ Bedrooms_Raw       : int  3 2 2 3 4 3 3 2 3 2 ...
#  $ Bathrooms_Raw      : num  2.5 2 1 1.75 3.25 2.5 2 1 2 2 ...
#  $ Stories_Raw        : num  1 1 1 1 3 1.5 1 1 1 1 ...
#  $ Quality            : chr  "Good" "Good" "Fair" "Average" ...
#  $ Condition          : chr  "Average" "Average" "Average" "Average" ...
#  $ Neighborhood       : chr  "101114" "100908" "100908" "101106" ...
#  $ Street_Type        : chr  "STREET UNPAVED" "STREET UNPAVED" "PAVED" "PAVED" ...
#  $ Utility_Water      : chr  "WATER INSTALLED" "WATER INSTALLED" "WATER INSTALLED" "WATER INSTALLED" ...
#  $ Utility_Electric   : chr  "POWER INSTALLED" "POWER INSTALLED" "POWER INSTALLED" "POWER INSTALLED" ...
#  $ Utility_Sewer      : chr  "SEWER/SEPTIC INSTALLED" "SEWER/SEPTIC INSTALLED" "SEWER/SEPTIC INSTALLED" "SEWER/SEPTIC INSTALLED" ...
#  $ Improved_Vacant_Raw: int  1 1 1 1 1 1 0 1 1 0 ...
#  $ Year_Built_Raw     : int  1995 1983 1976 1968 2023 2006 2020 1920 1997 1980 ...
#  $ Price_Per_SqFt     : num  373.6 79.5 403.2 234.6 330.9 ...


quality_levels <- c("Low", "Low Plus", "Fair", "Fair Plus", "Average", "Average Plus", "Good", "Good Plus", "Very Good", "Very Good Plus", "Excellent"  )
condition_levels <- c("Uninhabitable", "Extra Poor", "Very Poor", "Poor", "Fair", "Average", "Good")
housing_data <- housing_data %>%
  mutate(
    Sale_Date_Raw = as.Date(Sale_Date_Raw),
    Quality = factor(Quality, levels = quality_levels),
    Condition = factor(Condition, levels = condition_levels),
    Neighborhood = factor(Neighborhood, ordered = FALSE),
    Street_Type = factor(Street_Type, ordered = FALSE),
    Utility_Water = factor(Utility_Water, ordered = FALSE),
    Utility_Electric = factor(Utility_Electric, ordered = FALSE),
    Utility_Sewer = factor(Utility_Sewer, ordered = FALSE),
    Improved_Vacant_Raw = as.logical(Improved_Vacant_Raw)
  ) %>%
  select(-Price_Per_SqFt)


ui <- fluidPage(
  titlePanel("Prediction of Housing Prices"),
  tabsetPanel(
    tabPanel(
      "Prediction",
      fluidRow(
        column(
          12,
          h1("Input Parameters")
        )
      ),
      fluidRow(
        column(
          3,
          numericInput("Square_Feet_Raw", "Square Feet",
            value = sample(housing_data$Square_Feet_Raw, 1),
            min = min(housing_data$Square_Feet_Raw, na.rm = TRUE),
            max = max(housing_data$Square_Feet_Raw, na.rm = TRUE)
          ),
          numericInput("Latitude_Raw", "Latitude",
            value = sample(housing_data$Latitude_Raw, 1),
            min = min(housing_data$Latitude_Raw, na.rm = TRUE),
            max = max(housing_data$Latitude_Raw, na.rm = TRUE)
          ),
          numericInput("Longitude_Raw", "Longitude",
            value = sample(housing_data$Longitude_Raw, 1),
            min = min(housing_data$Longitude_Raw, na.rm = TRUE),
            max = max(housing_data$Longitude_Raw, na.rm = TRUE)
          ),
          # numericInput("Price_Per_SqFt", "Price Per SqFt",
          #   value = sample(housing_data$Price_Per_SqFt, 1),
          #   min = min(housing_data$Price_Per_SqFt, na.rm = TRUE),
          #   max = max(housing_data$Price_Per_SqFt, na.rm = TRUE)
          # )
        ),
        column(
          3,
          numericInput("Bedrooms_Raw", "Bedrooms",
            value = sample(housing_data$Bedrooms_Raw, 1),
            min = min(housing_data$Bedrooms_Raw, na.rm = TRUE),
            max = max(housing_data$Bedrooms_Raw, na.rm = TRUE)
          ),
          numericInput("Bathrooms_Raw", "Bathrooms",
            value = sample(housing_data$Bathrooms_Raw, 1),
            min = min(housing_data$Bathrooms_Raw, na.rm = TRUE),
            max = max(housing_data$Bathrooms_Raw, na.rm = TRUE), step = 0.25
          ),
          numericInput("Stories_Raw", "Stories",
            value = sample(housing_data$Stories_Raw, 1),
            min = min(housing_data$Stories_Raw, na.rm = TRUE),
            max = max(housing_data$Stories_Raw, na.rm = TRUE), step = 0.5
          ),
          dateInput("Sale_Date_Raw", "Sale Date",
            min = min(as.Date(housing_data$Sale_Date_Raw), na.rm = TRUE),
            max = max(as.Date(housing_data$Sale_Date_Raw), na.rm = TRUE),
            value = sample(as.Date(housing_data$Sale_Date_Raw), 1)
          ),
          div(
            style = "display: flex; justify-content: center; align-items: center; height: 100px;",
            actionButton("go", "Predict", style = "font-size: 24px;")
          )
        ),
        column(
          3,
          selectInput("Quality", "Quality", choices = quality_levels),
          selectInput("Condition", "Condition", choices = condition_levels),
          selectInput("Neighborhood", "Neighborhood", choices = unique(housing_data$Neighborhood)),
          numericInput("Year_Built_Raw", "Year Built",
            value = sample(housing_data$Year_Built_Raw, 1),
            min = min(housing_data$Year_Built_Raw, na.rm = TRUE),
            max = max(housing_data$Year_Built_Raw, na.rm = TRUE)
          ),
        ),
        column(
          3,
          h1("Predicted House Price:"),
          h2(textOutput("prediction"))
        )
      ),
    ),
    tabPanel(
      "EDA",
      fluidRow(
        column(
          12,
          h3("First Rows of Data"),
          DT::dataTableOutput("head_table")
        )
      ),
      fluidRow(
        column(
          6,
          h4("Sale Price Distribution"),
          plotOutput("eda_hist")
        ),
        column(
          6,
          h4("Sale Price vs Square Feet"),
          plotOutput("eda_scatter")
        )
      ),
      fluidRow(
        column(
          6,
          h4("Sale Price by Quality"),
          plotOutput("eda_boxplot")
        ),
        column(
          6,
          h4("Sale Price by Condition"),
          plotOutput("eda_boxplot_condition")
        )
      ),
      fluidRow(
        column(
          6,
          h4("Bathrooms vs Sale Price"),
          plotOutput("eda_bathrooms_scatter")
        ),
        column(
          6,
          h4("Year Built vs Sale Price"),
          plotOutput("eda_yearbuilt_scatter")
        )
      ),
      fluidRow(
        column(
          12,
          h4("Sale Price by Neighborhood (Top 10)"),
          plotOutput("eda_neighborhood_boxplot")
        )
      )
    ),
  )
)

server <- function(input, output) {
  predict <- eventReactive(input$go, {
    value <- sample(housing_data$Sale_Price_Raw, 1)
    formatted <- formatC(value, format = "f", big.mark = ",", digits = 2)
    paste0(formatted, " $")
  })
  output$prediction <- renderText(predict())

  # Add a navigator to flip between the pages
  output$head_table <- DT::renderDataTable({
    DT::datatable(head(housing_data, 100), options = list(pageLength = 5, dom = "tp"))
  })

  output$eda_hist <- renderPlot({
    ggplot(housing_data, aes(x = Sale_Price_Raw)) +
      geom_histogram(bins = 50, fill = "skyblue", color = "black") +
      labs(x = "Sale Price", y = "Count", title = "Distribution of Sale Price")
  })

  output$eda_scatter <- renderPlot({
    ggplot(housing_data, aes(x = Square_Feet_Raw, y = Sale_Price_Raw)) +
      geom_point(alpha = 0.3, color = "darkblue") +
      scale_y_continuous(trans = "log10") +
      labs(x = "Square Feet", y = "Sale Price", title = "Sale Price vs Square Feet")
  })

  output$eda_boxplot <- renderPlot({
    ggplot(housing_data, aes(x = Quality, y = Sale_Price_Raw)) +
      geom_boxplot(fill = "orange", outlier.color = "red", outlier.size = 1) +
      labs(x = "Quality", y = "Sale Price", title = "Sale Price by Quality") +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
  })

  output$eda_boxplot_condition <- renderPlot({
    ggplot(housing_data, aes(x = Condition, y = Sale_Price_Raw)) +
      geom_boxplot(fill = "lightgreen", outlier.color = "red", outlier.size = 1) +
      labs(x = "Condition", y = "Sale Price", title = "Sale Price by Condition") +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
  })

  output$eda_bathrooms_scatter <- renderPlot({
    ggplot(housing_data, aes(x = Bathrooms_Raw, y = Sale_Price_Raw)) +
      geom_point(alpha = 0.3, color = "purple") +
      scale_y_continuous(trans = "log10") +
      labs(x = "Bathrooms", y = "Sale Price", title = "Bathrooms vs Sale Price")
  })

  output$eda_yearbuilt_scatter <- renderPlot({
    ggplot(housing_data, aes(x = Year_Built_Raw, y = Sale_Price_Raw)) +
      geom_point(alpha = 0.3, color = "darkred") +
      scale_y_continuous(trans = "log10") +
      labs(x = "Year Built", y = "Sale Price", title = "Year Built vs Sale Price")
  })

  output$eda_neighborhood_boxplot <- renderPlot({
    top_neigh <- housing_data %>%
      count(Neighborhood, sort = TRUE) %>%
      top_n(10, n) %>%
      pull(Neighborhood)
    ggplot(
      housing_data %>% filter(Neighborhood %in% top_neigh),
      aes(x = Neighborhood, y = Sale_Price_Raw)
    ) +
      geom_boxplot(fill = "lightblue", outlier.color = "red", outlier.size = 1) +
      scale_y_continuous(trans = "log10") +
      labs(x = "Neighborhood", y = "Sale Price", title = "Sale Price by Neighborhood (Top 10)") +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
  })
}


shinyApp(ui = ui, server = server)
