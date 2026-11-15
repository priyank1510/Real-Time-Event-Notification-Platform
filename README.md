# Real-Time Event & Notification Platform — Dockerized

This version runs the Spring Boot app, Java 17/Maven build, PostgreSQL, and Redis through Docker.
You do **not** need local Java or Maven to run it. You only need Docker Desktop.

## Start everything

From this folder:

```bat
docker compose up --build
```

First build may take a few minutes because Docker downloads the Java/Maven base images and Maven dependencies.

When you see the Spring application start, open another terminal and test:

```bat
curl http://localhost:8080/actuator/health
```

Expected:

```json
{"status":"UP"}
```

## WebSocket demo

Open `websocket-demo.html` in your browser, leave `user-1`, then click **Connect**.

## Create an event

Windows Command Prompt:

```bat
curl -i -X POST http://localhost:8080/api/events -H "Content-Type: application/json" -d "{\"eventType\":\"PAYMENT_SUCCESS\",\"userId\":\"user-1\",\"referenceId\":\"payment-1001\"}"
```

The API returns `202 Accepted`. Note the returned `id`.

## Check event status

```bat
curl http://localhost:8080/api/events/1
```

Typical status flow:

`PENDING -> PROCESSING -> COMPLETED`

## Read notifications

```bat
curl "http://localhost:8080/api/notifications/users/user-1?limit=20"
```

## Stop everything

```bat
docker compose down
```

To also delete PostgreSQL/Redis data:

```bat
docker compose down -v
```

## What Docker runs

- `app`: Spring Boot application, built with Maven + Java 17 inside Docker
- `postgres`: PostgreSQL 16
- `redis`: Redis 7

So your Windows Java 11 installation does not matter for this Dockerized version.

## Load test with k6

The project now includes `load-test/k6.js` and a Dockerized k6 runner, so you do **not** need to install k6 on Windows.

First make sure the application stack is running:

```bat
docker compose up -d --build
```

Then run the load test:

```bat
run-load-test.bat
```

Or run it directly with Docker Compose:

```bat
docker compose --profile loadtest run --rm k6
```

### What the test does

- Sends **8 event-ingestion requests per second** for **60 seconds**.
- Target workload: approximately **480 submitted events/minute**.
- Mixes `PAYMENT_SUCCESS`, `PAYMENT_FAILED`, `ORDER_CREATED`, `ORDER_SHIPPED`, and `ACCOUNT_CREATED` events.
- Treats only `HTTP 202 Accepted` responses as successfully accepted events.
- Requires the event-ingestion HTTP failure rate to stay below **1%**.
- Requires the **median latency of `POST /api/events`** to stay below **300 ms**.

The `<300 ms` threshold applies only to the synchronous event-ingestion HTTP request. It does **not** mean the WebSocket notification is guaranteed to arrive within 300 ms.

The complete raw k6 summary is saved to:

```text
load-test/results/k6-summary.json
```

### What to look for in the k6 output

Look for these metrics:

```text
accepted_events
http_req_failed
http_req_duration
checks
```

For the resume performance statement to be defensible, the actual run should show roughly 480 accepted requests over the one-minute scenario, less than 1% failures, and a median event-ingestion request duration below 300 ms.

Do not present those numbers as measured results unless your actual k6 run passes the thresholds on the environment you tested.
