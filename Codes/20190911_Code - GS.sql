	#### Step 1 ####
-----join the item transaction and discount tables------
--drop table pricing_users.mck_resa_discount_instore_valid_trans_with_orin purge;
drop table pricing_users.blr_resa_discount_instore_valid_trans_with_orin purge;
create table pricing_users.blr_resa_discount_instore_valid_trans_with_orin as
select 
a.item,
a.entity_code, 
a.dept, 
a.brand_code,
b.*
from pricing_users.blr_resa_item_instore_valid_trans a 
left join pricing_users.blr_resa_discount_instore_valid_trans b
on  a.store_num = b.store_num
and a.tran_seq_no = b.tran_seq_no
and a.item_seq_no = b.item_seq_no
and a.tran_datetime = b.tran_datetime
and a.terminal_num = b.terminal_num
;
--2343600046



#### Step 2 ####
----get the discount data at hierarchy level----
drop table pricing_users.blr_resa_discount_instore_valid_trans_with_sub purge ;
--2343598852
create table pricing_users.blr_resa_discount_instore_valid_trans_with_sub as
select
  b.division
 ,b.div_name
 ,b.group_name
 ,b.dept_name
 ,b.brand_nm
 ,b.item_type_nm
 ,b.prod_type_hier_nm
 ,a.* 
from pricing_users.blr_resa_discount_instore_valid_trans_with_orin  a
left join jcp.rms_merch_hierarchy b
on a.item = b.orin_sku;
--2343600046

---not needed----
#### Step 3 ####
drop table pricing_users.blr_resa_discount_sampled_store_one_year purge;
create table pricing_users.blr_resa_discount_sampled_store_one_year as 
select a.*
from pricing_users.blr_resa_discount_instore_valid_trans_with_sub a
inner join pricing_users.blr_modeling_store_list_tw b
---mck_coupon_summary_rand_store_list b 
on a.store_num = b.store
where a.tran_datetime between '2019-03-09' and '2020-03-08'
;

--not needed----
drop table pricing_users.blr_resa_item_instore_valid_trans_sample_store purge;
create table pricing_users.blr_resa_item_instore_valid_trans_sample_store
as select a.* 
from pricing_users.blr_resa_item_instore_valid_trans  a
join pricing_users.blr_modeling_store_list_tw b
on a.store_num = b.store
where a.tran_datetime between '2019-03-09' and '2020-03-08'
;

----not needed----
#### Step 4 ####
drop table pricing_users.blr_resa_item_instore_valid_trans_sample_store_transaction_summary_TW purge;
create table pricing_users.BLR_resa_item_instore_valid_trans_sample_store_transaction_summary_TW as 
select 
tran_seq_no, 
tran_datetime, 
store_num, 
terminal_num,
sum(item_ord_qty) as total_units, 
sum(actual_rtl_amt) as total_sales
from pricing_users.BLR_resa_item_instore_valid_trans_sample_store
where entity_code not in (55)
and item_status_code in ('S','ORD')
group by 
tran_seq_no, 
tran_datetime, 
store_num, 
terminal_num
;


#### Step 5 ####
Upload coupon data into Hive.

--not needed---
#### Step 6 ####
drop table pricing_users.mck_trans_discount_w_coupon_sampled_one_year_tw;
create table pricing_users.blr_trans_discount_w_coupon_sampled_one_year_tw as
select 
 tran_seq_no
  ,tran_datetime 
  ,store_num
  ,item_seq_no
  ,terminal_num
  ,division
  ,div_name
  ,entity_code
  ,group_name
  ,dept
  ,dept_name
  ,brand_code
  ,brand_nm
  ,item_type_nm
  ,prod_type_hier_nm 
  ,item,
  value_off 
 ,type_off
 ,type_value_off   
 ,coupon_type_adj
 ,loyalty_flag    
 ,bmgm_flag
  ,substring(coupon_no, 3, 6) as coupon_code
  ,sum(unit_discount_amt * qty) as coupon_saved_amt
