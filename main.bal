import ballerina/io;
import ballerina/log;
import ballerina/websocket;
import ballerinax/kafka;

configurable kafka:ConsumerConfiguration consumerConfiguration = ?;

listener kafka:Listener kafkaListener = new (kafka:DEFAULT_URL, consumerConfiguration);

service on kafkaListener {

    remote function onConsumerRecord(kafka:Caller caller, kafka:BytesConsumerRecord[] records) {
        foreach var 'record in records {
            string message = 'record.value.toString();
            io:println("Received notification message: ", message);
            error? nh = sendNotificationToAll(message);
            if nh is error {
                log:printError("Condum");
            }
        }
    }
}

final map<websocket:Caller> clients = {};

public function addClient(string userId, websocket:Caller caller) {
    lock {
        clients[userId] = caller;
    }
}

public function removeClient(string userId) {
    lock {
        _ = clients.removeIfHasKey(userId);
    }
}

public function sendNotificationToAll(string message) returns error? {
    foreach var [_, caller] in clients.entries() {
        check caller->writeMessage(message);
    }
}

public function sendNotificationToUser(string userId, string message) returns error? {
    websocket:Caller? caller = clients[userId];
    if caller is websocket:Caller {
        check caller->writeMessage(message);
    }
}

service /notifications on new websocket:Listener(27760) {

    resource function get .(string userId) returns websocket:Service|websocket:UpgradeError {
        return new NotificationService(userId);
    }
}

service class NotificationService {
    *websocket:Service;

    final string userId;

    public function init(string userId) {
        self.userId = userId;
    }

    remote function onOpen(websocket:Caller caller) {
        io:println("WebSocket connected for user: ", self.userId);
        addClient(self.userId, caller);
    }

    remote function onTextMessage(websocket:Caller caller, string text) {
        io:println("Received message from user: ", text);
    }

    remote function onClose(websocket:Caller caller, int statusCode, string reason) {
        io:println("WebSocket closed for user: ", self.userId);
        removeClient(self.userId);
    }
}
