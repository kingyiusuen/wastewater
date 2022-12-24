library(dplyr)
library(readr)
library(stringr)
library(ISOweek)
library(scales)


process_date <- function(df) {
  # Change SampleDate to the first day of the week that SampleDate is in
  # If two samples are collected in the same week, they will have the same SampleDate

  # Convert SampleDate from character to Date object
  if (is.character(df$SampleDate)) {
    df <- df %>% mutate(SampleDate = as.Date(SampleDate, "%m/%d/%Y"))
  }
  
  df <- df %>%
    # Get the year and the week number based on the SampleDate
    # Following the format of the case count data, the first day of the week is Sunday
    # Add one because the first day of the week is Monday in R
    mutate(Year = format(SampleDate + 1, "%Y"), Week = format(SampleDate + 1, "%V")) %>%
    # Calculate the date of the first day of a given week in a given year
    mutate(SampleDate = ISOweek2date(paste(Year, paste0("W", str_pad(Week, 2, pad = "0")), "1", sep = "-"))) %>%
    # Subtract one so that the first day of the week is Sunday
    mutate(SampleDate = SampleDate - 1, Year = NULL, Week = NULL)
  return(df)
}


load_data <- function(root_dir) {
  wastewater_data <- read_csv(paste0(root_dir, "/data/data_wastewater/WWTP_NewTargets_withPMMoV.csv")) %>%
    rename(O = ORFlab_Copies.L, S = S_Copies.L, N = N_Copies.L, PMMoV = PMMoV_Copies.L) %>%
    process_date() %>%
    select(Code, SampleDate, O, S, N, PMMoV) %>%
    group_by(Code, SampleDate) %>%
    summarize(
      O = mean(O, na.rm = TRUE),
      S = mean(S, na.rm = TRUE),
      N = mean(N, na.rm = TRUE), 
      PMMoV = mean(PMMoV, na.rm = TRUE)
    ) %>%
    # Replace NaNs with NAs
    mutate(PMMoV = ifelse(is.nan(PMMoV), NA, PMMoV))

  cases_data <- read_csv(paste0(root_dir, "/data/data_cases/cases-wwtp_2022-11-04.csv")) %>%
    rename(CaseCount = Case) %>%
    process_date() %>%
    select(Code, SampleDate, CaseCount, PopulationSize)
  
  flow_data <- read_csv(paste0(root_dir, "/data/data_flow/Flow_2022-10-31_edited.csv")) %>%
    process_date() %>%
    select(Code, SampleDate, Flow) %>%
    group_by(Code, SampleDate) %>%
    summarize(Flow = mean(Flow, na.rm = TRUE))
  
  vax_data <- read_csv(paste0(root_dir, "/data/data_vaccines/vaxbyweek_111022.csv")) %>%
    rename(OneVaxCount = PPL_One, FullVaxCount = PPL_Full) %>%
    process_date() %>%
    select(Code, SampleDate, OneVaxCount, FullVaxCount)

  wwtp_code_to_name_mapping <- read_csv(paste0(root_dir, "/data/county-sewer-zip-map/sewershed_cty.csv")) %>%
    rename(Code = wwtp_key) %>%
    select(WWTP, Code)
  
  merged_data <- wastewater_data %>%
    inner_join(cases_data, c("Code", "SampleDate")) %>%
    inner_join(flow_data, c("Code", "SampleDate")) %>%
    inner_join(vax_data, c("Code", "SampleDate")) %>%
    left_join(wwtp_code_to_name_mapping, "Code")
  return(merged_data)
}


process_data <- function(df, divide_by_population = TRUE) {
  quantiles <- quantile(df$PMMoV, probs = c(0.05, 0.95), na.rm = TRUE)
  df <- df %>% 
    mutate(
      # If PMMoV is below the 5th percentile, replace it the 5th percentile value
      # If PMMoV is above the 95th percentile, replace it the 95th percentile value
      PMMoV = squish(PMMoV, quantiles),
      # Replace 0 with 1; otherwise can't do log transform
      CaseCount = ifelse(CaseCount == 0, 1, CaseCount),
    )

  if (divide_by_population) {
    df <- df %>% mutate(
      N = N / PopulationSize,
      O = O / PopulationSize,
      S = S / PopulationSize,
      CaseCount = CaseCount / PopulationSize,
      OneVaxCount = OneVaxCount / PopulationSize,
      FullVaxCount = FullVaxCount / PopulationSize
    )
  }

  df <- df %>% 
    group_by(Code) %>%
    mutate(
      CaseCount_Lag1 = lag(CaseCount, 1),
      CaseCount_Lag2 = lag(CaseCount, 2),
      CaseCount_Lead1 = lead(CaseCount, 1),
      CaseCount_Lead2 = lead(CaseCount, 2),
      O_Lag1 = lag(O, 1),
      O_Lag2 = lag(O, 2),
      N_Lag1 = lag(N, 1),
      N_Lag2 = lag(N, 2),
      PMMoV_Lag1 = lag(PMMoV, 1),
      PMMoV_Lag2 = lag(PMMoV, 2),
      Flow_Lag1 = lag(Flow, 1),
      Flow_Lag2 = lag(Flow, 2)
    ) %>%
    filter(O > 0 & O_Lag1 > 0 & O_Lag2 > 0 & N > 0 & N_Lag1 > 0 & N_Lag2 > 0) %>%
    drop_na()
  
  return(df)
}
