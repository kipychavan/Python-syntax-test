from jinja2 import Environment, FileSystemLoader
import yaml
import os
import json
import sys
import openpyxl 

current_dir = os.path.dirname(os.path.abspath(__file__))
yml_dir = "yml_files"
jinja_template_filename = "dag_template.jinja2"

sf_sql_dir = 'sf_sql'
sql_source_dir = 'sql_query_source'
copy_workbook = 'Airflow Copy Queries.xlsx'
merge_workbook = 'Airflow Merge Queries.xlsx'

def fetch_sql_queries(workbook_filename, yml_config):
    try:
        sql_wb = openpyxl.load_workbook(current_dir + '/' + str(sql_source_dir) + '/' + str(workbook_filename))
        sql_sheet = sql_wb[yml_config['config_values']['sf_schema'].upper()]
        sql_command_fetched = ''

        file_suffix = ''
        if 'copy' in workbook_filename.lower():
            file_suffix = 'hist'
        elif 'merge' in workbook_filename.lower():
            file_suffix = 'snap'

        for cell in sql_sheet['A']:
            if cell.value is not None:
                if (cell.value).rsplit("_" + file_suffix.upper(),1)[0] == yml_config['common_values']['base_table_name'].upper():
                        print("SQL Command Found for: %s in %s" % (yml_config['common_values']['base_table_name'],workbook_filename))
                        sql_command_fetched = sql_sheet[f"B{cell.row}"].value
                        break
        
        if sql_command_fetched != '':
            if file_suffix != '':
                with open(f"{yml_config['dags_dir_path']}/{sf_sql_dir}/{yml_config['common_values']['base_table_name']}_{file_suffix}.sql", "w") as f:
                    f.write(sql_command_fetched)
                print(f"{yml_config['dags_dir_path']}/{sf_sql_dir}/{yml_config['common_values']['base_table_name']}_{file_suffix}.sql")
            else:
                print('Incorrect file name. Create SQL file manually for :' + workbook_filename)
        else:
            print("NO SQL COMMAND NOT FOUND FOR: %s in %s " % (yml_config['common_values']['base_table_name'],workbook_filename))
    except Exception as e:
        print('Exception during SQL file creation: ' + str(e))

def generateDag(yml_file):
    """
        Generate DAG files.
    """
    try:
        print('Starting DAGs creation')
        global current_dir
        env = Environment(loader=FileSystemLoader(current_dir))
        dag_template = env.get_template(jinja_template_filename)

        f = open(current_dir + "/" + yml_dir + "/" + yml_file)
        yml_config = yaml.safe_load(f)

        # Generating DAGs for different markets configured in yml file
        for current_market in yml_config['market_dag_list']:
            print('Creating DAG: ' + yml_config['common_values']
                  ['base_table_name'] + '_' + current_market['market_ext'])

            with open(f"{yml_config['dags_dir_path']}/{yml_config['common_values']['base_table_name']}_{current_market['market_ext']}.py", "w") as f:
                f.write(
                    dag_template.render(
                        yml_config,
                        global_config_path=yml_config['common_values']['global_config_path'],
                        base_table=yml_config['common_values']['base_table_name'],
                        dag_config_path=yml_config['common_values']['dag_config_path'],
                        market_ext=current_market['market_ext']
                    )
                )

            print("DAG successfully create: " +
                  f"{yml_config['dags_dir_path']}/{yml_config['common_values']['base_table_name']}_{current_market['market_ext']}.py")
        print('DAGs creation completed.')
    except Exception as e:
        print('Exception during DAG creation: ' + str(e))
        return False

    """
        Generate JSON configuration file.
    """
    try:
        # Create config directory if not exists
        config_dir = "config"
        configExists = os.path.exists(
            yml_config['dags_dir_path'] + "/" + config_dir)
        if configExists == False:
            print("Creating 'config' directory: " +
                  yml_config['dags_dir_path'] + "/" + config_dir)
            os.makedirs(yml_config['dags_dir_path'] + "/" + config_dir)
            print("Directory created: " +
                  yml_config['dags_dir_path'] + "/" + config_dir)

        # Generating table level config file
        print('Starting JSON configuration file creation.')
        config_params = yml_config['config_values']

        with open(f"{yml_config['dags_dir_path']}/{config_dir}/{yml_config['common_values']['base_table_name']}_config.json", 'w') as json_file:
            json.dump(config_params, json_file)
        print('Completed JSON configuration file creation.')
    except Exception as e:
        print('Exception during JSON config creation: ' + str(e))
        return False

    """
        Create if sf_sql directory and files doesn't exist.
    """
    try:
        # Create config directory if not exists
        sqlDirExists = os.path.exists(
            yml_config['dags_dir_path'] + "/" + sf_sql_dir)
        if sqlDirExists == False:
            print("Creating 'sf_sql' directory: " +
                  yml_config['dags_dir_path'] + "/" + sf_sql_dir)
            os.makedirs(yml_config['dags_dir_path'] + '/sf_sql')
            print("Directory created: " +
                  yml_config['dags_dir_path'] + "/" + sf_sql_dir)
            
        # Reading workbook and sheet to fetch copy into command
        fetch_sql_queries(copy_workbook, yml_config)

        # Reading workbook and sheet to fetch copy into command
        fetch_sql_queries(merge_workbook, yml_config)

    except Exception as e:
        print('Exception during sf_sql directory / file creation: ' + str(e))
        return False

    return True


