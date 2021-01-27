
--create separate tables for coupon type,barcodes, offer and merchandise using the below tables----
1.	coupondata_event
2.	coupondata_type
3.	coupondata_offer
4.	coupondata_offer_detail
5.	coupondata_offer_std_exc
6.	coupondata_offer_merch_exc
7.	coupondata_offer_merch_inc

8. pricing_users.mstr_barcode
9. pricing_users.shop_spree_ofr_rdm


queries---

1. ~~~~~~~~~~~tab = "coupontype" ~~~~~~~~~~~

select 

barcode_id_num as Barcode,
barcode_id_desc as barcode_desc,
e.desc as event_desc,
e.bc_type_id as coupon_type_id,
t.desc as coupon_type

from pricing_users.coupondata_event as e 
inner join pricing_users.coupondata_type as t
on e.bc_type_id=t.bc_type_id

--table creation---
drop table pricing_users.coupontype purge;
create table pricing_users.coupontype as 
select 
barcode_id_num as Barcode,
barcode_id_desc as barcode_desc,
e.desc as event_desc,
e.bc_type_id as coupon_type_id,
t.desc as coupon_type

from pricing_users.coupondata_event as e 
inner join pricing_users.coupondata_type as t
on e.bc_type_id=t.bc_type_id;

2. ~~~~~~~~~~~~~~~~tab = "offer"~~~~~~~~~~~~

select        e.Barcode_ID_Num as Barcode,
              e.Barcode_ID_Desc as Barcode_Desc,
              E.Start_Date_Time AS Start_Date,
              E.END_Date_Time AS Expire_Date, 
              o.Offer_Num as Offer_Num,
              od.Detail_Num,
              od.Tier_Num,
              od.Min_Type,
              od.Min_Value,
              od.Off_Type as Type_Off,
              od.Off_Value as Value_Off
from         pricing_users.coupondata_event as e 
inner join    pricing_users.coupondata_offer o on e.bc_event_num = o.bc_event_num
inner join    pricing_users.coupondata_offer_detail od on o.Offer_Num = od.Offer_Num
;
--table creation---
drop table pricing_users.offer purge;
create table pricing_users.offer as 
select        e.Barcode_ID_Num as Barcode,
              e.Barcode_ID_Desc as Barcode_Desc,
              E.Start_Date_Time AS Start_Date,
              E.END_Date_Time AS Expire_Date, 
              o.Offer_Num as Offer_Num,
              od.Detail_Num,
              od.Tier_Num,
              od.Min_Type,
              od.Min_Value,
              od.Off_Type as Type_Off,
              od.Off_Value as Value_Off
from         pricing_users.coupondata_event as e 
inner join    pricing_users.coupondata_offer o on e.bc_event_num = o.bc_event_num
inner join    pricing_users.coupondata_offer_detail od on o.Offer_Num = od.Offer_Num

	



3. ~~~~~~~~~~~~~~~~~~~tab = "Barcodes"~~~~~~~~~~~~~~~~~~~~~

select         id_num as Barcode_ID, 
                prog_name as Barcode_Desc, 
                start_date as Start_Date,
                barcode_strt_tm as Start_Time,
                exp_date as Expire_Date,
                barcode_expiry_tm as Expire_Time,
                ofr_nm as Offer,
                rwd_typ_cd as Loyalty,
                shopg_spree_in as Spree,
                chnl_ID as Spree_Chanel,
                cpn_use_qy as Spree_Use_Quantity,
                cpn_hr_durn_qy as Spree_Duration,
                use_and_kill_in as Use_Kill,
                mail_stream_in as Mailstream,
                entrprs_ofr_in as Enterprise,
                barcode_mnemonic_cd as Online_Code
                

from           pricing_users.mstr_barcode bc
left join      pricing_users.shop_spree_ofr_rdm  spree
on             spree.BARCODE_DISC_ID = bc.id_num
order by       start_date
;

--filter on barcodes dates--
--select * from pricing_users.barcodes
--where to_date(Expire_Date) >='2017-07-01' and to_date(Start_Date)<='2019-10-26'

