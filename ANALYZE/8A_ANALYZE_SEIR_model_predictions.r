
# Get SEIR model predictions
setwd("[YOUR DIRECTORY PATH HERE]")

library(covoid)
library(lubridate)
library(dplyr)

rm(list=ls())

dirpath_data <- "./data"
dirpath_gen <- paste0(dirpath_data, "/generated")
dirpath_final <- paste0(dirpath_gen, "/final")
dirpath_final_results <- paste0(dirpath_final, "/results")

migrant_covid <- function(seed_urban,length_stay,fraction_depart,predict_time,
                          pop_urban,pop_rural,r0_urban,r0_rural)
{
  # import contact matrix and age distribution
  cm_oz <- import_contact_matrix("India","general")
  p_age_oz <- import_age_distribution("India")
  
  #Initial Conditions urban
  N<- seed_urban
  S <- p_age_oz*pop_urban
  E <- c(0,0,0,0,rep(N/12,12))
  I <- rep(0,length(S))
  R <- rep(0,length(S))
  
  param <- seir_c_param(R0 = r0_urban,gamma = (1/10),sigma=(1/10),
                        cm=cm_oz,dist=p_age_oz)
  state0 <- seir_c_state0(S = S,E = E,I = I,R = R)
  res <- simulate_seir_c(t = predict_time,state_t0 = state0,param = param)
  
  covid = res$epi$E + res$epi$I +res$epi$R
  ever_infected_urban=tail(covid,1)
  lockdown_infected_urban=covid[length_stay]
  
  #Initial Conditions rural
  Ne <- fraction_depart*res$epi$E[length_stay]
  Ni <- fraction_depart*res$epi$I[length_stay]
  
  S <- p_age_oz*pop_rural
  E <- c(0,0,0,0,rep(Ne/12,12))
  I <- c(0,0,0,0,rep(Ni/12,12))
  R <- rep(0,length(S))
  
  #Rural active infection time
  rural_predict_time=predict_time-length_stay
  
  param <- seir_c_param(R0 = r0_rural,gamma = (1/10),sigma=(1/10),
                        cm=cm_oz,dist=p_age_oz)
  state0 <- seir_c_state0(S = S,E = E,I = I,R = R)
  res <- simulate_seir_c(t = rural_predict_time,state_t0 = state0,param = param)
  
  covid = res$epi$E + res$epi$I +res$epi$R
  ever_infected_rural=tail(covid,1)
  
  answer=c(urban_infections=ever_infected_urban,
           rural_infections=ever_infected_rural,
           lockdown_infections=lockdown_infected_urban,
           total_infections=ever_infected_urban+ever_infected_rural)
  answer
}

covid_lossfun <- function(r0,seed_urban,calibrate_estimate,predict_time,pop_urban)
{
  # import contact matrix and age distribution
  cm_oz <- import_contact_matrix("India","general")
  p_age_oz <- import_age_distribution("India")
  
  #Initial Conditions urban
  N<- seed_urban
  S <- p_age_oz*pop_urban
  E <- c(0,0,0,0,rep(N/12,12))
  I <- rep(0,length(S))
  R <- rep(0,length(S))
  
  param <- seir_c_param(R0 = r0,gamma = 1/10,sigma=1/10,cm=cm_oz,dist=p_age_oz)
  state0 <- seir_c_state0(S = S,E = E,I = I,R = R)
  res <- simulate_seir_c(t = predict_time,state_t0 = state0,param = param)
  
  covid = res$epi$E + res$epi$I +res$epi$R
  ever_infected_urban=tail(covid,1)
  loss=(ever_infected_urban-calibrate_estimate)^2
  loss
  
}

#Calibrate model to identify the seed level of infections that would have 
# been present on March 25 to create the July 15 estimate of total infections 
# from TIFR report
#1. TIFR found 15.6 percent antibody positives
#2. t=0 = March 25
#3. t=T = July 15
#4. T-0 = 113 days
#5. Seed on March 25: 500
#6. Ro source = From optimization
#7. Ro sink = 0.5*ro_source
#8. Population source: 13702964
#9. Population sink: 16642462
#10. Migrants: 50229

population_urban = 13702964
r0_urban = optimize(covid_lossfun,c(1,5),seed_urban=500,
                    calibrate_estimate=0.327*population_urban,
                    predict_time=112,pop_urban=population_urban)$minimum

df_phase2=data.frame(urban_infections=rep(NA,150),
                     rural_infections=rep(NA,150),
                     lockdown_infections=rep(NA,150),
                     total_infections=rep(NA,150))

# Function takes fraction of departing population
# tot mumbai pop: 
population_rural = 16642462
migrants = 50229
fracdep = migrants / population_urban

for (i in 1:150)
{
  a=migrant_covid(seed_urban = 500, length_stay = i, 
                  fraction_depart = fracdep, predict_time = 189, 
                  pop_urban = population_urban, pop_rural = population_rural, 
                  r0_urban=r0_urban, r0_rural=0.5*r0_urban)
  df_phase2[i,]=a
}


df_phase2$date=as.Date(c(dmy("25-03-2020"):dmy("21-08-2020")),
                       origin="1970-01-01")
df_phase2$week = week(df_phase2$date)

write.csv(df_phase2, paste0(dirpath_final_results, "/RESULTS_seir_model_predictions.csv"))

