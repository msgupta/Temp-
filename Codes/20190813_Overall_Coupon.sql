#### Step 1 ####
--drop table pricing_users.mck_transaction_summary purge;
----get the total and clearance sales,cogs at transaction level----
drop table pricing_users.blr_transaction_summary purge;
create table pricing_users.blr_transaction_summary as 
select 
  store_num
 ,tran_seq_no
 ,tran_datetime
 ,terminal_num
 ,tran_num
 ,sum(actual_rtl_amt) as total_sales
 ,sum(item_ord_qty) as total_qty
 ,sum(unit_cost_amt * item_ord_qty) as total_cogs
 ,sum(case when unit_discount_amt_by_clr_adj_type_code14 > 0 then actual_rtl_amt else 0 end) as clr_sales_p4
 ,sum(case when unit_discount_amt_by_clr_adj_type_code14 > 0 then item_ord_qty else 0 end) as clr_qty_p4
 ,sum(case when unit_discount_amt_by_clr_adj_type_code12 > 0 then actual_rtl_amt else 0 end) as clr_sales -- p5
 ,sum(case when unit_discount_amt_by_clr_adj_type_code12 > 0 then item_ord_qty else 0 end) as clr_qty     -- p5
from pricing_users.blr_resa_combined_filtered_woR_filtered_store a 
left join pricing_users.blr_item_daily_cost b
on a.item = b.item
and a.tran_datetime = b.string_format
group by 
  store_num
 ,tran_seq_no
 ,tran_datetime
 ,terminal_num
 ,tran_num
;


---not needed----
select 
tran_datetime, 
count(distinct tran_seq_no) as cnt_trns 
from pricing_users.mck_resa_combined_filtered_woR_filtered_store a 
left join
(select orin_sku, new_category 
from pricing_users.mck_item_category_mapping_all_divisions
where new_category = "Appliances") b
on a.item = b.orin_sku
group by 
tran_datetime
;


#### Step 2 ####
---join the customer data with the transaction table at transaction level---
--drop table pricing_users.mck_transaction_summary_new_CID;
drop table pricing_users.blr_transaction_summary_new_CID purge;
create table pricing_users.blr_transaction_summary_new_CID as 
select 
  a.*
, b.CID
, case when b.CID is null then a.tran_seq_no else CID end as new_CID ---replace the null customer id with the trans seq no---
, b.loyalty
, case when b.loyalty is null then 'N' else b.loyalty end as new_loyalty ----replace the null values in loyalty column with 'N'---
from pricing_users.blr_transaction_summary a 
--left join pricing_users.mck_customer_to_trans_mapping_sample b
left join pricing_users.epsilon_loyalty_final b
on  a.store_num = b.SELL_STORE_NBR  
and a.tran_num = b.TXN_SEQ_NBR              
and a.tran_datetime = from_unixtime(unix_timestamp(b.txn_dt,'dd-MMM-yy'), 'yyyy-MM-dd')             
and a.terminal_num = b.REGISTER_NBR    
;



#### Step 3 ####
---aggregate the coupon wise saved amount at trans seq no and tran date level---
--drop table pricing_users.mck_transaction_coupon_group_summary;
drop table pricing_users.blr_transaction_coupon_group_summary  purge;
create table pricing_users.blr_transaction_coupon_group_summary as 
select 
   tran_seq_no
  ,tran_datetime 

-- primary coupon groups
  ,sum(poff20_non_loyalty_storewide_coupon_saved_amt) as poff20_non_loyalty_storewide_coupon_saved_amt
  ,sum(d10off10_loyalty_storewide_coupon_saved_amt) as d10off10_loyalty_storewide_coupon_saved_amt
  ,sum(poff15_non_loyalty_storewide_coupon_saved_amt) as poff15_non_loyalty_storewide_coupon_saved_amt 
  ,sum(d10off25_non_loyalty_storewide_coupon_saved_amt) as d10off25_non_loyalty_storewide_coupon_saved_amt
  ,sum(poff30_non_loyalty_storewide_coupon_saved_amt) as poff30_non_loyalty_storewide_coupon_saved_amt
  ,sum(poff25_non_loyalty_storewide_coupon_saved_amt) as poff25_non_loyalty_storewide_coupon_saved_amt

  -- secondary coupon groups
  ,sum(d10off10_non_loyalty_storewide_coupon_saved_amt) as d10off10_non_loyalty_storewide_coupon_saved_amt
  ,sum(poff40_non_loyalty_storewide_coupon_saved_amt) as poff40_non_loyalty_storewide_coupon_saved_amt
  ,sum(poff50_non_loyalty_storewide_coupon_saved_amt) as poff50_non_loyalty_storewide_coupon_saved_amt
  ,sum(poff10_non_loyalty_storewide_coupon_saved_amt) as poff10_non_loyalty_storewide_coupon_saved_amt
  ,sum(poff20_non_loyalty_business_specific_coupon_saved_amt) as poff20_non_loyalty_business_specific_coupon_saved_amt

  -- other coupon groups (including jewelry)
  ,sum(business_specific_jewelry_coupon_saved_amt) as business_specific_jewelry_coupon_saved_amt
  ,sum(business_specific_non_jewelry_coupon_saved_amt) as business_specific_non_jewelry_coupon_saved_amt
  ,sum(storewide_doff_coupon_saved_amt) as storewide_doff_coupon_saved_amt
  ,sum(storewide_poff_coupon_saved_amt) as storewide_poff_coupon_saved_amt