--table creation---
drop table pricing_users.barcodes purge;
create table pricing_users.barcodes as 
select         id_num as Barcode_ID, 
                prog_name as Barcode_Desc, 
                start_date as Start_Date,
                barcode_strt_tm as Start_Time,
                exp_date as Expire_Date,
                barcode_expiry_tm as Expire_Time,
                ofr_nm as Offer,
                rwd_typ_cd as Loyalty,
                shopg_spree_in as Spree,
                chnl_ID as Spree_Chanel,
                cpn_use_qy as Spree_Use_Quantity,
                cpn_hr_durn_qy as Spree_Duration,
                use_and_kill_in as Use_Kill,
                mail_stream_in as Mailstream,
                entrprs_ofr_in as Enterprise,
                barcode_mnemonic_cd as Online_Code
                

from           pricing_users.mstr_barcode bc
left join      pricing_users.shop_spree_ofr_rdm  spree
on             spree.BARCODE_DISC_ID = bc.id_num
order by       start_date;









4. ~~~~~~~~~~~~~~~tab = "Merchandise"~~~~~~~~~~~~~~~~~~~~~~~~~~


SELECT        E.Barcode_ID_Num as Barcode_ID,
              E.Barcode_ID_Desc as Desc, 
              E.Start_Date_Time AS Start_Date,
              E.END_Date_Time AS Expire_Date, 
              I.Offer_Num Offer_Num,
              "Exclusion" as Type,
              I.Sub as Sub,
              I.Brand as Brand,
              I.Category as Category,
              I.Lot as Lot,
              I.Desc AS  Item_Desc, 
              I.Merch_Level_ID as Merch_Level
FROM          pricing_users.coupondata_event E 
INNER JOIN     pricing_users.coupondata_offer_merch_exc I ON E.BC_Event_Num = I.BC_Event_Num

UNION 

SELECT       E.Barcode_ID_Num as Barcode_ID,
              E.Barcode_ID_Desc as Desc, 
              E.Start_Date_Time AS Start_Date,
              E.END_Date_Time AS Expire_Date, 
              I.Offer_Num Offer_Num,
              "Inclusion" as Type,
              I.Sub as Sub,
              I.Brand as Brand,
              I.Category as Category,
              I.Lot as Lot, 
              I.Desc AS  Item_Desc, 
              I.Merch_Level_ID as Merch_Level
FROM           pricing_users.coupondata_event E 
INNER JOIN    pricing_users.coupondata_offer_merch_inc I ON E.BC_Event_Num = I.BC_Event_Num

UNION 
 
SELECT        E.Barcode_ID_Num as Barcode_ID,
              E.Barcode_ID_Desc as Desc, 
              E.Start_Date_Time AS Start_Date,
              E.END_Date_Time AS Expire_Date, 
              I.Offer_Num Offer_Num,
              "Exclusion" as Type,
              I.Sub as Sub,
              I.Brand as Brand,
              I.Category as Category,
              I.Lot as Lot, 
              I.Desc AS  Item_Desc, 
              I.Merch_Level_ID as Merch_Level
              FROM           pricing_users.coupondata_event E 
INNER JOIN    pricing_users.coupondata_offer_std_exc I ON E.BC_Event_Num = I.BC_Event_Num
;



--filter on merchandise---

--select * from pricing_users.merchandise
--where to_date(Expire_Date) >='2017-07-01' and to_date(Start_Date)<='2019-10-26'

--table creation---
drop table pricing_users.merchandise purge;
create table pricing_users.merchandise as 
SELECT        E.Barcode_ID_Num as Barcode_ID,
              E.Barcode_ID_Desc as Desc, 
              E.Start_Date_Time AS Start_Date,
              E.END_Date_Time AS Expire_Date, 
              I.Offer_Num Offer_Num,
              "Exclusion" as Type,
              I.Sub as Sub,
              I.Brand as Brand,
              I.Category as Category,
              I.Lot as Lot,
              I.Desc AS  Item_Desc, 
              I.Merch_Level_ID as Merch_Level
