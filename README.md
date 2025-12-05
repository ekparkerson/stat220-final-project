# **Exploring COVID-19 death rates in the United States**

## Link to Published Shiny App

<https://vivianyxdu.shinyapps.io/final-blobfish/>

## Technical Overview

For this project, we are interested in the following questions:

-   **How do rates of COVID deaths vary across different states?**

-   **How do Google searches for COVID symptoms such as cough and phlegm vary over time in each state? How do the Google search trends correspond with COVID deaths?**

-   **How does the racial/ethnic makeup of each state inform COVID deaths?**

We obtained our data from two sources: 1) the National Center for Health Statistics (NCHS) under the Center for Disease Control and Prevention and 2) the “covidcast” endpoint of the Carnegie Mellon University Delphi research group’s epidemiological data API (source name: `google-symptoms`). The NCHS `covid-juris` data spanned from January 2020 to March 2025, while `covid-demog` only contained data as of September 2023. For data related to COVID symptoms, we only focused on fever, hyperthermia, chills, shivering, and low grade fever. In order to visualize the spatial data, we combined each of the three data sets with a separate tibble called `states_tbl` which had all the state names and their corresponding abbreviations. On the time series plots, the average relative frequncy values of Google searches for COVID symptoms are in arbitrary units normalized against overall search patterns within each region. The age-adjusted, annualized COVID death rate is an indexrather than a direct or actual measure of relative mortality risks across all age groups per 100,000 population that would be expected in a year if the observed period (weekly) rate prevailed for a full year. Statistically, the rate is a weighted average of age-specific death rates, where the weights represent the fixed population proportions by age.

The honeycomb map turned out trickier to create than we had expected. We referenced code from [Hexbin map in R: an example with US states](https://r-graph-gallery.com/328-hexbin-map-of-the-usa.html) and used [this .json file](https://team.carto.com/u/andrew/tables/andrew.us_states_hexgrid/public/map) to plot the hexagons.

For the Shiny app, we separate functions to generate the honeycomb map, the time series plot, and the stacked bar charts. Unfortunately, we failed to make the time series plots interactive, because ggplotly was incompatible with the rescaling code we used to label the second y-axis on the static version (see Line 62, 68 in `final_project_app_complete.R`). However, the tooltips on the stacked bar charts work perfectly well.

Last but not least, we would like to acknowledge ChatGPT for providing us with the JavaScript code to realize the hovering effect on our honeycomb map (see Line 152-158 in `final_project_app_complete.R`).

## How to Navigate the Repo

Our completed app is stored in the `final_project_app_complete.R` file. This code uses the .rds files that are stored in the `data` directory. The `load_data.R` script takes the csv files stored in `data` and does all of the data cleaning and wrangling for this project, before storing the results as the set of .rds files in `data`. The data that we used for the hexbin map comes from the `us_states_hexgrid.geojson` file in `data`. Our report is in this README!

## Completed Rubric

### Successful

#### All boxes should be checked

-   [x] Acquire data from at least 2 sources
-   [x] Consider the who, what, when, why, and how of your datasets
-   [x] Work with a type of data that was not accessible to you as a Stat120, 230, or 250 student (text, spatial, network, date, etc)
-   [x] Demonstrate proficiency with joining data
-   [x] Demonstrate proficiency with tidying data
-   [x] Demonstrate proficiency using non-numeric data types (text, spatial, date time, factor)
-   [x] Create high-quality, customized graphics using R or ggplot
-   [x] Graphs contain interactive components (plotly, leaflet, etc)
-   [x] Product is published online as an rpubs or shinyapps website and is pitched towards a public audience
-   [x] Product meets high submission quality standards:
    -   [x] No grammatical mistakes, spelling mistakes, or typos
    -   [x] All graphs are readable with appropriate labels and titles
    -   [x] Rendered document does not contain any unnecessary content (package loading messages, warnings, etc.)
    -   [x] Graphs have been customized and are appropriate and readable with the theme of the document
-   [x] All group members have a commit history on github
-   [x] Code is well-documented and clean
-   [x] Project repo is organized
-   [x] README contains a link to your published project, a technical summary of what you did, and a self-evaluation using this rubric

### Excellent

#### Must be checked

-   [x] Meets very high submission quality standards: Final product is polished, professional, and customized

#### Two of three must be checked

-   [x] Acquire data using one of the advanced techniques discussed in class (scraping, API, database, iterating over files in a folder, etc.)
-   [ ] Significant portion of the project uses non-numeric data types (e.g. maps that use lat/long location; text analysis; etc) **OR** Project relied on a significant amount of joining or combining data
-   [x] Product is an interactive shiny app
