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
$10,
$11,
$12,
$13,
$14,
$15,
$16,
$17,
$18,
$19,
$20,
$21,
$22,
$23,
$24,
$25,
$26,
$27,
$28,
$29,
$30,
$31,
$32,
$33,
$34,
$35,
$36,
$37,
$38,
$39,
$40,
$41,
$42,
$43,
$44,
$45,
$46,
$47,
$48,
$49,
$50,
$51,
$52,
$53,
$54,
$55,
$56,
$57,
$58,
$59,
$60,
$61,
$62,
$63,
$64,
current_timestamp(),
current_user(),
NULL,
NULL,
'{{run_id}}',
md5(concat(COALESCE($1,'0'),COALESCE($2,0),COALESCE($3,0),COALESCE($4,'0'),COALESCE($5,'0'),COALESCE($6,'0'),COALESCE($7,'0'),COALESCE($8,'0'),COALESCE($9,'0'),COALESCE($10,'0'),COALESCE($11,'0'),COALESCE($12,'0'),COALESCE($13,'0'),COALESCE($14,'0'),COALESCE($15,'0'),COALESCE($16,'0'),COALESCE($17,0),COALESCE($18,'0'),COALESCE($19,'0'),COALESCE($20,'0'),COALESCE($21,'0'),COALESCE($22,'0'),COALESCE($23,'0'),COALESCE($24,0),COALESCE($25,'0'),COALESCE($26,'0'),COALESCE($27,'0'),COALESCE($28,'0'),COALESCE($29,'0'),COALESCE($30,'0'),COALESCE($31,'0'),COALESCE($32,'0'),COALESCE($33,'0'),COALESCE($34,'0'),COALESCE($35,0),COALESCE($36,0),COALESCE($37,0),COALESCE($38,'0'),COALESCE($39,0),COALESCE($40,0),COALESCE($41,0),COALESCE($42,0),COALESCE($43,0),COALESCE($44,0),COALESCE($45,0),COALESCE($46,0),COALESCE($47,0),COALESCE($48,0),COALESCE($49,'0'),COALESCE($50,0),COALESCE($51,0),COALESCE($52,'0'),COALESCE($53,0),COALESCE($54,'0'),COALESCE($55,'0'),COALESCE($56,'0'),COALESCE($57,0),COALESCE($58,0),COALESCE($59,'0'),COALESCE($60,0),COALESCE($61,0),COALESCE($62,'0'),COALESCE($63,'0'),COALESCE($64,'0'))),
'{{ params.fileName }}' 
from 
@{{ params.snowDB }}.{{ params.commonSchema }}.{{ params.snowStage }}/{{params.base_path}} ) 
FILES=('{{ params.fileName }}') file_format = ( format_name = {{ params.snowDB }}.{{ params.commonSchema }}.{{ params.ff }})