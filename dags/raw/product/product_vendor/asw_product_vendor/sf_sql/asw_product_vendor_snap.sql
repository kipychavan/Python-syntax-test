merge into {{ params.snowDB }}.{{ params.snowSchema }}.{{ params.snowTable }} as TGT
using (select * from (select *,row_number() over(partition by PRODUCT_ID
order by PRODUCT_ID ) as r  from
 {{ params.snowDB }}.{{ params.snowSchema }}.{{ params.snowHistTablestream }})where r=1) as SRC
on SRC.PRODUCT_ID = TGT.PRODUCT_ID
when matched and SRC."METADATA$ACTION" = 'INSERT' then update set
STATE_ID = SRC.STATE_ID,
PRODUCT_ID = SRC.PRODUCT_ID,
PRODUCT_DESC = SRC.PRODUCT_DESC,
VENDOR_ID = SRC.VENDOR_ID,
SUPPLIER_ID = SRC.SUPPLIER_ID,
ETL_UPDATE_DATE = current_timestamp(),
ETL_UPDATE_USER_ID = current_user(),
ETL_TASK_RUN_ID = SRC.ETL_TASK_RUN_ID,
ETL_ROW_HASH = SRC.ETL_ROW_HASH,
RAW_FILE_NAME = SRC.RAW_FILE_NAME

WHEN NOT MATCHED AND SRC."METADATA$ACTION" = 'INSERT' THEN INSERT
(
"STATE_ID",
"PRODUCT_ID",
"PRODUCT_DESC",
"VENDOR_ID",
"SUPPLIER_ID",
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
"STATE_ID",
"PRODUCT_ID",
"PRODUCT_DESC",
"VENDOR_ID",
"SUPPLIER_ID",
current_timestamp(),
current_user(),
null,
null,
"ETL_TASK_RUN_ID",
"ETL_ROW_HASH",
"RAW_FILE_NAME"
)