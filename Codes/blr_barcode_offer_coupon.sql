--combine the coupon offer related tables---
drop table pricing_users.blr_barcode_offer_coupon purge;
create table pricing_users.blr_barcode_offer_coupon as   select * from 
	(select barcode.*,event_desc, coupontype.coupon_type_id, coupontype.coupon_type,Offer_Num,
				  Detail_Num,
				  Tier_Num,
				  Min_Type,
				  Min_Value,
				  Type_Off,
				  Value_Off
	 from 
	---barcode cleaning----
	(select distinct Barcode_ID, Barcode_Desc,Start_Date, Start_Time,
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
	--change the case and filter out non essential coupons--
	where (upper(Barcode_Desc) not like ('%TEST%') and 
	upper(Barcode_Desc) not like('%REBATE%') 
	and upper(Barcode_Desc) not like('%COMMERCIAL%')
	and upper(Barcode_Desc) not like('%ASSOCIATE%') and 
	upper(Barcode_Desc) not like ('%FREE%') and 
	upper(Barcode_Desc) not like ('%CANCEL%') and 
	upper(Barcode_Desc) not like ('%DO NOT USE%')) and 
	(upper(offer) not like ('%TEST%')  
	and upper(offer) not like ('%CANCEL%') 
	and upper(offer) not like ('%DO NOT USE%'))
	and (to_date(Expire_Date) >='2017-07-01' and to_date(Start_Date)<='2020-03-08')) as barcode ---filter on offer dates----
	--adding coupontype---
	inner join

	(select distinct  Barcode, barcode_desc, event_desc, coupon_type_id, coupon_type
	from pricing_users.coupontype) as coupontype

	on barcode.Barcode_ID=coupontype.Barcode
	--adding offer data---
	inner join
	  
	(select       distinct Barcode,
				  Barcode_Desc,
				  Start_Date,
				  Expire_Date, 
				  Offer_Num,
				  Detail_Num,
				  Tier_Num,
				  Min_Type,
				  Min_Value,
				  Type_Off,
				  Value_Off
	from         pricing_users.offer) as offer

	on barcode.Barcode_ID=offer.Barcode
	) c
