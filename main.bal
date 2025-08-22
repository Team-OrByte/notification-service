import notification_service.db;
import notification_service.websocket as ws;

import ballerina/http;
import ballerina/log;
import ballerina/time;
import ballerinax/kafka;

configurable int PORT = ?;
configurable string KAFKA_SERVER_URL = ?;
configurable kafka:ConsumerConfiguration consumerConfiguration = ?;

listener kafka:Listener kafkaListener = new (KAFKA_SERVER_URL, consumerConfiguration);

type EventConsumerRecord record {|
    *kafka:AnydataConsumerRecord;
    Event value;
|};

service on kafkaListener {

    function init() {
        log:printInfo(`The Notification Service Listener Initiated.`);
    }

    remote function onConsumerRecord(kafka:Caller caller, EventConsumerRecord[] records) {
        foreach EventConsumerRecord 'record in records {
            Event event = 'record.value;
            log:printInfo("Ride event received.", timestamp = 'record.timestamp, userId = event.userId, eventType = event.eventType);
            handleEvent(event);
        }
    }

    remote function onError(kafka:Error 'error, kafka:Caller caller) returns error? {
        if 'error is kafka:PayloadBindingError || 'error is kafka:PayloadValidationError {
            log:printError("Payload error occured", 'error);
            check caller->seek({
                partition: 'error.detail().partition,
                offset: 'error.detail().offset + 1
            });
        } else {
            log:printError("An error occured while lisening to ride events", 'error);
        }
    }
}

service /notification\-service on new http:Listener(PORT) {
    function init() {
        log:printInfo(`The Notification Service is initialized on PORT: ${PORT}`);
    }

    // This should be admin endpoint
    resource function get notifications/[string id]() returns http:Ok|http:NotFound|error {
        db:Notification? notif = check db:getNotification(id);
        if notif is () {
            return <http:NotFound>{};
        }
        return <http:Ok>{body: notif};
    }

    resource function put notifications/read/[string id](@http:Header string Authorization) returns http:Ok|http:BadRequest|error {
        string? userId = check getUserIdFromHeader(Authorization);
        if userId is null {
            return <http:BadRequest>{body: "Invalid Token"};
        }
        time:Utc readAt = time:utcNow();
        error? err = db:readNotification(id, userId, readAt);
        if err is error {
            return err;
        }
        return <http:Ok>{};
    }

    resource function get notifications(@http:Header string Authorization, int lim, int offset) returns http:Ok|http:BadRequest|error {
        string? userId = check getUserIdFromHeader(Authorization);
        if userId is null {
            return <http:BadRequest>{body: "Invalid Token"};
        }
        db:Notification[]|error notifications = db:getNotifications(userId, lim, offset);
        if notifications is error {
            return notifications;
        }
        return <http:Ok>{body: notifications};
    }
}

public function handleEvent(Event event) {
    EventType eventType = event.eventType;
    string userId = event.userId;
    string msg;
    if eventType is RIDE_STARTED {
        RideStartedData eventData = <RideStartedData>event.data;
        msg = string `🚴 Your ride with bike ${eventData.bikeId} has started at ${eventData.startStation}. \n
                            Enjoy your journey!`;
    } else if eventType is RIDE_ENDED {
        RideEndedData eventData = <RideEndedData>event.data;
        msg = string `✅ Your ride with bike ${eventData.bikeId} has ended.\n
                            Duration: ${eventData.duration} seconds.\n
                            Fare: ${eventData.fare.toString()} credits.`;
    }

    db:NotificationInput notificationInput = {
        userId: userId,
        notificationType: eventType,
        message: msg,
        isRead: false,
        createdAt: time:utcNow()
    };

    ws:sendNotificationToUser(event.userId, msg);

    checkpanic db:insertNotification(notificationInput);
}
