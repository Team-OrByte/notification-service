# 🚴 Notification Service  

This service is designed to provide **real-time notifications** for an e-bike rental application. It consumes ride events from **Kafka**, persists notifications in **MongoDB**, and delivers live notifications to clients via **WebSocket**.  

---

## 📌 Features  
- Consumes ride events (`RIDE_STARTED`, `RIDE_ENDED`) from Kafka.  
- Persists notifications in MongoDB for retrieval.  
- Provides REST API endpoints to manage and fetch notifications.  
- Sends **live notifications** to users via WebSocket.  
- Supports JWT-based user validation through the `Authorization` header.  

---

## ⚙️ Configuration  

Configuration is provided via `Config.toml`.  

### Sample `Config.toml`  

```toml
[notification_service]
PORT = 8084
KAFKA_SERVER_URL = "localhost:9094"

[notification_service.websocket]
WEBSOCKET_PORT = 27760

[notification_service.consumerConfiguration]
groupId = "notification-service"
topics = ["ride-events"]
pollingInterval = 1.0
clientId = "event-producer"
autoSeekOnValidationFailure = false

[notification_service.db]
host = "localhost"
port = 27017
username = "notif_user"
password = "notif_pass"
database = "notification-management"
```

---

## 🚀 Running the Service  

1. **Start Kafka** with the topic `ride-events`.  
2. **Start MongoDB** with configured credentials.  
3. Run the Notification Service:  
   ```bash
   bal run
   ```

---

## 🌐 API Endpoints  

### Base URL  
```
http://localhost:8084/notification-service
```

### 1. **Get Notifications by ID (Admin endpoint)**  
- **Endpoint:** `GET /notifications/{id}`  
- **Description:** Fetch a notification by ID.  
- **Response:**  
  - `200 OK` → Notification object.  
  - `404 Not Found` → If notification does not exist.  

---

### 2. **Mark Notification as Read**  
- **Endpoint:** `PUT /notifications/read/{id}`  
- **Headers:**  
  - `Authorization: Bearer <JWT>`  
- **Description:** Marks a notification as read by the authenticated user.  
- **Response:**  
  - `200 OK` → Successfully marked as read.  
  - `400 Bad Request` → Invalid or missing token.  

---

### 3. **Get User Notifications**  
- **Endpoint:** `GET /notifications?lim={limit}&offset={offset}`  
- **Headers:**  
  - `Authorization: Bearer <JWT>`  
- **Query Parameters:**  
  - `lim` → Maximum number of notifications to fetch.  
  - `offset` → Pagination offset.  
- **Response:**  
  - `200 OK` → List of notifications.  
  - `400 Bad Request` → Invalid or missing token.  

---

## 🔔 WebSocket Endpoint  

### Base URL  
```
ws://localhost:27760/notifications
```

- Clients connect to receive **real-time notifications**.  
- Notifications are pushed whenever a ride event is consumed from Kafka.  

---

## 🗄️ Database  

MongoDB stores notifications in the following structure:  

```json
{
  "id": "string",
  "userId": "string",
  "notificationType": "RIDE_STARTED | RIDE_ENDED",
  "message": "string",
  "isRead": false,
  "createdAt": "2025-08-22T14:15:22Z"
}
```

---

## 🛠️ Event Handling  

### Example: `RIDE_STARTED`  
```json
{
  "eventType": "RIDE_STARTED",
  "userId": "user123",
  "data": {
    "bikeId": "bike001",
    "startStation": "Station A"
  }
}
```

➡️ Notification Sent:  
```
🚴 Your ride with bike bike001 has started at Station A. 
Enjoy your journey!
```

### Example: `RIDE_ENDED`  
```json
{
  "eventType": "RIDE_ENDED",
  "userId": "user123",
  "data": {
    "bikeId": "bike001",
    "duration": 540,
    "fare": 12.5
  }
}
```

➡️ Notification Sent:  
```
✅ Your ride with bike bike001 has ended.
Duration: 540 seconds.
Fare: 12.5 credits.
```

---

## 📖 Summary  

This Notification Service integrates:  
- **Kafka** → Event consumption.  
- **MongoDB** → Persistence.  
- **HTTP APIs** → User notification management.  
- **WebSocket** → Live updates.  
