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
pub_key = "./public.crt"
KAFKA_SERVER_URL = "localhost:9094"

[notification_service.websocket]
WEBSOCKET_PORT = 27760
pub_key = "./public.crt"

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

All endpoints (except the **admin endpoint**) require **JWT authentication** via the `Authorization` header:  

```
Authorization: Bearer {token}
```

---

### 1. Get Notifications by ID (Admin endpoint)  

Retrieve a specific notification by its ID.  

- **Method:** `GET`  
- **Endpoint:** `/notifications/{id}`  
- **Auth:** Admin access only  

##### Example Request  
```bash
curl --request GET \
  --url 'http://localhost:8084/notification-service/notifications/12345' \
  --header 'Authorization: Bearer {token}' \
  --header 'Content-Type: application/json'
  
```

##### Example Response (200 OK)  
```json
{
  "id": "12345",
  "userId": "user_001",
  "notificationType": "RIDE_STARTED",
  "message": "🚴 Your ride with bike B101 has started at Station A. \n Enjoy your journey!",
  "isRead": false,
  "createdAt": "2025-08-27T12:34:56Z",
  "readAt": null
}
```

---

### 2. Mark Notification as Read  

Mark a specific notification as read for the authenticated user.  

- **Method:** `PUT`  
- **Endpoint:** `/notifications/read/{id}`  
- **Auth:** JWT required  

##### Example Request  
```bash
curl --request PUT \
  --url 'http://localhost:8084/notification-service/notifications/read/12345' \
  --header 'Authorization: Bearer {token}' \
  --header 'Content-Type: application/json'
```

##### Example Response (200 OK)  
```json
{}
```

---

### 3. Get All Notifications (Paginated)  

Fetch notifications for the authenticated user with pagination.  

- **Method:** `GET`  
- **Endpoint:** `/notifications?lim={limit}&offset={offset}`  
- **Auth:** JWT required  

##### Example Request  
```bash
curl --request GET \
  --url 'http://localhost:8084/notification-service/notifications?lim=5&offset=0' \
  --header 'Authorization: Bearer {token}' \
  --header 'Content-Type: application/json'
```

##### Example Response (200 OK)  
```json
[
  {
    "id": "12345",
    "userId": "user_001",
    "notificationType": "RIDE_STARTED",
    "message": "🚴 Your ride with bike B101 has started at Station A. \n Enjoy your journey!",
    "isRead": false,
    "createdAt": "2025-08-27T12:34:56Z",
    "readAt": null
  },
  {
    "id": "12346",
    "userId": "user_001",
    "notificationType": "RIDE_ENDED",
    "message": "✅ Your ride with bike B101 has ended.\n Duration: 450 seconds.\n Fare: 20 credits.",
    "isRead": true,
    "createdAt": "2025-08-27T13:20:00Z",
    "readAt": "2025-08-27T13:25:10Z"
  }
]
```

---

## 🔔 WebSocket Notifications  

### Base URL  
```
ws://localhost:8090/notifications/{userId}
```

- **Auth:** JWT required in the WebSocket handshake.  
- **Description:** Clients can subscribe to receive **real-time notifications** for a specific `userId`.  

##### Example WebSocket Connection (using `wscat`)  
```bash
wscat -c "ws://localhost:8090/notifications/user_001" \
  -H "Authorization: Bearer {token}"
```

##### Example Push Message from Server  
```json
"🚴 Your ride with bike B101 has started at Station A. 
Enjoy your journey!"
```


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