from pricing_users.blr_resa_discount_sampled_store_one_year a 
inner join pricing_users.20191105_barcode_sub_vF2 b
on (case when substring(coupon_no, 1, 2) = 'MC' then substring(coupon_no, 3, 6) else 'OTHER' end) = cast(barcode_id as string) 
and cast(a.dept as int) = cast(b.sub as int)
where substring(coupon_no, 1, 2) = 'MC' -- filter out transactions with a coupon 
group by 
   tran_seq_no
  ,tran_datetime 
  ,store_num
  ,item_seq_no
  ,terminal_num
  ,division
  ,div_name
  ,entity_code
  ,group_name
  ,dept
  ,dept_name
  ,brand_code
  ,brand_nm
  ,item_type_nm
  ,prod_type_hier_nm 
  ,item
  ,value_off 
 ,type_off
 ,type_value_off    --these columns not there in any of the tables
 ,coupon_type_adj
 ,loyalty_flag    
 ,bmgm_flag
  ,substring(coupon_no, 3, 6) 
;



---not needed----
#### Step 7 #### 
--drop table pricing_users.mck_coupon_summary ; 
create table pricing_users.blr_coupon_summary as
select 
  y.value_off 
 ,y.type_off
 ,y.type_value_off    
 ,y.coupon_type_adj
 ,y.loyalty_flag    
 ,y.bmgm_flag
 ,y.coupon_saved_amt 
 ,x.total_sales
 ,y.cnt_distinct_coupon_tran
from 
(
select 
  value_off 
 ,type_off
 ,type_value_off
 ,coupon_type_adj
 ,loyalty_flag    
 ,bmgm_flag
 ,sum(total_sales) as total_sales
from pricing_users.blr_resa_item_instore_valid_trans_sample_store_transaction_summary_TW a
inner join pricing_users.blr_trans_discount_w_coupon_sampled_one_year_tw b
on  a.store_num = b.store_num
and a.tran_seq_no = b.tran_seq_no
--and a.item_seq_no = b.item_seq_no
and a.tran_datetime = b.tran_datetime
and a.terminal_num = b.terminal_num

--where a.tran_datetime between '2018-10-27'  
group by value_off 
 ,type_off
 ,type_value_off
 ,coupon_type_adj
 ,loyalty_flag    
 ,bmgm_flag
) x 
inner join 
(
select 
  value_off 
 ,type_off
 ,type_value_off
 ,coupon_type_adj
 ,loyalty_flag    
 ,bmgm_flag
 ,sum(coupon_saved_amt) as coupon_saved_amt 
 ,count(distinct tran_seq_no) as cnt_distinct_coupon_tran
from pricing_users.blr_trans_discount_w_coupon_sampled_one_year_tw 
--where tran_datetime='2018-10-27'
group by 
  value_off 
 ,type_off
 ,type_value_off
 ,coupon_type_adj
 ,loyalty_flag    
 ,bmgm_flag
) y
on x.value_off = y.value_off
and x.type_off = y.type_off
and x.type_value_off = y.type_value_off
and x.coupon_type_adj = y.coupon_type_adj 
and x.loyalty_flag = y.loyalty_flag
and x.bmgm_flag = y.bmgm_flag
;

--not needed---
#### Step 8 ####
drop table pricing_users.mck_dept_daily_total_trn_amt_cnt;
create table pricing_users.mck_dept_daily_total_trn_amt_cnt as
select
  final_customer_backed_category_mapping
 ,final_model_level
 ,a.tran_datetime
 ,count(distinct tran_seq_no) as cnt_dist_trans
 ,sum(actual_rtl_amt) as total_sales
from pricing_users.mck_resa_combined_filtered_woR_filtered_store a 
inner join pricing_users.product_category_mapping_w_brand_group_footwear b
on cast(a.item as int) = cast(b.orin_sku as int)	
where sellable_ind = 'Y'
group by 
  final_customer_backed_category_mapping
 ,final_model_level
 ,a.tran_datetime
;

