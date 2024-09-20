-- 1 
select case 
		when CUSTOMER_GENDER = 'F' then 'Ms' 
		when CUSTOMER_GENDER = 'M' then 'Mr' 
		end TITLE,
	concat (upper(CUSTOMER_FNAME),' ',upper(CUSTOMER_LNAME)) as CUSTOMER_FULL_NAME,
    CUSTOMER_EMAIL, CUSTOMER_CREATION_DATE, 
    case when CUSTOMER_CREATION_DATE < '2005-01-01' then 'A'
		 when CUSTOMER_CREATION_DATE >= '2005-01-01' and CUSTOMER_CREATION_DATE < '2011-01-01' then 'B'
         when CUSTOMER_CREATION_DATE >= '2011-01-01' then 'C'
         end CUSTOMER_CATEGORY
from online_customer;


-- 2
select 
p.PRODUCT_ID, p.PRODUCT_DESC, p.PRODUCT_QUANTITY_AVAIL, p.PRODUCT_PRICE, 
p.PRODUCT_QUANTITY_AVAIL * p.PRODUCT_PRICE as INVENTORY_VALUE,
case 
when p.PRODUCT_PRICE > '200000' then p.PRODUCT_PRICE*0.80
when p.PRODUCT_PRICE > '100000' and p.PRODUCT_PRICE <= '200000' then p.PRODUCT_PRICE*0.85
when p.PRODUCT_PRICE <= '100000' then p.PRODUCT_PRICE*0.90
end as NEW_PRICE
from product as p
LEFT JOIN order_items as o_i on p.PRODUCT_ID = o_i.PRODUCT_ID
where o_i.PRODUCT_ID is null
ORDER BY INVENTORY_VALUE DESC ;

-- 3
select p.PRODUCT_CLASS_CODE, pc.PRODUCT_CLASS_DESC, count(pc.PRODUCT_CLASS_CODE) as PRODUCT_COUNT,
sum(p.PRODUCT_QUANTITY_AVAIL * p.PRODUCT_PRICE) as INVENTORY_VALUE
from product as p
LEFT JOIN PRODUCT_CLASS as pc ON  p.PRODUCT_CLASS_CODE =  pc.PRODUCT_CLASS_CODE
group by p.PRODUCT_CLASS_CODE having INVENTORY_VALUE > 100000
order by INVENTORY_VALUE DESC;

-- 4
select oh.CUSTOMER_ID, concat(upper(oc.CUSTOMER_FNAME),' ',upper(oc.CUSTOMER_LNAME)) as CUSTOMER_FULL_NAME 
, oc.CUSTOMER_EMAIL, oc.CUSTOMER_PHONE,a.COUNTRY
from order_header as oh
LEFT JOIN online_customer as oc on oh.CUSTOMER_ID = oc.CUSTOMER_ID
LEFT JOIN address as a on oc.ADDRESS_ID = a.ADDRESS_ID
where oh.customer_id in  (select customer_id from order_header where order_status='Cancelled')
group by oh.CUSTOMER_ID having count(distinct oh.ORDER_STATUS) = 1;


-- 5
select S.SHIPPER_NAME,  ad.CITY, count(distinct(oh.CUSTOMER_ID)) as CUSTOMER_CATERED, 
count(ad.CITY) as CONSIGNMENTS_DELIVERED  from  shipper as S
left join order_header as oh on S.SHIPPER_ID = oh.SHIPPER_ID
left join online_customer as oc on oh.CUSTOMER_ID=oc.CUSTOMER_ID
left join address as ad on oc.ADDRESS_ID = ad.ADDRESS_ID
where S.SHIPPER_NAME = 'DHL'
group by ad.CITY;

