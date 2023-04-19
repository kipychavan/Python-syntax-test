merge into {{ params.snowDB }}.{{ params.snowSchema }}.{{ params.snowTable }} as TGT
using (select * from (select *,row_number() over(partition by PREMISE_ID
order by PREMISE_ID ) as r  from
 {{ params.snowDB }}.{{ params.snowSchema }}.{{ params.snowHistTablestream }})where r=1) as SRC
on SRC.PREMISE_ID = TGT.PREMISE_ID
when matched and SRC."METADATA$ACTION" = 'INSERT' then update set 
CDC_FUNC = SRC.CDC_FUNC,
PREMISE_ID = SRC.PREMISE_ID,
PREMISE_DESC = SRC.PREMISE_DESC,
ETL_UPDATE_DATE = current_timestamp(), 
ETL_UPDATE_USER_ID = current_user(), 
ETL_TASK_RUN_ID = SRC.ETL_TASK_RUN_ID, 
ETL_ROW_HASH = SRC.ETL_ROW_HASH, 
RAW_FILE_NAME = SRC.RAW_FILE_NAME
 
WHEN NOT MATCHED AND SRC."METADATA$ACTION" = 'INSERT' THEN INSERT 
(
"CDC_FUNC",
"PREMISE_ID",
"PREMISE_DESC",
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
"PREMISE_ID",
"PREMISE_DESC",
current_timestamp(), 
current_user(), 
null, 
null, 
"ETL_TASK_RUN_ID",
"ETL_ROW_HASH", 
"RAW_FILE_NAME"
)