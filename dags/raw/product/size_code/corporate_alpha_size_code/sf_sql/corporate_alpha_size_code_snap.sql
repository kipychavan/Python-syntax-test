merge into corporate_alpha_country_code_snap as TGT
using (select * from (select *,row_number() over(partition by CNTRY_CODE
order by CNTRY_CODE ) as r  from
corporate_alpha_country_code_hist_stream )where r=1) as SRC
on SRC.CNTRY_CODE = TGT.CNTRY_CODE
when matched and SRC."METADATA$ACTION" = 'INSERT' then update set 
CDC_FUNC = SRC.CDC_FUNC,
CNTRY_ID = SRC.CNTRY_ID,
CNTRY_CODE = SRC.CNTRY_CODE,
CNTRY_DESC = SRC.CNTRY_DESC,
ETL_UPDATE_DATE = current_timestamp(), 
ETL_UPDATE_USER_ID = current_user(), 
ETL_TASK_RUN_ID = SRC.ETL_TASK_RUN_ID, 
ETL_ROW_HASH = SRC.ETL_ROW_HASH, 
RAW_FILE_NAME = SRC.RAW_FILE_NAME
 
WHEN NOT MATCHED AND SRC."METADATA$ACTION" = 'INSERT' THEN INSERT 
(
"CDC_FUNC",
"CNTRY_ID",
"CNTRY_CODE",
"CNTRY_DESC",
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
"CNTRY_ID",
"CNTRY_CODE",
"CNTRY_DESC",
current_timestamp(), 
current_user(), 
null, 
null, 
"ETL_TASK_RUN_ID",
"ETL_ROW_HASH", 
"RAW_FILE_NAME"
)