#### Step 9 ####
---join the transaction,coupon and business type data to get the coupon wise saved amount at transaction and hierarchy levels---
--drop table pricing_users.mck_trans_item_coupon_groups_transposed_v2 purge;
drop table pricing_users.blr_trans_item_coupon_groups_transposed_v2 purge;
create table pricing_users.blr_trans_item_coupon_groups_transposed_v2 as 
select 
   tran_seq_no
  ,tran_datetime 
  ,store_num
  ,item_seq_no
  ,terminal_num    
  ,division
  ,div_name
  ,entity_code
  ,group_name
  ,a.dept
  ,a.dept_name
  ,c.business_type
  ,brand_code
  ,brand_nm
  ,item_type_nm
  ,prod_type_hier_nm 
  ,item

  -- primary coupon groups
  ,sum(case when coupon_group = '20 P_0_Storewide' then unit_discount_amt * qty else 0 end) as Poff20_non_loyalty_storewide_coupon_saved_amt
  ,sum(case when coupon_group = '10 D 10Doff_1_Storewide' then unit_discount_amt * qty else 0 end) as D10off10_loyalty_storewide_coupon_saved_amt
  ,sum(case when coupon_group = '15 P_0_Storewide' then unit_discount_amt * qty else 0 end) as Poff15_non_loyalty_storewide_coupon_saved_amt
  ,sum(case when coupon_group = '10 D 23Doff_0_Storewide' then unit_discount_amt * qty else 0 end) as D10off25_non_loyalty_storewide_coupon_saved_amt
  ,sum(case when coupon_group = '30 P_0_Storewide' then unit_discount_amt * qty else 0 end) as Poff30_non_loyalty_storewide_coupon_saved_amt
  ,sum(case when coupon_group = '25 P_0_Storewide' then unit_discount_amt * qty else 0 end) as Poff25_non_loyalty_storewide_coupon_saved_amt

  -- secondary coupon groups
  ,sum(case when coupon_group = '10 D 10Doff_0_Storewide' then unit_discount_amt * qty else 0 end) as D10off10_non_loyalty_storewide_coupon_saved_amt
  ,sum(case when coupon_group = '40 P_0_Storewide' then unit_discount_amt * qty else 0 end) as Poff40_non_loyalty_storewide_coupon_saved_amt
  ,sum(case when coupon_group = '50 P_0_Storewide' then unit_discount_amt * qty else 0 end) as Poff50_non_loyalty_storewide_coupon_saved_amt
  ,sum(case when coupon_group = '10 P_0_Storewide' then unit_discount_amt * qty else 0 end) as Poff10_non_loyalty_storewide_coupon_saved_amt
  ,sum(case when coupon_group = '20 P_0_Business Specific' then unit_discount_amt * qty else 0 end) as Poff20_non_loyalty_business_specific_coupon_saved_amt

  -- other coupon groups 
  ,sum(case when (coupon_group = 'D_Business Specific' or coupon_group = 'P_Business Specific') and division = 5 then unit_discount_amt * qty else 0 end) as Business_specific_jewelry_coupon_saved_amt
  ,sum(case when (coupon_group = 'D_Business Specific' or coupon_group = 'P_Business Specific') and division <> 5 then unit_discount_amt * qty else 0 end) as Business_specific_non_jewelry_coupon_saved_amt
  ,sum(case when coupon_group = 'D_Storewide' then unit_discount_amt * qty else 0 end) as Storewide_doff_coupon_saved_amt
  ,sum(case when coupon_group = 'P_Storewide' then unit_discount_amt * qty else 0 end) as Storewide_poff_coupon_saved_amt

