##################################################################################################################
##################################################################################################################
#######################################  Overall Coupon effectiveness model#######################################
##############  There are two parts of the code:                             #####################################
################################################ 1 Data cleaning and model  ######################################
################################################ 2. Baseline generation ##########################################
##################################################################################################################
##############  This is the baseline and incremental simulation session, which includes: #########################
##############        01. Load useful data                                   #####################################
##############        02. Baseline trip and trip incremental simulation      #####################################
##############        03. Baseline basket simulation                         #####################################
##############        04. Baseline revenue and margin simulation             #####################################
##############        05. Summary campaign performance                       #####################################
##################################################################################################################
##################################################################################################################
############## The input of this moel is the coefficients from the model     #####################################
##################################################################################################################
##################################################################################################################
##################################################################################################################
##################################################################################################################
##################################################################################################################
### Importing necessary libraries
library(dplyr)
#library(xlsx)#read excel file
#setwd("/home/gsharma7")
library(data.table)
library(tidyverse)
library(tidylog)
library(dplyr)
library(lubridate)
library(car)
library(purrr)
library(readxl) ## to read xls files
##############        01. Load useful data                                   #####################################

##coupon_d <- read.csv("overall_coupon_data_full_20191125", guess_max = 1000)
setwd("C:/Users/gsharma7/OneDrive - JC Penney/Mckinsey/new data/Data/4. Coupon - Elasticity/final coupon data/20200316")

##coupon_d <- read.csv("overall_coupon_data_full.csv")
coupon_d <- read_csv("Overall_coupon_data_full_20200318.csv", guess_max = 1000)

#loading other data for the simulation
cpn_data_sales <- read_csv("Sales_by_coupon_20200318.csv", guess_max = 1000)
cpn_primary_sales <- read_csv("Primary_disc_20200318.csv", guess_max = 1000)
cost_data <- read_csv("cgs.csv", guess_max = 1000)
###campaign calendar
campaign_date_mapping <- read_xlsx("cleaned_campaign_calendar_2018-2019_updated.xlsx", 
                                  sheet ="cleaned_campaign_calendar_2018")%>% 
mutate(tran_datetime = date(tran_datetime))
non_coupon_data <- read_csv("non_coupon_data.csv", guess_max = 1000)

coupon_d <- read_csv("Overall_coupon_data_full_20200318.csv", guess_max = 1000)

#loading other data for the simulation
#cpn_data_sales <- read_csv("sales_by_coupon 20191125.csv", guess_max = 1000)
#cpn_primary_sales <- read_csv("primary_discount_saved_amt_coupon 20191125.csv", guess_max = 1000)
#cost_data <- read_csv("overall_coupon_cogs_data 20191125.csv", guess_max = 1000)
##campaign_date_mapping <- read_csv("cleaned_campaign_calendar_2018-2019_updated.csv", guess_max = 1000)

##campaign_date_mapping1<- campaign_date_mapping %>% mutate(tran_datetime=date(tran_datetime))
#class(campaign_date_mapping$tran_datetime)                         
 ## mutate(tran_datetime = date(tran_datetime))
#non_coupon_data <- read_csv("non coupon data 20191125.csv", guess_max = 1000)

#cpn_data_sales <- read.csv("sales_by_coupon 20191125.csv")

#View(cpn_data_sales)
##cpn_primary_sales <- read.csv("primary_discount_saved_amt_coupon 20191125.csv")
##cost_data <- read.csv("overall_coupon_cogs_data 20191125.csv")
##campaign_date_mapping <- read.xlsx("cleaned_campaign_calendar_2018-2019_updated.xlsx", 
##                                   1)%>% 
##mutate(tran_datetime = date(tran_datetime))
##non_coupon_data <- read.csv("non coupon data 20191125.csv")
##View(campaign_date_mapping)

#Joining key cleaning
#cpn_data_sales$tran_datetime = format(as.Date(cpn_data_sales$tran_datetime, '%Y-%m-%d'), "%m/%d/%Y")
#cpn_data_sales$tran_datetime = format(as.Date(cpn_data_sales$tran_datetime, '%Y-%m-%d'), "%m/%d/%Y")
##create new column by summing up the saved sales for all the coupons
cpn_data_sales$sales_cpn <- rowSums(cpn_data_sales[,which(grepl("saved_sales", colnames(cpn_data_sales))>0)])
#cpn_primary_sales$tran_datetime = format(as.Date(cpn_primary_sales$tran_datetime, '%Y-%m-%d'), "%m/%d/%Y")
#cost_data$tran_datetime = format(as.Date(cost_data$tran_datetime, '%Y-%m-%d'), "%m/%d/%Y")
#non_coupon_data$tran_datetime <- format(as.Date(non_coupon_data$tran_datetime, '%Y-%m-%d'), "%m/%d/%Y")
head(cpn_data_sales$sales_cpn)
####identify columns which have amt in their names
coupon_amt_list <- colnames(coupon_d)[which(grepl("amt", colnames(coupon_d))>0 & grepl("trips", colnames(coupon_d))==0)]
coupon_amt_list
coupon_d_1 <- as.data.frame(coupon_d)
###create new column
coupon_d$new_perc_saved_w_non_coupon <- 1 - rowSums(coupon_d_1[c(coupon_amt_list)])/coupon_d$p1_sales - coupon_d$trip*coupon_d$avg_basket_size/coupon_d$p1_sales

#Essential data transformation

cpn_baseline_data1 <- 
  coupon_d %>%
  mutate(
    weekday = wday(coupon_d$tran_datetime)
    , weekend_flag = ifelse(as.character(weekday) %in% c(1, 6, 7), 1, 0)
    , month = month(tran_datetime)
    # date # 
   # ,tran_datetime = format(as.Date(tran_datetime, '%Y-%m-%d'), "%m/%d/%Y")
    , per_total_saved = 1-(trip*avg_basket_size/p1_sales)
    , per_total_saved_log = log(1-(trip*avg_basket_size/p1_sales))
    , perc_saved_w_non_coupon_log = log(new_perc_saved_w_non_coupon)
    # perc trip by coupon group #
    ,perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips=poff20_non_loyalty_storewide_coupon_saved_amt_trips/trip
    ,perc_d10off10_loyalty_storewide_coupon_saved_amt_trips=d10off10_loyalty_storewide_coupon_saved_amt_trips/trip
    ,perc_d10off25_non_loyalty_storewide_coupon_saved_amt_trips=d10off25_non_loyalty_storewide_coupon_saved_amt_trips/trip
    ,perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips=poff25_non_loyalty_storewide_coupon_saved_amt_trips/trip
    ,perc_poff40_non_loyalty_storewide_coupon_saved_amt_trips=poff40_non_loyalty_storewide_coupon_saved_amt_trips/trip
    ,perc_poff10_non_loyalty_storewide_coupon_saved_amt_trips=poff10_non_loyalty_storewide_coupon_saved_amt_trips/trip
    ,perc_business_specific_jewelry_coupon_saved_amt_trips=business_specific_jewelry_coupon_saved_amt_trips/trip
    ,perc_storewide_doff_coupon_saved_amt_trips=storewide_doff_coupon_saved_amt_trips/trip
    ,perc_business_specific_jewelry_coupon_saved_amt_trips=business_specific_jewelry_coupon_saved_amt_trips/trip
    ,perc_storewide_doff_coupon_saved_amt_trips=storewide_doff_coupon_saved_amt_trips/trip
    ,perc_poff15_non_loyalty_storewide_coupon_saved_amt_trips=poff15_non_loyalty_storewide_coupon_saved_amt_trips/trip
    ,perc_poff30_non_loyalty_storewide_coupon_saved_amt_trips=poff30_non_loyalty_storewide_coupon_saved_amt_trips/trip
    ,perc_d10off10_non_loyalty_storewide_coupon_saved_amt_trips=d10off10_non_loyalty_storewide_coupon_saved_amt_trips/trip
    ,perc_poff50_non_loyalty_storewide_coupon_saved_amt_trips=poff50_non_loyalty_storewide_coupon_saved_amt_trips/trip
    ,perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips=poff20_non_loyalty_business_specific_coupon_saved_amt_trips/trip
    ,perc_business_specific_non_jewelry_coupon_saved_amt_trips=business_specific_non_jewelry_coupon_saved_amt_trips/trip
    ,perc_storewide_poff_coupon_saved_amt_trips=storewide_poff_coupon_saved_amt_trips/trip
    ,perc_business_specific_non_jewelry_coupon_saved_amt_trips=business_specific_non_jewelry_coupon_saved_amt_trips/trip
    ,perc_storewide_poff_coupon_saved_amt_trips=storewide_poff_coupon_saved_amt_trips/trip
    # log of dep
    ,log_trip = log(trip)
    ,log_avg_baseket_size = log(avg_basket_size)
  ) %>%
  replace(., is.na(.), 0)

###merge baseline data with non coupon data
cpn_baseline_data2 <- merge(cpn_baseline_data1, non_coupon_data, by = "tran_datetime")
####merge with cost data
cpn_baseline_data <- merge(cpn_baseline_data2, cost_data[c("tran_datetime", colnames(cost_data)[which(grepl("coupon_saved_total_cogs", colnames(cost_data))>0)])], by = "tran_datetime")

#View(cpn_baseline_data)
##############        02. Baseline trip and trip incremental simulation      #####################################


##############        1. The following are the outputs from previous trip model, we only care about the coupon coefficient and price coefficient
##############        2. The coupon marketing coefficient should be positive, so if they are negative, we replace them with 0



# perc_d10off10_loyalty_storewide_coupon_saved_amt_trips_flag     -0.008361   0.016144  -0.518 0.604710    
# perc_poff10_non_loyalty_storewide_coupon_saved_amt_trips_flag    0.039923   0.017195   2.322 0.020531 *  
#   perc_poff30_non_loyalty_storewide_coupon_saved_amt_trips_flag    0.008316   0.017707   0.470 0.638762    
# perc_storewide_doff_coupon_saved_amt_trips_flag                 -0.021585   0.016373  -1.318 0.187827    
# perc_d10off10_non_loyalty_storewide_coupon_saved_amt_trips_flag  0.009371   0.019182   0.489 0.625329    
# perc_business_specific_non_jewelry_coupon_saved_amt_trips_flag   0.012733   0.015815   0.805 0.421009    
# perc_storewide_poff_coupon_saved_amt_trips_flag                 -0.022710   0.019954  -1.138 0.255466    
# perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips_flag   -0.006762   0.017413  -0.388 0.697879    
# flag_other                                                       0.012112   0.017672   0.685 0.493309    
# flag_15_20_non_loyalty_storewide                                 0.020512   0.017429   1.177 0.239633    
# flag_30_50_non_loyalty_storewide                                 0.047680   0.026943   1.770 0.077223 .
#per_total_saved_log                                              0.900180   0.099128   9.081  < 2e-16 ***

#perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips   0.020512
#perc_d10off10_loyalty_storewide_coupon_saved_amt_trips     0
#perc_d10off25_non_loyalty_storewide_coupon_saved_amt_trips   0.012112
#perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips      0
#perc_poff40_non_loyalty_storewide_coupon_saved_amt_trips     0.047680
#perc_poff10_non_loyalty_storewide_coupon_saved_amt_trips     0.039923
#perc_business_specific_jewelry_coupon_saved_amt_trips       0.012112
#perc_storewide_doff_coupon_saved_amt_trips                 0
#perc_poff15_non_loyalty_storewide_coupon_saved_amt_trips   0.020512
#perc_poff30_non_loyalty_storewide_coupon_saved_amt_trips    0.008316
#perc_d10off10_non_loyalty_storewide_coupon_saved_amt_trips   0.009371
#perc_poff50_non_loyalty_storewide_coupon_saved_amt_trips     0.047680
#perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips    0.012112
#perc_business_specific_non_jewelry_coupon_saved_amt_trips      0.012733
#perc_storewide_poff_coupon_saved_amt_trips                  0
#price 0.900180 per_total_saved_log 0.900180   0.103283  10.469  < 2e-16 ***


