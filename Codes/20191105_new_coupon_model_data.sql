
#### Step 6a input 1 Name: 'overall_coupon_data_full'####
select 
   tran_datetime
  
  ,count(distinct new_CID) as trip
  ,sum(total_sales)/count(distinct new_CID) as avg_basket_size
  ,sum(total_discount_amt_by_clr + final_primary_discount)/sum(p1_sales) as perc_saved_w_non_coupon
  ,sum(final_secondary_discount) as final_secondary_discount
  ,sum(final_primary_discount) as final_primary_discount
  ,sum(p1_sales) as p1_sales
  ,sum(total_cogs) as total_cogs

  ,sum(case when poff20_non_loyalty_storewide_coupon_saved_amt_trans > 0 then 1 else 0 end) as poff20_non_loyalty_storewide_coupon_saved_amt_trips
  ,sum(case when d10off10_loyalty_storewide_coupon_saved_amt_trans > 0 then 1 else 0 end) as d10off10_loyalty_storewide_coupon_saved_amt_trips
  ,sum(case when poff15_non_loyalty_storewide_coupon_saved_amt_trans > 0 then 1 else 0 end) as poff15_non_loyalty_storewide_coupon_saved_amt_trips
  ,sum(case when d10off25_non_loyalty_storewide_coupon_saved_amt_trans > 0 then 1 else 0 end) as d10off25_non_loyalty_storewide_coupon_saved_amt_trips
  ,sum(case when poff30_non_loyalty_storewide_coupon_saved_amt_trans > 0 then 1 else 0 end) as poff30_non_loyalty_storewide_coupon_saved_amt_trips
  ,sum(case when poff25_non_loyalty_storewide_coupon_saved_amt_trans > 0 then 1 else 0 end) as poff25_non_loyalty_storewide_coupon_saved_amt_trips
  ,sum(case when d10off10_non_loyalty_storewide_coupon_saved_amt_trans > 0 then 1 else 0 end) as d10off10_non_loyalty_storewide_coupon_saved_amt_trips
  ,sum(case when poff40_non_loyalty_storewide_coupon_saved_amt_trans > 0 then 1 else 0 end) as poff40_non_loyalty_storewide_coupon_saved_amt_trips
  ,sum(case when poff50_non_loyalty_storewide_coupon_saved_amt_trans > 0 then 1 else 0 end) as poff50_non_loyalty_storewide_coupon_saved_amt_trips
  ,sum(case when poff10_non_loyalty_storewide_coupon_saved_amt_trans > 0 then 1 else 0 end) as poff10_non_loyalty_storewide_coupon_saved_amt_trips
  ,sum(case when poff20_non_loyalty_business_specific_coupon_saved_amt_trans > 0 then 1 else 0 end) as poff20_non_loyalty_business_specific_coupon_saved_amt_trips
  ,sum(case when business_specific_jewelry_coupon_saved_amt_trans > 0 then 1 else 0 end) as business_specific_jewelry_coupon_saved_amt_trips
  ,sum(case when business_specific_non_jewelry_coupon_saved_amt_trans > 0 then 1 else 0 end) as business_specific_non_jewelry_coupon_saved_amt_trips
  ,sum(case when storewide_doff_coupon_saved_amt_trans > 0 then 1 else 0 end) as storewide_doff_coupon_saved_amt_trips
  ,sum(case when storewide_poff_coupon_saved_amt_trans > 0 then 1 else 0 end) as storewide_poff_coupon_saved_amt_trips
  ,sum(poff20_non_loyalty_storewide_coupon_saved_amt) as poff20_non_loyalty_storewide_coupon_saved_amt
  ,sum(d10off10_loyalty_storewide_coupon_saved_amt) as d10off10_loyalty_storewide_coupon_saved_amt
  ,sum(poff15_non_loyalty_storewide_coupon_saved_amt) as poff15_non_loyalty_storewide_coupon_saved_amt 
  ,sum(d10off25_non_loyalty_storewide_coupon_saved_amt) as d10off25_non_loyalty_storewide_coupon_saved_amt
  ,sum(poff30_non_loyalty_storewide_coupon_saved_amt) as poff30_non_loyalty_storewide_coupon_saved_amt
  ,sum(poff25_non_loyalty_storewide_coupon_saved_amt) as poff25_non_loyalty_storewide_coupon_saved_amt
  ,sum(d10off10_non_loyalty_storewide_coupon_saved_amt) as d10off10_non_loyalty_storewide_coupon_saved_amt
  ,sum(poff40_non_loyalty_storewide_coupon_saved_amt) as poff40_non_loyalty_storewide_coupon_saved_amt
  ,sum(poff50_non_loyalty_storewide_coupon_saved_amt) as poff50_non_loyalty_storewide_coupon_saved_amt
  ,sum(poff10_non_loyalty_storewide_coupon_saved_amt) as poff10_non_loyalty_storewide_coupon_saved_amt
  ,sum(poff20_non_loyalty_business_specific_coupon_saved_amt) as poff20_non_loyalty_business_specific_coupon_saved_amt
  ,sum(business_specific_jewelry_coupon_saved_amt) as business_specific_jewelry_coupon_saved_amt
  ,sum(business_specific_non_jewelry_coupon_saved_amt) as business_specific_non_jewelry_coupon_saved_amt
  ,sum(storewide_doff_coupon_saved_amt) as storewide_doff_coupon_saved_amt
  ,sum(storewide_poff_coupon_saved_amt) as storewide_poff_coupon_saved_amt