from pricing_users.blr_resa_discount_instore_valid_trans_with_sub  a --transaction table---
inner join (select * from pricing_users.barcode_coupun_model where coupon_group <> 'coupon_group') b ---coupon data---
on (case when substring(coupon_no, 1, 2) = 'MC' then substring(coupon_no, 3, 6) else 'OTHER' end) = cast(cast(barcode_id as int) as string) 
and cast(a.dept as int) = cast(b.sub as int)
inner join pricing_users.blr_dept_business_type_20190808 c  --business type table--
on cast(a.dept as int) = cast(c.dept as int)
where substring(coupon_no, 1, 2) = 'MC' -- filter out transactions with a coupon 
and c.business_type in ('MRD', 'CNS', 'SRE') --filter on the business types---
group by 
   tran_seq_no
  ,tran_datetime 
  ,store_num
  ,item_seq_no
  ,terminal_num
  ,division
  ,div_name
  ,entity_code
  ,group_name
  ,a.dept
  ,a.dept_name
  ,c.business_type
  ,brand_code
  ,brand_nm
  ,item_type_nm
  ,prod_type_hier_nm 
  ,item
;


-----not needed---
#### Step 10 #### 
drop table pricing_users.mck_new_cat_daily_coupon_trn_amt_cnt;
create table pricing_users.mck_new_cat_daily_coupon_trn_amt_cnt as
select  
   final_customer_backed_category_mapping
  ,final_model_level
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


  -- primary coupon groups
  ,coalesce(count(distinct case when Poff20_non_loyalty_storewide_coupon_saved_amt > 0 then tran_seq_no end),0) as Poff20_non_loyalty_storewide_trn_cnt
  ,coalesce(count(distinct case when D10off10_loyalty_storewide_coupon_saved_amt > 0 then tran_seq_no end),0) as D10off10_loyalty_storewide_trn_cnt
  ,coalesce(count(distinct case when Poff15_non_loyalty_storewide_coupon_saved_amt > 0 then tran_seq_no end),0) as Poff15_non_loyalty_storewide_trn_cnt
  ,coalesce(count(distinct case when d10off25_non_loyalty_storewide_coupon_saved_amt > 0 then tran_seq_no end),0) as d10off25_non_loyalty_storewide_trn_cnt
  ,coalesce(count(distinct case when poff30_non_loyalty_storewide_coupon_saved_amt > 0 then tran_seq_no end),0) as poff30_non_loyalty_storewide_trn_cnt
  ,coalesce(count(distinct case when poff25_non_loyalty_storewide_coupon_saved_amt > 0 then tran_seq_no end),0) as poff25_non_loyalty_storewide_trn_cnt


  -- secondary coupon groups
  ,coalesce(count(distinct case when d10off10_non_loyalty_storewide_coupon_saved_amt > 0 then tran_seq_no end),0) as d10off10_non_loyalty_storewide_trn_cnt
  ,coalesce(count(distinct case when poff40_non_loyalty_storewide_coupon_saved_amt > 0 then tran_seq_no end),0) as poff40_non_loyalty_storewide_trn_cnt
  ,coalesce(count(distinct case when poff50_non_loyalty_storewide_coupon_saved_amt> 0 then tran_seq_no end),0) as poff50_non_loyalty_storewide_trn_cnt
  ,coalesce(count(distinct case when poff10_non_loyalty_storewide_coupon_saved_amt > 0 then tran_seq_no end),0) as poff10_non_loyalty_storewide_trn_cnt
  ,coalesce(count(distinct case when poff20_non_loyalty_business_specific_coupon_saved_amt> 0 then tran_seq_no end),0) as poff20_non_loyalty_business_specific_trn_cnt	

  -- other coupon groups (including jewelry)
  ,coalesce(count(distinct case when business_specific_jewelry_coupon_saved_amt > 0 then tran_seq_no end),0) as business_specific_jewelry_trn_cnt
  ,coalesce(count(distinct case when business_specific_non_jewelry_coupon_saved_amt > 0 then tran_seq_no end),0) as business_specific_non_jewelry_trn_cnt
  ,coalesce(count(distinct case when storewide_doff_coupon_saved_amt > 0 then tran_seq_no end),0) as storewide_doff_trn_cnt
  ,coalesce(count(distinct case when storewide_poff_coupon_saved_amt > 0 then tran_seq_no end),0) as storewide_poff_tnr_cnt