from pricing_users.blr_trans_item_coupon_groups_transposed_v2 
group by 
   tran_seq_no
  ,tran_datetime 
;

#### Step 4 ####
-----aggregate the discount amount and p1 sales columns at transa seq no and tran date level--
--created done 20191115-------
--drop table pricing_users.mck_tran_saved_amt_by_price_promo purge;
drop table pricing_users.blr_tran_saved_amt_by_price_promo purge;
create table pricing_users.blr_tran_saved_amt_by_price_promo as 
select 
  tran_seq_no
, tran_datetime 
, sum(unit_discount_amt_by_clr_adj_type_code12 * item_ord_qty) as total_discount_amt_by_clr_adj_type_code12
, sum(unit_discount_amt_by_clr_adj_type_code14 * item_ord_qty) as total_discount_amt_by_clr_adj_type_code14
, sum(final_secondary_discount * item_ord_qty) as final_secondary_discount
, sum(final_primary_discount * item_ord_qty) as final_primary_discount
, sum(final_p1 * item_ord_qty) as p1_sales
from pricing_users.blr_resa_combined_filtered_wor_v2_after_store_filter_w_p1_p2_from_resa_no_gaps_jx
group by 
  tran_seq_no
, tran_datetime
;



#### Step 5 ####
--drop table pricing_users.mck_cust_coupon_summary_20190826 ;
---aggregate the total,P1 sales,cogs,discount at customer id, tran date level and saved amount,transactions for all coupon groups---
drop table pricing_users.blr_cust_coupon_summary_20190826 purge;
create table pricing_users.blr_cust_coupon_summary_20190826 as 
select 
   a.new_CID
  ,a.tran_datetime

  , sum(total_sales) as total_sales
  , sum(total_qty) as total_qty	
-- amt saved by promo
  , sum(total_discount_amt_by_clr_adj_type_code12 + total_discount_amt_by_clr_adj_type_code14) as total_discount_amt_by_clr
  , sum(final_secondary_discount) as final_secondary_discount
  , sum(final_primary_discount) as final_primary_discount
  , sum(p1_sales) as p1_sales
  , sum(total_cogs) as total_cogs

-- primary coupon groups
  ,sum(poff20_non_loyalty_storewide_coupon_saved_amt) as poff20_non_loyalty_storewide_coupon_saved_amt
  ,sum(d10off10_loyalty_storewide_coupon_saved_amt) as d10off10_loyalty_storewide_coupon_saved_amt
  ,sum(poff15_non_loyalty_storewide_coupon_saved_amt) as poff15_non_loyalty_storewide_coupon_saved_amt 
  ,sum(d10off25_non_loyalty_storewide_coupon_saved_amt) as d10off25_non_loyalty_storewide_coupon_saved_amt
  ,sum(poff30_non_loyalty_storewide_coupon_saved_amt) as poff30_non_loyalty_storewide_coupon_saved_amt
  ,sum(poff25_non_loyalty_storewide_coupon_saved_amt) as poff25_non_loyalty_storewide_coupon_saved_amt

  -- secondary coupon groups
  ,sum(d10off10_non_loyalty_storewide_coupon_saved_amt) as d10off10_non_loyalty_storewide_coupon_saved_amt
  ,sum(poff40_non_loyalty_storewide_coupon_saved_amt) as poff40_non_loyalty_storewide_coupon_saved_amt
  ,sum(poff50_non_loyalty_storewide_coupon_saved_amt) as poff50_non_loyalty_storewide_coupon_saved_amt
  ,sum(poff10_non_loyalty_storewide_coupon_saved_amt) as poff10_non_loyalty_storewide_coupon_saved_amt
  ,sum(poff20_non_loyalty_business_specific_coupon_saved_amt) as poff20_non_loyalty_business_specific_coupon_saved_amt

  -- other coupon groups (including jewelry)
  ,sum(business_specific_jewelry_coupon_saved_amt) as business_specific_jewelry_coupon_saved_amt
  ,sum(business_specific_non_jewelry_coupon_saved_amt) as business_specific_non_jewelry_coupon_saved_amt
  ,sum(storewide_doff_coupon_saved_amt) as storewide_doff_coupon_saved_amt
  ,sum(storewide_poff_coupon_saved_amt) as storewide_poff_coupon_saved_amt

  , sum(case when poff20_non_loyalty_storewide_coupon_saved_amt> 0 then 1 else 0 end) as poff20_non_loyalty_storewide_coupon_saved_amt_trans
  , sum(case when d10off10_loyalty_storewide_coupon_saved_amt> 0 then 1 else 0 end) as d10off10_loyalty_storewide_coupon_saved_amt_trans
  , sum(case when poff15_non_loyalty_storewide_coupon_saved_amt> 0 then 1 else 0 end) as poff15_non_loyalty_storewide_coupon_saved_amt_trans
  , sum(case when d10off25_non_loyalty_storewide_coupon_saved_amt> 0 then 1 else 0 end) as d10off25_non_loyalty_storewide_coupon_saved_amt_trans
  , sum(case when poff30_non_loyalty_storewide_coupon_saved_amt> 0 then 1 else 0 end) as poff30_non_loyalty_storewide_coupon_saved_amt_trans
  , sum(case when poff25_non_loyalty_storewide_coupon_saved_amt> 0 then 1 else 0 end) as poff25_non_loyalty_storewide_coupon_saved_amt_trans
  , sum(case when d10off10_non_loyalty_storewide_coupon_saved_amt> 0 then 1 else 0 end) as d10off10_non_loyalty_storewide_coupon_saved_amt_trans
  , sum(case when poff40_non_loyalty_storewide_coupon_saved_amt> 0 then 1 else 0 end) as poff40_non_loyalty_storewide_coupon_saved_amt_trans
  , sum(case when poff50_non_loyalty_storewide_coupon_saved_amt> 0 then 1 else 0 end) as poff50_non_loyalty_storewide_coupon_saved_amt_trans
  , sum(case when poff10_non_loyalty_storewide_coupon_saved_amt> 0 then 1 else 0 end) as poff10_non_loyalty_storewide_coupon_saved_amt_trans
  , sum(case when poff20_non_loyalty_business_specific_coupon_saved_amt> 0 then 1 else 0 end) as poff20_non_loyalty_business_specific_coupon_saved_amt_trans
  , sum(case when business_specific_jewelry_coupon_saved_amt> 0 then 1 else 0 end) as business_specific_jewelry_coupon_saved_amt_trans
  , sum(case when business_specific_non_jewelry_coupon_saved_amt> 0 then 1 else 0 end) as business_specific_non_jewelry_coupon_saved_amt_trans
  , sum(case when storewide_doff_coupon_saved_amt> 0 then 1 else 0 end) as storewide_doff_coupon_saved_amt_trans
  , sum(case when storewide_poff_coupon_saved_amt> 0 then 1 else 0 end) as storewide_poff_coupon_saved_amt_trans