def validations(yml_file):
    try:
        print('Starting validations')
        global current_dir

        # Validate if JINJA template exists
        print(f"JINJA Template File: {jinja_template_filename}")
        isTemplateExist = os.path.isfile(
            current_dir + "/" + jinja_template_filename)
        if isTemplateExist == False:
            print("JINJA Template for DAG creation does not exists:" +
                  current_dir + "/" + jinja_template_filename)
            return False

        # Validate if yml directory and file in directory exists
        isymlDirExist = os.path.exists(current_dir + '/' + yml_dir)
        if isymlDirExist == True:
            isymlExist = os.path.isfile(
                current_dir + "/" + yml_dir + "/" + yml_file)
            if isymlExist == False:
                print("yml for DAG creation don't exists: " +
                      current_dir + "/" + yml_dir + "/" + yml_file)
                return False
            print(current_dir + "/" + yml_dir +
                  "/" + yml_file + " file exists")
        else:
            print(current_dir + "/" + yml_dir + " does not exists!")
            return False

        # Fetching yml file
        file = open(current_dir + "/" + yml_dir + "/" + yml_file)
        yml_config = yaml.safe_load(file)
        file.close()

        # Validate if DAG directory exists, else create
        isDirExist = os.path.exists(yml_config["dags_dir_path"])
        if isDirExist == False:
            print("Directory for DAG creation don't exists! Creating directory: " +
                  yml_config["dags_dir_path"])
            os.makedirs(yml_config["dags_dir_path"])
            print("Created DAG directory: " + yml_config["dags_dir_path"])

        # Validating market count is same in DAG and JSON config file
        jsonConfigMarketCount = len(
            yml_config['config_values']['market_src_files'])
        dagMarketCount = len(yml_config['market_dag_list'])
        if jsonConfigMarketCount != dagMarketCount:
            print('Markets configured in DAG not matching with JSON configuration file! Kindly correct and re try!')
            print("Count of markets 'market_src_files': " +
                  str(jsonConfigMarketCount))
            print("Count of markets 'market_dag_list': " + str(dagMarketCount))
            return False
        else:
            # Checking for market extension matches in JSON key-value
            mismatched_Json_config = []
            for key, value in yml_config['config_values']['market_src_files'].items():
                if len(value) != 0:
                    if key.rsplit('_', 1)[1] != value.rsplit('.', 1)[1]:
                        mismatched_Json_config.append(
                            f"key-value market extension mismatch : {key}: '{value}'")
                else:
                    print(f"No value for: {key}")
                    return False
            if len(mismatched_Json_config) != 0:
                print('Kindly correct mismatched key-value extensions!')
                for item in mismatched_Json_config:
                    print(item)
                return False

            # Checking market extension matching in JSON and DAG
            mismatch_dag_json = []
            for dagMarketValue in yml_config['market_dag_list']:
                if len(dagMarketValue['market_ext']) != 0:
                    matched_flag = False
                    for jsonMarketValue in yml_config['config_values']['market_src_files'].values():
                        if dagMarketValue['market_ext'] == jsonMarketValue.rsplit('.', 1)[1]:
                            matched_flag = True
                            break
                    if matched_flag == False:
                        mismatch_dag_json.append(
                            f"Add 'market_src_files' entry for: {dagMarketValue['market_ext']}")
                else:
                    print(
                        "Empty value found for 'market_ext' ! Kindly correct yml and try again!")
                    return False
            if len(mismatch_dag_json) != 0:
                print("Kindly add 'market_src_files' in for below markets!")
                for item in mismatch_dag_json:
                    print(item)
                return False

        print('Validations completed.')
        return True
    except Exception as e:
        print('Exception during validation: ' + str(e))
        return False


# Start of program.
if __name__ == "__main__":
    try:
        arg_count = len(sys.argv)
        print("Total arguments passed:" + str(arg_count))
        print("Processing for yml file: " + sys.argv[1])

        if arg_count == 2:
            validationStatus = validations(sys.argv[1])
            if validationStatus == True:
                dagStatus = generateDag(sys.argv[1])
                if dagStatus == True:
                    print("Completed dynamic DAGs generation.")
                else:
                    print(
                        'Some issue ocuured during DAG creation. Kindly resolve the stated issue and try again!')
            else:
                print(
                    'Validation failed. Kindly resolve the stated issue and try again!')
        else:
            print(
                "Incorrect number of arguments! Use Command: python dag_creation.py <yml_config_file_name>")
            exit()
    except Exception as e:
        print('Exception in main block: ' + str(e))
