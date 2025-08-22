public type Event readonly & record {|
    string userId;
    EventType eventType;
    EventDataType data;
|};

public enum EventType {
    RIDE_STARTED,
    RIDE_ENDED
};

public type EventDataType RideStartedData|RideEndedData;

public type RideStartedData record {|
    string bikeId;
    string startStation;
|};

public type RideEndedData record {|
    string bikeId;
    string duration;
    string fare;
|};