from pricing_users.mck_trans_item_coupon_groups_transposed_v2 a 
inner join (
select * from pricing_users.mck_dept_business_type_20190808
where business_type in ('MRD','CNS','SRE')
) c
on a.dept = c.dept
inner join pricing_users.product_category_mapping_w_brand_group_footwear b
on cast(a.item as int) = cast(b.orin_sku as int)	
where sellable_ind = 'Y'
group by 
   final_customer_backed_category_mapping
  ,final_model_level
  ,tran_datetime
;

20191105_barcode_sub_vF2


#### Step 11 ####--not needed---
drop table pricing_users.mck_new_cat_daily_coupon_trn_perc ;
create table pricing_users.mck_new_cat_daily_coupon_trn_perc as
select 
   a.final_customer_backed_category_mapping
  ,a.final_model_level
  ,a.tran_datetime

  ,coalesce(poff20_non_loyalty_storewide_coupon_saved_amt,0) as poff20_non_loyalty_storewide_coupon_saved_amt
  ,coalesce(d10off10_loyalty_storewide_coupon_saved_amt,0) as d10off10_loyalty_storewide_coupon_saved_amt
  ,coalesce(poff15_non_loyalty_storewide_coupon_saved_amt,0) as poff15_non_loyalty_storewide_coupon_saved_amt
  ,coalesce(d10off25_non_loyalty_storewide_coupon_saved_amt,0) as d10off25_non_loyalty_storewide_coupon_saved_amt
  ,coalesce(poff30_non_loyalty_storewide_coupon_saved_amt,0) as poff30_non_loyalty_storewide_coupon_saved_amt
  ,coalesce(poff25_non_loyalty_storewide_coupon_saved_amt,0) as poff25_non_loyalty_storewide_coupon_saved_amt
  ,coalesce(d10off10_non_loyalty_storewide_coupon_saved_amt,0) as d10off10_non_loyalty_storewide_coupon_saved_amt
  ,coalesce(poff40_non_loyalty_storewide_coupon_saved_amt,0) as poff40_non_loyalty_storewide_coupon_saved_amt
  ,coalesce(poff50_non_loyalty_storewide_coupon_saved_amt,0) as poff50_non_loyalty_storewide_coupon_saved_amt
  ,coalesce(poff10_non_loyalty_storewide_coupon_saved_amt,0) as poff10_non_loyalty_storewide_coupon_saved_amt
  ,coalesce(poff20_non_loyalty_business_specific_coupon_saved_amt,0) as poff20_non_loyalty_business_specific_coupon_saved_amt
  ,coalesce(business_specific_jewelry_coupon_saved_amt,0) as business_specific_jewelry_coupon_saved_amt
  ,coalesce(business_specific_non_jewelry_coupon_saved_amt,0) as business_specific_non_jewelry_coupon_saved_amt
  ,coalesce(storewide_doff_coupon_saved_amt,0) as storewide_doff_coupon_saved_amt
  ,coalesce(storewide_poff_coupon_saved_amt,0) as storewide_poff_coupon_saved_amt

  ,coalesce(round(case when cnt_dist_trans>=poff20_non_loyalty_storewide_trn_cnt then poff20_non_loyalty_storewide_trn_cnt/cnt_dist_trans else 1 end,4),0) as perc_poff20_non_loyalty_storewide_trn_cnt
  ,coalesce(round(case when cnt_dist_trans>=d10off10_loyalty_storewide_trn_cnt then d10off10_loyalty_storewide_trn_cnt/cnt_dist_trans else 1 end,4),0) as perc_d10off10_loyalty_storewide_trn_cnt
  ,coalesce(round(case when cnt_dist_trans>=poff15_non_loyalty_storewide_trn_cnt then poff15_non_loyalty_storewide_trn_cnt/cnt_dist_trans else 1 end,4),0) as perc_poff15_non_loyalty_storewide_trn_cnt
  ,coalesce(round(case when cnt_dist_trans>=d10off25_non_loyalty_storewide_trn_cnt then d10off25_non_loyalty_storewide_trn_cnt/cnt_dist_trans else 1 end,4),0) as perc_d10off25_non_loyalty_storewide_trn_cnt
  ,coalesce(round(case when cnt_dist_trans>=poff30_non_loyalty_storewide_trn_cnt then poff30_non_loyalty_storewide_trn_cnt/cnt_dist_trans else 1 end,4),0) as perc_poff30_non_loyalty_storewide_trn_cnt
  ,coalesce(round(case when cnt_dist_trans>=poff25_non_loyalty_storewide_trn_cnt then poff25_non_loyalty_storewide_trn_cnt/cnt_dist_trans else 1 end,4),0) as perc_poff25_non_loyalty_storewide_trn_cnt
  ,coalesce(round(case when cnt_dist_trans>=d10off10_non_loyalty_storewide_trn_cnt then d10off10_non_loyalty_storewide_trn_cnt/cnt_dist_trans else 1 end,4),0) as perc_d10off10_non_loyalty_storewide_trn_cnt
  ,coalesce(round(case when cnt_dist_trans>=poff40_non_loyalty_storewide_trn_cnt then poff40_non_loyalty_storewide_trn_cnt/cnt_dist_trans else 1 end,4),0) as perc_poff40_non_loyalty_storewide_trn_cnt
  ,coalesce(round(case when cnt_dist_trans>=poff50_non_loyalty_storewide_trn_cnt then poff50_non_loyalty_storewide_trn_cnt/cnt_dist_trans else 1 end,4),0) as perc_poff50_non_loyalty_storewide_trn_cnt
  ,coalesce(round(case when cnt_dist_trans>=poff10_non_loyalty_storewide_trn_cnt then poff10_non_loyalty_storewide_trn_cnt/cnt_dist_trans else 1 end,4),0) as perc_poff10_non_loyalty_storewide_trn_cnt
  ,coalesce(round(case when cnt_dist_trans>=poff20_non_loyalty_business_specific_trn_cnt then poff20_non_loyalty_business_specific_trn_cnt/cnt_dist_trans else 1 end,4),0) as perc_poff20_non_loyalty_business_specific_trn_cnt
  ,coalesce(round(case when cnt_dist_trans>=business_specific_jewelry_trn_cnt then business_specific_jewelry_trn_cnt/cnt_dist_trans else 1 end,4),0) as perc_business_specific_jewelry_trn_cnt
  ,coalesce(round(case when cnt_dist_trans>=business_specific_non_jewelry_trn_cnt then business_specific_non_jewelry_trn_cnt/cnt_dist_trans else 1 end,4),0) as perc_business_specific_non_jewelry_trn_cnt
  ,coalesce(round(case when cnt_dist_trans>=storewide_doff_trn_cnt then storewide_doff_trn_cnt/cnt_dist_trans else 1 end,4),0) as perc_storewide_doff_trn_cnt
  ,coalesce(round(case when cnt_dist_trans>=storewide_poff_tnr_cnt then storewide_poff_tnr_cnt/cnt_dist_trans else 1 end,4),0) as perc_storewide_poff_tnr_cnt