#######################################  Model result week 40 #########################

Coefficients:
  #   Estimate Std. Error t value Pr(>|t|)    
  # (Intercept)                                                      2.201393   0.430281   5.116 3.87e-07 ***
  #   per_total_saved_log                                              0.957404   0.085692  11.173  < 2e-16 ***
  #   weekend_flag                                                     0.382774   0.014091  27.164  < 2e-16 ***
  #   hol_pre_valen                                                    0.046003   0.132943   0.346   0.7294    
  # hol_thx                                                          1.206231   0.135092   8.929  < 2e-16 ***
  #   hol_pre_thx                                                     -0.048038   0.186695  -0.257   0.7970    
  # hol_christ                                                       0.669198   0.096355   6.945 7.62e-12 ***
  #   hol_aug_sale                                                     0.379705   0.094679   4.010 6.60e-05 ***
  #   hol_mar_apr_sale                                                 0.391034   0.077689   5.033 5.91e-07 ***
  #   hol_post_thx                                                    -0.200503   0.086072  -2.329   0.0201 *  
#   perc_d10off10_loyalty_storewide_coupon_saved_amt_trips_flag     -0.027436   0.016434  -1.669   0.0954 .  
# perc_poff10_non_loyalty_storewide_coupon_saved_amt_trips_flag    0.065115   0.014267   4.564 5.77e-06 ***
#   perc_poff30_non_loyalty_storewide_coupon_saved_amt_trips_flag   -0.001774   0.015316  -0.116   0.9078    
# perc_storewide_doff_coupon_saved_amt_trips_flag                 -0.027492   0.014519  -1.893   0.0586 .  
# perc_d10off10_non_loyalty_storewide_coupon_saved_amt_trips_flag  0.006237   0.014664   0.425   0.6707    
# perc_business_specific_non_jewelry_coupon_saved_amt_trips_flag   0.017990   0.014778   1.217   0.2238    
# perc_storewide_poff_coupon_saved_amt_trips_flag                  0.019316   0.015956   1.211   0.2264    
# perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips_flag   -0.006422   0.014620  -0.439   0.6606    
# flag_other                                                      -0.005151   0.016556  -0.311   0.7558    
# flag_15_20_non_loyalty_storewide                                 0.006986   0.015033   0.465   0.6422    
# flag_30_50_non_loyalty_storewide                                 0.046270   0.022576   2.050   0.0407 *  
#   trip_trend_log                                                   0.855703   0.032517  26.316  < 2e-16 ***
#   --


###create the baseline trip column
cpn_baseline_data$log_base_trip <-(
  log(cpn_baseline_data$trip)-
    cpn_baseline_data$per_total_saved_log*( 1.099910) +
    cpn_baseline_data$perc_saved_w_non_coupon_log*( 1.099910) -
    cpn_baseline_data$perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips * 0-
    cpn_baseline_data$perc_d10off10_loyalty_storewide_coupon_saved_amt_trips * 0-
    cpn_baseline_data$perc_d10off25_non_loyalty_storewide_coupon_saved_amt_trips *   0.010749-
    cpn_baseline_data$perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips * 0-
    cpn_baseline_data$perc_poff40_non_loyalty_storewide_coupon_saved_amt_trips *   0.041578-
    cpn_baseline_data$perc_poff10_non_loyalty_storewide_coupon_saved_amt_trips * 0.038902  -
    cpn_baseline_data$perc_business_specific_jewelry_coupon_saved_amt_trips *  0.010749  -
    cpn_baseline_data$perc_storewide_doff_coupon_saved_amt_trips * 0-
    cpn_baseline_data$perc_poff15_non_loyalty_storewide_coupon_saved_amt_trips *    0 -
    cpn_baseline_data$perc_poff30_non_loyalty_storewide_coupon_saved_amt_trips * 0-
    cpn_baseline_data$perc_d10off10_non_loyalty_storewide_coupon_saved_amt_trips *  0.015521 -
    cpn_baseline_data$perc_poff50_non_loyalty_storewide_coupon_saved_amt_trips *  0.041578  -
    cpn_baseline_data$perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips *  0.010749 -
    cpn_baseline_data$perc_business_specific_non_jewelry_coupon_saved_amt_trips *  0.005156-
    cpn_baseline_data$perc_storewide_poff_coupon_saved_amt_trips *0.018589    
)

cpn_baseline_data$base_trip <- exp(cpn_baseline_data$log_base_trip)
##calculate the increamental trips
cpn_baseline_data$trip_incre_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips <- exp(cpn_baseline_data$log_base_trip + log(1+cpn_baseline_data$poff20_non_loyalty_storewide_coupon_saved_amt/(cpn_baseline_data$new_perc_saved_w_non_coupon*cpn_baseline_data$p1_sales))*  1.099910 +  0*cpn_baseline_data$perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips ) - cpn_baseline_data$base_trip
cpn_baseline_data$trip_incre_perc_d10off10_loyalty_storewide_coupon_saved_amt_trips <- exp(cpn_baseline_data$log_base_trip + log(1+cpn_baseline_data$d10off10_loyalty_storewide_coupon_saved_amt/(cpn_baseline_data$new_perc_saved_w_non_coupon*cpn_baseline_data$p1_sales))*  1.099910 + 0*cpn_baseline_data$perc_d10off10_loyalty_storewide_coupon_saved_amt_trips ) - cpn_baseline_data$base_trip
cpn_baseline_data$trip_incre_perc_d10off25_non_loyalty_storewide_coupon_saved_amt_trips <- exp(cpn_baseline_data$log_base_trip + log(1+cpn_baseline_data$d10off25_non_loyalty_storewide_coupon_saved_amt/(cpn_baseline_data$new_perc_saved_w_non_coupon*cpn_baseline_data$p1_sales))*  1.099910 + 0.010749*cpn_baseline_data$perc_d10off25_non_loyalty_storewide_coupon_saved_amt_trips ) - cpn_baseline_data$base_trip
cpn_baseline_data$trip_incre_perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips <- exp(cpn_baseline_data$log_base_trip + log(1+cpn_baseline_data$poff25_non_loyalty_storewide_coupon_saved_amt/(cpn_baseline_data$new_perc_saved_w_non_coupon*cpn_baseline_data$p1_sales))*  1.099910 + 0*cpn_baseline_data$perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips ) - cpn_baseline_data$base_trip
cpn_baseline_data$trip_incre_perc_poff40_non_loyalty_storewide_coupon_saved_amt_trips <- exp(cpn_baseline_data$log_base_trip + log(1+cpn_baseline_data$poff40_non_loyalty_storewide_coupon_saved_amt/(cpn_baseline_data$new_perc_saved_w_non_coupon*cpn_baseline_data$p1_sales))*  1.099910 + 0.041578*cpn_baseline_data$perc_poff40_non_loyalty_storewide_coupon_saved_amt_trips ) - cpn_baseline_data$base_trip
cpn_baseline_data$trip_incre_perc_poff10_non_loyalty_storewide_coupon_saved_amt_trips <- exp(cpn_baseline_data$log_base_trip + log(1+cpn_baseline_data$poff10_non_loyalty_storewide_coupon_saved_amt/(cpn_baseline_data$new_perc_saved_w_non_coupon*cpn_baseline_data$p1_sales))*  1.099910 + 0.038902*cpn_baseline_data$perc_poff10_non_loyalty_storewide_coupon_saved_amt_trips ) - cpn_baseline_data$base_trip
cpn_baseline_data$trip_incre_perc_business_specific_jewelry_coupon_saved_amt_trips <- exp(cpn_baseline_data$log_base_trip + log(1+cpn_baseline_data$business_specific_jewelry_coupon_saved_amt/(cpn_baseline_data$new_perc_saved_w_non_coupon*cpn_baseline_data$p1_sales))*  1.099910 + 0.010749*cpn_baseline_data$perc_business_specific_jewelry_coupon_saved_amt_trips ) - cpn_baseline_data$base_trip
cpn_baseline_data$trip_incre_perc_storewide_doff_coupon_saved_amt_trips <- exp(cpn_baseline_data$log_base_trip + log(1+cpn_baseline_data$storewide_doff_coupon_saved_amt/(cpn_baseline_data$new_perc_saved_w_non_coupon*cpn_baseline_data$p1_sales))*  1.099910 + 0*cpn_baseline_data$perc_storewide_doff_coupon_saved_amt_trips ) - cpn_baseline_data$base_trip
cpn_baseline_data$trip_incre_perc_poff15_non_loyalty_storewide_coupon_saved_amt_trips <- exp(cpn_baseline_data$log_base_trip + log(1+cpn_baseline_data$poff15_non_loyalty_storewide_coupon_saved_amt/(cpn_baseline_data$new_perc_saved_w_non_coupon*cpn_baseline_data$p1_sales))*  1.099910 + 0*cpn_baseline_data$perc_poff15_non_loyalty_storewide_coupon_saved_amt_trips ) - cpn_baseline_data$base_trip
cpn_baseline_data$trip_incre_perc_poff30_non_loyalty_storewide_coupon_saved_amt_trips <- exp(cpn_baseline_data$log_base_trip + log(1+cpn_baseline_data$poff30_non_loyalty_storewide_coupon_saved_amt/(cpn_baseline_data$new_perc_saved_w_non_coupon*cpn_baseline_data$p1_sales))*  1.099910 + 0*cpn_baseline_data$perc_poff30_non_loyalty_storewide_coupon_saved_amt_trips ) - cpn_baseline_data$base_trip
cpn_baseline_data$trip_incre_perc_d10off10_non_loyalty_storewide_coupon_saved_amt_trips <- exp(cpn_baseline_data$log_base_trip + log(1+cpn_baseline_data$d10off10_non_loyalty_storewide_coupon_saved_amt/(cpn_baseline_data$new_perc_saved_w_non_coupon*cpn_baseline_data$p1_sales))*  1.099910 +  0.015521*cpn_baseline_data$perc_d10off10_non_loyalty_storewide_coupon_saved_amt_trips ) - cpn_baseline_data$base_trip
cpn_baseline_data$trip_incre_perc_poff50_non_loyalty_storewide_coupon_saved_amt_trips <- exp(cpn_baseline_data$log_base_trip + log(1+cpn_baseline_data$poff50_non_loyalty_storewide_coupon_saved_amt/(cpn_baseline_data$new_perc_saved_w_non_coupon*cpn_baseline_data$p1_sales))*  1.099910 +   0.041578*cpn_baseline_data$perc_poff50_non_loyalty_storewide_coupon_saved_amt_trips ) - cpn_baseline_data$base_trip
cpn_baseline_data$trip_incre_perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips <- exp(cpn_baseline_data$log_base_trip + log(1+cpn_baseline_data$poff20_non_loyalty_business_specific_coupon_saved_amt/(cpn_baseline_data$new_perc_saved_w_non_coupon*cpn_baseline_data$p1_sales))*  1.099910 + 0.010749*cpn_baseline_data$perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips ) - cpn_baseline_data$base_trip
cpn_baseline_data$trip_incre_perc_business_specific_non_jewelry_coupon_saved_amt_trips <- exp(cpn_baseline_data$log_base_trip + log(1+cpn_baseline_data$business_specific_non_jewelry_coupon_saved_amt/(cpn_baseline_data$new_perc_saved_w_non_coupon*cpn_baseline_data$p1_sales))*  1.099910 + 0.005156*cpn_baseline_data$perc_business_specific_non_jewelry_coupon_saved_amt_trips ) - cpn_baseline_data$base_trip
cpn_baseline_data$trip_incre_perc_storewide_poff_coupon_saved_amt_trips <- exp(cpn_baseline_data$log_base_trip + log(1+cpn_baseline_data$storewide_poff_coupon_saved_amt/(cpn_baseline_data$new_perc_saved_w_non_coupon*cpn_baseline_data$p1_sales))*  1.099910 +  0.018589 *cpn_baseline_data$perc_storewide_poff_coupon_saved_amt_trips ) - cpn_baseline_data$base_trip