from pricing_users.blr_cust_coupon_summary_20190826 
group by
 tran_datetime
;

#### Step 6b input 2 Name: 'sales_by_coupon'####
select 
   tran_datetime
  
  ,count(distinct new_CID) as trip
  ,sum(total_sales)/count(distinct new_CID) as avg_basket_size
  ,sum(total_discount_amt_by_clr + final_primary_discount)/sum(p1_sales) as perc_saved_w_non_coupon
  ,sum(final_secondary_discount) as final_secondary_discount
  ,sum(final_primary_discount) as final_primary_discount
  ,sum(p1_sales) as p1_sales
  ,sum(total_cogs) as total_cogs
,sum(case when poff20_non_loyalty_storewide_coupon_saved_amt > 0 then total_sales else 0 end) as poff20_non_loyalty_storewide_coupon_saved_sales
,sum(case when d10off10_loyalty_storewide_coupon_saved_amt > 0 then total_sales else 0 end) as d10off10_loyalty_storewide_coupon_saved_sales
,sum(case when poff15_non_loyalty_storewide_coupon_saved_amt > 0 then total_sales else 0 end) as poff15_non_loyalty_storewide_coupon_saved_sales
,sum(case when d10off25_non_loyalty_storewide_coupon_saved_amt > 0 then total_sales else 0 end) as d10off25_non_loyalty_storewide_coupon_saved_sales
,sum(case when poff30_non_loyalty_storewide_coupon_saved_amt > 0 then total_sales else 0 end) as poff30_non_loyalty_storewide_coupon_saved_sales
,sum(case when poff25_non_loyalty_storewide_coupon_saved_amt > 0 then total_sales else 0 end) as poff25_non_loyalty_storewide_coupon_saved_sales
,sum(case when d10off10_non_loyalty_storewide_coupon_saved_amt > 0 then total_sales else 0 end) as d10off10_non_loyalty_storewide_coupon_saved_sales
,sum(case when poff40_non_loyalty_storewide_coupon_saved_amt > 0 then total_sales else 0 end) as poff40_non_loyalty_storewide_coupon_saved_sales
,sum(case when poff50_non_loyalty_storewide_coupon_saved_amt > 0 then total_sales else 0 end) as poff50_non_loyalty_storewide_coupon_saved_sales
,sum(case when poff10_non_loyalty_storewide_coupon_saved_amt > 0 then total_sales else 0 end) as poff10_non_loyalty_storewide_coupon_saved_sales
,sum(case when poff20_non_loyalty_business_specific_coupon_saved_amt > 0 then total_sales else 0 end) as poff20_non_loyalty_business_specific_coupon_saved_sales
,sum(case when business_specific_jewelry_coupon_saved_amt > 0 then total_sales else 0 end) as business_specific_jewelry_coupon_saved_sales
,sum(case when business_specific_non_jewelry_coupon_saved_amt > 0 then total_sales else 0 end) as business_specific_non_jewelry_coupon_saved_sales
,sum(case when storewide_doff_coupon_saved_amt > 0 then total_sales else 0 end) as storewide_doff_coupon_saved_sales
,sum(case when storewide_poff_coupon_saved_amt > 0 then total_sales else 0 end) as storewide_poff_coupon_saved_sales