from pricing_users.blr_transaction_summary_new_CID a 
left join pricing_users.blr_tran_saved_amt_by_price_promo c
on a.tran_seq_no = c.tran_seq_no
left join pricing_users.blr_transaction_coupon_group_summary b
on a.tran_seq_no = b.tran_seq_no
group by 
   a.new_CID
  ,a.tran_datetime
;
-----------------------------------------------------------------------------------------------------------till here-----------------------------------

create table pricing_users.mck_cust_coupon_summary_primary_discount as 
select 
   a.new_CID
  ,a.tran_datetime

  , sum(total_sales) as total_sales
  , sum(total_qty) as total_qty	
-- amt saved by promo
  , sum(total_discount_amt_by_clr_adj_type_code12 + total_discount_amt_by_clr_adj_type_code14) as total_discount_amt_by_clr
  , sum(final_secondary_discount) as final_secondary_discount
  , sum(final_primary_discount) as final_primary_discount
  , sum(p1_sales) as p1_sales
  , sum(total_cogs) as total_cogs

  , sum(case when poff20_non_loyalty_storewide_coupon_saved_amt> 0 then final_primary_discount else 0 end) as poff20_non_loyalty_storewide_coupon_saved_amt_trans_final_primary_discount
  , sum(case when d10off10_loyalty_storewide_coupon_saved_amt> 0 then final_primary_discount else 0 end) as d10off10_loyalty_storewide_coupon_saved_amt_trans_primary_discount
  , sum(case when poff15_non_loyalty_storewide_coupon_saved_amt> 0 then final_primary_discount else 0 end) as poff15_non_loyalty_storewide_coupon_saved_amt_trans_primary_discount
  , sum(case when d10off25_non_loyalty_storewide_coupon_saved_amt> 0 then final_primary_discount else 0 end) as d10off25_non_loyalty_storewide_coupon_saved_amt_trans_primary_discount
  , sum(case when poff30_non_loyalty_storewide_coupon_saved_amt> 0 then final_primary_discount else 0 end) as poff30_non_loyalty_storewide_coupon_saved_amt_trans_primary_discount
  , sum(case when poff25_non_loyalty_storewide_coupon_saved_amt> 0 then final_primary_discount else 0 end) as poff25_non_loyalty_storewide_coupon_saved_amt_trans_primary_discount
  , sum(case when d10off10_non_loyalty_storewide_coupon_saved_amt> 0 then final_primary_discount else 0 end) as d10off10_non_loyalty_storewide_coupon_saved_amt_trans_primary_discount
  , sum(case when poff40_non_loyalty_storewide_coupon_saved_amt> 0 then final_primary_discount else 0 end) as poff40_non_loyalty_storewide_coupon_saved_amt_trans_primary_discount
  , sum(case when poff50_non_loyalty_storewide_coupon_saved_amt> 0 then final_primary_discount else 0 end) as poff50_non_loyalty_storewide_coupon_saved_amt_trans_primary_discount
  , sum(case when poff10_non_loyalty_storewide_coupon_saved_amt> 0 then final_primary_discount else 0 end) as poff10_non_loyalty_storewide_coupon_saved_amt_trans_primary_discount
  , sum(case when poff20_non_loyalty_business_specific_coupon_saved_amt> 0 then final_primary_discount else 0 end) as poff20_non_loyalty_business_specific_coupon_saved_amt_trans_primary_discount
  , sum(case when business_specific_jewelry_coupon_saved_amt> 0 then final_primary_discount else 0 end) as business_specific_jewelry_coupon_saved_amt_trans_primary_discount
  , sum(case when business_specific_non_jewelry_coupon_saved_amt> 0 then final_primary_discount else 0 end) as business_specific_non_jewelry_coupon_saved_amt_trans_primary_discount
  , sum(case when storewide_doff_coupon_saved_amt> 0 then final_primary_discount else 0 end) as storewide_doff_coupon_saved_amt_trans_primary_discount
  , sum(case when storewide_poff_coupon_saved_amt> 0 then final_primary_discount else 0 end) as storewide_poff_coupon_saved_amt_trans_primary_discount