####create the totel trips
cpn_baseline_data$trip_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips <- exp(cpn_baseline_data$log_base_trip + log(1+cpn_baseline_data$poff20_non_loyalty_storewide_coupon_saved_amt/(cpn_baseline_data$new_perc_saved_w_non_coupon*cpn_baseline_data$p1_sales))*1.099910 +  0*cpn_baseline_data$perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips ) 
cpn_baseline_data$trip_perc_d10off10_loyalty_storewide_coupon_saved_amt_trips <- exp(cpn_baseline_data$log_base_trip + log(1+cpn_baseline_data$d10off10_loyalty_storewide_coupon_saved_amt/(cpn_baseline_data$new_perc_saved_w_non_coupon*cpn_baseline_data$p1_sales))*1.099910 +  0*cpn_baseline_data$perc_d10off10_loyalty_storewide_coupon_saved_amt_trips ) 
cpn_baseline_data$trip_perc_d10off25_non_loyalty_storewide_coupon_saved_amt_trips <- exp(cpn_baseline_data$log_base_trip + log(1+cpn_baseline_data$d10off25_non_loyalty_storewide_coupon_saved_amt/(cpn_baseline_data$new_perc_saved_w_non_coupon*cpn_baseline_data$p1_sales))*1.099910 + 0.010749*cpn_baseline_data$perc_d10off25_non_loyalty_storewide_coupon_saved_amt_trips ) 
cpn_baseline_data$trip_perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips <- exp(cpn_baseline_data$log_base_trip + log(1+cpn_baseline_data$poff25_non_loyalty_storewide_coupon_saved_amt/(cpn_baseline_data$new_perc_saved_w_non_coupon*cpn_baseline_data$p1_sales))*1.099910 + 0*cpn_baseline_data$perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips ) 
cpn_baseline_data$trip_perc_poff40_non_loyalty_storewide_coupon_saved_amt_trips <- exp(cpn_baseline_data$log_base_trip + log(1+cpn_baseline_data$poff40_non_loyalty_storewide_coupon_saved_amt/(cpn_baseline_data$new_perc_saved_w_non_coupon*cpn_baseline_data$p1_sales))*1.099910 + 0.041578*cpn_baseline_data$perc_poff40_non_loyalty_storewide_coupon_saved_amt_trips ) 
cpn_baseline_data$trip_perc_poff10_non_loyalty_storewide_coupon_saved_amt_trips <- exp(cpn_baseline_data$log_base_trip + log(1+cpn_baseline_data$poff10_non_loyalty_storewide_coupon_saved_amt/(cpn_baseline_data$new_perc_saved_w_non_coupon*cpn_baseline_data$p1_sales))*1.099910 + 0.038902*cpn_baseline_data$perc_poff10_non_loyalty_storewide_coupon_saved_amt_trips ) 
cpn_baseline_data$trip_perc_business_specific_jewelry_coupon_saved_amt_trips <- exp(cpn_baseline_data$log_base_trip + log(1+cpn_baseline_data$business_specific_jewelry_coupon_saved_amt/(cpn_baseline_data$new_perc_saved_w_non_coupon*cpn_baseline_data$p1_sales))*1.099910 + 0.010749*cpn_baseline_data$perc_business_specific_jewelry_coupon_saved_amt_trips ) 
cpn_baseline_data$trip_perc_storewide_doff_coupon_saved_amt_trips <- exp(cpn_baseline_data$log_base_trip + log(1+cpn_baseline_data$storewide_doff_coupon_saved_amt/(cpn_baseline_data$new_perc_saved_w_non_coupon*cpn_baseline_data$p1_sales))*1.099910 + 0*cpn_baseline_data$perc_storewide_doff_coupon_saved_amt_trips ) 
cpn_baseline_data$trip_perc_poff15_non_loyalty_storewide_coupon_saved_amt_trips <- exp(cpn_baseline_data$log_base_trip + log(1+cpn_baseline_data$poff15_non_loyalty_storewide_coupon_saved_amt/(cpn_baseline_data$new_perc_saved_w_non_coupon*cpn_baseline_data$p1_sales))*1.099910 + 0*cpn_baseline_data$perc_poff15_non_loyalty_storewide_coupon_saved_amt_trips ) 
cpn_baseline_data$trip_perc_poff30_non_loyalty_storewide_coupon_saved_amt_trips <- exp(cpn_baseline_data$log_base_trip + log(1+cpn_baseline_data$poff30_non_loyalty_storewide_coupon_saved_amt/(cpn_baseline_data$new_perc_saved_w_non_coupon*cpn_baseline_data$p1_sales))*1.099910 + 0*cpn_baseline_data$perc_poff30_non_loyalty_storewide_coupon_saved_amt_trips ) 
cpn_baseline_data$trip_perc_d10off10_non_loyalty_storewide_coupon_saved_amt_trips <- exp(cpn_baseline_data$log_base_trip + log(1+cpn_baseline_data$d10off10_non_loyalty_storewide_coupon_saved_amt/(cpn_baseline_data$new_perc_saved_w_non_coupon*cpn_baseline_data$p1_sales))*1.099910 +  0.015521*cpn_baseline_data$perc_d10off10_non_loyalty_storewide_coupon_saved_amt_trips ) 
cpn_baseline_data$trip_perc_poff50_non_loyalty_storewide_coupon_saved_amt_trips <- exp(cpn_baseline_data$log_base_trip + log(1+cpn_baseline_data$poff50_non_loyalty_storewide_coupon_saved_amt/(cpn_baseline_data$new_perc_saved_w_non_coupon*cpn_baseline_data$p1_sales))*1.099910 +   0.041578  *cpn_baseline_data$perc_poff50_non_loyalty_storewide_coupon_saved_amt_trips ) 
cpn_baseline_data$trip_perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips <- exp(cpn_baseline_data$log_base_trip + log(1+cpn_baseline_data$poff20_non_loyalty_business_specific_coupon_saved_amt/(cpn_baseline_data$new_perc_saved_w_non_coupon*cpn_baseline_data$p1_sales))*1.099910 + 0.010749 *cpn_baseline_data$perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips ) 
cpn_baseline_data$trip_perc_business_specific_non_jewelry_coupon_saved_amt_trips <- exp(cpn_baseline_data$log_base_trip + log(1+cpn_baseline_data$business_specific_non_jewelry_coupon_saved_amt/(cpn_baseline_data$new_perc_saved_w_non_coupon*cpn_baseline_data$p1_sales))*1.099910 + 0.005156*cpn_baseline_data$perc_business_specific_non_jewelry_coupon_saved_amt_trips ) 
cpn_baseline_data$trip_perc_storewide_poff_coupon_saved_amt_trips <- exp(cpn_baseline_data$log_base_trip + log(1+cpn_baseline_data$storewide_poff_coupon_saved_amt/(cpn_baseline_data$new_perc_saved_w_non_coupon*cpn_baseline_data$p1_sales))*1.099910 +  0.018589*cpn_baseline_data$perc_storewide_poff_coupon_saved_amt_trips ) 


##############        03. Baseline basket simulation                         #####################################


##############        1. The following are the outputs from previous basket model, we only care about the coupon coefficient and price coefficient
##############        2. The coupon marketing coefficient can be negative to the basket, no need to clean here

# perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips_flag         -0.010100   0.007733  -1.306 0.191931    
# perc_d10off10_loyalty_storewide_coupon_saved_amt_trips_flag           -0.006730   0.006335  -1.062 0.288441    
# perc_d10off25_non_loyalty_storewide_coupon_saved_amt_trips_flag        0.017236   0.007319   2.355 0.018809 *  
#   perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips_flag          0.001982   0.007003   0.283 0.777282    
# perc_poff40_non_loyalty_storewide_coupon_saved_amt_trips_flag         -0.005909   0.013058  -0.453 0.651037    
# perc_poff10_non_loyalty_storewide_coupon_saved_amt_trips_flag          0.000245   0.006657   0.037 0.970655    
# perc_business_specific_jewelry_coupon_saved_amt_trips_flag             0.014667   0.006899   2.126 0.033851 *  
#   perc_storewide_doff_coupon_saved_amt_trips_flag                       -0.000691   0.006474  -0.107 0.915028    
# perc_poff15_non_loyalty_storewide_coupon_saved_amt_trips_flag         -0.009454   0.006927  -1.365 0.172737    
# perc_poff30_non_loyalty_storewide_coupon_saved_amt_trips_flag          0.003994   0.006978   0.572 0.567276    
# perc_d10off10_non_loyalty_storewide_coupon_saved_amt_trips_flag       -0.005021   0.007074  -0.710 0.478092    
# perc_poff50_non_loyalty_storewide_coupon_saved_amt_trips_flag          0.020177   0.017323   1.165 0.244511    
# perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips_flag  0.002540   0.007489   0.339 0.734592    
# perc_business_specific_non_jewelry_coupon_saved_amt_trips_flag         0.005570   0.006411   0.869 0.385219    
# perc_storewide_poff_coupon_saved_amt_trips_flag                        0.002589   0.007933   0.326 0.744218    
# per_total_saved_log                                                   -0.144917   0.039794  -3.642 0.000291 ***



#########################3 model result week 40 ####################################