,sum(case when poff20_non_loyalty_storewide_coupon_saved_amt > 0 then p1_sales else 0 end) as poff20_non_loyalty_storewide_coupon_saved_p1_sales
,sum(case when d10off10_loyalty_storewide_coupon_saved_amt > 0 then p1_sales else 0 end) as d10off10_loyalty_storewide_coupon_saved_p1_sales
,sum(case when poff15_non_loyalty_storewide_coupon_saved_amt > 0 then p1_sales else 0 end) as poff15_non_loyalty_storewide_coupon_saved_p1_sales
,sum(case when d10off25_non_loyalty_storewide_coupon_saved_amt > 0 then p1_sales else 0 end) as d10off25_non_loyalty_storewide_coupon_saved_p1_sales
,sum(case when poff30_non_loyalty_storewide_coupon_saved_amt > 0 then p1_sales else 0 end) as poff30_non_loyalty_storewide_coupon_saved_p1_sales
,sum(case when poff25_non_loyalty_storewide_coupon_saved_amt > 0 then p1_sales else 0 end) as poff25_non_loyalty_storewide_coupon_saved_p1_sales
,sum(case when d10off10_non_loyalty_storewide_coupon_saved_amt > 0 then p1_sales else 0 end) as d10off10_non_loyalty_storewide_coupon_saved_p1_sales
,sum(case when poff40_non_loyalty_storewide_coupon_saved_amt > 0 then p1_sales else 0 end) as poff40_non_loyalty_storewide_coupon_saved_p1_sales
,sum(case when poff50_non_loyalty_storewide_coupon_saved_amt > 0 then p1_sales else 0 end) as poff50_non_loyalty_storewide_coupon_saved_p1_sales
,sum(case when poff10_non_loyalty_storewide_coupon_saved_amt > 0 then p1_sales else 0 end) as poff10_non_loyalty_storewide_coupon_saved_p1_sales
,sum(case when poff20_non_loyalty_business_specific_coupon_saved_amt > 0 then p1_sales else 0 end) as poff20_non_loyalty_business_specific_coupon_saved_p1_sales
,sum(case when business_specific_jewelry_coupon_saved_amt > 0 then p1_sales else 0 end) as business_specific_jewelry_coupon_saved_p1_sales
,sum(case when business_specific_non_jewelry_coupon_saved_amt > 0 then p1_sales else 0 end) as business_specific_non_jewelry_coupon_saved_p1_sales
,sum(case when storewide_doff_coupon_saved_amt > 0 then p1_sales else 0 end) as storewide_doff_coupon_saved_p1_sales
,sum(case when storewide_poff_coupon_saved_amt > 0 then p1_sales else 0 end) as storewide_poff_coupon_saved_p1_sales

,sum(case when poff20_non_loyalty_storewide_coupon_saved_amt > 0 then total_qty else 0 end) as poff20_non_loyalty_storewide_coupon_saved_total_qty
,sum(case when d10off10_loyalty_storewide_coupon_saved_amt > 0 then total_qty else 0 end) as d10off10_loyalty_storewide_coupon_saved_total_qty
,sum(case when poff15_non_loyalty_storewide_coupon_saved_amt > 0 then total_qty else 0 end) as poff15_non_loyalty_storewide_coupon_saved_total_qty
,sum(case when d10off25_non_loyalty_storewide_coupon_saved_amt > 0 then total_qty else 0 end) as d10off25_non_loyalty_storewide_coupon_saved_total_qty
,sum(case when poff30_non_loyalty_storewide_coupon_saved_amt > 0 then total_qty else 0 end) as poff30_non_loyalty_storewide_coupon_saved_total_qty
,sum(case when poff25_non_loyalty_storewide_coupon_saved_amt > 0 then total_qty else 0 end) as poff25_non_loyalty_storewide_coupon_saved_total_qty
,sum(case when d10off10_non_loyalty_storewide_coupon_saved_amt > 0 then total_qty else 0 end) as d10off10_non_loyalty_storewide_coupon_saved_total_qty
,sum(case when poff40_non_loyalty_storewide_coupon_saved_amt > 0 then total_qty else 0 end) as poff40_non_loyalty_storewide_coupon_saved_total_qty
,sum(case when poff50_non_loyalty_storewide_coupon_saved_amt > 0 then total_qty else 0 end) as poff50_non_loyalty_storewide_coupon_saved_total_qty
,sum(case when poff10_non_loyalty_storewide_coupon_saved_amt > 0 then total_qty else 0 end) as poff10_non_loyalty_storewide_coupon_saved_total_qty
,sum(case when poff20_non_loyalty_business_specific_coupon_saved_amt > 0 then total_qty else 0 end) as poff20_non_loyalty_business_specific_coupon_saved_total_qty
,sum(case when business_specific_jewelry_coupon_saved_amt > 0 then total_qty else 0 end) as business_specific_jewelry_coupon_saved_total_qty
,sum(case when business_specific_non_jewelry_coupon_saved_amt > 0 then total_qty else 0 end) as business_specific_non_jewelry_coupon_saved_total_qty
,sum(case when storewide_doff_coupon_saved_amt > 0 then total_qty else 0 end) as storewide_doff_coupon_saved_total_qty
,sum(case when storewide_poff_coupon_saved_amt > 0 then total_qty else 0 end) as storewide_poff_coupon_saved_total_qty
from pricing_users.blr_cust_coupon_summary_20190826 a

