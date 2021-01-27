#### Step 1 ####
---6/24/2017	10/19/2019

---pricing_users.mck_tw_store_item_weekly_filtered_inventory_abs_neg
---24162861535
----GETTING THE INVENTORY DATA FOR ITEMS HAVING INVENTORY ON HAND FOR STORES; THE CLEARANCE ITEMS ARE EXCLUDED 
	
	drop view pricing_users.blr_tw_store_item_weekly_filtered_inventory_abs_neg;
	create view pricing_users.blr_tw_store_item_weekly_filtered_inventory_abs_neg as
	select 
	  item
	, dept
	, location as store
	, eow_date
	, unit_cost_amt
	, clear_ind
	, opn_stk_qty
	, cls_stk_qty
	, abs(case when clear_ind = 'Y' then 0 else cls_stk_qty end) as adj_cls_stk_qty  ---exlcude clr items---
	from jcp.item_week_data_vw
	where
	eow_date >= '2017-06-24' and eow_date <= '2020-03-08'  --filter on date---
	and channel_id = 1 --filter for store---
	and location < 3000 --filter for retail store---
	and loc_type = 'S' --filter for retail store---
	and sellable_ind = 'Y'; --filter on sellable items----
---24162861535

#### Step 2 ####
---pricing_users.mck_tw_store_in_scope_total_sales_qty
--845
---GETTING THE TOTAL SALES AND QTY FOR ACTIVE STORE LIST AT STORE LEVEL FOR ONE YEAR
drop table pricing_users.BLR_tw_store_in_scope_total_sales_qty purge;
create table pricing_users.BLR_tw_store_in_scope_total_sales_qty as 
select 
 b.store_num as store
,sum(total_sales) as total_sales
,sum(total_qty) as total_qty
from pricing_users.blr_modeling_store_list_tw a  
inner join pricing_users.blr_resa_consolidated b
on cast(a.store as int) = cast(b.store_num as int)
where b.tran_datetime between '2019-03-09' and '2020-03-08'
group by 
 b.store_num
;
---845


#### Step 3 ####
--pricing_users.mck_tw_in_scope_store_sales_item_weekly_inventory_cleaned
---22974100370
--GETTING THE SALES AND QTY FOR ACTIVE STORES FOR 1 YEAR
drop table pricing_users.BLR_tw_in_scope_store_sales_item_weekly_inventory_cleaned purge;
create table pricing_users.BLR_tw_in_scope_store_sales_item_weekly_inventory_cleaned as 
select 
  b.*
 ,a.total_sales as annual_store_sales
 ,a.total_qty as annual_store_qty
from pricing_users.BLR_tw_store_in_scope_total_sales_qty a
inner join pricing_users.BLR_tw_store_item_weekly_filtered_inventory_abs_neg b 
on a.store = b.store
;
--22974100370
---2019-11-02	2017-06-24

#### Step 4 ####
---pricing_users.mck_tw_item_week_weighted_store_sales
---219749126
---GETTING THE ITEM LEVEL INENTORY DATA, COST AND PERCENTAGE DISTRIBUTION 
drop table pricing_users.blr_tw_item_week_weighted_store_sales purge;
create table pricing_users.blr_tw_item_week_weighted_store_sales as 
select 
  item 
 ,a.dept
 ,eow_date
 ,percentile_approx(unit_cost_amt, 0.5) as unit_cost_amt ---TAKING THE MEDIAN OF THE UNIT COST 
 ,sum(opn_stk_qty) as opn_stk_qty
 ,sum(cls_stk_qty) as cls_stk_qty 
 ,sum(adj_cls_stk_qty) as adj_cls_stk_qty
 ,sum(case when adj_cls_stk_qty > 0 then annual_store_sales else 0 end) / sum(annual_store_sales) as distribution_percentage ---CALCULATE THE DISTRIBUTION PERCENTAGE
from pricing_users.blr_tw_in_scope_store_sales_item_weekly_inventory_cleaned a 
inner join pricing_users.blr_dept_business_type_20190808 b
on cast(a.dept as int) = cast(b.dept as int)
where b.business_type in ("MRD", "CNS", "SRE") ---FILTERING FOR THE BUSINESS TYPES
group by 
  item 
 ,a.dept
 ,eow_date;
