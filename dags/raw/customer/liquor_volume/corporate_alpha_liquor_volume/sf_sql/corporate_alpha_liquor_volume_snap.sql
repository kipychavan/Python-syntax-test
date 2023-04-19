merge into {{ params.snowDB }}.{{ params.snowSchema }}.{{ params.snowTable }} as TGT
using (select * from (select *,row_number() over(partition by LIQUOR_VOLUME_ID
order by LIQUOR_VOLUME_ID ) as r  from
 {{ params.snowDB }}.{{ params.snowSchema }}.{{ params.snowHistTablestream }})where r=1) as SRC
on SRC.LIQUOR_VOLUME_ID = TGT.LIQUOR_VOLUME_ID 
when matched and SRC."METADATA$ACTION" = 'INSERT' then update set 
CDC_FUNC = SRC.CDC_FUNC,
LIQUOR_VOLUME_ID = SRC.LIQUOR_VOLUME_ID,
LIQUOR_VOLUME_DESC = SRC.LIQUOR_VOLUME_DESC,
LIQUOR_VOLUME_SEQ = SRC.LIQUOR_VOLUME_SEQ,
ETL_UPDATE_DATE = current_timestamp(), 
ETL_UPDATE_USER_ID = current_user(), 
ETL_TASK_RUN_ID = SRC.ETL_TASK_RUN_ID, 
ETL_ROW_HASH = SRC.ETL_ROW_HASH, 
RAW_FILE_NAME = SRC.RAW_FILE_NAME
 
WHEN NOT MATCHED AND SRC."METADATA$ACTION" = 'INSERT' THEN INSERT 
(
"CDC_FUNC",
"LIQUOR_VOLUME_ID",
"LIQUOR_VOLUME_DESC",
"LIQUOR_VOLUME_SEQ",
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
"LIQUOR_VOLUME_ID",
"LIQUOR_VOLUME_DESC",
"LIQUOR_VOLUME_SEQ",
current_timestamp(), 
current_user(), 
null, 
null, 
"ETL_TASK_RUN_ID",
"ETL_ROW_HASH", 
"RAW_FILE_NAME"
)