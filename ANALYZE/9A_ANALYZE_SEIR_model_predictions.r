
# Build SEIR model predictions

setwd("[YOUR DIRECTORY PATH HERE]")

library(covoid)
library(lubridate)
library(dplyr)

rm(list=ls())

dirpath_out <- "./data/Generated/Final/Results/"

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
# TIFR found 15.6 percent antibody positives
#1. Greater Mumbai slum population: 5,206,473 (Census 2011) or 42 percent of 
# total
# Total mumbai population: 12,442,373
#4. t=0 = March 25
#5. t=T = July 15
#6. T-0 = 113 days
#7. Seed on March 25: 500
#7. Ro = From optimization
#8. Ro = 0.5*ro_urban
#9. Population (Phase 2): 13,694,348
#10. Population (Phase 3): 76,808,204
#11. Migrants (Phase 2): 258,399
#12. Migrants (Phase 3): 333,884
#13. Population growth 2011-2020: Multiply by 1.09
#14. Population density of phase2 is higher so r0_phase2 = 0.5*r0_urban 
# and r0_phase3 = 1.379 (long run average for India from paper)

r0_urban = optimize(covid_lossfun,c(1,5),seed_urban=500,
                    calibrate_estimate=0.327*1.09*12.4*10^6,
                    predict_time=113,pop_urban=1.09*12.4*10^6)$minimum

#Use this r0 to simulate infections at different lockdown durations for phase2 and Phase 3

#First we do phase2

df_phase2=data.frame(urban_infections=rep(NA,150),
                     rural_infections=rep(NA,150),
                     lockdown_infections=rep(NA,150),
                     total_infections=rep(NA,150))

#Function takes fraction of departing population
# tot mumbai pop: 
fracdep=258399/(1.09*12.4*10^6)


for (i in 1:150)
{
  a=migrant_covid(seed_urban = 500, length_stay = i, 
                  fraction_depart = fracdep, predict_time = 189, 
                  pop_urban = 1.09*12.4*10^6, pop_rural = 1.09*13.7*10^6, 
                  r0_urban=r0_urban, r0_rural=0.5*r0_urban)
  df_phase2[i,]=a
}

df_phase2$date=as.Date(c(dmy("25-03-2020"):dmy("21-08-2020")),
                       origin="1970-01-01")
df_phase2$week = week(df_phase2$date)
#Estimated additional cases for phase2 = total cases for lockdown release on June 5 - total cases from release on May 8
# Row 73 - Day 44
df_phase2$rural_infections[73]-df_phase2$rural_infections[45]
df_phase2$phase2 <- 1

#Next we do Phase 3

df_phase3=data.frame(urban_infections=rep(NA,150),
                     rural_infections=rep(NA,150),
                     lockdown_infections=rep(NA,150),
                     total_infections=rep(NA,150))

#Function takes fraction of departing population
fracdep=333884/(1.09*12.4*10^6)

for (i in 1:150)
{
  a=migrant_covid(seed_urban = 500, length_stay = i, 
                  fraction_depart = fracdep, predict_time = 189, 
                  pop_urban = 1.09*12.4*10^6, pop_rural = 1.09*76.8*10^6, 
                  r0_urban=r0_urban, r0_rural=1.450)
  df_phase3[i,]=a
}

df_phase3$date=as.Date(c(dmy("25-03-2020"):dmy("21-08-2020")),
                       origin="1970-01-01")
df_phase3$week = week(df_phase3$date)

# Estimated additional cases for non phase2 = total cases for 
# lockdown release on Aug 19 - total cases from release on May 8
# Row 148 - Day 45
df_phase3$rural_infections[148]-df_phase3$rural_infections[45]
df_phase3$phase2 <- 0

df_phase2_phase3 <- rbind(df_phase2, df_phase3) %>%
  select(rural_infections, date, phase2)
  
write.csv(df_phase2_phase3, paste0(dirpath_out, "sier_travel_phases.csv"))