-----219749126

---TABLES HAVE BEEN CREATED TILL HERE----
#### Step 5 ####

drop table pricing_users.mck_tw_dept_week_weighted_store_sales;
create table pricing_users.mck_tw_dept_week_weighted_store_sales as
select 
  final_customer_backed_category_mapping
 ,final_model_level
 ,eow_date
 ,sum(opn_stk_qty) as opn_stk_qty
 ,sum(cls_stk_qty) as cls_stk_qty 
 ,sum(adj_cls_stk_qty) as adj_cls_stk_qty
 ,max(distribution_percentage) as max_distribution_percentage
 ,avg(distribution_percentage) as avg_distribution_percentage
from pricing_users.mck_tw_item_week_weighted_store_sales a 
--inner join pricing_users.product_category_mapping_w_brand_group_footwear b
inner join pricing_users.mck_women_category_with_item_brand_agg b
on cast(a.item as int) = cast(b.orin_sku as int)	
where sellable_ind = 'Y'
group by
  final_customer_backed_category_mapping
 ,final_model_level
 ,eow_date
;

#### Step 6 ####

drop table pricing_users.mck_tw_store_dept_week_cnt_item_w_positive_eow_inventory;
create table pricing_users.mck_tw_store_dept_week_cnt_item_w_positive_eow_inventory as
select 
  final_customer_backed_category_mapping
, final_model_level
, division
, store
, eow_date
, coalesce(count(distinct (case when adj_cls_stk_qty > 0 then item end)),0) as cnt_distinct_items
from pricing_users.mck_tw_in_scope_store_sales_item_weekly_inventory_cleaned a
inner join pricing_users.product_category_mapping_w_brand_group_footwear b
on cast(a.item as int) = cast(b.orin_sku as int)	
where sellable_ind = 'Y'
group by
  final_customer_backed_category_mapping
, final_model_level
, division
, store
, eow_date
;


#### Step 7 ####
drop table pricing_users.mck_tw_dept_week_wtd_avg_cnt_item;
create table pricing_users.mck_tw_dept_week_wtd_avg_cnt_item as
select 
  final_customer_backed_category_mapping
, final_model_level
, eow_date
, sum(cnt_distinct_items * total_sales)/sum(total_sales) as sales_weighted_avg_distinct_item_cnt
from pricing_users.mck_tw_store_dept_week_cnt_item_w_positive_eow_inventory a 
inner join pricing_users.mck_tw_store_in_scope_total_sales_qty b
on a.store = b.store
group by
  final_customer_backed_category_mapping
, final_model_level
, eow_date
;


#### Step 8 ####
drop table pricing_users.mck_tw_dept_wk_inv_w_calc_columns;
create table pricing_users.mck_tw_dept_wk_inv_w_calc_columns as
select 
  a.final_customer_backed_category_mapping
 ,a.final_model_level
 ,a.eow_date
 ,a.opn_stk_qty
 ,a.cls_stk_qty
 ,a.adj_cls_stk_qty
 ,round(a.max_distribution_percentage, 4) as max_distribution_percentage
 ,round(a.avg_distribution_percentage, 4) as avg_distribution_percentage
 ,round(b.sales_weighted_avg_distinct_item_cnt) as sales_weighted_avg_distinct_item_cnt
from pricing_users.mck_tw_dept_week_weighted_store_sales a 
inner join pricing_users.mck_tw_dept_week_wtd_avg_cnt_item b
on a.final_model_level = b.final_model_level
and a.eow_date = b.eow_date;


#### Step 9 ####

drop table pricing_users.mck_tw_dept_daily_inv_w_calc_columns;
create table pricing_users.mck_tw_dept_daily_inv_w_calc_columns as 
select 
  a.*
, b.fis_wk_id
, c.string_format
from pricing_users.mck_tw_dept_wk_inv_w_calc_columns a 
inner join jcp.fiscal_calendar b
on a.eow_date = b.string_format -- join on calendar day to bring in fiscal id
inner join jcp.fiscal_calendar c
on b.fis_wk_id = c.fis_wk_id;   -- join on fiscal id to bring in dates within a fiscal week
