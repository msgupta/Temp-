#### Step 1 - From Resa_Item, filter out eCOMM and Void transactions ####
pricing_users.mck_resa_item_instore_valid_trans 
###1443372141
---GETTING ALL THE TRANSACTION FOR STORES----
drop view pricing_users.blr_resa_item_instore_valid_trans;
create view pricing_users.blr_resa_item_instore_valid_trans as 
select 
*
from insiderdata.resa_item
where tran_datetime >= '2017-07-01' and tran_datetime <='2020-03-08'
and tran_type_code not in ("VOID")     -- exclude void transactions 
and ln_voided_ind = "N"                -- exclude void line items
and channel_cd = "R"                   -- only stores 
;
###1443372141

#### Step 2 - From Resa_Discount, filter out pricing_users.blr_resa_discount_instore_valid_trans ####

pricing_users.mck_resa_discount_instore_valid_trans
###2153493171
-----GETTING ALL THE DISCOUNTED TRANSACTIONS FOR STORES----
drop view pricing_users.blr_resa_discount_instore_valid_trans;
create view pricing_users.blr_resa_discount_instore_valid_trans as 

select 
*
from insiderdata.resa_discount
where tran_datetime >= '2017-07-01' and tran_datetime <='2020-03-08'
and tran_type_code not in ("VOID")       -- exclude void transactions 
--and ln_voided_ind = "N"                -- exclude void line items, no line item void indicator in discount table
and channel_cd = "R"                     -- only stores 
;
###2153493171

#### Step 3. From step 2, pricing_users.blr_resa_discount_instore_valid_trans #### 
#### create discount aggregation by adjustment type by the following columns tran_datetime, store_num, terminal_num, tran_seq_no, item_seq_no ####

pricing_users.mck_resa_discount_by_adjustment_type
####1251568892
-----BRING THE DISCOUNTED TRANSACTIONS TO THE SAME LEVEL AS THE TOTAL TRANSACTIONS BY PIVOTING THE adj_type_code COLUMN------
drop view pricing_users.blr_resa_discount_by_adjustment_type;
create view pricing_users.blr_resa_discount_by_adjustment_type as
select 
 tran_datetime 
,store_num
,terminal_num
,tran_seq_no
,item_seq_no
,sum(case when adj_type_code=1 then unit_discount_amt else 0 end ) as unit_discount_amt_by_pri_adj_type_code1
,sum(case when adj_type_code=2 then unit_discount_amt else 0 end ) as unit_discount_amt_by_pri_adj_type_code2
,sum(case when adj_type_code=3 then unit_discount_amt else 0 end ) as unit_discount_amt_by_pri_adj_type_code3
,sum(case when adj_type_code=5 then unit_discount_amt else 0 end ) as unit_discount_amt_by_pri_adj_type_code5
,sum(case when adj_type_code=7 then unit_discount_amt else 0 end ) as unit_discount_amt_by_pri_adj_type_code7
,sum(case when adj_type_code=9 then unit_discount_amt else 0 end ) as unit_discount_amt_by_pri_adj_type_code9
,sum(case when adj_type_code=10 then unit_discount_amt else 0 end ) as unit_discount_amt_by_pri_adj_type_code10
,sum(case when adj_type_code=13 then unit_discount_amt else 0 end ) as unit_discount_amt_by_pri_adj_type_code13
,sum(case when adj_type_code=15 then unit_discount_amt else 0 end ) as unit_discount_amt_by_pri_adj_type_code15
,sum(case when adj_type_code=16 then unit_discount_amt else 0 end ) as unit_discount_amt_by_pri_adj_type_code16
,sum(case when adj_type_code=17 then unit_discount_amt else 0 end ) as unit_discount_amt_by_pri_adj_type_code17
,sum(case when adj_type_code=18 then unit_discount_amt else 0 end ) as unit_discount_amt_by_pri_adj_type_code18
,sum(case when adj_type_code=27 then unit_discount_amt else 0 end ) as unit_discount_amt_by_pri_adj_type_code27
,sum(case when adj_type_code=12 then unit_discount_amt else 0 end ) as unit_discount_amt_by_clr_adj_type_code12
,sum(case when adj_type_code=14 and tran_datetime >= '2018-10-01' then unit_discount_amt else 0 end ) as unit_discount_amt_by_clr_adj_type_code14 -----THE  adj_type_code=14 USED TO BE CONSIDERED A PROMOTIONAL DISC BEFORE 1ST OCT 2018 BUT AFTER THAT IT IS A PART OF CLEARANCE DISCOUNTS----
,sum(case when adj_type_code=14 and tran_datetime < '2018-10-01' then unit_discount_amt else 0 end ) as unit_discount_amt_by_sec_adj_type_code14
,sum(case when adj_type_code in (19,20,21,8,22,23,28,28,25,26,4,6,11,24) then unit_discount_amt else 0 end ) as unit_discount_amt_by_sec_adj_type_code
,sum(case when adj_type_code not in (1,2,3,5,7,9,10,13,14,15,16,17,18,27,12,19,20,21,8,22,23,28,28,25,26,4,6,11,24) then unit_discount_amt else 0 end) unit_discount_amt_by_Other
from pricing_users.blr_resa_discount_instore_valid_trans            
group by
 tran_datetime 
