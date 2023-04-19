# Function to read JSON configuation file and return configurations as dictionary object.
def read_json_config(file_path):
    import json

    with open(file_path) as f:
        config = json.load(f)
    return config