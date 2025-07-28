import azure.functions as func
import logging
import pandas as pd
import io
import json
import os
import requests
from azure.storage.blob import BlobServiceClient, ContentSettings

def extract_data(df):
    headers = df.columns.tolist()
    summary = df.describe(include='all').to_dict()
    return headers, summary 

def ask_openrouter(headers):
    api_key = "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"
    prompt = f"Given the following column headers from a CSV file:\n{headers}\n" \
             f"What is the best way to visualize or present this data in a dashboard?"

    res = requests.post(
        "https://openrouter.ai/api/v1/chat/completions",
        headers={
            "Authorization": f"Bearer {api_key}",
            "HTTP-Referer": "https://your-azure-function-app-name.azurewebsites.net",  # Replace with your app domain
            "X-Title": "azure-csv-visualizer"
        },
        json={
            "model": "mistralai/mistral-7b-instruct",  # Or any other supported free model
            "messages": [{"role": "user", "content": prompt}]
        }
    )

    if res.status_code != 200:
        logging.error(f"OpenRouter error: {res.status_code}, {res.text}")
        return "Error fetching AI suggestion."

    return res.json()["choices"][0]["message"]["content"]

app = func.FunctionApp()

@app.blob_trigger(arg_name="myblob", path="csv-uploads/{name}", connection="AzureWebJobsStorage") 
def CsvBlobTrigger(myblob: func.InputStream):
    logging.info(f"Processing blob: {myblob.name}, Size: {myblob.length} bytes")

    data = myblob.read()
    df = pd.read_csv(io.BytesIO(data))
    logging.info(f"Parsed DataFrame:\n{df.head()}")

    json_data = json.dumps(df.to_dict(orient='records'), indent=2)
    original_name = myblob.name.split('/')[-1].replace('.csv', '')

    connection_string = os.environ["AzureWebJobsStorage"]
    blob_service_client = BlobServiceClient.from_connection_string(connection_string)

    container_name = "parsed-data"
    container_client = blob_service_client.get_container_client(container_name)
    try:
        container_client.get_container_properties()
    except Exception:
        logging.info(f"Creating container '{container_name}'...")
        container_client.create_container()

    suggestions_container_name = "suggestions"
    suggestions_container_client = blob_service_client.get_container_client(suggestions_container_name)
    try:
        suggestions_container_client.get_container_properties()
    except Exception:
        logging.info(f"Creating container '{suggestions_container_name}'...")
        suggestions_container_client.create_container()

    blob_name = f"parsed-{original_name}.json"
    blob_client = container_client.get_blob_client(blob_name)
    blob_client.upload_blob(json_data, overwrite=True, content_settings=ContentSettings(content_type='application/json'))
    logging.info(f"Uploaded parsed data to '{container_name}/{blob_name}'") 

    headers, summary = extract_data(df)
    suggestions = ask_openrouter(headers)

    suggestions_blob_name = f"suggestions-{original_name}.json"
    suggestions_blob_client = suggestions_container_client.get_blob_client(suggestions_blob_name)
    suggestions_blob_client.upload_blob(
        json.dumps({ "llm_advice": suggestions }), overwrite=True, content_settings=ContentSettings(content_type='application/json')
    )
    logging.info(f"Uploaded suggestions to '{suggestions_container_name}/{suggestions_blob_name}'")
