#### Step 1 ####
----pricing_users.mck_item_daily_cost
---1538243882
----EXPAND COST AT DAILY LEVEL FROM THE TABLE CREATED IN THE INVENTORY CODES---
drop table pricing_users.BLR_item_daily_cost purge;
create table pricing_users.BLR_item_daily_cost as 
select 
  a.item
, a.eow_date
, a.unit_cost_amt
, b.fis_wk_id
, c.string_format
from pricing_users.BLR_tw_item_week_weighted_store_sales a
inner join jcp.fiscal_calendar b
on a.eow_date = b.string_format 
inner join jcp.fiscal_calendar c
on b.fis_wk_id = c.fis_wk_id
;   
----1538243882

--2017-07-01	2019-10-19
#### Step 2 ####
--- pricing_users.mck_item_daily_total_cost
---169509191
--GETTING THE TOTAL COST AT ITEM DATE LEVEL--
drop table pricing_users.BLR_item_daily_total_cost purge;
create table pricing_users.BLR_item_daily_total_cost as 
select 
  a.item
, b.tran_datetime
, sum(a.unit_cost_amt * total_qty) as daily_cost
from pricing_users.BLR_item_daily_cost a
inner join 
pricing_users.BLR_resa_consolidated b 
on cast(a.item as int) = cast(b.item as int) 
and a.string_format = b.tran_datetime
group by 
  a.item
, b.tran_datetime
;
------169509238
---TABLES ARE CREATED TILL HERE----
#### Step 3 ####
drop table pricing_users.mck_cat_daily_total_cost;
create table pricing_users.mck_cat_daily_total_cost as 
select 
  final_customer_backed_category_mapping
 ,final_model_level
 ,tran_datetime
 ,sum(daily_cost) as cost 
from pricing_users.mck_item_daily_total_cost a 
inner join 
pricing_users.product_category_mapping_w_brand_group_footwear b
on cast(a.item as int) = cast(b.orin_sku as int)	
where sellable_ind = 'Y'
group by
  final_customer_backed_category_mapping
 ,final_model_level
 ,tran_datetime
;




