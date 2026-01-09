import json
import logging
import azure.functions as func
from azure.cosmos import CosmosClient
import os
import uuid

app = func.FunctionApp()

@app.function_name(name="CreateTask")
@app.route(route="tasks", methods=["POST"], auth_level=func.AuthLevel.ANONYMOUS)
def create_task(req: func.HttpRequest) -> func.HttpResponse:
    logging.info("Processing CreateTask request")

    try:
        body = req.get_json()
    except ValueError:
        return func.HttpResponse(
            json.dumps({"error": "Invalid JSON"}),
            status_code=400,
            mimetype="application/json"
        )

    title = body.get("title")
    description = body.get("description")

    if not title:
        return func.HttpResponse(
            json.dumps({"error": "Missing required field: title"}),
            status_code=400,
            mimetype="application/json"
        )

    # Generate unique ID
    task_id = str(uuid.uuid4())

    # Connect to Cosmos DB
    cosmos_url = os.environ["COSMOS_DB_CONNECTION_STRING"]
    database_name = os.environ["COSMOS_DB_DATABASE_NAME"]
    container_name = os.environ["COSMOS_DB_CONTAINER_NAME"]

    client = CosmosClient.from_connection_string(cosmos_url)
    database = client.get_database_client(database_name)
    container = database.get_container_client(container_name)

    # Create item
    item = {
        "id": task_id,
        "title": title,
        "description": description,
    }

    container.create_item(item)

    return func.HttpResponse(
        json.dumps({"message": "Task created", "task": item}),
        status_code=201,
        mimetype="application/json"
    )