from pricing_users.mck_dept_daily_total_trn_amt_cnt a 
left join pricing_users.mck_new_cat_daily_coupon_trn_amt_cnt b
on a.final_model_level = b.final_model_level
and a.tran_datetime = b.tran_datetime;



#### Archived ####

create table pricing_users.mck_trans_item_daily_coupon_amt as 
select 
   store_num
  ,tran_seq_no 
  ,item_seq_no 
  ,tran_datetime
  ,terminal_num 
  ,tran_datetime 
  ,division
  ,div_name
  ,entity_code
  ,group_name
  ,dept
  ,dept_name
  ,brand_code
  ,brand_nm
  ,item_type_nm
  ,prod_type_hier_nm 
  ,item
  ,case when substring(coupon_no, 1, 2) = 'MC' then substring(coupon_no, 3, 6) else 'OTHER' end as coupon_code
  ,sum(unit_discount_amt * qty) as coupon_saved_amt
from pricing_users.mck_resa_discount_instore_valid_trans_with_sub 
where coupon_no is not null and coupon_no <> '' -- filter out transactions with a coupon 
group by 
   tran_datetime 
  ,division
  ,div_name
  ,entity_code
  ,group_name
  ,dept
  ,dept_name
  ,brand_code
  ,brand_nm
  ,item_type_nm
  ,prod_type_hier_nm 
  ,item
  ,case when substring(coupon_no, 1, 2) = 'MC' then substring(coupon_no, 3, 6) else 'OTHER' end
