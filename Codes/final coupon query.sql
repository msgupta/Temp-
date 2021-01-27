---combine the coupon offers data with merch hierarchy---
select * from 
(select distinct barcode_id,offer_num,concat(barcode_id,'-',offer_num)  as barcode_offer,loyalty_flag,coupon_type,
case when trim(coupon_type) in ('Business Specific') then 'Business Specific' else 'Storewide' end as coupon_type_adj,
barcode_desc,start_date,expire_date,min_type,min_value,value_off,type_off,
case when type_off ='$' then concat(min_value,type_off) else '%' end as discount_depth,
CONCAT(value_off,'_',type_off,'_',min_type) as coupon_offer_name,sub,brand,category,lot,item_desc,Merch_Level


 from 
(select a.*,Type,
             Sub,
              Brand,
              Category,
              Lot,
              Item_Desc, 
              Merch_Level from 
			  
			  
			  
(select distinct blr_barcode_offer_coupon.barcode_id
,blr_barcode_offer_coupon.barcode_desc
,blr_barcode_offer_coupon.start_date
,blr_barcode_offer_coupon.expire_date
,blr_barcode_offer_coupon.offer
,blr_barcode_offer_coupon.loyalty_flag
,blr_barcode_offer_coupon.coupon_type_id
,blr_barcode_offer_coupon.coupon_type
,blr_barcode_offer_coupon.offer_num
,blr_barcode_offer_coupon.min_type
,blr_barcode_offer_coupon.min_value
,blr_barcode_offer_coupon.type_off
,blr_barcode_offer_coupon.value_off

from

pricing_users.blr_barcode_offer_coupon blr_barcode_offer_coupon inner join 
	(
		select barcode_id,offer_num, min(min_value) as min_value from pricing_users.blr_barcode_offer_coupon 
		group by barcode_id,offer_num 
	) inner_query 
on blr_barcode_offer_coupon.min_value=inner_query.min_value and 
blr_barcode_offer_coupon.barcode_id=inner_query.barcode_id and blr_barcode_offer_coupon.offer_num=inner_query.offer_num ---get the min offer value for multiple offer values for an offer----
) a
inner join

  
(SELECT    distinct  Barcode_ID,
            Desc, 
             Start_Date,
              Expire_Date, 
              Offer_Num,
             Type,
             Sub,
              Brand,
              Category,
              Lot,
              Item_Desc, 
              Merch_Level
from pricing_users.merchandise
where type='Inclusion') as b ---inlcude the merchandise applicable for coupons---

on concat(cast(a.Barcode_ID as int),cast(a.Offer_Num as int)) = concat(cast(b.Barcode_ID as int),cast(b.Offer_Num as int))) as q
) i

