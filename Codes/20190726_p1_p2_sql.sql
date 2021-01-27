
---calculate the Primary and Secondary Discounts at transaction level----
drop table pricing_users.blr_price_p1_p2_price_from_resa_a_discount_info_jx purge;
create table pricing_users.blr_price_p1_p2_price_from_resa_a_discount_info_jx
as select * from (
select tran_datetime,item_seq_no, tran_seq_no,store_num,
sum (case when adj_type_code in (1 ,2,3,5,7,9,10,13,15,16,17,18,27,50,51,52,53,54) then unit_discount_amt else 0 end) as primary_discount,
sum (case when adj_type_code in (1 ,2,3,5,7,9,10,13,15,16,17,18,27,50,51,52,53,54) then 0 else unit_discount_amt end) as secondary_discount
from insiderdata.resa_discount
where tran_datetime between '2017-07-01' and '2020-03-08' --filter on transaction date
and tran_type_code not in ("VOID")     --exlcude void transactions
and store_num not like '74%' ----exclude dotcom and virtual stores----
and channel_cd = "R" ----filter for store channel----
group by tran_datetime,item_seq_no, tran_seq_no,store_num) as a 

----calculate the P1 and net price at transaction level-----
drop table pricing_users.blr_price_p1_p2_price_from_resa_b_p1_netprice_jx purge;
create table pricing_users.blr_price_p1_p2_price_from_resa_b_p1_netprice_jx
as select * from (
select tran_datetime,item_seq_no, tran_seq_no,store_num,
max(calc_start_rtl) as p1, min(calc_end_rtl) as net_price
from insiderdata.resa_discount 
where tran_datetime between '2017-07-01' and '2020-03-08' -----filter on transaction date
and tran_type_code not in ("VOID")      --exlcude void transactions
and store_num not like '74%'  ----exclude dotcom and virtual stores----
and channel_cd = "R" ----filter for store channel----
group by tran_datetime,item_seq_no, tran_seq_no,store_num
) as a 


-----combining the above two tables to bring price and discount metrics in one table at transaction level---
drop table pricing_users.blr_price_p1_p2_price_from_resa_discount_jx purge;
create table pricing_users.blr_price_p1_p2_price_from_resa_discount_jx
as select * from (
select a.*, b.p1, b.net_price, b.p1 - a.primary_discount as p2, b.p1-a.primary_discount - a.secondary_discount as calc_net_price  
from pricing_users.blr_price_p1_p2_price_from_resa_a_discount_info_jx a
inner join pricing_users.blr_price_p1_p2_price_from_resa_b_p1_netprice_jx b
on a.tran_datetime = b.tran_datetime
and a.item_seq_no = b.item_seq_no
and a.tran_seq_no = b.tran_seq_no
and a.store_num = b.store_num) as c


---replacing the price and discount metrics with AUR and 0 for null values resp at transaction level----
drop table pricing_users.blr_resa_combined_filtered_wor_v2_after_store_filter_w_p1_p2_from_resa_no_gaps_jx purge;
create table pricing_users.blr_resa_combined_filtered_wor_v2_after_store_filter_w_p1_p2_from_resa_no_gaps_jx 
as select * from (select a.*, b.primary_discount,b.secondary_discount,b.p1,b.net_price,b.p2,b.calc_net_price, 
case when b.p1 is null then actual_rtl_amt/item_ord_qty else b.p1 end as final_p1,
case when b.p2 is null then actual_rtl_amt/item_ord_qty else b.p2 end as final_p2,
case when b.primary_discount is null then 0 else b.primary_discount end as final_primary_discount,
case when b.secondary_discount is null then 0 else b.secondary_discount end as final_secondary_discount
from  pricing_users.blr_resa_combined_filtered_woR_filtered_store   a
left join pricing_users.blr_price_p1_p2_price_from_resa_discount_jx b
on a.tran_seq_no = b.tran_seq_no
and a.item_seq_no = b.item_seq_no
and a.tran_datetime = b.tran_datetime) as c;
