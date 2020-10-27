import logging
import requests
import uuid
import datetime
import json
import os

import azure.functions as func

from azure.cosmosdb.table.tableservice import TableService
from azure.cosmosdb.table.models import Entity


def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')

    try:
        req_body = req.get_json()
    except ValueError:
        pass

    emotion = req_body.get('emotion')
    activity = req_body.get('activity')
    notes = req_body.get('notes')
    time_generated = datetime.datetime.now().timestamp()

    id = str(uuid.uuid4())
    # Connect to Cosmos
    the_connection_string = os.environ['COSMOS_CXN_STRING']
    table_service = TableService(endpoint_suffix = "table.cosmos.azure.com", connection_string= the_connection_string)

    # Insert/Replace
    new_body = req_body
    new_body["RowKey"] = id
    new_body["PartitionKey"] = '1'
    new_body["rating"] = rating
    insert = table_service.insert_or_replace_entity('emotions', new_body)

    del new_body["PartitionKey"]
    del new_body["RowKey"]
    new_body["id"] = id

    if emotion and activity:
        return func.HttpResponse(f"""Hello. This HTTP triggered function executed successfully. You submitted
        an emotion: {emotion}
        an activity: {activity}
        and some notes: {notes}
        at time: {time_generated}
        """)
    else:
        return func.HttpResponse(
             "This HTTP triggered function executed successfully. However, all the correct parameters were not sent. Please send an emotion and an activity. We'll also keep track of your notes if you would like.",
             status_code=200
        )
