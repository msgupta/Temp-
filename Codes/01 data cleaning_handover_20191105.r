##################################################################################################################
##################################################################################################################
#######################################  Overall Coupon effectiveness model#######################################
##############  There are two parts of the code:                             #####################################
################################################ 1 Data cleaning and model  ######################################
################################################ 2. Baseline generation ##########################################
##################################################################################################################
##############  This is the data cleaning and model session, which includes: #####################################
##############        01. Data input                                         #####################################
##############        02. Feature engineering                                #####################################
##############        03. Defining model structure and variables             #####################################
##############        04. Model                                              #####################################
##################################################################################################################
##################################################################################################################
############## The input of this moel is daily data,                         #####################################
############## which includes trip, basket, coupon redeemed trip info        #####################################
############## The output of this is just the coefficients from the model,   #####################################
############## which will be used for the baseline generation.               #####################################
##################################################################################################################
##################################################################################################################
##################################################################################################################
##################################################################################################################
##################################################################################################################

###Importing necessary libraries
library(data.table)
library(tidyverse)
library(tidylog)
library(dplyr)
library(lubridate)
library(car)

setwd("C:/Users/gsharma7/OneDrive - JC Penney/Mckinsey/new data/Data/4. Coupon - Elasticity/final coupon data/20200316")

#### 1.0  Data input ####
coupon_d <- fread("Overall_coupon_data_full_20200318.csv")