# (Intercept)                                                           -0.9964497  0.2718245  -3.666 0.000262 ***
#   per_total_saved_log                                                   -0.2812879  0.0529680  -5.311 1.41e-07 ***
#   weekend_flag                                                           0.0413748  0.0082872   4.993 7.27e-07 ***
#   hol_halo                                                               0.1179622  0.0397518   2.967 0.003089 ** 
#   hol_pre_valen                                                         -0.0205669  0.0775466  -0.265 0.790906    
# hol_thx                                                                0.1408888  0.0783743   1.798 0.072598 .  
# hol_pre_thx                                                            0.0373400  0.1086435   0.344 0.731165    
# hol_christ                                                             0.1101720  0.0558615   1.972 0.048915 *  
#   hol_aug_sale                                                           0.1672435  0.0555974   3.008 0.002708 ** 
#   hol_mar_apr_sale                                                       0.0054909  0.0455192   0.121 0.904015    
# hol_post_thx                                                           0.0173287  0.0504641   0.343 0.731395    
# perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips_flag         -0.0319019  0.0096685  -3.300 0.001010 ** 
#   perc_d10off10_loyalty_storewide_coupon_saved_amt_trips_flag           -0.0051792  0.0097932  -0.529 0.597048    
# perc_d10off25_non_loyalty_storewide_coupon_saved_amt_trips_flag        0.0394614  0.0094875   4.159 3.53e-05 ***
#   perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips_flag          0.0042264  0.0087634   0.482 0.629731    
# perc_poff40_non_loyalty_storewide_coupon_saved_amt_trips_flag         -0.0052217  0.0171437  -0.305 0.760761    
# perc_poff10_non_loyalty_storewide_coupon_saved_amt_trips_flag         -0.0161084  0.0084847  -1.899 0.057974 .  
# perc_business_specific_jewelry_coupon_saved_amt_trips_flag             0.0136426  0.0086304   1.581 0.114315    
# perc_storewide_doff_coupon_saved_amt_trips_flag                        0.0015506  0.0085305   0.182 0.855804    
# perc_poff15_non_loyalty_storewide_coupon_saved_amt_trips_flag         -0.0007326  0.0088576  -0.083 0.934102    
# perc_poff30_non_loyalty_storewide_coupon_saved_amt_trips_flag          0.0140182  0.0089829   1.561 0.119011    
# perc_d10off10_non_loyalty_storewide_coupon_saved_amt_trips_flag       -0.0059066  0.0084108  -0.702 0.482713    
# perc_poff50_non_loyalty_storewide_coupon_saved_amt_trips_flag          0.0101549  0.0221243   0.459 0.646360    
# perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips_flag -0.0026285  0.0093240  -0.282 0.778085    
# perc_business_specific_non_jewelry_coupon_saved_amt_trips_flag        -0.0020364  0.0090695  -0.225 0.822399    
# perc_storewide_poff_coupon_saved_amt_trips_flag                       -0.0146550  0.0093407  -1.569 0.117043    
# basket_size_trend_log                                                  1.1927582  0.0639587  18.649  < 2e-16 ***

##calculate the baseline basket
cpn_baseline_data$log_base_basket <-(
  cpn_baseline_data$log_avg_baseket_size-
    cpn_baseline_data$per_total_saved_log*(-0.228734) +
    cpn_baseline_data$perc_saved_w_non_coupon_log*(-0.228734) -
    cpn_baseline_data$perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips * (-0.040193) - 
    cpn_baseline_data$perc_d10off10_loyalty_storewide_coupon_saved_amt_trips * (-0.012291) - 
    cpn_baseline_data$perc_d10off25_non_loyalty_storewide_coupon_saved_amt_trips * (0.022834 ) - 
    cpn_baseline_data$perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips * (0.001170) - 
    cpn_baseline_data$perc_poff40_non_loyalty_storewide_coupon_saved_amt_trips * ( 0.002625) - 
    cpn_baseline_data$perc_poff10_non_loyalty_storewide_coupon_saved_amt_trips * ( -0.009105) -  
    cpn_baseline_data$perc_business_specific_jewelry_coupon_saved_amt_trips * ( 0.008396) - 
    cpn_baseline_data$perc_storewide_doff_coupon_saved_amt_trips * (0.007851 ) - 
    cpn_baseline_data$perc_poff15_non_loyalty_storewide_coupon_saved_amt_trips * (-0.004689 ) - 
    cpn_baseline_data$perc_poff30_non_loyalty_storewide_coupon_saved_amt_trips * ( 0.012572  ) - 
    cpn_baseline_data$perc_d10off10_non_loyalty_storewide_coupon_saved_amt_trips * ( -0.005391) - 
    cpn_baseline_data$perc_poff50_non_loyalty_storewide_coupon_saved_amt_trips * (-0.011350) - 
    cpn_baseline_data$perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips * ( 0.004697) - 
    cpn_baseline_data$perc_business_specific_non_jewelry_coupon_saved_amt_trips * ( -0.004637 ) - 
    cpn_baseline_data$perc_storewide_poff_coupon_saved_amt_trips * (-0.010346) 
)


cpn_baseline_data$base_basket_size <- exp(cpn_baseline_data$log_base_basket)
##merge with the coupon sales data,primary discount data  
cpn_baseline_data_w_sales <- merge(cpn_baseline_data,cpn_data_sales , by = "tran_datetime")
cpn_baseline_data_w_sales_primary_discount <- merge(cpn_baseline_data_w_sales,cpn_primary_sales , by = "tran_datetime")
##get the non coupon basket size
cpn_baseline_data_w_sales_primary_discount$non_coupon_basket <- cpn_baseline_data_w_sales_primary_discount$non_coupon_rev/cpn_baseline_data_w_sales_primary_discount$non_coupon_trips



##############        04. Baseline revenue and margin simulation             #####################################


##############        Calculate the average non-coupon basket and baseline for the days that running such coupon
cpn_baseline_data_w_sales_primary_discount$baseline_rev_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$non_coupon_rev +(cpn_baseline_data_w_sales_primary_discount$poff20_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$trip_incre_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips) * cpn_baseline_data_w_sales_primary_discount$base_basket_size
cpn_baseline_data_w_sales_primary_discount$baseline_rev_perc_d10off10_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$non_coupon_rev +(cpn_baseline_data_w_sales_primary_discount$d10off10_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$trip_incre_perc_d10off10_loyalty_storewide_coupon_saved_amt_trips) * cpn_baseline_data_w_sales_primary_discount$base_basket_size
cpn_baseline_data_w_sales_primary_discount$baseline_rev_perc_d10off25_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$non_coupon_rev +(cpn_baseline_data_w_sales_primary_discount$d10off25_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$trip_incre_perc_d10off25_non_loyalty_storewide_coupon_saved_amt_trips) *cpn_baseline_data_w_sales_primary_discount$base_basket_size
cpn_baseline_data_w_sales_primary_discount$baseline_rev_perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$non_coupon_rev +(cpn_baseline_data_w_sales_primary_discount$poff25_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$trip_incre_perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips) * cpn_baseline_data_w_sales_primary_discount$base_basket_size
cpn_baseline_data_w_sales_primary_discount$baseline_rev_perc_poff40_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$non_coupon_rev +(cpn_baseline_data_w_sales_primary_discount$poff40_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$trip_incre_perc_poff40_non_loyalty_storewide_coupon_saved_amt_trips) * cpn_baseline_data_w_sales_primary_discount$base_basket_size
cpn_baseline_data_w_sales_primary_discount$baseline_rev_perc_poff10_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$non_coupon_rev +(cpn_baseline_data_w_sales_primary_discount$poff10_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$trip_incre_perc_poff10_non_loyalty_storewide_coupon_saved_amt_trips) * cpn_baseline_data_w_sales_primary_discount$base_basket_size
cpn_baseline_data_w_sales_primary_discount$baseline_rev_perc_business_specific_jewelry_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$non_coupon_rev +(cpn_baseline_data_w_sales_primary_discount$business_specific_jewelry_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$trip_incre_perc_business_specific_jewelry_coupon_saved_amt_trips) * cpn_baseline_data_w_sales_primary_discount$base_basket_size
cpn_baseline_data_w_sales_primary_discount$baseline_rev_perc_storewide_doff_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$non_coupon_rev +(cpn_baseline_data_w_sales_primary_discount$storewide_doff_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$trip_incre_perc_storewide_doff_coupon_saved_amt_trips) * cpn_baseline_data_w_sales_primary_discount$base_basket_size
cpn_baseline_data_w_sales_primary_discount$baseline_rev_perc_poff15_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$non_coupon_rev +(cpn_baseline_data_w_sales_primary_discount$poff15_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$trip_incre_perc_poff15_non_loyalty_storewide_coupon_saved_amt_trips) * cpn_baseline_data_w_sales_primary_discount$base_basket_size
cpn_baseline_data_w_sales_primary_discount$baseline_rev_perc_poff30_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$non_coupon_rev +(cpn_baseline_data_w_sales_primary_discount$poff30_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$trip_incre_perc_poff30_non_loyalty_storewide_coupon_saved_amt_trips) * cpn_baseline_data_w_sales_primary_discount$base_basket_size
cpn_baseline_data_w_sales_primary_discount$baseline_rev_perc_d10off10_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$non_coupon_rev +(cpn_baseline_data_w_sales_primary_discount$d10off10_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$trip_incre_perc_d10off10_non_loyalty_storewide_coupon_saved_amt_trips) * cpn_baseline_data_w_sales_primary_discount$base_basket_size
cpn_baseline_data_w_sales_primary_discount$baseline_rev_perc_poff50_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$non_coupon_rev +(cpn_baseline_data_w_sales_primary_discount$poff50_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$trip_incre_perc_poff50_non_loyalty_storewide_coupon_saved_amt_trips) * cpn_baseline_data_w_sales_primary_discount$base_basket_size
cpn_baseline_data_w_sales_primary_discount$baseline_rev_perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$non_coupon_rev +(cpn_baseline_data_w_sales_primary_discount$poff20_non_loyalty_business_specific_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$trip_incre_perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips) * cpn_baseline_data_w_sales_primary_discount$base_basket_size
cpn_baseline_data_w_sales_primary_discount$baseline_rev_perc_business_specific_non_jewelry_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$non_coupon_rev +(cpn_baseline_data_w_sales_primary_discount$business_specific_non_jewelry_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$trip_incre_perc_business_specific_non_jewelry_coupon_saved_amt_trips) * cpn_baseline_data_w_sales_primary_discount$base_basket_size
cpn_baseline_data_w_sales_primary_discount$baseline_rev_perc_storewide_poff_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$non_coupon_rev +(cpn_baseline_data_w_sales_primary_discount$storewide_poff_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$trip_incre_perc_storewide_poff_coupon_saved_amt_trips) * cpn_baseline_data_w_sales_primary_discount$base_basket_size


##############       Calculate the new revenue for each coupon group

cpn_baseline_data_w_sales_primary_discount$rev_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$poff20_non_loyalty_storewide_coupon_saved_sales+cpn_baseline_data_w_sales_primary_discount$non_coupon_rev
cpn_baseline_data_w_sales_primary_discount$rev_perc_d10off10_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$d10off10_loyalty_storewide_coupon_saved_sales+cpn_baseline_data_w_sales_primary_discount$non_coupon_rev
cpn_baseline_data_w_sales_primary_discount$rev_perc_d10off25_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$d10off25_non_loyalty_storewide_coupon_saved_sales+cpn_baseline_data_w_sales_primary_discount$non_coupon_rev
cpn_baseline_data_w_sales_primary_discount$rev_perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$poff25_non_loyalty_storewide_coupon_saved_sales+cpn_baseline_data_w_sales_primary_discount$non_coupon_rev
cpn_baseline_data_w_sales_primary_discount$rev_perc_poff40_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$poff40_non_loyalty_storewide_coupon_saved_sales+cpn_baseline_data_w_sales_primary_discount$non_coupon_rev
cpn_baseline_data_w_sales_primary_discount$rev_perc_poff10_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$poff10_non_loyalty_storewide_coupon_saved_sales+cpn_baseline_data_w_sales_primary_discount$non_coupon_rev
cpn_baseline_data_w_sales_primary_discount$rev_perc_business_specific_jewelry_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$business_specific_jewelry_coupon_saved_sales+cpn_baseline_data_w_sales_primary_discount$non_coupon_rev
cpn_baseline_data_w_sales_primary_discount$rev_perc_storewide_doff_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$storewide_doff_coupon_saved_sales+cpn_baseline_data_w_sales_primary_discount$non_coupon_rev
cpn_baseline_data_w_sales_primary_discount$rev_perc_poff15_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$poff15_non_loyalty_storewide_coupon_saved_sales+cpn_baseline_data_w_sales_primary_discount$non_coupon_rev
cpn_baseline_data_w_sales_primary_discount$rev_perc_poff30_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$poff30_non_loyalty_storewide_coupon_saved_sales+cpn_baseline_data_w_sales_primary_discount$non_coupon_rev
cpn_baseline_data_w_sales_primary_discount$rev_perc_d10off10_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$d10off10_non_loyalty_storewide_coupon_saved_sales+cpn_baseline_data_w_sales_primary_discount$non_coupon_rev
cpn_baseline_data_w_sales_primary_discount$rev_perc_poff50_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$poff50_non_loyalty_storewide_coupon_saved_sales+cpn_baseline_data_w_sales_primary_discount$non_coupon_rev
cpn_baseline_data_w_sales_primary_discount$rev_perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$poff20_non_loyalty_business_specific_coupon_saved_sales+cpn_baseline_data_w_sales_primary_discount$non_coupon_rev
cpn_baseline_data_w_sales_primary_discount$rev_perc_business_specific_non_jewelry_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$business_specific_non_jewelry_coupon_saved_sales+cpn_baseline_data_w_sales_primary_discount$non_coupon_rev
cpn_baseline_data_w_sales_primary_discount$rev_perc_storewide_poff_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$storewide_poff_coupon_saved_sales+cpn_baseline_data_w_sales_primary_discount$non_coupon_rev


