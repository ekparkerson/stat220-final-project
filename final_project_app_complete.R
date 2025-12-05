# Load packages ----------------------------------------------------------------
library(tidyverse)
library(ggplot2)
library(ggthemes)
library(maps)
library(mapproj)
library(sf)
library(lubridate)
library(patchwork)
library(covidcast)
library(datasets)
library(stringr)
library(tibble)
library(scales)
library(plotly)
library(htmlwidgets)
library(RColorBrewer)
library(shinythemes)
library(epidatr)

# Load data
covid_demog <- read_rds("data/covid_demog.rds")
covid_juris <- read_rds("data/covid_juris.rds")
covidcast_google_symptoms <- read_rds("data/covidcast_google_symptoms.rds")
hex_geo <- read_rds("data/hex_geo.rds")

  # Set up a function for making honeycomb map based on time frame

make_map <- function(TIMEFRAME){
  covid_juris_filtered  <- covid_juris |>
    filter(Group == TIMEFRAME, !str_detect(Jurisdiction_Residence, "Region"))
  
  hex_geo_covid <- hex_geo |>
    left_join(covid_juris_filtered, by = c("google_name" = "Jurisdiction_Residence"))
  
  p <- hex_geo_covid |>
    group_by(iso3166_2, google_name) |>
    summarize(mean_aa_COVID_rate_ann = mean(aa_COVID_rate_ann, na.rm = TRUE)) |>
    ggplot() + 
    geom_sf(aes(fill = mean_aa_COVID_rate_ann, text = google_name), color = "white") +
    geom_sf_text(aes(label = iso3166_2)) +
    scale_fill_distiller(palette = "Blues", direction = 1) +
    theme_void() +
    labs(fill = "Average age-adjusted annualized\nCOVID death rate per 100k population") +
    coord_sf(crs = st_crs(3857))
  
  return(p)
}
  

  # Set up a function for making time series plots
make_plot <- function(STATE, TIME){
  state_google <- covidcast_google_symptoms |>
    filter(geo_value == STATE)
  
  state_covid_juris <- covid_juris |>
    mutate(data_period_start = mdy(data_period_start),
           data_period_end = mdy(data_period_end)) |>
    filter(abbreviation == STATE,
           Group == TIME,
           year(data_period_end) <= 2025) |>
    mutate(aa_COVID_rate_ann_scaled = rescale(aa_COVID_rate_ann, to = range(state_google$value, na.rm = TRUE)))
  
  output_plot <- ggplot() +
    geom_freqpoly(data = state_google, aes(x = time_value, y = value, color = "Google searches"), stat = "identity") +
    geom_freqpoly(data = state_covid_juris, aes(x = data_period_end, y = aa_COVID_rate_ann_scaled, color = "COVID death rate"), stat = "identity") +
    scale_y_continuous(name = "Average relative frequency of Google\n searches for COVID symptoms",
                       sec.axis = sec_axis(~ rescale(., from = range(state_google$value, na.rm = TRUE), to = range(state_covid_juris$aa_COVID_rate_ann, na.rm = TRUE)), name = "Age-adjusted annualized COVID\ndeath rate (per 100k)")) +
    scale_color_manual(values = c("COVID death rate" = "red", "Google searches" = "blue")) +
    labs(x = "", color = "") +
    theme_minimal(base_size = 14) +
    theme(legend.position = "bottom")
  
  output_plot
}

  # Set up a function for making stacked bar charts 
