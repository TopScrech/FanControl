enum RemoteCloudSchema {
    static let containerIdentifier = "iCloud.dev.topscrech.FanControl"
    static let macRecordType = "RemoteMac"
    static let registryRecordType = "RemoteMacRegistry"
    static let commandRecordType = "RemoteFanCommand"
    static let registryRecordName = "remote-mac-registry"

    enum Field {
        static let deviceID = "deviceID"
        static let name = "name"
        static let deviceIDs = "deviceIDs"
        static let updatedAt = "updatedAt"
        static let fans = "fans"
        static let requestID = "requestID"
        static let fanID = "fanID"
        static let action = "action"
        static let createdAt = "createdAt"
        static let status = "status"
        static let errorMessage = "errorMessage"
        static let completedAt = "completedAt"
    }

    static func macRecordName(deviceID: String) -> String {
        "mac-\(deviceID)"
    }

    static func commandRecordName(deviceID: String) -> String {
        "command-\(deviceID)"
    }
}