##############       Calculate the incremental revenue for each coupon group

cpn_baseline_data_w_sales_primary_discount$rev_incre_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$rev_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$baseline_rev_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips
cpn_baseline_data_w_sales_primary_discount$rev_incre_perc_d10off10_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$rev_perc_d10off10_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$baseline_rev_perc_d10off10_loyalty_storewide_coupon_saved_amt_trips
cpn_baseline_data_w_sales_primary_discount$rev_incre_perc_d10off25_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$rev_perc_d10off25_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$baseline_rev_perc_d10off25_non_loyalty_storewide_coupon_saved_amt_trips
cpn_baseline_data_w_sales_primary_discount$rev_incre_perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$rev_perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$baseline_rev_perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips
cpn_baseline_data_w_sales_primary_discount$rev_incre_perc_poff40_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$rev_perc_poff40_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$baseline_rev_perc_poff40_non_loyalty_storewide_coupon_saved_amt_trips
cpn_baseline_data_w_sales_primary_discount$rev_incre_perc_poff10_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$rev_perc_poff10_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$baseline_rev_perc_poff10_non_loyalty_storewide_coupon_saved_amt_trips
cpn_baseline_data_w_sales_primary_discount$rev_incre_perc_business_specific_jewelry_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$rev_perc_business_specific_jewelry_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$baseline_rev_perc_business_specific_jewelry_coupon_saved_amt_trips
cpn_baseline_data_w_sales_primary_discount$rev_incre_perc_storewide_doff_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$rev_perc_storewide_doff_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$baseline_rev_perc_storewide_doff_coupon_saved_amt_trips
cpn_baseline_data_w_sales_primary_discount$rev_incre_perc_poff15_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$rev_perc_poff15_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$baseline_rev_perc_poff15_non_loyalty_storewide_coupon_saved_amt_trips
cpn_baseline_data_w_sales_primary_discount$rev_incre_perc_poff30_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$rev_perc_poff30_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$baseline_rev_perc_poff30_non_loyalty_storewide_coupon_saved_amt_trips
cpn_baseline_data_w_sales_primary_discount$rev_incre_perc_d10off10_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$rev_perc_d10off10_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$baseline_rev_perc_d10off10_non_loyalty_storewide_coupon_saved_amt_trips
cpn_baseline_data_w_sales_primary_discount$rev_incre_perc_poff50_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$rev_perc_poff50_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$baseline_rev_perc_poff50_non_loyalty_storewide_coupon_saved_amt_trips
cpn_baseline_data_w_sales_primary_discount$rev_incre_perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$rev_perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$baseline_rev_perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips
cpn_baseline_data_w_sales_primary_discount$rev_incre_perc_business_specific_non_jewelry_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$rev_perc_business_specific_non_jewelry_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$baseline_rev_perc_business_specific_non_jewelry_coupon_saved_amt_trips
cpn_baseline_data_w_sales_primary_discount$rev_incre_perc_storewide_poff_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$rev_perc_storewide_poff_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$baseline_rev_perc_storewide_poff_coupon_saved_amt_trips


##############       Calculate the baseline margin for each coupon group

cpn_baseline_data_w_sales_primary_discount$baseline_margin_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$baseline_rev_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$non_coupon_cogs-(cpn_baseline_data_w_sales_primary_discount$poff20_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$trip_incre_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips) * cpn_baseline_data_w_sales_primary_discount$non_coupon_cogs/cpn_baseline_data_w_sales_primary_discount$non_coupon_trips * cpn_baseline_data_w_sales_primary_discount$base_basket_size/cpn_baseline_data_w_sales_primary_discount$non_coupon_basket
cpn_baseline_data_w_sales_primary_discount$baseline_margin_perc_d10off10_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$baseline_rev_perc_d10off10_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$non_coupon_cogs-(cpn_baseline_data_w_sales_primary_discount$d10off10_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$trip_incre_perc_d10off10_loyalty_storewide_coupon_saved_amt_trips) * cpn_baseline_data_w_sales_primary_discount$non_coupon_cogs/cpn_baseline_data_w_sales_primary_discount$non_coupon_trips* cpn_baseline_data_w_sales_primary_discount$base_basket_size/cpn_baseline_data_w_sales_primary_discount$non_coupon_basket
cpn_baseline_data_w_sales_primary_discount$baseline_margin_perc_d10off25_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$baseline_rev_perc_d10off25_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$non_coupon_cogs-(cpn_baseline_data_w_sales_primary_discount$d10off25_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$trip_incre_perc_d10off25_non_loyalty_storewide_coupon_saved_amt_trips) * cpn_baseline_data_w_sales_primary_discount$non_coupon_cogs/cpn_baseline_data_w_sales_primary_discount$non_coupon_trips* cpn_baseline_data_w_sales_primary_discount$base_basket_size/cpn_baseline_data_w_sales_primary_discount$non_coupon_basket
cpn_baseline_data_w_sales_primary_discount$baseline_margin_perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$baseline_rev_perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$non_coupon_cogs-(cpn_baseline_data_w_sales_primary_discount$poff25_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$trip_incre_perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips) * cpn_baseline_data_w_sales_primary_discount$non_coupon_cogs/cpn_baseline_data_w_sales_primary_discount$non_coupon_trips* cpn_baseline_data_w_sales_primary_discount$base_basket_size/cpn_baseline_data_w_sales_primary_discount$non_coupon_basket
cpn_baseline_data_w_sales_primary_discount$baseline_margin_perc_poff40_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$baseline_rev_perc_poff40_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$non_coupon_cogs-(cpn_baseline_data_w_sales_primary_discount$poff40_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$trip_incre_perc_poff40_non_loyalty_storewide_coupon_saved_amt_trips) * cpn_baseline_data_w_sales_primary_discount$non_coupon_cogs/cpn_baseline_data_w_sales_primary_discount$non_coupon_trips* cpn_baseline_data_w_sales_primary_discount$base_basket_size/cpn_baseline_data_w_sales_primary_discount$non_coupon_basket
cpn_baseline_data_w_sales_primary_discount$baseline_margin_perc_poff10_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$baseline_rev_perc_poff10_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$non_coupon_cogs-(cpn_baseline_data_w_sales_primary_discount$poff10_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$trip_incre_perc_poff10_non_loyalty_storewide_coupon_saved_amt_trips) * cpn_baseline_data_w_sales_primary_discount$non_coupon_cogs/cpn_baseline_data_w_sales_primary_discount$non_coupon_trips* cpn_baseline_data_w_sales_primary_discount$base_basket_size/cpn_baseline_data_w_sales_primary_discount$non_coupon_basket
cpn_baseline_data_w_sales_primary_discount$baseline_margin_perc_business_specific_jewelry_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$baseline_rev_perc_business_specific_jewelry_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$non_coupon_cogs-(cpn_baseline_data_w_sales_primary_discount$business_specific_jewelry_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$trip_incre_perc_business_specific_jewelry_coupon_saved_amt_trips) * cpn_baseline_data_w_sales_primary_discount$non_coupon_cogs/cpn_baseline_data_w_sales_primary_discount$non_coupon_trips* cpn_baseline_data_w_sales_primary_discount$base_basket_size/cpn_baseline_data_w_sales_primary_discount$non_coupon_basket
cpn_baseline_data_w_sales_primary_discount$baseline_margin_perc_storewide_doff_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$baseline_rev_perc_storewide_doff_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$non_coupon_cogs-(cpn_baseline_data_w_sales_primary_discount$storewide_doff_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$trip_incre_perc_storewide_doff_coupon_saved_amt_trips) * cpn_baseline_data_w_sales_primary_discount$non_coupon_cogs/cpn_baseline_data_w_sales_primary_discount$non_coupon_trips* cpn_baseline_data_w_sales_primary_discount$base_basket_size/cpn_baseline_data_w_sales_primary_discount$non_coupon_basket
cpn_baseline_data_w_sales_primary_discount$baseline_margin_perc_poff15_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$baseline_rev_perc_poff15_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$non_coupon_cogs-(cpn_baseline_data_w_sales_primary_discount$poff15_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$trip_incre_perc_poff15_non_loyalty_storewide_coupon_saved_amt_trips) * cpn_baseline_data_w_sales_primary_discount$non_coupon_cogs/cpn_baseline_data_w_sales_primary_discount$non_coupon_trips* cpn_baseline_data_w_sales_primary_discount$base_basket_size/cpn_baseline_data_w_sales_primary_discount$non_coupon_basket
cpn_baseline_data_w_sales_primary_discount$baseline_margin_perc_poff30_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$baseline_rev_perc_poff30_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$non_coupon_cogs-(cpn_baseline_data_w_sales_primary_discount$poff30_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$trip_incre_perc_poff30_non_loyalty_storewide_coupon_saved_amt_trips) * cpn_baseline_data_w_sales_primary_discount$non_coupon_cogs/cpn_baseline_data_w_sales_primary_discount$non_coupon_trips* cpn_baseline_data_w_sales_primary_discount$base_basket_size/cpn_baseline_data_w_sales_primary_discount$non_coupon_basket
cpn_baseline_data_w_sales_primary_discount$baseline_margin_perc_d10off10_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$baseline_rev_perc_d10off10_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$non_coupon_cogs-(cpn_baseline_data_w_sales_primary_discount$d10off10_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$trip_incre_perc_d10off10_non_loyalty_storewide_coupon_saved_amt_trips) * cpn_baseline_data_w_sales_primary_discount$non_coupon_cogs/cpn_baseline_data_w_sales_primary_discount$non_coupon_trips* cpn_baseline_data_w_sales_primary_discount$base_basket_size/cpn_baseline_data_w_sales_primary_discount$non_coupon_basket
cpn_baseline_data_w_sales_primary_discount$baseline_margin_perc_poff50_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$baseline_rev_perc_poff50_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$non_coupon_cogs-(cpn_baseline_data_w_sales_primary_discount$poff50_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$trip_incre_perc_poff50_non_loyalty_storewide_coupon_saved_amt_trips) * cpn_baseline_data_w_sales_primary_discount$non_coupon_cogs/cpn_baseline_data_w_sales_primary_discount$non_coupon_trips* cpn_baseline_data_w_sales_primary_discount$base_basket_size/cpn_baseline_data_w_sales_primary_discount$non_coupon_basket
cpn_baseline_data_w_sales_primary_discount$baseline_margin_perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$baseline_rev_perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$non_coupon_cogs-(cpn_baseline_data_w_sales_primary_discount$poff20_non_loyalty_business_specific_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$trip_incre_perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips) * cpn_baseline_data_w_sales_primary_discount$non_coupon_cogs/cpn_baseline_data_w_sales_primary_discount$non_coupon_trips* cpn_baseline_data_w_sales_primary_discount$base_basket_size/cpn_baseline_data_w_sales_primary_discount$non_coupon_basket
cpn_baseline_data_w_sales_primary_discount$baseline_margin_perc_business_specific_non_jewelry_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$baseline_rev_perc_business_specific_non_jewelry_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$non_coupon_cogs-(cpn_baseline_data_w_sales_primary_discount$business_specific_non_jewelry_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$trip_incre_perc_business_specific_non_jewelry_coupon_saved_amt_trips) * cpn_baseline_data_w_sales_primary_discount$non_coupon_cogs/cpn_baseline_data_w_sales_primary_discount$non_coupon_trips* cpn_baseline_data_w_sales_primary_discount$base_basket_size/cpn_baseline_data_w_sales_primary_discount$non_coupon_basket
cpn_baseline_data_w_sales_primary_discount$baseline_margin_perc_storewide_poff_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$baseline_rev_perc_storewide_poff_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$non_coupon_cogs-(cpn_baseline_data_w_sales_primary_discount$storewide_poff_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$trip_incre_perc_storewide_poff_coupon_saved_amt_trips) * cpn_baseline_data_w_sales_primary_discount$non_coupon_cogs/cpn_baseline_data_w_sales_primary_discount$non_coupon_trips* cpn_baseline_data_w_sales_primary_discount$base_basket_size/cpn_baseline_data_w_sales_primary_discount$non_coupon_basket