from pricing_users.mck_transaction_summary_new_CID a 
left join pricing_users.mck_tran_saved_amt_by_price_promo c
on a.tran_seq_no = c.tran_seq_no
left join pricing_users.mck_transaction_coupon_group_summary b
on a.tran_seq_no = b.tran_seq_no
group by 
   a.new_CID
  ,a.tran_datetime
;


,sum(case when poff20_non_loyalty_storewide_coupon_saved_amt>0 then total_cogs else 0 end) as poff20_non_loyalty_storewide_coupon_cogs
,sum(case when d10off10_loyalty_storewide_coupon_saved_amt>0 then total_cogs else 0 end) as d10off10_loyalty_storewide_coupon_cogs
,sum(case when poff15_non_loyalty_storewide_coupon_saved_amt>0 then total_cogs else 0 end) as poff15_non_loyalty_storewide_coupon_cogs
,sum(case when d10off25_non_loyalty_storewide_coupon_saved_amt>0 then total_cogs else 0 end) as d10off25_non_loyalty_storewide_coupon_cogs
,sum(case when poff30_non_loyalty_storewide_coupon_saved_amt>0 then total_cogs else 0 end) as poff30_non_loyalty_storewide_coupon_cogs
,sum(case when poff25_non_loyalty_storewide_coupon_saved_amt>0 then total_cogs else 0 end) as poff25_non_loyalty_storewide_coupon_cogs
,sum(case when d10off10_non_loyalty_storewide_coupon_saved_amt>0 then total_cogs else 0 end) as d10off10_non_loyalty_storewide_coupon_cogs
,sum(case when poff40_non_loyalty_storewide_coupon_saved_amt>0 then total_cogs else 0 end) as poff40_non_loyalty_storewide_coupon_cogs
,sum(case when poff50_non_loyalty_storewide_coupon_saved_amt>0 then total_cogs else 0 end) as poff50_non_loyalty_storewide_coupon_cogs
,sum(case when poff10_non_loyalty_storewide_coupon_saved_amt>0 then total_cogs else 0 end) as poff10_non_loyalty_storewide_coupon_cogs
,sum(case when poff20_non_loyalty_business_specific_coupon_saved_amt>0 then total_cogs else 0 end) as poff20_non_loyalty_business_specific_coupon_cogs
,sum(case when business_specific_jewelry_coupon_saved_amt>0 then total_cogs else 0 end) as business_specific_jewelry_coupon_cogs
,sum(case when business_specific_non_jewelry_coupon_saved_amt>0 then total_cogs else 0 end) as business_specific_non_jewelry_coupon_cogs
,sum(case when storewide_doff_coupon_saved_amt>0 then total_cogs else 0 end) as storewide_doff_coupon_cogs
,sum(case when storewide_poff_coupon_saved_amt>0 then total_cogs else 0 end) as storewide_poff_coupon_cogs

create table pricing_users.mck_cust_coupon_summary_saved_p1_qty as 
select 
   a.new_CID
  ,a.tran_datetime

  , sum(total_sales) as total_sales
  , sum(total_qty) as total_qty	
-- amt saved by promo
  , sum(total_discount_amt_by_clr_adj_type_code12 + total_discount_amt_by_clr_adj_type_code14) as total_discount_amt_by_clr
  , sum(final_secondary_discount) as final_secondary_discount
  , sum(final_primary_discount) as final_primary_discount
  , sum(p1_sales) as p1_sales
  , sum(total_cogs) as total_cogs

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


from pricing_users.mck_transaction_summary_new_CID a 
left join pricing_users.mck_tran_saved_amt_by_price_promo c
on a.tran_seq_no = c.tran_seq_no
left join pricing_users.mck_transaction_coupon_group_summary b
on a.tran_seq_no = b.tran_seq_no
group by 
   a.new_CID
  ,a.tran_datetime