group by
 tran_datetime
;







#### Step 6c input 3 Name: 'primary_discount_saved_amt_coupon'####
select 
   tran_datetime
  
  ,count(distinct new_CID) as trip
  ,sum(total_sales)/count(distinct new_CID) as avg_basket_size
  ,sum(total_discount_amt_by_clr + final_primary_discount)/sum(p1_sales) as perc_saved_w_non_coupon
  ,sum(final_secondary_discount) as final_secondary_discount
  ,sum(final_primary_discount) as final_primary_discount
  ,sum(p1_sales) as p1_sales
  ,sum(total_cogs) as total_cogs

, sum(case when poff20_non_loyalty_storewide_coupon_saved_amt> 0 then final_primary_discount else 0 end) as poff20_non_loyalty_storewide_coupon_saved_amt_final_primary_discount
, sum(case when d10off10_loyalty_storewide_coupon_saved_amt> 0 then final_primary_discount else 0 end) as d10off10_loyalty_storewide_coupon_saved_amt_final_primary_discount
, sum(case when poff15_non_loyalty_storewide_coupon_saved_amt> 0 then final_primary_discount else 0 end) as poff15_non_loyalty_storewide_coupon_saved_amt_final_primary_discount
, sum(case when d10off25_non_loyalty_storewide_coupon_saved_amt> 0 then final_primary_discount else 0 end) as d10off25_non_loyalty_storewide_coupon_saved_amt_final_primary_discount
, sum(case when poff30_non_loyalty_storewide_coupon_saved_amt> 0 then final_primary_discount else 0 end) as poff30_non_loyalty_storewide_coupon_saved_amt_final_primary_discount
, sum(case when poff25_non_loyalty_storewide_coupon_saved_amt> 0 then final_primary_discount else 0 end) as poff25_non_loyalty_storewide_coupon_saved_amt_final_primary_discount
, sum(case when d10off10_non_loyalty_storewide_coupon_saved_amt> 0 then final_primary_discount else 0 end) as d10off10_non_loyalty_storewide_coupon_saved_amt_final_primary_discount
, sum(case when poff40_non_loyalty_storewide_coupon_saved_amt> 0 then final_primary_discount else 0 end) as poff40_non_loyalty_storewide_coupon_saved_amt_final_primary_discount
, sum(case when poff50_non_loyalty_storewide_coupon_saved_amt> 0 then final_primary_discount else 0 end) as poff50_non_loyalty_storewide_coupon_saved_amt_final_primary_discount
, sum(case when poff10_non_loyalty_storewide_coupon_saved_amt> 0 then final_primary_discount else 0 end) as poff10_non_loyalty_storewide_coupon_saved_amt_final_primary_discount
, sum(case when poff20_non_loyalty_business_specific_coupon_saved_amt> 0 then final_primary_discount else 0 end) as poff20_non_loyalty_business_specific_coupon_saved_amt_final_primary_discount
, sum(case when business_specific_jewelry_coupon_saved_amt> 0 then final_primary_discount else 0 end) as business_specific_jewelry_coupon_saved_amt_final_primary_discount
, sum(case when business_specific_non_jewelry_coupon_saved_amt> 0 then final_primary_discount else 0 end) as business_specific_non_jewelry_coupon_saved_amt_final_primary_discount
, sum(case when storewide_doff_coupon_saved_amt> 0 then final_primary_discount else 0 end) as storewide_doff_coupon_saved_amt_final_primary_discount
, sum(case when storewide_poff_coupon_saved_amt> 0 then final_primary_discount else 0 end) as storewide_poff_coupon_saved_amt_final_primary_discount
from pricing_users.blr_cust_coupon_summary_20190826 a

group by
 tran_datetime
;




#### Step 6c input 3 Name: 'overall_coupon_cogs_data'####
select 
   tran_datetime
  
  ,count(distinct new_CID) as trip
  ,sum(total_sales)/count(distinct new_CID) as avg_basket_size
  ,sum(total_discount_amt_by_clr + final_primary_discount)/sum(p1_sales) as perc_saved_w_non_coupon
  ,sum(final_secondary_discount) as final_secondary_discount
  ,sum(final_primary_discount) as final_primary_discount
  ,sum(p1_sales) as p1_sales
  ,sum(total_cogs) as total_cogs
