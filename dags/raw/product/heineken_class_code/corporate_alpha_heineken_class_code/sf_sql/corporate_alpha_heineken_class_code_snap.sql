merge into {{ params.snowDB }}.{{ params.snowSchema }}.{{ params.snowTable }} as TGT
using (select * from (select *,row_number() over(partition by HEINEKEN_CLASS, HEINEKEN_CODE
order by HEINEKEN_CLASS, HEINEKEN_CODE ) as r  from
 {{ params.snowDB }}.{{ params.snowSchema }}.{{ params.snowHistTablestream }})where r=1) as SRC
on (SRC.HEINEKEN_CLASS = TGT.HEINEKEN_CLASS
and SRC.HEINEKEN_CODE = TGT.HEINEKEN_CODE) 
when matched and SRC."METADATA$ACTION" = 'INSERT' then update set 
CDC_FUNC = SRC.CDC_FUNC,
HEINEKEN_CLASS = SRC.HEINEKEN_CLASS,
HEINEKEN_CODE = SRC.HEINEKEN_CODE,
HEINEKEN_CODE_DESC = SRC.HEINEKEN_CODE_DESC,
ETL_UPDATE_DATE = current_timestamp(), 
ETL_UPDATE_USER_ID = current_user(), 
ETL_TASK_RUN_ID = SRC.ETL_TASK_RUN_ID, 
ETL_ROW_HASH = SRC.ETL_ROW_HASH, 
RAW_FILE_NAME = SRC.RAW_FILE_NAME
 
WHEN NOT MATCHED AND SRC."METADATA$ACTION" = 'INSERT' THEN INSERT 
(
"CDC_FUNC",
"HEINEKEN_CLASS",
"HEINEKEN_CODE",
"HEINEKEN_CODE_DESC",
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
"HEINEKEN_CLASS",
"HEINEKEN_CODE",
"HEINEKEN_CODE_DESC",
current_timestamp(), 
current_user(), 
null, 
null, 
"ETL_TASK_RUN_ID",
"ETL_ROW_HASH", 
"RAW_FILE_NAME"
)