;


  , sum(case when poff20_non_loyalty_storewide_coupon_saved_amt> 0 then 1 else 0 end) as poff20_non_loyalty_storewide_coupon_saved_amt_trans
  , sum(case when d10off10_loyalty_storewide_coupon_saved_amt> 0 then 1 else 0 end) as d10off10_loyalty_storewide_coupon_saved_amt_trans
  , sum(case when poff15_non_loyalty_storewide_coupon_saved_amt> 0 then 1 else 0 end) as poff15_non_loyalty_storewide_coupon_saved_amt_trans
  , sum(case when d10off25_non_loyalty_storewide_coupon_saved_amt> 0 then 1 else 0 end) as d10off25_non_loyalty_storewide_coupon_saved_amt_trans
  , sum(case when poff30_non_loyalty_storewide_coupon_saved_amt> 0 then 1 else 0 end) as poff30_non_loyalty_storewide_coupon_saved_amt_trans
  , sum(case when poff25_non_loyalty_storewide_coupon_saved_amt> 0 then 1 else 0 end) as poff25_non_loyalty_storewide_coupon_saved_amt_trans
  , sum(case when d10off10_non_loyalty_storewide_coupon_saved_amt> 0 then 1 else 0 end) as d10off10_non_loyalty_storewide_coupon_saved_amt_trans
  , sum(case when poff40_non_loyalty_storewide_coupon_saved_amt> 0 then 1 else 0 end) as poff40_non_loyalty_storewide_coupon_saved_amt_trans
  , sum(case when poff50_non_loyalty_storewide_coupon_saved_amt> 0 then 1 else 0 end) as poff50_non_loyalty_storewide_coupon_saved_amt_trans
  , sum(case when poff10_non_loyalty_storewide_coupon_saved_amt> 0 then 1 else 0 end) as poff10_non_loyalty_storewide_coupon_saved_amt_trans
  , sum(case when poff20_non_loyalty_business_specific_coupon_saved_amt> 0 then 1 else 0 end) as poff20_non_loyalty_business_specific_coupon_saved_amt_trans
  , sum(case when business_specific_jewelry_coupon_saved_amt> 0 then 1 else 0 end) as business_specific_jewelry_coupon_saved_amt_trans
  , sum(case when business_specific_non_jewelry_coupon_saved_amt> 0 then 1 else 0 end) as business_specific_non_jewelry_coupon_saved_amt_trans
  , sum(case when storewide_doff_coupon_saved_amt> 0 then 1 else 0 end) as storewide_doff_coupon_saved_amt_trans
  , sum(case when storewide_poff_coupon_saved_amt> 0 then 1 else 0 end) as storewide_poff_coupon_saved_amt_trans





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

#### Step 6 ####
drop table pricing_users.mck_daily_coupon_summary_20180826;
create table pricing_users.mck_daily_coupon_summary_20180826 as 
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



-- primary coupon groups
  ,sum(poff20_non_loyalty_storewide_coupon_saved_amt) as poff20_non_loyalty_storewide_coupon_saved_amt
  ,sum(d10off10_loyalty_storewide_coupon_saved_amt) as d10off10_loyalty_storewide_coupon_saved_amt
  ,sum(poff15_non_loyalty_storewide_coupon_saved_amt) as poff15_non_loyalty_storewide_coupon_saved_amt 
  ,sum(d10off25_non_loyalty_storewide_coupon_saved_amt) as d10off25_non_loyalty_storewide_coupon_saved_amt
  ,sum(poff30_non_loyalty_storewide_coupon_saved_amt) as poff30_non_loyalty_storewide_coupon_saved_amt
  ,sum(poff25_non_loyalty_storewide_coupon_saved_amt) as poff25_non_loyalty_storewide_coupon_saved_amt

  -- secondary coupon groups
  ,sum(d10off10_non_loyalty_storewide_coupon_saved_amt) as d10off10_non_loyalty_storewide_coupon_saved_amt
  ,sum(poff40_non_loyalty_storewide_coupon_saved_amt) as poff40_non_loyalty_storewide_coupon_saved_amt
  ,sum(poff50_non_loyalty_storewide_coupon_saved_amt) as poff50_non_loyalty_storewide_coupon_saved_amt
  ,sum(poff10_non_loyalty_storewide_coupon_saved_amt) as poff10_non_loyalty_storewide_coupon_saved_amt
  ,sum(poff20_non_loyalty_business_specific_coupon_saved_amt) as poff20_non_loyalty_business_specific_coupon_saved_amt

  -- other coupon groups (including jewelry)
  ,sum(business_specific_jewelry_coupon_saved_amt) as business_specific_jewelry_coupon_saved_amt
  ,sum(business_specific_non_jewelry_coupon_saved_amt) as business_specific_non_jewelry_coupon_saved_amt
  ,sum(storewide_doff_coupon_saved_amt) as storewide_doff_coupon_saved_amt
  ,sum(storewide_poff_coupon_saved_amt) as storewide_poff_coupon_saved_amt

from pricing_users.mck_cust_coupon_summary_20190826 
group by
 tran_datetime
;


create table pricing_users.mck_non_coupon_spend_basket as 
select 
   tran_datetime
  ,sum(case when 
	poff20_non_loyalty_storewide_coupon_saved_amt_trans = 0 and 
        d10off10_loyalty_storewide_coupon_saved_amt_trans = 0 and 
	poff15_non_loyalty_storewide_coupon_saved_amt_trans = 0 and
	d10off25_non_loyalty_storewide_coupon_saved_amt_trans = 0 and
	poff30_non_loyalty_storewide_coupon_saved_amt_trans = 0 and 
	poff25_non_loyalty_storewide_coupon_saved_amt_trans = 0 and 
	d10off10_non_loyalty_storewide_coupon_saved_amt_trans = 0 and 
	poff40_non_loyalty_storewide_coupon_saved_amt_trans = 0 and
	poff50_non_loyalty_storewide_coupon_saved_amt_trans = 0 and
	poff10_non_loyalty_storewide_coupon_saved_amt_trans = 0 and
	poff20_non_loyalty_business_specific_coupon_saved_amt_trans = 0 and
	business_specific_jewelry_coupon_saved_amt_trans = 0 and
	business_specific_non_jewelry_coupon_saved_amt_trans = 0 and
	storewide_doff_coupon_saved_amt_trans = 0 and
	storewide_poff_coupon_saved_amt_trans = 0 
            then total_sales else 0 end) as total_trip_spend, 
  ,count(distinct case when 
	poff20_non_loyalty_storewide_coupon_saved_amt_trans = 0 and 
        d10off10_loyalty_storewide_coupon_saved_amt_trans = 0 and 
	poff15_non_loyalty_storewide_coupon_saved_amt_trans = 0 and
	d10off25_non_loyalty_storewide_coupon_saved_amt_trans = 0 and
	poff30_non_loyalty_storewide_coupon_saved_amt_trans = 0 and 
	poff25_non_loyalty_storewide_coupon_saved_amt_trans = 0 and 
	d10off10_non_loyalty_storewide_coupon_saved_amt_trans = 0 and 
	poff40_non_loyalty_storewide_coupon_saved_amt_trans = 0 and
	poff50_non_loyalty_storewide_coupon_saved_amt_trans = 0 and
	poff10_non_loyalty_storewide_coupon_saved_amt_trans = 0 and
	poff20_non_loyalty_business_specific_coupon_saved_amt_trans = 0 and
	business_specific_jewelry_coupon_saved_amt_trans = 0 and
	business_specific_non_jewelry_coupon_saved_amt_trans = 0 and
	storewide_doff_coupon_saved_amt_trans = 0 and
	storewide_poff_coupon_saved_amt_trans = 0 
            then new_CID else 0 end) as total_trips

