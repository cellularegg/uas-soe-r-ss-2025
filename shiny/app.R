library(shiny)
library(ggplot2)
library(dplyr)
library(DT) # For data tables
library(h2o) # For machine learning model
library(rlang) # For .data pronoun in dplyr
housing_data <- read.csv("../data/final_data_incl_land_area.csv")

# Initialize h2o
h2o.init(nthreads = -1, max_mem_size = "4G")

# Load the saved model
model_path <- "../models/saved-models/final-run/StackedEnsemble_AllModels_1_AutoML_1_20250623_200154"
model <- h2o.loadModel(model_path)

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
            max = max(housing_data$Latitude_Raw, na.rm = TRUE),
            step = 0.001
          ),
          numericInput("Longitude_Raw", "Longitude",
            value = sample(housing_data$Longitude_Raw, 1),
            min = min(housing_data$Longitude_Raw, na.rm = TRUE),
            max = max(housing_data$Longitude_Raw, na.rm = TRUE),
            step = 0.001
          ),
          numericInput("Net_Land_Square_Feet_Raw", "Land Square Feet",
            value = sample(housing_data$Net_Land_Square_Feet_Raw, 1),
            min = min(housing_data$Net_Land_Square_Feet_Raw, na.rm = TRUE),
            max = max(housing_data$Net_Land_Square_Feet_Raw, na.rm = TRUE)
          ),
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

        ),
        column(
          3,
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
          selectInput("Neighborhood", "Neighborhood", choices = unique(housing_data$Neighborhood)),
          numericInput("Year_Built_Raw", "Year Built",
            value = sample(housing_data$Year_Built_Raw, 1),
            min = min(housing_data$Year_Built_Raw, na.rm = TRUE),
            max = max(housing_data$Year_Built_Raw, na.rm = TRUE)
          ),
          selectInput("Quality", "Quality", choices = quality_levels),

          div(
            style = "display: flex; justify-content: center; align-items: center; height: 100px;",
            actionButton("go", "Predict", style = "font-size: 24px;")
          )
        ),
        column(
          3,
          selectInput("Condition", "Condition", choices = condition_levels),
          selectInput("Street_Type", "Street Type", choices = unique(housing_data$Street_Type)),
          selectInput("Utility_Water", "Utility Water", choices = unique(housing_data$Utility_Water)),
          selectInput("Utility_Electric", "Utility Electric", choices = unique(housing_data$Utility_Electric)),
          selectInput("Utility_Sewer", "Utility Sewer", choices = unique(housing_data$Utility_Sewer)),
          checkboxInput("Improved_Vacant_Raw", "Improved (vs Vacant)", value = sample(housing_data$Improved_Vacant_Raw, 1))
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
    # Create a dataframe with the input values
    input_data <- data.frame(
      Sale_Date_Raw = input$Sale_Date_Raw,
      Square_Feet_Raw = input$Square_Feet_Raw,
      Latitude_Raw = input$Latitude_Raw,
      Longitude_Raw = input$Longitude_Raw,
      Bedrooms_Raw = input$Bedrooms_Raw,
      Bathrooms_Raw = input$Bathrooms_Raw,
      Stories_Raw = input$Stories_Raw,
      Quality = input$Quality,
      Condition = input$Condition,
      Neighborhood = input$Neighborhood,
      Street_Type = input$Street_Type,
      Utility_Water = input$Utility_Water,
      Utility_Electric = input$Utility_Electric,
      Utility_Sewer = input$Utility_Sewer,
      Improved_Vacant_Raw = input$Improved_Vacant_Raw,
      Year_Built_Raw = input$Year_Built_Raw,
      Net_Land_Square_Feet_Raw = input$Net_Land_Square_Feet_Raw
    )
    
    # Convert the dataframe to H2O format
    input_h2o <- as.h2o(input_data)
    
    # Make a prediction using the model
    prediction <- h2o.predict(model, input_h2o)
    
    # Extract the predicted value
    value <- as.numeric(prediction[1, 1])
    
    # Format the value
    formatted <- formatC(value, format = "f", big.mark = ",", digits = 2)
    paste0(formatted, " $")
  })
  output$prediction <- renderText(predict())

  # Add a navigator to flip between the pages
  output$head_table <- DT::renderDataTable({
    DT::datatable(head(housing_data, 100), options = list(pageLength = 5, dom = "tp"))
  })

  output$eda_hist <- renderPlot({
    ggplot(housing_data, aes(x = .data$Sale_Price_Raw)) +
      geom_histogram(bins = 50, fill = "skyblue", color = "black") +
      labs(x = "Sale Price", y = "Count", title = "Distribution of Sale Price")
  })

  output$eda_scatter <- renderPlot({
    ggplot(housing_data, aes(x = .data$Square_Feet_Raw, y = .data$Sale_Price_Raw)) +
      geom_point(alpha = 0.3, color = "darkblue") +
      scale_y_continuous(trans = "log10") +
      labs(x = "Square Feet", y = "Sale Price", title = "Sale Price vs Square Feet")
  })

  output$eda_boxplot <- renderPlot({
    ggplot(housing_data, aes(x = .data$Quality, y = .data$Sale_Price_Raw)) +
      geom_boxplot(fill = "orange", outlier.color = "red", outlier.size = 1) +
      labs(x = "Quality", y = "Sale Price", title = "Sale Price by Quality") +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
  })

  output$eda_boxplot_condition <- renderPlot({
    ggplot(housing_data, aes(x = .data$Condition, y = .data$Sale_Price_Raw)) +
      geom_boxplot(fill = "lightgreen", outlier.color = "red", outlier.size = 1) +
      labs(x = "Condition", y = "Sale Price", title = "Sale Price by Condition") +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
  })

  output$eda_bathrooms_scatter <- renderPlot({
    ggplot(housing_data, aes(x = .data$Bathrooms_Raw, y = .data$Sale_Price_Raw)) +
      geom_point(alpha = 0.3, color = "purple") +
      scale_y_continuous(trans = "log10") +
      labs(x = "Bathrooms", y = "Sale Price", title = "Bathrooms vs Sale Price")
  })

  output$eda_yearbuilt_scatter <- renderPlot({
    ggplot(housing_data, aes(x = .data$Year_Built_Raw, y = .data$Sale_Price_Raw)) +
      geom_point(alpha = 0.3, color = "darkred") +
      scale_y_continuous(trans = "log10") +
      labs(x = "Year Built", y = "Sale Price", title = "Year Built vs Sale Price")
  })

  output$eda_neighborhood_boxplot <- renderPlot({
    top_neigh <- housing_data %>%
      count(.data$Neighborhood, sort = TRUE) %>%
      top_n(10, n) %>%
      pull(.data$Neighborhood)
    ggplot(
      housing_data %>% filter(.data$Neighborhood %in% top_neigh),
      aes(x = .data$Neighborhood, y = .data$Sale_Price_Raw)
    ) +
      geom_boxplot(fill = "lightblue", outlier.color = "red", outlier.size = 1) +
      scale_y_continuous(trans = "log10") +
      labs(x = "Neighborhood", y = "Sale Price", title = "Sale Price by Neighborhood (Top 10)") +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
  })
}

# Make sure to shut down h2o when the app is closed
onStop(function() {
  h2o.shutdown(prompt = FALSE)
})

shinyApp(ui = ui, server = server)