#### 2.0 Feature Engineering, create basic variables and redemption####
coupon_d_vF <- 
  coupon_d %>%
  mutate(
    # date # 
    tran_datetime = date(tran_datetime)
    , weekday = wday(date(coupon_d$tran_datetime))
    , weekend_flag = ifelse(as.character(weekday) %in% c(1, 6, 7), 1, 0)
    , month = month(date(tran_datetime))
    , per_total_saved = 1-(trip*avg_basket_size/p1_sales)
    , per_total_saved_log = log(1-(trip*avg_basket_size/p1_sales))
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
  replace(., is.na(.), 0) ## replace null to zeros in dataframe



###################################Coupon flag calculation and grouping###################

cpn_column_list <- which(grepl("perc",colnames(coupon_d_vF))>0 &grepl("trips",colnames(coupon_d_vF))>0) ##index of columns with the names with perc and trips in it

cpn_column_list

cpn_column_list1 <- which(grepl("perc",colnames(coupon_d_vF)) == 0 &grepl("trips",colnames(coupon_d_vF))>0)
cpn_column_list1 ## index of columns with trips in the names

category_model_data1 <- coupon_d_vF

#View(category_model_data1)
#cpn_column_list1

##View()

##taking median value to create trip flags when the percentage is >100 else no change in the percentage value
for (ii in 1:length(cpn_column_list)){
  median_value <- median(category_model_data1[which(category_model_data1[,cpn_column_list1[ii]] > 100),cpn_column_list[ii]])
  category_model_data1$new_col <- ifelse(category_model_data1[,cpn_column_list[ii]] > median_value, 1, 0)
  #category_model_data1$new_col <- ifelse(category_model_data1[,cpn_column_list[ii]] > 0.01, 1, 0)
  colnames(category_model_data1)[dim(category_model_data1)[2]] <- paste(colnames(category_model_data1)[cpn_column_list[ii]], "flag", sep='_') 
  print(c(median_value, median(category_model_data1[,cpn_column_list[ii]])))
}

flag_column_list <- which(grepl("trips_flag",colnames(category_model_data1))>0)

###combining correlated coupon flags
combined_coupon_index_15_20 <- which(colnames(category_model_data1) %in% c("perc_poff15_non_loyalty_storewide_coupon_saved_amt_trips_flag", 
                                                                           "perc_poff20_non_loyalty_storewide_coupon_saved_amt_trips_flag"
))

combined_coupon_index_30_50 <- which(colnames(category_model_data1) %in% c("perc_poff40_non_loyalty_storewide_coupon_saved_amt_trips_flag", 
                                                                           "perc_poff50_non_loyalty_storewide_coupon_saved_amt_trips_flag"))

flag_column_list_other <- which(colnames(category_model_data1) %in% c("perc_poff20_non_loyalty_business_specific_coupon_saved_amt_trips_flag",
                                                                      "perc_d10off25_non_loyalty_storewide_coupon_saved_amt_trips_flag",
                                                                      "perc_business_specific_jewelry_coupon_saved_amt_trips_flag"))

flag_column_10_off_10 <- which(colnames(category_model_data1) %in% c("perc_d10off10_loyalty_storewide_coupon_saved_amt_trips_flag", 
                                                                     "perc_poff30_non_loyalty_storewide_coupon_saved_amt_trips_flag"))

## taking the maximum value of the percentage after combining the trip flags
category_model_data1$flag_other <- do.call(pmax, category_model_data1[,flag_column_list_other])
category_model_data1$flag_15_20_non_loyalty_storewide <- do.call(pmax, category_model_data1[,combined_coupon_index_15_20])
category_model_data1$flag_30_50_non_loyalty_storewide <- do.call(pmax, category_model_data1[,combined_coupon_index_30_50])
category_model_data1$flag_column_10_off_10 <- do.call(pmax, category_model_data1[,flag_column_10_off_10])



##########################filter the outliers###########################

average_daily_trip <- mean(category_model_data1$trip)
average_basket_size <- mean(category_model_data1$avg_basket_size)
average_pct_saved <- mean(category_model_data1$per_total_saved)
#filters
category_model_data2 <- subset(category_model_data1, trip > average_daily_trip*0.1 & avg_basket_size < average_basket_size *2 & per_total_saved > average_pct_saved * 0.1)


################################Create Trend variable ############################
category_model_data2$DayofWeek <- lubridate::wday(as.Date(category_model_data2$tran_datetime))
time_series_data <- category_model_data2 %>% arrange(tran_datetime)
decomposedRes2 <- stl(ts(time_series_data$trip, frequency = 30), s.window = "per") # use type = "additive" for additive compon
trend_trip <- decomposedRes2$time.series[, 2]
decomposedRes3 <- stl(ts(time_series_data$avg_basket_size, frequency = 30), s.window = "per") # use type = "additive" for additive compon
trend_basket_size <- decomposedRes3$time.series[, 2]



category_model_data2 <- category_model_data2 %>% arrange(tran_datetime)

category_model_data2$trip_trend <- trend_trip
category_model_data2$basket_size_trend <- trend_basket_size

category_model_data2$trip_trend_log <- log(trend_trip)
category_model_data2$basket_size_trend_log <- log(trend_basket_size)



####################################Holiday######################################
#Halloween holiday
category_model_data2$hol_halo <- ifelse(category_model_data2$tran_datetime > as.Date("2017-10-26") & category_model_data2$tran_datetime < as.Date("2017-10-31"), 1 ,
                                        ifelse(category_model_data2$tran_datetime > as.Date("2018-10-25") & category_model_data2$tran_datetime < as.Date("2018-10-30"), 1 ,
                                               ifelse(category_model_data2$tran_datetime >= as.Date("2019-10-27") & category_model_data2$tran_datetime <= as.Date("2019-10-31"), 1 , 0)))
#Pre val holiday
category_model_data2$hol_pre_valen <- ifelse(category_model_data2$tran_datetime > as.Date("2018-02-09") & category_model_data2$tran_datetime < as.Date("2018-02-12"), 1 ,
                                             ifelse(category_model_data2$tran_datetime >= as.Date("2019-02-10") & category_model_data2$tran_datetime <= as.Date("2019-02-14"), 1 ,
                                                    ifelse(category_model_data2$tran_datetime >= as.Date("2020-02-09") & category_model_data2$tran_datetime <= as.Date("2020-02-14"), 1 , 0)))

#Thxgiving holiday
category_model_data2$hol_thx <- ifelse(category_model_data2$tran_datetime > as.Date("2017-11-22") & category_model_data2$tran_datetime < as.Date("2017-11-25"), 1 ,
                                       ifelse(category_model_data2$tran_datetime > as.Date("2018-11-21") & category_model_data2$tran_datetime < as.Date("2018-11-24"), 1 ,
                                              ifelse(category_model_data2$tran_datetime >= as.Date("2019-11-24") & category_model_data2$tran_datetime <= as.Date("2019-11-28"), 1 ,0)))

category_model_data2$hol_pre_thx <- ifelse(category_model_data2$tran_datetime > as.Date("2017-11-22") & category_model_data2$tran_datetime < as.Date("2017-11-24"), 1 ,
                                           ifelse(category_model_data2$tran_datetime > as.Date("2018-11-21") & category_model_data2$tran_datetime < as.Date("2018-11-23"), 1,
                                                  ifelse(category_model_data2$tran_datetime >= as.Date("2019-11-24") & category_model_data2$tran_datetime <= as.Date("2019-11-27"), 1, 0)))

#Christ holiday
category_model_data2$hol_christ <- ifelse(category_model_data2$tran_datetime > as.Date("2017-12-21") & category_model_data2$tran_datetime < as.Date("2017-12-24"), 1 ,
                                          ifelse(category_model_data2$tran_datetime > as.Date("2018-12-20") & category_model_data2$tran_datetime < as.Date("2018-12-23"), 1 , 
                                                 ifelse(category_model_data2$tran_datetime >= as.Date("2019-12-22") & category_model_data2$tran_datetime <= as.Date("2019-12-25"), 1 ,0)))


#Aug sales
category_model_data2$hol_aug_sale <- ifelse(category_model_data2$tran_datetime %in% c(as.Date("2017-08-05"), as.Date("2017-08-12"),as.Date("2018-08-04"), as.Date("2018-08-11")), 1 , 0)

#March april sales
category_model_data2$hol_mar_apr_sale <- ifelse(category_model_data2$tran_datetime %in% c(as.Date("2018-03-17"), as.Date("2018-03-24"), as.Date("2018-03-31"),
                                                                                          as.Date("2019-04-06"), as.Date("2019-04-13"), as.Date("2019-04-20")), 1 , 0)

#post weekend thx
category_model_data2$hol_post_thx <- ifelse(category_model_data2$tran_datetime %in% c(as.Date("2017-12-01"), as.Date("2018-12-02"), as.Date("2018-12-03"),
                                                                                      as.Date("2018-11-30")), 1 , 0)

################################# 3.0 Defining model structure and variables #################################
dep1 <- "trip"
dep2 <- "avg_basket_size"

dep1_ln <- "log_trip"
dep2_ln <- "log_avg_baseket_size"

indep_trip <- c( #"perc_saved_w_non_coupon"
  "per_total_saved_log"
  ,"weekend_flag"
  #,"hol_halo"
  ,"hol_pre_valen"
  ,"hol_thx"
  ,"hol_pre_thx"
  ,"hol_christ"
  ,"hol_aug_sale"
  ,"hol_mar_apr_sale"
  ,"hol_post_thx"
  ,"perc_d10off10_loyalty_storewide_coupon_saved_amt_trips_flag"
  ,"perc_poff10_non_loyalty_storewide_coupon_saved_amt_trips_flag"
  ,"perc_poff30_non_loyalty_storewide_coupon_saved_amt_trips_flag"
  ,"perc_storewide_doff_coupon_saved_amt_trips_flag"
  ,"perc_d10off10_non_loyalty_storewide_coupon_saved_amt_trips_flag"
  ,"perc_business_specific_non_jewelry_coupon_saved_amt_trips_flag"
  ,"perc_storewide_poff_coupon_saved_amt_trips_flag"
  , "perc_poff25_non_loyalty_storewide_coupon_saved_amt_trips_flag"
  ,"flag_other"
  ,"flag_15_20_non_loyalty_storewide"
  ,"flag_30_50_non_loyalty_storewide"
  #, "flag_column_10_off_10"
  , "trip_trend_log"
)

formula_log_trip <- as.formula(paste(dep1_ln, paste(indep_trip, collapse = " + "), sep = ' ~ '))

formula_log_trip

indep_basket_size <- c( "per_total_saved_log"
                        ,"weekend_flag"
                        ,colnames(category_model_data2)[which(grepl("hol", colnames(category_model_data2))>0 & grepl("holiday", colnames(category_model_data2)) == 0)]
                        ,colnames(category_model_data1)[flag_column_list]
                        , "basket_size_trend_log"
)

indep_basket_size

formula_log_basket_size <- as.formula(paste(dep2_ln, paste(indep_basket_size, collapse = " + "), sep = ' ~ '))

formula_log_basket_size
################################# 4.0 Model #################################

fit_trip <- lm(formula_log_trip, data=unique(category_model_data2))
fit_trip
summary(fit_trip)
vif(fit_trip)


fit_basket_size <- lm(formula_log_basket_size, data=unique(category_model_data2))
summary(fit_basket_size)
vif(fit_basket_size)


#######MAPE
model_data_cpn_overall <- category_model_data2
model_data_cpn_overall$predict_trip_log <- fit_trip$fitted.values
model_data_cpn_overall$predict_avg_basket_size_log <- fit_basket_size$fitted.values
model_data_cpn_overall$predict_avg_basket_size_log

model_data_cpn_overall$predict_trip <- exp(model_data_cpn_overall$predict_trip_log)
model_data_cpn_overall$predict_basket_size <- exp(model_data_cpn_overall$predict_avg_basket_size_log)

model_data_cpn_overall$trip_delta <- model_data_cpn_overall$predict_trip - model_data_cpn_overall$trip

MAPE_trip <- mean(abs((model_data_cpn_overall$predict_trip - model_data_cpn_overall$trip)/model_data_cpn_overall$trip))
MAPE_basket_size <- mean(abs((model_data_cpn_overall$predict_basket_size - model_data_cpn_overall$avg_basket_size)/model_data_cpn_overall$avg_basket_size))

MAPE_trip
MAPE_basket_size


############################################

# summary(fit_trip)
# 
# Call:
#   lm(formula = formula_log_trip, data = unique(category_model_data2))
# 
# Residuals:
#   Min       1Q   Median       3Q      Max 
# -0.47003 -0.12367 -0.01542  0.10732  0.66852 
# 
# Coefficients:
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
#   ---
#   Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
# 
# Residual standard error: 0.1859 on 833 degrees of freedom
# Multiple R-squared:  0.8006,	Adjusted R-squared:  0.7956 
# F-statistic: 159.3 on 21 and 833 DF,  p-value: < 2.2e-16
# 
# > summary(fit_basket_size)
# 
# Call:
#   lm(formula = formula_log_basket_size, data = unique(category_model_data2))
# 
# Residuals:
#   Min       1Q   Median       3Q      Max 
# -0.29465 -0.06256 -0.01116  0.04135  0.35388 
# 
# Coefficients:
#   Estimate Std. Error t value Pr(>|t|)    
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
#   ---
#   Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
# 
# Residual standard error: 0.1081 on 828 degrees of freedom
# Multiple R-squared:  0.3866,	Adjusted R-squared:  0.3673 
# F-statistic: 20.07 on 26 and 828 DF,  p-value: < 2.2e-16
