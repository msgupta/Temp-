### Importing necessary libraries
library(data.table)
library(dplyr)
library(lubridate)
library(tidyverse)


#coupon_offer <- fread('/Users/twu1/Desktop/coupon/coupon_offer.csv')
###Importing the csv file
raw_coupon_combined <- fread('C:/Users/gsharma7/OneDrive - JC Penney/Mckinsey/new data/Data/4. Coupon - Elasticity/final coupon data/20200316/Barcode_Data_20200316.csv')
##raw_coupon_part2 <- fread('/Users/twu1/Desktop/Data/coupon/Raw Data/20190805_coupon_merchandise_cleaned_part2.csv')
##raw_coupon_combined <- rbind(raw_coupon_part1, raw_coupon_part2)

##the unique barcode ids corresponding to the BMSM offers
bmsm_barcode <- c(455964,	455973,	456068,	456413,	456592,	456597,	456605,	456608,	456609,	456617,	456630,	457002,	457007,	457090,	457106,	457106,	457134,	457134,	457136,	457137,	457138,	457141,	457155,	457221,	457221,	457310,	457318,	457377,	457381,	457382,	457383,	457384,	457385,	457385,	457473,	457551,	457570,	457726,	457726,	457728,	457729,	457730,	457733,	457746,	457762,	457774,	457799,	457800,	457817,	457851,	457852,	457853,	457858,	457869,	457879,	457926,	458038,	458058,	458152,	458152,	458153,	458153,	458185,	458189,	458189,	458189,	458197,	458217,	458223,	458465,	458509,	458536,	458736,	458764,	458773,	458774,	458775,	458778,	458782,	458783,	458793,	458794,	458815,	458816,	458861,	458862,	458884,	458885,	458886,	458887,	458888,	458889,	458902,	458903,	458914,	458915,	458981,	458982,	459006,	459006,	459063,	459068,	459080,	459083,	459093,	459094,	459111,	459118,	459119,	459127,	459133,	459134,	459143,	459144,	459145,	459146,	459158,	459159,	459160,	459161,	459162,	459163,	459185,	459212,	459213,	459214,	459215,	459301,	459302,	459315,	459316,	459319,	459320,	459323,	459324,	459374,	459395,	459425,	459426)
head(raw_coupon_combined)
###manipulate the columns and create new columns for offer type and offer value 
raw_coupon_combined <- 
  raw_coupon_combined %>%
  mutate(
    value_off = round(i.value_off), 
    type_off = ifelse(i.type_off == '$', 'D', 'P'), 
    discount_depth3 = i.discount_depth,
    discount_depth2 = gsub("[$]", "Doff", discount_depth3),
    discount_depth = gsub("[%]", "Poff", discount_depth2), ### renaming the $ to DOFF and % to Poff
    bmgm_flag = ifelse(i.barcode_id %in% bmsm_barcode, 1, 0), ##creating flag for BMSM barcodes
    type_value_off = ifelse(type_off == 'P', paste(value_off, type_off), paste(paste(value_off, type_off), discount_depth)), ##combining value_off, type_off and disc depth columns
    value_off_adj = ifelse(bmgm_flag == 1, "BMSM", value_off), 
    coupon_offer_name = paste(value_off_adj, type_off, sep = "_")
  )

head(raw_coupon_combined)


check <- raw_coupon_combined %>% filter(bmgm_flag == 1)
###check for the unique data for barcode_id, loyalty_flag, coupon_type_adj, discount_depth, bmgm_flag, sub levels
summa_coupon <- 
  raw_coupon_combined %>% 
  group_by(i.barcode_id, i.loyalty_flag, i.coupon_type_adj, discount_depth, bmgm_flag, i.sub) %>%
  mutate(
    dist_type_off = n_distinct(type_off) ##distinct values of type off
    , dist_value_off = n_distinct(value_off) ##distinct values of offer value
  )

head(summa_coupon)
######get the unique data for barcode_id, loyalty_flag, coupon_type_adj, discount_depth, bmgm_flag, sub,type_off, value_off, type_value_off levels where dist_value_off=1
barcode_w_one_value_off <- 
  summa_coupon %>% 
  filter(dist_value_off == 1) %>%
  distinct(i.barcode_id, i.loyalty_flag,i.coupon_type_adj, i.discount_depth, bmgm_flag, i.sub, type_off, value_off, type_value_off)

######get the unique data for barcode_id, loyalty_flag, coupon_type_adj, discount_depth, bmgm_flag, sub,type_off levels where dist_value_off>1
barcode_w_more_than_one_value_off <- 
  summa_coupon %>% 
  filter(dist_value_off > 1) %>%
  group_by(i.barcode_id, i.loyalty_flag, i.coupon_type_adj, i.discount_depth, bmgm_flag, i.sub, type_off) %>%
  summarise(
    value_off = min(value_off) ##taking min of the offer value
  ) %>%
  mutate(
    type_value_off = ifelse(type_off == 'P', paste(value_off, type_off), paste(paste(value_off, type_off), i.discount_depth))
  )


barcode_vF <- rbind(barcode_w_one_value_off, barcode_w_more_than_one_value_off) ##append the above data frames

head(barcode_vF)

###create list of primary and secondary coupon groups
primary_coupon_groups <- 
  c('20 P_0_Storewide'
    , '10 D 10Doff_1_Storewide'
    , '15 P_0_Storewide'
    , '10 D 23Doff_0_Storewide'
    , '30 P_0_Storewide'
    , '25 P_0_Storewide'
  )

secondary_coupon_groups <- 
  c('10 D 10Doff_0_Storewide'
    ,'40 P_0_Storewide'
    ,'50 P_0_Storewide'
    ,'10 P_0_Storewide'
    ,'20 P_0_Business Specific'
  )
##create the final coupon groups
barcode_vF2<- 
  barcode_vF %>%
  mutate(
    coupon_group_raw = paste(str_trim(type_value_off), str_trim(i.loyalty_flag), str_trim(i.coupon_type_adj), sep = '_') , 
    primary_coupon_group_flag = ifelse(coupon_group_raw %in% primary_coupon_groups, 1, 0),
    coupon_group = ifelse(!coupon_group_raw %in% append(primary_coupon_groups, secondary_coupon_groups), paste(str_trim(type_off), str_trim(i.coupon_type_adj), sep = '_'), coupon_group_raw)
  )

head(barcode_vF2)
##barcode_vF3 <- select(barcode_vF2,barcode_id, loyalty_flag, coupon_type_adj,bmgm_flag,sub, type_off, value_off, type_value_off,coupon_group_raw)

barcode_vF2 <-barcode_vF2 %>% rename(sub=i.sub,discount_depth1=i.discount_depth,barcode_id=i.barcode_id,loyalty_flag=i.loyalty_flag,coupon_type_adj=i.coupon_type_adj)
###export the csv
write.csv(barcode_vF2, 'C:/Users/gsharma7/OneDrive - JC Penney/Mckinsey/new data/Data/4. Coupon - Elasticity/final coupon data/20200316/20200316_barcode_sub_vF2.csv', row.names = F)

# head(barcode_vF2 %>% filter(bmgm_flag == 1))
# 
# 
# barcode_vF2 %>%
#   group_by(coupon_group, primary_coupon_group_flag) %>%
#   tally
# 
# ## check
# barcode_vF2 %>%
#   group_by(barcode_id, loyalty_flag, coupon_type_adj, discount_depth, bmgm_flag, sub, type_value_off) %>%
#   tally %>%
#   arrange(desc(n))