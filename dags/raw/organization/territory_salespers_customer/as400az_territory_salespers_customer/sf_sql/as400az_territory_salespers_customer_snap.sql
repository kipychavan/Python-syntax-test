merge into {{ params.snowDB }}.{{ params.snowSchema }}.{{ params.snowTable }} as TGT
using (select * from (select *,row_number() over(partition by HOUSE_ID, TERRITORY_OVERLAY_ID, CUSTOMER_ID
order by HOUSE_ID, TERRITORY_OVERLAY_ID, CUSTOMER_ID ) as r  from
 {{ params.snowDB }}.{{ params.snowSchema }}.{{ params.snowHistTablestream }})where r=1) as SRC
on SRC.HOUSE_ID = TGT.HOUSE_ID
    and SRC.TERRITORY_OVERLAY_ID = TGT.TERRITORY_OVERLAY_ID
    and SRC.CUSTOMER_ID = TGT.CUSTOMER_ID
when matched and SRC."METADATA$ACTION" = 'INSERT' then update set 
HOUSE_ID = SRC.HOUSE_ID,
TERRITORY_SALESREP_ID = SRC.TERRITORY_SALESREP_ID,
CUSTOMER_ID = SRC.CUSTOMER_ID,
TERRITORY_OVERLAY_ID = SRC.TERRITORY_OVERLAY_ID,
ETL_UPDATE_DATE = current_timestamp(), 
ETL_UPDATE_USER_ID = current_user(), 
ETL_TASK_RUN_ID = SRC.ETL_TASK_RUN_ID, 
ETL_ROW_HASH = SRC.ETL_ROW_HASH, 
RAW_FILE_NAME = SRC.RAW_FILE_NAME
 
WHEN NOT MATCHED AND SRC."METADATA$ACTION" = 'INSERT' THEN INSERT 
(
"HOUSE_ID",
"TERRITORY_SALESREP_ID",
"CUSTOMER_ID",
"TERRITORY_OVERLAY_ID",
"ETL_CREATE_DATE", 
"ETL_CREATE_USER_ID", 
"ETL_UPDATE_DATE", 
"ETL_UPDATE_USER_ID", 
"ETL_TASK_RUN_ID",
"ETL_ROW_HASH", 
"RAW_FILE_NAME"
)
VALUES
(
"HOUSE_ID",
"TERRITORY_SALESREP_ID",
"CUSTOMER_ID",
"TERRITORY_OVERLAY_ID",
current_timestamp(), 
current_user(), 
null, 
null, 
"ETL_TASK_RUN_ID",
"ETL_ROW_HASH", 
"RAW_FILE_NAME"
)