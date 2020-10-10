# Get remittance flows from Mumbai

setwd("[YOUR DIRECTORY PATH HERE]")

rm(list = ls())

library(tidyverse)
library(haven)

dirpath <- "./data/generated/intermediate/remittances/"
df <- read_csv(paste0(dirpath, "remittances_send_rec_locations.csv"))

##
# Number unique retailers in Mumbai
df %>% 
  filter(dtname_send == "MUMBAI") %>%
  distinct(retailerid) %>%
  nrow()

# Number of unique depositors in Mumbai
df %>%
  filter(dtname_send == "MUMBAI") %>%
  distinct(depositorid) %>%
  nrow()
##
# Number of geocoded unique depositors in Mumbai with transfers okay to use
df %>%
  filter(dtname_send == "MUMBAI") %>%
  filter(transfer_ok_to_use == 1,
         is_geocoded_send_rec == 1) %>%
  distinct(depositorid) %>%
  nrow()
##

# Number of transactions sent from Mumbai
df %>%
  filter(dtname_send == "MUMBAI") %>%
  summarize(cum_trxn = sum(count_trxn))
  
##

# Filter on transfers carrying usable geographic information on recipient
df <- df %>% filter(transfer_ok_to_use == 1)
df <- df %>% filter(is_geocoded_send_rec == 1)

# Remove all groups where the IFSC/bank account suggests a large city recipient 
# or one of the 7 flagged accounts. Rural or Small town Destination 
# (population cutoff of 100th town is 409,403 by 2001 population)
# Include NAs population i.e treat as small
df1 <- df %>% filter((Rural_rec == 1))
df1 <- df1 %>% filter(top_7_manual_only_ifsc == 0)

rm(df)

# Select depositor-district pairs where transfers are consistent with remittances
df2 <- df1 %>%
  dplyr::group_by(depositorid, JID_rec) %>%
  dplyr::mutate(
    total_transfer = sum(sum_amt, na.rm = TRUE),
    total_transactions = sum(count_trxn, na.rm = TRUE),
    total_batch_transactions = sum(count_batch_trxn, na.rm = T),
    median_avg_amt = median(avg_amt, na.rm = TRUE),
    sender_population = first(TOT_P_send),
    recipient_population = first(TOT_P_rec)
  )

#If there is more than one district, break ties by the one receiving more transactions and then recipient district population
df2 = df2 %>%
  dplyr::group_by(depositorid) %>%
  dplyr:: mutate(max_total_transactions = max(total_transactions),
                 max_recipient_population=max(recipient_population))
df2 = df2 %>%
  dplyr::group_by(depositorid, JID_rec) %>%
  dplyr::mutate(drop_district1 = (total_transactions<max_total_transactions),
                drop_district2 = (recipient_population<max_recipient_population))

df2 = df2 %>%
  dplyr::filter(drop_district1==FALSE)
df2 = df2 %>%
  dplyr::filter(drop_district2==FALSE)

# Outward Path is depositor district -> recipient district
df2$OutPathID <- paste(df2$JID_send, df2$JID_rec, sep = "_")

# Summarise characteristics of this rural path
df3 <- df2 %>%
  dplyr::group_by(OutPathID) %>%
  dplyr::summarise(
    total_transfer = sum(sum_amt, na.rm = TRUE),
    total_transactions = sum(count_trxn, na.rm = TRUE),
    total_batch_transactions = sum(count_batch_trxn),
    lon_dist_cent_rec = first(lon_dist_cent_rec),
    lat_dist_cent_rec = first(lat_dist_cent_rec),
    lon_dist_cent_send = first(lon_dist_cent_send),
    lat_dist_cent_send = first(lat_dist_cent_send),
    tot_days = sum(no_of_days, na.rm = TRUE),
    max_transfer_transaction = max(max_amt, na.rm = TRUE),
    number_of_migrants = length(unique(depositorid)),
    dtname_rec = first(dtname_rec),
    stname_rec = first(stname_rec),
    dtname_send = first(dtname_send),
    stname_send = first(stname_send),
    JID_send=first(JID_send),
    JID_rec=first(JID_rec),
    sender_population = first(sender_population)
  )

# Remove same district transfers
df3 <- df3 %>% filter(df3$JID_rec != df3$JID_send)

# Select necessary variables
df4 <- df3 %>%
  select(stname_send, dtname_send, JID_send, number_of_migrants, 
         stname_rec, dtname_rec, JID_rec)

df5 <- df4 %>%
  filter(JID_send == 1111,
         !(JID_rec %in% c(1111))) %>%
  group_by(JID_rec, stname_rec, dtname_rec) %>%
  dplyr::summarize(mumbai_flows = sum(number_of_migrants)) %>%
  ungroup() %>%
  dplyr::rename(JID = JID_rec, state = stname_rec, district = dtname_rec)

df5[is.na(df5)] <- 0
write_dta(df5, paste0(dirpath, "remittance_flows_from_mumbai.dta"))


