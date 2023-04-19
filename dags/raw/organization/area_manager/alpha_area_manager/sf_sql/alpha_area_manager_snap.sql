merge into {{ params.snowDB }}.{{ params.snowSchema }}.{{ params.snowTable }} as TGT
using (select * from (select *,row_number() over(partition by AM_ID,HOUSE_ID
order by AM_ID,HOUSE_ID ) as r  from
 {{ params.snowDB }}.{{ params.snowSchema }}.{{ params.snowHistTablestream }})where r=1) as SRC
on SRC.AM_ID = TGT.AM_ID and SRC.HOUSE_ID = TGT.HOUSE_ID 
when matched and SRC."METADATA$ACTION" = 'INSERT' then update set 
CDC_FUNC = SRC.CDC_FUNC,
HOUSE_ID = SRC.HOUSE_ID,
AM_ID = SRC.AM_ID,
AM_DESC = SRC.AM_DESC,
DIVISION_ID = SRC.DIVISION_ID,
AM_EMAIL = SRC.AM_EMAIL,
AM_PHONE = SRC.AM_PHONE,
NON_COMM_SALES_FLAG = SRC.NON_COMM_SALES_FLAG,
EMPLOYEE_ID = SRC.EMPLOYEE_ID,
ETL_UPDATE_DATE = current_timestamp(), 
ETL_UPDATE_USER_ID = current_user(), 
ETL_TASK_RUN_ID = SRC.ETL_TASK_RUN_ID, 
ETL_ROW_HASH = SRC.ETL_ROW_HASH, 
RAW_FILE_NAME = SRC.RAW_FILE_NAME
 
WHEN NOT MATCHED AND SRC."METADATA$ACTION" = 'INSERT' THEN INSERT 
(
"CDC_FUNC",
"HOUSE_ID",
"AM_ID",
"AM_DESC",
"DIVISION_ID",
"AM_EMAIL",
"AM_PHONE",
"NON_COMM_SALES_FLAG",
"EMPLOYEE_ID",
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
"CDC_FUNC",
"HOUSE_ID",
"AM_ID",
"AM_DESC",
"DIVISION_ID",
"AM_EMAIL",
"AM_PHONE",
"NON_COMM_SALES_FLAG",
"EMPLOYEE_ID",
current_timestamp(), 
current_user(), 
null, 
null, 
"ETL_TASK_RUN_ID",
"ETL_ROW_HASH", 
"RAW_FILE_NAME"
)