, sum(case when poff20_non_loyalty_storewide_coupon_saved_amt> 0 then total_cogs else 0 end) as poff20_non_loyalty_storewide_coupon_saved_total_cogs
, sum(case when d10off10_loyalty_storewide_coupon_saved_amt> 0 then total_cogs else 0 end) as d10off10_loyalty_storewide_coupon_saved_total_cogs
, sum(case when poff15_non_loyalty_storewide_coupon_saved_amt> 0 then total_cogs else 0 end) as poff15_non_loyalty_storewide_coupon_saved_total_cogs
, sum(case when d10off25_non_loyalty_storewide_coupon_saved_amt> 0 then total_cogs else 0 end) as d10off25_non_loyalty_storewide_coupon_saved_total_cogs
, sum(case when poff30_non_loyalty_storewide_coupon_saved_amt> 0 then total_cogs else 0 end) as poff30_non_loyalty_storewide_coupon_saved_total_cogs
, sum(case when poff25_non_loyalty_storewide_coupon_saved_amt> 0 then total_cogs else 0 end) as poff25_non_loyalty_storewide_coupon_saved_total_cogs
, sum(case when d10off10_non_loyalty_storewide_coupon_saved_amt> 0 then total_cogs else 0 end) as d10off10_non_loyalty_storewide_coupon_saved_total_cogs
, sum(case when poff40_non_loyalty_storewide_coupon_saved_amt> 0 then total_cogs else 0 end) as poff40_non_loyalty_storewide_coupon_saved_total_cogs
, sum(case when poff50_non_loyalty_storewide_coupon_saved_amt> 0 then total_cogs else 0 end) as poff50_non_loyalty_storewide_coupon_saved_total_cogs
, sum(case when poff10_non_loyalty_storewide_coupon_saved_amt> 0 then total_cogs else 0 end) as poff10_non_loyalty_storewide_coupon_saved_total_cogs
, sum(case when poff20_non_loyalty_business_specific_coupon_saved_amt> 0 then total_cogs else 0 end) as poff20_non_loyalty_business_specific_coupon_saved_total_cogs
, sum(case when business_specific_jewelry_coupon_saved_amt> 0 then total_cogs else 0 end) as business_specific_jewelry_coupon_saved_total_cogs
, sum(case when business_specific_non_jewelry_coupon_saved_amt> 0 then total_cogs else 0 end) as business_specific_non_jewelry_coupon_saved_total_cogs
, sum(case when storewide_doff_coupon_saved_amt> 0 then total_cogs else 0 end) as storewide_doff_coupon_saved_total_cogs
, sum(case when storewide_poff_coupon_saved_amt> 0 then total_cogs else 0 end) as storewide_poff_coupon_saved_total_cogs
from pricing_users.blr_cust_coupon_summary_20190826 a

group by
 tran_datetime
;




#### Step 6d input 4 Name: 'non coupon data'####
select tran_datetime,count(distinct new_CID) as non_coupon_trips, sum(total_sales) as non_coupon_rev,
sum(p1_sales) as total_p1_sale_non_coupon,sum(total_cogs) as non_coupon_cogs
from
pricing_users.blr_cust_coupon_summary_20190826
where poff20_non_loyalty_storewide_coupon_saved_amt_trans < 0.001
and d10off10_loyalty_storewide_coupon_saved_amt_trans < 0.001
and poff15_non_loyalty_storewide_coupon_saved_amt_trans < 0.001
and d10off25_non_loyalty_storewide_coupon_saved_amt_trans < 0.001
and poff30_non_loyalty_storewide_coupon_saved_amt_trans < 0.001
and poff25_non_loyalty_storewide_coupon_saved_amt_trans < 0.001
and d10off10_non_loyalty_storewide_coupon_saved_amt_trans < 0.001
and poff40_non_loyalty_storewide_coupon_saved_amt_trans < 0.001
and poff50_non_loyalty_storewide_coupon_saved_amt_trans < 0.001
and poff10_non_loyalty_storewide_coupon_saved_amt_trans < 0.001
and poff20_non_loyalty_business_specific_coupon_saved_amt_trans < 0.001
and business_specific_jewelry_coupon_saved_amt_trans < 0.001
and business_specific_non_jewelry_coupon_saved_amt_trans < 0.001
and storewide_doff_coupon_saved_amt_trans < 0.001
and storewide_poff_coupon_saved_amt_trans < 0.001
group by tran_datetime;