from pricing_users.mck_cust_coupon_summary_20190826 
group by
 tran_datetime
;


create table pricing_users.mck_daily_coupon_summary_cogs as 
select 
   tran_datetime
  
  ,count(distinct new_CID) as trip
  ,sum(total_sales)/count(distinct new_CID) as avg_basket_size
  ,sum(total_discount_amt_by_clr + final_primary_discount)/sum(p1_sales) as perc_saved_w_non_coupon
  ,sum(final_secondary_discount) as final_secondary_discount
  ,sum(final_primary_discount) as final_primary_discount
  ,sum(p1_sales) as p1_sales
  ,sum(total_cogs) as total_cogs

,sum(poff20_non_loyalty_storewide_coupon_cogs) as poff20_non_loyalty_storewide_coupon_cogs
,sum(d10off10_loyalty_storewide_coupon_cogs) as d10off10_loyalty_storewide_coupon_cogs
,sum(poff15_non_loyalty_storewide_coupon_cogs) as poff15_non_loyalty_storewide_coupon_cogs
,sum(d10off25_non_loyalty_storewide_coupon_cogs) as d10off25_non_loyalty_storewide_coupon_cogs
,sum(poff30_non_loyalty_storewide_coupon_cogs) as poff30_non_loyalty_storewide_coupon_cogs
,sum(poff25_non_loyalty_storewide_coupon_cogs) as poff25_non_loyalty_storewide_coupon_cogs
,sum(d10off10_non_loyalty_storewide_coupon_cogs) as d10off10_non_loyalty_storewide_coupon_cogs
,sum(poff40_non_loyalty_storewide_coupon_cogs) as poff40_non_loyalty_storewide_coupon_cogs
,sum(poff50_non_loyalty_storewide_coupon_cogs) as poff50_non_loyalty_storewide_coupon_cogs
,sum(poff10_non_loyalty_storewide_coupon_cogs) as poff10_non_loyalty_storewide_coupon_cogs
,sum(poff20_non_loyalty_business_specific_coupon_cogs) as poff20_non_loyalty_business_specific_coupon_cogs
,sum(business_specific_jewelry_coupon_cogs) as business_specific_jewelry_coupon_cogs
,sum(business_specific_non_jewelry_coupon_cogs) as business_specific_non_jewelry_coupon_cogs
,sum(storewide_doff_coupon_cogs) as storewide_doff_coupon_cogs
,sum(storewide_poff_coupon_cogs) as storewide_poff_coupon_cogs

from pricing_users.mck_cust_coupon_summary_cogs 
group by tran_datetime
;


create table pricing_users.mck_daily_coupon_summary_primary_discount as 
select 
   tran_datetime
  
  ,count(distinct new_CID) as trip
  ,sum(total_sales)/count(distinct new_CID) as avg_basket_size
  ,sum(total_discount_amt_by_clr + final_primary_discount)/sum(p1_sales) as perc_saved_w_non_coupon
  ,sum(final_secondary_discount) as final_secondary_discount
  ,sum(final_primary_discount) as final_primary_discount
  ,sum(p1_sales) as p1_sales
  ,sum(total_cogs) as total_cogs

