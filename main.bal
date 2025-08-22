import notification_service.websocket as ws;

import ballerina/log;
import ballerinax/kafka;

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

public function handleEvent(Event event) {
    EventType eventType = event.eventType;
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

    //save the notification to the database

    ws:sendNotificationToUser(event.userId, msg);
}
