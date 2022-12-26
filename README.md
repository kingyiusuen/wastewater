# Wastewater Surveillance of SARS-CoV-2 for Predicting COVID-19 Cases in Minnesota

This is the repository for the code I used in my Plan B project for the degree of Master in Statistics at the University of Minnesota. The report was written in RMarkdown to ensure the reproducibility of the results. Here is the [PDF version of the report]().

## Introduction 

Previous studies have found that as many as 45% of COVID-19 infections are asymptomatic. As a result, the number of confirmed clinical cases may underestimate the prevalence of the disease, as people are unlikely to seek medical attention when they do not have any symptoms. Moreover, symptoms may take 2 weeks to show up after infection. Hence, test results are a lagging indicator of the pandemic's progression. On the other hand, SARS-CoV-2 viral particles can be found in feces from infected individuals even if they are asymptomatic. Therefore, SARS-CoV-2 RNA concentrations in wastewater can potentially predict COVID-19 prevalence even earlier than clinical case data. The aim of this project is to evaluate the use of wastewater-based epidemiology as an early warning system to identify disease hotspots.

## Data

The variables available in the dataset are:

- Concentrations of three SARS-CoV-2 target genes: nucleocapsid (N), spike (S) and ORF1ab (O) proteins
- Concentrations of a human fecal marker, Pepper Mild Mottle Virus (PMMoV)
- Flow (volume of wastewater that passed through the WWTP in the sampling day)
- Number of people who have received at least one dose of COVID-19 vaccine
- Number of fully vaccinated people
- Size of the population served by the WWTP

The SARS-CoV-2 RNA was measured in 40 wastewater treatment plants (WWTPs) of varying sizes and served populations across the state of Minnesota from March to October 2022. The case counts and the number of vaccinated individuals were obtained from the Minnesota Department of Health. I do not have the authorization to share the data publicly. 

## Analysis

All data were aggregated to weekly level for the purpose of this analysis. Various linear regression models were fitted to answer the following questions:

1. What is the best way to incorporate SARS-CoV-2 concentrations into the model? More specifically,    
    a. How should the virus concentrations be normalized (by flow, PMMoV or both)?    
    b. Which SARS-CoV-2 gene should be used (N, S, O)?    
    c. Does including lagged virus concentrations in the model improve the predictive performance?    
    d. Does a $\log_{10}$ transformation of the variables improve the predictive performance? 
2. Is it possible to develop one model for all WWTPs or is it necessary to develop one
model for each WWTP?
3. Is the vaccination rate a useful predictor?
4. Is the lagged case count a more useful predictor than virus concentrations?
5. How will the predictive performance be affected if the forecast horizon is increased (same week, one week in advance, two weeks in advance)?

The model performance was evaluated with leave-one-out cross validation. The evaluation metric was RMSE.

## Results

The results can be summarized as follows:

- Normalizing by flow seemed to provide the best predictive performance.
- Either N or O could be used, as they were highly correlated.
- Including lagged virus concentrations tended to worsen the predictive performance.
- $\log_{10}$ transformation slightly decreased the prediction errors.
- The relationship between COVID-19 incidence and SARS-CoV-2 RNA in wastewater may be treatment plant-specific.
- Including the vaccination rate in the model may be helpful but the results are not very robust over different forecast horizons.
- The case count of the previous week alone could provide similar predictive performance as SARS-CoV-2 RNA concentrations.