,sum(poff20_non_loyalty_storewide_coupon_saved_amt_trans_final_primary_discount) as poff20_non_loyalty_storewide_coupon_saved_amt_trans_final_primary_discount
,sum(d10off10_loyalty_storewide_coupon_saved_amt_trans_primary_discount) as d10off10_loyalty_storewide_coupon_saved_amt_trans_primary_discount
,sum(poff15_non_loyalty_storewide_coupon_saved_amt_trans_primary_discount) as poff15_non_loyalty_storewide_coupon_saved_amt_trans_primary_discount
,sum(d10off25_non_loyalty_storewide_coupon_saved_amt_trans_primary_discount) as d10off25_non_loyalty_storewide_coupon_saved_amt_trans_primary_discount
,sum(poff30_non_loyalty_storewide_coupon_saved_amt_trans_primary_discount) as poff30_non_loyalty_storewide_coupon_saved_amt_trans_primary_discount
,sum(poff25_non_loyalty_storewide_coupon_saved_amt_trans_primary_discount) as poff25_non_loyalty_storewide_coupon_saved_amt_trans_primary_discount
,sum(d10off10_non_loyalty_storewide_coupon_saved_amt_trans_primary_discount) as d10off10_non_loyalty_storewide_coupon_saved_amt_trans_primary_discount
,sum(poff40_non_loyalty_storewide_coupon_saved_amt_trans_primary_discount) as poff40_non_loyalty_storewide_coupon_saved_amt_trans_primary_discount
,sum(poff50_non_loyalty_storewide_coupon_saved_amt_trans_primary_discount) as poff50_non_loyalty_storewide_coupon_saved_amt_trans_primary_discount
,sum(poff10_non_loyalty_storewide_coupon_saved_amt_trans_primary_discount) as poff10_non_loyalty_storewide_coupon_saved_amt_trans_primary_discount
,sum(poff20_non_loyalty_business_specific_coupon_saved_amt_trans_primary_discount) as poff20_non_loyalty_business_specific_coupon_saved_amt_trans_primary_discount
,sum(business_specific_jewelry_coupon_saved_amt_trans_primary_discount) as business_specific_jewelry_coupon_saved_amt_trans_primary_discount
,sum(business_specific_non_jewelry_coupon_saved_amt_trans_primary_discount) as business_specific_non_jewelry_coupon_saved_amt_trans_primary_discount
,sum(storewide_doff_coupon_saved_amt_trans_primary_discount) as storewide_doff_coupon_saved_amt_trans_primary_discount
,sum(storewide_poff_coupon_saved_amt_trans_primary_discount) as storewide_poff_coupon_saved_amt_trans_primary_discount

from pricing_users.mck_cust_coupon_summary_primary_discount 
group by tran_datetime
;



create table pricing_users.mck_daily_coupon_cogs_summary_20190924 as
select 
   tran_datetime
  
  ,count(distinct new_CID) as trip
  ,sum(total_sales)/count(distinct new_CID) as avg_basket_size
  ,sum(total_discount_amt_by_clr + final_primary_discount)/sum(p1_sales) as perc_saved_w_non_coupon
  ,sum(final_secondary_discount) as final_secondary_discount
  ,sum(final_primary_discount) as final_primary_discount
  ,sum(p1_sales) as p1_sales
  ,sum(total_cogs) as total_cogs

,sum(poff20_non_loyalty_storewide_coupon_saved_total_qty) as poff20_non_loyalty_storewide_coupon_saved_total_qty
,sum(d10off10_loyalty_storewide_coupon_saved_total_qty) as d10off10_loyalty_storewide_coupon_saved_total_qty
,sum(poff15_non_loyalty_storewide_coupon_saved_total_qty) as poff15_non_loyalty_storewide_coupon_saved_total_qty
,sum(d10off25_non_loyalty_storewide_coupon_saved_total_qty) as d10off25_non_loyalty_storewide_coupon_saved_total_qty
,sum(poff30_non_loyalty_storewide_coupon_saved_total_qty) as poff30_non_loyalty_storewide_coupon_saved_total_qty
,sum(poff25_non_loyalty_storewide_coupon_saved_total_qty) as poff25_non_loyalty_storewide_coupon_saved_total_qty
,sum(d10off10_non_loyalty_storewide_coupon_saved_total_qty) as d10off10_non_loyalty_storewide_coupon_saved_total_qty
,sum(poff40_non_loyalty_storewide_coupon_saved_total_qty) as poff40_non_loyalty_storewide_coupon_saved_total_qty
,sum(poff50_non_loyalty_storewide_coupon_saved_total_qty) as poff50_non_loyalty_storewide_coupon_saved_total_qty
,sum(poff10_non_loyalty_storewide_coupon_saved_total_qty) as poff10_non_loyalty_storewide_coupon_saved_total_qty
,sum(poff20_non_loyalty_business_specific_coupon_saved_total_qty) as poff20_non_loyalty_business_specific_coupon_saved_total_qty
,sum(business_specific_jewelry_coupon_saved_total_qty) as business_specific_jewelry_coupon_saved_total_qty
,sum(business_specific_non_jewelry_coupon_saved_total_qty) as business_specific_non_jewelry_coupon_saved_total_qty
,sum(storewide_doff_coupon_saved_total_qty) as storewide_doff_coupon_saved_total_qty
,sum(storewide_poff_coupon_saved_total_qty) as storewide_poff_coupon_saved_total_qty