;


drop table pricing_users.mck_dept_daily_coupon_trn_amt_cnt;
create table pricing_users.mck_dept_daily_coupon_trn_amt_cnt as
select 
   tran_datetime
  ,division
  ,div_name
  ,entity_code
  ,group_name
  ,dept
  ,dept_name

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


  -- primary coupon groups
  ,coalesce(count(distinct case when Poff20_non_loyalty_storewide_coupon_saved_amt > 0 then tran_seq_no end),0) as Poff20_non_loyalty_storewide_trn_cnt
  ,coalesce(count(distinct case when D10off10_loyalty_storewide_coupon_saved_amt > 0 then tran_seq_no end),0) as D10off10_loyalty_storewide_trn_cnt
  ,coalesce(count(distinct case when Poff15_non_loyalty_storewide_coupon_saved_amt > 0 then tran_seq_no end),0) as Poff15_non_loyalty_storewide_trn_cnt
  ,coalesce(count(distinct case when d10off25_non_loyalty_storewide_coupon_saved_amt > 0 then tran_seq_no end),0) as d10off25_non_loyalty_storewide_trn_cnt
  ,coalesce(count(distinct case when poff30_non_loyalty_storewide_coupon_saved_amt > 0 then tran_seq_no end),0) as poff30_non_loyalty_storewide_trn_cnt
  ,coalesce(count(distinct case when poff25_non_loyalty_storewide_coupon_saved_amt > 0 then tran_seq_no end),0) as poff25_non_loyalty_storewide_trn_cnt


  -- secondary coupon groups
  ,coalesce(count(distinct case when d10off10_non_loyalty_storewide_coupon_saved_amt > 0 then tran_seq_no end),0) as d10off10_non_loyalty_storewide_trn_cnt
  ,coalesce(count(distinct case when poff40_non_loyalty_storewide_coupon_saved_amt > 0 then tran_seq_no end),0) as poff40_non_loyalty_storewide_trn_cnt
  ,coalesce(count(distinct case when poff50_non_loyalty_storewide_coupon_saved_amt> 0 then tran_seq_no end),0) as poff50_non_loyalty_storewide_trn_cnt
  ,coalesce(count(distinct case when poff10_non_loyalty_storewide_coupon_saved_amt > 0 then tran_seq_no end),0) as poff10_non_loyalty_storewide_trn_cnt
  ,coalesce(count(distinct case when poff20_non_loyalty_business_specific_coupon_saved_amt> 0 then tran_seq_no end),0) as poff20_non_loyalty_business_specific_trn_cnt	

  -- other coupon groups (including jewelry)
  ,coalesce(count(distinct case when business_specific_jewelry_coupon_saved_amt > 0 then tran_seq_no end),0) as business_specific_jewelry_trn_cnt
  ,coalesce(count(distinct case when business_specific_non_jewelry_coupon_saved_amt > 0 then tran_seq_no end),0) as business_specific_non_jewelry_trn_cnt
  ,coalesce(count(distinct case when storewide_doff_coupon_saved_amt > 0 then tran_seq_no end),0) as storewide_doff_trn_cnt
  ,coalesce(count(distinct case when storewide_poff_coupon_saved_amt > 0 then tran_seq_no end),0) as storewide_poff_tnr_cnt

from pricing_users.mck_trans_item_coupon_groups_transposed
group by 
   tran_datetime
  ,division
  ,div_name
  ,entity_code
  ,group_name
  ,dept
  ,dept_name
;