##############       Calculate the new margin for each coupon group

cpn_baseline_data_w_sales_primary_discount$margin_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$rev_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$non_coupon_cogs-cpn_baseline_data_w_sales_primary_discount$poff20_non_loyalty_storewide_coupon_saved_total_cogs
cpn_baseline_data_w_sales_primary_discount$margin_perc_d10off10_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$rev_perc_d10off10_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$non_coupon_cogs-cpn_baseline_data_w_sales_primary_discount$d10off10_loyalty_storewide_coupon_saved_total_cogs
cpn_baseline_data_w_sales_primary_discount$margin_perc_d10off25_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$rev_perc_d10off25_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$non_coupon_cogs-cpn_baseline_data_w_sales_primary_discount$d10off25_non_loyalty_storewide_coupon_saved_total_cogs
cpn_baseline_data_w_sales_primary_discount$margin_perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$rev_perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$non_coupon_cogs-cpn_baseline_data_w_sales_primary_discount$poff25_non_loyalty_storewide_coupon_saved_total_cogs
cpn_baseline_data_w_sales_primary_discount$margin_perc_poff40_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$rev_perc_poff40_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$non_coupon_cogs-cpn_baseline_data_w_sales_primary_discount$poff40_non_loyalty_storewide_coupon_saved_total_cogs
cpn_baseline_data_w_sales_primary_discount$margin_perc_poff10_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$rev_perc_poff10_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$non_coupon_cogs-cpn_baseline_data_w_sales_primary_discount$poff10_non_loyalty_storewide_coupon_saved_total_cogs
cpn_baseline_data_w_sales_primary_discount$margin_perc_business_specific_jewelry_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$rev_perc_business_specific_jewelry_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$non_coupon_cogs-cpn_baseline_data_w_sales_primary_discount$business_specific_jewelry_coupon_saved_total_cogs
cpn_baseline_data_w_sales_primary_discount$margin_perc_storewide_doff_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$rev_perc_storewide_doff_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$non_coupon_cogs-cpn_baseline_data_w_sales_primary_discount$storewide_doff_coupon_saved_total_cogs
cpn_baseline_data_w_sales_primary_discount$margin_perc_poff15_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$rev_perc_poff15_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$non_coupon_cogs-cpn_baseline_data_w_sales_primary_discount$poff15_non_loyalty_storewide_coupon_saved_total_cogs
cpn_baseline_data_w_sales_primary_discount$margin_perc_poff30_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$rev_perc_poff30_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$non_coupon_cogs-cpn_baseline_data_w_sales_primary_discount$poff30_non_loyalty_storewide_coupon_saved_total_cogs
cpn_baseline_data_w_sales_primary_discount$margin_perc_d10off10_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$rev_perc_d10off10_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$non_coupon_cogs-cpn_baseline_data_w_sales_primary_discount$d10off10_non_loyalty_storewide_coupon_saved_total_cogs
cpn_baseline_data_w_sales_primary_discount$margin_perc_poff50_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$rev_perc_poff50_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$non_coupon_cogs-cpn_baseline_data_w_sales_primary_discount$poff50_non_loyalty_storewide_coupon_saved_total_cogs
cpn_baseline_data_w_sales_primary_discount$margin_perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$rev_perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$non_coupon_cogs-cpn_baseline_data_w_sales_primary_discount$poff20_non_loyalty_business_specific_coupon_saved_total_cogs
cpn_baseline_data_w_sales_primary_discount$margin_perc_business_specific_non_jewelry_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$rev_perc_business_specific_non_jewelry_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$non_coupon_cogs-cpn_baseline_data_w_sales_primary_discount$business_specific_non_jewelry_coupon_saved_total_cogs
cpn_baseline_data_w_sales_primary_discount$margin_perc_storewide_poff_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$rev_perc_storewide_poff_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$non_coupon_cogs-cpn_baseline_data_w_sales_primary_discount$storewide_poff_coupon_saved_total_cogs

##############       Calculate the incremental margin for each coupon group

cpn_baseline_data_w_sales_primary_discount$margin_incre_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$margin_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$baseline_margin_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips
cpn_baseline_data_w_sales_primary_discount$margin_incre_perc_d10off10_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$margin_perc_d10off10_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$baseline_margin_perc_d10off10_loyalty_storewide_coupon_saved_amt_trips
cpn_baseline_data_w_sales_primary_discount$margin_incre_perc_d10off25_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$margin_perc_d10off25_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$baseline_margin_perc_d10off25_non_loyalty_storewide_coupon_saved_amt_trips
cpn_baseline_data_w_sales_primary_discount$margin_incre_perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$margin_perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$baseline_margin_perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips
cpn_baseline_data_w_sales_primary_discount$margin_incre_perc_poff40_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$margin_perc_poff40_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$baseline_margin_perc_poff40_non_loyalty_storewide_coupon_saved_amt_trips
cpn_baseline_data_w_sales_primary_discount$margin_incre_perc_poff10_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$margin_perc_poff10_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$baseline_margin_perc_poff10_non_loyalty_storewide_coupon_saved_amt_trips
cpn_baseline_data_w_sales_primary_discount$margin_incre_perc_business_specific_jewelry_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$margin_perc_business_specific_jewelry_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$baseline_margin_perc_business_specific_jewelry_coupon_saved_amt_trips
cpn_baseline_data_w_sales_primary_discount$margin_incre_perc_storewide_doff_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$margin_perc_storewide_doff_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$baseline_margin_perc_storewide_doff_coupon_saved_amt_trips
cpn_baseline_data_w_sales_primary_discount$margin_incre_perc_poff15_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$margin_perc_poff15_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$baseline_margin_perc_poff15_non_loyalty_storewide_coupon_saved_amt_trips
cpn_baseline_data_w_sales_primary_discount$margin_incre_perc_poff30_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$margin_perc_poff30_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$baseline_margin_perc_poff30_non_loyalty_storewide_coupon_saved_amt_trips
cpn_baseline_data_w_sales_primary_discount$margin_incre_perc_d10off10_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$margin_perc_d10off10_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$baseline_margin_perc_d10off10_non_loyalty_storewide_coupon_saved_amt_trips
cpn_baseline_data_w_sales_primary_discount$margin_incre_perc_poff50_non_loyalty_storewide_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$margin_perc_poff50_non_loyalty_storewide_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$baseline_margin_perc_poff50_non_loyalty_storewide_coupon_saved_amt_trips
cpn_baseline_data_w_sales_primary_discount$margin_incre_perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$margin_perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$baseline_margin_perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips
cpn_baseline_data_w_sales_primary_discount$margin_incre_perc_business_specific_non_jewelry_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$margin_perc_business_specific_non_jewelry_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$baseline_margin_perc_business_specific_non_jewelry_coupon_saved_amt_trips
cpn_baseline_data_w_sales_primary_discount$margin_incre_perc_storewide_poff_coupon_saved_amt_trips<-cpn_baseline_data_w_sales_primary_discount$margin_perc_storewide_poff_coupon_saved_amt_trips - cpn_baseline_data_w_sales_primary_discount$baseline_margin_perc_storewide_poff_coupon_saved_amt_trips


##############        05. Summary campaign performance                       #####################################

cpn_baseline_data_w_sales_primary_discount[is.na(cpn_baseline_data_w_sales_primary_discount)] <- 0


##############        Joining the dates with campaign data 

#campaign_date_mapping$tran_datetime = as.Date(campaign_date_mapping$tran_datetime, "%m/%d/%Y")
cpn_baseline_data_w_sales_primary_discount_w_campaign <- merge(cpn_baseline_data_w_sales_primary_discount,campaign_date_mapping , by="tran_datetime", all.x = T)


#cpn_baseline_data_w_sales_primary_discount_w_campaign1 <- merge(cpn_baseline_data_w_sales_primary_discount,campaign_date_mapping , by.x = c(as.POSIXct(as.numeric(as.character("tran_datetime")),origin = "1970-01-01")), by.y=c("tran_datetime"), all.x = T)

##View(as.POSIXct(as.numeric(as.character(cpn_baseline_data_w_sales_primary_discount$tran_datetime)),origin = "1970-01-01"))

##as.POSIXct(as.numeric(as.character(nakamura$AddedDate)),origin = "1970-01-01")

##class(cpn_baseline_data_w_sales_primary_discount_w_campaign$tran_datetime)
##############        Summarizing the campaign performance with corresponding coupon groups
##############        Update the following ifelse statement if the current logic doesn't cover new coupon campaigns

#cpn_baseline_data_w_sales_primary_discount_w_campaign$tran_datetime1 <- as.Date(class(cpn_baseline_data_w_sales_primary_discount_w_campaign$tran_datetime))

##filter on the date 
campaign_summary1 <- cpn_baseline_data_w_sales_primary_discount_w_campaign %>%
  filter(tran_datetime >= as.Date("2020-02-02") & tran_datetime <= as.Date("2020-03-07"))