make_chart <- function(STATE){
  output_chart <- covid_demog |>   
    filter(abbreviation == STATE, AgeGroup == "All ages, standardized") |>   
    select("State", "abbreviation", "Race/Hispanic origin", 
           "Distribution of COVID-19 deaths (%)", "Weighted distribution of population (%)") |>   
    pivot_longer(cols = c("Distribution of COVID-19 deaths (%)", "Weighted distribution of population (%)"), 
                 values_to = "metric_value", names_to = "metric") |>   
    mutate(metric = factor(metric, levels = c("Weighted distribution of population (%)", "Distribution of COVID-19 deaths (%)"))) |>   
    group_by(State, metric) |>   
    ggplot(aes(x = metric, y = metric_value, fill = `Race/Hispanic origin`, text = paste(`Race/Hispanic origin`, ": ", metric_value, "%"))) +   
    geom_bar(stat = "identity", position = "fill", width = 0.6) + 
    scale_y_continuous(labels = label_percent()) +
    labs(x = "", y = "Percentage of Population") +  
    theme(
      legend.position = "right",  # Keep legend on the side
      legend.direction = "vertical",  # Keep stacked vertically
      legend.justification = c(0.5, 1),  # Move legend slightly higher
      legend.margin = margin(-20, 0, 0, 0),  # Adjust vertical spacing
      axis.text.y = element_text(size = 12)  # Keep y-axis text readable
    ) +
    scale_fill_brewer(palette = "Set3") +
    theme_minimal()
  
  return(ggplotly(output_chart, tooltip = "text"))
}


plottype <- c("COVID death rates over time", "COVID death rates across races")

# Define UI --------------------------------------------------------------------

ui <- fluidPage(
  theme = shinytheme("united"),
  titlePanel(title = "Exploring COVID-19 death rates in the United States"),
  sidebarLayout(
    
    sidebarPanel(
      radioButtons(
      inputId = "plot_type",
      label = "Select one of the following:",
      choices = plottype,
      selected = plottype[1]
      ),
      selectInput(
      inputId = "timeframe",
      label = "Select a time frame for data displayed: ",
      choices = unique(covid_juris$Group)[-3],
      selected = "weekly"
      )
    ),
  
    mainPanel(
      hr(),
      "Hover over any state and check out the COVID death rate data visualization for it!",
      plotlyOutput(outputId = "honeycomb"),
      textOutput(outputId = "selected_state"),
      hr(),
      uiOutput("dynamic_plot")
    )
  )
)

# Define server function -------------------------------------------------------

server <- function(input, output, session){
  selected_timeframe <- reactive({req(input$timeframe)
    input$timeframe})
  
  output$honeycomb <- renderPlotly(
    ggplotly(make_map(selected_timeframe()), tooltip = "text") |>
      layout(xaxis = list(visible = FALSE),
             yaxis = list(visible = FALSE)) |>
      event_register("plotly_hover") |>
      onRender("
    function(el, x) {
      el.on('plotly_hover', function(d) {
        var state = d.points[0].text;
        Shiny.setInputValue('hovered_state', state, {priority: 'event'});
      });
    }
  ")
  )
  
  state_full_name <- reactive({req(input$hovered_state)
                               input$hovered_state})
  
  observe({
    print(paste("Hovered state:", input$hovered_state))
    print(paste("Extracted state name:", state_full_name()))
  })
  
  output$selected_state <- reactive({
    str_c("You have selected: ", state_full_name())
  })
  
  observeEvent(input$plot_type, {
    req(input$plot_type)
    
    output$dynamic_plot <- renderUI({
      req(state_full_name())
      
      if (input$plot_type == plottype[1]) {
        tagList(
          p("Do you see any relationships between COVID deaths rates and Google searches for COVID-related symptoms? How do they each vary over time?"),
          plotOutput("time_series", width = "900px", height = "450px")
        )
      } else {
        tagList(
        p("Based on the state's population distribution, do we observe more or fewer COVID deaths than we expect for each racial/ethnic group? \n Note: Data displayed for distribution of COVID-19 deaths (%) is cumulative as of September 23, 2023."),
        plotlyOutput("stacked_bar")
        )
      }
    })
    
    if (input$plot_type == plottype[1]) {
      output$time_series <- renderPlot({
      req(state_full_name())
      make_plot(state_full_name(), selected_timeframe())
    }) 
      output$stacked_bar <- renderPlotly(NULL)
    } else {
      output$stacked_bar <- renderPlotly({
      req(state_full_name())
      make_chart(state_full_name())
  })
      output$time_series <- renderPlot(NULL)
  }})
}


# Create the Shiny app object --------------------------------------------------

shinyApp(ui = ui, server = server)
