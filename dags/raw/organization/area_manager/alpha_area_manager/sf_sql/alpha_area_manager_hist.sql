copy into {{ params.snowDB }}.{{ params.snowSchema }}.{{ params.snowTable }} from 
(
select 
$1,
$2,
$3,
$4,
$5,
$6,
$7,
$8,
$9,
current_timestamp(),
current_user(),
NULL,
NULL,
'{{run_id}}',
md5(concat(COALESCE($1,'0'),COALESCE($2,0),COALESCE($3,0),COALESCE($4,'0'),COALESCE($5,0),COALESCE($6,'0'),COALESCE($7,'0'),COALESCE($8,'0'),COALESCE($9,'0'))),
'{{ params.fileName }}' 
from 
@{{ params.snowDB }}.{{ params.commonSchema }}.{{ params.snowStage }}/{{params.base_path}} ) 
FILES=('{{ params.fileName }}') file_format = ( format_name = {{ params.snowDB }}.{{ params.commonSchema }}.{{ params.ff }})