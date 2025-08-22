import ballerina/io;
import ballerina/log;
import ballerina/websocket;

configurable int WEBSOCKET_PORT = ?;

final map<websocket:Caller> clients = {};

service /notifications on new websocket:Listener(WEBSOCKET_PORT) {

    function init() {
        log:printInfo(`The Notification Websocket is initialized with PORT : ${WEBSOCKET_PORT}`);
    }

    resource function get .(string userId) returns websocket:Service|websocket:UpgradeError {
        return new NotificationService(userId);
    }
}

service class NotificationService {
    *websocket:Service;
    private final string userId;

    public function init(string userId) {
        self.userId = userId;
    }

    remote function onOpen(websocket:Caller caller) {
        io:println("WebSocket connected for user: ", self.userId);
        addClient(self.userId, caller);
    }

    remote function onClose(websocket:Caller caller, int statusCode, string reason) {
        io:println("WebSocket closed for user: ", self.userId);
        removeClient(self.userId);
    }
}

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

public function sendNotificationToUser(string userId, string message) {
    websocket:Caller? caller = clients[userId];
    if caller is websocket:Caller {
        websocket:Error? err = caller->writeMessage(message);
        if err is websocket:Error {
            log:printError("Error occured while sending the notification to user", message = message, userId = userId);
        }
    }
}
