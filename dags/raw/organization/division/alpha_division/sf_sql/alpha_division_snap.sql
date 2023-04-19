merge into {{ params.snowDB }}.{{ params.snowSchema }}.{{ params.snowTable }} as TGT
using (select * from (select *,row_number() over(partition by HOUSE_ID, DIVISION_ID
order by HOUSE_ID, DIVISION_ID ) as r  from
 {{ params.snowDB }}.{{ params.snowSchema }}.{{ params.snowHistTablestream }})where r=1) as SRC
On  SRC. HOUSE_ID= TGT. HOUSE_ID
AND SRC. DIVISION_ID = TGT. DIVISION_ID
when matched and SRC."METADATA$ACTION" = 'INSERT' then update set 
CDC_FUNC = SRC.CDC_FUNC,
DIVISION_ID = SRC.DIVISION_ID,
HOUSE_ID = SRC.HOUSE_ID,
DIVISION_DESC = SRC.DIVISION_DESC,
DIVISION_EMAIL = SRC.DIVISION_EMAIL,
DIVISION_PHONE = SRC.DIVISION_PHONE,
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
"DIVISION_ID",
"HOUSE_ID",
"DIVISION_DESC",
"DIVISION_EMAIL",
"DIVISION_PHONE",
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
"DIVISION_ID",
"HOUSE_ID",
"DIVISION_DESC",
"DIVISION_EMAIL",
"DIVISION_PHONE",
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