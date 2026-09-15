import CloudKit
import Foundation

@MainActor
final class RemoteCloudStore {
    private let container: CKContainer
    private let database: CKDatabase
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(containerIdentifier: String? = nil) {
        container = CKContainer(identifier: containerIdentifier ?? RemoteCloudSchema.containerIdentifier)
        database = container.privateCloudDatabase
    }

    func verifyAccount() async throws {
        guard try await container.accountStatus() == .available else {
            throw RemoteCloudError.iCloudUnavailable
        }
    }

    func fetchMacs() async throws -> [RemoteMacState] {
        try await verifyAccount()
        let registryID = CKRecord.ID(recordName: RemoteCloudSchema.registryRecordName)
        guard
            let registry = try await existingRecord(withID: registryID),
            let deviceIDs = registry[RemoteCloudSchema.Field.deviceIDs] as? [String]
        else {
            return []
        }

        var macs: [RemoteMacState] = []

        for deviceID in deviceIDs {
            let recordID = CKRecord.ID(recordName: RemoteCloudSchema.macRecordName(deviceID: deviceID))
            guard let record = try await existingRecord(withID: recordID) else { continue }
            guard let mac = try? macState(from: record) else { continue }
            macs.append(mac)
        }

        return macs.sorted {
            $0.updatedAt > $1.updatedAt
        }
    }

    func publishMac(deviceID: String, name: String, fans: [RemoteFanState]) async throws {
        try await verifyAccount()
        let recordID = CKRecord.ID(recordName: RemoteCloudSchema.macRecordName(deviceID: deviceID))
        let record = try await existingRecord(withID: recordID) ?? CKRecord(
            recordType: RemoteCloudSchema.macRecordType,
            recordID: recordID
        )

        record[RemoteCloudSchema.Field.deviceID] = deviceID
        record[RemoteCloudSchema.Field.name] = name
        record[RemoteCloudSchema.Field.updatedAt] = Date()
        record[RemoteCloudSchema.Field.fans] = try encoder.encode(fans)
        _ = try await database.save(record)
        try await registerMac(deviceID: deviceID)
    }

    func sendCommand(deviceID: String, fanID: Int, action: RemoteFanAction) async throws -> RemoteFanCommand {
        try await verifyAccount()
        let recordID = CKRecord.ID(recordName: RemoteCloudSchema.commandRecordName(deviceID: deviceID))
        let record = try await existingRecord(withID: recordID) ?? CKRecord(
            recordType: RemoteCloudSchema.commandRecordType,
            recordID: recordID
        )
        let command = RemoteFanCommand(
            id: UUID().uuidString,
            deviceID: deviceID,
            fanID: fanID,
            action: action,
            createdAt: Date(),
            status: .pending,
            errorMessage: nil
        )

        record[RemoteCloudSchema.Field.requestID] = command.id
        record[RemoteCloudSchema.Field.deviceID] = command.deviceID
        record[RemoteCloudSchema.Field.fanID] = command.fanID
        record[RemoteCloudSchema.Field.action] = command.action.rawValue
        record[RemoteCloudSchema.Field.createdAt] = command.createdAt
        record[RemoteCloudSchema.Field.status] = command.status.rawValue
        record[RemoteCloudSchema.Field.errorMessage] = nil
        record[RemoteCloudSchema.Field.completedAt] = nil
        _ = try await database.save(record)
        return command
    }

    func fetchCommand(deviceID: String) async throws -> RemoteFanCommand? {
        try await verifyAccount()
        let recordID = CKRecord.ID(recordName: RemoteCloudSchema.commandRecordName(deviceID: deviceID))
        guard let record = try await existingRecord(withID: recordID) else { return nil }
        return try command(from: record)
    }

    func completeCommand(_ command: RemoteFanCommand, errorMessage: String?) async throws {
        let recordID = CKRecord.ID(recordName: RemoteCloudSchema.commandRecordName(deviceID: command.deviceID))
        guard let record = try await existingRecord(withID: recordID) else { return }
        guard record[RemoteCloudSchema.Field.requestID] as? String == command.id else { return }

        record[RemoteCloudSchema.Field.status] = errorMessage == nil
            ? RemoteFanCommand.Status.completed.rawValue
            : RemoteFanCommand.Status.failed.rawValue
        record[RemoteCloudSchema.Field.errorMessage] = errorMessage
        record[RemoteCloudSchema.Field.completedAt] = Date()
        _ = try await database.save(record)
    }

    private func existingRecord(withID recordID: CKRecord.ID) async throws -> CKRecord? {
        do {
            return try await database.record(for: recordID)
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        }
    }

    private func registerMac(deviceID: String) async throws {
        let recordID = CKRecord.ID(recordName: RemoteCloudSchema.registryRecordName)
        var lastError: Error?

        for _ in 0..<3 {
            let record = try await existingRecord(withID: recordID) ?? CKRecord(
                recordType: RemoteCloudSchema.registryRecordType,
                recordID: recordID
            )
            var deviceIDs = record[RemoteCloudSchema.Field.deviceIDs] as? [String] ?? []
            guard !deviceIDs.contains(deviceID) else { return }
            deviceIDs.append(deviceID)
            record[RemoteCloudSchema.Field.deviceIDs] = deviceIDs

            do {
                _ = try await database.save(record)
                return
            } catch let error as CKError where error.code == .serverRecordChanged {
                lastError = error
            }
        }

        if let lastError {
            throw lastError
        }
    }

    private func macState(from record: CKRecord) throws -> RemoteMacState {
        guard
            let deviceID = record[RemoteCloudSchema.Field.deviceID] as? String,
            let name = record[RemoteCloudSchema.Field.name] as? String,
            let updatedAt = record[RemoteCloudSchema.Field.updatedAt] as? Date,
            let fanData = record[RemoteCloudSchema.Field.fans] as? Data
        else {
            throw RemoteCloudError.invalidRecord
        }

        return RemoteMacState(
            id: deviceID,
            name: name,
            updatedAt: updatedAt,
            fans: try decoder.decode([RemoteFanState].self, from: fanData)
        )
    }

    private func command(from record: CKRecord) throws -> RemoteFanCommand {
        guard
            let requestID = record[RemoteCloudSchema.Field.requestID] as? String,
            let deviceID = record[RemoteCloudSchema.Field.deviceID] as? String,
            let fanID = record[RemoteCloudSchema.Field.fanID] as? Int,
            let actionRawValue = record[RemoteCloudSchema.Field.action] as? String,
            let action = RemoteFanAction(rawValue: actionRawValue),
            let createdAt = record[RemoteCloudSchema.Field.createdAt] as? Date,
            let statusRawValue = record[RemoteCloudSchema.Field.status] as? String,
            let status = RemoteFanCommand.Status(rawValue: statusRawValue)
        else {
            throw RemoteCloudError.invalidRecord
        }

        return RemoteFanCommand(
            id: requestID,
            deviceID: deviceID,
            fanID: fanID,
            action: action,
            createdAt: createdAt,
            status: status,
            errorMessage: record[RemoteCloudSchema.Field.errorMessage] as? String
        )
    }
}