-- 6
select p.product_id, p.product_desc, p.product_quantity_avail, sum(coalesce(o.product_quantity,0)) as quantity_sold,
case
when coalesce(o.product_quantity,0) = 0 then 'No Sales in past, give discount to reduce inventory'
when pc.product_class_desc in ('Electronics','Computer') then
    case
		when p.product_quantity_avail < (sum(coalesce(o.product_quantity,0))*0.10) then 'Low inventory, need to add inventory'
		when p.product_quantity_avail < (sum(coalesce(o.product_quantity,0))*0.50) then 'Medium inventory, need to add some inventory'
		when p.product_quantity_avail >= (sum(coalesce(o.product_quantity,0))*0.50) then 'Sufficient inventory'
	end
when pc.product_class_desc in ('Mobiles','Watches') then
    case
		when p.product_quantity_avail < (sum(coalesce(o.product_quantity,0))*0.20) then 'Low inventory, need to add inventory'
		when p.product_quantity_avail < (sum(coalesce(o.product_quantity,0))*0.60) then 'Medium inventory, need to add some inventory'
		when p.product_quantity_avail >= (sum(coalesce(o.product_quantity,0))*0.60) then 'Sufficient inventory'
	end
else
	case
		when p.product_quantity_avail < (sum(coalesce(o.product_quantity,0))*0.30) then 'Low inventory, need to add inventory'
		when p.product_quantity_avail < (sum(coalesce(o.product_quantity,0))*0.70) then 'Medium inventory, need to add some inventory'
		when p.product_quantity_avail >= (sum(coalesce(o.product_quantity,0))*0.70) then 'Sufficient inventory'
	end
end as inventory_status
from product p inner join product_class pc using (product_class_code)
left join order_items o using (product_id)
group by p.product_id, p.product_desc, p.product_quantity_avail;


-- 7

select oi.order_id, sum(p.len * p.width * p.height) as PRODUCT_VOLUME
from order_items as oi
left join product as p on oi.product_id = p.product_id
group by  order_id  having PRODUCT_VOLUME < (select len * width * height as CARTON_VOLUME from carton where carton_id = 10) 
order by product_volume desc
limit 1;

-- 8
select oc.customer_id, concat(oc.customer_fname,' ',oc.customer_lname) as CUSTOMER_FULL_NAME, sum(oi.product_quantity) as TOTAL_QUANTITY, sum(oi.product_quantity*p.product_price) as TOTAL_VALUE
from online_customer as oc
left join order_header as oh on oc.customer_id = oh.customer_id
left join order_items as oi on oh.order_id = oi.order_id
left join product as p on oi.product_id = p.product_id
where oh.payment_mode = 'Cash' and oc.customer_lname LIKE 'G%'
group by CUSTOMER_FULL_NAME, oc.customer_id ; 

-- 9 
SELECT P.PRODUCT_ID, P.PRODUCT_DESC, COUNT(OI.PRODUCT_QUANTITY) AS TOTAL_QUANTITY_OF_PRODUCTS
FROM ONLINE_CUSTOMER AS OC
LEFT JOIN ADDRESS AS AD
ON OC.ADDRESS_ID = AD.ADDRESS_ID
LEFT JOIN ORDER_HEADER AS OH
ON OC.CUSTOMER_ID = OH.CUSTOMER_ID
LEFT JOIN ORDER_ITEMS AS OI
ON OI.ORDER_ID = OH.ORDER_ID
RIGHT JOIN PRODUCT AS P
ON P.PRODUCT_ID = OI.PRODUCT_ID
WHERE P.PRODUCT_ID = 201 AND AD.CITY NOT IN ('Bangalore', 'New Delhi')
GROUP BY P.PRODUCT_ID, P.PRODUCT_DESC;




-- 10
select oh.order_id, oc.customer_id, concat(oc.customer_fname,' ',oc.customer_lname) as CUSTOMER_FULL_NAME,
sum(oi.product_quantity) as TOTAL_QUANTITY
from online_customer as oc
left join order_header as oh on oc.customer_id = oh.customer_id
left join order_items as oi on oh.order_id = oi.order_id
left join address as a on oc.address_id = a.address_id
where oh.order_id % 2 = 0 and a.pincode not like '5%' and oi.product_quantity is not null and oh.order_status = 'shipped'
group by oc.customer_id, oh.order_id;


