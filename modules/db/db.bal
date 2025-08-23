import ballerina/time;
import ballerina/uuid;
import ballerinax/mongodb;

configurable string host = ?;
configurable int port = ?;
configurable string username = ?;
configurable string password = ?;
configurable string database = ?;

const string collection = "notifications";

final mongodb:Client mongoDb = check new ({
    connection: {
        serverAddress: {
            host,
            port
        },
        auth: <mongodb:ScramSha256AuthCredential>{
            username,
            password,
            database
        }
    }
});

final mongodb:Database notificationDb;

function init() returns error? {
    notificationDb = check mongoDb->getDatabase(database);
}

public isolated function getNotification(string id) returns Notification?|error {
    mongodb:Collection notificationsCollection = check notificationDb->getCollection(collection);
    stream<Notification, error?> findResult = check notificationsCollection->find({id});
    Notification[] result = check from Notification n in findResult
        select n;
    if result.length() != 1 {
        return ();
    }
    return result[0];
}

public isolated function getNotifications(string userId, int lim = 10, int offset = 0) returns Notification[]|error {

    mongodb:Collection notificationsCollection = check notificationDb->getCollection(collection);

    stream<Notification, error?> resultStream = check notificationsCollection->aggregate([
        {
            \$match: {
                userId: userId
            }
        },
        {
            \$sort: {
                createdAt: -1 // newest first
            }
        },
        {
            \$skip: offset
        },
        {
            \$limit: lim
        }
    ]);

    return from Notification notif in resultStream
        select notif;
}

public function insertNotification(NotificationInput input) returns error? {
    string id = uuid:createType1AsString();
    Notification notification = {id, ...input};
    mongodb:Collection notificationsCollection = check notificationDb->getCollection(collection);
    check notificationsCollection->insertOne(notification);
}

public function readNotification(string id, string userId, time:Utc readAt) returns error? {
    mongodb:Collection notificationsCollection = check notificationDb->getCollection(collection);
    NotificationUpdate update = {
        isRead: true,
        readAt: readAt
    };
    _ = check notificationsCollection->updateOne(
        {
            "id": id,
            "userId": userId
        },
        {set: update}
    );
}

public type NotificationInput record {|
    string userId;
    string message;  
    string notificationType;        
    boolean isRead = false;
    time:Utc createdAt;
    time:Utc? readAt?;
|};

public type NotificationUpdate record {|
    boolean isRead?;
    time:Utc readAt?;
|};

public type Notification record {|
    readonly string id;
    *NotificationInput;
|};