,sum(poff20_non_loyalty_storewide_coupon_saved_p1_sales) as poff20_non_loyalty_storewide_coupon_saved_p1_sales
,sum(d10off10_loyalty_storewide_coupon_saved_p1_sales) as d10off10_loyalty_storewide_coupon_saved_p1_sales
,sum(poff15_non_loyalty_storewide_coupon_saved_p1_sales) as poff15_non_loyalty_storewide_coupon_saved_p1_sales
,sum(d10off25_non_loyalty_storewide_coupon_saved_p1_sales) as d10off25_non_loyalty_storewide_coupon_saved_p1_sales
,sum(poff30_non_loyalty_storewide_coupon_saved_p1_sales) as poff30_non_loyalty_storewide_coupon_saved_p1_sales
,sum(poff25_non_loyalty_storewide_coupon_saved_p1_sales) as poff25_non_loyalty_storewide_coupon_saved_p1_sales
,sum(d10off10_non_loyalty_storewide_coupon_saved_p1_sales) as d10off10_non_loyalty_storewide_coupon_saved_p1_sales
,sum(poff40_non_loyalty_storewide_coupon_saved_p1_sales) as poff40_non_loyalty_storewide_coupon_saved_p1_sales
,sum(poff50_non_loyalty_storewide_coupon_saved_p1_sales) as poff50_non_loyalty_storewide_coupon_saved_p1_sales
,sum(poff10_non_loyalty_storewide_coupon_saved_p1_sales) as poff10_non_loyalty_storewide_coupon_saved_p1_sales
,sum(poff20_non_loyalty_business_specific_coupon_saved_p1_sales) as poff20_non_loyalty_business_specific_coupon_saved_p1_sales
,sum(business_specific_jewelry_coupon_saved_p1_sales) as business_specific_jewelry_coupon_saved_p1_sales
,sum(business_specific_non_jewelry_coupon_saved_p1_sales) as business_specific_non_jewelry_coupon_saved_p1_sales
,sum(storewide_doff_coupon_saved_p1_sales) as storewide_doff_coupon_saved_p1_sales
,sum(storewide_poff_coupon_saved_p1_sales) as storewide_poff_coupon_saved_p1_sales

,sum(poff20_non_loyalty_storewide_coupon_saved_sales) as poff20_non_loyalty_storewide_coupon_saved_sales
,sum(d10off10_loyalty_storewide_coupon_saved_sales) as d10off10_loyalty_storewide_coupon_saved_sales
,sum(poff15_non_loyalty_storewide_coupon_saved_sales) as poff15_non_loyalty_storewide_coupon_saved_sales
,sum(d10off25_non_loyalty_storewide_coupon_saved_sales) as d10off25_non_loyalty_storewide_coupon_saved_sales
,sum(poff30_non_loyalty_storewide_coupon_saved_sales) as poff30_non_loyalty_storewide_coupon_saved_sales
,sum(poff25_non_loyalty_storewide_coupon_saved_sales) as poff25_non_loyalty_storewide_coupon_saved_sales
,sum(d10off10_non_loyalty_storewide_coupon_saved_sales) as d10off10_non_loyalty_storewide_coupon_saved_sales
,sum(poff40_non_loyalty_storewide_coupon_saved_sales) as poff40_non_loyalty_storewide_coupon_saved_sales
,sum(poff50_non_loyalty_storewide_coupon_saved_sales) as poff50_non_loyalty_storewide_coupon_saved_sales
,sum(poff10_non_loyalty_storewide_coupon_saved_sales) as poff10_non_loyalty_storewide_coupon_saved_sales
,sum(poff20_non_loyalty_business_specific_coupon_saved_sales) as poff20_non_loyalty_business_specific_coupon_saved_sales
,sum(business_specific_jewelry_coupon_saved_sales) as business_specific_jewelry_coupon_saved_sales
,sum(business_specific_non_jewelry_coupon_saved_sales) as business_specific_non_jewelry_coupon_saved_sales
,sum(storewide_doff_coupon_saved_sales) as storewide_doff_coupon_saved_sales
,sum(storewide_poff_coupon_saved_sales) as storewide_poff_coupon_saved_sales


from pricing_users.mck_cust_coupon_summary_saved_p1_qty a

group by
 tran_datetime
;




-- check
select 
count(distinct new_CID) 
from pricing_users.mck_transaction_summary_new_CID a 
left join pricing_users.mck_transaction_coupon_group_summary b
on a.tran_seq_no = b.tran_seq_no
where a.tran_datetime = '2019-06-05'
and poff20_non_loyalty_storewide_coupon_saved_amt>0
;


select * from pricing_users.mck_daily_coupon_summary 
where business_specific_jewelry_coupon_saved_amt is null 
or business_specific_jewelry_coupon_saved_amt = "";

-- there are three days where 

--20190909
create table pricing_users.mck_sublot_daily_p1p2_price as 
select 
  tran_datetime
, dept * 10000 + lot_num as sub_lot
, avg(final_p1) as P1_Price
, avg(final_p2) as P2_Price
, sum(item_ord_qty) as Quantity
, sum(final_p1 * item_ord_qty) as p1_sales
, sum(final_p2 * item_ord_qty) as p2_sales
, sum(final_primary_discount * item_ord_qty) as final_primary_discount
, sum(final_secondary_discount * item_ord_qty) as final_secondary_discount
,sum(actual_rtl_amt) as total_sales
,sum(item_ord_qty) as total_qty
from pricing_users.mck_resa_combined_filtered_wor_v2_after_store_filter_w_p1_p2_from_resa_no_gaps_jx
where tran_datetime between '2018-07-01' and '2019-06-30'
group by
tran_datetime, 
dept * 10000 + lot_num
;



set hive.resultset.use.unique.column.names=false;

create table pricing_users.mck_sublot_daily_p1p2_price_w_hier as 
select distinct * from (
select 
b.division,
b.div_name,
b.group_no,
b.group_name,
b.dept,
b.dept_name,
a.*
from pricing_users.mck_sublot_daily_p1p2_price a 
join jcp.rms_merch_hierarchy b
on cast(a.sub_lot as int) = cast(b.legacy_lot as int)) x
;



set hive.resultset.use.unique.column.names=false;
select * from pricing_users.mck_sublot_daily_p1p2_price_w_hier;