## aggregate the data at the campaign level
campaign_summary1$total_primary_trips_coupon_redeemed <- ifelse(campaign_summary1$Coupon.flag.day == "$10 off $25 OR Ex20% off jcp", campaign_summary1$d10off25_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$poff20_non_loyalty_business_specific_coupon_saved_amt_trips + campaign_summary1$poff20_non_loyalty_storewide_coupon_saved_amt_trips,
                                                                ifelse(campaign_summary1$Coupon.flag.day == "30%/40%/50% any MOP single U&K", campaign_summary1$poff30_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$poff40_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$poff50_non_loyalty_storewide_coupon_saved_amt_trips,
                                                                       ifelse(campaign_summary1$Coupon.flag.day == "20%/30%,/40% any MOP single U&K", campaign_summary1$poff30_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$poff40_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$poff20_non_loyalty_storewide_coupon_saved_amt_trips,##### added new coupon in week 40
                                                                              ifelse(campaign_summary1$Coupon.flag.day == "Ex20% off jcp, 15% off other MOP", campaign_summary1$poff15_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$poff20_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$poff20_non_loyalty_business_specific_coupon_saved_amt_trips,
                                                                                     ifelse(campaign_summary1$Coupon.flag.day == "$10 off $25" , campaign_summary1$d10off25_non_loyalty_storewide_coupon_saved_amt_trips ,
                                                                                            ifelse(campaign_summary1$Coupon.flag.day == "Ex20% off any MOP", campaign_summary1$poff20_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$poff20_non_loyalty_business_specific_coupon_saved_amt_trips,
                                                                                                   ifelse(campaign_summary1$Coupon.flag.day == "20% off JCP, Ex15% other; 25% off >$100", campaign_summary1$poff25_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$poff15_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$poff20_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$poff20_non_loyalty_business_specific_coupon_saved_amt_trips,
                                                                                                          ifelse(campaign_summary1$Coupon.flag.day == "Ex25% JCP, Ex20% off other MOP", campaign_summary1$poff25_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$poff20_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$poff20_non_loyalty_business_specific_coupon_saved_amt_trips,#
                                                                                                                 ifelse(campaign_summary1$Coupon.flag.day == "Ex25% off any MOP", campaign_summary1$poff25_non_loyalty_storewide_coupon_saved_amt_trips,#
                                                                                                                        ifelse(campaign_summary1$Coupon.flag.day == "Ex25% JCP, Ex20% off other MOP, Ex30%>$100", campaign_summary1$poff25_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$poff20_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$poff20_non_loyalty_business_specific_coupon_saved_amt_trips + campaign_summary1$poff30_non_loyalty_storewide_coupon_saved_amt_trips,#
                                                                                                                               ifelse(campaign_summary1$Coupon.flag.day %in% c("Ex25% off any MOP; Ex30% off >$100", "30% off JCP, Ex25% off other MOP", "Ex25% off any MOP; Ex30% off Rewards Members") , campaign_summary1$poff25_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$poff30_non_loyalty_storewide_coupon_saved_amt_trips ,
                                                                                                                                      ifelse(campaign_summary1$Coupon.flag.day == "Ex20% off any MOP; Ex25% off >$100" , campaign_summary1$poff25_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$poff20_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$poff20_non_loyalty_business_specific_coupon_saved_amt_trips,
                                                                                                                                             0))))))))))))

campaign_summary1$total_primary_trip_incremental <- ifelse(campaign_summary1$Coupon.flag.day == "$10 off $25 OR Ex20% off jcp", campaign_summary1$trip_incre_perc_d10off25_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$trip_incre_perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips + campaign_summary1$trip_incre_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips,
                                                           ifelse(campaign_summary1$Coupon.flag.day == "30%/40%/50% any MOP single U&K", campaign_summary1$trip_incre_perc_poff30_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$trip_incre_perc_poff40_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$trip_incre_perc_poff50_non_loyalty_storewide_coupon_saved_amt_trips,
                                                                  ifelse(campaign_summary1$Coupon.flag.day == "20%/30%,/40% any MOP single U&K", campaign_summary1$trip_incre_perc_poff30_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$trip_incre_perc_poff40_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$trip_incre_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips, ######
                                                                         ifelse(campaign_summary1$Coupon.flag.day == "Ex20% off jcp, 15% off other MOP", campaign_summary1$trip_incre_perc_poff15_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$trip_incre_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$trip_incre_perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips,
                                                                                ifelse(campaign_summary1$Coupon.flag.day == "$10 off $25" , campaign_summary1$trip_incre_perc_d10off25_non_loyalty_storewide_coupon_saved_amt_trips ,
                                                                                       ifelse(campaign_summary1$Coupon.flag.day == "Ex20% off any MOP", campaign_summary1$trip_incre_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$trip_incre_perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips,
                                                                                              ifelse(campaign_summary1$Coupon.flag.day == "20% off JCP, Ex15% other; 25% off >$100", campaign_summary1$trip_incre_perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$trip_incre_perc_poff15_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$trip_incre_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$trip_incre_perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips,
                                                                                                     ifelse(campaign_summary1$Coupon.flag.day == "Ex25% off any MOP", campaign_summary1$trip_incre_perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips,#
                                                                                                            ifelse(campaign_summary1$Coupon.flag.day == "Ex25% JCP, Ex20% off other MOP, Ex30%>$100", campaign_summary1$trip_incre_perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$trip_incre_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$trip_incre_perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips + campaign_summary1$trip_incre_perc_poff30_non_loyalty_storewide_coupon_saved_amt_trips,#
                                                                                                                   ifelse(campaign_summary1$Coupon.flag.day == "Ex25% JCP, Ex20% off other MOP", campaign_summary1$trip_incre_perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$trip_incre_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$trip_incre_perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips,#
                                                                                                                          ifelse(campaign_summary1$Coupon.flag.day %in% c("Ex25% off any MOP; Ex30% off >$100", "30% off JCP, Ex25% off other MOP", "Ex25% off any MOP; Ex30% off Rewards Members") , campaign_summary1$trip_incre_perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$trip_incre_perc_poff30_non_loyalty_storewide_coupon_saved_amt_trips ,
                                                                                                                                 ifelse(campaign_summary1$Coupon.flag.day == "Ex20% off any MOP; Ex25% off >$100" , campaign_summary1$trip_incre_perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$trip_incre_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$trip_incre_perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips,
                                                                                                                                        0))))))))))))



campaign_summary1$total_primary_revenue_coupon_redeemed <- ifelse(campaign_summary1$Coupon.flag.day == "$10 off $25 OR Ex20% off jcp", campaign_summary1$rev_perc_d10off25_non_loyalty_storewide_coupon_saved_amt_trips - campaign_summary1$non_coupon_rev  + campaign_summary1$rev_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips - campaign_summary1$non_coupon_rev + campaign_summary1$rev_perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips- campaign_summary1$non_coupon_rev ,
                                                                  ifelse(campaign_summary1$Coupon.flag.day == "30%/40%/50% any MOP single U&K", campaign_summary1$rev_perc_poff30_non_loyalty_storewide_coupon_saved_amt_trips- campaign_summary1$non_coupon_rev  + campaign_summary1$rev_perc_poff40_non_loyalty_storewide_coupon_saved_amt_trips- campaign_summary1$non_coupon_rev  + campaign_summary1$rev_perc_poff50_non_loyalty_storewide_coupon_saved_amt_trips- campaign_summary1$non_coupon_rev ,
                                                                         ifelse(campaign_summary1$Coupon.flag.day == "20%/30%,/40% any MOP single U&K", campaign_summary1$rev_perc_poff30_non_loyalty_storewide_coupon_saved_amt_trips - campaign_summary1$non_coupon_rev + campaign_summary1$rev_perc_poff40_non_loyalty_storewide_coupon_saved_amt_trips- campaign_summary1$non_coupon_rev  + campaign_summary1$rev_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips- campaign_summary1$non_coupon_rev , #####
                                                                                ifelse(campaign_summary1$Coupon.flag.day == "Ex20% off jcp, 15% off other MOP", campaign_summary1$rev_perc_poff15_non_loyalty_storewide_coupon_saved_amt_trips- campaign_summary1$non_coupon_rev  + campaign_summary1$rev_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips- campaign_summary1$non_coupon_rev  + campaign_summary1$rev_perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips- campaign_summary1$non_coupon_rev ,
                                                                                       ifelse(campaign_summary1$Coupon.flag.day == "$10 off $25" , campaign_summary1$rev_perc_d10off25_non_loyalty_storewide_coupon_saved_amt_trips- campaign_summary1$non_coupon_rev  ,
                                                                                              ifelse(campaign_summary1$Coupon.flag.day == "Ex20% off any MOP", campaign_summary1$rev_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips- campaign_summary1$non_coupon_rev  + campaign_summary1$rev_perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips- campaign_summary1$non_coupon_rev ,
                                                                                                     ifelse(campaign_summary1$Coupon.flag.day == "20% off JCP, Ex15% other; 25% off >$100", campaign_summary1$rev_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips- campaign_summary1$non_coupon_rev  + campaign_summary1$rev_perc_poff15_non_loyalty_storewide_coupon_saved_amt_trips - campaign_summary1$non_coupon_rev + campaign_summary1$rev_perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips - campaign_summary1$non_coupon_rev + campaign_summary1$rev_perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips- campaign_summary1$non_coupon_rev ,
                                                                                                            ifelse(campaign_summary1$Coupon.flag.day == "Ex25% off any MOP", campaign_summary1$rev_perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips- campaign_summary1$non_coupon_rev ,#
                                                                                                                   ifelse(campaign_summary1$Coupon.flag.day == "Ex25% JCP, Ex20% off other MOP, Ex30%>$100", campaign_summary1$rev_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips- campaign_summary1$non_coupon_rev  + campaign_summary1$rev_perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips- campaign_summary1$non_coupon_rev  + campaign_summary1$rev_perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips - campaign_summary1$non_coupon_rev + campaign_summary1$rev_perc_poff30_non_loyalty_storewide_coupon_saved_amt_trips- campaign_summary1$non_coupon_rev ,#
                                                                                                                          ifelse(campaign_summary1$Coupon.flag.day == "Ex25% JCP, Ex20% off other MOP", campaign_summary1$rev_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips- campaign_summary1$non_coupon_rev  + campaign_summary1$rev_perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips- campaign_summary1$non_coupon_rev  + campaign_summary1$rev_perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips- campaign_summary1$non_coupon_rev ,#
                                                                                                                                 ifelse(campaign_summary1$Coupon.flag.day %in% c("Ex25% off any MOP; Ex30% off >$100", "30% off JCP, Ex25% off other MOP", "Ex25% off any MOP; Ex30% off Rewards Members") , campaign_summary1$rev_perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips - campaign_summary1$non_coupon_rev + campaign_summary1$rev_perc_poff30_non_loyalty_storewide_coupon_saved_amt_trips - campaign_summary1$non_coupon_rev ,
                                                                                                                                        ifelse(campaign_summary1$Coupon.flag.day == "Ex20% off any MOP; Ex25% off >$100" , campaign_summary1$rev_perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips- campaign_summary1$non_coupon_rev  + campaign_summary1$rev_perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips- campaign_summary1$non_coupon_rev  + campaign_summary1$rev_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips- campaign_summary1$non_coupon_rev ,
                                                                                                                                               0))))))))))))





