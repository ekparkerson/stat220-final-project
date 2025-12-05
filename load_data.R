# Load data --------------------------------------------------------------------
covid_demog <- read_csv("data/covid_demog.csv")
covid_juris <- read_csv("data/covid_juris.csv")

covidcast_api_key <- Sys.getenv("DELPHI_EPIDATA_KEY")
covidcast_google_symptoms <- covidcast_signal(
  data_source = "google-symptoms", signal = "s01_smoothed_search",
  start_day = "2020-01-26", end_day = "2025-03-01",
  geo_type = "state"
)

# Data wrangling --------------------------------------------------------------------  
states_tbl <- tibble(state = state.name, abbreviation = state.abb)
states_tbl <- add_row(states_tbl, 
                      state = c("District of Columbia", "Puerto Rico", "New York City", "United States", "New York and New York City"), 
                      abbreviation = c("DC", "PR", "NYC", "US", "NY"))

covid_demog <- covid_demog |> 
  left_join(states_tbl, by = c("State" = "state"))

covid_juris <- covid_juris |>
  filter(!Jurisdiction_Residence %in% c("New York City", "New York", "United States")) |>
  inner_join(states_tbl, by = c("Jurisdiction_Residence" = "state")) |>
  mutate(Jurisdiction_Residence = str_replace(Jurisdiction_Residence, "New York and New York City", "New York"))

covid_juris_weekly <- covid_juris |>
  filter(Group == "weekly", !str_detect(Jurisdiction_Residence, "Region"))

covidcast_deaths_prop <- covidcast_deaths_prop |>
  mutate(geo_value = str_to_upper(geo_value))

covidcast_google_symptoms <- covidcast_google_symptoms |>
  mutate(geo_value = str_to_upper(geo_value)) |>
  left_join(states_tbl, by = c("geo_value" = "abbreviation"))

# Hexbin data ------------------------------------------------------------------

hex_geo <- read_sf("data/us_states_hexgrid.geojson") |>
  mutate(google_name = gsub(" \\(United States\\)", "", google_name))

# Save data --------------------------------------------------------------------

write_rds(covid_demog, file = "data/covid_demog.rds")
write_rds(covid_juris, file = "data/covid_juris.rds")
write_rds(covidcast_google_symptoms, file = "data/covidcast_google_symptoms.rds")
write_rds(hex_geo, file = "data/hex_geo.rds")
