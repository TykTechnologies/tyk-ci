# Webhook Server

A simple Go application to receive and store webhook events, and retrieve them based on an ID.

## Features

- Receives webhook events at `/webhook/{id}`
- Stores requests associated with each `{id}`
- Retrieves stored requests at `/requests/{id}`


## Usage

### Start webhook server

`go run main.go` runs the webhook server listening on port `8080`.

### Sending a Webhook Event

Send a POST request to `/webhook/{id}` with your webhook payload:

```
curl -X POST http://localhost:8080/webhook/1 \
     -H "Content-Type: application/json" \
     -d '{"event": "test"}'
```

### Retrieving Stored Requests
Send a GET request to `/requests/{id}` to retrieve the requests stored for a particular ID (ID is of string type)
```
curl http://localhost:8080/requests/1
```

This will return a JSON array of all received webhook requests for the given ID.

### Example
1. Send a webhook event to ID `wh-1`:

```
curl -X POST http://localhost:8080/webhook/wh-1 \
     -H "Content-Type: application/json" \
     -d '{"event": "test event for ID wh-1"}'
```

2. Retrieve stored requests for ID `wh-1`:
```
curl http://localhost:8080/requests/wh-1
```

Response 
```
[
  {
    "headers": {
      "Content-Type": ["application/json"],
      ...
    },
    "body": {"event": "test event for ID wh-1"}
  }
]
```