campaign_summary1$total_primary_revenue_incremental <- ifelse(campaign_summary1$Coupon.flag.day == "$10 off $25 OR Ex20% off jcp", campaign_summary1$rev_incre_perc_d10off25_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$rev_incre_perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips + campaign_summary1$rev_incre_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips,
                                                              ifelse(campaign_summary1$Coupon.flag.day == "30%/40%/50% any MOP single U&K", campaign_summary1$rev_incre_perc_poff30_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$rev_incre_perc_poff40_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$rev_incre_perc_poff50_non_loyalty_storewide_coupon_saved_amt_trips,
                                                                     ifelse(campaign_summary1$Coupon.flag.day == "20%/30%,/40% any MOP single U&K", campaign_summary1$rev_incre_perc_poff30_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$rev_incre_perc_poff40_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$rev_incre_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips, #####
                                                                            ifelse(campaign_summary1$Coupon.flag.day == "Ex20% off jcp, 15% off other MOP", campaign_summary1$rev_incre_perc_poff15_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$rev_incre_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$rev_incre_perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips,
                                                                                   ifelse(campaign_summary1$Coupon.flag.day == "$10 off $25" , campaign_summary1$rev_incre_perc_d10off25_non_loyalty_storewide_coupon_saved_amt_trips ,
                                                                                          ifelse(campaign_summary1$Coupon.flag.day == "Ex20% off any MOP", campaign_summary1$rev_incre_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$rev_incre_perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips,
                                                                                                 ifelse(campaign_summary1$Coupon.flag.day == "20% off JCP, Ex15% other; 25% off >$100", campaign_summary1$rev_incre_perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$rev_incre_perc_poff15_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$rev_incre_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$rev_incre_perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips,
                                                                                                        ifelse(campaign_summary1$Coupon.flag.day == "Ex25% off any MOP", campaign_summary1$rev_incre_perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips ,#
                                                                                                               ifelse(campaign_summary1$Coupon.flag.day == "Ex25% JCP, Ex20% off other MOP, Ex30%>$100", campaign_summary1$rev_incre_perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$rev_incre_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$rev_incre_perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips + campaign_summary1$rev_incre_perc_poff30_non_loyalty_storewide_coupon_saved_amt_trips,#
                                                                                                                      ifelse(campaign_summary1$Coupon.flag.day == "Ex25% JCP, Ex20% off other MOP", campaign_summary1$rev_incre_perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$rev_incre_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$rev_incre_perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips,#
                                                                                                                             ifelse(campaign_summary1$Coupon.flag.day %in% c("Ex25% off any MOP; Ex30% off >$100", "30% off JCP, Ex25% off other MOP", "Ex25% off any MOP; Ex30% off Rewards Members") , campaign_summary1$rev_incre_perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$rev_incre_perc_poff30_non_loyalty_storewide_coupon_saved_amt_trips ,
                                                                                                                                    ifelse(campaign_summary1$Coupon.flag.day == "Ex20% off any MOP; Ex25% off >$100" , campaign_summary1$rev_incre_perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$rev_incre_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$rev_incre_perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips,
                                                                                                                                           0))))))))))))

campaign_summary1$non_coupon_margin <- campaign_summary1$non_coupon_rev  -  campaign_summary1$non_coupon_cogs

campaign_summary1$total_primary_margin_coupon_redeemed <- ifelse(campaign_summary1$Coupon.flag.day == "$10 off $25 OR Ex20% off jcp", campaign_summary1$margin_perc_d10off25_non_loyalty_storewide_coupon_saved_amt_trips - campaign_summary1$non_coupon_margin+ campaign_summary1$margin_perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips- campaign_summary1$non_coupon_margin + campaign_summary1$margin_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips- campaign_summary1$non_coupon_margin,
                                                                 ifelse(campaign_summary1$Coupon.flag.day == "30%/40%/50% any MOP single U&K", campaign_summary1$margin_perc_poff30_non_loyalty_storewide_coupon_saved_amt_trips- campaign_summary1$non_coupon_margin + campaign_summary1$margin_perc_poff40_non_loyalty_storewide_coupon_saved_amt_trips- campaign_summary1$non_coupon_margin + campaign_summary1$margin_perc_poff50_non_loyalty_storewide_coupon_saved_amt_trips- campaign_summary1$non_coupon_margin,
                                                                        ifelse(campaign_summary1$Coupon.flag.day == "20%/30%,/40% any MOP single U&K", campaign_summary1$margin_perc_poff30_non_loyalty_storewide_coupon_saved_amt_trips- campaign_summary1$non_coupon_margin + campaign_summary1$margin_perc_poff40_non_loyalty_storewide_coupon_saved_amt_trips - campaign_summary1$non_coupon_margin+ campaign_summary1$margin_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips- campaign_summary1$non_coupon_margin, ####week 40
                                                                               ifelse(campaign_summary1$Coupon.flag.day == "Ex20% off jcp, 15% off other MOP", campaign_summary1$margin_perc_poff15_non_loyalty_storewide_coupon_saved_amt_trips - campaign_summary1$non_coupon_margin+ campaign_summary1$margin_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips - campaign_summary1$non_coupon_margin+ campaign_summary1$margin_perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips- campaign_summary1$non_coupon_margin,
                                                                                      ifelse(campaign_summary1$Coupon.flag.day == "$10 off $25" , campaign_summary1$margin_perc_d10off25_non_loyalty_storewide_coupon_saved_amt_trips - campaign_summary1$non_coupon_margin,
                                                                                             ifelse(campaign_summary1$Coupon.flag.day == "Ex20% off any MOP", campaign_summary1$margin_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips - campaign_summary1$non_coupon_margin+ campaign_summary1$margin_perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips- campaign_summary1$non_coupon_margin,
                                                                                                    ifelse(campaign_summary1$Coupon.flag.day == "20% off JCP, Ex15% other; 25% off >$100", campaign_summary1$margin_perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips- campaign_summary1$non_coupon_margin + campaign_summary1$margin_perc_poff15_non_loyalty_storewide_coupon_saved_amt_trips- campaign_summary1$non_coupon_margin + campaign_summary1$margin_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips - campaign_summary1$non_coupon_margin+ campaign_summary1$margin_perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips- campaign_summary1$non_coupon_margin,
                                                                                                           ifelse(campaign_summary1$Coupon.flag.day == "Ex25% off any MOP", campaign_summary1$margin_perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips- campaign_summary1$non_coupon_margin,#
                                                                                                                  ifelse(campaign_summary1$Coupon.flag.day == "Ex25% JCP, Ex20% off other MOP, Ex30%>$100", campaign_summary1$margin_perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips - campaign_summary1$non_coupon_margin + campaign_summary1$margin_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips - campaign_summary1$non_coupon_margin+ campaign_summary1$margin_perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips - campaign_summary1$non_coupon_margin+ campaign_summary1$margin_perc_poff30_non_loyalty_storewide_coupon_saved_amt_trips- campaign_summary1$non_coupon_margin,#
                                                                                                                         ifelse(campaign_summary1$Coupon.flag.day == "Ex25% JCP, Ex20% off other MOP", campaign_summary1$margin_perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips - campaign_summary1$non_coupon_margin + campaign_summary1$margin_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips - campaign_summary1$non_coupon_margin + campaign_summary1$margin_perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips- campaign_summary1$non_coupon_margin,#
                                                                                                                                ifelse(campaign_summary1$Coupon.flag.day %in% c("Ex25% off any MOP; Ex30% off >$100", "30% off JCP, Ex25% off other MOP", "Ex25% off any MOP; Ex30% off Rewards Members") , campaign_summary1$margin_perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips - campaign_summary1$non_coupon_margin + campaign_summary1$margin_perc_poff30_non_loyalty_storewide_coupon_saved_amt_trips - campaign_summary1$non_coupon_margin,
                                                                                                                                       ifelse(campaign_summary1$Coupon.flag.day == "Ex20% off any MOP; Ex25% off >$100" , campaign_summary1$margin_perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips - campaign_summary1$non_coupon_margin + campaign_summary1$margin_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips - campaign_summary1$non_coupon_margin + campaign_summary1$margin_perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips- campaign_summary1$non_coupon_margin,
                                                                                                                                              0))))))))))))

campaign_summary1$total_primary_margin_incremental <- ifelse(campaign_summary1$Coupon.flag.day == "$10 off $25 OR Ex20% off jcp", campaign_summary1$margin_incre_perc_d10off25_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$margin_incre_perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips + campaign_summary1$margin_incre_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips,
                                                             ifelse(campaign_summary1$Coupon.flag.day == "30%/40%/50% any MOP single U&K", campaign_summary1$margin_incre_perc_poff30_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$margin_incre_perc_poff40_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$margin_incre_perc_poff50_non_loyalty_storewide_coupon_saved_amt_trips,
                                                                    ifelse(campaign_summary1$Coupon.flag.day == "20%/30%,/40% any MOP single U&K", campaign_summary1$margin_incre_perc_poff30_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$margin_incre_perc_poff40_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$margin_incre_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips, ####
                                                                           ifelse(campaign_summary1$Coupon.flag.day == "Ex20% off jcp, 15% off other MOP", campaign_summary1$margin_incre_perc_poff15_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$margin_incre_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$margin_incre_perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips,
                                                                                  ifelse(campaign_summary1$Coupon.flag.day == "$10 off $25" , campaign_summary1$margin_incre_perc_d10off25_non_loyalty_storewide_coupon_saved_amt_trips ,
                                                                                         ifelse(campaign_summary1$Coupon.flag.day == "Ex20% off any MOP", campaign_summary1$margin_incre_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$margin_incre_perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips,
                                                                                                ifelse(campaign_summary1$Coupon.flag.day == "20% off JCP, Ex15% other; 25% off >$100", campaign_summary1$margin_incre_perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$margin_incre_perc_poff15_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$margin_incre_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$margin_incre_perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips,
                                                                                                       ifelse(campaign_summary1$Coupon.flag.day == "Ex25% off any MOP", campaign_summary1$margin_incre_perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips,#
                                                                                                              ifelse(campaign_summary1$Coupon.flag.day == "Ex25% JCP, Ex20% off other MOP, Ex30%>$100", campaign_summary1$margin_incre_perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$margin_incre_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$margin_incre_perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips + campaign_summary1$margin_incre_perc_poff30_non_loyalty_storewide_coupon_saved_amt_trip,#
                                                                                                                     ifelse(campaign_summary1$Coupon.flag.day == "Ex25% JCP, Ex20% off other MOP", campaign_summary1$margin_incre_perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$margin_incre_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$margin_incre_perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips,#
                                                                                                                            ifelse(campaign_summary1$Coupon.flag.day %in% c("Ex25% off any MOP; Ex30% off >$100", "30% off JCP, Ex25% off other MOP", "Ex25% off any MOP; Ex30% off Rewards Members") , campaign_summary1$margin_incre_perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$margin_incre_perc_poff30_non_loyalty_storewide_coupon_saved_amt_trips ,
                                                                                                                                   ifelse(campaign_summary1$Coupon.flag.day == "Ex20% off any MOP; Ex25% off >$100" , campaign_summary1$margin_incre_perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$margin_incre_perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips + campaign_summary1$margin_incre_perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips,
                                                                                                                                          0))))))))))))


campaign_summary1$overall_baseline_revenue <- campaign_summary1$non_coupon_rev + campaign_summary1$total_primary_revenue_coupon_redeemed - campaign_summary1$total_primary_revenue_incremental
campaign_summary1$overall_baseline_margin <- campaign_summary1$non_coupon_rev  -  campaign_summary1$non_coupon_cogs + campaign_summary1$total_primary_margin_coupon_redeemed - campaign_summary1$total_primary_margin_incremental
campaign_summary1$overall_baseline_trip <- campaign_summary1$base_trip

summary_columns <- which(grepl("tran_datetime", colnames(campaign_summary1))>0|grepl("Coupon.flag.day", colnames(campaign_summary1))>0 | grepl("total_primary", colnames(campaign_summary1))>0 |grepl("overall_baseline", colnames(campaign_summary1))>0 )

##############        Final output of summary

campaign_summary_clean <- campaign_summary1[, summary_columns]
##export the campaign summary and the coupon summary as model outputs
write.csv(campaign_summary1,"campaign_summary_20200319.csv")
write.csv(campaign_summary_clean, "coupon_summary_20200319.csv")
