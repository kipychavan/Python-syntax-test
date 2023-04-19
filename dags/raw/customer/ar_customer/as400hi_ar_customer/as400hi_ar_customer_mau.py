# Importing required libraries for DAG execution.
from airflow import DAG
from datetime import datetime
from airflow.providers.snowflake.operators.snowflake import SnowflakeOperator
from airflow.providers.amazon.aws.operators.s3 import S3CopyObjectOperator
from airflow.providers.amazon.aws.operators.s3 import S3DeleteObjectsOperator
# Importing parseJsonConfig module, which reads JSON file and returns Dictonary object.
import parseJsonConfig as parseJson
# Variable to store global configurations from globalConfig.json
global_config = parseJson.read_json_config(
    'dags/raw/globalConfig.json')
# Variable to store DAG configurations from <ERP>_<FEED>_config.json
dag_config = parseJson.read_json_config(
    'dags/raw/customer/ar_customer/as400hi_ar_customer/config/as400hi_ar_customer_config.json')
# A dictionary of parameters that will be applied to all tasks in the DAG.
default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': datetime(2023, 1, 1),
}
# Dag Intialization with parameters
# <ERP>_<FEED>_<MARKET> is the DAG name.
# DAG name and current file name should be same.
dag = DAG(
    'as400hi_ar_customer_mau',
    default_args=default_args,
    max_active_runs=1,
    catchup=False,
    template_searchpath=dag_config["sql_template_path"],
)
# Define all tasks in current DAG.
with dag:
    # Task to load data into <ERP>_<FEED>_HIST table.
    # Task uses SnowflakeOperator to execute COPY INTO command stored in sf_sql/<ERP>_<FEED>_hist.sql
    # To establish connecton to Snowflake, 'snowflake_connection' is configured as Airflow Connections.
    # Values are passed to SQL file by using 'params' parameters.
    snowflake_hist_load = SnowflakeOperator(
        task_id='snowflake_hist_load',
        snowflake_conn_id='snowflake_connection',
        dag=dag,
        sql=dag_config["sf_hist_table"] + ".sql",
        params={
            "snowDB": global_config["sf_db_name"],
            "snowSchema": dag_config["sf_schema"],
            "commonSchema": "COMMON",
            "snowTable": dag_config["sf_hist_table"],
            "snowStage": global_config["sf_stage_name"],
            "ff": global_config["sf_file_format_pipe"],
            "base_path": dag_config["src_base_folder"] + '/current/',
            "fileName": dag_config["market_src_files"]["market_file_mau"]
        },
    )
    # Housekeeping Step 1: Task uses S3CopyObjectOperator for file copy.
    # Task to copy source file from <src_base_folder>/current to <src_base_folder>/archive/<CURRENT DATE>/ directory.
    # Archived file is renamed as : <ERP>_<FEED>_<TIMESTAMP>.<MARKET>
    # To establish connecton to AWS, 'aws_connection' is configured as Airflow Connections.
    src_file_archive = S3CopyObjectOperator(
        aws_conn_id="aws_connection",
        task_id="src_file_archive",
        source_bucket_name=global_config["s3_bucket_name"],
        dest_bucket_name=global_config["s3_bucket_name"],
        source_bucket_key=dag_config["src_base_folder"] +
        '/current/' + dag_config["market_src_files"]["market_file_mau"],
                dest_bucket_key=dag_config["src_base_folder"] + '/archive/' + datetime.now().strftime("%Y-%m-%d") + "/" + dag_config["market_src_files"]["market_file_mau"].split(
                    ".", 1)[0] + "_" + datetime.now().strftime("%Y-%m-%d_%H-%M-%S") + "." + dag_config["market_src_files"]["market_file_mau"].split(".", 1)[1]
    )
    # Housekeeping Step 2: Task uses S3DeleteObjectsOperator to delete source file.
    # Task to remove source file from <src_base_folder>/current
    # To establish connecton to AWS, 'aws_connection' is configured as Airflow Connections.
    # Note: This task is only executed post 'src_file_archive' task completion.
    src_file_delete = S3DeleteObjectsOperator(
        aws_conn_id="aws_connection",
        task_id="src_file_delete",
        bucket=global_config["s3_bucket_name"],
        keys=dag_config["src_base_folder"] + '/current/' + dag_config["market_src_files"]["market_file_mau"],
    )
    # Task to load data into <ERP>_<FEED>_SNAP table.
    # Task uses SnowflakeOperator to execute MERGE command stored in sf_sql/<ERP>_<FEED>_snap.sql
    # To establish connecton to Snowflake, 'snowflake_connection' is configured as Airflow Connections.
    # Values are passed to SQL file by using 'params' parameters.
    snowflake_snap_load = SnowflakeOperator(
        task_id='snowflake_snap_load',
        snowflake_conn_id='snowflake_connection',
        dag=dag,
        sql=dag_config["sf_snap_table"] + ".sql",
        params={
            "snowDB": global_config["sf_db_name"],
            "snowSchema": dag_config["sf_schema"],
            "snowTable": dag_config["sf_snap_table"],
            "snowHistTablestream": dag_config["sf_hist_stream"],
        },
    )
    # DATA PIPELINE TASK DEPENDENCIES
    #   Task starts from 'snowflake_hist_load'
    #   On successful execution of 'snowflake_hist_load', 'src_file_archive' and 'snowflake_snap_load'
    #   start execution independent of each other.
    #   On successful execution of 'src_file_archive' , 'src_file_delete' is executed.
    snowflake_hist_load >> [src_file_archive, snowflake_snap_load]
    src_file_archive >> src_file_delete