,store_num
,terminal_num
,tran_seq_no
,item_seq_no;
####1251568892


#### Step 4. Join ITEM with Discount #### 
#### Left join pricing_users.blr_resa_item_instore_valid_trans a 
#### WITH pricing_users.blr_resa_discount_by_adjustment_type b 
#### on tran_datetime, store_num_terminal_num, tran_seq_no, item_seq_no

---2017-07-01	2019-10-29---
pricing_users.mck_resa_combined
###1443372141
----JOIN THE TOTAL TRANSACTIONS WITH THE DISCOUNTED TRANSACTIONS AT THE SAME LEVEL LEFT JOIN IS USED SO THAT WE DO NOT MISS ANY TRANSACTION AFTER THE JOIN----
drop view pricing_users.blr_resa_combined;
create view pricing_users.blr_resa_combined as 
select 
 a.*
,b.tran_seq_no as resa_discount_tran_seq_no
,unit_discount_amt_by_pri_adj_type_code1
,unit_discount_amt_by_pri_adj_type_code2
,unit_discount_amt_by_pri_adj_type_code3
,unit_discount_amt_by_pri_adj_type_code5
,unit_discount_amt_by_pri_adj_type_code7
,unit_discount_amt_by_pri_adj_type_code9
,unit_discount_amt_by_pri_adj_type_code10
,unit_discount_amt_by_pri_adj_type_code13
,unit_discount_amt_by_pri_adj_type_code15
,unit_discount_amt_by_pri_adj_type_code16
,unit_discount_amt_by_pri_adj_type_code17
,unit_discount_amt_by_pri_adj_type_code18
,unit_discount_amt_by_pri_adj_type_code27
,unit_discount_amt_by_clr_adj_type_code12
,unit_discount_amt_by_clr_adj_type_code14
,unit_discount_amt_by_sec_adj_type_code14
,unit_discount_amt_by_sec_adj_type_code
,unit_discount_amt_by_Other
from pricing_users.blr_resa_item_instore_valid_trans a 
left join pricing_users.blr_resa_discount_by_adjustment_type b
on  a.store_num = b.store_num
and a.tran_seq_no = b.tran_seq_no
and a.item_seq_no = b.item_seq_no
and a.tran_datetime = b.tran_datetime
and a.terminal_num = b.terminal_num
;
###1443372141