FROM          pricing_users.coupondata_event E 
INNER JOIN     pricing_users.coupondata_offer_merch_exc I ON E.BC_Event_Num = I.BC_Event_Num

UNION 

SELECT       E.Barcode_ID_Num as Barcode_ID,
              E.Barcode_ID_Desc as Desc, 
              E.Start_Date_Time AS Start_Date,
              E.END_Date_Time AS Expire_Date, 
              I.Offer_Num Offer_Num,
              "Inclusion" as Type,
              I.Sub as Sub,
              I.Brand as Brand,
              I.Category as Category,
              I.Lot as Lot, 
              I.Desc AS  Item_Desc, 
              I.Merch_Level_ID as Merch_Level
FROM           pricing_users.coupondata_event E 
INNER JOIN    pricing_users.coupondata_offer_merch_inc I ON E.BC_Event_Num = I.BC_Event_Num

UNION 
 
SELECT        E.Barcode_ID_Num as Barcode_ID,
              E.Barcode_ID_Desc as Desc, 
              E.Start_Date_Time AS Start_Date,
              E.END_Date_Time AS Expire_Date, 
              I.Offer_Num Offer_Num,
              "Exclusion" as Type,
              I.Sub as Sub,
              I.Brand as Brand,
              I.Category as Category,
              I.Lot as Lot, 
              I.Desc AS  Item_Desc, 
              I.Merch_Level_ID as Merch_Level
              FROM           pricing_users.coupondata_event E 
INNER JOIN    pricing_users.coupondata_offer_std_exc I ON E.BC_Event_Num = I.BC_Event_Num
;

---archived-----

select coupontype.* , offer.*,barcodes.*,merchandise.* from pricing_users.coupontype

inner join

pricing_users.offer

on coupontype.Barcode=offer.Barcode

inner join
 pricing_users.barcodes 

on coupontype.Barcode=barcodes.Barcode_ID

inner join
pricing_users.merchandise
on coupontype.Barcode=merchandise.Barcode_ID

where coupontype.Barcode=458194



---barcode cleaning----2508----

select distinct Barcode_ID, Barcode_Desc,Start_Date, Start_Time,
                Expire_Date,
                 Expire_Time,
                Offer,
                 Loyalty,
                Use_Kill,
                Mailstream,
                Enterprise,
                Online_Code,
		case when Loyalty in ('N','') then '0' else '1' end as loyalty_flag

from pricing_users.barcodes

where (Barcode_Desc not like ('%test%') and Barcode_Desc not like ('%Test%') and Barcode_Desc not like ('%TEST%')and 
Barcode_Desc not like('%rebate%') and Barcode_Desc not like('%Rebate%') and Barcode_Desc not like('%REBATE%')
and Barcode_Desc not like('%commercial%') and Barcode_Desc not like('%Commercial%') and Barcode_Desc not like('%COMMERCIAL%')
and Barcode_Desc not like('%associate%') and Barcode_Desc not like('%Associate%') and Barcode_Desc not like('%ASSOCIATE%') and 
Barcode_Desc not like('%free%') and Barcode_Desc not like('%Free%') and Barcode_Desc not like('%FREE%') and 
Barcode_Desc not like ('%cancel%') and Barcode_Desc not like ('%Cancel%') and Barcode_Desc not like ('%CANCEL%') and 
Barcode_Desc not like('%do not use%') and Barcode_Desc not like('%Do Not Use%') and Barcode_Desc not like('%DO NOT USE%'))  
(offer not like ('%test%') and offer not like ('%Test%') and offer not like ('%TEST%') and 
and offer not like ('%cancel%') and offer not like ('%Cancel%') and offer not like ('%CANCEL%') 
and offer not like ('%do not use%') and offer not like ('%Do Not Use%') and offer not like ('%DO NOT USE%'))
and (to_date(Expire_Date) >='2017-07-01' and to_date(Start_Date)<='2019-10-26')




