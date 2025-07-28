import azure.functions as func
import logging
import pandas as pd
import io
import json
import os
from azure.storage.blob import BlobServiceClient


app = func.FunctionApp()

@app.blob_trigger(arg_name="myblob", path="csv-uploads/{name}", connection="AzureWebJobsStorage") 
def CsvBlobTrigger(myblob: func.InputStream):
    logging.info(f"Processing blob: {myblob.name}, Size: {myblob.length} bytes")

    # Read blob data and parse CSV
    data = myblob.read()
    df = pd.read_csv(io.BytesIO(data))
    logging.info(f"Parsed DataFrame:\n{df.head()}")

    # Convert DataFrame to JSON
    json_data = json.dumps(df.to_dict(orient='records'), indent=2)
    original_name = myblob.name.split('/')[-1].replace('.csv', '')

    # Initialize BlobServiceClient
    connection_string = os.environ["AzureWebJobsStorage"]
    blob_service_client = BlobServiceClient.from_connection_string(connection_string)

    # Ensure the 'parsed' container exists
    container_name = "parsed"
    container_client = blob_service_client.get_container_client(container_name)
    try:
        container_client.get_container_properties()
        logging.info(f"Container '{container_name}' already exists.")
    except Exception:
        logging.info(f"Container '{container_name}' not found. Creating it now...")
        container_client.create_container()

    # Upload JSON blob
    blob_name = f"parsed-{original_name}.json"
    blob_client = container_client.get_blob_client(blob_name)
    blob_client.upload_blob(json_data, overwrite=True)
    logging.info(f"Uploaded parsed data to '{container_name}/{blob_name}'") 