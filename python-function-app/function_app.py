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

    if not headers:
        logging.warning("No headers found to send to OpenRouter.")
        return "No headers found for suggestion."

    prompt = f"Given the following column headers from a CSV file:\n{headers}\n" \
             f"What is the best way to visualize or present this data in a dashboard?"

    try:
        res = requests.post(
            "https://openrouter.ai/api/v1/chat/completions",
            headers={
                "Authorization": f"Bearer {api_key}",
                "HTTP-Referer": "https://your-azure-function-app-name.azurewebsites.net",  # Replace as needed
                "X-Title": "azure-csv-visualizer"
            },
            json={
                "model": "mistralai/mistral-7b-instruct",
                "messages": [{"role": "user", "content": prompt}]
            }
        )
    except Exception as e:
        logging.error(f"Failed to connect to OpenRouter: {e}")
        return "OpenRouter request failed."

    if res.status_code != 200:
        logging.error(f"OpenRouter error: {res.status_code}, {res.text}")
        return "Error fetching AI suggestion."

    return res.json()["choices"][0]["message"]["content"]

app = func.FunctionApp()

@app.blob_trigger(arg_name="myblob", path="csv-uploads/{user_id}/{name}", connection="AzureWebJobsStorage") 
def CsvBlobTrigger(myblob: func.InputStream, user_id: str, name: str):
    logging.info(f"Processing blob for user: {user_id}, file: {name}, Size: {myblob.length} bytes")

    data = myblob.read()

    try:
        df = pd.read_csv(io.BytesIO(data))
    except Exception as e:
        logging.warning(f"C parser failed ({e}), retrying with python engine and skipping bad lines")
        try:
            df = pd.read_csv(io.BytesIO(data), engine="python", on_bad_lines="skip")
        except Exception as e2:
            logging.error(f"Failed to parse CSV file: {e2}")
            return

    headers, summary = extract_data(df)
    logging.info(f"Extracted Headers: {headers}")

    suggestions = ask_openrouter(headers)

    connection_string = os.environ["AzureWebJobsStorage"]
    blob_service_client = BlobServiceClient.from_connection_string(connection_string)

    # Upload parsed JSON under user folder
    parsed_container = "parsed-data"
    parsed_blob_name = f"{user_id}/parsed-{name.replace('.csv', '')}.json"
    parsed_client = blob_service_client.get_container_client(parsed_container)
    try:
        parsed_client.get_container_properties()
    except Exception:
        logging.info(f"Creating container '{parsed_container}'...")
        parsed_client.create_container()

    parsed_client.get_blob_client(parsed_blob_name).upload_blob(
        json.dumps(df.to_dict(orient='records'), indent=2),
        overwrite=True,
        content_settings=ContentSettings(content_type='application/json')
    )
    logging.info(f"Uploaded parsed data to '{parsed_container}/{parsed_blob_name}'")

    # Upload suggestions JSON under user folder
    suggestions_container = "suggestions"
    suggestions_blob_name = f"{user_id}/suggestions-{name.replace('.csv', '')}.json"
    suggestions_client = blob_service_client.get_container_client(suggestions_container)
    try:
        suggestions_client.get_container_properties()
    except Exception:
        logging.info(f"Creating container '{suggestions_container}'...")
        suggestions_client.create_container()

    suggestions_client.get_blob_client(suggestions_blob_name).upload_blob(
        json.dumps({ "llm_advice": suggestions }, indent=2),
        overwrite=True,
        content_settings=ContentSettings(content_type='application/json')
    )
    logging.info(f"Uploaded suggestions to '{suggestions_container}/{suggestions_blob_name}'")