--Step 5. Apply Additional Filters ####
-- Apply filters transaction type + transaction subtype.
-- Entity_code not in 55 (jewelry services)
-- item_status_code in ("S", "R", "ORD)

pricing_users.mck_resa_combined_filtered_wR
####1395782991
---not creating this----
-----FILTER THE TABLE TO CONSIDER ONLY THE SALE, RETURN,SPECIAL ORDER AND EXCHANGED TRANSACTIONS----- 
drop table pricing_users.blr_resa_combined_filtered_wR purge;
create table pricing_users.blr_resa_combined_filtered_wR as 
select * from pricing_users.blr_resa_combined 
where ((xntf_tran_type_code in (1,2,3) and xntf_tran_subtype_code in (1)) or (xntf_tran_type_code in (4) and xntf_tran_subtype_code in (5,13)) )---FILTER SALE, RETURN,SPECIAL ORDER AND EXCHANGED TRANSACTIONS
and entity_code not in (55)               -- for fine jewelry promotional (trade in, services)
and item_status_code in ("S","R","ORD") ----ITEM CONSIDERED WHICH WERE PART OF TRANSACTION TYPES ABOVE---TO MATCH THE SALES, QTY WITH THE FINANCE TEAM REPORTING----
;
###1395783709


---2017-07-01	2019-10-29---
pricing_users.mck_resa_combined_filtered_woR_v4
####1268880859
------FILTER OUT THE BUSINESS TYPE AND EXCLUDE THE RETURN TRANSACTION TYPES------
drop table pricing_users.blr_resa_combined_filtered_woR_v4 purge;
create table pricing_users.blr_resa_combined_filtered_woR_v4 as 
select a.*, b.business_type from pricing_users.blr_resa_combined a
inner join pricing_users.blr_dept_business_type_20190808 b  ----one time mapping table created using the 20190918_rms_department_attributes file---
on cast(a.dept as int) = cast(b.dept as int)
where ((xntf_tran_type_code in (1,2,3) and xntf_tran_subtype_code in (1)) or (xntf_tran_type_code in (4) and xntf_tran_subtype_code in (5,13)) )
and entity_code not in ( 55)  -- for fine jewelry promotional (trade in, services)
and item_status_code in ("S","ORD")--EXCLUDE THE RETURNED ITEMS---THE MODELING IS DONE FOR THIS TYPE OF TRANSACTIONS----
and b.business_type in ("MRD", "CNS", "SRE")---FILTER OUT THE MERCHANDISE, CONSIGNMENT AND SALON AND RETAIL BUSINESS TYPES-----
;
#####1268881160



pricing_users.mck_modeling_store_list_tw
####857
------GET THE LIST OF ACTIVE STORES----
--done 20191125---
#### Step 7. Obtain a list of open stores ####
drop table pricing_users.blr_modeling_store_list_tw purge;
create table pricing_users.blr_modeling_store_list_tw as 
select store from jcp.rms_store 
where channel_id = 1 -----FILTER FOR STORE CHANNEL
and store_name3 != 'TES'----FILTER TO EXCLUDE THE VIRTUAL STORES(WAREHOUSE,DISTRIBUTION CENTERS ETC.)
and store_open_date <= '2017-01-01' ---FILTER THE STORES OPENED BEFORE THE DATE OF ANALYSIS-- 
and (store_close_date is null or store_close_date = "");--FILTER ALL THE OPEN/ACTIVE STORES---
###857



#### Step 5c ####

pricing_users.mck_resa_combined_filtered_woR_filtered_store
####1238297251
----GETTING THE TRANSACTION DATA FOR ALL THE ACTIVE STORES----
drop table pricing_users.blr_resa_combined_filtered_woR_filtered_store purge;
create table pricing_users.blr_resa_combined_filtered_woR_filtered_store as
select 
a.*
from pricing_users.blr_resa_combined_filtered_woR_v4 a
inner join pricing_users.blr_modeling_store_list_tw b
on cast(a.store_num as int) = cast(b.store as int) 
;
####1238297518

---2017-07-01	2019-10-29---

#### Step 6. Agg woR from 5 to get total sales, total qty, clr sales, clr quantity at item + date + store + all other hierarchy level ####

pricing_users.mck_resa_consolidated
####1072344912

drop table pricing_users.blr_resa_consolidated purge;      
create table pricing_users.blr_resa_consolidated as
select 
 store_num
,tran_datetime
,entity_code
,dept
,class
,brand_code
,lot_num
,item
,sum(actual_rtl_amt) as total_sales
,sum(item_ord_qty) as total_qty
,sum(case when unit_discount_amt_by_clr_adj_type_code14 > 0 then actual_rtl_amt else 0 end) as clr_sales_p4
,sum(case when unit_discount_amt_by_clr_adj_type_code14 > 0 then item_ord_qty else 0 end) as clr_qty_p4
,sum(case when unit_discount_amt_by_clr_adj_type_code12 > 0 then actual_rtl_amt else 0 end) as clr_sales -- p5
,sum(case when unit_discount_amt_by_clr_adj_type_code12 > 0 then item_ord_qty else 0 end) as clr_qty     -- p5
from pricing_users.blr_resa_combined_filtered_woR_filtered_store 
group by 
 store_num
,tran_datetime
,entity_code
,dept
,class
,brand_code
,lot_num
,item
;
####1072345100
-----The tables have been created till here --------
#### Step 8 Agg to New Category ####
drop table pricing_users.mck_new_cat_daily_sales_qty ;
create table pricing_users.mck_new_cat_daily_sales_qty_home as 
select 
 final_customer_backed_category_mapping -- this is category
,final_model_level -- this is model level
,tran_datetime
,sum(total_sales) as total_sales
,sum(total_qty) as total_qty
,sum(clr_sales_p4) as clr_sales_p4
,sum(clr_qty_p4) as clr_qty_p4
,sum(clr_sales) as clr_sales_p5
,sum(clr_qty) as clr_qty_p5
from pricing_users.mck_resa_consolidated a 
--inner join  pricing_users.mck_women_category_with_item_brand_agg b
inner join pricing_users.mck_div_home_category_with_item_brand_agg b
on cast(a.item as int) = cast(b.orin_sku as int)	
--where sellable_ind = 'Y'
group by 
 final_customer_backed_category_mapping
,final_model_level
,tran_datetime;